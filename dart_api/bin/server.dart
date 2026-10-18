import "dart:convert";
import "dart:io";

import "package:mysql1/mysql1.dart";
import "package:shelf/shelf.dart";
import "package:shelf/shelf_io.dart" as shelf_io;
import "package:shelf_router/shelf_router.dart";

Future<void> main() async {
  final connection = await MySqlConnection.connect(
    ConnectionSettings(
      host: Platform.environment["DB_HOST"] ?? "127.0.0.1",
      port: int.tryParse(Platform.environment["DB_PORT"] ?? "") ?? 3306,
      user: Platform.environment["DB_USER"] ?? "stokku",
      password: Platform.environment["DB_PASSWORD"] ?? "",
      db: Platform.environment["DB_NAME"] ?? "stokku",
    ),
  );

  final router = Router()
    ..get("/api/health", (Request request) => _json({"status": "ok"}))
    ..get("/api/products", (Request request) => _getProducts(connection))
    ..get("/api/invoices", (Request request) => _getInvoices(request, connection))
    ..get("/api/invoices/<id>/comments", (Request request, String id) => _getInvoiceComments(request, id, connection))
    ..get("/api/statistics/profit", (Request request) => _getProfitStatistics(request, connection))
    ..post("/api/products", (Request request) => _createProduct(request, connection))
    ..post("/api/invoices", (Request request) => _createInvoice(request, connection))
    ..post("/api/invoices/<id>/comments", (Request request, String id) => _createInvoiceComment(request, id, connection))
    ..delete("/api/products/<id>", (Request request, String id) => _deleteProduct(request, id, connection))
    ..delete("/api/invoices/<id>", (Request request, String id) => _deleteInvoice(request, id, connection));

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addMiddleware(_errors())
      .addHandler(router.call);
  final port = int.tryParse(Platform.environment["PORT"] ?? "") ?? 8080;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln("Stokku API aktif di http://${server.address.host}:${server.port}");
}

Future<Response> _getProducts(MySqlConnection db) async {
  final rows = await db.query(
    "SELECT id, name, sku, category, cost, price, stock, reject_stock, min_stock "
    "FROM products ORDER BY created_at DESC",
  );
  return _json(rows.map((row) => {
        "id": row["id"],
        "name": row["name"],
        "sku": row["sku"],
        "category": row["category"],
        "cost": row["cost"],
        "price": row["price"],
        "stock": row["stock"],
        "rejectStock": row["reject_stock"],
        "minStock": row["min_stock"],
      }).toList());
}

Future<Response> _getInvoices(Request request, MySqlConnection db) async {
  if (!_hasRole(request, const {"admin", "manager"})) {
    return _json({"error": "Fitur Faktur hanya dapat diakses oleh Admin atau Manager."}, status: 403);
  }
  final rows = await db.query(
    "SELECT id, invoice_number, customer, contact, payment_type, payment_status, "
    "due_date, total, created_at FROM invoices ORDER BY created_at DESC",
  );
  return _json(rows.map((row) => {
        "id": row["id"],
        "number": row["invoice_number"],
        "customer": row["customer"],
        "contact": row["contact"],
        "paymentType": row["payment_type"],
        "status": row["payment_status"],
        "dueDate": row["due_date"]?.toString(),
        "total": row["total"],
        "createdAt": row["created_at"].toString(),
      }).toList());
}

Future<Response> _createProduct(Request request, MySqlConnection db) async {
  if (!_hasRole(request, const {"admin"})) {
    return _json({"error": "Tambah Produk hanya dapat diakses oleh Admin."}, status: 403);
  }
  final body = await _body(request);
  final ingredients = (body["ingredients"] as List<dynamic>? ?? const []);
  final stock = _positiveInt(body["stock"], allowZero: true);
  final rejectStock = _positiveInt(body["rejectStock"], allowZero: true);
  if (rejectStock > stock || ingredients.isEmpty) {
    return _json({"error": "Komposisi wajib diisi dan reject tidak boleh melebihi stok."}, status: 422);
  }

  final cost = ingredients.fold<int>(0, (sum, raw) {
    final item = raw as Map<String, dynamic>;
    return sum + ((_number(item["quantity"]) * _number(item["unitCost"])).round());
  });
  await db.query("START TRANSACTION");
  try {
    final result = await db.query(
      "INSERT INTO products (name, sku, category, cost, price, stock, reject_stock, min_stock) "
      "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
      [
        body["name"],
        body["sku"],
        body["category"],
        cost,
        _positiveInt(body["price"]),
        stock - rejectStock,
        rejectStock,
        _positiveInt(body["minStock"], allowZero: true),
      ],
    );
    final productId = result.insertId;
    for (final raw in ingredients) {
      final item = raw as Map<String, dynamic>;
      await db.query(
        "INSERT INTO product_ingredients (product_id, name, quantity, unit, unit_cost) VALUES (?, ?, ?, ?, ?)",
        [productId, item["name"], _number(item["quantity"]), item["unit"], _positiveInt(item["unitCost"], allowZero: true)],
      );
    }
    await db.query("COMMIT");
    return _json({"id": productId, "cost": cost}, status: 201);
  } catch (_) {
    await db.query("ROLLBACK");
    rethrow;
  }
}

