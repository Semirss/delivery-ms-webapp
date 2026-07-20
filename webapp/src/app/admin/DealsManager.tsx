"use client";

import { type ReactNode, useEffect, useMemo, useState } from "react";

type DealCardType = "hero" | "grid";

type AppDeal = {
  id?: string;
  title: string;
  subtitle?: string | null;
  body?: string | null;
  image_url?: string | null;
  card_type: DealCardType;
  accent_color: string;
  text_color: string;
  overlay_opacity: number;
  badge_text?: string | null;
  cta_label?: string | null;
  cta_url?: string | null;
  sort_order: number;
  is_active: boolean;
  starts_at?: string | null;
  ends_at?: string | null;
  created_at?: string;
  updated_at?: string;
};

const emptyDeal: AppDeal = {
  title: "",
  subtitle: "",
  body: "",
  image_url: "",
  card_type: "grid",
  accent_color: "#f2644d",
  text_color: "#ffffff",
  overlay_opacity: 0.52,
  badge_text: "",
  cta_label: "",
  cta_url: "",
  sort_order: 0,
  is_active: true,
  starts_at: "",
  ends_at: "",
};

async function fetchJson<T>(url: string, init?: RequestInit): Promise<T> {
  const response = await fetch(url, {
    cache: "no-store",
    credentials: "same-origin",
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(init?.headers || {}),
    },
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data?.error || `Deals API request failed (${response.status})`);
  return data as T;
}

async function uploadDealImage(file: File): Promise<string> {
  const formData = new FormData();
  formData.append("image", file);
  const response = await fetch("/api/deals/uploads", {
    method: "POST",
    body: formData,
    cache: "no-store",
    credentials: "same-origin",
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data?.error || "Image upload failed");
  if (!data?.url) throw new Error("Upload did not return an image URL");
  return data.url as string;
}

function messageFromError(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback;
}

function copyDeal(deal: AppDeal = emptyDeal): AppDeal {
  return { ...deal };
}

function sortableDeals(deals: AppDeal[]) {
  return [...deals].sort((a, b) => {
    if (a.sort_order !== b.sort_order) return a.sort_order - b.sort_order;
    return new Date(b.created_at || 0).getTime() - new Date(a.created_at || 0).getTime();
  });
}

function visibleInApp(deal: AppDeal) {
  if (!deal.is_active) return false;
  const now = Date.now();
  const startsAt = deal.starts_at ? new Date(deal.starts_at).getTime() : null;
  const endsAt = deal.ends_at ? new Date(deal.ends_at).getTime() : null;
  return (startsAt == null || startsAt <= now) && (endsAt == null || endsAt >= now);
}

function toDateTimeInput(value?: string | null) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value.slice(0, 16);
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return local.toISOString().slice(0, 16);
}

function scheduleLabel(deal: AppDeal) {
  if (!deal.starts_at && !deal.ends_at) return "Always visible";
  const start = deal.starts_at ? new Date(deal.starts_at).toLocaleString() : "Now";
  const end = deal.ends_at ? new Date(deal.ends_at).toLocaleString() : "No end";
  return `${start} to ${end}`;
}

