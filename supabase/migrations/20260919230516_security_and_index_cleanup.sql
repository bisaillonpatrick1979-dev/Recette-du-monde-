revoke execute on function public.rls_auto_enable() from public, anon, authenticated;

create policy billing_accounts_no_client_access on public.billing_accounts
for all to anon, authenticated
using (false)
with check (false);

create index content_reports_recipe_id_idx on public.content_reports(recipe_id);
create index content_reports_comment_id_idx on public.content_reports(comment_id);
create index content_reports_reported_user_id_idx on public.content_reports(reported_user_id);
create index cook_attempts_user_id_idx on public.cook_attempts(user_id);
create index notifications_actor_id_idx on public.notifications(actor_id);
create index notifications_recipe_id_idx on public.notifications(recipe_id);
create index notifications_comment_id_idx on public.notifications(comment_id);
create index recipe_comments_parent_comment_id_idx on public.recipe_comments(parent_comment_id);
create index recipe_likes_user_id_idx on public.recipe_likes(user_id);
create index recipe_ratings_user_id_idx on public.recipe_ratings(user_id);
create index user_blocks_blocked_id_idx on public.user_blocks(blocked_id);
