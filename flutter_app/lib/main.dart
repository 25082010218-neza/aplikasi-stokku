import "package:flutter/material.dart";
import "api_service.dart";
import "models.dart";

void main() {
  runApp(const StokkuApp());
}

class StokkuApp extends StatelessWidget {
  const StokkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Stokku Desktop Suite",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
        fontFamily: "Segoe UI",
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final StokkuApi _api = StokkuApi();

  String _role = "admin"; // "manager" | "admin"
  bool _isLoggedIn = false; // Tampilkan halaman login terlebih dahulu
  String _storeName = "Toko Kelontong Berkah";
  String _userName = "Rina Amelia";
  String _currentView =
      "dashboard"; // dashboard, products, add, invoices, statistics, profile

  // Form Login Controllers
  final TextEditingController _loginStoreCtrl =
      TextEditingController(text: "Toko Kelontong Berkah");
  final TextEditingController _loginUserCtrl =
      TextEditingController(text: "Rina Amelia");
  final TextEditingController _loginPassCtrl =
      TextEditingController(text: "admin123");
  bool _obscurePassword = true;
  String _selectedLoginRole = "admin"; // "admin" | "manager"

  // Search & Filter
  String _searchQuery = "";
  String _selectedCategory = "Semua";

  // Data Store
  late List<Product> _products;
  late List<Invoice> _invoices;
  late List<ProfitRecord> _profitRecords;
  late List<NotificationItem> _notifications;

