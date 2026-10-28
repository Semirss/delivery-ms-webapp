import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { PGlite } from '@electric-sql/pglite';
import { pgcrypto } from '@electric-sql/pglite/contrib/pgcrypto';
import { gpsQuality, moneyAmount, validatedLocation } from '../src/lib/driver-operations.ts';

let db;
const driver = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
async function row(sql, params = []) { return (await db.query(sql,params)).rows[0]; }
async function wallet() { return row('SELECT * FROM driver_wallets WHERE driver_id=$1',[driver]); }
async function delivery(fee=200,method='cash') {
  const d = await row("INSERT INTO deliveries(customer_name,customer_phone,pickup_location,dropoff_location,delivery_fee,fee_collection_method) VALUES ('Customer','0912345678','Bole','Piazza',$1,$2) RETURNING *",[fee,method]);
  return d.id;
}
async function assign(id) { return row('SELECT * FROM assign_delivery_offer($1,$2)',[id,driver]); }
async function action(id,kind,driverId=driver) { return row('SELECT * FROM driver_delivery_action($1,$2,$3)',[id,driverId,kind]); }
async function request(kind,amount,key=randomUUID(),method=kind==='convert'?'earnings':'telebirr',withProof=true) {
  const result = await row('SELECT * FROM request_driver_wallet($1,$2,$3,$4,$5,$6,$7,$8)',[driver,kind,amount,method,'Driver name','0912345678','',key]);
  if (kind === 'topup' && withProof) await db.query("UPDATE driver_wallet_requests SET proof_path=$1,proof_mime_type='image/png' WHERE id=$2 AND proof_path IS NULL", [`${driver}/${key}.png`,result.id]);
  return result;
}
async function review(id,approve=true,reference=randomUUID()) {
  return row('SELECT * FROM review_driver_wallet_request($1,$2,$3,$4)',[id,approve,reference,'Independently reconciled in business account']);
}
async function topup(amount=100) { const r = await request('topup',amount); await review(r.id); }
async function platformTrip(fee=200) {
  const id = await delivery(fee,'platform'); await assign(id); await action(id,'accept'); await action(id,'pickup');
  await row('SELECT * FROM confirm_delivery_payment($1,$2)',[id,randomUUID()]);
  await action(id,'complete'); return id;
}

before(async () => {
  db = new PGlite({extensions:{pgcrypto}});
  await db.exec("CREATE SCHEMA extensions; CREATE SCHEMA storage; CREATE TABLE storage.buckets(id text PRIMARY KEY,name text,public boolean,file_size_limit integer,allowed_mime_types text[]); CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role BYPASSRLS; CREATE PUBLICATION supabase_realtime; CREATE TABLE public.app_notifications(id uuid DEFAULT gen_random_uuid(),app text,recipient_id uuid,title text,body text,type text);");
  for (const name of ['schema.sql','schema_v2_updates.sql','schema_v3_updates.sql','schema_v15_driver_operations.sql','schema_v16_driver_topup_proofs.sql','schema_v17_browser_gps_accuracy.sql']) {
    await db.exec(await readFile(new URL(`../../supabase/${name}`,import.meta.url),'utf8'));
  }
});
after(async () => { await db?.close(); });
beforeEach(async () => {
  await db.exec('TRUNCATE app_notifications,driver_wallet_requests,driver_wallet_ledger,driver_wallets,driver_credentials,deliveries,drivers CASCADE; UPDATE driver_operations_settings SET commission_percent=12;');
  await db.query("INSERT INTO drivers(id,name,phone,password,approval_status,status,current_lat,current_lng,last_location_update,location_accuracy_m) VALUES ($1,'Driver','0912345678','secret123','Approved','Online',9,38,now(),12),($2,'Other','0998765432','otherpass','Approved','Online',9,38,now(),12)",[driver,other]);
});

test('top-up approval requires proof and notifies the driver once after review',async () => {
  const pending = await request('topup',100,randomUUID(),'telebirr',false);
  await assert.rejects(review(pending.id,true,'PAYMENT-PROOF-001'),/payment screenshot/);
  await db.query("UPDATE driver_wallet_requests SET proof_path='driver/proof.png',proof_mime_type='image/png' WHERE id=$1",[pending.id]);
  await review(pending.id,true,'PAYMENT-PROOF-001');
  await review(pending.id,true,'PAYMENT-PROOF-001');
  assert.equal((await row('SELECT count(*)::int AS count FROM app_notifications WHERE recipient_id=$1',[driver])).count,1);
  assert.equal(Number((await wallet()).commission_credit),100);
});

