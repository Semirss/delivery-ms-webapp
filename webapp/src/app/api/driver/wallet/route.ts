import { requireDriver } from '@/lib/driver-session';
import { moneyAmount, OperationsError, textValue, uuid } from '@/lib/driver-operations';
import { operationsFailure, operationsJson, operationsOptions } from '@/lib/operations-response';

export const OPTIONS = operationsOptions;
const proofBucket = 'driver_topup_proofs';
function imageType(bytes: Uint8Array) {
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) return { mime: 'image/jpeg', ext: 'jpg' };
  if (bytes.length >= 8 && bytes.slice(0, 8).every((v, i) => v === [137,80,78,71,13,10,26,10][i])) return { mime: 'image/png', ext: 'png' };
  if (bytes.length >= 12 && String.fromCharCode(...bytes.slice(0, 4)) === 'RIFF' && String.fromCharCode(...bytes.slice(8, 12)) === 'WEBP') return { mime: 'image/webp', ext: 'webp' };
  throw new OperationsError('Choose a JPG, PNG or WebP payment screenshot.');
}
export async function POST(request: Request) {
  try {
    const { db, driver } = await requireDriver(request);
    const isMultipart = request.headers.get('content-type')?.startsWith('multipart/form-data') ?? false;
    const form = isMultipart ? await request.formData() : null;
    const body = form ? Object.fromEntries(form.entries()) : await request.json();
    const kind = textValue(body.kind, 20);
    if (kind !== 'topup') throw new OperationsError('Only commission credit top-ups are available.');
    const key = uuid(body.idempotency_key);
    const amount = moneyAmount(Number(body.amount));
    const method = textValue(body.method, 20);
    const { data: settings, error: settingsError } = await db.from('driver_operations_settings')
      .select('telebirr_phone,bank_enabled,bank_name,bank_account_name,bank_account_number')
      .eq('id', true).single();
    if (settingsError) throw settingsError;
    const { data: priorRequest, error: priorError } = await db.from('driver_wallet_requests')
      .select('method,account_name,account_number,bank_name,proof_path,proof_mime_type')
      .eq('driver_id', driver.id).eq('idempotency_key', key).maybeSingle();
    if (priorError) throw priorError;
    if (method !== 'telebirr' && method !== 'bank') throw new OperationsError('Choose Telebirr or bank transfer.');
    if (priorRequest && priorRequest.method !== method) {
      throw new OperationsError('This request was started with another payment method. Start a new top-up.');
    }
    if (method === 'bank' && !settings.bank_enabled && !priorRequest) {
      throw new OperationsError('Bank transfer is not available right now. Refresh your wallet.');
    }
    const accountName = priorRequest?.account_name ?? (method === 'bank' ? settings.bank_account_name : '');
    const accountNumber = priorRequest?.account_number ?? (method === 'bank' ? settings.bank_account_number : settings.telebirr_phone);
    const bankName = priorRequest?.bank_name ?? (method === 'bank' ? settings.bank_name : '');
    let proof: { path: string; mime: string } | null = null;
    if (kind === 'topup') {
      const file = form?.get('proof');
      if (!(file instanceof File) || file.size === 0 || file.size > 5 * 1024 * 1024) {
        throw new OperationsError('Upload a payment screenshot under 5 MB.');
      }
      const bytes = new Uint8Array(await file.arrayBuffer());
      const type = imageType(bytes);
      if (priorRequest?.proof_path) proof = { path: priorRequest.proof_path, mime: priorRequest.proof_mime_type };
      else {
        const path = `${driver.id}/${key}-${crypto.randomUUID()}.${type.ext}`;
        const { error: uploadError } = await db.storage.from(proofBucket).upload(path, bytes,
          { contentType: type.mime, upsert: false });
        if (uploadError) throw uploadError;
        proof = { path, mime: type.mime };
      }
    }
    const { data, error } = await db.rpc('request_driver_wallet', {
      p_driver_id: driver.id, p_kind: kind, p_amount: amount,
      p_method: method, p_account_name: accountName,
      p_account_number: accountNumber, p_bank_name: bankName,
      p_key: key,
    });
    if (error) throw new OperationsError(error.message, 409);
    if (proof && !data.proof_path) {
      const { data: updated, error: updateError } = await db.from('driver_wallet_requests')
        .update({ proof_path: proof.path, proof_mime_type: proof.mime })
        .eq('id', data.id).eq('driver_id', driver.id).eq('status', 'pending').is('proof_path', null)
        .select().maybeSingle();
      if (updateError) throw updateError;
      if (!updated) throw new OperationsError('Could not attach the screenshot. Please retry this request.', 409);
      return operationsJson(updated, 201);
    }
    return operationsJson(data, 201);
  } catch (error) { return operationsFailure(error); }
}
