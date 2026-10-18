class Product {
  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.cost,
    required this.price,
    required this.stock,
    this.rejectStock = 0,
    this.minStock = 5,
  });

  final int id;
  String name;
  String sku;
  String category;
  int cost;
  int price;
  int stock;
  int rejectStock;
  int minStock;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["id"] is int ? json["id"] as int : int.parse(json["id"].toString()),
        name: json["name"] as String? ?? "",
        sku: json["sku"] as String? ?? "",
        category: json["category"] as String? ?? "Umum",
        cost: json["cost"] is int ? json["cost"] as int : int.tryParse(json["cost"].toString()) ?? 0,
        price: json["price"] is int ? json["price"] as int : int.tryParse(json["price"].toString()) ?? 0,
        stock: json["stock"] is int ? json["stock"] as int : int.tryParse(json["stock"].toString()) ?? 0,
        rejectStock: json["rejectStock"] is int
            ? json["rejectStock"] as int
            : int.tryParse(json["rejectStock"]?.toString() ?? "0") ?? 0,
        minStock: json["minStock"] is int
            ? json["minStock"] as int
            : int.tryParse(json["minStock"]?.toString() ?? "5") ?? 5,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "sku": sku,
        "category": category,
        "cost": cost,
        "price": price,
        "stock": stock,
        "rejectStock": rejectStock,
        "minStock": minStock,
      };

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? category,
    int? cost,
    int? price,
    int? stock,
    int? rejectStock,
    int? minStock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      cost: cost ?? this.cost,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      rejectStock: rejectStock ?? this.rejectStock,
      minStock: minStock ?? this.minStock,
    );
  }
}

class InvoiceLine {
  InvoiceLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final int productId;
  final String productName;
  final int quantity;
  final int unitPrice;

  int get subtotal => quantity * unitPrice;

  factory InvoiceLine.fromJson(Map<String, dynamic> json) => InvoiceLine(
        productId: json["productId"] as int? ?? 0,
        productName: json["productName"] as String? ?? "",
        quantity: json["quantity"] as int? ?? 1,
        unitPrice: json["unitPrice"] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "productId": productId,
        "productName": productName,
        "quantity": quantity,
        "unitPrice": unitPrice,
      };
}

class InvoiceComment {
  InvoiceComment({
    required this.id,
    required this.actor,
    required this.message,
    required this.date,
  });

  final int id;
  final String actor;
  final String message;
  final String date;

  factory InvoiceComment.fromJson(Map<String, dynamic> json) => InvoiceComment(
        id: json["id"] as int? ?? 0,
        actor: json["actor"] as String? ?? "",
        message: json["message"] as String? ?? "",
        date: json["date"] as String? ?? "",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "actor": actor,
        "message": message,
        "date": date,
      };
}

class Invoice {
  Invoice({
    required this.id,
    required this.number,
    required this.customer,
    required this.contact,
    required this.paymentType,
    required this.status,
    required this.date,
    required this.lines,
    required this.total,
    this.dueDate,
    List<InvoiceComment>? comments,
  }) : comments = comments ?? [];

  final int id;
  final String number;
  final String customer;
  final String contact;
  final String paymentType; // 'cash' | 'credit'
  final String status; // 'paid' | 'unpaid'
  final String? dueDate;
  final String date;
  final List<InvoiceLine> lines;
  final int total;
  final List<InvoiceComment> comments;

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json["id"] as int? ?? 0,
        number: json["number"] as String? ?? "",
        customer: json["customer"] as String? ?? "",
        contact: json["contact"] as String? ?? "",
        paymentType: json["paymentType"] as String? ?? "cash",
        status: json["status"] as String? ?? "paid",
        dueDate: json["dueDate"] as String?,
        date: json["date"] as String? ?? "",
        lines: (json["lines"] as List<dynamic>? ?? [])
            .map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json["total"] as int? ?? 0,
        comments: (json["comments"] as List<dynamic>? ?? [])
            .map((e) => InvoiceComment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "number": number,
        "customer": customer,
        "contact": contact,
        "paymentType": paymentType,
        "status": status,
        "dueDate": dueDate,
        "date": date,
        "lines": lines.map((l) => l.toJson()).toList(),
        "total": total,
        "comments": comments.map((c) => c.toJson()).toList(),
      };
}

class ProfitRecord {
  ProfitRecord({required this.date, required this.profit});

  final String date;
  final int profit;

  factory ProfitRecord.fromJson(Map<String, dynamic> json) => ProfitRecord(
        date: json["date"] as String? ?? "",
        profit: json["profit"] is int
            ? json["profit"] as int
            : int.tryParse(json["profit"].toString()) ?? 0,
      );
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.product,
    required this.actor,
    required this.oldCost,
    required this.newCost,
    required this.oldPrice,
    required this.newPrice,
    required this.date,
  });

  final int id;
  final String product;
  final String actor;
  final int oldCost;
  final int newCost;
  final int oldPrice;
  final int newPrice;
  final String date;
}

class IngredientItem {
  IngredientItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitCost,
  });

  String name;
  double quantity;
  String unit;
  int unitCost;

  int get totalCost => (quantity * unitCost).round();
}

class InvoiceLineInput {
  const InvoiceLineInput({required this.productId, required this.quantity});

  final int productId;
  final int quantity;

  Map<String, dynamic> toJson() => {
        "productId": productId,
        "quantity": quantity,
      };
}

class InvoiceInput {
  const InvoiceInput({
    required this.customer,
    required this.contact,
    required this.paymentType,
    required this.lines,
    this.dueDate,
  });

  final String customer;
  final String contact;
  final String paymentType;
  final String? dueDate;
  final List<InvoiceLineInput> lines;

  Map<String, dynamic> toJson() => {
        "customer": customer,
        "contact": contact,
        "paymentType": paymentType,
        "dueDate": dueDate,
        "lines": lines.map((line) => line.toJson()).toList(),
      };
}