test('cash completion deducts commission credit once and never creates withdrawable cash earnings',async () => {
  await topup(); const id = await delivery(); const offer = await assign(id);
  assert.equal(Number(offer.owner_commission),24); assert.equal(Number(offer.driver_earnings),176);
  await action(id,'accept'); assert.equal(Number((await wallet()).reserved_credit),24);
  await action(id,'pickup'); await Promise.all([action(id,'complete'),action(id,'complete')]);
  const w = await wallet(); assert.equal(Number(w.commission_credit),76); assert.equal(Number(w.reserved_credit),0);
  assert.equal(Number(w.earnings_balance),0);
  assert.equal((await row('SELECT count(*)::int AS count FROM driver_wallet_ledger WHERE delivery_id=$1',[id])).count,1);
  assert.equal((await row('SELECT total_deliveries FROM drivers WHERE id=$1',[driver])).total_deliveries,1);
  const totals = await row('SELECT driver_finance_totals() AS totals'); assert.equal(Number(totals.totals.owner_commission),24);
});

test('offers freeze commission, round to cents, and preserve net plus owner equals fare',async () => {
  const id = await delivery(100.05); const offer = await assign(id);
  await db.exec('UPDATE driver_operations_settings SET commission_percent=25');
  await topup(); await action(id,'accept');
  assert.equal(Number(offer.owner_commission),12.01); assert.equal(Number(offer.driver_earnings),88.04);
  assert.equal(Number((await row('SELECT commission_percent FROM deliveries WHERE id=$1',[id])).commission_percent),12);
});

test('cash acceptance without enough credit fails with no reservation or accepted status',async () => {
  const id = await delivery(); await assign(id);
  await assert.rejects(action(id,'accept'),/Top up commission credit/);
  assert.equal((await row('SELECT status FROM deliveries WHERE id=$1',[id])).status,'Assigned');
  assert.equal(await wallet(),undefined);
});

test('offers reject the wrong driver, expired acceptance, skipped pickup and simultaneous assignments',async () => {
  await topup(); const id = await delivery(); await assign(id);
  await assert.rejects(action(id,'accept',other),/no longer assigned/);
  await assert.rejects(action(id,'pickup'),/Slide to accept/);
  await assert.rejects(assign(await delivery()),/already has an active/);
  await db.query("UPDATE deliveries SET offer_expires_at=now()-interval '1 second' WHERE id=$1",[id]);
  await assert.rejects(action(id,'accept'),/expired/);
  assert.equal((await action(id,'expire')).status,'Pending');
});

test('accepted jobs survive timeout and cancellation releases reserved credit',async () => {
  await topup(); const id = await delivery(); await assign(id); await action(id,'accept');
  await db.query("UPDATE deliveries SET assigned_at=now()-interval '10 minutes',offer_expires_at=now()-interval '8 minutes' WHERE id=$1",[id]);
  assert.equal((await row('SELECT * FROM cancel_delivery_offer($1,$2,true)',[id,'Offer timed out'])).status,'Accepted');
  await assert.rejects(row('SELECT * FROM driver_set_offline($1)',[driver]),/active delivery/);
  await row('SELECT * FROM cancel_delivery_offer($1,$2,false)',[id,'Customer requested cancellation']);
  assert.equal(Number((await wallet()).reserved_credit),0); assert.equal(Number((await wallet()).commission_credit),100);
});

test('business-collected earnings require reconciled payment before settlement',async () => {
  const id = await delivery(200,'platform'); await assign(id); await action(id,'accept'); await action(id,'pickup');
  await assert.rejects(action(id,'complete'),/verify the platform payment/);
  assert.equal(Number((await wallet()).earnings_balance),0);
  await row('SELECT * FROM confirm_delivery_payment($1,$2)',[id,'BANK-PAID-001']);
  await action(id,'complete'); assert.equal(Number((await wallet()).earnings_balance),176);
  assert.equal(Number((await wallet()).commission_credit),0);
});

test('cashouts reserve funds, reject overspending, and reconcile or release exactly once',async () => {
  await platformTrip(); const r = await request('cashout',100);
  assert.equal(Number((await wallet()).reserved_cashout),100);
  await assert.rejects(request('cashout',100),/Insufficient/);
  await review(r.id,false); await review(r.id,false);
  assert.equal(Number((await wallet()).reserved_cashout),0);
  const r2 = await request('cashout',50); await review(r2.id,true,'PAYOUT-SUCCESS-001'); await review(r2.id,true,'PAYOUT-SUCCESS-001');
  assert.equal(Number((await wallet()).earnings_balance),126); assert.equal(Number((await wallet()).reserved_cashout),0);
});

