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
  coverImageUrl: string | null;
  placeId: string;
};

export type AtlasSpecialty = {
  id: string;
  placeId: string;
  recipeId: string | null;
  name: string;
  description: string | null;
  originNote: string | null;
  isSignature: boolean;
  sortOrder: number;
};

export type AtlasPlaceImage = {
  id: string;
  placeId: string;
  url: string;
  altText: string | null;
  caption: string | null;
  sourceType: "external_licensed" | "generated" | "user_uploaded";
  attributionText: string | null;
  sourcePageUrl: string | null;
  isPrimary: boolean;
};

export const levelLabels: Record<CulinaryPlaceType, string> = {
  country: "Pays",
  region: "Région",
  island: "Île",
  city: "Ville",
  locality: "Localité",
};
