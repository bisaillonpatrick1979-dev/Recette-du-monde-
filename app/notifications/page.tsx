import Link from "next/link";
import { redirect } from "next/navigation";
import { clearReadNotifications, markAllNotificationsRead } from "@/app/notifications/actions";
import type { Json } from "@/lib/supabase/database.types";
import { createClient } from "@/lib/supabase/server";

export const metadata = { title: "Notifications · Spoontrotter" };

const ICONS: Record<string, string> = {
  like: "♥",
  rating: "★",
  comment: "💬",
  follow: "👥",
  cook_attempt: "🍽",
  system: "📣",
};

function payloadText(payload: Json, key: string) {
  if (payload && typeof payload === "object" && !Array.isArray(payload)) {
    const value = (payload as Record<string, Json | undefined>)[key];
    if (typeof value === "string" || typeof value === "number") return String(value);
  }
  return null;
}

function describe(type: string, actor: string, payload: Json) {
  const title = payloadText(payload, "titre");
  const recipe = title ? `« ${title} »` : "votre recette";
  switch (type) {
    case "like":
      return `${actor} aime ${recipe}.`;
    case "rating":
      return `${actor} a donné ${payloadText(payload, "note") ?? "une note"} ★ à ${recipe}.`;
    case "comment":
      return `${actor} a commenté ${recipe}.`;
    case "follow":
      return `${actor} s’est abonné à vos recettes.`;
    case "cook_attempt":
      return `${actor} a cuisiné ${recipe} !`;
    default:
      return payloadText(payload, "message") ?? "Nouvelle notification.";
  }
}

function timeAgo(value: string) {
  const minutes = Math.round((Date.now() - new Date(value).getTime()) / 60000);
  if (minutes < 1) return "à l’instant";
  if (minutes < 60) return `il y a ${minutes} min`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `il y a ${hours} h`;
  const days = Math.round(hours / 24);
  if (days < 7) return `il y a ${days} j`;
  return new Date(value).toLocaleDateString("fr-CA", { day: "numeric", month: "short", year: "numeric" });
}

export default async function NotificationsPage() {
  const supabase = await createClient();
  const { data: claimsData } = await supabase.auth.getClaims();
  const userId = claimsData?.claims?.sub;
  if (typeof userId !== "string") redirect("/login");

  const { data: rows, error } = await supabase
    .from("notifications")
    .select("id,actor_id,type,recipe_id,payload,read_at,created_at")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(60);

  const notifications = rows ?? [];
  const actorIds = [...new Set(notifications.map((item) => item.actor_id).filter((id): id is string => Boolean(id)))];
  const { data: actors } = actorIds.length
    ? await supabase.from("profiles").select("id,display_name,username").in("id", actorIds)
    : { data: [] };
  const actorById = new Map((actors ?? []).map((actor) => [actor.id, actor.display_name || actor.username || "Un membre"]));
  const unread = notifications.filter((item) => !item.read_at).length;

  return (
    <main className="account-page">
      <div className="account-shell">
        <div className="account-topbar">
          <Link href="/" className="logo-lockup">
            <span className="logo-globe">🌍</span>
            <span><strong>Spoontrotter</strong><small>Notifications</small></span>
          </Link>
          <div className="recipe-top-actions">
            <Link href="/community" className="ghost-button">Communauté</Link>
            <Link href="/profile" className="ghost-button">Mon profil</Link>
          </div>
        </div>

        <section className="account-card">
          <div className="section-heading">
            <div>
              <span className="eyebrow">{unread ? `${unread} non lue${unread > 1 ? "s" : ""}` : "Tout est lu"}</span>
              <h2>Notifications</h2>
            </div>
            <div className="notification-actions">
              {unread ? (
                <form action={markAllNotificationsRead}>
                  <button className="ghost-button">Tout marquer comme lu</button>
                </form>
              ) : null}
              {notifications.length > unread ? (
                <form action={clearReadNotifications}>
                  <button className="ghost-button">Effacer les lues</button>
                </form>
              ) : null}
            </div>
          </div>

          {error ? (
            <p className="muted">Les notifications sont momentanément indisponibles.</p>
          ) : notifications.length ? (
            <ul className="notification-list">
              {notifications.map((item) => {
                const actor = item.actor_id ? actorById.get(item.actor_id) ?? "Un membre" : "Spoontrotter";
                const href =
                  item.type === "follow" && item.actor_id
                    ? `/cooks/${item.actor_id}`
                    : item.recipe_id
                      ? `/recipes/${item.recipe_id}`
                      : null;
                const excerpt = payloadText(item.payload, "extrait");
                const content = (
                  <>
                    <span className="notification-icon" aria-hidden="true">{ICONS[item.type] ?? "•"}</span>
                    <span className="notification-body">
                      <strong>{describe(item.type, actor, item.payload)}</strong>
                      {excerpt ? <span className="notification-excerpt">« {excerpt} »</span> : null}
                      <time dateTime={item.created_at}>{timeAgo(item.created_at)}</time>
                    </span>
                  </>
                );
                return (
                  <li key={item.id} className={item.read_at ? "notification-item" : "notification-item unread"}>
                    {href ? <Link href={href}>{content}</Link> : <div>{content}</div>}
                  </li>
                );
              })}
            </ul>
          ) : (
            <div className="community-empty">
              <span>🔔</span>
              <h2>Rien de neuf pour l’instant</h2>
              <p>
                Vous serez averti ici quand des membres aimeront, noteront, commenteront ou cuisineront vos recettes,
                et quand quelqu’un s’abonnera à votre profil.
              </p>
              <Link href="/publish" className="primary-button">Publier une recette</Link>
            </div>
          )}
        </section>
      </div>
    </main>
  );
}
