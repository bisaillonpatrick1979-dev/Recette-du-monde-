-- Notifications automatiques et crédits du Chef IA.
--
-- 1. Notifications : un déclencheur par action sociale (j'aime, note, commentaire, abonnement,
--    « je l'ai cuisinée ») crée une ligne dans public.notifications pour la personne concernée.
--    Aucune notification pour soi-même, ni venant d'une personne qu'on a bloquée.
--    Un même geste répété dans la journée (j'aime retiré puis remis) ne crée pas de doublon.
-- 2. Chef IA : public.credits_ia() donne le solde du forfait mensuel (remis à zéro au changement de
--    mois) et public.consommer_credit_ia() débite un crédit et journalise l'appel réussi.

-- ---------------------------------------------------------------------------
-- 1. Notifications
-- ---------------------------------------------------------------------------

create or replace function private.notifier(
  p_destinataire uuid,
  p_acteur uuid,
  p_type public.notification_type,
  p_recette uuid default null,
  p_commentaire uuid default null,
  p_donnees jsonb default '{}'::jsonb
) returns void
language plpgsql
security definer
set search_path to ''
as $fn$
begin
  if p_destinataire is null or p_acteur is null or p_destinataire = p_acteur then
    return;
  end if;

  -- Le destinataire a bloqué l'auteur de l'action : silence.
  if exists (
    select 1 from public.user_blocks b
    where b.blocker_id = p_destinataire and b.blocked_id = p_acteur
  ) then
    return;
  end if;

  -- Anti-doublon : même acteur, même type, même cible dans les dernières 24 h (sauf commentaires).
  if p_type <> 'comment' and exists (
    select 1 from public.notifications n
    where n.user_id = p_destinataire
      and n.actor_id = p_acteur
      and n.type = p_type
      and n.recipe_id is not distinct from p_recette
      and n.created_at > now() - interval '24 hours'
  ) then
    return;
  end if;

  insert into public.notifications (user_id, actor_id, type, recipe_id, comment_id, payload)
  values (p_destinataire, p_acteur, p_type, p_recette, p_commentaire, coalesce(p_donnees, '{}'::jsonb));
end;
$fn$;

revoke all on function private.notifier(uuid, uuid, public.notification_type, uuid, uuid, jsonb) from public, anon, authenticated;

create or replace function private.notifier_action_recette()
returns trigger
language plpgsql
security definer
set search_path to ''
as $fn$
declare
  v_auteur uuid;
  v_titre text;
begin
  select r.author_id, r.title into v_auteur, v_titre from public.recipes r where r.id = new.recipe_id;

  if tg_table_name = 'recipe_likes' then
    perform private.notifier(v_auteur, new.user_id, 'like', new.recipe_id, null,
      jsonb_build_object('titre', v_titre));
  elsif tg_table_name = 'recipe_ratings' then
    perform private.notifier(v_auteur, new.user_id, 'rating', new.recipe_id, null,
      jsonb_build_object('titre', v_titre, 'note', new.rating));
  elsif tg_table_name = 'recipe_comments' then
    perform private.notifier(v_auteur, new.user_id, 'comment', new.recipe_id, new.id,
      jsonb_build_object('titre', v_titre, 'extrait', left(new.body, 140)));
  elsif tg_table_name = 'cook_attempts' then
    if new.visible then
      perform private.notifier(v_auteur, new.user_id, 'cook_attempt', new.recipe_id, null,
        jsonb_build_object('titre', v_titre, 'extrait', left(coalesce(new.note, ''), 140)));
    end if;
  end if;

  return new;
end;
$fn$;

create or replace function private.notifier_abonnement()
returns trigger
language plpgsql
security definer
set search_path to ''
as $fn$
begin
  perform private.notifier(new.following_id, new.follower_id, 'follow');
  return new;
end;
$fn$;

revoke all on function private.notifier_action_recette() from public, anon, authenticated;
revoke all on function private.notifier_abonnement() from public, anon, authenticated;

drop trigger if exists trg_notifier_like on public.recipe_likes;
create trigger trg_notifier_like after insert on public.recipe_likes
  for each row execute function private.notifier_action_recette();

-- Une note modifiée ne renvoie pas de notification : seulement la première note.
drop trigger if exists trg_notifier_note on public.recipe_ratings;
create trigger trg_notifier_note after insert on public.recipe_ratings
  for each row execute function private.notifier_action_recette();

drop trigger if exists trg_notifier_commentaire on public.recipe_comments;
create trigger trg_notifier_commentaire after insert on public.recipe_comments
  for each row execute function private.notifier_action_recette();

drop trigger if exists trg_notifier_cuisinee on public.cook_attempts;
create trigger trg_notifier_cuisinee after insert on public.cook_attempts
  for each row execute function private.notifier_action_recette();

drop trigger if exists trg_notifier_abonnement on public.follows;
create trigger trg_notifier_abonnement after insert on public.follows
  for each row execute function private.notifier_abonnement();

-- ---------------------------------------------------------------------------
-- 2. Crédits du Chef IA
-- ---------------------------------------------------------------------------
-- Déroulement côté serveur : credits_ia() avant l'appel au modèle (refus si 0), puis
-- consommer_credit_ia() seulement si le modèle a répondu. Un appel raté ne coûte rien,
-- et aucune fonction ne permet de se « rembourser » soi-même.

-- Forfait de l'utilisateur connecté, remis à zéro au changement de mois.
create or replace function private.droits_ia_courants(p_user uuid)
returns public.entitlements
language plpgsql
security definer
set search_path to ''
as $fn$
declare
  v_droits public.entitlements%rowtype;
begin
  -- Forfait gratuit créé au besoin (comptes antérieurs au déclencheur d'inscription).
  insert into public.entitlements (user_id) values (p_user) on conflict (user_id) do nothing;

  select * into v_droits from public.entitlements e where e.user_id = p_user for update;

  if v_droits.period_end <= now() then
    update public.entitlements e
      set ai_credits_used = 0,
          period_start = date_trunc('month', now()),
          period_end = date_trunc('month', now()) + interval '1 month'
      where e.user_id = p_user
      returning * into v_droits;
  end if;

  return v_droits;
end;
$fn$;

revoke all on function private.droits_ia_courants(uuid) from public, anon, authenticated;

create or replace function public.credits_ia()
returns table (credits_restants integer, credits_mensuels integer, forfait text, fin_periode timestamptz)
language plpgsql
security definer
set search_path to ''
as $fn$
declare
  v_user uuid := auth.uid();
  v_droits public.entitlements%rowtype;
begin
  if v_user is null then
    raise exception 'Connexion requise' using errcode = '28000';
  end if;
  v_droits := private.droits_ia_courants(v_user);
  return query select greatest(v_droits.ai_monthly_credits - v_droits.ai_credits_used, 0),
    v_droits.ai_monthly_credits, v_droits.plan_code, v_droits.period_end;
end;
$fn$;

create or replace function public.consommer_credit_ia(
  p_fonction text,
  p_modele text,
  p_jetons_entree integer default 0,
  p_jetons_sortie integer default 0
) returns integer
language plpgsql
security definer
set search_path to ''
as $fn$
declare
  v_user uuid := auth.uid();
  v_droits public.entitlements%rowtype;
begin
  if v_user is null then
    raise exception 'Connexion requise' using errcode = '28000';
  end if;

  v_droits := private.droits_ia_courants(v_user);

  update public.entitlements e
    set ai_credits_used = e.ai_credits_used + 1
    where e.user_id = v_user
    returning * into v_droits;

  insert into public.ai_usage_events (user_id, feature, provider, model, input_tokens, output_tokens, credits_used)
  values (v_user, left(coalesce(p_fonction, 'chef'), 40), 'openai', left(coalesce(p_modele, 'inconnu'), 80),
    greatest(coalesce(p_jetons_entree, 0), 0), greatest(coalesce(p_jetons_sortie, 0), 0), 1);

  return greatest(v_droits.ai_monthly_credits - v_droits.ai_credits_used, 0);
end;
$fn$;

revoke all on function public.credits_ia() from public, anon;
revoke all on function public.consommer_credit_ia(text, text, integer, integer) from public, anon;
grant execute on function public.credits_ia() to authenticated;
grant execute on function public.consommer_credit_ia(text, text, integer, integer) to authenticated;
