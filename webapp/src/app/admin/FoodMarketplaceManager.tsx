"use client";

import { type ReactNode, useEffect, useMemo, useState } from "react";

type FoodCategory = {
  id?: string;
  name: string;
  slug?: string;
  description?: string | null;
  parent_id?: string | null;
  icon_name?: string | null;
  sort_order: number;
  is_active: boolean;
};

type FoodRestaurant = {
  id?: string;
  name: string;
  slug?: string;
  subtitle?: string | null;
  phone?: string | null;
  image_url?: string | null;
  pickup_location?: string | null;
  pickup_lat?: number | null;
  pickup_lng?: number | null;
  is_featured: boolean;
  is_active: boolean;
  sort_order: number;
};

type FoodItem = {
  id?: string;
  title: string;
  description?: string | null;
  price: number;
  image_url?: string | null;
  seller_name: string;
  seller_phone: string;
  pickup_location?: string | null;
  pickup_lat?: number | null;
  pickup_lng?: number | null;
  category_id?: string | null;
  restaurant_id?: string | null;
  restaurant_name?: string | null;
  source_type: "client" | "restaurant" | "admin";
  is_featured: boolean;
  is_active: boolean;
  sort_order: number;
  category?: { name?: string };
  restaurant?: { name?: string };
};

type PaginatedFoodItems = {
  data: FoodItem[];
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
  countsByRestaurant?: Record<string, number>;
};

type EditorKind = "item" | "restaurant" | "category";

const FOOD_ITEMS_PAGE_SIZE = 8;

const emptyCategory: FoodCategory = {
  name: "",
  description: "",
  parent_id: null,
  icon_name: "",
  sort_order: 0,
  is_active: true,
};

const emptyRestaurant: FoodRestaurant = {
  name: "",
  subtitle: "",
  phone: "",
  image_url: "",
  pickup_location: "",
  pickup_lat: null,
  pickup_lng: null,
  is_featured: false,
  is_active: true,
  sort_order: 0,
};

const emptyItem: FoodItem = {
  title: "",
  description: "",
  price: 0,
  image_url: "",
  seller_name: "",
  seller_phone: "",
  pickup_location: "",
  pickup_lat: null,
  pickup_lng: null,
  category_id: null,
  restaurant_id: null,
  restaurant_name: "",
  source_type: "admin",
  is_featured: false,
  is_active: true,
  sort_order: 0,
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
  if (!response.ok) {
    throw new Error(data?.error || `Food API request failed (${response.status})`);
  }
  return data as T;
}

