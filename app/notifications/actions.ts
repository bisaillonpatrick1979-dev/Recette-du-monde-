"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

// Marque toutes les notifications de la personne connectée comme lues.
export async function markAllNotificationsRead() {
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  const userId = data?.claims?.sub;
  if (typeof userId !== "string") return;

  await supabase
    .from("notifications")
    .update({ read_at: new Date().toISOString() })
    .eq("user_id", userId)
    .is("read_at", null);

  revalidatePath("/notifications");
}

// Supprime les notifications déjà lues.
export async function clearReadNotifications() {
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  const userId = data?.claims?.sub;
  if (typeof userId !== "string") return;

  await supabase.from("notifications").delete().eq("user_id", userId).not("read_at", "is", null);

  revalidatePath("/notifications");
}