export default function DealsManager() {
  const [deals, setDeals] = useState<AppDeal[]>([]);
  const [draft, setDraft] = useState<AppDeal>(copyDeal());
  const [editing, setEditing] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [formError, setFormError] = useState("");

  const sortedDeals = useMemo(() => sortableDeals(deals), [deals]);
  const liveDeals = useMemo(() => sortedDeals.filter(visibleInApp), [sortedDeals]);

  async function loadDeals() {
    setLoading(true);
    setError("");
    try {
      const data = await fetchJson<AppDeal[]>("/api/deals?includeInactive=1");
      setDeals(data);
    } catch (err: unknown) {
      setError(messageFromError(err, "Could not load deals"));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadDeals();
  }, []);

  function openNewDeal() {
    setDraft(copyDeal());
    setFormError("");
    setEditing(true);
  }

  function openDeal(deal: AppDeal) {
    setDraft(copyDeal(deal));
    setFormError("");
    setEditing(true);
  }

  function closeEditor() {
    setEditing(false);
    setFormError("");
  }

  async function saveDeal() {
    const payload = {
      ...draft,
      title: draft.title.trim(),
      subtitle: draft.subtitle?.trim() || "",
      body: draft.body?.trim() || "",
      image_url: draft.image_url?.trim() || "",
      badge_text: draft.badge_text?.trim() || "",
      cta_label: draft.cta_label?.trim() || "",
      cta_url: draft.cta_url?.trim() || "",
      accent_color: draft.accent_color || "#f2644d",
      text_color: draft.text_color || "#ffffff",
      overlay_opacity: Number(draft.overlay_opacity) || 0,
      sort_order: Math.trunc(Number(draft.sort_order) || 0),
      starts_at: draft.starts_at || null,
      ends_at: draft.ends_at || null,
    };

    if (!payload.title) {
      setFormError("Deal title is required.");
      return;
    }

    setSaving(true);
    setFormError("");
    try {
      const id = draft.id;
      await fetchJson<AppDeal>(id ? `/api/deals/${id}` : "/api/deals", {
        method: id ? "PATCH" : "POST",
        body: JSON.stringify(payload),
      });
      closeEditor();
      await loadDeals();
    } catch (err: unknown) {
      setFormError(messageFromError(err, "Could not save deal"));
    } finally {
      setSaving(false);
    }
  }

  async function deleteDeal(id: string) {
    if (!confirm("Delete this deal?")) return;
    setSaving(true);
    setError("");
    try {
      await fetchJson(`/api/deals/${id}`, { method: "DELETE" });
      await loadDeals();
    } catch (err: unknown) {
      setError(messageFromError(err, "Could not delete deal"));
    } finally {
      setSaving(false);
    }
  }

  async function toggleDeal(deal: AppDeal) {
    if (!deal.id) return;
    setDeals((current) => current.map((entry) => entry.id === deal.id ? { ...entry, is_active: !entry.is_active } : entry));
    try {
      await fetchJson<AppDeal>(`/api/deals/${deal.id}`, {
        method: "PATCH",
        body: JSON.stringify({ ...deal, is_active: !deal.is_active }),
      });
      await loadDeals();
    } catch (err: unknown) {
      setError(messageFromError(err, "Could not update deal"));
      await loadDeals();
    }
  }

  return (
    <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_380px]">
      <div className="space-y-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h2 className="text-2xl font-extrabold text-neutral-900">Deals</h2>
            <p className="mt-1 text-sm font-medium text-neutral-500">Control the Upcoming deals section shown in the client app.</p>
          </div>
          <div className="flex flex-wrap gap-2">
            <button
              onClick={() => void loadDeals()}
              className="rounded-xl border border-neutral-200 bg-white px-4 py-2 text-sm font-extrabold text-neutral-600 hover:border-blue-300"
            >
              Refresh
            </button>
            <button
              onClick={openNewDeal}
              className="rounded-xl bg-neutral-900 px-4 py-2 text-sm font-extrabold text-white shadow-sm hover:bg-black"
            >
              Add deal
            </button>
          </div>
        </div>

        {error && (
          <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-bold text-red-700">
            {error}
          </div>
        )}

        {loading ? (
          <div className="rounded-3xl border border-neutral-200 bg-white p-10 text-center font-bold text-neutral-500">
            Loading deals...
          </div>
        ) : (
          <DealsList
            deals={sortedDeals}
            saving={saving}
            onAdd={openNewDeal}
            onEdit={openDeal}
            onDelete={deleteDeal}
            onToggle={toggleDeal}
          />
        )}
      </div>

      <MobileDealsPreview deals={liveDeals} />

      {editing && (
        <EditorModal title={draft.id ? "Edit deal" : "Add deal"} onClose={closeEditor}>
          <DealForm
            draft={draft}
            setDraft={setDraft}
            saving={saving}
            error={formError}
            onSave={saveDeal}
            onCancel={closeEditor}
          />
        </EditorModal>
      )}
    </div>
  );
}

