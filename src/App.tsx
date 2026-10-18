import { FormEvent, ReactNode, useMemo, useState } from "react";

type Role = "manager" | "admin";
type View = "dashboard" | "products" | "add" | "invoices" | "statistics" | "profile";

type Product = {
  id: number;
  name: string;
  sku: string;
  category: string;
  cost: number;
  price: number;
  stock: number;
  rejectStock: number;
  minStock: number;
};

type InvoiceLine = {
  productId: number;
  productName: string;
  quantity: number;
  unitPrice: number;
};

type InvoiceComment = {
  id: number;
  actor: string;
  message: string;
  date: string;
};

type Invoice = {
  id: number;
  number: string;
  customer: string;
  contact: string;
  paymentType: "cash" | "credit";
  status: "paid" | "unpaid";
  dueDate?: string;
  date: string;
  lines: InvoiceLine[];
  total: number;
  comments: InvoiceComment[];
};

type NewProductInput = Omit<Product, "id">;
type NewInvoiceInput = Omit<Invoice, "id" | "number" | "date" | "status" | "total" | "comments">;

type ProfitRecord = {
  date: string;
  profit: number;
};

type Notification = {
  id: number;
  product: string;
  actor: string;
  oldCost: number;
  newCost: number;
  oldPrice: number;
  newPrice: number;
  date: string;
};

const initialProducts: Product[] = [
  { id: 1, name: "Minyak Goreng 1L", sku: "MK-001", category: "Sembako", cost: 12000, price: 14500, stock: 2, rejectStock: 0, minStock: 8 },
  { id: 2, name: "Beras Premium 5kg", sku: "BR-005", category: "Sembako", cost: 58000, price: 68000, stock: 5, rejectStock: 0, minStock: 10 },
  { id: 3, name: "Gula Pasir 1kg", sku: "GL-010", category: "Sembako", cost: 12500, price: 14500, stock: 45, rejectStock: 0, minStock: 10 },
  { id: 4, name: "Teh Celup Kotak", sku: "TH-022", category: "Minuman", cost: 4800, price: 6500, stock: 30, rejectStock: 0, minStock: 8 },
  { id: 5, name: "Kopi Sachet 10pcs", sku: "KP-031", category: "Minuman", cost: 9500, price: 12000, stock: 25, rejectStock: 0, minStock: 8 },
  { id: 6, name: "Keripik Singkong Balado", sku: "SN-014", category: "Makanan Ringan", cost: 6500, price: 9000, stock: 50, rejectStock: 0, minStock: 12 },
];

const initialInvoices: Invoice[] = [
  {
    id: 1,
    number: "INV-2026-001",
    customer: "Warung Bu Sari",
    contact: "0812 3456 7890",
    paymentType: "credit",
    status: "unpaid",
    dueDate: "2026-10-30",
    date: "15 Okt 2026",
    lines: [{ productId: 3, productName: "Gula Pasir 1kg", quantity: 5, unitPrice: 14500 }],
    total: 72500,
    comments: [],
  },
];

const initialProfitRecords: ProfitRecord[] = [
  { date: "2026-07-04", profit: 340000 },
  { date: "2026-07-11", profit: 465000 },
  { date: "2026-07-19", profit: 295000 },
  { date: "2026-07-27", profit: 525000 },
  { date: "2026-08-05", profit: 410000 },
  { date: "2026-08-13", profit: 580000 },
  { date: "2026-08-22", profit: 490000 },
  { date: "2026-08-29", profit: 635000 },
  { date: "2026-09-06", profit: 545000 },
  { date: "2026-09-14", profit: 710000 },
  { date: "2026-09-23", profit: 620000 },
  { date: "2026-10-02", profit: 680000 },
  { date: "2026-10-09", profit: 795000 },
  { date: "2026-10-15", profit: 745000 },
];

const initialNotifications: Notification[] = [
  {
    id: 1,
    product: "Beras Premium 5kg",
    actor: "Budi Santoso",
    oldCost: 56000,
    newCost: 58000,
    oldPrice: 65000,
    newPrice: 68000,
    date: "Hari ini, 09.42",
  },
  {
    id: 2,
    product: "Kopi Sachet 10pcs",
    actor: "Budi Santoso",
    oldCost: 9000,
    newCost: 9500,
    oldPrice: 11500,
    newPrice: 12000,
    date: "Kemarin, 15.18",
  },
];

const rupiah = (value: number) =>
  new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", maximumFractionDigits: 0 }).format(value);

const compactRupiah = (value: number) => {
  if (value >= 1_000_000) return `Rp ${(value / 1_000_000).toLocaleString("id-ID", { maximumFractionDigits: 1 })} jt`;
  return rupiah(value);
};

function Icon({ name, className = "size-5" }: { name: string; className?: string }) {
  const paths: Record<string, ReactNode> = {
    grid: <><rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" /><rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" /></>,
    box: <><path d="m21 8-9 5-9-5 9-5 9 5Z" /><path d="m3 8 9 5 9-5v9l-9 5-9-5V8Z" /><path d="M12 13v9" /></>,
    plus: <><path d="M12 5v14M5 12h14" /></>,
    chart: <><path d="M4 19V9M10 19V5M16 19v-7M22 19H2" /></>,
    search: <><circle cx="11" cy="11" r="7" /><path d="m20 20-4-4" /></>,
    bell: <><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4" /></>,
    chevron: <path d="m9 18 6-6-6-6" />,
    down: <path d="m6 9 6 6 6-6" />,
    edit: <><path d="M12 20h9" /><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4Z" /></>,
    close: <><path d="m6 6 12 12M18 6 6 18" /></>,
    check: <path d="m5 12 4 4L19 6" />,
    trend: <><path d="m3 17 6-6 4 4 8-9" /><path d="M15 6h6v6" /></>,
    wallet: <><path d="M4 6h14a2 2 0 0 1 2 2v10H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h12" /><path d="M16 11h6v4h-6a2 2 0 0 1 0-4Z" /></>,
    menu: <><path d="M4 7h16M4 12h16M4 17h16" /></>,
    logout: <><path d="M10 17l5-5-5-5M15 12H3M15 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4" /></>,
    history: <><path d="M3 12a9 9 0 1 0 3-6.7L3 8" /><path d="M3 3v5h5M12 7v5l3 2" /></>,
    arrow: <path d="M5 12h14m-5-5 5 5-5 5" />,
    logo: <><rect x="3" y="3" width="18" height="18" rx="5" /><path d="M3 9h18M9 21V9" /></>,
    user: <><circle cx="12" cy="8" r="4" /><path d="M4 21a8 8 0 0 1 16 0" /></>,
    store: <><path d="M3 9h18l-2-5H5L3 9Z" /><path d="M5 9v11h14V9M9 20v-6h6v6" /><path d="M3 9a3 3 0 0 0 6 0 3 3 0 0 0 6 0 3 3 0 0 0 6 0" /></>,
    shield: <><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z" /><path d="m9 12 2 2 4-4" /></>,
    invoice: <><path d="M6 2h9l4 4v16l-3-2-3 2-3-2-3 2-2-1V3a1 1 0 0 1 1-1Z" /><path d="M14 2v5h5M8 11h8M8 15h6" /></>,
    trash: <><path d="M4 7h16M9 7V4h6v3M7 7l1 14h8l1-14M10 11v6M14 11v6" /></>,
    print: <><path d="M6 9V3h12v6M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2" /><path d="M6 14h12v8H6z" /></>,
    share: <><circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" /><path d="m8.6 10.5 6.8-4M8.6 13.5l6.8 4" /></>,
  };
  return <svg aria-hidden="true" className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">{paths[name]}</svg>;
}

function Button({
  children,
  onClick,
  type = "button",
  variant = "primary",
  className = "",
  disabled = false,
}: {
  children: ReactNode;
  onClick?: () => void;
  type?: "button" | "submit";
  variant?: "primary" | "secondary" | "ghost";
  className?: string;
  disabled?: boolean;
}) {
  const variants = {
    primary: "bg-blue-600 text-white hover:bg-blue-700 shadow-sm shadow-blue-200",
    secondary: "border border-slate-200 bg-white text-slate-700 hover:border-slate-300 hover:bg-slate-50",
    ghost: "text-slate-600 hover:bg-slate-100 hover:text-slate-900",
  };
  return <button type={type} disabled={disabled} onClick={onClick} className={`inline-flex items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition disabled:cursor-not-allowed disabled:opacity-50 ${variants[variant]} ${className}`}>{children}</button>;
}

