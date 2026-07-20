export function normalizeEthiopianPhone(value: unknown): string {
  const digits = String(value ?? "").replace(/\D/g, "");

  if (!digits) return "";

  if (
    digits.length === 12 &&
    digits.startsWith("251") &&
    ["7", "9"].includes(digits.charAt(3))
  ) {
    return `0${digits.slice(3)}`;
  }

  if (digits.length === 9 && ["7", "9"].includes(digits.charAt(0))) {
    return `0${digits}`;
  }

  if (
    digits.length === 10 &&
    digits.startsWith("0") &&
    ["7", "9"].includes(digits.charAt(1))
  ) {
    return digits;
  }

  return digits;
}

export function phoneSearchCandidates(value: unknown): string[] {
  const raw = String(value ?? "").trim();
  const digits = raw.replace(/\D/g, "");
  const normalized = normalizeEthiopianPhone(value);
  const candidates = new Set<string>();

  [raw, digits, normalized].forEach((candidate) => {
    if (candidate) candidates.add(candidate);
  });

  if (
    normalized.length === 10 &&
    normalized.startsWith("0") &&
    ["7", "9"].includes(normalized.charAt(1))
  ) {
    candidates.add(`251${normalized.slice(1)}`);
    candidates.add(`+251${normalized.slice(1)}`);
  }

  return Array.from(candidates);
}