function DealsList({
  deals,
  saving,
  onAdd,
  onEdit,
  onDelete,
  onToggle,
}: {
  deals: AppDeal[];
  saving: boolean;
  onAdd: () => void;
  onEdit: (deal: AppDeal) => void;
  onDelete: (id: string) => void;
  onToggle: (deal: AppDeal) => void;
}) {
  return (
    <section className="space-y-4 rounded-3xl border border-neutral-200 bg-white p-5 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h3 className="text-lg font-extrabold text-neutral-900">Deal cards</h3>
        <button onClick={onAdd} className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-extrabold text-white hover:bg-blue-700">Add deal</button>
      </div>

      <div className="grid grid-cols-1 gap-3">
        {deals.map((deal) => (
          <div key={deal.id} className="overflow-hidden rounded-2xl border border-neutral-200 bg-white shadow-sm">
            <div className="grid gap-4 p-4 md:grid-cols-[112px_minmax(0,1fr)_auto] md:items-center">
              <div className="h-28 overflow-hidden rounded-xl bg-neutral-100">
                {deal.image_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={deal.image_url} alt="" className="h-full w-full object-cover" />
                ) : (
                  <div className="flex h-full w-full items-center justify-center text-xs font-extrabold text-neutral-400">No image</div>
                )}
              </div>
              <div className="min-w-0">
                <div className="flex flex-wrap items-center gap-2">
                  <p className="truncate text-lg font-extrabold text-neutral-900">{deal.title}</p>
                  <span className="rounded-full bg-neutral-100 px-2.5 py-1 text-[10px] font-extrabold uppercase tracking-wide text-neutral-600">{deal.card_type}</span>
                  <span className={`rounded-full px-2.5 py-1 text-[10px] font-extrabold uppercase tracking-wide ${deal.is_active ? "bg-emerald-50 text-emerald-700" : "bg-neutral-100 text-neutral-500"}`}>
                    {deal.is_active ? "Active" : "Hidden"}
                  </span>
                  {!visibleInApp(deal) && deal.is_active && (
                    <span className="rounded-full bg-amber-50 px-2.5 py-1 text-[10px] font-extrabold uppercase tracking-wide text-amber-700">Scheduled</span>
                  )}
                </div>
                <p className="mt-1 line-clamp-2 text-sm font-semibold text-neutral-600">{deal.subtitle || deal.body || "No supporting text"}</p>
                <div className="mt-3 grid gap-1 text-[11px] font-bold text-neutral-400 sm:grid-cols-2">
                  <p>Placement {deal.sort_order || 0}</p>
                  <p>Schedule: {scheduleLabel(deal)}</p>
                  <p className="flex items-center gap-2">
                    Accent <span className="inline-block h-3 w-3 rounded-full border border-neutral-200" style={{ backgroundColor: deal.accent_color }} />
                    {deal.accent_color}
                  </p>
                  <p>Overlay {Number(deal.overlay_opacity || 0).toFixed(2)}</p>
                </div>
              </div>
              <div className="flex shrink-0 flex-wrap gap-2 md:flex-col">
                <button disabled={saving} onClick={() => onEdit(deal)} className="rounded-lg bg-blue-50 px-3 py-1.5 text-xs font-extrabold text-blue-700 hover:bg-blue-100 disabled:opacity-50">Edit</button>
                <button disabled={saving} onClick={() => onToggle(deal)} className="rounded-lg bg-neutral-100 px-3 py-1.5 text-xs font-extrabold text-neutral-700 hover:bg-neutral-200 disabled:opacity-50">
                  {deal.is_active ? "Hide" : "Show"}
                </button>
                <button disabled={saving} onClick={() => deal.id && onDelete(deal.id)} className="rounded-lg bg-red-50 px-3 py-1.5 text-xs font-extrabold text-red-700 hover:bg-red-100 disabled:opacity-50">Delete</button>
              </div>
            </div>
          </div>
        ))}
        {deals.length === 0 && (
          <div className="rounded-2xl border border-dashed border-neutral-300 bg-neutral-50 p-10 text-center text-sm font-bold text-neutral-500">
            No deals yet. Add the hero and grid cards you want customers to see.
          </div>
        )}
      </div>
    </section>
  );
}

