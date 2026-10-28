import { requireDriver } from '@/lib/driver-session';
import { moneyAmount, OperationsError, textValue, uuid } from '@/lib/driver-operations';
import { operationsFailure, operationsJson, operationsOptions } from '@/lib/operations-response';

export const OPTIONS = operationsOptions;
export async function POST(request: Request) {
  try {
    const { db, driver } = await requireDriver(request);
    const body = await request.json();
    const { data, error } = await db.rpc('request_driver_wallet', {
      p_driver_id: driver.id, p_kind: textValue(body.kind, 20), p_amount: moneyAmount(body.amount),
      p_method: textValue(body.method, 20), p_account_name: textValue(body.account_name),
      p_account_number: textValue(body.account_number, 60), p_bank_name: textValue(body.bank_name),
      p_key: uuid(body.idempotency_key),
    });
    if (error) throw new OperationsError(error.message, 409);
    return operationsJson(data, 201);
  } catch (error) { return operationsFailure(error); }
}
