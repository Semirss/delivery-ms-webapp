import { requireDriver } from '@/lib/driver-session';
import { operationsFailure, operationsJson, operationsOptions } from '@/lib/operations-response';

export const dynamic = 'force-dynamic';
export const OPTIONS = operationsOptions;

const profileFields = [
  'id',
  'name',
  'phone',
  'status',
  'availability_paused',
  'is_active',
  'approval_status',
  'last_location_update',
  'working_radius_km',
  'notifications_enabled',
  'vehicle_type',
] as const;

export async function GET(request: Request) {
  try {
    const { driver } = await requireDriver(request);
    const profile = Object.fromEntries(
      profileFields.map((field) => [field, driver[field]]),
    );
    return operationsJson(profile);
  } catch (error) {
    return operationsFailure(error);
  }
}
