export const CONTINENTS = {
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
  "north-america": {
    label: "Amérique du Nord",
    codes: [
      "CA", "US", "GL", "BM", "MX", "GT", "BZ", "HN", "SV", "NI", "CR", "PA",
      "CU", "DO", "HT", "JM", "BS", "BB", "TT", "GD", "LC", "VC", "AG", "DM",
      "KN",
    ],
  },
  "south-america": {
    label: "Amérique du Sud",
    codes: ["CO", "VE", "GY", "SR", "EC", "PE", "BO", "BR", "PY", "UY", "AR", "CL"],
  },
  antarctica: {
    label: "Antarctique",
    codes: ["AQ"],
  },
  asia: {
    label: "Asie",
    codes: [
      "AF", "AM", "AZ", "BH", "BD", "BT", "BN", "KH", "CN", "GE", "IN", "ID",
      "IR", "IQ", "IL", "JP", "JO", "KZ", "KW", "KG", "LA", "LB", "MY", "MV",
      "MN", "MM", "NP", "KP", "KR", "OM", "PK", "PS", "PH", "QA", "SA", "SG",
      "LK", "SY", "TW", "TJ", "TH", "TL", "TR", "TM", "AE", "UZ", "VN", "YE",
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
  oceania: {
    label: "Océanie",
    codes: ["AU", "FJ", "KI", "MH", "FM", "NR", "NZ", "PW", "PG", "WS", "SB", "TO", "TV", "VU"],
  },
} as const;

export type ContinentKey = keyof typeof CONTINENTS;

export function isContinentKey(value: string): value is ContinentKey {
  return value in CONTINENTS;
}