function DealForm({
  draft,
  setDraft,
  saving,
  error,
  onSave,
  onCancel,
}: {
  draft: AppDeal;
  setDraft: (value: AppDeal) => void;
  saving: boolean;
  error: string;
  onSave: () => void;
  onCancel: () => void;
}) {
  return (
    <div className="space-y-4">
      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-bold text-red-700">
          {error}
        </div>
      )}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <TextInput label="Title" value={draft.title} onChange={(title) => setDraft({ ...draft, title })} />
        <SelectInput
          label="Card type"
          value={draft.card_type}
          onChange={(card_type) => setDraft({ ...draft, card_type: (card_type || "grid") as DealCardType })}
          options={[
            { value: "hero", label: "Hero wide card" },
            { value: "grid", label: "Small grid card" },
          ]}
        />
      </div>
      <TextInput label="Subtitle" value={draft.subtitle || ""} onChange={(subtitle) => setDraft({ ...draft, subtitle })} />
      <TextAreaInput label="Body or internal note" value={draft.body || ""} onChange={(body) => setDraft({ ...draft, body })} />
      <ImageUploadInput label="Deal image" value={draft.image_url || ""} onChange={(image_url) => setDraft({ ...draft, image_url })} />

      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <ColorInput label="Accent color" value={draft.accent_color} onChange={(accent_color) => setDraft({ ...draft, accent_color })} />
        <ColorInput label="Text color" value={draft.text_color} onChange={(text_color) => setDraft({ ...draft, text_color })} />
        <NumberInput label="Overlay opacity" value={draft.overlay_opacity} step={0.05} min={0} max={0.95} onChange={(overlay_opacity) => setDraft({ ...draft, overlay_opacity: overlay_opacity ?? 0 })} />
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <TextInput label="Badge text" value={draft.badge_text || ""} onChange={(badge_text) => setDraft({ ...draft, badge_text })} />
        <TextInput label="CTA label" value={draft.cta_label || ""} onChange={(cta_label) => setDraft({ ...draft, cta_label })} />
      </div>
      <TextInput label="CTA URL" value={draft.cta_url || ""} onChange={(cta_url) => setDraft({ ...draft, cta_url })} />

      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <NumberInput label="Sort order" value={draft.sort_order} step={1} onChange={(sort_order) => setDraft({ ...draft, sort_order: sort_order ?? 0 })} />
        <DateTimeInput label="Starts at" value={draft.starts_at || ""} onChange={(starts_at) => setDraft({ ...draft, starts_at })} />
        <DateTimeInput label="Ends at" value={draft.ends_at || ""} onChange={(ends_at) => setDraft({ ...draft, ends_at })} />
      </div>

      <Toggle label="Show in app" checked={draft.is_active} onChange={(is_active) => setDraft({ ...draft, is_active })} />
      <div className="rounded-2xl border border-neutral-200 bg-neutral-50 p-4">
        <p className="mb-3 text-xs font-extrabold uppercase tracking-wide text-neutral-500">Preview</p>
        <DealPreviewCard deal={draft} size={draft.card_type} />
      </div>

      <div className="flex flex-col-reverse gap-3 border-t border-neutral-100 pt-4 sm:flex-row sm:justify-end">
        <button onClick={onCancel} disabled={saving} className="rounded-xl border border-neutral-200 px-4 py-2 text-sm font-extrabold text-neutral-600 hover:bg-neutral-50 disabled:opacity-50">Cancel</button>
        <button onClick={onSave} disabled={saving} className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-extrabold text-white hover:bg-blue-700 disabled:opacity-50">
          {saving ? "Saving..." : draft.id ? "Update deal" : "Create deal"}
        </button>
      </div>
    </div>
  );
}