Future<Response> _deleteProduct(Request request, String id, MySqlConnection db) async {
  if (!_hasRole(request, const {"admin"})) {
    return _json({"error": "Hapus produk hanya dapat dilakukan oleh Admin."}, status: 403);
  }
  final productId = int.tryParse(id);
  if (productId == null) {
    return _json({"error": "ID produk tidak valid."}, status: 400);
  }
  await db.query("START TRANSACTION");
  try {
    await db.query("DELETE FROM product_ingredients WHERE product_id = ?", [productId]);
    await db.query("DELETE FROM invoice_items WHERE product_id = ?", [productId]);
    await db.query("DELETE FROM products WHERE id = ?", [productId]);
    await db.query("COMMIT");
    return _json({"status": "deleted", "id": productId});
  } catch (_) {
    await db.query("ROLLBACK");
    rethrow;
  }
}

Future<Response> _createInvoice(Request request, MySqlConnection db) async {
  if (!_hasRole(request, const {"admin"})) {
    return _json({"error": "Fitur Faktur hanya dapat diakses oleh Admin."}, status: 403);
  }
  final body = await _body(request);
  final rawLines = (body["lines"] as List<dynamic>? ?? const []);
  final paymentType = body["paymentType"] == "credit" ? "credit" : "cash";
  if (rawLines.isEmpty || (paymentType == "credit" && body["dueDate"] == null)) {
    return _json({"error": "Item dan tanggal tempo untuk kredit wajib diisi."}, status: 422);
  }

  final quantities = <int, int>{};
  for (final raw in rawLines) {
    final line = raw as Map<String, dynamic>;
    final productId = _positiveInt(line["productId"]);
    quantities[productId] = (quantities[productId] ?? 0) + _positiveInt(line["quantity"]);
  }

  await db.query("START TRANSACTION");
  try {
    final preparedLines = <Map<String, dynamic>>[];
    var total = 0;
    for (final entry in quantities.entries) {
      final productId = entry.key;
      final quantity = entry.value;
      final rows = await db.query(
        "SELECT name, cost, price, stock FROM products WHERE id = ? FOR UPDATE",
        [productId],
      );
      if (rows.isEmpty || (rows.first["stock"] as int) < quantity) {
        throw StateError("Stok produk $productId tidak mencukupi.");
      }
      final price = rows.first["price"] as int;
      total += price * quantity;
      preparedLines.add({
        "productId": productId,
        "productName": rows.first["name"],
        "quantity": quantity,
        "cost": rows.first["cost"],
        "price": price,
      });
    }

    final countRows = await db.query("SELECT COUNT(*) AS total FROM invoices WHERE YEAR(created_at) = YEAR(CURRENT_DATE())");
    final sequence = (countRows.first["total"] as int) + 1;
    final number = "INV-${DateTime.now().year}-${sequence.toString().padLeft(3, "0")}";
    final invoiceResult = await db.query(
      "INSERT INTO invoices (invoice_number, customer, contact, payment_type, payment_status, due_date, total) "
      "VALUES (?, ?, ?, ?, ?, ?, ?)",
      [number, body["customer"], body["contact"] ?? "", paymentType, paymentType == "cash" ? "paid" : "unpaid", body["dueDate"], total],
    );
    for (final line in preparedLines) {
      await db.query(
        "INSERT INTO invoice_lines (invoice_id, product_id, product_name, quantity, unit_cost, unit_price, subtotal) "
        "VALUES (?, ?, ?, ?, ?, ?, ?)",
        [invoiceResult.insertId, line["productId"], line["productName"], line["quantity"], line["cost"], line["price"], (line["quantity"] as int) * (line["price"] as int)],
      );
      await db.query("UPDATE products SET stock = stock - ? WHERE id = ?", [line["quantity"], line["productId"]]);
    }
    await db.query("COMMIT");
    return _json({"id": invoiceResult.insertId, "number": number, "total": total}, status: 201);
  } catch (error) {
    await db.query("ROLLBACK");
    if (error is StateError) return _json({"error": error.message}, status: 409);
    rethrow;
  }
}

Future<Response> _getProfitStatistics(Request request, MySqlConnection db) async {
  if (!_hasRole(request, const {"manager"})) {
    return _json({"error": "Statistik keuntungan hanya dapat diakses oleh Manager."}, status: 403);
  }
  final period = request.url.queryParameters["period"] == "month" ? "month" : "week";
  final periodExpression = period == "month"
      ? "DATE_FORMAT(i.created_at, '%Y-%m-01')"
      : "DATE_SUB(DATE(i.created_at), INTERVAL WEEKDAY(i.created_at) DAY)";
  final rows = await db.query(
    "SELECT $periodExpression AS period_start, "
    "SUM((il.unit_price - il.unit_cost) * il.quantity) AS profit "
    "FROM invoices i INNER JOIN invoice_lines il ON il.invoice_id = i.id "
    "GROUP BY period_start ORDER BY period_start ASC",
  );
  return _json({
    "period": period,
    "items": rows.map((row) => {
          "periodStart": row["period_start"].toString(),
          "profit": row["profit"],
        }).toList(),
  });
}