  // Widget Logo Stokku
  static Widget buildAppLogo({double size = 42, double radius = 12}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          "assets/images/logo.png",
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CustomPaint(
            size: Size(size, size),
            painter: _StokkuLogoPainter(),
          ),
        ),
      ),
    );
  }

  // Formatting helpers
  static String formatRupiah(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(".");
      }
      buffer.write(s[i]);
    }
    return "Rp ${buffer.toString()}";
  }

  static String formatCompactRupiah(int value) {
    if (value >= 1000000) {
      final jt = (value / 1000000).toStringAsFixed(1);
      return "Rp $jt jt";
    }
    return formatRupiah(value);
  }

  String get _userInitials {
    final parts = _userName.trim().split(" ");
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return _role == "manager" ? "BS" : "RA";
  }

  @override
  void initState() {
    super.initState();
    _initInitialData();
    _fetchApiProducts();
  }

  @override
  void dispose() {
    _loginStoreCtrl.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _api.close();
    super.dispose();
  }

  void _initInitialData() {
    _products = [
      Product(
          id: 1,
          name: "Minyak Goreng 1L",
          sku: "MK-001",
          category: "Sembako",
          cost: 12000,
          price: 14500,
          stock: 2,
          rejectStock: 0,
          minStock: 8),
      Product(
          id: 2,
          name: "Beras Premium 5kg",
          sku: "BR-005",
          category: "Sembako",
          cost: 58000,
          price: 68000,
          stock: 5,
          rejectStock: 0,
          minStock: 10),
      Product(
          id: 3,
          name: "Gula Pasir 1kg",
          sku: "GL-010",
          category: "Sembako",
          cost: 12500,
          price: 14500,
          stock: 45,
          rejectStock: 0,
          minStock: 10),
      Product(
          id: 4,
          name: "Teh Celup Kotak",
          sku: "TH-022",
          category: "Minuman",
          cost: 4800,
          price: 6500,
          stock: 30,
          rejectStock: 0,
          minStock: 8),
      Product(
          id: 5,
          name: "Kopi Sachet 10pcs",
          sku: "KP-031",
          category: "Minuman",
          cost: 9500,
          price: 12000,
          stock: 25,
          rejectStock: 0,
          minStock: 8),
      Product(
          id: 6,
          name: "Keripik Singkong Balado",
          sku: "SN-014",
          category: "Makanan Ringan",
          cost: 6500,
          price: 9000,
          stock: 50,
          rejectStock: 0,
          minStock: 12),
    ];

    _invoices = [
      Invoice(
        id: 1,
        number: "INV-2026-001",
        customer: "Warung Bu Sari",
        contact: "0812 3456 7890",
        paymentType: "credit",
        status: "unpaid",
        dueDate: "2026-10-30",
        date: "15 Okt 2026",
        lines: [
          InvoiceLine(
              productId: 3,
              productName: "Gula Pasir 1kg",
              quantity: 5,
              unitPrice: 14500),
        ],
        total: 72500,
        comments: [],
      ),
    ];

    _profitRecords = [
      ProfitRecord(date: "2026-07-04", profit: 340000),
      ProfitRecord(date: "2026-07-11", profit: 465000),
      ProfitRecord(date: "2026-07-19", profit: 295000),
      ProfitRecord(date: "2026-07-27", profit: 525000),
      ProfitRecord(date: "2026-08-05", profit: 410000),
      ProfitRecord(date: "2026-08-13", profit: 580000),
      ProfitRecord(date: "2026-08-22", profit: 490000),
      ProfitRecord(date: "2026-08-29", profit: 635000),
      ProfitRecord(date: "2026-09-06", profit: 545000),
      ProfitRecord(date: "2026-09-14", profit: 710000),
      ProfitRecord(date: "2026-09-23", profit: 620000),
      ProfitRecord(date: "2026-10-02", profit: 680000),
      ProfitRecord(date: "2026-10-09", profit: 795000),
      ProfitRecord(date: "2026-10-15", profit: 745000),
    ];

    _notifications = [
      NotificationItem(
        id: 1,
        product: "Beras Premium 5kg",
        actor: "Budi Santoso",
        oldCost: 56000,
        newCost: 58000,
        oldPrice: 65000,
        newPrice: 68000,
        date: "Hari ini, 09.42",
      ),
      NotificationItem(
        id: 2,
        product: "Kopi Sachet 10pcs",
        actor: "Budi Santoso",
        oldCost: 9000,
        newCost: 9500,
        oldPrice: 11500,
        newPrice: 12000,
        date: "Kemarin, 15.18",
      ),
    ];
  }

  Future<void> _fetchApiProducts() async {
    final list = await _api.getProducts();
    if (list.isNotEmpty && mounted) {
      setState(() {
        _products = list;
      });
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _switchRole(String nextRole) {
    setState(() {
      _role = nextRole;
      if (nextRole == "admin" && _currentView == "statistics") {
        _currentView = "dashboard";
      } else if (nextRole == "manager" && _currentView == "add") {
        _currentView = "dashboard";
      }
    });
    _showToast(
        "Masuk sebagai ${nextRole == 'manager' ? 'Manager' : 'Admin Stok'}");
  }

  // Edit Price Dialog (Manager)
  void _openEditPriceDialog(Product product) {
    if (_role != "manager") return;
    final costController = TextEditingController(text: product.cost.toString());
    final priceController =
        TextEditingController(text: product.price.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ubah Harga Produk",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(product.name,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Harga Modal / HPP (Rp)",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Harga Jual (Rp)",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newCost = int.tryParse(costController.text) ?? product.cost;
              final newPrice =
                  int.tryParse(priceController.text) ?? product.price;

              if (newCost > 0 && newPrice > 0) {
                setState(() {
                  product.cost = newCost;
                  product.price = newPrice;
                  _notifications.insert(
                    0,
                    NotificationItem(
                      id: DateTime.now().millisecondsSinceEpoch,
                      product: product.name,
                      actor: "Budi Santoso",
                      oldCost: product.cost,
                      newCost: newCost,
                      oldPrice: product.price,
                      newPrice: newPrice,
                      date: "Baru saja",
                    ),
                  );
                });
                Navigator.pop(ctx);
                _showToast("Harga ${product.name} berhasil diperbarui");
              }
            },
            child: const Text("Simpan Perubahan"),
          ),
        ],
      ),
    );
  }

  // Delete Product Confirmation (Admin Only)
  void _confirmDeleteProduct(Product product) {
    if (_role != "admin") return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text("Hapus Produk",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Apakah Anda yakin ingin menghapus produk \"${product.name}\" (${product.sku})?",
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Kategori: ${product.category} · Stok: ${product.stock} pcs",
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _products.removeWhere((p) => p.id == product.id);
              });
              _api.deleteProduct(product.id);
              _showToast("Produk \"${product.name}\" berhasil dihapus");
            },
            child: const Text("Hapus Produk"),
          ),
        ],
      ),
    );
  }

  // Notifications Dialog
  void _openNotificationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.history_rounded, color: Color(0xFFD97706)),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Riwayat Perubahan Harga",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Dapat dipantau oleh Manager & Admin",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          height: 380,
          child: _notifications.isEmpty
              ? const Center(child: Text("Belum ada riwayat perubahan"))
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.price_change_outlined,
                            color: Color(0xFF2563EB), size: 18),
                      ),
                      title: Text(item.product,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            "${item.actor} mengubah harga: ${formatRupiah(item.oldPrice)} ➔ ${formatRupiah(item.newPrice)}",
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF334155)),
                          ),
                          Text(item.date,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return _buildLoginScreen();
    }

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar (Desktop Navigation)
          _buildSidebar(),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildHeader(),

                // Scrollable Body Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: _buildCurrentView(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          // Logo & Brand Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                buildAppLogo(size: 42, radius: 12),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Stokku",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB)),
                    ),
                    Text(
                      "DESKTOP SUITE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Navigation Menu List
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "MENU UTAMA",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(
                  key: "dashboard",
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: "Ringkasan",
                ),
                _buildNavItem(
                  key: "products",
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: "Daftar produk",
                ),
                if (_role == "admin")
                  _buildNavItem(
                    key: "add",
                    icon: Icons.add_circle_outline_rounded,
                    activeIcon: Icons.add_circle_rounded,
                    label: "Tambah produk",
                  ),
                _buildNavItem(
                  key: "invoices",
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: "Faktur",
                ),
                if (_role == "manager")
                  _buildNavItem(
                    key: "statistics",
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics_rounded,
                    label: "Statistik",
                  ),
                _buildNavItem(
                  key: "profile",
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: "Profil",
                ),
              ],
            ),
          ),

          // Role Switcher / User Profile Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showAccountSwitchDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _role == "manager"
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFE0F2FE),
                      child: Text(
                        _userInitials,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _role == "manager"
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _role == "manager" ? "Manager" : "Admin Stok",
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.unfold_more_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String key,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentView == key;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _currentView = key;
              if (key != "products") _searchQuery = "";
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountSwitchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Pilih Akun",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                selected: _role == "manager",
                selectedTileColor: const Color(0xFFEFF6FF),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Text("BS",
                      style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold)),
                ),
                title: const Text("Budi Santoso",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Manager"),
                trailing: _role == "manager"
                    ? const Icon(Icons.check, color: Color(0xFF2563EB))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _switchRole("manager");
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                selected: _role == "admin",
                selectedTileColor: const Color(0xFFE0F2FE),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Text("RA",
                      style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.bold)),
                ),
                title: const Text("Rina Amelia",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Admin Stok"),
                trailing: _role == "admin"
                    ? const Icon(Icons.check, color: Color(0xFF0284C7))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _switchRole("admin");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    String title = "Ringkasan Inventaris";
    if (_currentView == "products") title = "Daftar Produk";
    if (_currentView == "add") title = "Tambah Produk";
    if (_currentView == "invoices") title = "Faktur & Pemesanan";
    if (_currentView == "statistics") title = "Statistik Bisnis";
    if (_currentView == "profile") title = "Profil Akun";

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _role == "manager" ? "Akun Manager" : "Akun Admin",
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B)),
              ),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_rounded,
                        size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      _storeName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Notification Bell with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: Color(0xFF475569)),
                    onPressed: _openNotificationsDialog,
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  if (_notifications.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== VIEW ROUTER ====================
  Widget _buildCurrentView() {
    switch (_currentView) {
      case "dashboard":
        return _buildDashboardView();
      case "products":
        return _buildProductsView();
      case "add":
        return _buildAddProductView();
      case "invoices":
        return _buildInvoicesView();
      case "statistics":
        return _buildStatisticsView();
      case "profile":
        return _buildProfileView();
      default:
        return _buildDashboardView();
    }
  }

  // ==================== 1. DASHBOARD ====================
  Widget _buildDashboardView() {
    final totalStock = _products.fold<int>(0, (sum, p) => sum + p.stock);
    final totalSKU = _products.length;
    final lowStockItems =
        _products.where((p) => p.stock <= p.minStock).toList();
    final inventoryValue =
        _products.fold<int>(0, (sum, p) => sum + (p.cost * p.stock));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top 4 Metrics Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 48) / 4;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildMetricCard(
                  width: cardWidth.clamp(220, 300),
                  title: "Stok Layak Jual",
                  value: "$totalStock pcs",
                  icon: Icons.layers_outlined,
                  iconColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                ),
                _buildMetricCard(
                  width: cardWidth.clamp(220, 300),
                  title: "Jumlah Produk",
                  value: "$totalSKU SKU",
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFE0F2FE),
                ),
                _buildMetricCard(
                  width: cardWidth.clamp(220, 300),
                  title: "Stok Menipis / Kritis",
                  value: "${lowStockItems.length} Produk",
                  icon: Icons.warning_amber_rounded,
                  iconColor: lowStockItems.isNotEmpty
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF16A34A),
                  bgColor: lowStockItems.isNotEmpty
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF0FDF4),
                ),
                if (_role == "manager")
                  _buildMetricCard(
                    width: cardWidth.clamp(220, 300),
                    title: "Nilai Inventaris (Modal)",
                    value: formatCompactRupiah(inventoryValue),
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFF5F3FF),
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 28),

        // Urgent Action / Attention Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notification_important_outlined,
                          color: Color(0xFFEA580C), size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Perlu Segera Diperhatikan (Stok Menipis)",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _currentView = "products"),
                    icon: const Text("Semua Produk",
                        style: TextStyle(fontSize: 13)),
                    label: const Icon(Icons.arrow_forward_rounded, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (lowStockItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "Seluruh stok produk berada dalam batas aman.",
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lowStockItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = lowStockItems[index];
                    final isCritical = item.stock <= (item.minStock / 2);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      leading: CircleAvatar(
                        backgroundColor: isCritical
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFFEF3C7),
                        child: Icon(
                          isCritical
                              ? Icons.error_outline_rounded
                              : Icons.warning_amber_rounded,
                          color: isCritical
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      title: Text(item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                          "SKU: ${item.sku} · Min: ${item.minStock} pcs · Sisa: ${item.stock} pcs"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCritical
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCritical
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Text(
                              isCritical ? "Kritis" : "Menipis",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCritical
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                          if (_role == "manager") ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: "Ubah Harga",
                              onPressed: () => _openEditPriceDialog(item),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // ==================== 2. DAFTAR PRODUK ====================
  Widget _buildProductsView() {
    final filtered = _products.where((p) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == "Semua" || p.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText:
                      "Cari berdasarkan nama produk, SKU, atau kategori...",
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(width: 16),
            if (_role == "admin")
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => setState(() => _currentView = "add"),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("Tambah Produk",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                ["Semua", "Sembako", "Minuman", "Makanan Ringan"].map((cat) {
              final isSel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  selected: isSel,
                  label: Text(cat),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? Colors.white : const Color(0xFF475569),
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF2563EB),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                        color: isSel
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0)),
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Product Cards / Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(
                    child: Text("Tidak ada produk yang cocok dengan pencarian.",
                        style: TextStyle(color: Color(0xFF64748B))),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isCritical = item.stock <= (item.minStock / 2);
                    final isLow = item.stock <= item.minStock;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: Color(0xFF2563EB), size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(
                                  "${item.sku} · ${item.category}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatRupiah(item.price),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              if (_role == "manager")
                                Text("Modal: ${formatRupiah(item.cost)}",
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8))),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Text("${item.stock} pcs",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCritical
                                          ? const Color(0xFFFEF2F2)
                                          : isLow
                                              ? const Color(0xFFFFFBEB)
                                              : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isCritical
                                          ? "Kritis"
                                          : isLow
                                              ? "Menipis"
                                              : "Aman",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCritical
                                            ? const Color(0xFFDC2626)
                                            : isLow
                                                ? const Color(0xFFB45309)
                                                : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.rejectStock > 0)
                                Text("Reject: ${item.rejectStock}",
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFDC2626))),
                            ],
                          ),
                          if (_role == "manager") ...[
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 20, color: Color(0xFF2563EB)),
                              tooltip: "Ubah Harga",
                              onPressed: () => _openEditPriceDialog(item),
                            ),
                          ],
                          if (_role == "admin") ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 20, color: Color(0xFFDC2626)),
                              tooltip: "Hapus Produk",
                              onPressed: () => _confirmDeleteProduct(item),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==================== 3. TAMBAH PRODUK (ADMIN ONLY) ====================
  Widget _buildAddProductView() {
    return const AddProductForm();
  }

  // ==================== 4. FAKTUR ====================
  Widget _buildInvoicesView() {
    return InvoicesComponent(
      role: _role,
      invoices: _invoices,
      products: _products,
      onInvoiceCreated: (newInv) {
        setState(() {
          _invoices.insert(0, newInv);
          // calculate profit
          int profit = 0;
          for (final line in newInv.lines) {
            final p = _products.firstWhere((item) => item.id == line.productId,
                orElse: () => _products.first);
            profit += (line.unitPrice - p.cost) * line.quantity;
            p.stock -= line.quantity;
          }
          _profitRecords.add(ProfitRecord(
              date: DateTime.now().toIso8601String().substring(0, 10),
              profit: profit));
        });
        _showToast("${newInv.number} berhasil dibuat!");
      },
      onAddComment: (invId, commentText) {
        setState(() {
          final inv = _invoices.firstWhere((i) => i.id == invId);
          inv.comments.add(
            InvoiceComment(
              id: DateTime.now().millisecondsSinceEpoch,
              actor: _userName,
              message: commentText,
              date: "Baru saja",
            ),
          );
        });
        _showToast("Komentar koreksi berhasil dikirim!");
      },
      onDeleteInvoice: (inv) {
        setState(() {
          _invoices.removeWhere((i) => i.id == inv.id);
        });
        _api.deleteInvoice(inv.id);
        _showToast("Faktur ${inv.number} berhasil dihapus");
      },
    );
  }

  // ==================== 5. STATISTIK (MANAGER ONLY) ====================
  Widget _buildStatisticsView() {
    return StatisticsComponent(
      profitRecords: _profitRecords,
      products: _products,
    );
  }

  // ==================== 6. PROFIL ====================
  Widget _buildProfileView() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: _role == "manager"
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFE0F2FE),
                child: Text(
                  _userInitials,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _role == "manager"
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _role == "manager" ? "Role: Manager" : "Role: Admin Stok",
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 20),
          _buildProfileDetailRow("Nama Usaha / Toko", _storeName),
          _buildProfileDetailRow("Username", _userName),
          _buildProfileDetailRow(
              "Platform", "Stokku Desktop Suite (Windows x64)"),
          _buildProfileDetailRow(
              "Status Sesi", "Aktif (Offline / Local Persistence Ready)"),
          const SizedBox(height: 32),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showAccountSwitchDialog,
                icon: const Icon(Icons.switch_account_rounded, size: 18),
                label: const Text("Ganti Akun"),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() => _isLoggedIn = false);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text("Keluar (Logout)"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // ==================== LOGIN SCREEN ====================
  Widget _buildLoginScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      buildAppLogo(size: 64, radius: 18),
                      const SizedBox(height: 14),
                      const Text(
                        "Stokku",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Aplikasi Inventaris & Penjualan (Desktop Suite)",
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 20),

                // Form Nama Toko
                const Text(
                  "Nama Toko / Usaha",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _loginStoreCtrl,
                  decoration: InputDecoration(
                    hintText: "Contoh: Toko Kelontong Berkah",
                    prefixIcon: const Icon(Icons.storefront_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Form Username
                const Text(
                  "Username / Nama Pengguna",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _loginUserCtrl,
                  decoration: InputDecoration(
                    hintText: "Contoh: Rina Amelia / Budi Santoso",
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Form Password
                const Text(
                  "Password / Kata Sandi",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _loginPassCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Masukkan password akun",
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Pilihan Role
                const Text(
                  "Pilih Hak Akses (Role)",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleSelectOption(
                        title: "Admin Stok",
                        desc: "Kelola & hapus item",
                        icon: Icons.admin_panel_settings_outlined,
                        isSelected: _selectedLoginRole == "admin",
                        onTap: () => setState(() => _selectedLoginRole = "admin"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoleSelectOption(
                        title: "Manager",
                        desc: "Ubah harga & statistik",
                        icon: Icons.manage_accounts_outlined,
                        isSelected: _selectedLoginRole == "manager",
                        onTap: () =>
                            setState(() => _selectedLoginRole = "manager"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Akun Demo Quick Fill
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text("Akun Demo:",
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ActionChip(
                      label: const Text("Admin (Rina Amelia)",
                          style: TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFEFF6FF),
                      labelStyle: const TextStyle(
                          color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      onPressed: () {
                        setState(() {
                          _loginStoreCtrl.text = "Toko Kelontong Berkah";
                          _loginUserCtrl.text = "Rina Amelia";
                          _loginPassCtrl.text = "admin123";
                          _selectedLoginRole = "admin";
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text("Manager (Budi Santoso)",
                          style: TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFEFF6FF),
                      labelStyle: const TextStyle(
                          color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      onPressed: () {
                        setState(() {
                          _loginStoreCtrl.text = "Toko Kelontong Berkah";
                          _loginUserCtrl.text = "Budi Santoso";
                          _loginPassCtrl.text = "manager123";
                          _selectedLoginRole = "manager";
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Submit Login Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _performLogin,
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: const Text(
                      "Masuk ke Menu Utama",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectOption({
    required String title,
    required String desc,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performLogin() {
    final store = _loginStoreCtrl.text.trim();
    final user = _loginUserCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();

    if (store.isEmpty || user.isEmpty || pass.isEmpty) {
      _showToast("Mohon lengkapi Nama Toko, Username, dan Password!");
      return;
    }

    setState(() {
      _storeName = store;
      _userName = user;
      _role = _selectedLoginRole;
      _isLoggedIn = true;
      _currentView = "dashboard";
    });
    _showToast(
        "Selamat datang, $_userName di $_storeName (${_role == 'admin' ? 'Admin Stok' : 'Manager'})!");
  }
}

// ==========================================
// COMPONENT: ADD PRODUCT FORM (ADMIN)
// ==========================================
class AddProductForm extends StatefulWidget {
  const AddProductForm({super.key});

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController(text: "5");
  final _initialStockCtrl = TextEditingController(text: "10");
  final _rejectCtrl = TextEditingController(text: "0");
  String _category = "Sembako";

  // Dynamic Ingredients for HPP calculation
  final List<IngredientItem> _ingredients = [];

  int get _calculatedHpp {
    if (_ingredients.isEmpty) return 0;
    return _ingredients.fold<int>(0, (sum, i) => sum + i.totalCost);
  }

  int get _saleableStock {
    final initial = int.tryParse(_initialStockCtrl.text) ?? 0;
    final reject = int.tryParse(_rejectCtrl.text) ?? 0;
    return (initial - reject).clamp(0, 999999);
  }

  void _addIngredientDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: "1");
    final costCtrl = TextEditingController();
    String unit = "pcs";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Bahan Baku",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Nama Bahan",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Jumlah",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: unit,
                    items: ["pcs", "kg", "gram", "liter", "pak"]
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => unit = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Biaya per Satuan (Rp)",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final qty = double.tryParse(qtyCtrl.text) ?? 1;
              final cost = int.tryParse(costCtrl.text) ?? 0;
              if (name.isNotEmpty && cost > 0) {
                setState(() {
                  _ingredients.add(IngredientItem(
                      name: name, quantity: qty, unit: unit, unitCost: cost));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Tambahkan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Formulir Produk Baru",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
              "Khusus Admin Stok untuk menambahkan SKU dan menghitung HPP otomatis",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 24),

          // Main Inputs Grid
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Nama Produk",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _skuCtrl,
                  decoration: InputDecoration(
                    labelText: "SKU (Kode Produk)",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: "Kategori",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ["Sembako", "Minuman", "Makanan Ringan", "Umum"]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Harga Jual (Rp)",
                    prefixText: "Rp ",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minStockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Batas Stok Minimum",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _initialStockCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: "Stok Awal",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _rejectCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: "Barang Reject / Rusak",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Komposisi Bahan & Kalkulasi HPP
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Komposisi Bahan & Perhitungan HPP",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("HPP = Σ (Jumlah bahan × Biaya per satuan)",
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _addIngredientDialog,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text("Tambah Bahan"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_ingredients.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                          "Belum ada bahan baku ditambahkan. Klik 'Tambah Bahan' di atas.",
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 13)),
                    ),
                  )
                else
                  Column(
                    children: _ingredients.map((item) {
                      return ListTile(
                        dense: true,
                        title: Text(item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            "${item.quantity} ${item.unit} @ ${_MainScreenState.formatRupiah(item.unitCost)}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_MainScreenState.formatRupiah(item.totalCost),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _ingredients.remove(item)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("HPP / Modal Satuan Otomatis:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      _MainScreenState.formatRupiah(_calculatedHpp),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Stok Layak Jual:",
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text("$_saleableStock pcs",
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Nilai Inventaris:",
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text(
                        _MainScreenState.formatRupiah(
                            _calculatedHpp * _saleableStock),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A))),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final name = _nameCtrl.text.trim();
                final sku = _skuCtrl.text.trim().toUpperCase();
                final price = int.tryParse(_priceCtrl.text) ?? 0;
                final minStock = int.tryParse(_minStockCtrl.text) ?? 5;
                final reject = int.tryParse(_rejectCtrl.text) ?? 0;

                if (name.isNotEmpty && sku.isNotEmpty && price > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "$name ($sku) [Min: $minStock, Reject: $reject] berhasil ditambahkan!")),
                  );
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text("Simpan Produk ke Inventaris",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENT: INVOICES
// ==========================================
class InvoicesComponent extends StatelessWidget {
  const InvoicesComponent({
    super.key,
    required this.role,
    required this.invoices,
    required this.products,
    required this.onInvoiceCreated,
    required this.onAddComment,
    this.onDeleteInvoice,
  });

  final String role;
  final List<Invoice> invoices;
  final List<Product> products;
  final ValueChanged<Invoice> onInvoiceCreated;
  final void Function(int invoiceId, String comment) onAddComment;
  final ValueChanged<Invoice>? onDeleteInvoice;

  void _openCreateInvoiceDialog(BuildContext context) {
    if (role != "admin") return;
    final customerCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    String paymentType = "cash";
    DateTime dueDate = DateTime.now().add(const Duration(days: 14));

    final lines = <InvoiceLine>[
      if (products.isNotEmpty)
        InvoiceLine(
          productId: products.first.id,
          productName: products.first.name,
          quantity: 1,
          unitPrice: products.first.price,
        ),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final total = lines.fold<int>(0, (sum, l) => sum + l.subtotal);

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Buat Faktur Baru",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: customerCtrl,
                      decoration: InputDecoration(
                        labelText: "Nama Pelanggan / Toko",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactCtrl,
                      decoration: InputDecoration(
                        labelText: "Nomor Kontak / WhatsApp",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("Metode Pembayaran: ",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        ChoiceChip(
                          label: const Text("Cash (Lunas)"),
                          selected: paymentType == "cash",
                          onSelected: (_) =>
                              setDialogState(() => paymentType = "cash"),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text("Credit (Tempo)"),
                          selected: paymentType == "credit",
                          onSelected: (_) =>
                              setDialogState(() => paymentType = "credit"),
                        ),
                      ],
                    ),
                    if (paymentType == "credit") ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text("Jatuh Tempo: ",
                              style: TextStyle(fontSize: 13)),
                          Text(
                            "${dueDate.day}-${dueDate.month}-${dueDate.year}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setDialogState(() => dueDate = picked);
                              }
                            },
                            child: const Text("Ubah"),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text("Daftar Item Faktur:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...lines.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final line = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: line.productId,
                              items: products
                                  .map((p) => DropdownMenuItem(
                                      value: p.id,
                                      child:
                                          Text("${p.name} (Stok: ${p.stock})")))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final p = products
                                      .firstWhere((item) => item.id == val);
                                  setDialogState(() {
                                    lines[idx] = InvoiceLine(
                                      productId: p.id,
                                      productName: p.name,
                                      quantity: 1,
                                      unitPrice: p.price,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: "Qty"),
                              controller: TextEditingController(
                                  text: line.quantity.toString()),
                              onSubmitted: (val) {
                                final qty = int.tryParse(val) ?? 1;
                                setDialogState(() {
                                  lines[idx] = InvoiceLine(
                                    productId: line.productId,
                                    productName: line.productName,
                                    quantity: qty,
                                    unitPrice: line.unitPrice,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_MainScreenState.formatRupiah(line.subtotal),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            onPressed: () {
                              if (lines.length > 1) {
                                setDialogState(() => lines.removeAt(idx));
                              }
                            },
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        if (products.isNotEmpty) {
                          setDialogState(() {
                            lines.add(InvoiceLine(
                              productId: products.first.id,
                              productName: products.first.name,
                              quantity: 1,
                              unitPrice: products.first.price,
                            ));
                          });
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Tambah Item Produk"),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Faktur:",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          _MainScreenState.formatRupiah(total),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Batal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final cust = customerCtrl.text.trim();
                  if (cust.isNotEmpty && lines.isNotEmpty) {
                    final invoice = Invoice(
                      id: DateTime.now().millisecondsSinceEpoch,
                      number:
                          "INV-${DateTime.now().year}-${(invoices.length + 1).toString().padLeft(3, '0')}",
                      customer: cust,
                      contact: contactCtrl.text.trim(),
                      paymentType: paymentType,
                      status: paymentType == "cash" ? "paid" : "unpaid",
                      dueDate: paymentType == "credit"
                          ? "${dueDate.day}-${dueDate.month}-${dueDate.year}"
                          : null,
                      date: "${DateTime.now().day} Okt ${DateTime.now().year}",
                      lines: lines,
                      total: total,
                    );
                    onInvoiceCreated(invoice);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Simpan & Cetak Faktur"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openDetailAndCommentDialog(BuildContext context, Invoice inv) {
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text("Detail ${inv.number}"),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 480,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pelanggan: ${inv.customer} (${inv.contact})",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        "Tanggal: ${inv.date} · Pembayaran: ${inv.paymentType.toUpperCase()}"),
                    if (inv.dueDate != null)
                      Text("Jatuh tempo: ${inv.dueDate}",
                          style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    const Divider(),
                    const Text("Rincian Item:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...inv.lines.map((l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${l.productName} × ${l.quantity}"),
                              Text(_MainScreenState.formatRupiah(l.subtotal),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_MainScreenState.formatRupiah(inv.total),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2563EB))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Komentar Koreksi Manager:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    if (inv.comments.isEmpty)
                      const Text("Belum ada komentar koreksi dari Manager.",
                          style:
                              TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
                    else
                      ...inv.comments.map((c) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(c.actor,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Color(0xFF2563EB))),
                                    Text(c.date,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF94A3B8))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(c.message,
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          )),
                    if (role == "manager") ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentCtrl,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText:
                              "Tulis catatan koreksi (maks 500 karakter)...",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final text = commentCtrl.text.trim();
                            if (text.isNotEmpty) {
                              onAddComment(inv.id, text);
                              setDialogState(() {
                                inv.comments.add(InvoiceComment(
                                  id: DateTime.now().millisecondsSinceEpoch,
                                  actor: "Budi Santoso",
                                  message: text,
                                  date: "Baru saja",
                                ));
                                commentCtrl.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: const Text("Kirim Catatan Koreksi"),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Tutup")),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Daftar Faktur Penjualan",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    "Kelola transaksi, status pembayaran, dan komentar koreksi",
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
            if (role == "admin")
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openCreateInvoiceDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text("Buat Faktur Baru",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: invoices.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: Text("Belum ada faktur yang tercatat.")),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final inv = invoices[index];
                    final isPaid = inv.status == "paid";

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.receipt_outlined,
                            color: Color(0xFF2563EB)),
                      ),
                      title: Row(
                        children: [
                          Text(inv.number,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPaid ? "Lunas" : "Belum Lunas",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPaid
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle:
                          Text("Pelanggan: ${inv.customer} · ${inv.date}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_MainScreenState.formatRupiah(inv.total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined,
                                color: Color(0xFF2563EB)),
                            tooltip: "Detail & Koreksi",
                            onPressed: () =>
                                _openDetailAndCommentDialog(context, inv),
                          ),
                          if (role == "admin") ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Color(0xFFDC2626)),
                              tooltip: "Hapus Faktur",
                              onPressed: () =>
                                  _confirmDeleteInvoice(context, inv),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDeleteInvoice(BuildContext context, Invoice inv) {
    if (role != "admin") return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text("Hapus Faktur",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Apakah Anda yakin ingin menghapus faktur \"${inv.number}\" untuk pelanggan \"${inv.customer}\"?",
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Total: ${_MainScreenState.formatRupiah(inv.total)} · Tanggal: ${inv.date}",
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDeleteInvoice?.call(inv);
            },
            child: const Text("Hapus Faktur"),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENT: STATISTIK & PARETO (MANAGER)
// ==========================================
class StatisticsComponent extends StatefulWidget {
  const StatisticsComponent({
    super.key,
    required this.profitRecords,
    required this.products,
  });

  final List<ProfitRecord> profitRecords;
  final List<Product> products;

  @override
  State<StatisticsComponent> createState() => _StatisticsComponentState();
}

class _StatisticsComponentState extends State<StatisticsComponent> {
  String _period = "week"; // week | month

  @override
  Widget build(BuildContext context) {
    final totalModal =
        widget.products.fold<int>(0, (sum, p) => sum + (p.cost * p.stock));
    final potentialRevenue =
        widget.products.fold<int>(0, (sum, p) => sum + (p.price * p.stock));
    final estimatedProfit = potentialRevenue - totalModal;
    final potentialMargin = potentialRevenue > 0
        ? ((estimatedProfit / potentialRevenue) * 100).toStringAsFixed(1)
        : "0";
    final rejectLoss = widget.products
        .fold<int>(0, (sum, p) => sum + (p.cost * p.rejectStock));

    // Sort records descending for Pareto
    final sorted = List<ProfitRecord>.from(widget.profitRecords)
      ..sort((a, b) => b.profit.compareTo(a.profit));

    final totalProfitSum = sorted.fold<int>(0, (sum, r) => sum + r.profit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary KPIs
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 48) / 4;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatBox(
                    cardWidth.clamp(220, 300),
                    "Total Modal Stok",
                    _MainScreenState.formatCompactRupiah(totalModal),
                    const Color(0xFF2563EB)),
                _buildStatBox(
                    cardWidth.clamp(220, 300),
                    "Potensi Omzet",
                    _MainScreenState.formatCompactRupiah(potentialRevenue),
                    const Color(0xFF0284C7)),
                _buildStatBox(
                    cardWidth.clamp(220, 300),
                    "Perkiraan Keuntungan",
                    _MainScreenState.formatCompactRupiah(estimatedProfit),
                    const Color(0xFF16A34A)),
                _buildStatBox(cardWidth.clamp(220, 300), "Margin Potensi",
                    "$potentialMargin %", const Color(0xFF7C3AED)),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        if (rejectLoss > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626)),
                const SizedBox(width: 12),
                Text(
                  "Kerugian Barang Reject: ${_MainScreenState.formatRupiah(rejectLoss)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                ),
              ],
            ),
          ),

        const SizedBox(height: 28),

        // Pareto Chart Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pareto Chart Keuntungan",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                          "Batang biru: Keuntungan periode · Garis kuning: Kumulatif %",
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: "week", label: Text("Mingguan")),
                      ButtonSegment(value: "month", label: Text("Bulanan")),
                    ],
                    selected: {_period},
                    onSelectionChanged: (set) {
                      setState(() => _period = set.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Visual Bars & Cumulative Points
              SizedBox(
                height: 220,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: sorted.take(8).map((record) {
                    final maxProfit = sorted.first.profit;
                    final heightPercent =
                        maxProfit > 0 ? (record.profit / maxProfit) : 0.0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _MainScreenState.formatCompactRupiah(
                                  record.profit),
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: (heightPercent * 160).clamp(10, 160),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              record.date.length >= 10
                                  ? record.date.substring(5)
                                  : record.date,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildParetoSummary("Total Keuntungan",
                      _MainScreenState.formatRupiah(totalProfitSum)),
                  _buildParetoSummary("Periode Terbaik",
                      sorted.isNotEmpty ? sorted.first.date : "-"),
                  _buildParetoSummary(
                      "Keuntungan Tertinggi",
                      sorted.isNotEmpty
                          ? _MainScreenState.formatRupiah(sorted.first.profit)
                          : "-"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(double width, String title, String value, Color color) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildParetoSummary(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
      ],
    );
  }
}

// ==========================================
// PAINTER: LOGO STOKKU (CUSTOM DESKTOP ICON)
// ==========================================
class _StokkuLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Blue gradient background (squircle)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0091FF), Color(0xFF0066FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final rrectBg = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.24),
    );
    canvas.drawRRect(rrectBg, bgPaint);

    // 2. White inner window frame
    final strokeWidth = size.width * 0.075;
    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final inset = size.width * 0.20;
    final frameRect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    final innerRRect = RRect.fromRectAndRadius(
      frameRect,
      Radius.circular(size.width * 0.15),
    );
    canvas.drawRRect(innerRRect, framePaint);

    // 3. Horizontal divider line (header separator)
    final hY = frameRect.top + frameRect.height * 0.32;
    canvas.drawLine(
      Offset(frameRect.left, hY),
      Offset(frameRect.right, hY),
      framePaint,
    );

    // 4. Vertical divider line (sidebar separator)
    final vX = frameRect.left + frameRect.width * 0.36;
    canvas.drawLine(
      Offset(vX, hY),
      Offset(vX, frameRect.bottom),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
