"use client";
import { useCallback, useEffect, useState } from 'react';

type Delivery = { id: string; status: string; customer_name: string; delivery_fee: string | null;
  fee_collection_method?: string; commission_percent?: number | null; payment_confirmed_at?: string | null; pickup_location: string; dropoff_location: string };
type RequestRow = { id: string; kind: string; amount: number; method: string; status: string; account_name?: string;
  account_number?: string; bank_name?: string; external_reference?: string; review_note?: string; driver?: { name: string; phone: string } };
type FinanceData = {
  settings: { commission_percent: number; rate_note: string };
  totals: { owner_commission: number; driver_earnings_balance: number; commission_credit: number; reserved_cashout: number };
  requests: RequestRow[];
  wallets: { driver_id: string; commission_credit: number; reserved_credit: number; earnings_balance: number;
    reserved_cashout: number; driver?: { name: string } }[];
  ledger: { id: string; kind: string; created_at: string; credit_delta: number; earnings_delta: number; owner_commission: number; driver?: { name: string } }[];
};
const money = (value: unknown) => `${Number(value ?? 0).toFixed(2)} ETB`;
const field = 'w-full rounded-xl border border-neutral-300 bg-white px-3 py-2 text-sm text-neutral-900';

export default function FinanceManager({ deliveries, onUpdated }: { deliveries: Delivery[]; onUpdated: () => void }) {
  const [data,setData] = useState<FinanceData | null>(null);
  const [error,setError] = useState('');
  const [notice,setNotice] = useState('');
  const [rate,setRate] = useState('12');
  const [rateNote,setRateNote] = useState('');
  const [busy,setBusy] = useState(false);
  const [review,setReview] = useState<RequestRow | null>(null);
  const [reference,setReference] = useState('');
  const [note,setNote] = useState('');
  const [confirmed,setConfirmed] = useState(false);
  const [deliveryId,setDeliveryId] = useState('');
  const [fee,setFee] = useState('');
  const [collection,setCollection] = useState('cash');
  const [paymentReference,setPaymentReference] = useState('');
  const [paymentConfirmed,setPaymentConfirmed] = useState(false);
  const load = useCallback(async () => {
    try {
      const response = await fetch('/api/admin/finance',{ cache:'no-store' });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error);
      setData(payload); setRate(String(payload.settings.commission_percent)); setRateNote(payload.settings.rate_note); setError('');
    } catch (e) { setError(e instanceof Error ? e.message : 'Could not load finance.'); }
  },[]);
  useEffect(() => { void load(); },[load]);
  async function mutate(body: Record<string,unknown>, message: string) {
    if (busy) return false;
    setBusy(true); setError(''); setNotice('');
    try {
      const response = await fetch('/api/admin/finance',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
      const result = await response.json();
      if (!response.ok) throw new Error(result.error);
      setNotice(message); await load(); onUpdated(); return true;
    } catch (e) { setError(e instanceof Error ? e.message : 'Finance update failed.'); return false; }
    finally { setBusy(false); }
  }
  const selected = deliveries.find(d => d.id === deliveryId);
  const pending = data?.requests.filter(r => r.status === 'pending') ?? [];
  return <div className="space-y-6">
    <div className="rounded-2xl bg-amber-50 border border-amber-200 p-5 text-sm text-amber-900">
      <p className="font-extrabold">Payments use manual reconciliation</p>
      <p className="mt-1">No payment provider is connected. Send payouts through your business Telebirr or bank account, then reconcile the actual transaction here. A request alone never credits money or confirms a transfer.</p>
    </div>
    {error && <p role="alert" className="rounded-xl bg-red-50 p-4 text-red-700">{error}</p>}
    {notice && <p role="status" className="rounded-xl bg-emerald-50 p-4 text-emerald-700">{notice}</p>}
    {!data ? <button onClick={load} className="rounded-xl border px-4 py-2">Reload finance</button> : <>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {[
          ['Owner commission earned',data.totals.owner_commission],
          ['Driver wallet liabilities',data.totals.driver_earnings_balance],
          ['Prepaid commission credit',data.totals.commission_credit],
          ['Reserved cash outs',data.totals.reserved_cashout],
        ].map(([label,value]) => <div key={String(label)} className="rounded-2xl border bg-white p-5"><p className="text-xs font-bold text-neutral-500">{label}</p><p className="mt-2 text-2xl font-black text-neutral-900">{money(value)}</p></div>)}
      </div>
      <form className="rounded-2xl border bg-white p-5 space-y-3" onSubmit={e => {e.preventDefault(); void mutate({action:'commission',commission_percent:Number(rate),rate_note:rateNote},'Commission saved. Existing offers retain their quoted rate.');}}>
        <h3 className="font-extrabold text-neutral-900">Owner commission</h3>
        <p className="text-sm text-neutral-500">Applies to the delivery fee only. The rate is frozen when dispatch sends an offer. The initial 12% is provisional; RIDE’s current rate has not been verified.</p>
        <div className="grid gap-3 sm:grid-cols-[160px_1fr_auto]">
          <label className="text-sm font-bold">Percent<input aria-label="Commission percent" type="number" min="0" max="100" step="0.01" required value={rate} onChange={e => setRate(e.target.value)} className={field}/></label>
          <label className="text-sm font-bold">Rate note<input required maxLength={300} value={rateNote} onChange={e => setRateNote(e.target.value)} className={field}/></label>
          <button disabled={busy} className="self-end rounded-xl bg-blue-600 px-5 py-2 text-white font-bold disabled:opacity-50">Save commission</button>
        </div>
        <p className="text-xs text-neutral-500">200 ETB delivery → owner {money(200 * Number(rate || 0)/100)} · driver {money(200 - 200 * Number(rate || 0)/100)}</p>
      </form>
      <section className="rounded-2xl border bg-white p-5 space-y-4">
        <h3 className="font-extrabold">Delivery fee and payment collection</h3>
        <label className="block text-sm font-bold">Select delivery<select className={field} value={deliveryId} onChange={e => {
          const d = deliveries.find(d => d.id === e.target.value); setDeliveryId(e.target.value); setFee(String(d?.delivery_fee ?? '')); setCollection(d?.fee_collection_method ?? 'cash'); setPaymentReference(''); setPaymentConfirmed(false);
        }}><option value="">Choose a pending or active delivery</option>{deliveries.filter(d => ['Pending','Assigned','Accepted','Picked Up'].includes(d.status)).map(d => <option key={d.id} value={d.id}>{d.customer_name} · {d.pickup_location} → {d.dropoff_location} · {d.status}</option>)}</select></label>
        {selected?.status === 'Pending' && <form className="flex flex-wrap gap-3 items-end" onSubmit={e => {e.preventDefault();void mutate({action:'delivery_fee',delivery_id:deliveryId,delivery_fee:Number(fee),fee_collection_method:collection},'Delivery fee saved. You can now dispatch the offer.');}}>
          <label className="text-sm font-bold">Delivery fee (ETB)<input className={field} required type="number" min="0.01" max="1000000" step="0.01" value={fee} onChange={e => setFee(e.target.value)}/></label>
          <label className="text-sm font-bold">Who collects?<select className={field} value={collection} onChange={e => setCollection(e.target.value)}><option value="cash">Driver collects cash</option><option value="platform">Business collects payment</option></select></label>
          <button disabled={busy} className="rounded-xl bg-blue-600 px-4 py-2 text-white font-bold disabled:opacity-50">Save fee</button>
        </form>}
        {selected && selected.commission_percent == null && ['Assigned','Picked Up'].includes(selected.status) && <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 space-y-3">
          <p className="font-bold">Legacy delivery review</p><p className="text-sm">{selected.status === 'Assigned' ? 'Return only this old offer to dispatch so it can receive a new price quote and acceptance slider.' : 'Confirm this was a driver-collected cash job. Preserve its original driver earnings with zero retroactive commission. If the business collected payment, resolve this job with support instead.'}</p>
          <label className="flex gap-2 text-sm"><input type="checkbox" checked={paymentConfirmed} onChange={e => setPaymentConfirmed(e.target.checked)}/>I reviewed this specific delivery and its collection history.</label>
          <button disabled={busy || !paymentConfirmed} onClick={() => void mutate({action:'legacy_delivery',delivery_id:selected.id,confirmed:paymentConfirmed,mode:selected.status === 'Assigned' ? 'reoffer' : 'preserve_cash_earnings'},'This delivery was reviewed. Other active jobs were preserved.')} className="rounded-xl border px-4 py-2 font-bold disabled:opacity-50">{selected.status === 'Assigned' ? 'Return this offer for a new quote' : 'Preserve original cash earnings'}</button>
        </div>}
        {selected && selected.status !== 'Pending' && selected.fee_collection_method === 'platform' && !selected.payment_confirmed_at && <form className="space-y-3" onSubmit={e => {e.preventDefault();void mutate({action:'verify_payment',delivery_id:deliveryId,external_reference:paymentReference,confirmed:paymentConfirmed},'Received payment reconciled. The driver can complete delivery after pickup.');}}>
          <p className="text-sm">Verify the full {money(selected.delivery_fee)} delivery fee in your business account.</p>
          <input className={field} aria-label="Delivery payment reference" placeholder="Actual bank or Telebirr transaction reference" minLength={5} maxLength={150} required value={paymentReference} onChange={e => setPaymentReference(e.target.value)}/>
          <label className="flex gap-2 text-sm"><input type="checkbox" required checked={paymentConfirmed} onChange={e => setPaymentConfirmed(e.target.checked)}/>I verified the full delivery fee in the business account.</label>
          <button disabled={busy || !paymentConfirmed} className="rounded-xl bg-emerald-700 px-4 py-2 text-white font-bold disabled:opacity-50">Confirm received payment</button>
        </form>}
      </section>
      <section className="rounded-2xl border bg-white p-5 space-y-4">
        <div className="flex justify-between"><h3 className="font-extrabold">Wallet requests · {pending.length} pending</h3><button onClick={load} className="text-sm font-bold text-blue-600">Refresh</button></div>
        {pending.length === 0 && <p className="text-sm text-neutral-500">No pending wallet requests.</p>}
        {pending.map(r => <div key={r.id} className="rounded-xl border p-4 flex flex-wrap gap-4 justify-between items-center"><div><p className="font-bold">{r.driver?.name} · {r.kind === 'cashout' ? 'Cash out' : 'Credit top-up'} · {money(r.amount)}</p><p className="text-sm text-neutral-500">{r.method} · {r.driver?.phone}{r.account_number ? ` · ${r.bank_name || 'Telebirr'} / ${r.account_name} / ${r.account_number}` : ''}</p></div><button disabled={busy} onClick={() => {setReview(r);setReference('');setNote('');setConfirmed(false);}} className="rounded-xl border px-4 py-2 text-sm font-bold">Review</button></div>)}
        {review && <form className="rounded-xl bg-neutral-50 p-4 space-y-3" onSubmit={async e => {e.preventDefault();if(await mutate({action:'review',request_id:review.id,approve:true,external_reference:reference,review_note:note},'Payment reconciled and wallet updated.'))setReview(null);}}>
          <p className="font-bold">{review.driver?.name} · {review.kind} · {money(review.amount)}</p>
          <p className="text-sm">{review.kind === 'cashout' ? 'Send the payout first, verify its final success, then enter the transaction reference.' : 'Verify that the driver’s top-up payment has reached the business account before adding credit.'}</p>
          <label className="block text-sm">Actual transaction reference<input className={field} minLength={5} maxLength={150} required value={reference} onChange={e => setReference(e.target.value)}/></label>
          <label className="block text-sm">Review note<textarea className={field} required minLength={3} maxLength={500} value={note} onChange={e => setNote(e.target.value)}/></label>
          <label className="flex gap-2 text-sm"><input type="checkbox" required checked={confirmed} onChange={e => setConfirmed(e.target.checked)}/>I independently verified the account, amount and completed transaction.</label>
          <div className="flex flex-wrap gap-2"><button disabled={busy || !confirmed} className="rounded-xl bg-emerald-700 px-4 py-2 text-white font-bold disabled:opacity-50">Reconcile completed payment</button>
            <button type="button" disabled={busy || note.trim().length < 3} onClick={async () => {if(await mutate({action:'review',request_id:review.id,approve:false,review_note:note},'Request rejected. Any reserved cash-out amount was released.'))setReview(null);}} className="rounded-xl border px-4 py-2 font-bold disabled:opacity-50">Reject with note</button>
            <button type="button" disabled={busy} onClick={() => setReview(null)} className="px-4 py-2">Close</button></div>
        </form>}
        <details><summary className="cursor-pointer text-sm font-bold">Recent completed and rejected requests</summary>{data.requests.filter(r => r.status !== 'pending').map(r => <p key={r.id} className="py-2 text-sm border-b">{r.driver?.name} · {r.kind} · {money(r.amount)} · {r.status} · {r.external_reference || r.review_note}</p>)}</details>
      </section>
      <section className="rounded-2xl border bg-white p-5 overflow-x-auto"><h3 className="font-extrabold mb-4">Driver balances</h3><table className="w-full text-sm text-left"><thead><tr><th>Driver</th><th>Credit available</th><th>Earnings available</th><th>Cash out reserved</th></tr></thead><tbody>{data.wallets.map(w => <tr key={w.driver_id} className="border-t"><td className="py-3 font-bold">{w.driver?.name}</td><td>{money(Number(w.commission_credit)-Number(w.reserved_credit))}</td><td>{money(Number(w.earnings_balance)-Number(w.reserved_cashout))}</td><td>{money(w.reserved_cashout)}</td></tr>)}</tbody></table></section>
      <details className="rounded-2xl border bg-white p-5"><summary className="font-extrabold cursor-pointer">Recent ledger activity (latest 100)</summary>{data.ledger.map(e => <p key={e.id} className="py-3 border-b text-sm">{new Date(e.created_at).toLocaleString()} · {e.driver?.name} · {e.kind.replaceAll('_',' ')} · credit {money(e.credit_delta)} · earnings {money(e.earnings_delta)} · owner {money(e.owner_commission)}</p>)}</details>
    </>}
  </div>;
}