async function uploadFoodImage(file: File): Promise<string> {
  const formData = new FormData();
  formData.append("image", file);
  const response = await fetch("/api/food/uploads", {
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

function copyCategory(category: FoodCategory = emptyCategory): FoodCategory {
  return { ...category };
}

function copyRestaurant(restaurant: FoodRestaurant = emptyRestaurant): FoodRestaurant {
  return { ...restaurant };
}

function copyItem(item: FoodItem = emptyItem): FoodItem {
  return { ...item };
}

export default function FoodMarketplaceManager() {
  const [view, setView] = useState<EditorKind>("item");
  const [editor, setEditor] = useState<EditorKind | null>(null);
  const [categories, setCategories] = useState<FoodCategory[]>([]);
  const [restaurants, setRestaurants] = useState<FoodRestaurant[]>([]);
  const [items, setItems] = useState<FoodItem[]>([]);
  const [categoryDraft, setCategoryDraft] = useState<FoodCategory>(copyCategory());
  const [restaurantDraft, setRestaurantDraft] = useState<FoodRestaurant>(copyRestaurant());
  const [itemDraft, setItemDraft] = useState<FoodItem>(copyItem());
  const [restaurantFilterId, setRestaurantFilterId] = useState("");
  const [itemPage, setItemPage] = useState(1);
  const [itemTotal, setItemTotal] = useState(0);
  const [foodCountsByRestaurant, setFoodCountsByRestaurant] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [formError, setFormError] = useState("");

  const categoryById = useMemo(() => {
    return new Map(categories.map((category) => [category.id || "", category.name]));
  }, [categories]);

  const foodCountByRestaurant = useMemo(() => {
    return new Map(Object.entries(foodCountsByRestaurant));
  }, [foodCountsByRestaurant]);

  async function loadFoodData(options?: { page?: number; restaurantId?: string }) {
    const nextPage = options?.page ?? itemPage;
    const nextRestaurantId = options?.restaurantId ?? restaurantFilterId;
    const params = new URLSearchParams({
      page: String(nextPage),
      pageSize: String(FOOD_ITEMS_PAGE_SIZE),
    });
    if (nextRestaurantId) params.set("restaurant_id", nextRestaurantId);

    setLoading(true);
    setError("");
    try {
      const [nextCategories, nextRestaurants, nextItems] = await Promise.all([
        fetchJson<FoodCategory[]>("/api/food/categories"),
        fetchJson<FoodRestaurant[]>("/api/food/restaurants"),
        fetchJson<PaginatedFoodItems>(`/api/food/items?${params.toString()}`),
      ]);
      setCategories(nextCategories);
      setRestaurants(nextRestaurants);
      setItems(nextItems.data);
      setItemPage(nextItems.page);
      setItemTotal(nextItems.total);
      setFoodCountsByRestaurant(nextItems.countsByRestaurant || {});
    } catch (err: unknown) {
      setError(messageFromError(err, "Could not load food marketplace data"));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadFoodData({ page: 1, restaurantId: "" });
    // The initial load must run once; loadFoodData depends on live paging state for user actions.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function closeEditor() {
    setEditor(null);
    setFormError("");
  }

  function openNewEditor(kind: EditorKind) {
    setFormError("");
    if (kind === "category") setCategoryDraft(copyCategory());
    if (kind === "restaurant") setRestaurantDraft(copyRestaurant());
    if (kind === "item") setItemDraft(copyItem());
    setEditor(kind);
  }

  function openCategoryEditor(category: FoodCategory) {
    setCategoryDraft(copyCategory(category));
    setEditor("category");
  }

  function openRestaurantEditor(restaurant: FoodRestaurant) {
    setRestaurantDraft(copyRestaurant(restaurant));
    setEditor("restaurant");
  }

  function openItemEditor(item: FoodItem) {
    const linkedRestaurantName =
      item.restaurant?.name ||
      restaurants.find((restaurant) => restaurant.id === item.restaurant_id)?.name ||
      "";
    setItemDraft({
      ...copyItem(item),
      restaurant_name: item.restaurant_name || linkedRestaurantName,
    });
    setEditor("item");
  }

  function changeRestaurantFilter(restaurantId: string) {
    setRestaurantFilterId(restaurantId);
    setItemPage(1);
    void loadFoodData({ page: 1, restaurantId });
  }

  function changeItemPage(page: number) {
    const totalPages = Math.max(1, Math.ceil(itemTotal / FOOD_ITEMS_PAGE_SIZE));
    const nextPage = Math.min(Math.max(1, page), totalPages);
    setItemPage(nextPage);
    void loadFoodData({ page: nextPage, restaurantId: restaurantFilterId });
  }

  function itemDraftForRestaurant(restaurant: FoodRestaurant): FoodItem {
    return {
      ...copyItem(),
      seller_name: restaurant.name,
      seller_phone: restaurant.phone || "",
      pickup_location: restaurant.pickup_location || "",
      pickup_lat: restaurant.pickup_lat ?? null,
      pickup_lng: restaurant.pickup_lng ?? null,
      restaurant_id: restaurant.id || null,
      restaurant_name: restaurant.name,
      source_type: "restaurant",
    };
  }

  function startRestaurantListing(restaurant: FoodRestaurant) {
    setView("item");
    setItemDraft(itemDraftForRestaurant(restaurant));
    setEditor("item");
    changeRestaurantFilter(restaurant.id || "");
  }

  function applyRestaurantToItemDraft(restaurantId: string) {
    const restaurant = restaurants.find((entry) => entry.id === restaurantId);
    setItemDraft((draft) => {
      if (!restaurant) {
        return {
          ...draft,
          restaurant_id: restaurantId || null,
          restaurant_name: "",
        };
      }
      return {
        ...draft,
        seller_name: draft.seller_name || restaurant.name,
        seller_phone: draft.seller_phone || restaurant.phone || "",
        pickup_location: draft.pickup_location || restaurant.pickup_location || "",
        pickup_lat: draft.pickup_lat ?? restaurant.pickup_lat ?? null,
        pickup_lng: draft.pickup_lng ?? restaurant.pickup_lng ?? null,
        restaurant_id: restaurant.id || null,
        restaurant_name: restaurant.name,
        source_type: "restaurant",
      };
    });
  }

  async function saveCategory() {
    const payload = {
      ...categoryDraft,
      name: categoryDraft.name.trim(),
      slug: categoryDraft.slug?.trim() || undefined,
      description: categoryDraft.description?.trim() || "",
      icon_name: categoryDraft.icon_name?.trim() || "",
      parent_id: categoryDraft.parent_id || null,
      sort_order: Math.trunc(Number(categoryDraft.sort_order) || 0),
    };

    if (!payload.name) {
      setFormError("Category name is required.");
      return;
    }

    setSaving(true);
    setFormError("");
    try {
      const id = categoryDraft.id;
      await fetchJson<FoodCategory>(id ? `/api/food/categories/${id}` : "/api/food/categories", {
        method: id ? "PATCH" : "POST",
        body: JSON.stringify(payload),
      });
      closeEditor();
      setCategoryDraft(copyCategory());
      await loadFoodData({ page: itemPage, restaurantId: restaurantFilterId });
    } catch (err: unknown) {
      setFormError(messageFromError(err, "Could not save category"));
    } finally {
      setSaving(false);
    }
  }

  async function saveRestaurant() {
    const payload = {
      ...restaurantDraft,
      name: restaurantDraft.name.trim(),
      slug: restaurantDraft.slug?.trim() || undefined,
      subtitle: restaurantDraft.subtitle?.trim() || "",
      phone: restaurantDraft.phone?.trim() || "",
      image_url: restaurantDraft.image_url?.trim() || "",
      pickup_location: restaurantDraft.pickup_location?.trim() || "",
      pickup_lat: restaurantDraft.pickup_lat ?? null,
      pickup_lng: restaurantDraft.pickup_lng ?? null,
      sort_order: Math.trunc(Number(restaurantDraft.sort_order) || 0),
    };

    if (!payload.name) {
      setFormError("Restaurant name is required.");
      return;
    }

    setSaving(true);
    setFormError("");
    try {
      const id = restaurantDraft.id;
      await fetchJson<FoodRestaurant>(id ? `/api/food/restaurants/${id}` : "/api/food/restaurants", {
        method: id ? "PATCH" : "POST",
        body: JSON.stringify(payload),
      });
      closeEditor();
      setRestaurantDraft(copyRestaurant());
      await loadFoodData({ page: itemPage, restaurantId: restaurantFilterId });
    } catch (err: unknown) {
      setFormError(messageFromError(err, "Could not save restaurant"));
    } finally {
      setSaving(false);
    }
  }

  async function saveItem() {
    const payload = {
      title: itemDraft.title.trim(),
      description: itemDraft.description?.trim() || "",
      price: Number(itemDraft.price) || 0,
      image_url: itemDraft.image_url?.trim() || "",
      seller_name: itemDraft.seller_name.trim(),
      seller_phone: itemDraft.seller_phone.trim(),
      pickup_location: itemDraft.pickup_location?.trim() || "",
      pickup_lat: itemDraft.pickup_lat ?? null,
      pickup_lng: itemDraft.pickup_lng ?? null,
      category_id: itemDraft.category_id || null,
      restaurant_id: itemDraft.restaurant_id || null,
      restaurant_name: itemDraft.restaurant_name?.trim() || "",
      source_type: itemDraft.source_type || "admin",
      is_featured: itemDraft.is_featured,
      is_active: itemDraft.is_active,
      sort_order: Math.trunc(Number(itemDraft.sort_order) || 0),
    };

    if (!payload.title) {
      setFormError("Food title is required.");
      return;
    }
    if (!payload.seller_name || !payload.seller_phone) {
      setFormError("Seller name and seller phone are required.");
      return;
    }

    setSaving(true);
    setFormError("");
    try {
      const id = itemDraft.id;
      await fetchJson<FoodItem>(id ? `/api/food/items/${id}` : "/api/food/items", {
        method: id ? "PATCH" : "POST",
        body: JSON.stringify(payload),
      });
      closeEditor();
      setItemDraft(copyItem());
      await loadFoodData({
        page: id ? itemPage : 1,
        restaurantId: restaurantFilterId,
      });
    } catch (err: unknown) {
      setFormError(messageFromError(err, "Could not save food listing"));
    } finally {
      setSaving(false);
    }
  }

  async function deleteRow(path: string) {
    if (!confirm("Delete this food marketplace record?")) return;
    setSaving(true);
    try {
      await fetchJson(path, { method: "DELETE" });
      await loadFoodData({ page: itemPage, restaurantId: restaurantFilterId });
    } catch (err: unknown) {
      setError(messageFromError(err, "Could not delete record"));
    } finally {
      setSaving(false);
    }
  }

  const addLabel = view === "item" ? "Add listing" : view === "restaurant" ? "Add restaurant" : "Add category";

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 className="text-2xl font-extrabold text-neutral-900">Food Marketplace</h2>
          <p className="mt-1 text-sm font-medium text-neutral-500">Manage foods, restaurants, and categories without crowding the page.</p>
        </div>
        <div className="flex flex-wrap gap-2">
          {([
            ["item", "Listings"],
            ["restaurant", "Restaurants"],
            ["category", "Categories"],
          ] as const).map(([key, label]) => (
            <button
              key={key}
              onClick={() => setView(key)}
              className={`rounded-xl px-4 py-2 text-sm font-extrabold transition-all ${view === key ? "bg-blue-600 text-white shadow-sm" : "border border-neutral-200 bg-white text-neutral-600 hover:border-blue-300"}`}
            >
              {label}
            </button>
          ))}
          <button
            onClick={() => openNewEditor(view)}
            className="rounded-xl bg-neutral-900 px-4 py-2 text-sm font-extrabold text-white shadow-sm hover:bg-black"
          >
            {addLabel}
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
          Loading food marketplace...
        </div>
      ) : view === "category" ? (
        <CategoryList
          categories={categories}
          onAdd={() => openNewEditor("category")}
          onEdit={openCategoryEditor}
          onDelete={(id) => deleteRow(`/api/food/categories/${id}`)}
        />
      ) : view === "restaurant" ? (
        <RestaurantList
          restaurants={restaurants}
          foodCountByRestaurant={foodCountByRestaurant}
          onAdd={() => openNewEditor("restaurant")}
          onEdit={openRestaurantEditor}
          onAddFood={startRestaurantListing}
          onDelete={(id) => deleteRow(`/api/food/restaurants/${id}`)}
        />
      ) : (
        <ItemList
          items={items}
          restaurants={restaurants}
          categoryById={categoryById}
          restaurantFilterId={restaurantFilterId}
          itemPage={itemPage}
          itemPageSize={FOOD_ITEMS_PAGE_SIZE}
          itemTotal={itemTotal}
          onAdd={() => openNewEditor("item")}
          onEdit={openItemEditor}
          onDelete={(id) => deleteRow(`/api/food/items/${id}`)}
          onRestaurantFilterChange={changeRestaurantFilter}
          onPageChange={changeItemPage}
        />
      )}

      {editor === "category" && (
        <EditorModal title={categoryDraft.id ? "Edit category" : "Add category"} onClose={closeEditor}>
          <CategoryForm
            draft={categoryDraft}
            setDraft={setCategoryDraft}
            categories={categories}
            saving={saving}
            error={formError}
            onSave={saveCategory}
            onCancel={closeEditor}
          />
        </EditorModal>
      )}

      {editor === "restaurant" && (
        <EditorModal title={restaurantDraft.id ? "Edit restaurant" : "Add restaurant"} onClose={closeEditor}>
          <RestaurantForm
            draft={restaurantDraft}
            setDraft={setRestaurantDraft}
            saving={saving}
            error={formError}
            onSave={saveRestaurant}
            onCancel={closeEditor}
          />
        </EditorModal>
      )}

      {editor === "item" && (
        <EditorModal title={itemDraft.id ? "Edit food listing" : "Add food listing"} onClose={closeEditor}>
          <ItemForm
            draft={itemDraft}
            setDraft={setItemDraft}
            categories={categories}
            restaurants={restaurants}
            saving={saving}
            error={formError}
            onSave={saveItem}
            onRestaurantSelect={applyRestaurantToItemDraft}
            onCancel={closeEditor}
          />
        </EditorModal>
      )}
    </div>
  );
}

function CategoryList({
  categories,
  onAdd,
  onEdit,
  onDelete,
}: {
  categories: FoodCategory[];
  onAdd: () => void;
  onEdit: (category: FoodCategory) => void;
  onDelete: (id: string) => void;
}) {
  return (
    <Panel
      title="Categories"
      action={<button onClick={onAdd} className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-extrabold text-white hover:bg-blue-700">Add category</button>}
    >
      <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
        {categories.map((category) => (
          <RowCard key={category.id}>
            <div className="min-w-0">
              <p className="truncate font-extrabold text-neutral-900">{category.name}</p>
              <p className="text-xs text-neutral-500">{category.slug || "No slug"} {category.parent_id ? "- child category" : ""}</p>
              <p className="mt-1 text-[11px] font-bold text-neutral-400">
                Placement {category.sort_order || 0} - {category.is_active ? "Active" : "Hidden"}
              </p>
            </div>
            <RowActions onEdit={() => onEdit(category)} onDelete={() => category.id && onDelete(category.id)} />
          </RowCard>
        ))}
      </div>
    </Panel>
  );
}

function RestaurantList({
  restaurants,
  foodCountByRestaurant,
  onAdd,
  onEdit,
  onAddFood,
  onDelete,
}: {
  restaurants: FoodRestaurant[];
  foodCountByRestaurant: Map<string, number>;
  onAdd: () => void;
  onEdit: (restaurant: FoodRestaurant) => void;
  onAddFood: (restaurant: FoodRestaurant) => void;
  onDelete: (id: string) => void;
}) {
  return (
    <Panel
      title="Restaurants"
      action={<button onClick={onAdd} className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-extrabold text-white hover:bg-blue-700">Add restaurant</button>}
    >
      <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
        {restaurants.map((restaurant) => (
          <RowCard key={restaurant.id}>
            <div className="min-w-0">
              <p className="truncate font-extrabold text-neutral-900">{restaurant.name}</p>
              <p className="truncate text-xs text-neutral-500">{restaurant.subtitle || restaurant.phone || "Restaurant"}</p>
              <p className="mt-1 text-[11px] font-bold text-neutral-400">{foodCountByRestaurant.get(restaurant.id || "") || 0} foods listed</p>
              <p className="mt-1 text-[11px] font-bold text-neutral-400">
                Placement {restaurant.sort_order || 0} - {restaurant.is_featured ? "Featured" : "Standard"} - {restaurant.is_active ? "Active" : "Hidden"}
              </p>
            </div>
            <div className="flex shrink-0 flex-col gap-2 sm:flex-row">
              <button onClick={() => onAddFood(restaurant)} className="rounded-lg bg-emerald-50 px-3 py-1.5 text-xs font-extrabold text-emerald-700 hover:bg-emerald-100">Add food</button>
              <RowActions onEdit={() => onEdit(restaurant)} onDelete={() => restaurant.id && onDelete(restaurant.id)} />
            </div>
          </RowCard>
        ))}
      </div>
    </Panel>
  );
}

function ItemList({
  items,
  restaurants,
  categoryById,
  restaurantFilterId,
  itemPage,
  itemPageSize,
  itemTotal,
  onAdd,
  onEdit,
  onDelete,
  onRestaurantFilterChange,
  onPageChange,
}: {
  items: FoodItem[];
  restaurants: FoodRestaurant[];
  categoryById: Map<string, string>;
  restaurantFilterId: string;
  itemPage: number;
  itemPageSize: number;
  itemTotal: number;
  onAdd: () => void;
  onEdit: (item: FoodItem) => void;
  onDelete: (id: string) => void;
  onRestaurantFilterChange: (value: string) => void;
  onPageChange: (page: number) => void;
}) {
  const totalPages = Math.max(1, Math.ceil(itemTotal / itemPageSize));
  const firstVisible = itemTotal === 0 ? 0 : (itemPage - 1) * itemPageSize + 1;
  const lastVisible = Math.min(itemTotal, itemPage * itemPageSize);

  function restaurantLabel(item: FoodItem) {
    return item.restaurant?.name || item.restaurant_name || restaurants.find((restaurant) => restaurant.id === item.restaurant_id)?.name || "No restaurant";
  }

  return (
    <Panel
      title="Food listings"
      action={<button onClick={onAdd} className="rounded-xl bg-blue-600 px-4 py-2 text-sm font-extrabold text-white hover:bg-blue-700">Add listing</button>}
    >
      <div className="grid grid-cols-1 items-end gap-3 sm:grid-cols-[1fr_auto]">
        <SelectInput
          label="Show restaurant"
          value={restaurantFilterId}
          onChange={onRestaurantFilterChange}
          options={restaurants.map((restaurant) => ({ value: restaurant.id || "", label: restaurant.name }))}
        />
        <button onClick={() => onRestaurantFilterChange("")} className="rounded-xl border border-neutral-200 px-4 py-2 text-sm font-extrabold text-neutral-600 hover:bg-neutral-50">Show all</button>
      </div>
      <div className="flex flex-col gap-2 rounded-2xl border border-neutral-200 bg-neutral-50 px-4 py-3 text-sm font-bold text-neutral-600 sm:flex-row sm:items-center sm:justify-between">
        <span>{itemTotal === 0 ? "No listings found" : `Showing ${firstVisible}-${lastVisible} of ${itemTotal} listings`}</span>
        <span className="text-xs text-neutral-400">Page {itemPage} of {totalPages}</span>
      </div>
      <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
        {items.map((item) => (
          <div key={item.id} className="overflow-hidden rounded-2xl border border-neutral-200 bg-white shadow-sm">
            {item.image_url && (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={item.image_url} alt="" className="h-36 w-full bg-neutral-100 object-cover" />
            )}
            <div className="p-4">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="truncate font-extrabold text-neutral-900">{item.title}</p>
                  <p className="text-sm font-bold text-blue-600">{Number(item.price || 0).toLocaleString()} ETB</p>
                  <p className="truncate text-xs font-bold text-neutral-600">{restaurantLabel(item)}</p>
                  <p className="truncate text-xs text-neutral-500">{item.seller_name} - {item.seller_phone}</p>
                  {item.description && <p className="mt-2 line-clamp-2 text-xs text-neutral-500">{item.description}</p>}
                  <div className="mt-3 grid grid-cols-1 gap-1 text-[11px] font-bold text-neutral-400">
                    <p>{item.category?.name || categoryById.get(item.category_id || "") || "Uncategorized"} - {item.source_type}</p>
                    <p>Pickup: {item.pickup_location || "Not set"}</p>
                    <p>Map point: {item.pickup_lat ?? "not set"}, {item.pickup_lng ?? "not set"}</p>
                    <p>Placement {item.sort_order || 0} - {item.is_featured ? "Featured" : "Standard"} - {item.is_active ? "Active" : "Hidden"}</p>
                  </div>
                </div>
                <RowActions onEdit={() => onEdit(item)} onDelete={() => item.id && onDelete(item.id)} />
              </div>
            </div>
          </div>
        ))}
        {items.length === 0 && (
          <div className="col-span-full rounded-2xl border border-dashed border-neutral-300 bg-neutral-50 p-10 text-center text-sm font-bold text-neutral-500">
            No food listings match this restaurant filter.
          </div>
        )}
      </div>
      <PaginationControls page={itemPage} totalPages={totalPages} onPageChange={onPageChange} />
    </Panel>
  );
}

function CategoryForm({
  draft,
  setDraft,
  categories,
  saving,
  error,
  onSave,
  onCancel,
}: {
  draft: FoodCategory;
  setDraft: (value: FoodCategory) => void;
  categories: FoodCategory[];
  saving: boolean;
  error: string;
  onSave: () => void;
  onCancel: () => void;
}) {
  return (
    <FormGrid error={error}>
      <TextInput label="Name" value={draft.name} onChange={(name) => setDraft({ ...draft, name })} />
      <TextInput label="Slug" value={draft.slug || ""} onChange={(slug) => setDraft({ ...draft, slug })} />
      <TextAreaInput label="Description" value={draft.description || ""} onChange={(description) => setDraft({ ...draft, description })} />
      <TextInput label="Icon name" value={draft.icon_name || ""} onChange={(icon_name) => setDraft({ ...draft, icon_name })} />
      <SelectInput
        label="Parent category"
        value={draft.parent_id || ""}
        onChange={(parent_id) => setDraft({ ...draft, parent_id: parent_id || null })}
        options={categories.filter((category) => category.id !== draft.id).map((category) => ({ value: category.id || "", label: category.name }))}
      />
      <NumberInput label="Sort order" value={draft.sort_order} onChange={(sort_order) => setDraft({ ...draft, sort_order: sort_order ?? 0 })} />
      <Toggle label="Active" checked={draft.is_active} onChange={(is_active) => setDraft({ ...draft, is_active })} />
      <EditorActions saving={saving} saveLabel={draft.id ? "Update category" : "Create category"} onSave={onSave} onCancel={onCancel} />
    </FormGrid>
  );
}

function RestaurantForm({
  draft,
  setDraft,
  saving,
  error,
  onSave,
  onCancel,
}: {
  draft: FoodRestaurant;
  setDraft: (value: FoodRestaurant) => void;
  saving: boolean;
  error: string;
  onSave: () => void;
  onCancel: () => void;
}) {
  return (
    <FormGrid error={error}>
      <TextInput label="Name" value={draft.name} onChange={(name) => setDraft({ ...draft, name })} />
      <TextInput label="Slug" value={draft.slug || ""} onChange={(slug) => setDraft({ ...draft, slug })} />
      <TextInput label="Subtitle" value={draft.subtitle || ""} onChange={(subtitle) => setDraft({ ...draft, subtitle })} />
      <TextInput label="Phone" value={draft.phone || ""} onChange={(phone) => setDraft({ ...draft, phone })} />
      <ImageUploadInput label="Restaurant image" value={draft.image_url || ""} onChange={(image_url) => setDraft({ ...draft, image_url })} />
      <TextInput label="Pickup location" value={draft.pickup_location || ""} onChange={(pickup_location) => setDraft({ ...draft, pickup_location })} />
      <div className="grid grid-cols-2 gap-3">
        <NumberInput label="Pickup lat" value={draft.pickup_lat} allowEmpty onChange={(pickup_lat) => setDraft({ ...draft, pickup_lat })} />
        <NumberInput label="Pickup lng" value={draft.pickup_lng} allowEmpty onChange={(pickup_lng) => setDraft({ ...draft, pickup_lng })} />
      </div>
      <NumberInput label="App placement" value={draft.sort_order} onChange={(sort_order) => setDraft({ ...draft, sort_order: sort_order ?? 0 })} />
      <Toggle label="Feature on app" checked={draft.is_featured} onChange={(is_featured) => setDraft({ ...draft, is_featured })} />
      <Toggle label="Active" checked={draft.is_active} onChange={(is_active) => setDraft({ ...draft, is_active })} />
      <EditorActions saving={saving} saveLabel={draft.id ? "Update restaurant" : "Create restaurant"} onSave={onSave} onCancel={onCancel} />
    </FormGrid>
  );
}

function ItemForm({
  draft,
  setDraft,
  categories,
  restaurants,
  saving,
  error,
  onSave,
  onRestaurantSelect,
  onCancel,
}: {
  draft: FoodItem;
  setDraft: (value: FoodItem) => void;
  categories: FoodCategory[];
  restaurants: FoodRestaurant[];
  saving: boolean;
  error: string;
  onSave: () => void;
  onRestaurantSelect: (restaurantId: string) => void;
  onCancel: () => void;
}) {
  return (
    <FormGrid error={error}>
      <TextInput label="Food title" value={draft.title} onChange={(title) => setDraft({ ...draft, title })} />
      <NumberInput label="Price ETB" value={draft.price} onChange={(price) => setDraft({ ...draft, price: price ?? 0 })} />
      <TextAreaInput label="Description" value={draft.description || ""} onChange={(description) => setDraft({ ...draft, description })} />
      <ImageUploadInput label="Food image" value={draft.image_url || ""} onChange={(image_url) => setDraft({ ...draft, image_url })} />
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <SelectInput
          label="Category"
          value={draft.category_id || ""}
          onChange={(category_id) => setDraft({ ...draft, category_id: category_id || null })}
          options={categories.map((category) => ({ value: category.id || "", label: category.name }))}
        />
        <SelectInput
          label="Restaurant"
          value={draft.restaurant_id || ""}
          onChange={onRestaurantSelect}
          options={restaurants.map((restaurant) => ({ value: restaurant.id || "", label: restaurant.name }))}
        />
      </div>
      <TextInput label="Restaurant name override" value={draft.restaurant_name || ""} onChange={(restaurant_name) => setDraft({ ...draft, restaurant_name })} />
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <TextInput label="Seller name" value={draft.seller_name} onChange={(seller_name) => setDraft({ ...draft, seller_name })} />
        <TextInput label="Seller phone" value={draft.seller_phone} onChange={(seller_phone) => setDraft({ ...draft, seller_phone })} />
      </div>
      <TextInput label="Pickup location" value={draft.pickup_location || ""} onChange={(pickup_location) => setDraft({ ...draft, pickup_location })} />
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <NumberInput label="Pickup lat" value={draft.pickup_lat} allowEmpty onChange={(pickup_lat) => setDraft({ ...draft, pickup_lat })} />
        <NumberInput label="Pickup lng" value={draft.pickup_lng} allowEmpty onChange={(pickup_lng) => setDraft({ ...draft, pickup_lng })} />
      </div>
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <SelectInput
          label="Source"
          value={draft.source_type}
          onChange={(source_type) => setDraft({ ...draft, source_type: (source_type || "admin") as FoodItem["source_type"] })}
          options={[
            { value: "admin", label: "Admin" },
            { value: "restaurant", label: "Restaurant" },
            { value: "client", label: "Client" },
          ]}
        />
        <NumberInput label="Listing placement" value={draft.sort_order} onChange={(sort_order) => setDraft({ ...draft, sort_order: sort_order ?? 0 })} />
      </div>
      <Toggle label="Featured food" checked={draft.is_featured} onChange={(is_featured) => setDraft({ ...draft, is_featured })} />
      <Toggle label="Active" checked={draft.is_active} onChange={(is_active) => setDraft({ ...draft, is_active })} />
      <EditorActions saving={saving} saveLabel={draft.id ? "Update listing" : "Create listing"} onSave={onSave} onCancel={onCancel} />
    </FormGrid>
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

function FormGrid({ error, children }: { error: string; children: ReactNode }) {
  return (
    <div className="space-y-4">
      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-bold text-red-700">
          {error}
        </div>
      )}
      {children}
    </div>
  );
}

function PaginationControls({
  page,
  totalPages,
  onPageChange,
}: {
  page: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}) {
  const pages = Array.from({ length: totalPages }, (_, index) => index + 1)
    .filter((entry) => entry === 1 || entry === totalPages || Math.abs(entry - page) <= 1);

  if (totalPages <= 1) return null;

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-t border-neutral-100 pt-4">
      <button
        onClick={() => onPageChange(page - 1)}
        disabled={page <= 1}
        className="rounded-xl border border-neutral-200 px-4 py-2 text-sm font-extrabold text-neutral-600 hover:bg-neutral-50 disabled:cursor-not-allowed disabled:opacity-40"
      >
        Previous
      </button>
      <div className="flex flex-wrap items-center gap-2">
        {pages.map((entry, index) => {
          const previous = pages[index - 1];
          const showGap = previous != null && entry - previous > 1;
          return (
            <div key={entry} className="flex items-center gap-2">
              {showGap && <span className="text-xs font-bold text-neutral-400">...</span>}
              <button
                onClick={() => onPageChange(entry)}
                className={`h-9 min-w-9 rounded-xl px-3 text-sm font-extrabold ${entry === page ? "bg-blue-600 text-white" : "border border-neutral-200 text-neutral-600 hover:bg-neutral-50"}`}
              >
                {entry}
              </button>
            </div>
          );
        })}
      </div>
      <button
        onClick={() => onPageChange(page + 1)}
        disabled={page >= totalPages}
        className="rounded-xl border border-neutral-200 px-4 py-2 text-sm font-extrabold text-neutral-600 hover:bg-neutral-50 disabled:cursor-not-allowed disabled:opacity-40"
      >
        Next
      </button>
    </div>
  );
}

function Panel({ title, action, children }: { title: string; action?: ReactNode; children: ReactNode }) {
  return (
    <section className="space-y-4 rounded-3xl border border-neutral-200 bg-white p-5 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h3 className="text-lg font-extrabold text-neutral-900">{title}</h3>
        {action}
      </div>
      {children}
    </section>
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

function ImageUploadInput({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState("");

  async function handleFile(file: File | undefined) {
    if (!file) return;
    setUploading(true);
    setError("");
    try {
      const url = await uploadFoodImage(file);
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
            <p className="mt-1 truncate text-[11px] font-semibold text-neutral-500">{uploading ? "Uploading..." : value ? "Uploaded image ready" : "JPG, PNG, or WebP under 6MB"}</p>
            {error && <p className="mt-1 text-[11px] font-bold text-red-600">{error}</p>}
          </div>
          {value && (
            <button type="button" onClick={() => onChange("")} className="rounded-lg border border-neutral-200 px-2 py-1 text-xs font-extrabold text-neutral-500 hover:bg-white">Clear</button>
          )}
        </div>
      </div>
    </div>
  );
}

function NumberInput({
  label,
  value,
  allowEmpty = false,
  onChange,
}: {
  label: string;
  value: number | null | undefined;
  allowEmpty?: boolean;
  onChange: (value: number | null) => void;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-extrabold text-neutral-600">{label}</span>
      <input
        type="number"
        value={value ?? ""}
        onChange={(event) => {
          if (event.target.value === "" && allowEmpty) {
            onChange(null);
            return;
          }
          onChange(Number(event.target.value));
        }}
        className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold text-neutral-800 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100"
      />
    </label>
  );
}

function SelectInput({ label, value, options, onChange }: { label: string; value: string; options: { value: string; label: string }[]; onChange: (value: string) => void }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-extrabold text-neutral-600">{label}</span>
      <select value={value} onChange={(event) => onChange(event.target.value)} className="w-full rounded-xl border border-neutral-300 bg-neutral-50 px-3 py-2 text-sm font-semibold text-neutral-800 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100">
        <option value="">None</option>
        {options.map((option) => (
          <option key={option.value} value={option.value}>{option.label}</option>
        ))}
      </select>
    </label>
  );
}

function Toggle({ label, checked, onChange }: { label: string; checked: boolean; onChange: (checked: boolean) => void }) {
  return (
    <label className="flex items-center justify-between rounded-xl border border-neutral-200 bg-neutral-50 px-3 py-2">
      <span className="text-sm font-extrabold text-neutral-700">{label}</span>
      <input type="checkbox" checked={checked} onChange={(event) => onChange(event.target.checked)} className="h-5 w-5 accent-blue-600" />
    </label>
  );
}

function EditorActions({ saving, saveLabel, onSave, onCancel }: { saving: boolean; saveLabel: string; onSave: () => void; onCancel: () => void }) {
  return (
    <div className="flex gap-2 pt-2">
      <button disabled={saving} onClick={onSave} className="flex-1 rounded-xl bg-blue-600 px-4 py-3 text-sm font-extrabold text-white hover:bg-blue-700 disabled:opacity-50">
        {saving ? "Saving..." : saveLabel}
      </button>
      <button disabled={saving} onClick={onCancel} className="rounded-xl border border-neutral-200 px-4 py-3 text-sm font-extrabold text-neutral-600 hover:bg-neutral-50">
        Cancel
      </button>
    </div>
  );
}

function RowCard({ children }: { children: ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-3 rounded-2xl border border-neutral-200 bg-neutral-50 p-4">
      {children}
    </div>
  );
}

function RowActions({ onEdit, onDelete }: { onEdit: () => void; onDelete: () => void }) {
  return (
    <div className="flex shrink-0 gap-2">
      <button onClick={onEdit} className="rounded-lg bg-blue-50 px-3 py-1.5 text-xs font-extrabold text-blue-600 hover:bg-blue-100">Edit</button>
      <button onClick={onDelete} className="rounded-lg bg-red-50 px-3 py-1.5 text-xs font-extrabold text-red-600 hover:bg-red-100">Delete</button>
    </div>
  );
}
