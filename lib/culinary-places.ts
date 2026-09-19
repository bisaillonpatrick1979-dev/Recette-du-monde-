export type CulinaryPlaceType = "country" | "region" | "island" | "city" | "locality";

export type CulinaryPlace = {
  id: string;
  slug: string;
  name: string;
  countryCode: string;
  placeType: CulinaryPlaceType;
  parentId: string | null;
  longitude: number;
  latitude: number;
  zoom: number;
  summary: string | null;
};

export type AtlasRecipe = {
  id: string;
  title: string;
  description: string | null;
  category: string | null;
  coverImagePath: string | null;
  placeId: string;
};

export const levelLabels: Record<CulinaryPlaceType, string> = {
  country: "Pays",
  region: "Région",
  island: "Île",
  city: "Ville",
  locality: "Localité",
};