function StatusBadge({ product }: { product: Product }) {
  const critical = product.stock <= product.minStock / 2;
  const low = product.stock <= product.minStock;
  return (
    <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${critical ? "bg-rose-50 text-rose-700" : low ? "bg-amber-50 text-amber-700" : "bg-emerald-50 text-emerald-700"}`}>
      {critical ? "Kritis" : low ? "Menipis" : "Aman"}
    </span>
  );
}

function App() {
  const [role, setRole] = useState<Role>("manager");
  const [loggedIn, setLoggedIn] = useState(true);
  const [view, setView] = useState<View>("dashboard");
  const [products, setProducts] = useState(initialProducts);
  const [invoices, setInvoices] = useState(initialInvoices);
  const [profitRecords, setProfitRecords] = useState(initialProfitRecords);
  const [notifications, setNotifications] = useState(initialNotifications);
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("Semua");
  const [notificationOpen, setNotificationOpen] = useState(false);
  const [accountOpen, setAccountOpen] = useState(false);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [editing, setEditing] = useState<Product | null>(null);
  const [toast, setToast] = useState("");

  const visibleProducts = useMemo(() => {
    const needle = query.toLowerCase().trim();
    return products.filter((product) => {
      const matchesText = !needle || `${product.name} ${product.sku} ${product.category}`.toLowerCase().includes(needle);
      return matchesText && (category === "Semua" || product.category === category);
    });
  }, [products, query, category]);

  const totals = useMemo(() => products.reduce((acc, product) => ({
    stock: acc.stock + product.stock,
    cost: acc.cost + product.cost * product.stock,
    revenue: acc.revenue + product.price * product.stock,
    low: acc.low + (product.stock <= product.minStock ? 1 : 0),
  }), { stock: 0, cost: 0, revenue: 0, low: 0 }), [products]);

  const navigate = (next: View) => {
    setView(next);
    setMobileNavOpen(false);
    if (next !== "products") setQuery("");
  };

  const flash = (message: string) => {
    setToast(message);
    window.setTimeout(() => setToast(""), 2800);
  };

  const savePrice = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!editing || role !== "manager") return;
    const form = new FormData(event.currentTarget);
    const newCost = Number(form.get("cost"));
    const newPrice = Number(form.get("price"));
    if (newCost <= 0 || newPrice <= 0) return;
    setProducts((items) => items.map((item) => item.id === editing.id ? { ...item, cost: newCost, price: newPrice } : item));
    setNotifications((items) => [{
      id: Date.now(),
      product: editing.name,
      actor: "Budi Santoso",
      oldCost: editing.cost,
      newCost,
      oldPrice: editing.price,
      newPrice,
      date: "Baru saja",
    }, ...items]);
    setEditing(null);
    flash(`Harga ${editing.name} berhasil diperbarui`);
  };

  const addProduct = (input: NewProductInput) => {
    if (role !== "admin") return;
    const newProduct: Product = {
      id: Date.now(),
      ...input,
      sku: input.sku.toUpperCase(),
    };
    setProducts((items) => [newProduct, ...items]);
    flash(`${newProduct.name} ditambahkan ke inventaris`);
    setView("products");
  };

  const createInvoice = (input: NewInvoiceInput) => {
    if (role !== "admin") return false;
    const invalidLine = input.lines.find((line) => {
      const product = products.find((item) => item.id === line.productId);
      return !product || line.quantity <= 0 || line.quantity > product.stock;
    });
    if (invalidLine) {
      flash(`Stok ${invalidLine.productName} tidak mencukupi`);
      return false;
    }

    const total = input.lines.reduce((sum, line) => sum + line.quantity * line.unitPrice, 0);
    const invoice: Invoice = {
      ...input,
      id: Date.now(),
      number: `INV-${new Date().getFullYear()}-${String(invoices.length + 1).padStart(3, "0")}`,
      date: new Intl.DateTimeFormat("id-ID", { day: "numeric", month: "short", year: "numeric" }).format(new Date()),
      status: input.paymentType === "cash" ? "paid" : "unpaid",
      total,
      comments: [],
    };
    setProducts((items) => items.map((product) => {
      const line = input.lines.find((item) => item.productId === product.id);
      return line ? { ...product, stock: product.stock - line.quantity } : product;
    }));
    const invoiceProfit = input.lines.reduce((sum, line) => {
      const product = products.find((item) => item.id === line.productId);
      return sum + Math.max(0, line.unitPrice - (product?.cost ?? line.unitPrice)) * line.quantity;
    }, 0);
    setProfitRecords((items) => [...items, { date: new Date().toISOString().slice(0, 10), profit: invoiceProfit }]);
    setInvoices((items) => [invoice, ...items]);
    flash(`${invoice.number} berhasil dibuat dan stok diperbarui`);
    return true;
  };

  const addInvoiceComment = (invoiceId: number, message: string) => {
    if (role !== "manager" || !message.trim()) return;
    setInvoices((items) => items.map((invoice) => invoice.id === invoiceId ? {
      ...invoice,
      comments: [...invoice.comments, {
        id: Date.now(),
        actor: "Budi Santoso",
        message: message.trim(),
        date: "Baru saja",
      }],
    } : invoice));
    flash("Komentar koreksi berhasil ditambahkan");
  };

  const switchRole = (nextRole: Role) => {
    setRole(nextRole);
    setAccountOpen(false);
    if ((nextRole === "admin" && view === "statistics") || (nextRole === "manager" && view === "add")) setView("dashboard");
    flash(`Masuk sebagai ${nextRole === "manager" ? "Manager" : "Admin Stok"}`);
  };

  if (!loggedIn) {
    return (
      <div className="grid min-h-screen place-items-center bg-blue-50/60 p-5">
        <div className="w-full max-w-md rounded-3xl border border-blue-100 bg-white p-7 text-center shadow-xl shadow-blue-100/70 sm:p-9">
          <span className="mx-auto grid size-12 place-items-center rounded-2xl bg-gradient-to-br from-sky-400 to-blue-600 text-white shadow-md shadow-blue-200"><Icon name="logo" className="size-7" /></span>
          <h1 className="mt-5 text-2xl font-bold tracking-tight text-blue-600">Stokku</h1>
          <p className="mt-2 text-sm text-slate-500">Anda telah keluar dari sistem. Pilih akun untuk masuk kembali.</p>
          <div className="mt-7 space-y-3 text-left">
            {([
              ["manager", "BS", "Budi Santoso", "Manager"],
              ["admin", "RA", "Rina Amelia", "Admin Stok"],
            ] as [Role, string, string, string][]).map(([accountRole, initials, name, label]) => (
              <button key={accountRole} onClick={() => { setRole(accountRole); setLoggedIn(true); setView("dashboard"); }} className="flex w-full items-center gap-3 rounded-2xl border border-slate-200 p-3 text-left transition hover:border-blue-300 hover:bg-blue-50">
                <span className="grid size-10 place-items-center rounded-xl bg-blue-50 text-xs font-bold text-blue-700">{initials}</span>
                <span className="flex-1"><span className="block text-sm font-bold">{name}</span><span className="block text-xs text-slate-500">{label}</span></span>
                <Icon name="arrow" className="size-4 text-blue-600" />
              </button>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-blue-50/40 text-slate-950">
      <aside className={`fixed inset-y-0 left-0 z-40 flex w-64 flex-col border-r border-slate-200 bg-white p-4 transition-transform lg:translate-x-0 ${mobileNavOpen ? "translate-x-0" : "-translate-x-full"}`}>
        <div className="flex h-14 items-center justify-between px-2">
          <button onClick={() => navigate("dashboard")} className="flex items-center gap-3 rounded-xl text-left">
            <span className="grid size-9 place-items-center rounded-xl bg-gradient-to-br from-sky-400 to-blue-600 text-white shadow-sm shadow-blue-200"><Icon name="logo" className="size-5" /></span>
            <span><span className="block text-lg font-bold tracking-tight text-blue-600">Stokku</span><span className="block text-[10px] font-semibold uppercase tracking-[0.16em] text-slate-400">Desktop Suite</span></span>
          </button>
          <button onClick={() => setMobileNavOpen(false)} className="rounded-lg p-2 text-slate-500 lg:hidden" aria-label="Tutup navigasi"><Icon name="close" /></button>
        </div>

        <nav className="mt-7 flex-1 space-y-1">
          <p className="mb-2 px-3 text-[11px] font-bold uppercase tracking-[0.14em] text-slate-400">Menu utama</p>
          {([
            ["dashboard", "grid", "Ringkasan"],
            ["products", "box", "Daftar produk"],
            ...(role === "admin" ? [["add", "plus", "Tambah produk"]] : []),
            ["invoices", "invoice", "Faktur"],
            ...(role === "manager" ? [["statistics", "chart", "Statistik"]] : []),
            ["profile", "user", "Profil"],
          ] as [View, string, string][]).map(([key, icon, label]) => (
            <button key={key} onClick={() => navigate(key)} className={`flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition ${view === key ? "bg-blue-600 text-white shadow-sm shadow-blue-200" : "text-slate-600 hover:bg-blue-50 hover:text-blue-700"}`}>
              <Icon name={icon} className="size-[18px]" />{label}
            </button>
          ))}
        </nav>

        <div className="relative border-t border-slate-100 pt-4">
          {accountOpen && (
            <div className="absolute bottom-full left-0 mb-2 w-full rounded-2xl border border-slate-200 bg-white p-2 shadow-xl shadow-slate-200/70">
              <p className="px-3 py-2 text-xs font-semibold text-slate-400">Ganti akun</p>
              <button onClick={() => switchRole("manager")} className="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left hover:bg-slate-50">
                <span className="grid size-8 place-items-center rounded-lg bg-blue-50 text-xs font-bold text-blue-700">BS</span>
                <span className="flex-1"><span className="block text-sm font-semibold">Budi Santoso</span><span className="block text-xs text-slate-500">Manager</span></span>
                {role === "manager" && <Icon name="check" className="size-4 text-emerald-600" />}
              </button>
              <button onClick={() => switchRole("admin")} className="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left hover:bg-slate-50">
                <span className="grid size-8 place-items-center rounded-lg bg-sky-50 text-xs font-bold text-sky-700">RA</span>
                <span className="flex-1"><span className="block text-sm font-semibold">Rina Amelia</span><span className="block text-xs text-slate-500">Admin Stok</span></span>
                {role === "admin" && <Icon name="check" className="size-4 text-emerald-600" />}
              </button>
            </div>
          )}
          <button onClick={() => setAccountOpen(!accountOpen)} className="flex w-full items-center gap-3 rounded-xl p-2 text-left hover:bg-slate-50">
            <span className={`grid size-9 place-items-center rounded-xl text-xs font-bold ${role === "manager" ? "bg-blue-50 text-blue-700" : "bg-sky-50 text-sky-700"}`}>{role === "manager" ? "BS" : "RA"}</span>
            <span className="min-w-0 flex-1"><span className="block truncate text-sm font-semibold">{role === "manager" ? "Budi Santoso" : "Rina Amelia"}</span><span className="block text-xs text-slate-500">{role === "manager" ? "Manager" : "Admin Stok"}</span></span>
            <Icon name="down" className="size-4 text-slate-400" />
          </button>
        </div>
      </aside>

      {mobileNavOpen && <button aria-label="Tutup navigasi" className="fixed inset-0 z-30 bg-slate-950/30 backdrop-blur-sm lg:hidden" onClick={() => setMobileNavOpen(false)} />}

      <main className="min-h-screen lg:pl-64">
        <header className="sticky top-0 z-20 flex h-20 items-center justify-between border-b border-blue-100 bg-white/90 px-5 backdrop-blur-xl sm:px-8">
          <div className="flex items-center gap-3">
            <button onClick={() => setMobileNavOpen(true)} className="rounded-xl border border-slate-200 bg-white p-2 text-slate-600 lg:hidden" aria-label="Buka navigasi"><Icon name="menu" /></button>
            <div>
              <p className="text-xs font-medium text-slate-500">{role === "manager" ? "Akun Manager" : "Akun Admin"}</p>
              <h1 className="text-lg font-bold tracking-tight sm:text-xl">{view === "dashboard" ? "Ringkasan inventaris" : view === "products" ? "Daftar produk" : view === "add" ? "Tambah produk" : view === "invoices" ? "Faktur & pemesanan" : view === "statistics" ? "Statistik bisnis" : "Profil akun"}</h1>
            </div>
          </div>
          <div className="relative">
            <button onClick={() => setNotificationOpen(!notificationOpen)} className="relative grid size-11 place-items-center rounded-xl border border-slate-200 bg-white text-slate-600 shadow-sm transition hover:text-slate-950" aria-label="Buka notifikasi">
              <Icon name="bell" />
              {notifications.length > 0 && <span className="absolute right-2 top-2 size-2 rounded-full bg-rose-500 ring-2 ring-white" />}
            </button>
            {notificationOpen && (
              <div className="absolute right-0 top-14 w-[min(24rem,calc(100vw-2.5rem))] overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl shadow-slate-300/40">
                <div className="flex items-center justify-between border-b border-slate-100 px-5 py-4">
                  <div><p className="font-bold">Riwayat harga</p><p className="text-xs text-slate-500">Terlihat oleh manager dan admin</p></div>
                  <button onClick={() => setNotificationOpen(false)} className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100"><Icon name="close" className="size-4" /></button>
                </div>
                <div className="max-h-[28rem] overflow-y-auto p-2">
                  {notifications.map((item) => (
                    <div key={item.id} className="rounded-xl p-3 hover:bg-slate-50">
                      <div className="flex gap-3">
                        <span className="mt-0.5 grid size-9 shrink-0 place-items-center rounded-xl bg-amber-50 text-amber-700"><Icon name="history" className="size-4" /></span>
                        <div className="min-w-0"><p className="text-sm font-semibold">{item.product}</p><p className="mt-1 text-xs leading-relaxed text-slate-500">{item.actor} mengubah harga jual dari <span className="font-semibold text-slate-700">{rupiah(item.oldPrice)}</span> menjadi <span className="font-semibold text-slate-700">{rupiah(item.newPrice)}</span>.</p><p className="mt-1.5 text-[11px] font-medium text-slate-400">{item.date}</p></div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </header>

        <div className="mx-auto max-w-7xl p-5 sm:p-8">
          {view === "dashboard" && (
            <Dashboard products={products} totals={totals} role={role} onViewProducts={() => navigate("products")} onAdd={() => navigate("add")} onEdit={setEditing} />
          )}
          {view === "products" && (
            <Products products={visibleProducts} allProducts={products} query={query} setQuery={setQuery} category={category} setCategory={setCategory} role={role} onEdit={setEditing} />
          )}
          {view === "add" && role === "admin" && <AddProduct onSubmit={addProduct} />}
          {view === "invoices" && <Invoices invoices={invoices} products={products} role={role} onCreate={createInvoice} onComment={addInvoiceComment} />}
          {view === "statistics" && role === "manager" && <Statistics products={products} totals={totals} profitRecords={profitRecords} />}
          {view === "profile" && <Profile role={role} onSwitchRole={switchRole} onLogout={() => setLoggedIn(false)} />}
        </div>
      </main>

      {editing && role === "manager" && (
        <div className="fixed inset-0 z-50 grid place-items-center bg-slate-950/40 p-5 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl">
            <div className="flex items-start justify-between">
              <div><p className="text-lg font-bold">Ubah harga produk</p><p className="mt-1 text-sm text-slate-500">{editing.name} · {editing.sku}</p></div>
              <button onClick={() => setEditing(null)} className="rounded-xl p-2 text-slate-400 hover:bg-slate-100"><Icon name="close" /></button>
            </div>
            <form onSubmit={savePrice} className="mt-6 space-y-5">
              <Field label="Harga modal" name="cost" type="number" defaultValue={editing.cost} prefix="Rp" required />
              <Field label="Harga jual" name="price" type="number" defaultValue={editing.price} prefix="Rp" required />
              <div className="rounded-xl bg-amber-50 px-4 py-3 text-xs leading-relaxed text-amber-800">Perubahan akan dicatat dan dikirim sebagai notifikasi ke akun manager dan admin.</div>
              <div className="flex justify-end gap-2 pt-1"><Button variant="secondary" onClick={() => setEditing(null)}>Batal</Button><Button type="submit">Simpan perubahan</Button></div>
            </form>
          </div>
        </div>
      )}

      {toast && <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 rounded-2xl bg-blue-600 px-4 py-3 text-sm font-semibold text-white shadow-xl shadow-blue-200"><span className="grid size-6 place-items-center rounded-full bg-white/20"><Icon name="check" className="size-3.5" /></span>{toast}</div>}
    </div>
  );
}

function Dashboard({ products, totals, role, onViewProducts, onAdd, onEdit }: {
  products: Product[];
  totals: { stock: number; cost: number; revenue: number; low: number };
  role: Role;
  onViewProducts: () => void;
  onAdd: () => void;
  onEdit: (product: Product) => void;
}) {
  const attention = products.filter((product) => product.stock <= product.minStock).slice(0, 4);
  return (
    <div className="space-y-8">
      <section className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div><p className="text-sm text-slate-500">Selamat datang kembali,</p><h2 className="mt-1 text-2xl font-bold tracking-tight sm:text-3xl">{role === "manager" ? "Budi Santoso" : "Rina Amelia"}</h2><p className="mt-2 max-w-xl text-sm text-slate-500">Pantau kondisi stok dan kelola produk toko dari satu tempat.</p></div>
        {role === "admin" && <Button onClick={onAdd}><Icon name="plus" className="size-4" />Tambah produk</Button>}
      </section>
      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Metric label="Total stok" value={totals.stock.toLocaleString("id-ID")} note="Unit tersedia" icon="box" tone="slate" />
        <Metric label="Jumlah produk" value={String(products.length)} note="SKU terdaftar" icon="grid" tone="blue" />
        <Metric label="Perlu perhatian" value={String(totals.low)} note="Stok menipis & kritis" icon="bell" tone="amber" />
        <Metric label={role === "manager" ? "Nilai inventaris" : "Status inventaris"} value={role === "manager" ? compactRupiah(totals.cost) : "Terpantau"} note={role === "manager" ? "Berdasarkan harga modal" : "Data diperbarui langsung"} icon={role === "manager" ? "wallet" : "check"} tone="emerald" />
      </section>
      <section className="rounded-2xl border border-slate-200 bg-white shadow-sm shadow-slate-200/40">
        <div className="flex items-center justify-between border-b border-slate-100 px-5 py-4 sm:px-6">
          <div><h3 className="font-bold">Produk perlu perhatian</h3><p className="mt-1 text-xs text-slate-500">Prioritaskan stok di bawah batas minimum</p></div>
          <Button variant="ghost" onClick={onViewProducts} className="hidden sm:inline-flex">Lihat semua <Icon name="arrow" className="size-4" /></Button>
        </div>
        <ProductTable products={attention} role={role} onEdit={onEdit} compact />
      </section>
    </div>
  );
}

function Products({ products, allProducts, query, setQuery, category, setCategory, role, onEdit }: {
  products: Product[];
  allProducts: Product[];
  query: string;
  setQuery: (value: string) => void;
  category: string;
  setCategory: (value: string) => void;
  role: Role;
  onEdit: (product: Product) => void;
}) {
  const categories = ["Semua", ...Array.from(new Set(allProducts.map((product) => product.category)))];
  return (
    <div className="space-y-5">
      <div className="flex flex-col justify-between gap-4 xl:flex-row xl:items-center">
        <div><h2 className="text-2xl font-bold tracking-tight">Semua produk</h2><p className="mt-1 text-sm text-slate-500">{products.length} dari {allProducts.length} produk ditampilkan</p></div>
        <div className="flex flex-col gap-3 sm:flex-row">
          <label className="relative block min-w-72">
            <span className="sr-only">Cari produk</span><Icon name="search" className="absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-slate-400" />
            <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Cari nama, SKU, atau kategori..." className="h-11 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-4 text-sm outline-none transition placeholder:text-slate-400 focus:border-slate-400 focus:ring-4 focus:ring-slate-100" />
          </label>
          <select value={category} onChange={(event) => setCategory(event.target.value)} className="h-11 rounded-xl border border-slate-200 bg-white px-3 text-sm font-medium text-slate-700 outline-none focus:border-slate-400">
            {categories.map((item) => <option key={item}>{item}</option>)}
          </select>
        </div>
      </div>
      <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm shadow-slate-200/40">
        {products.length > 0 ? <ProductTable products={products} role={role} onEdit={onEdit} /> : <div className="grid min-h-72 place-items-center p-8 text-center"><div><span className="mx-auto grid size-12 place-items-center rounded-2xl bg-slate-100 text-slate-500"><Icon name="search" /></span><p className="mt-4 font-bold">Produk tidak ditemukan</p><p className="mt-1 text-sm text-slate-500">Coba gunakan kata kunci atau kategori lain.</p></div></div>}
      </section>
    </div>
  );
}

function ProductTable({ products, role, onEdit, compact = false }: { products: Product[]; role: Role; onEdit: (product: Product) => void; compact?: boolean }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[720px] text-left">
        <thead><tr className="border-b border-slate-100 text-[11px] font-bold uppercase tracking-[0.08em] text-slate-400"><th className="px-6 py-3.5">Produk</th><th className="px-4 py-3.5">Kategori</th><th className="px-4 py-3.5">Harga jual</th><th className="px-4 py-3.5">Stok</th><th className="px-4 py-3.5">Status</th><th className="px-6 py-3.5 text-right">Aksi</th></tr></thead>
        <tbody className="divide-y divide-slate-100">
          {products.map((product) => (
            <tr key={product.id} className="group hover:bg-slate-50/80">
              <td className="px-6 py-4"><div className="flex items-center gap-3"><span className="grid size-10 shrink-0 place-items-center rounded-xl bg-slate-100 font-bold text-slate-500">{product.name.charAt(0)}</span><div><p className="text-sm font-semibold">{product.name}</p><p className="mt-0.5 text-xs text-slate-400">{product.sku}</p></div></div></td>
              <td className="px-4 py-4 text-sm text-slate-600">{product.category}</td>
              <td className="px-4 py-4 text-sm font-semibold">{rupiah(product.price)}</td>
              <td className="px-4 py-4"><span className="text-sm font-semibold">{product.stock}</span><span className="ml-1 text-xs text-slate-400">unit</span>{product.rejectStock > 0 && <span className="mt-1 block text-xs font-medium text-rose-600">{product.rejectStock} reject</span>}</td>
              <td className="px-4 py-4"><StatusBadge product={product} /></td>
              <td className="px-6 py-4 text-right">{role === "manager" ? <Button variant="ghost" className="px-3 py-2" onClick={() => onEdit(product)}><Icon name="edit" className="size-4" />Ubah harga</Button> : <span className="text-xs font-medium text-slate-400">Hanya lihat</span>}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {compact && products.length === 0 && <p className="p-8 text-center text-sm text-slate-500">Semua stok dalam kondisi aman.</p>}
    </div>
  );
}

function Metric({ label, value, note, icon, tone }: { label: string; value: string; note: string; icon: string; tone: "slate" | "blue" | "amber" | "emerald" }) {
  const tones = { slate: "bg-slate-100 text-slate-700", blue: "bg-blue-50 text-blue-700", amber: "bg-amber-50 text-amber-700", emerald: "bg-emerald-50 text-emerald-700" };
  return <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm shadow-slate-200/30"><div className="flex items-start justify-between"><p className="text-sm font-medium text-slate-500">{label}</p><span className={`grid size-9 place-items-center rounded-xl ${tones[tone]}`}><Icon name={icon} className="size-[18px]" /></span></div><p className="mt-5 text-2xl font-bold tracking-tight">{value}</p><p className="mt-1 text-xs text-slate-400">{note}</p></div>;
}

type Ingredient = { id: number; name: string; quantity: number; unit: string; unitCost: number };

function AddProduct({ onSubmit }: { onSubmit: (product: NewProductInput) => void }) {
  const [ingredients, setIngredients] = useState<Ingredient[]>([
    { id: 1, name: "", quantity: 1, unit: "pcs", unitCost: 0 },
  ]);
  const [stock, setStock] = useState(0);
  const [rejectStock, setRejectStock] = useState(0);
  const unitCost = ingredients.reduce((total, item) => total + item.quantity * item.unitCost, 0);
  const sellableStock = Math.max(0, stock - rejectStock);

  const updateIngredient = (id: number, field: keyof Ingredient, value: string | number) => {
    setIngredients((items) => items.map((item) => item.id === id ? { ...item, [field]: value } : item));
  };

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    if (unitCost <= 0 || rejectStock > stock) return;
    onSubmit({
      name: String(form.get("name")),
      sku: String(form.get("sku")),
      category: String(form.get("category")),
      cost: unitCost,
      price: Number(form.get("price")),
      stock: sellableStock,
      rejectStock,
      minStock: Number(form.get("minStock")),
    });
  };

  return (
    <div className="mx-auto max-w-4xl">
      <div><h2 className="text-2xl font-bold tracking-tight">Produk baru</h2><p className="mt-1 text-sm text-slate-500">Hitung HPP dari komposisi bahan dan pisahkan stok reject secara otomatis.</p></div>
      <form onSubmit={submit} className="mt-6 space-y-5">
        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
          <div className="mb-5"><h3 className="font-bold">Informasi produk</h3><p className="mt-1 text-xs text-slate-500">Data utama produk yang akan dijual.</p></div>
        <div className="grid gap-5 sm:grid-cols-2">
          <div className="sm:col-span-2"><Field label="Nama produk" name="name" placeholder="Contoh: Susu UHT 1L" required /></div>
          <Field label="Kode / SKU" name="sku" placeholder="Contoh: SS-001" required />
          <label className="block"><span className="mb-2 block text-sm font-semibold text-slate-700">Kategori</span><select name="category" required className="h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm outline-none transition focus:border-slate-400 focus:ring-4 focus:ring-slate-100"><option>Sembako</option><option>Minuman</option><option>Makanan Ringan</option><option>Perlengkapan Mandi</option><option>Lainnya</option></select></label>
          <Field label="Harga jual" name="price" type="number" prefix="Rp" placeholder="0" required />
          <Field label="Batas stok minimum" name="minStock" type="number" placeholder="0" required />
        </div>
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
          <div className="flex items-start justify-between gap-4">
            <div><h3 className="font-bold">Komposisi bahan baku</h3><p className="mt-1 text-xs text-slate-500">Harga modal satuan dihitung dari total seluruh komponen.</p></div>
            <Button variant="secondary" onClick={() => setIngredients((items) => [...items, { id: Date.now(), name: "", quantity: 1, unit: "pcs", unitCost: 0 }])}><Icon name="plus" className="size-4" />Komponen</Button>
          </div>
          <div className="mt-5 space-y-3">
            {ingredients.map((item, index) => (
              <div key={item.id} className="grid gap-3 rounded-xl border border-slate-100 bg-slate-50/70 p-3 sm:grid-cols-[1.5fr_.6fr_.6fr_1fr_auto] sm:items-end">
                <Field label={index === 0 ? "Nama bahan" : "Bahan"} name={`ingredient-${item.id}`} placeholder="Contoh: Beras curah" required defaultValue={item.name} onChange={(value) => updateIngredient(item.id, "name", value)} />
                <Field label="Jumlah" name={`quantity-${item.id}`} type="number" step="0.01" required defaultValue={item.quantity} onChange={(value) => updateIngredient(item.id, "quantity", Number(value))} />
                <label className="block"><span className="mb-2 block text-sm font-semibold text-slate-700">Satuan</span><select value={item.unit} onChange={(event) => updateIngredient(item.id, "unit", event.target.value)} className="h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm outline-none"><option>pcs</option><option>kg</option><option>gram</option><option>liter</option><option>pak</option></select></label>
                <Field label="Biaya / satuan" name={`cost-${item.id}`} type="number" prefix="Rp" required defaultValue={item.unitCost} onChange={(value) => updateIngredient(item.id, "unitCost", Number(value))} />
                <button type="button" disabled={ingredients.length === 1} onClick={() => setIngredients((items) => items.filter((entry) => entry.id !== item.id))} className="grid size-11 place-items-center rounded-xl text-slate-400 transition hover:bg-rose-50 hover:text-rose-600 disabled:opacity-30" aria-label="Hapus komponen"><Icon name="trash" className="size-4" /></button>
              </div>
            ))}
          </div>
          <div className="mt-5 flex items-center justify-between rounded-2xl bg-blue-50 p-4"><div><p className="text-xs font-semibold uppercase tracking-wide text-blue-600">Modal satuan / HPP</p><p className="mt-1 text-xs text-blue-700/70">Total biaya seluruh komponen</p></div><p className="text-xl font-extrabold text-blue-700">{rupiah(unitCost)}</p></div>
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
          <div><h3 className="font-bold">Stok awal & reject</h3><p className="mt-1 text-xs text-slate-500">Barang reject tidak masuk ke stok yang dapat dijual.</p></div>
          <div className="mt-5 grid gap-5 sm:grid-cols-2">
            <label className="block"><span className="mb-2 block text-sm font-semibold text-slate-700">Stok awal</span><input type="number" min={0} value={stock} onChange={(event) => setStock(Number(event.target.value))} required className="h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm outline-none focus:border-slate-400 focus:ring-4 focus:ring-slate-100" /></label>
            <label className="block"><span className="mb-2 block text-sm font-semibold text-slate-700">Barang reject <span className="font-normal text-slate-400">(opsional)</span></span><input type="number" min={0} max={stock} value={rejectStock} onChange={(event) => setRejectStock(Number(event.target.value))} className="h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm outline-none focus:border-slate-400 focus:ring-4 focus:ring-slate-100" /></label>
          </div>
          <div className="mt-5 grid gap-3 sm:grid-cols-3">
            <SummaryValue label="Stok dapat dijual" value={`${sellableStock} unit`} />
            <SummaryValue label="Nilai inventaris" value={rupiah(unitCost * sellableStock)} />
            <SummaryValue label="Potensi rugi reject" value={rupiah(unitCost * rejectStock)} warning={rejectStock > 0} />
          </div>
        </section>
        <div className="flex justify-end"><Button type="submit" disabled={unitCost <= 0 || rejectStock > stock} className="w-full sm:w-auto"><Icon name="plus" className="size-4" />Simpan produk</Button></div>
      </form>
    </div>
  );
}

function SummaryValue({ label, value, warning = false }: { label: string; value: string; warning?: boolean }) {
  return <div className={`rounded-xl p-4 ${warning ? "bg-rose-50" : "bg-slate-50"}`}><p className={`text-xs font-medium ${warning ? "text-rose-600" : "text-slate-500"}`}>{label}</p><p className={`mt-1 text-sm font-bold ${warning ? "text-rose-800" : "text-slate-900"}`}>{value}</p></div>;
}

function Field({ label, name, type = "text", placeholder, defaultValue, prefix, required, step, onChange }: { label: string; name: string; type?: string; placeholder?: string; defaultValue?: string | number; prefix?: string; required?: boolean; step?: string; onChange?: (value: string) => void }) {
  return <label className="block"><span className="mb-2 block text-sm font-semibold text-slate-700">{label}</span><span className="relative block">{prefix && <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-sm font-medium text-slate-400">{prefix}</span>}<input name={name} type={type} placeholder={placeholder} defaultValue={defaultValue} required={required} min={type === "number" ? 0 : undefined} step={step} onChange={onChange ? (event) => onChange(event.target.value) : undefined} className={`h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm outline-none transition placeholder:text-slate-300 focus:border-slate-400 focus:ring-4 focus:ring-slate-100 ${prefix ? "pl-10" : ""}`} /></span></label>;
}

type DraftLine = { id: number; productId: number; quantity: number };

function Invoices({ invoices, products, role, onCreate, onComment }: { invoices: Invoice[]; products: Product[]; role: Role; onCreate: (invoice: NewInvoiceInput) => boolean; onComment: (invoiceId: number, message: string) => void }) {
  const availableProducts = products.filter((product) => product.stock > 0);
  const [creating, setCreating] = useState(false);
  const [reviewingId, setReviewingId] = useState<number | null>(null);
  const [comment, setComment] = useState("");
  const [customer, setCustomer] = useState("");
  const [contact, setContact] = useState("");
  const [paymentType, setPaymentType] = useState<"cash" | "credit">("cash");
  const [dueDate, setDueDate] = useState("");
  const [lines, setLines] = useState<DraftLine[]>([
    { id: 1, productId: availableProducts[0]?.id ?? 0, quantity: 1 },
  ]);

  const invoiceLines = lines.map((line) => {
    const product = products.find((item) => item.id === line.productId);
    return {
      productId: line.productId,
      productName: product?.name ?? "",
      quantity: line.quantity,
      unitPrice: product?.price ?? 0,
    };
  });
  const total = invoiceLines.reduce((sum, line) => sum + line.quantity * line.unitPrice, 0);
  const reviewingInvoice = invoices.find((invoice) => invoice.id === reviewingId);

  const resetForm = () => {
    setCustomer("");
    setContact("");
    setPaymentType("cash");
    setDueDate("");
    setLines([{ id: Date.now(), productId: availableProducts[0]?.id ?? 0, quantity: 1 }]);
    setCreating(false);
  };

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!customer.trim() || !invoiceLines.length || invoiceLines.some((line) => !line.productId || line.quantity <= 0)) return;
    if (paymentType === "credit" && !dueDate) return;
    if (onCreate({ customer: customer.trim(), contact: contact.trim(), paymentType, dueDate: paymentType === "credit" ? dueDate : undefined, lines: invoiceLines })) resetForm();
  };

  const shareInvoice = (invoice: Invoice) => {
    const linesText = invoice.lines.map((line) => `- ${line.productName} ${line.quantity}x ${rupiah(line.unitPrice)}`).join("\n");
    const message = `Faktur ${invoice.number}\nToko Kelontong Berkah\n\nPelanggan: ${invoice.customer}\n${linesText}\n\nTotal: ${rupiah(invoice.total)}\nStatus: ${invoice.status === "paid" ? "Lunas" : "Belum lunas"}`;
    window.open(`https://wa.me/?text=${encodeURIComponent(message)}`, "_blank", "noopener,noreferrer");
  };

  const printInvoice = (invoice: Invoice) => {
    const popup = window.open("", "_blank", "width=820,height=900");
    if (!popup) return;
    const escape = (value: string) => value.replace(/[&<>"']/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" })[character] ?? character);
    popup.document.write(`<!doctype html><html lang="id"><head><title>${escape(invoice.number)}</title><style>body{font-family:Arial,sans-serif;color:#0f172a;margin:48px}header{display:flex;justify-content:space-between;border-bottom:2px solid #2563eb;padding-bottom:20px;margin-bottom:28px}h1{color:#2563eb;margin:0}p{margin:5px 0;color:#475569}table{width:100%;border-collapse:collapse;margin-top:28px}th,td{padding:12px;border-bottom:1px solid #e2e8f0;text-align:left}th{font-size:12px;text-transform:uppercase;color:#64748b}.right{text-align:right}.total{font-size:20px;font-weight:700;color:#1d4ed8}.status{margin-top:28px;padding:14px;background:#eff6ff;border-radius:10px}@media print{body{margin:24px}}</style></head><body><header><div><h1>Stokku</h1><p>Toko Kelontong Berkah</p></div><div class="right"><strong>${escape(invoice.number)}</strong><p>${escape(invoice.date)}</p></div></header><section><strong>Tagihan kepada</strong><p>${escape(invoice.customer)}</p><p>${escape(invoice.contact || "-")}</p></section><table><thead><tr><th>Produk</th><th>Qty</th><th>Harga</th><th class="right">Subtotal</th></tr></thead><tbody>${invoice.lines.map((line) => `<tr><td>${escape(line.productName)}</td><td>${line.quantity}</td><td>${rupiah(line.unitPrice)}</td><td class="right">${rupiah(line.quantity * line.unitPrice)}</td></tr>`).join("")}</tbody><tfoot><tr><td colspan="3"><strong>Total tagihan</strong></td><td class="right total">${rupiah(invoice.total)}</td></tr></tfoot></table><div class="status"><strong>Status: ${invoice.status === "paid" ? "Lunas" : "Belum lunas"}</strong>${invoice.dueDate ? `<p>Jatuh tempo: ${new Date(invoice.dueDate).toLocaleDateString("id-ID")}</p>` : ""}</div><script>window.onload=()=>window.print();</script></body></html>`);
    popup.document.close();
  };

  return (
    <div className="space-y-6">
      <section className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
          <div className="mb-3 inline-flex items-center gap-2 rounded-full bg-sky-50 px-3 py-1 text-xs font-bold text-sky-700"><Icon name="shield" className="size-3.5" />{role === "admin" ? "Admin · Pembuat faktur" : "Manager · Review & koreksi"}</div>
          <h2 className="text-2xl font-bold tracking-tight">Faktur penjualan</h2>
          <p className="mt-1 text-sm text-slate-500">{role === "admin" ? "Catat pesanan, pembayaran, dan tindak lanjuti koreksi Manager." : "Periksa faktur yang dibuat Admin dan berikan komentar bila perlu dikoreksi."}</p>
        </div>
        {role === "admin" && <Button onClick={() => setCreating(!creating)}><Icon name={creating ? "close" : "plus"} className="size-4" />{creating ? "Tutup form" : "Buat faktur"}</Button>}
      </section>

      {creating && role === "admin" && (
        <form onSubmit={submit} className="rounded-2xl border border-blue-100 bg-white p-6 shadow-lg shadow-blue-100/50 sm:p-8">
          <div className="flex items-start gap-3 border-b border-slate-100 pb-5">
            <span className="grid size-10 place-items-center rounded-xl bg-blue-50 text-blue-700"><Icon name="invoice" /></span>
            <div><h3 className="font-bold">Faktur baru</h3><p className="mt-1 text-xs text-slate-500">Stok akan dipotong setelah faktur disimpan.</p></div>
          </div>
          <div className="mt-6 grid gap-5 sm:grid-cols-2">
            <label className="block"><span className="mb-2 block text-sm font-semibold text-slate-700">Nama pelanggan / toko</span><input value={customer} onChange={(event) => setCustomer(event.target.value)} placeholder="Contoh: Warung Bu Sari" required className="h-11 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-slate-400 focus:ring-4 focus:ring-slate-100" /></label>
            <label className="block"><span className="mb-2 block text-sm font-semibold text-slate-700">Kontak pelanggan</span><input value={contact} onChange={(event) => setContact(event.target.value)} placeholder="Nomor WhatsApp atau email" className="h-11 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-slate-400 focus:ring-4 focus:ring-slate-100" /></label>
          </div>

          <div className="mt-7">
            <div className="flex items-center justify-between"><div><h4 className="text-sm font-bold">Detail pesanan</h4><p className="mt-1 text-xs text-slate-500">Pilih produk dan jumlah yang dipesan.</p></div><Button variant="secondary" disabled={lines.length >= availableProducts.length} onClick={() => {
              const used = new Set(lines.map((line) => line.productId));
              const next = availableProducts.find((product) => !used.has(product.id));
              if (next) setLines((items) => [...items, { id: Date.now(), productId: next.id, quantity: 1 }]);
            }}><Icon name="plus" className="size-4" />Item</Button></div>
            <div className="mt-4 space-y-3">
              {lines.map((line, index) => {
                const selected = products.find((product) => product.id === line.productId);
                return (
                  <div key={line.id} className="grid gap-3 rounded-xl bg-slate-50 p-3 sm:grid-cols-[1fr_8rem_9rem_auto] sm:items-end">
                    <label className="block"><span className="mb-2 block text-xs font-semibold text-slate-600">Produk {index + 1}</span><select value={line.productId} onChange={(event) => setLines((items) => items.map((item) => item.id === line.id ? { ...item, productId: Number(event.target.value) } : item))} className="h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm outline-none">
                      {availableProducts.filter((product) => product.id === line.productId || !lines.some((item) => item.productId === product.id)).map((product) => <option key={product.id} value={product.id}>{product.name} · stok {product.stock}</option>)}
                    </select></label>
                    <label className="block"><span className="mb-2 block text-xs font-semibold text-slate-600">Jumlah</span><input type="number" min={1} max={selected?.stock ?? 1} value={line.quantity} onChange={(event) => setLines((items) => items.map((item) => item.id === line.id ? { ...item, quantity: Number(event.target.value) } : item))} className="h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm outline-none" /></label>
                    <div><p className="mb-2 text-xs font-semibold text-slate-600">Subtotal</p><div className="flex h-11 items-center rounded-xl bg-white px-3 text-sm font-bold">{rupiah((selected?.price ?? 0) * line.quantity)}</div></div>
                    <button type="button" disabled={lines.length === 1} onClick={() => setLines((items) => items.filter((item) => item.id !== line.id))} className="grid size-11 place-items-center rounded-xl text-slate-400 transition hover:bg-rose-50 hover:text-rose-600 disabled:opacity-30" aria-label="Hapus item"><Icon name="trash" className="size-4" /></button>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="mt-7 grid gap-5 border-t border-slate-100 pt-6 sm:grid-cols-2">
            <div>
              <p className="mb-2 text-sm font-semibold text-slate-700">Metode pembayaran</p>
              <div className="grid grid-cols-2 gap-2">
                {(["cash", "credit"] as const).map((method) => <button key={method} type="button" onClick={() => setPaymentType(method)} className={`rounded-xl border px-4 py-3 text-left transition ${paymentType === method ? "border-blue-300 bg-blue-50 ring-2 ring-blue-100" : "border-slate-200"}`}><span className="block text-sm font-bold">{method === "cash" ? "Cash" : "Credit"}</span><span className="mt-0.5 block text-xs text-slate-500">{method === "cash" ? "Langsung lunas" : "Bayar tempo"}</span></button>)}
              </div>
              {paymentType === "credit" && <label className="mt-4 block"><span className="mb-2 block text-sm font-semibold text-slate-700">Tanggal jatuh tempo</span><input type="date" value={dueDate} onChange={(event) => setDueDate(event.target.value)} required className="h-11 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none" /></label>}
            </div>
            <div className="rounded-2xl bg-blue-600 p-5 text-white">
              <p className="text-sm font-medium text-blue-100">Total tagihan</p><p className="mt-2 text-3xl font-extrabold tracking-tight">{rupiah(total)}</p>
              <div className="mt-5 flex justify-end"><Button type="submit" disabled={total <= 0} className="bg-white text-blue-700 shadow-none hover:bg-blue-50"><Icon name="check" className="size-4" />Simpan faktur</Button></div>
            </div>
          </div>
        </form>
      )}

      <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="border-b border-slate-100 px-5 py-4 sm:px-6"><h3 className="font-bold">Riwayat faktur</h3><p className="mt-1 text-xs text-slate-500">{invoices.length} transaksi tersimpan</p></div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[780px] text-left">
            <thead><tr className="border-b border-slate-100 text-[11px] font-bold uppercase tracking-wide text-slate-400"><th className="px-6 py-3.5">Nomor</th><th className="px-4 py-3.5">Pelanggan</th><th className="px-4 py-3.5">Pembayaran</th><th className="px-4 py-3.5">Total</th><th className="px-4 py-3.5">Status</th><th className="px-6 py-3.5 text-right">Aksi</th></tr></thead>
            <tbody className="divide-y divide-slate-100">{invoices.map((invoice) => (
              <tr key={invoice.id} className="hover:bg-slate-50/80">
                <td className="px-6 py-4"><p className="text-sm font-bold text-blue-700">{invoice.number}</p><p className="mt-1 text-xs text-slate-400">{invoice.date}</p>{invoice.comments.length > 0 && <span className="mt-2 inline-flex rounded-full bg-violet-50 px-2 py-0.5 text-[11px] font-bold text-violet-700">{invoice.comments.length} komentar</span>}</td>
                <td className="px-4 py-4"><p className="text-sm font-semibold">{invoice.customer}</p><p className="mt-1 text-xs text-slate-400">{invoice.lines.length} jenis produk</p></td>
                <td className="px-4 py-4 text-sm capitalize text-slate-600">{invoice.paymentType}{invoice.dueDate && <span className="block text-xs text-slate-400">Tempo {new Date(invoice.dueDate).toLocaleDateString("id-ID")}</span>}</td>
                <td className="px-4 py-4 text-sm font-bold">{rupiah(invoice.total)}</td>
                <td className="px-4 py-4"><span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-bold ${invoice.status === "paid" ? "bg-emerald-50 text-emerald-700" : "bg-amber-50 text-amber-700"}`}>{invoice.status === "paid" ? "Lunas" : "Belum lunas"}</span></td>
                <td className="px-6 py-4"><div className="flex justify-end gap-1"><Button variant="ghost" className="px-3 py-2" onClick={() => { setReviewingId(invoice.id); setComment(""); }}><Icon name="history" className="size-4" />{role === "manager" ? "Review" : "Koreksi"}</Button><Button variant="ghost" className="px-3 py-2" onClick={() => printInvoice(invoice)}><Icon name="print" className="size-4" />Cetak</Button><Button variant="ghost" className="px-3 py-2" onClick={() => shareInvoice(invoice)}><Icon name="share" className="size-4" /></Button></div></td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      </section>

      {reviewingInvoice && (
        <section className="rounded-2xl border border-violet-100 bg-white p-6 shadow-lg shadow-violet-100/40 sm:p-7">
          <div className="flex items-start justify-between gap-4 border-b border-slate-100 pb-5">
            <div className="flex items-start gap-3">
              <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-violet-50 text-violet-700"><Icon name="history" /></span>
              <div><h3 className="font-bold">Review {reviewingInvoice.number}</h3><p className="mt-1 text-xs text-slate-500">{reviewingInvoice.customer} · {rupiah(reviewingInvoice.total)}</p></div>
            </div>
            <button onClick={() => setReviewingId(null)} className="rounded-xl p-2 text-slate-400 hover:bg-slate-100" aria-label="Tutup review"><Icon name="close" /></button>
          </div>

          <div className="mt-5 space-y-3">
            {reviewingInvoice.comments.length === 0 ? (
              <div className="rounded-xl border border-dashed border-slate-200 p-5 text-center"><p className="text-sm font-semibold text-slate-600">Belum ada komentar koreksi</p><p className="mt-1 text-xs text-slate-400">{role === "manager" ? "Tambahkan catatan jika menemukan kesalahan pada faktur." : "Komentar dari Manager akan muncul di sini."}</p></div>
            ) : reviewingInvoice.comments.map((item) => (
              <div key={item.id} className="flex gap-3 rounded-xl bg-violet-50/60 p-4">
                <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-violet-600 text-xs font-bold text-white">BS</span>
                <div className="min-w-0"><div className="flex flex-wrap items-center gap-x-2"><p className="text-sm font-bold">{item.actor}</p><span className="text-[11px] text-slate-400">{item.date}</span></div><p className="mt-1.5 text-sm leading-relaxed text-slate-600">{item.message}</p></div>
              </div>
            ))}
          </div>

          {role === "manager" && (
            <form onSubmit={(event) => { event.preventDefault(); if (!comment.trim()) return; onComment(reviewingInvoice.id, comment); setComment(""); }} className="mt-5 rounded-2xl border border-slate-200 bg-slate-50 p-4">
              <label className="block"><span className="mb-2 block text-sm font-bold text-slate-700">Komentar koreksi</span><textarea value={comment} onChange={(event) => setComment(event.target.value)} rows={3} maxLength={500} placeholder="Contoh: Mohon periksa kembali jumlah Gula Pasir, pesanan pelanggan seharusnya 4 unit." className="w-full resize-none rounded-xl border border-slate-200 bg-white p-3 text-sm outline-none transition placeholder:text-slate-400 focus:border-violet-300 focus:ring-4 focus:ring-violet-100" /></label>
              <div className="mt-3 flex items-center justify-between gap-3"><p className="text-xs text-slate-400">{comment.length}/500 karakter</p><Button type="submit" disabled={!comment.trim()}>Kirim komentar</Button></div>
            </form>
          )}
          {role === "admin" && reviewingInvoice.comments.length > 0 && <div className="mt-5 rounded-xl bg-amber-50 px-4 py-3 text-xs leading-relaxed text-amber-800">Periksa komentar Manager dan lakukan koreksi pada sistem pencatatan sebelum faktur diteruskan ke pelanggan.</div>}
        </section>
      )}
    </div>
  );
}

function ProfitPareto({ records }: { records: ProfitRecord[] }) {
  const [period, setPeriod] = useState<"week" | "month">("week");
  const data = useMemo(() => {
    const grouped = new Map<string, { label: string; value: number }>();
    records.forEach((record) => {
      const date = new Date(`${record.date}T00:00:00`);
      let key: string;
      let label: string;
      if (period === "month") {
        key = record.date.slice(0, 7);
        label = new Intl.DateTimeFormat("id-ID", { month: "short", year: "2-digit" }).format(date);
      } else {
        const start = new Date(date);
        const dayFromMonday = (date.getDay() + 6) % 7;
        start.setDate(date.getDate() - dayFromMonday);
        key = start.toISOString().slice(0, 10);
        label = new Intl.DateTimeFormat("id-ID", { day: "numeric", month: "short" }).format(start);
      }
      const current = grouped.get(key);
      grouped.set(key, { label, value: (current?.value ?? 0) + record.profit });
    });
    return [...grouped.values()].sort((a, b) => b.value - a.value);
  }, [period, records]);

  const total = data.reduce((sum, item) => sum + item.value, 0);
  const maxValue = Math.max(...data.map((item) => item.value), 1);
  const chartLeft = 62;
  const chartRight = 838;
  const chartTop = 30;
  const chartBottom = 248;
  const plotWidth = chartRight - chartLeft;
  const plotHeight = chartBottom - chartTop;
  const slot = plotWidth / Math.max(data.length, 1);
  const barWidth = Math.min(42, slot * 0.58);
  let cumulative = 0;
  const points = data.map((item, index) => {
    cumulative += item.value;
    return {
      x: chartLeft + slot * index + slot / 2,
      y: chartBottom - (cumulative / Math.max(total, 1)) * plotHeight,
      percentage: Math.round((cumulative / Math.max(total, 1)) * 100),
    };
  });

  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-7">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
        <div>
          <div className="flex items-center gap-2"><span className="grid size-9 place-items-center rounded-xl bg-indigo-50 text-indigo-700"><Icon name="chart" className="size-[18px]" /></span><div><h3 className="font-bold">Pareto keuntungan</h3><p className="mt-0.5 text-xs text-slate-500">Kontribusi keuntungan terbesar dan akumulasi hingga 100%</p></div></div>
        </div>
        <div className="inline-flex rounded-xl bg-slate-100 p-1">
          {(["week", "month"] as const).map((item) => <button key={item} onClick={() => setPeriod(item)} className={`rounded-lg px-4 py-2 text-xs font-bold transition ${period === item ? "bg-white text-blue-700 shadow-sm" : "text-slate-500 hover:text-slate-800"}`}>{item === "week" ? "Mingguan" : "Bulanan"}</button>)}
        </div>
      </div>

      <div className="mt-5 grid gap-3 sm:grid-cols-3">
        <SummaryValue label={`Total keuntungan ${period === "week" ? "mingguan" : "bulanan"}`} value={rupiah(total)} />
        <SummaryValue label="Periode kontribusi tertinggi" value={data[0]?.label ?? "-"} />
        <SummaryValue label="Keuntungan tertinggi" value={rupiah(data[0]?.value ?? 0)} />
      </div>

      <div className="mt-6 overflow-x-auto rounded-2xl border border-slate-100 bg-slate-50/50 p-3">
        <svg viewBox="0 0 900 315" className="min-w-[760px]" role="img" aria-label={`Pareto keuntungan ${period === "week" ? "mingguan" : "bulanan"}`}>
          {[0, 0.5, 1].map((ratio) => {
            const y = chartBottom - ratio * plotHeight;
            return <g key={ratio}><line x1={chartLeft} x2={chartRight} y1={y} y2={y} className="stroke-slate-200" strokeDasharray={ratio === 0 ? undefined : "4 5"} /><text x={chartLeft - 10} y={y + 4} textAnchor="end" className="fill-slate-400 text-[10px]">{compactRupiah(maxValue * ratio)}</text><text x={chartRight + 10} y={y + 4} className="fill-amber-600 text-[10px]">{Math.round(ratio * 100)}%</text></g>;
          })}
          {data.map((item, index) => {
            const height = (item.value / maxValue) * plotHeight;
            const x = chartLeft + slot * index + (slot - barWidth) / 2;
            return (
              <g key={item.label}>
                <rect x={x} y={chartBottom - height} width={barWidth} height={height} rx="5" className="fill-blue-500"><title>{item.label}: {rupiah(item.value)}</title></rect>
                <text x={x + barWidth / 2} y={chartBottom + 18} textAnchor="middle" className="fill-slate-500 text-[9px] font-semibold">{item.label}</text>
              </g>
            );
          })}
          <polyline points={points.map((point) => `${point.x},${point.y}`).join(" ")} fill="none" className="stroke-amber-500" strokeWidth="3" strokeLinejoin="round" strokeLinecap="round" />
          {points.map((point, index) => <g key={`${point.x}-${point.y}`}><circle cx={point.x} cy={point.y} r="5" className="fill-white stroke-amber-500" strokeWidth="3"><title>Akumulasi {point.percentage}%</title></circle>{(index === 0 || index === points.length - 1) && <text x={point.x} y={point.y - 11} textAnchor="middle" className="fill-amber-700 text-[9px] font-bold">{point.percentage}%</text>}</g>)}
          <g transform="translate(300 292)"><rect width="12" height="12" rx="3" className="fill-blue-500" /><text x="18" y="10" className="fill-slate-500 text-[10px]">Keuntungan</text><line x1="105" x2="130" y1="6" y2="6" className="stroke-amber-500" strokeWidth="3" /><circle cx="117.5" cy="6" r="3" className="fill-white stroke-amber-500" strokeWidth="2" /><text x="138" y="10" className="fill-slate-500 text-[10px]">Kumulatif</text></g>
        </svg>
      </div>
      <p className="mt-3 text-xs leading-relaxed text-slate-400">Batang diurutkan dari keuntungan terbesar. Garis menunjukkan persentase kumulatif untuk membantu Manager mengenali periode yang paling berkontribusi.</p>
    </section>
  );
}

function Statistics({ products, totals, profitRecords }: { products: Product[]; totals: { stock: number; cost: number; revenue: number; low: number }; profitRecords: ProfitRecord[] }) {
  const profit = totals.revenue - totals.cost;
  const margin = totals.revenue ? Math.round((profit / totals.revenue) * 100) : 0;
  const maxValue = Math.max(...products.map((product) => product.price * product.stock));
  const rejectedUnits = products.reduce((sum, product) => sum + product.rejectStock, 0);
  const rejectLoss = products.reduce((sum, product) => sum + product.rejectStock * product.cost, 0);
  return (
    <div className="space-y-7">
      <div><div className="flex items-center gap-2"><span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-bold text-blue-700">Khusus Manager</span></div><h2 className="mt-3 text-2xl font-bold tracking-tight">Nilai dan potensi inventaris</h2><p className="mt-1 text-sm text-slate-500">Perhitungan berdasarkan seluruh stok yang tersedia saat ini.</p></div>
      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <div className="rounded-2xl bg-gradient-to-br from-blue-600 to-blue-700 p-6 text-white shadow-lg shadow-blue-200"><span className="grid size-10 place-items-center rounded-xl bg-white/15"><Icon name="wallet" /></span><p className="mt-6 text-sm font-medium text-blue-100">Total modal stok</p><p className="mt-2 text-3xl font-bold tracking-tight">{rupiah(totals.cost)}</p><p className="mt-2 text-xs text-blue-100">Nilai pembelian {totals.stock} unit</p></div>
        <div className="rounded-2xl border border-slate-200 bg-white p-6"><span className="grid size-10 place-items-center rounded-xl bg-blue-50 text-blue-700"><Icon name="chart" /></span><p className="mt-6 text-sm font-medium text-slate-500">Potensi omzet</p><p className="mt-2 text-3xl font-bold tracking-tight">{rupiah(totals.revenue)}</p><p className="mt-2 text-xs text-slate-400">Jika seluruh stok terjual</p></div>
        <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6"><span className="grid size-10 place-items-center rounded-xl bg-emerald-100 text-emerald-700"><Icon name="trend" /></span><p className="mt-6 text-sm font-medium text-emerald-700">Perkiraan keuntungan</p><p className="mt-2 text-3xl font-bold tracking-tight text-emerald-950">{rupiah(profit)}</p><p className="mt-2 text-xs font-medium text-emerald-700">Margin potensi {margin}%</p></div>
        <div className="rounded-2xl border border-rose-200 bg-rose-50 p-6"><span className="grid size-10 place-items-center rounded-xl bg-rose-100 text-rose-700"><Icon name="box" /></span><p className="mt-6 text-sm font-medium text-rose-700">Kerugian barang reject</p><p className="mt-2 text-3xl font-bold tracking-tight text-rose-950">{rupiah(rejectLoss)}</p><p className="mt-2 text-xs font-medium text-rose-700">{rejectedUnits} unit tercatat rusak</p></div>
      </section>
      <ProfitPareto records={profitRecords} />
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-7">
        <div><h3 className="font-bold">Kontribusi nilai jual</h3><p className="mt-1 text-xs text-slate-500">Potensi nilai setiap produk dari stok saat ini</p></div>
        <div className="mt-7 space-y-5">
          {[...products].sort((a, b) => b.price * b.stock - a.price * a.stock).map((product) => {
            const value = product.price * product.stock;
            return <div key={product.id}><div className="mb-2 flex items-center justify-between gap-4"><div><p className="text-sm font-semibold">{product.name}</p><p className="text-xs text-slate-400">{product.stock} unit</p></div><p className="text-sm font-bold">{rupiah(value)}</p></div><div className="h-2 overflow-hidden rounded-full bg-blue-50"><div className="h-full rounded-full bg-blue-500" style={{ width: `${Math.max(5, (value / maxValue) * 100)}%` }} /></div></div>;
          })}
        </div>
      </section>
    </div>
  );
}

function Profile({ role, onSwitchRole, onLogout }: { role: Role; onSwitchRole: (role: Role) => void; onLogout: () => void }) {
  const currentUser = role === "manager"
    ? { name: "Budi Santoso", initials: "BS", label: "Manager" }
    : { name: "Rina Amelia", initials: "RA", label: "Admin Stok" };

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <section className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-blue-700 via-blue-600 to-sky-400 p-6 text-white shadow-xl shadow-blue-200/70 sm:p-8">
        <div className="pointer-events-none absolute -right-20 -top-24 size-64 rounded-full bg-white/10" />
        <div className="pointer-events-none absolute -bottom-28 left-1/3 size-56 rounded-full bg-sky-300/20" />
        <div className="relative">
          <div className="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex items-center gap-4">
              <span className="grid size-20 shrink-0 place-items-center rounded-2xl border border-white/70 bg-white text-xl font-extrabold text-blue-700 shadow-lg shadow-blue-900/10">{currentUser.initials}</span>
              <div>
                <h2 className="text-2xl font-extrabold leading-tight tracking-tight text-white sm:text-3xl">{currentUser.name}</h2>
                <p className="mt-1.5 text-sm font-semibold text-blue-100">{currentUser.label}</p>
              </div>
            </div>
            <Button variant="secondary" onClick={onLogout} className="border-white/70 bg-white text-blue-700 shadow-sm hover:border-white hover:bg-blue-50">
              <Icon name="logout" className="size-4" />Keluar
            </Button>
          </div>

          <div className="mt-8 grid gap-3 sm:grid-cols-3">
            <ProfileInfo icon="user" label="Nama pengguna" value={currentUser.name} />
            <ProfileInfo icon="shield" label="Role akun" value={currentUser.label} />
            <ProfileInfo icon="store" label="Nama toko" value="Toko Kelontong Berkah" />
          </div>
        </div>
      </section>

      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-7">
        <div>
          <h3 className="font-bold">Ganti akun</h3>
          <p className="mt-1 text-sm text-slate-500">Pilih akun lain untuk mengakses sistem sesuai hak aksesnya.</p>
        </div>
        <div className="mt-5 grid gap-3 sm:grid-cols-2">
          {([
            ["manager", "BS", "Budi Santoso", "Manager · Analitik & review faktur"],
            ["admin", "RA", "Rina Amelia", "Admin Stok · Produk & faktur"],
          ] as [Role, string, string, string][]).map(([accountRole, initials, name, description]) => {
            const active = role === accountRole;
            return (
              <button
                key={accountRole}
                onClick={() => !active && onSwitchRole(accountRole)}
                className={`flex items-center gap-3 rounded-2xl border p-4 text-left transition ${active ? "border-blue-300 bg-blue-50 ring-2 ring-blue-100" : "border-slate-200 hover:border-blue-200 hover:bg-blue-50/50"}`}
              >
                <span className={`grid size-11 shrink-0 place-items-center rounded-xl text-xs font-bold ${active ? "bg-blue-600 text-white" : "bg-blue-50 text-blue-700"}`}>{initials}</span>
                <span className="min-w-0 flex-1"><span className="block truncate text-sm font-bold">{name}</span><span className="mt-0.5 block text-xs text-slate-500">{description}</span></span>
                {active ? <span className="grid size-6 place-items-center rounded-full bg-blue-600 text-white"><Icon name="check" className="size-3.5" /></span> : <Icon name="chevron" className="size-4 text-slate-400" />}
              </button>
            );
          })}
        </div>
      </section>

      <section className="flex flex-col justify-between gap-4 rounded-2xl border border-blue-100 bg-blue-50/60 p-6 sm:flex-row sm:items-center">
        <div><p className="font-bold text-blue-950">Keluar dari Stokku</p><p className="mt-1 text-sm text-blue-700/70">Anda perlu memilih akun kembali untuk masuk ke sistem.</p></div>
        <Button variant="secondary" onClick={onLogout} className="border-blue-200 text-blue-700 hover:bg-white"><Icon name="logout" className="size-4" />Logout akun</Button>
      </section>
    </div>
  );
}

function ProfileInfo({ icon, label, value }: { icon: string; label: string; value: string }) {
  return (
    <div className="flex items-center gap-3 rounded-2xl border border-white/25 bg-white/15 p-4 backdrop-blur-sm">
      <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-white text-blue-600 shadow-sm"><Icon name={icon} className="size-[18px]" /></span>
      <div className="min-w-0"><p className="text-xs font-medium text-blue-100">{label}</p><p className="mt-1 truncate text-sm font-bold text-white">{value}</p></div>
    </div>
  );
}

export default App;