function MobileDealsPreview({ deals }: { deals: AppDeal[] }) {
  const hero = deals.find((deal) => deal.card_type === "hero") || deals[0];
  const gridDeals = deals.filter((deal) => deal.id !== hero?.id).slice(0, 4);

  return (
    <aside className="xl:sticky xl:top-8 xl:self-start">
      <div className="rounded-[32px] border border-neutral-200 bg-neutral-950 p-3 shadow-2xl">
        <div className="overflow-hidden rounded-[24px] bg-white">
          <div className="px-5 pb-5 pt-6">
            <div className="mb-4 flex items-center justify-between">
              <div>
                <p className="text-[10px] font-extrabold uppercase tracking-[0.22em] text-neutral-400">Live app preview</p>
                <h3 className="text-2xl font-extrabold text-neutral-900">Upcoming</h3>
              </div>
              <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-[10px] font-extrabold text-emerald-700">{deals.length} live</span>
            </div>

            {hero ? (
              <DealPreviewCard deal={hero} size="hero" />
            ) : (
              <div className="flex h-36 items-center justify-center rounded-3xl border border-dashed border-neutral-300 bg-neutral-50 text-center text-sm font-bold text-neutral-500">
                No active deals are visible in the app.
              </div>
            )}

            {gridDeals.length > 0 && (
              <div className="mt-3 grid grid-cols-2 gap-3">
                {gridDeals.map((deal) => (
                  <DealPreviewCard key={deal.id || deal.title} deal={deal} size="grid" />
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </aside>
  );
}

function DealPreviewCard({ deal, size }: { deal: AppDeal; size: DealCardType }) {
  const isHero = size === "hero";
  const overlay = Math.min(0.95, Math.max(0, Number(deal.overlay_opacity) || 0));
  const textColor = deal.text_color || "#ffffff";

  return (
    <div
      className={`relative overflow-hidden rounded-[24px] bg-neutral-900 shadow-sm ${isHero ? "h-40" : "h-36"}`}
      style={{ color: textColor }}
    >
      {deal.image_url ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={deal.image_url} alt="" className="absolute inset-0 h-full w-full object-cover" />
      ) : (
        <div className="absolute inset-0 bg-gradient-to-br from-neutral-800 via-neutral-700 to-neutral-950" />
      )}
      <div className="absolute inset-0" style={{ background: `linear-gradient(90deg, rgba(0,0,0,${Math.min(0.98, overlay + 0.14)}) 0%, rgba(0,0,0,${overlay}) 48%, rgba(0,0,0,${Math.max(0.08, overlay - 0.28)}) 100%)` }} />
      {!isHero && <div className="absolute left-4 top-3 h-1 w-9 rounded-full" style={{ backgroundColor: deal.accent_color }} />}
      {deal.badge_text && (
        <div className="absolute right-3 top-3 rounded-full px-2 py-1 text-[10px] font-extrabold uppercase tracking-wide" style={{ backgroundColor: deal.accent_color, color: deal.text_color }}>
          {deal.badge_text}
        </div>
      )}
      <div className={`absolute inset-x-0 bottom-0 p-4 ${isHero ? "top-0 flex flex-col justify-center pr-24" : "pt-12"}`}>
        <p className={`${isHero ? "line-clamp-2 text-2xl" : "line-clamp-2 text-lg"} font-extrabold leading-tight`}>{deal.title || "Deal title"}</p>
        <p className={`mt-2 ${isHero ? "line-clamp-2 text-sm" : "line-clamp-2 text-xs"} font-semibold opacity-90`}>{deal.subtitle || deal.body || "Supporting text"}</p>
        {deal.cta_label && isHero && (
          <span className="mt-3 inline-flex w-max rounded-full px-3 py-1 text-[11px] font-extrabold" style={{ backgroundColor: deal.accent_color }}>
            {deal.cta_label}
          </span>
        )}
      </div>
    </div>
  );
}

function EditorModal({ title, children, onClose }: { title: string; children: ReactNode; onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <button className="absolute inset-0 bg-neutral-950/60 backdrop-blur-sm" onClick={onClose} aria-label="Close editor" />
      <div className="relative z-10 flex max-h-[90vh] w-full max-w-3xl flex-col overflow-hidden rounded-3xl bg-white shadow-2xl">
        <div className="flex items-center justify-between border-b border-neutral-100 px-6 py-4">
          <h3 className="text-xl font-extrabold text-neutral-900">{title}</h3>
          <button onClick={onClose} className="rounded-xl bg-neutral-100 px-3 py-1.5 text-sm font-extrabold text-neutral-600 hover:bg-neutral-200">Close</button>
        </div>
        <div className="overflow-y-auto p-6">
          {children}
        </div>
      </div>
    </div>
  );
}

function TextInput({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-extrabold text-neutral-600">{label}</span>
      <input value={value} onChange={(event) => onChange(event.target.value)} className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold text-neutral-800 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100" />
    </label>
  );
}

function TextAreaInput({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-extrabold text-neutral-600">{label}</span>
      <textarea value={value} onChange={(event) => onChange(event.target.value)} rows={3} className="w-full resize-y rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold text-neutral-800 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100" />
    </label>
  );
}

function SelectInput({ label, value, onChange, options }: { label: string; value: string; onChange: (value: string) => void; options: { value: string; label: string }[] }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-extrabold text-neutral-600">{label}</span>
      <select value={value} onChange={(event) => onChange(event.target.value)} className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold text-neutral-800 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100">
        {options.map((option) => (
          <option key={option.value} value={option.value}>{option.label}</option>
        ))}
      </select>
    </label>
  );
}

function ColorInput({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  const pickerValue = /^#[0-9a-f]{6}$/i.test(value) ? value : "#000000";

  return (
    <label className="block">
      <span className="mb-1 block text-xs font-extrabold text-neutral-600">{label}</span>
      <div className="flex rounded-xl border border-neutral-300 bg-neutral-50 p-1 focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">
        <input type="color" value={pickerValue} onChange={(event) => onChange(event.target.value)} className="h-9 w-12 rounded-lg border-0 bg-transparent" />
        <input value={value} onChange={(event) => onChange(event.target.value)} className="min-w-0 flex-1 bg-transparent px-2 text-sm font-semibold text-neutral-800 focus:outline-none" />
      </div>
    </label>
  );
}

function NumberInput({ label, value, onChange, step = 1, min, max }: { label: string; value: number | null; onChange: (value: number | null) => void; step?: number; min?: number; max?: number }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-extrabold text-neutral-600">{label}</span>
      <input
        type="number"
        value={value ?? ""}
        step={step}
        min={min}
        max={max}
        onChange={(event) => onChange(event.target.value === "" ? null : Number(event.target.value))}
        className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold text-neutral-800 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100"
      />
    </label>
  );
}

function DateTimeInput({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-extrabold text-neutral-600">{label}</span>
      <input
        type="datetime-local"
        value={toDateTimeInput(value)}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold text-neutral-800 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100"
      />
    </label>
  );
}

function Toggle({ label, checked, onChange }: { label: string; checked: boolean; onChange: (checked: boolean) => void }) {
  return (
    <label className="flex items-center justify-between gap-4 rounded-xl border border-neutral-200 bg-neutral-50 px-3 py-2">
      <span className="text-sm font-extrabold text-neutral-700">{label}</span>
      <button
        type="button"
        onClick={() => onChange(!checked)}
        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${checked ? "bg-emerald-500" : "bg-neutral-300"}`}
      >
        <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow-sm transition-transform ${checked ? "translate-x-6" : "translate-x-1"}`} />
      </button>
    </label>
  );
}

function ImageUploadInput({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState("");

  async function handleFile(file: File | undefined) {
    if (!file) return;
    setUploading(true);
    setError("");
    try {
      const url = await uploadDealImage(file);
      onChange(url);
    } catch (err: unknown) {
      setError(messageFromError(err, "Could not upload image"));
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="block">
      <span className="mb-1 block text-xs font-extrabold text-neutral-600">{label}</span>
      <div className="rounded-xl border border-neutral-300 bg-neutral-50 p-3">
        <div className="flex items-center gap-3">
          {value ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={value} alt="" className="h-16 w-16 rounded-lg bg-neutral-100 object-cover" />
          ) : (
            <div className="flex h-16 w-16 items-center justify-center rounded-lg border border-neutral-200 bg-white text-xs font-extrabold text-neutral-400">IMG</div>
          )}
          <div className="min-w-0 flex-1">
            <input
              type="file"
              accept="image/jpeg,image/png,image/webp"
              disabled={uploading}
              onChange={(event) => handleFile(event.target.files?.[0])}
              className="block w-full text-xs font-bold text-neutral-600 file:mr-3 file:rounded-lg file:border-0 file:bg-blue-600 file:px-3 file:py-2 file:text-xs file:font-extrabold file:text-white hover:file:bg-blue-700 disabled:opacity-60"
            />
            <input
              value={value}
              onChange={(event) => onChange(event.target.value)}
              placeholder="Image URL"
              className="mt-2 w-full rounded-lg border border-neutral-200 bg-white px-3 py-2 text-xs font-semibold text-neutral-700 focus:border-blue-500 focus:outline-none"
            />
          </div>
        </div>
        {uploading && <p className="mt-2 text-xs font-bold text-blue-600">Uploading...</p>}
        {error && <p className="mt-2 text-xs font-bold text-red-600">{error}</p>}
      </div>
    </div>
  );
}
