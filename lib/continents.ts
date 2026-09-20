export const CONTINENTS = {
  "north-america": {
    label: "Amérique du Nord",
    codes: ["CA", "US", "GL", "BM"],
  },
  "latin-america": {
    label: "Amérique latine",
    codes: [
      "MX", "GT", "BZ", "HN", "SV", "NI", "CR", "PA", "CU", "DO", "HT", "JM",
      "BS", "BB", "TT", "GD", "LC", "VC", "AG", "DM", "KN", "CO", "VE", "GY",
      "SR", "EC", "PE", "BO", "BR", "PY", "UY", "AR", "CL",
    ],
  },
  europe: {
    label: "Europe",
    codes: [
      "AL", "AD", "AT", "BY", "BE", "BA", "BG", "HR", "CY", "CZ", "DK", "EE",
      "FI", "FR", "DE", "GR", "HU", "IS", "IE", "IT", "LV", "LI", "LT", "LU",
      "MT", "MD", "MC", "ME", "NL", "MK", "NO", "PL", "PT", "RO", "RU", "SM",
      "RS", "SK", "SI", "ES", "SE", "CH", "UA", "GB", "VA",
    ],
  },
  asia: {
    label: "Asie",
    codes: [
      "AF", "BD", "BT", "BN", "KH", "CN", "IN", "ID", "JP", "KZ", "KG", "LA",
      "MY", "MV", "MN", "MM", "NP", "KP", "KR", "PK", "PH", "SG", "LK", "TW",
      "TJ", "TH", "TL", "TM", "UZ", "VN",
    ],
  },
  africa: {
    label: "Afrique",
    codes: [
      "DZ", "AO", "BJ", "BW", "BF", "BI", "CV", "CM", "CF", "TD", "KM", "CG",
      "CD", "CI", "DJ", "EG", "GQ", "ER", "SZ", "ET", "GA", "GM", "GH", "GN",
      "GW", "KE", "LS", "LR", "LY", "MG", "MW", "ML", "MR", "MU", "MA", "MZ",
      "NA", "NE", "NG", "RW", "ST", "SN", "SC", "SL", "SO", "ZA", "SS", "SD",
      "TZ", "TG", "TN", "UG", "ZM", "ZW",
    ],
  },
  "middle-east": {
    label: "Moyen-Orient",
    codes: [
      "AM", "AZ", "BH", "GE", "IR", "IQ", "IL", "JO", "KW", "LB", "OM", "PS",
      "QA", "SA", "SY", "TR", "AE", "YE",
    ],
  },
  oceania: {
    label: "Océanie",
    codes: ["AU", "FJ", "KI", "MH", "FM", "NR", "NZ", "PW", "PG", "WS", "SB", "TO", "TV", "VU"],
  },
} as const;

export type ContinentKey = keyof typeof CONTINENTS;

export function isContinentKey(value: string): value is ContinentKey {
  return value in CONTINENTS;
}
