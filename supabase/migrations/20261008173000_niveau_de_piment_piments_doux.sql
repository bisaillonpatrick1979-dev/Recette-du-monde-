-- Affine l'estimation du niveau de piment : les piments séchés doux et fumés (ñora, ancho, guajillo,
-- pasilla, mulato, cachemire, Alep, urfa, pimentón, chili powder) ne comptent que pour une note légère.
create or replace function private.ingredient_spice_points(p_text text)
returns integer
language sql
immutable
set search_path to ''
as $fn$
  select case
    when t ~ '(piment de la jama|allspice|pimienta de jamaica|piment doux|sweet chil|poivron|bell pepper|pimiento morr|paprika doux)' then 0
    when t ~ '(scotch bonnet|habanero|piri.?piri|peri.?peri|piment oiseau|bird.?s eye|\mnaga\M|carolina reaper|locoto|rocoto|wiri|madame jeanette|aj[ií] limo|ghost pepper|cabe rawit|prik kee noo|mitmita)' then 3
    when t ~ '(piment de cheiro|paprika fort|hot paprika|piment d.espelette|poivre du sichuan|sichuan pepper|curry fort|ñora|\mnora\M|\mancho\M|guajillo|pasilla|mulato|kashmiri|cachemire|piment d.alep|aleppo pepper|\murfa\M|\misot\M|pimentón|pimenton|chili powder|chile powder)' then 1
    when t ~ '(piment|chili|\mchile\M|chilli|guindilla|jalape|serrano|harissa|sambal|gochujang|gochugaru|cayenne|doubanjiang|sriracha|berbere|berbéré|chipotle|\maj[ií]\M|pepper sauce|hot sauce|sauce pimentée|\mpili|kochu|nam prik|árbol|piquín|pequin|tabasco|zhug|shatta|\mmala\M|\mớt\M|cabai|\mcabe\M|lombok|pul biber|chili flakes|red pepper flakes|crushed red pepper)' then
      case when t ~ '(facultatif|optional|opcional)' then 1 else 2 end
    else 0
  end
  from (select lower(coalesce(p_text, '')) as t) s;
$fn$;

update public.recipes r
  set spice_level = private.estimate_spice_level(r.id)
  where r.spice_level_source = 'auto'
    and r.spice_level is distinct from private.estimate_spice_level(r.id);