Future<Response> _getInvoiceComments(Request request, String invoiceId, MySqlConnection db) async {
  if (!_hasRole(request, const {"admin", "manager"})) {
    return _json({"error": "Komentar Faktur hanya dapat dilihat oleh Admin atau Manager."}, status: 403);
  }
  final id = int.tryParse(invoiceId);
  if (id == null) return _json({"error": "ID faktur tidak valid."}, status: 400);
  final rows = await db.query(
    "SELECT id, actor_name, message, created_at FROM invoice_comments "
    "WHERE invoice_id = ? ORDER BY created_at ASC",
    [id],
  );
  return _json(rows.map((row) => {
        "id": row["id"],
        "actor": row["actor_name"],
        "message": row["message"],
        "createdAt": row["created_at"].toString(),
      }).toList());
}

Future<Response> _createInvoiceComment(Request request, String invoiceId, MySqlConnection db) async {
  if (!_hasRole(request, const {"manager"})) {
    return _json({"error": "Komentar koreksi hanya dapat dibuat oleh Manager."}, status: 403);
  }
  final id = int.tryParse(invoiceId);
  if (id == null) return _json({"error": "ID faktur tidak valid."}, status: 400);
  final body = await _body(request);
  final message = body["message"]?.toString().trim() ?? "";
  if (message.isEmpty || message.length > 500) {
    return _json({"error": "Komentar wajib diisi dan maksimal 500 karakter."}, status: 422);
  }
  final invoice = await db.query("SELECT id FROM invoices WHERE id = ?", [id]);
  if (invoice.isEmpty) return _json({"error": "Faktur tidak ditemukan."}, status: 404);
  final result = await db.query(
    "INSERT INTO invoice_comments (invoice_id, actor_role, actor_name, message) VALUES (?, 'manager', ?, ?)",
    [id, body["actor"]?.toString().trim().isNotEmpty == true ? body["actor"] : "Manager", message],
  );
  return _json({"id": result.insertId, "invoiceId": id, "message": message}, status: 201);
}

Future<Response> _deleteInvoice(Request request, String id, MySqlConnection db) async {
  if (!_hasRole(request, const {"admin"})) {
    return _json({"error": "Hapus faktur hanya dapat dilakukan oleh Admin."}, status: 403);
  }
  final invoiceId = int.tryParse(id);
  if (invoiceId == null) {
    return _json({"error": "ID faktur tidak valid."}, status: 400);
  }
  await db.query("START TRANSACTION");
  try {
    await db.query("DELETE FROM invoice_comments WHERE invoice_id = ?", [invoiceId]);
    await db.query("DELETE FROM invoice_items WHERE invoice_id = ?", [invoiceId]);
    await db.query("DELETE FROM invoices WHERE id = ?", [invoiceId]);
    await db.query("COMMIT");
    return _json({"status": "deleted", "id": invoiceId});
  } catch (_) {
    await db.query("ROLLBACK");
    rethrow;
  }
}

Future<Map<String, dynamic>> _body(Request request) async {
  final value = jsonDecode(await request.readAsString());
  if (value is! Map<String, dynamic>) throw const FormatException("JSON object diperlukan.");
  return value;
}

num _number(dynamic value) => value is num ? value : num.parse(value.toString());

int _positiveInt(dynamic value, {bool allowZero = false}) {
  final number = _number(value).toInt();
  if (allowZero ? number < 0 : number <= 0) throw const FormatException("Angka tidak valid.");
  return number;
}

bool _hasRole(Request request, Set<String> roles) => roles.contains(request.headers["x-stokku-role"]);

Response _json(Object body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: const {"content-type": "application/json; charset=utf-8"},
    );

Middleware _cors() => (innerHandler) => (request) async {
      if (request.method == "OPTIONS") return _withCors(Response.ok(""));
      return _withCors(await innerHandler(request));
    };

Response _withCors(Response response) => response.change(headers: {
      ...response.headers,
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "GET, POST, OPTIONS",
      "access-control-allow-headers": "content-type, authorization, x-stokku-role",
    });

Middleware _errors() => (innerHandler) => (request) async {
      try {
        return await innerHandler(request);
      } on FormatException catch (error) {
        return _json({"error": error.message}, status: 400);
      } catch (error, stackTrace) {
        stderr.writeln("$error\n$stackTrace");
        return _json({"error": "Terjadi kesalahan pada server."}, status: 500);
      }
    };