test('wallet retries are idempotent and payment references cannot be credited twice',async () => {
  const key = randomUUID(); const first = await request('topup',100,key); const retry = await request('topup',100,key);
  assert.equal(first.id,retry.id); await assert.rejects(request('topup',101,key),/different details/);
  await review(first.id,true,'TOPUP-UNIQUE-001');
  await assert.rejects(review(first.id,false),/already reviewed/);
  await assert.rejects(review(first.id,true,'DIFFERENT-REFERENCE'),/already reviewed/);
  const second = await request('topup',100); await assert.rejects(review(second.id,true,'TOPUP-UNIQUE-001'),/duplicate key/);
  assert.equal(Number((await wallet()).commission_credit),100);
  assert.equal((await row('SELECT status FROM driver_wallet_requests WHERE id=$1',[second.id])).status,'pending');
});

test('payment reference reuse across a trip and wallet topup rolls back',async () => {
  const id = await delivery(200,'platform'); await assign(id); await action(id,'accept');
  await row('SELECT * FROM confirm_delivery_payment($1,$2)',[id,'COMMON-PAYMENT-001']);
  const r = await request('topup',100); await assert.rejects(review(r.id,true,'COMMON-PAYMENT-001'),/already reconciled/);
  assert.equal(Number((await wallet()).commission_credit),0);
});

test('earnings conversion cannot spend reserved cashouts and is atomic on retries',async () => {
  await platformTrip(); await request('cashout',100); await assert.rejects(request('convert',100),/Insufficient/);
  const key=randomUUID(); await request('convert',50,key); await request('convert',50,key);
  assert.equal(Number((await wallet()).earnings_balance),126); assert.equal(Number((await wallet()).commission_credit),50);
});

test('credentials are hashed and hidden, and password changes invalidate session versions',async () => {
  const original=await row('SELECT password,auth_version FROM drivers WHERE id=$1',[driver]); assert.equal(original.password,null);
  const credential=await row('SELECT password_hash FROM driver_credentials WHERE driver_id=$1',[driver]);
  assert.match(credential.password_hash,/^\$2/); assert.notEqual(credential.password_hash,'secret123');
  assert.equal((await row('SELECT verify_driver_password($1,$2) AS ok',[driver,'secret123'])).ok,true);
  await db.query('UPDATE drivers SET password=$2 WHERE id=$1',[driver,'newpass123']);
  assert.equal((await row('SELECT verify_driver_password($1,$2) AS ok',[driver,'secret123'])).ok,false);
  assert.ok((await row('SELECT auth_version FROM drivers WHERE id=$1',[driver])).auth_version > original.auth_version);
});

test('anonymous and authenticated database roles cannot mutate money or forge completion',async () => {
  const id=await delivery();
  for(const role of ['anon','authenticated']) {
    await db.exec(`SET ROLE ${role}`);
    try {
      await assert.rejects(db.exec('SELECT * FROM driver_wallets'),/permission denied/);
      await assert.rejects(db.exec(`SELECT * FROM driver_delivery_action('${id}','${driver}','complete')`),/permission denied/);
      await assert.rejects(db.exec('SELECT * FROM driver_credentials'),/permission denied/);
      await assert.rejects(db.exec("UPDATE drivers SET current_lat=0"),/permission denied/);
      await assert.rejects(db.exec('UPDATE deliveries SET delivery_fee=99999'),/permission denied/);
      await assert.rejects(db.exec("UPDATE deliveries SET status='Delivered'"),/row-level security/);
    } finally { await db.exec('RESET ROLE'); }
  }
});

test('dispatch rejects stale, inaccurate, inactive and unapproved drivers',async () => {
  const id=await delivery();
  await db.query("UPDATE drivers SET last_location_update=now()-interval '2 minutes' WHERE id=$1",[driver]);
  await assert.rejects(assign(id),/fresh GPS/);
  await db.query('UPDATE drivers SET last_location_update=now(),location_accuracy_m=500 WHERE id=$1',[driver]);
  await assert.rejects(assign(id),/fresh GPS/);
  await db.query('UPDATE drivers SET location_accuracy_m=10,is_active=false WHERE id=$1',[driver]);
  await assert.rejects(assign(id),/approved, active/);
});

test('Chrome-size 150 m fixes can receive and accept offers, but 201 m cannot',async () => {
  await db.query('UPDATE drivers SET location_accuracy_m=150 WHERE id=$1',[driver]);
  const id=await delivery(); await assign(id); await topup();
  await db.query('UPDATE drivers SET location_accuracy_m=201 WHERE id=$1',[driver]);
  await assert.rejects(action(id,'accept'),/fresh, accurate GPS/);
  await db.query('UPDATE drivers SET location_accuracy_m=150 WHERE id=$1',[driver]);
  assert.equal((await action(id,'accept')).status,'Accepted');
});

