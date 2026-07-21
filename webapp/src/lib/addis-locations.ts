export type AddisNeighborhood = {
  name: string;
  lat: number;
  lng: number;
  aliases: string[];
};

export const ADDIS_NEIGHBORHOODS: AddisNeighborhood[] = [
  { name: "Bole", lat: 8.9947, lng: 38.7891, aliases: ["bole road", "edna mall"] },
  { name: "Bole Atlas", lat: 8.9979, lng: 38.7815, aliases: ["atlas", "atlas hotel"] },
  { name: "Bole Medhanialem", lat: 8.9974, lng: 38.7866, aliases: ["bole medhanealem", "medhanialem", "edna"] },
  { name: "Bole Michael", lat: 8.9829, lng: 38.7888, aliases: ["bole mikhael", "bole mikael"] },
  { name: "Bole Bulbula", lat: 8.9256, lng: 38.7856, aliases: ["bulbula"] },
  { name: "Bole Arabsa", lat: 8.9184, lng: 38.8347, aliases: ["arabsa", "arabssa"] },
  { name: "CMC", lat: 9.0272, lng: 38.8429, aliases: ["cmc michael", "cmc square"] },
  { name: "Gurd Shola", lat: 9.0223, lng: 38.814, aliases: ["gurdi shola", "gurdshola"] },
  { name: "Piassa", lat: 9.0369, lng: 38.7524, aliases: ["piazza", "arada"] },
  { name: "Kazanchis", lat: 9.0133, lng: 38.7652, aliases: ["kasanchis"] },
  { name: "Meskel Square", lat: 9.0104, lng: 38.7612, aliases: ["meskel", "stadium"] },
  { name: "Gotera", lat: 8.9964, lng: 38.7665, aliases: ["gotera interchange"] },
  { name: "Summit", lat: 9.0311, lng: 38.8688, aliases: ["summit square", "summit mazoria"] },
  { name: "Hayat", lat: 9.025, lng: 38.85, aliases: ["hayat hospital", "yeka hayat"] },
  { name: "Ayat", lat: 9.0266, lng: 38.858, aliases: ["ayat real estate"] },
  { name: "Megenagna", lat: 9.0194, lng: 38.8005, aliases: ["megenagna taxi station"] },
  { name: "Haya Hulet 22", lat: 9.0069, lng: 38.7852, aliases: ["22", "haya hulet", "22 mazoria"] },
  { name: "Gerji", lat: 9.0104, lng: 38.8068, aliases: ["gerji mebrat hail", "gerji imperial"] },
  { name: "Jacros", lat: 9.0158, lng: 38.8285, aliases: ["jakros", "yekatit 12 square"] },
  { name: "Shola", lat: 9.0262, lng: 38.7956, aliases: ["shola market", "shola gebeya"] },
  { name: "Urael", lat: 9.0101, lng: 38.7749, aliases: ["ural", "urael church"] },
  { name: "Wollo Sefer", lat: 8.9989, lng: 38.7732, aliases: ["wello sefer", "bole wello sefer"] },
  { name: "Merkato", lat: 9.0277, lng: 38.7388, aliases: ["mercato", "autobus tera"] },
  { name: "Mexico Square", lat: 9.0097, lng: 38.7458, aliases: ["mexico", "mex"] },
  { name: "Lideta Square", lat: 9.0155, lng: 38.7344, aliases: ["ledeta", "lideta"] },
  { name: "Torhailoch Square", lat: 9.0125, lng: 38.7233, aliases: ["tor hayloch", "tor hailoch", "torhayloch"] },
  { name: "Old Airport", lat: 8.996, lng: 38.7291, aliases: ["airport area", "bisrate gabriel"] },
  { name: "Weyra Sefer", lat: 8.9955, lng: 38.7555, aliases: ["weira sefer"] },
  { name: "Lancha", lat: 8.9964, lng: 38.7466, aliases: ["lancia"] },
  { name: "Kera", lat: 8.9864, lng: 38.7477, aliases: ["kera roundabout"] },
  { name: "Sar Bet", lat: 8.9913, lng: 38.7328, aliases: ["sarbet"] },
  { name: "Mekanisa", lat: 8.9771, lng: 38.7288, aliases: ["mekanissa", "mekanisa abo"] },
  { name: "Lafto", lat: 8.9585, lng: 38.7404, aliases: ["nifas silk lafto", "nifas silk"] },
  { name: "Saris Abo", lat: 8.9711, lng: 38.7633, aliases: ["saris", "saris adey abeba"] },
  { name: "Kality Menaharia", lat: 8.8955, lng: 38.7583, aliases: ["kaliti", "kality"] },
  { name: "Lebu", lat: 8.9645, lng: 38.7184, aliases: ["lebu mebrat", "lebu medhanialem"] },
  { name: "Jemo", lat: 8.9588, lng: 38.7246, aliases: ["jemo michael", "jemo condominium"] },
];

function normalizeLocation(value: string) {
  return value
    .toLowerCase()
    .replace(/addis ababa|ethiopia/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

function namesFor(place: AddisNeighborhood) {
  return [place.name, ...place.aliases].map(normalizeLocation);
}

export function findAddisNeighborhood(value: unknown) {
  if (typeof value !== "string") return null;
  const query = normalizeLocation(value);
  if (!query) return null;

  for (const place of ADDIS_NEIGHBORHOODS) {
    if (namesFor(place).some((name) => name === query)) return place;
  }

  for (const place of ADDIS_NEIGHBORHOODS) {
    if (namesFor(place).some((name) => query.includes(name) || name.includes(query))) {
      return place;
    }
  }

  return null;
}

export function suggestAddisNeighborhoods(value: unknown, limit = 8) {
  if (typeof value !== "string" || !value.trim()) {
    return ADDIS_NEIGHBORHOODS.slice(0, limit);
  }
  const query = normalizeLocation(value);
  const ranked = ADDIS_NEIGHBORHOODS.filter((place) =>
    namesFor(place).some((name) => name.includes(query) || query.includes(name))
  );
  return (ranked.length ? ranked : ADDIS_NEIGHBORHOODS).slice(0, limit);
}
