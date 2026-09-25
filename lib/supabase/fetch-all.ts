// PostgREST plafonne chaque réponse (1000 lignes par défaut sur Supabase).
// Ce helper lit une requête page par page pour ne jamais tronquer l'atlas.
const PAGE_SIZE = 1000;

type PageResult<T> = PromiseLike<{
  data: T[] | null;
  error: { message: string } | null;
}>;

export async function fetchAllRows<T>(
  page: (from: number, to: number) => PageResult<T>,
  maxRows = 20000,
): Promise<{ data: T[]; error: string | null }> {
  const rows: T[] = [];

  for (let from = 0; from < maxRows; from += PAGE_SIZE) {
    const { data, error } = await page(from, from + PAGE_SIZE - 1);
    if (error) return { data: rows, error: error.message };
    rows.push(...(data ?? []));
    if (!data || data.length < PAGE_SIZE) break;
  }

  return { data: rows, error: null };
}
