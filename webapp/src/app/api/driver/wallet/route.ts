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
    const key = uuid(body.idempotency_key);
    const amount = moneyAmount(Number(body.amount));
    const method = textValue(body.method, 20);
    let proof: { path: string; mime: string } | null = null;
    if (kind === 'topup') {
      if (method !== 'telebirr') throw new OperationsError('Choose Telebirr for a commission credit top-up.');
      const file = form?.get('proof');
      if (!(file instanceof File) || file.size === 0 || file.size > 5 * 1024 * 1024) {
        throw new OperationsError('Upload a payment screenshot under 5 MB.');
      }
      const bytes = new Uint8Array(await file.arrayBuffer());
      const type = imageType(bytes);
      const { data: existing, error: lookupError } = await db.from('driver_wallet_requests')
        .select('proof_path,proof_mime_type').eq('driver_id', driver.id).eq('idempotency_key', key).maybeSingle();
      if (lookupError) throw lookupError;
      if (existing?.proof_path) proof = { path: existing.proof_path, mime: existing.proof_mime_type };
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
      p_method: method, p_account_name: textValue(body.account_name),
      p_account_number: textValue(body.account_number, 60), p_bank_name: textValue(body.bank_name),
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
