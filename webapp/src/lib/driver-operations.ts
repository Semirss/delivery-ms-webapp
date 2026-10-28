export class OperationsError extends Error {
  status: number;
  constructor(message: string, status = 400) { super(message); this.status = status; }
}

export function moneyAmount(value: unknown): number {
  const amount = typeof value === 'number' ? value : Number.NaN;
  if (!Number.isFinite(amount) || amount <= 0 || amount > 1_000_000 ||
      Math.abs(amount * 100 - Math.round(amount * 100)) > 0.000001) {
    throw new OperationsError('Enter a positive amount with at most two decimal places.');
  }
  return amount;
}

export function uuid(value: unknown): string {
  if (typeof value !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)) {
    throw new OperationsError('Invalid request identifier.');
  }
  return value;
}

export function textValue(value: unknown, max = 200): string {
  return typeof value === 'string' ? value.trim().slice(0, max) : '';
}

export function validatedLocation(body: Record<string, unknown>, now = Date.now()) {
  const { lat, lng, accuracy, observed_at } = body;
  const observed = typeof observed_at === 'string' ? Date.parse(observed_at) : Number.NaN;
  if (typeof lat !== 'number' || typeof lng !== 'number' || !Number.isFinite(lat) || !Number.isFinite(lng) ||
      lat < -90 || lat > 90 || lng < -180 || lng > 180 ||
      typeof accuracy !== 'number' || !Number.isFinite(accuracy) || accuracy < 0 || accuracy > 100 ||
      !Number.isFinite(observed) || observed > now + 10_000 || now - observed > 90_000) {
    throw new OperationsError('A fresh GPS reading with accuracy within 100 m is required.');
  }
  const heading = typeof body.heading === 'number' && Number.isFinite(body.heading) && body.heading >= 0 && body.heading < 360 ? body.heading : null;
  const speed = typeof body.speed === 'number' && Number.isFinite(body.speed) && body.speed >= 0 && body.speed <= 100 ? body.speed : null;
  return {
    current_lat: lat, current_lng: lng, location_accuracy_m: accuracy,
    location_heading: heading, location_speed_mps: speed,
    last_location_update: new Date(observed).toISOString(),
    location_received_at: new Date(now).toISOString(),
  };
}

export function gpsQuality(driver: {
  status?: string; current_lat?: number | null; current_lng?: number | null;
  last_location_update?: string | null; location_accuracy_m?: number | null;
}, now = Date.now()): 'live' | 'stale' | 'inaccurate' | 'offline' | 'unknown' {
  if (driver.status !== 'Online') return 'offline';
  const observed = Date.parse(driver.last_location_update ?? '');
  if (driver.current_lat == null || driver.current_lng == null || !Number.isFinite(driver.current_lat) ||
      !Number.isFinite(driver.current_lng) || Math.abs(driver.current_lat) > 90 || Math.abs(driver.current_lng) > 180 ||
      !Number.isFinite(observed) || driver.location_accuracy_m == null || !Number.isFinite(driver.location_accuracy_m)) return 'unknown';
  if (now - observed > 90_000 || observed > now + 10_000) return 'stale';
  if (driver.location_accuracy_m < 0 || driver.location_accuracy_m > 100) return 'inaccurate';
  return 'live';
}