test('going offline records an explicit driver pause',async () => {
  assert.equal((await row('SELECT availability_paused FROM drivers WHERE id=$1',[driver])).availability_paused,false);
  await row('SELECT * FROM driver_set_offline($1)',[driver]);
  const paused=await row('SELECT status,availability_paused FROM drivers WHERE id=$1',[driver]);
  assert.equal(paused.status,'Offline');
  assert.equal(paused.availability_paused,true);
});

test('account closure protects balances and anonymizes the driver after final cashout',async () => {
  await platformTrip();
  await assert.rejects(row('SELECT close_driver_account($1)',[driver]),/Settle wallet balances/);
  const r = await request('cashout',176); await review(r.id);
  await row('SELECT close_driver_account($1)',[driver]);
  const closed = await row('SELECT * FROM drivers WHERE id=$1',[driver]);
  assert.equal(closed.approval_status,'Closed'); assert.equal(closed.name,'Closed driver account');
  assert.equal(closed.current_lat,null); assert.equal(closed.email,null);
  assert.equal((await row('SELECT count(*)::int AS count FROM driver_credentials WHERE driver_id=$1',[driver])).count,0);
  assert.equal((await row('SELECT count(*)::int AS count FROM driver_wallet_ledger WHERE driver_id=$1',[driver])).count,2);
});

test('GPS validation preserves sensor time and rejects stale, future, inaccurate or invalid readings',() => {
  const now=Date.parse('2026-10-26T10:00:00Z');
  const fix={lat:0,lng:0,accuracy:12,observed_at:'2026-10-26T09:59:40Z'};
  assert.equal(validatedLocation(fix,now).last_location_update,'2026-10-26T09:59:40.000Z');
  assert.equal(validatedLocation({...fix,accuracy:150},now).location_accuracy_m,150);
  for(const invalid of [{...fix,lat:NaN},{...fix,lng:181},{...fix,accuracy:201},{...fix,accuracy:-1},
    {...fix,observed_at:'2026-10-26T09:58:00Z'},{...fix,observed_at:'2026-10-26T10:00:20Z'}]) {
    assert.throws(() => validatedLocation(invalid,now));
  }
  assert.equal(gpsQuality({status:'Online',current_lat:0,current_lng:0,last_location_update:fix.observed_at,location_accuracy_m:12},now),'live');
  assert.equal(gpsQuality({status:'Online',current_lat:0,current_lng:0,last_location_update:fix.observed_at,location_accuracy_m:150},now),'live');
  assert.equal(gpsQuality({status:'Online',current_lat:0,current_lng:0,last_location_update:fix.observed_at,location_accuracy_m:201},now),'inaccurate');
  assert.equal(gpsQuality({status:'Online',current_lat:9,current_lng:38,last_location_update:'2026-10-26T09:58:00Z',location_accuracy_m:12},now),'stale');
  for(const amount of [NaN,Infinity,0,-1,1.001,1000001,'100']) assert.throws(() => moneyAmount(amount));
});

test('legacy review changes only the explicitly reviewed job and preserves original cash earnings',async () => {
  const id = await delivery(); const untouched = await delivery();
  await db.query("UPDATE deliveries SET status='Picked Up',driver_id=$2 WHERE id=$1",[id,driver]);
  await row('SELECT * FROM review_legacy_driver_delivery($1,$2)',[id,'preserve_cash_earnings']);
  const prepared=await row('SELECT * FROM deliveries WHERE id=$1',[id]);
  assert.equal(Number(prepared.commission_percent),0); assert.equal(Number(prepared.driver_earnings),200);
  assert.equal((await row('SELECT commission_percent FROM deliveries WHERE id=$1',[untouched])).commission_percent,null);
  await action(id,'complete'); assert.equal(Number((await wallet()).commission_credit),0);
  assert.equal(Number((await wallet()).earnings_balance),0);
});

test('server offer expiry only returns unaccepted expired offers',async () => {
  await topup(); const id=await delivery(); await assign(id); await action(id,'accept');
  await db.query("UPDATE deliveries SET offer_expires_at=now()-interval '1 minute' WHERE id=$1",[id]);
  await row('SELECT expire_driver_offers($1)',[driver]);
  assert.equal((await row('SELECT status FROM deliveries WHERE id=$1',[id])).status,'Accepted');
  await row('SELECT * FROM cancel_delivery_offer($1,$2,false)',[id,'Admin cancelled test']);
  const next=await delivery(); await assign(next);
  await db.query("UPDATE deliveries SET offer_expires_at=now()-interval '1 minute' WHERE id=$1",[next]);
  await row('SELECT expire_driver_offers($1)',[driver]);
  assert.equal((await row('SELECT status FROM deliveries WHERE id=$1',[next])).status,'Pending');
});
