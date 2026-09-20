import { NextRequest, NextResponse } from "next/server";
import { findWikimediaRecipeImage } from "@/lib/wikimedia-images";

export const runtime = "nodejs";

export async function GET(request: NextRequest) {
  const title = request.nextUrl.searchParams.get("title")?.trim() ?? "";
  const countryCode =
    request.nextUrl.searchParams.get("countryCode")?.trim().toUpperCase() ?? "";

  if (!title || title.length > 180 || (countryCode && !/^[A-Z]{2}$/.test(countryCode))) {
    return NextResponse.json({ error: "Paramètres invalides." }, { status: 400 });
  }

  try {
    const image = await findWikimediaRecipeImage({
      title,
      countryCode: countryCode || null,
    });

    const response = NextResponse.json(
      { image },
      { status: image ? 200 : 404 },
    );

    response.headers.set(
      "Cache-Control",
      "public, s-maxage=2592000, stale-while-revalidate=604800",
    );

    return response;
  } catch (error) {
    console.error("Unable to load Wikimedia recipe image", error);
    return NextResponse.json(
      { error: "Impossible de charger la photo de référence." },
      { status: 502 },
    );
  }
}
