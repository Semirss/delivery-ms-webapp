import { requireDriver } from '@/lib/driver-session';
import { moneyAmount, OperationsError, uuid } from '@/lib/driver-operations';
import { operationsFailure, operationsJson, operationsOptions } from '@/lib/operations-response';

export const OPTIONS = operationsOptions;
export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { db, driver } = await requireDriver(request);
    const id = uuid((await context.params).id);
    const { action, fare } = await request.json();
    if (action === 'quote') {
      const { data, error } = await db.rpc('driver_set_offer_fare', {
        p_delivery_id: id, p_driver_id: driver.id, p_fare: moneyAmount(fare),
      });
      if (error) throw new OperationsError(error.message, 409);
      return operationsJson(data);
    }
    if (!['accept','pickup','complete','reject','expire'].includes(action)) throw new OperationsError('Unknown delivery action.');
    const { data, error } = await db.rpc('driver_delivery_action', { p_delivery_id: id, p_driver_id: driver.id, p_action: action });
    if (error) throw new OperationsError(error.message, 409);
    return operationsJson(data);
  } catch (error) { return operationsFailure(error); }
}
