import 'package:saytarly/core/services/app_settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:saytarly/Features/materials/presentation/screens/manage_materials.dart';
import 'package:saytarly/core/models/models.dart';
import 'package:saytarly/core/utils/DeviceFingerprint.dart';
import 'package:saytarly/core/localization/messages.dart';

class DBHelper {
  static Database? _db;
  static final DBHelper instance = DBHelper._(); // ✅ نسخة واحدة من الكلاس
  DBHelper._(); // ✅ Constructor خاص

  /// أول قيمة رقمية من نتيجة استعلام — بديل للسطر Sqflite.firstIntValue
  static int? _firstIntOrNull(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return null;
    final v = rows.first.values.first;
    if (v == null) return null;
    return (v as num).toInt();
  }

  static Future<Database> initDB() async {
    if (_db != null) return _db!;
    String path = join(await getDatabasesPath(), 'xo_cafe57.db');

    _db = await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await addColumnsToConsoles();
    await addColumnsToDebtPayments();
    await addDrinkIdColumnToDebtItems();

    await ensureAuditLogTable();
    await ensureVodafoneCashTable();
    await ensureOrdersTables();
    await ensureAppSettingsTable();
    await ensureSuperAdminSupport();
    await ensureAppModules();
    // 🌿 جدول فروع التعيين (الموظف الفرعي عند أكتر من كاشير) — مضمن
    // (idempotent): بيتعمل لو مش موجود وبيرحّل القديم مرة واحدة بس.
    await ensureSubStaffAssignments();
    await addShishaCostColumnToInvoices();
    await cleanupAllMaterialQuantities();
    await healInvoiceStaffNames();
    return _db!;
  }

  static Future<Database> get database async {
    if (_db != null) return _db!;
    return await initDB();
  }

  static Future<void> addColumnsToConsoles() async {
    final db = await database;

    final columns = await db.rawQuery("PRAGMA table_info(consoles)");

    if (!columns.any((c) => c['name'] == 'is_fixed_price')) {
      await db.execute(
        'ALTER TABLE consoles ADD COLUMN is_fixed_price INTEGER DEFAULT 0',
      );
      print('✅ Added column is_fixed_price to consoles');
    }

    if (!columns.any((c) => c['name'] == 'fixed_price')) {
      await db.execute(
        'ALTER TABLE consoles ADD COLUMN fixed_price REAL DEFAULT 0.0',
      );
      print('✅ Added column fixed_price to consoles');
    }

    if (!columns.any((c) => c['name'] == 'single_match_price')) {
      await db.execute(
        'ALTER TABLE consoles ADD COLUMN single_match_price REAL DEFAULT 0.0',
      );
      print('✅ Added column single_match_price to consoles');
    }

    if (!columns.any((c) => c['name'] == 'double_match_price')) {
      await db.execute(
        'ALTER TABLE consoles ADD COLUMN double_match_price REAL DEFAULT 0.0',
      );
      print('✅ Added column double_match_price to consoles');
    }
  }

  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // جدول الترابيزات
      await db.execute('''
      CREATE TABLE tables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        active_invoice_id INTEGER
      )
    ''');

      await db.execute('ALTER TABLE invoices ADD COLUMN staff_name TEXT');
    }

    if (oldVersion < 3) {
      // إضافة العمود type لجدول drinks
      await db.execute(
        'ALTER TABLE drinks ADD COLUMN type TEXT DEFAULT "drink"',
      );
    }
  }
  /////////////////////////////////////////////////////////

  /////////////////////////////////////////////////////////////////
  static Future<void> addPaidColumnToSalaries() async {
    final db = await database;

    // فحص الأعمدة الموجودة في جدول salaries
    final columns = await db.rawQuery("PRAGMA table_info(salaries)");
    final hasPaid = columns.any((c) => c['name'] == 'paid');

    if (!hasPaid) {
      await db.execute(
        'ALTER TABLE salaries ADD COLUMN paid INTEGER DEFAULT 0;',
      );
      print("✅ تم إضافة العمود paid لجدول salaries");
    } else {
      print("ℹ️ العمود paid موجود بالفعل");
    }
  }

  static Future _onCreate(Database db, int version) async {
    ///////////////////////////////////////////////////////
    // ✅ جداول الطلبات — SQLite syntax
    await db.execute('''
  CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_id INTEGER NOT NULL,
    table_name TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TEXT NOT NULL,
    shift_id INTEGER,
    invoice_id INTEGER,
    note TEXT
  )
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS vodafone_cash_notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  shift_id INTEGER,
  amount REAL,
  note TEXT,
  added_by TEXT,
  created_at TEXT
)
''');
    //معلافه مين الي عدل
    await db.execute('''
CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER,
  customer_name TEXT,
  action TEXT,
  details TEXT,
  changed_by TEXT,
  changed_at TEXT
)
''');
    await db.execute('''
  CREATE TABLE IF NOT EXISTS order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    drink_id INTEGER NOT NULL,
    drink_name TEXT NOT NULL,
    qty INTEGER NOT NULL,
    price REAL NOT NULL,
    total REAL NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE
  )
''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS menu_drinks (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    price REAL NOT NULL,
    temperature TEXT
  )
''');

    // ⬆️ بعد كده باقي الجداول العادية (users, consoles, drinks, ...)

    /////////////////////////////////////////////////
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT CHECK(role IN ('superadmin','admin','cashier','waiter')) DEFAULT 'cashier'
    )
  ''');

    await db.execute('''
CREATE TABLE activation (
  id INTEGER PRIMARY KEY,
  cpu_id TEXT,
  board_id TEXT,
  disk_id TEXT,
  device_hash TEXT
)
''');

    await db.execute('''
      CREATE TABLE consoles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price_per_hour REAL NOT NULL
      )
    ''');
    await db.execute('''
    CREATE TABLE raw_materials (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  unit TEXT NOT NULL,
  qty REAL DEFAULT 0,
  min_qty REAL DEFAULT 0,
  cost REAL DEFAULT 0
)
    ''');
    await db.execute('''
  CREATE TABLE material_transactions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  material_id INTEGER,
  qty REAL,
  type TEXT,
  notes TEXT,
  created_at TEXT
)
    ''');
    await db.execute('''
   CREATE TABLE material_inventory_history(
id INTEGER PRIMARY KEY AUTOINCREMENT,
material_id INTEGER,
old_qty REAL,
new_qty REAL,
difference REAL,
inventory_date TEXT
)
    ''');
    await db.execute('''
        CREATE TABLE drink_recipes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  drink_id INTEGER NOT NULL,
  material_id INTEGER NOT NULL,
  qty REAL NOT NULL
)
    ''');
    await db.execute('''
     CREATE TABLE stock_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  material_id INTEGER,
  movement_type TEXT,
  qty REAL,
  created_at TEXT
)
    ''');
    await db.execute('''
  CREATE TABLE expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    description TEXT NOT NULL,
    amount REAL NOT NULL,
    date TEXT NOT NULL,
    added_by TEXT NOT NULL,
    shift_id INTEGER
  )
''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sub_staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        supervisor_shift_id INTEGER,
        shift_start TEXT,
        shift_end TEXT,
        salary_per_hour REAL,
        advance REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sub_staff_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        waiter_id INTEGER NOT NULL,
        supervisor_id INTEGER NOT NULL,
        created_at TEXT,
        UNIQUE(waiter_id, supervisor_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE drinks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_en TEXT DEFAULT '',
        price REAL NOT NULL,
         temperature TEXT,
        qty INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS tables (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      active_invoice_id INTEGER
    )
  ''');
    await db.execute('''
  CREATE TABLE invoice_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER,
  drink_id INTEGER,
  drink_name TEXT,
  qty INTEGER DEFAULT 1,
  price REAL NOT NULL,
  total REAL NOT NULL,
  item_type TEXT DEFAULT 'drink',
  hours REAL DEFAULT 0
)
''');
    await db.execute('''
  CREATE TABLE invoices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    console_id INTEGER,
    start_time TEXT,
    end_time TEXT,
    paused_at TEXT,             -- وقت الإيقاف المؤقت
    total_paused_seconds INTEGER DEFAULT 0,
    is_fixed_price INTEGER DEFAULT 0,  -- 1 إذا كانت الجلسة بسعر ثابت
    fixed_price REAL DEFAULT 0.0,      -- السعر الثابت للجلسة
    device_cost REAL DEFAULT 0,
    drinks_cost REAL DEFAULT 0,
    total_cost REAL DEFAULT 0,
    discount REAL DEFAULT 0,
    customer_name TEXT,
    staff_name TEXT,
    payment_type TEXT,
    shift_id INTEGER,
    products_cost REAL DEFAULT 0,
    cigarettes_cost REAL DEFAULT 0,
    shisha_cost REAL DEFAULT 0
    
  )
''');

    await db.execute('''
  CREATE TABLE staff_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    salary_per_hour REAL NOT NULL,
    work_hours_per_day INTEGER NOT NULL,
    days_off TEXT, -- مثلاً "Friday,Saturday"
    FOREIGN KEY (user_id) REFERENCES users(id)
  )
''');
    await db.execute('''
  CREATE TABLE shifts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    shift_date TEXT NOT NULL,
    check_in TEXT,
    check_out TEXT,
    total_hours REAL DEFAULT 0,
    late_minutes INTEGER DEFAULT 0,
    is_absent INTEGER DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id)
  )
''');
    await db.execute('''
  CREATE TABLE payrolls (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    month TEXT NOT NULL,
    total_hours REAL DEFAULT 0,
    total_late_minutes INTEGER DEFAULT 0,
    total_absent_days INTEGER DEFAULT 0,
    net_salary REAL DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id)
  )
''');
    await db.execute('''
  CREATE TABLE debts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_name TEXT,
    total_amount REAL,
    date TEXT,
    invoice_id INTEGER,
    type TEXT,
    shift_id INTEGER
  )
''');
    await db.execute('''
  CREATE TABLE IF NOT EXISTS cash_drawer (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL NOT NULL,
    type TEXT NOT NULL,
    source TEXT,
    invoice_id INTEGER,
    date TEXT NOT NULL,
    shift_id INTEGER,
    discount REAL DEFAULT 0,
    cashier TEXT
  )
''');

    await db.execute('''
  CREATE TABLE debt_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    debt_id INTEGER,
    drink_name TEXT,
    qty INTEGER,
    price REAL,
    total REAL,
    FOREIGN KEY(debt_id) REFERENCES debts(id) ON DELETE CASCADE
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS invoice_drinks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER,
  drink_name TEXT,
  qty INTEGER,
  price REAL,
  total REAL,
  FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
)
''');
    await db.execute('''
CREATE TABLE debt_payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  debt_id INTEGER,
  amount REAL,
  paid_at TEXT,
  discount REAL DEFAULT 0
);

''');

    await db.execute('''
CREATE TABLE staff_members (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id INTEGER NOT NULL,  -- الكاشير المسؤول
    name TEXT NOT NULL,
    salary_per_hour REAL NOT NULL,
    shift_start TEXT,
    shift_end TEXT,
    work_hours REAL DEFAULT 0,  -- يحسب تلقائياً
    FOREIGN KEY(staff_id) REFERENCES users(id)
);


''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS staff_shifts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  staff_id INTEGER NOT NULL,
  start_time TEXT,
  end_time TEXT,
  FOREIGN KEY(staff_id) REFERENCES users(id)
);
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS staff_due_salaries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  staff_id INTEGER,
  staff_name TEXT,
  shift_id INTEGER,
  hours REAL,
  earned REAL,
  advance REAL,
  net REAL,
  date TEXT,
  is_paid INTEGER DEFAULT 0
);

''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS machine_balance (
id INTEGER PRIMARY KEY AUTOINCREMENT,
balance REAL NOT NULL
)
''');
    await db.execute('''
CREATE TABLE salaries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  month TEXT,
  paid_at INTEGER
);
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS transactions (
id INTEGER PRIMARY KEY AUTOINCREMENT,
cost REAL NOT NULL,
received REAL NOT NULL,
profit REAL NOT NULL,
date TEXT NOT NULL,
shift_id INTEGER
)
''');
    await db.execute('''
  CREATE TABLE IF NOT EXISTS machine_balance_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL NOT NULL,
    type TEXT NOT NULL,      -- deposit / withdraw
    note TEXT,
    date TEXT NOT NULL
  )
''');

    // seed initial machine_balance row
    await db.insert('machine_balance', {'balance': 0.0});
    /* await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        console_id INTEGER,
        start_time TEXT,
        end_time TEXT,
        device_cost REAL DEFAULT 0,
        drinks_cost REAL DEFAULT 0,
        total_cost REAL DEFAULT 0
      )
    ''');*/

    // seed: حساب السوبر ادمن فقط — النظام يبدأ فاضي من غير أي بيانات تجريبية
    await db.insert('users', {
      'username': 'superadmin',
      'password': '1234',
      'role': 'superadmin',
    });
    // جدول العملاء / الكاش
    await db.execute('''
    CREATE TABLE IF NOT EXISTS customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      balance REAL DEFAULT 0
    )
  ''');

    // seed: إضافة كاش الإدمن
    await db.insert('customers', {'name': 'AdminCash', 'balance': 0});
  }

  static Future<int> addStaffDueSalary(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('staff_due_salaries', {
      'staff_id': data['id'],
      'staff_name': data['name'],
      'shift_id': data['shiftId'],
      'hours': data['hours'],
      'earned': data['earned'],
      'advance': data['advance'],
      'net': data['net'],
      'date': DateTime.now().toIso8601String(),
      'is_paid': 0,
    });
  }

  static Future<bool> checkDevice() async {
    final db = await database;

    final result = await db.query('activation', limit: 1);

    final currentCpu = await DeviceFingerprint.cpuId();

    final currentBoard = await DeviceFingerprint.motherboardId();

    final currentDisk = await DeviceFingerprint.diskId();

    final currentHash = await DeviceFingerprint.deviceId();

    // أول تشغيل
    if (result.isEmpty) {
      print("===== FIRST ACTIVATION =====");

      print("CPU ID      : $currentCpu");
      print("BOARD ID    : $currentBoard");
      print("DISK ID     : $currentDisk");
      print("DEVICE HASH : $currentHash");
      await db.insert('activation', {
        'cpu_id': currentCpu,
        'board_id': currentBoard,
        'disk_id': currentDisk,
        'device_hash': currentHash,
      });

      return true;
    }

    final row = result.first;

    return row['cpu_id'] == currentCpu &&
        row['board_id'] == currentBoard &&
        row['disk_id'] == currentDisk &&
        row['device_hash'] == currentHash;
  }
  // ✋ حط الدالة دي جوه كلاس DBHelper بتاعك في lib/db_helper.dart
  // (زي addPaidColumnToSalaries وباقي دوال addXColumn الموجودة عندك بالفعل)
  //
  // الجدول ده بيخزن آخر حالة "approved/pending/..." معروفة محليًا،
  // عشان البرنامج يقدر يشتغل أوفلاين لفترة سماح حتى لو مفيش نت.

  static Future<void> addRemoteActivationTable() async {
    final db =
        await database; // نفس الـ getter/method اللي بتستخدمه في checkDevice()

    await db.execute('''
    CREATE TABLE IF NOT EXISTS remote_activation (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      device_hash TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      last_checked_at TEXT,
      license_type TEXT DEFAULT 'lifetime',
      expires_at TEXT,
      activation_code TEXT
    )
  ''');

    try {
      await db.execute(
        'ALTER TABLE remote_activation ADD COLUMN license_type TEXT DEFAULT \'lifetime\'',
      );
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE remote_activation ADD COLUMN expires_at TEXT',
      );
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE remote_activation ADD COLUMN activation_code TEXT',
      );
    } catch (_) {}
  }

  static Future<int> insertStaffSettings({
    required int userId,
    required double salaryPerHour,
    required int workHoursPerDay,
    required String daysOff,
  }) async {
    final db = await database;
    return await db.insert('staff_settings', {
      'user_id': userId,
      'salary_per_hour': salaryPerHour,
      'work_hours_per_day': workHoursPerDay,
      'days_off': daysOff,
    });
  }

  /*
  static Future<void> updateInvoiceDrinksCost(int invoiceId) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT SUM(total) as sum FROM invoice_items WHERE invoice_id = ?',
      [invoiceId],
    );

    final total = (res.first['sum'] ?? 0) as num;

    await db.update(
      'invoices',
      {'drinks_cost': total},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }
*/
  static Future<void> updateInvoiceDrinksCost(int invoiceId) async {
    final db = await database;

    // 🔹 المشروبات والأقسام الجديدة (أي تصنيف غير معروف بيدخل هنا)
    final drinks = await db.rawQuery(
      '''
    SELECT SUM(ii.total) AS sum
    FROM invoice_items ii
    JOIN drinks d ON d.id = ii.drink_id
    WHERE ii.invoice_id = ?
    AND d.temperature IS NOT NULL
    AND d.temperature NOT IN ('prodect', 'cigarette', 'shisha')
  ''',
      [invoiceId],
    );

    // 🔹 المنتجات فقط
    final products = await db.rawQuery(
      '''
  SELECT SUM(ii.total) AS sum
  FROM invoice_items ii
  JOIN drinks d ON d.id = ii.drink_id
  WHERE ii.invoice_id = ?
    AND (d.temperature = 'prodect' OR d.temperature IS NULL)
''',
      [invoiceId],
    );

    // 🔹 السجائر فقط
    final cigarettes = await db.rawQuery(
      '''
    SELECT SUM(ii.total) AS sum
    FROM invoice_items ii
    JOIN drinks d ON d.id = ii.drink_id
    WHERE ii.invoice_id = ?
    AND d.temperature = 'cigarette'
  ''',
      [invoiceId],
    );

    // 🔹 الشيشة فقط
    final shisha = await db.rawQuery(
      '''
    SELECT SUM(ii.total) AS sum
    FROM invoice_items ii
    JOIN drinks d ON d.id = ii.drink_id
    WHERE ii.invoice_id = ?
    AND d.temperature = 'shisha'
  ''',
      [invoiceId],
    );

    final drinksCost = (drinks.first['sum'] ?? 0) as num;
    final cigaretteCost = (cigarettes.first['sum'] ?? 0) as num;
    final shishaCost = (shisha.first['sum'] ?? 0) as num;
    final productsCost = ((products.first['sum'] ?? 0) as num).toDouble();

    // نحافظ على تكلفة البلايستيشن والخصم المسجلين على الفاتورة
    final invRow = await db.query(
      'invoices',
      columns: ['device_cost', 'discount'],
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    final deviceCost =
        invRow.isNotEmpty
            ? ((invRow.first['device_cost'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
    final discount =
        invRow.isNotEmpty
            ? ((invRow.first['discount'] as num?)?.toDouble() ?? 0.0)
            : 0.0;

    final totalItems = drinksCost + cigaretteCost + shishaCost + productsCost;
    final computedTotal = (deviceCost + totalItems - discount).clamp(
      0.0,
      double.infinity,
    );

    await db.update(
      'invoices',
      {
        'drinks_cost': drinksCost,
        'products_cost': productsCost,
        'cigarettes_cost': cigaretteCost,
        'shisha_cost': shishaCost,
        'total_cost': computedTotal,
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  // ===================== Settings (Feature Flags) =====================
  static Future<void> ensureAppSettingsTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  static Future<String?> getSetting(String key) async {
    final db = await database;
    final res = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first['value'] as String?;
  }

  static Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ===================== السوبر ادمن =====================

  static const String kBusinessNameKey = 'business_name';
  static const String kBusinessLogoKey = 'business_logo';
  static const String kBusinessTypeKey = 'business_type';
  static const String kCurrencySymbolKey = 'currency_symbol';
  static const String kReceiptThanksKey = 'receipt_thanks';
  static const String kReceiptPhoneKey = 'receipt_phone';
  static const String kReceiptAddressKey = 'receipt_address';
  static const String kReceiptTaxIdKey = 'receipt_tax_id';
  static const String kInvoicePaperMmKey = 'invoice_paper_mm';
  static const String kInvoicePrinterKey = 'invoice_printer_name';
  static const String kMaterialUnitsKey = 'material_units';
  static const String kPlaystationEnabledKey = 'playstation_enabled';
  static const String kSetupCompletedKey = 'setup_completed';

  /// يتأكد إن جدول المستخدمين بيسمح بالأدوار الأربعة
  /// (superadmin / admin / cashier / waiter) وكمان يضمن وجود حساب السوبر ادمن.
  ///
  /// ترحيل الدور القديم `staff`:
  /// - عند له [supervisor_id] (موظف فرعي تابع لكاشير) → دور `waiter` (موظف طلبات).
  /// - بدون مشرف (كان هو الكاشير في النظام القديم) → دور `cashier` (مدير صالة).
  static Future<void> ensureSuperAdminSupport() async {
    final db = await database;

    // 1) فحص تعريف جدول المستخدمين
    final tableInfo = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type='table' AND name='users'",
    );
    final createSql =
        (tableInfo.isNotEmpty ? (tableInfo.first['sql'] as String? ?? '') : '')
            .toLowerCase();

    final needsRebuild =
        ![
          'superadmin',
          'cashier',
          'waiter',
        ].every((r) => createSql.contains("'$r'"));

    if (needsRebuild) {
      // إعادة بناء الجدول لأن SQLite مش بتسمح بتعديل الـ CHECK
      final cols = await db.rawQuery('PRAGMA table_info(users)');
      final hasSupervisor = cols.any((c) => c['name'] == 'supervisor_id');

      await db.execute('PRAGMA foreign_keys = OFF');
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE users_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            role TEXT CHECK(role IN ('superadmin','admin','cashier','waiter')) DEFAULT 'cashier'${hasSupervisor ? ',\n            supervisor_id INTEGER' : ''}
          )
        ''');
        // staff من غير مشرف كان هو الكاشير، ومع مشرف بقى موظف طلبات
        final staffElse =
            hasSupervisor
                ? "CASE WHEN role = 'staff' THEN"
                    " CASE WHEN supervisor_id IS NOT NULL THEN 'waiter' ELSE 'cashier' END"
                    " ELSE 'cashier' END"
                : "'cashier'";
        await txn.execute('''
          INSERT INTO users_new (id, username, password, role${hasSupervisor ? ', supervisor_id' : ''})
          SELECT id, username, password,
            CASE
              WHEN role IN ('super_admin', 'superadmin') THEN 'superadmin'
              WHEN role = 'admin' THEN 'admin'
              WHEN role = 'cashier' THEN 'cashier'
              WHEN role = 'waiter' THEN 'waiter'
              ELSE $staffElse
            END${hasSupervisor ? ', supervisor_id' : ''}
          FROM users
        ''');
        await txn.execute('DROP TABLE users');
        await txn.execute('ALTER TABLE users_new RENAME TO users');
      });
      await db.execute('PRAGMA foreign_keys = ON');
      print('✅ تم تحديث جدول المستخدمين لدعم الأدوار (cashier / waiter)');
    }

    // 2) التأكد من وجود حساب السوبر ادمن (بالاسم أو بالدور)
    final byName = await db.query(
      'users',
      where: "username = 'superadmin'",
      limit: 1,
    );
    final byRole = await db.query(
      'users',
      where: "role = 'superadmin'",
      limit: 1,
    );

    if (byName.isEmpty && byRole.isEmpty) {
      await db.insert('users', {
        'username': 'superadmin',
        'password': '1234',
        'role': 'superadmin',
      });
      print('✅ تم إنشاء حساب السوبر ادمن الافتراضي (superadmin / 1234)');
    } else if (byName.isNotEmpty && byName.first['role'] != 'superadmin') {
      // حساب اسمه superadmin بدور قديم (زي super_admin) — نصلّح الدور
      await db.update(
        'users',
        {'role': 'superadmin'},
        where: 'id = ?',
        whereArgs: [byName.first['id']],
      );
      print('✅ تم تصحيح دور حساب superadmin');
    }
  }

  /// تحديث كلمة سر المستخدم الحالي
  static Future<void> updateUserPassword(int userId, String newPassword) async {
    final db = await database;
    await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ===================== أقسام المنتجات (Modules) =====================

  static const List<String> kLegacyTempOrder = [
    'hot',
    'cold',
    'normal',
    'prodect',
    'cigarette',
    'shisha',
  ];

  static const Map<String, String> kLegacyTempLabels = {
    'hot': 'سخن',
    'cold': 'بارد',
    'normal': 'غازية',
    'prodect': 'منتجات',
    'cigarette': 'سجائر',
    'shisha': 'شيشة',
  };

  static const Map<String, String> kLegacyTempLabelsEn = {
    'hot': 'Hot',
    'cold': 'Cold',
    'normal': 'Soft drinks',
    'prodect': 'Products',
    'cigarette': 'Cigarettes',
    'shisha': 'Hookah',
  };

  /// ينشئ جداول الأقسام والقوائم الفرعية، ويربط البيانات القديمة بقسم «المشروبات»
  static Future<void> ensureAppModules() async {
    final db = await database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_modules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_en TEXT DEFAULT '',
        icon TEXT DEFAULT 'category',
        color INTEGER DEFAULT 4283215696,
        sort_order INTEGER DEFAULT 0,
        is_enabled INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    // Upgrade existing databases created before bilingual section names.
    final moduleCols = await db.rawQuery('PRAGMA table_info(app_modules)');
    if (!moduleCols.any((c) => c['name'] == 'name_en')) {
      await db.execute(
        "ALTER TABLE app_modules ADD COLUMN name_en TEXT DEFAULT ''",
      );
      print('✅ Added column name_en to app_modules');
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_module_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        name_en TEXT DEFAULT '',
        key TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        is_enabled INTEGER DEFAULT 1
      )
    ''');

    // Upgrade existing databases created before bilingual submenu names.
    final categoryCols = await db.rawQuery(
      'PRAGMA table_info(app_module_categories)',
    );
    if (!categoryCols.any((c) => c['name'] == 'name_en')) {
      await db.execute(
        "ALTER TABLE app_module_categories ADD COLUMN name_en TEXT DEFAULT ''",
      );
      print('✅ Added column name_en to app_module_categories');
    }

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_module_categories_key ON app_module_categories(module_id, key)',
    );

    // إضافة عمود module_id للمنتجات والخامات
    final drinkCols = await db.rawQuery('PRAGMA table_info(drinks)');
    if (!drinkCols.any((c) => c['name'] == 'module_id')) {
      await db.execute('ALTER TABLE drinks ADD COLUMN module_id INTEGER');
      print('✅ Added column module_id to drinks');
    }
    if (!drinkCols.any((c) => c['name'] == 'name_en')) {
      await db.execute("ALTER TABLE drinks ADD COLUMN name_en TEXT DEFAULT ''");
      print('✅ Added column name_en to drinks');
    }

    final matCols = await db.rawQuery('PRAGMA table_info(raw_materials)');
    if (!matCols.any((c) => c['name'] == 'module_id')) {
      await db.execute(
        'ALTER TABLE raw_materials ADD COLUMN module_id INTEGER',
      );
      print('✅ Added column module_id to raw_materials');
    }

    // migration: قاعدة قديمة فيها منتجات ومن غير أقسام → اعمل قسم «المشروبات»
    final modulesCount =
        _firstIntOrNull(
          await db.rawQuery('SELECT COUNT(*) FROM app_modules'),
        ) ??
        0;

    if (modulesCount == 0) {
      final drinksCount =
          _firstIntOrNull(await db.rawQuery('SELECT COUNT(*) FROM drinks')) ??
          0;
      final materialsCount =
          _firstIntOrNull(
            await db.rawQuery('SELECT COUNT(*) FROM raw_materials'),
          ) ??
          0;
      final consolesCount =
          _firstIntOrNull(await db.rawQuery('SELECT COUNT(*) FROM consoles')) ??
          0;
      final legacyUsers =
          _firstIntOrNull(
            await db.rawQuery(
              "SELECT COUNT(*) FROM users WHERE role IN ('admin','cashier','waiter')",
            ),
          ) ??
          0;

      // قسم «المشروبات» بيتعمل بس لو فيه منتجات أو خامات فعلية تتلم عليه
      final hasProducts = drinksCount > 0 || materialsCount > 0;
      final isLegacyUsage = hasProducts || consolesCount > 0 || legacyUsers > 0;

      if (hasProducts) {
        final moduleId = await db.insert('app_modules', {
          'name': 'المشروبات',
          'name_en': 'Drinks',
          'icon': 'local_drink',
          'color': 0xFF14B8A6,
          'sort_order': 0,
          'is_enabled': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.rawUpdate(
          'UPDATE drinks SET module_id = ? WHERE module_id IS NULL',
          [moduleId],
        );
        await db.rawUpdate(
          'UPDATE raw_materials SET module_id = ? WHERE module_id IS NULL',
          [moduleId],
        );

        // قوائم فرعية من التصنيفات القديمة الموجودة فعلاً
        final temps = await db.rawQuery(
          'SELECT DISTINCT temperature FROM drinks WHERE temperature IS NOT NULL AND temperature != ""',
        );
        final found = temps.map((r) => r['temperature'].toString()).toSet();
        final ordered = <String>[
          ...kLegacyTempOrder.where(found.contains),
          ...found.where((t) => !kLegacyTempOrder.contains(t)),
        ];
        var order = 0;
        for (final t in ordered) {
          await db.insert('app_module_categories', {
            'module_id': moduleId,
            'name': kLegacyTempLabels[t] ?? t,
            'name_en': kLegacyTempLabelsEn[t] ?? '',
            'key': t,
            'sort_order': order++,
            'is_enabled': 1,
          });
        }

        print('✅ تم إنشاء قسم «المشروبات» وربط البيانات القديمة بيه');
      }

      // إعدادات افتراضية للنظام المستعمل — عشان معالج التهيئة ما يظهرش
      if (isLegacyUsage) {
        if (await getSetting(kBusinessNameKey) == null) {
          await setSetting(kBusinessNameKey, '');
        }
        if (await getSetting(kPlaystationEnabledKey) == null) {
          await setSetting(kPlaystationEnabledKey, '1');
        }
        if (await getSetting(kSetupCompletedKey) == null) {
          await setSetting(kSetupCompletedKey, '1');
        }
      }
    }

    // شفاء ذاتي (idempotent — ينفذ على كل فتح): أي منتج أو خامات من غير
    // قسم بيتلم مع أول قسم موجود، ولو مفيش أقسام أصلًا بيتعمل قسم
    // «المشروبات» الافتراضي. بيغطي بيانات اتحطت بعد آول ترحيل.
    final orphanCount =
        (_firstIntOrNull(
              await db.rawQuery(
                'SELECT COUNT(*) FROM drinks WHERE module_id IS NULL',
              ),
            ) ??
            0) +
        (_firstIntOrNull(
              await db.rawQuery(
                'SELECT COUNT(*) FROM raw_materials WHERE module_id IS NULL',
              ),
            ) ??
            0);
    if (orphanCount > 0) {
      final defaultModuleId =
          _firstIntOrNull(
            await db.rawQuery(
              'SELECT id FROM app_modules ORDER BY sort_order, id LIMIT 1',
            ),
          ) ??
          await db.insert('app_modules', {
            'name': 'المشروبات',
            'name_en': 'Drinks',
            'icon': 'local_drink',
            'color': 0xFF14B8A6,
            'sort_order': 0,
            'is_enabled': 1,
            'created_at': DateTime.now().toIso8601String(),
          });
      await db.rawUpdate(
        'UPDATE drinks SET module_id = ? WHERE module_id IS NULL',
        [defaultModuleId],
      );
      await db.rawUpdate(
        'UPDATE raw_materials SET module_id = ? WHERE module_id IS NULL',
        [defaultModuleId],
      );
      print('✅ تم ربط $orphanCount منتج/خامات من غير قسم بالقسم الافتراضي');
    }
  }

  // ---------- CRUD الأقسام ----------

  static Future<List<Map<String, dynamic>>> getModules({
    bool enabledOnly = false,
  }) async {
    final db = await database;
    return db.query(
      'app_modules',
      where: enabledOnly ? 'is_enabled = 1' : null,
      orderBy: 'sort_order ASC, id ASC',
    );
  }

  static Future<int> insertModule(Map<String, dynamic> module) async {
    final db = await database;
    final nextOrder =
        _firstIntOrNull(
          await db.rawQuery(
            'SELECT COALESCE(MAX(sort_order), -1) + 1 FROM app_modules',
          ),
        ) ??
        0;
    return db.insert('app_modules', {
      'name': module['name'],
      'name_en': module['name_en'] ?? '',
      'icon': module['icon'] ?? 'category',
      'color': module['color'] ?? 0xFF14B8A6,
      'sort_order': module['sort_order'] ?? nextOrder,
      'is_enabled': module['is_enabled'] ?? 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateModule(Map<String, dynamic> module) async {
    final db = await database;
    await db.update(
      'app_modules',
      module,
      where: 'id = ?',
      whereArgs: [module['id']],
    );
  }

  static Future<int> countModuleDrinks(int moduleId) async {
    final db = await database;
    return _firstIntOrNull(
          await db.rawQuery('SELECT COUNT(*) FROM drinks WHERE module_id = ?', [
            moduleId,
          ]),
        ) ??
        0;
  }

  static Future<void> deleteModule(int moduleId) async {
    final db = await database;
    await db.delete(
      'app_module_categories',
      where: 'module_id = ?',
      whereArgs: [moduleId],
    );
    await db.delete('app_modules', where: 'id = ?', whereArgs: [moduleId]);
  }

  static Future<void> reorderModules(List<int> orderedIds) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update(
          'app_modules',
          {'sort_order': i},
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
      }
    });
  }

  // ---------- CRUD القوائم الفرعية ----------

  static Future<List<Map<String, dynamic>>> getCategories({
    int? moduleId,
    bool enabledOnly = false,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object>[];
    if (moduleId != null) {
      where.add('module_id = ?');
      args.add(moduleId);
    }
    if (enabledOnly) {
      where.add('is_enabled = 1');
    }
    return db.query(
      'app_module_categories',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'sort_order ASC, id ASC',
    );
  }

  static Future<int> insertCategory({
    required int moduleId,
    required String name,
    String nameEn = '',
    String? key,
  }) async {
    final db = await database;
    final k = key ?? 'c${DateTime.now().microsecondsSinceEpoch}';
    final nextOrder =
        _firstIntOrNull(
          await db.rawQuery(
            'SELECT COALESCE(MAX(sort_order), -1) + 1 FROM app_module_categories WHERE module_id = ?',
            [moduleId],
          ),
        ) ??
        0;
    return db.insert('app_module_categories', {
      'module_id': moduleId,
      'name': name,
      'name_en': nameEn,
      'key': k,
      'sort_order': nextOrder,
      'is_enabled': 1,
    });
  }

  static Future<void> updateCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.update(
      'app_module_categories',
      category,
      where: 'id = ?',
      whereArgs: [category['id']],
    );
  }

  static Future<int> countCategoryDrinks(String key) async {
    final db = await database;
    return _firstIntOrNull(
          await db.rawQuery(
            'SELECT COUNT(*) FROM drinks WHERE temperature = ?',
            [key],
          ),
        ) ??
        0;
  }

  static Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('app_module_categories', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> reorderCategories(List<int> orderedIds) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update(
          'app_module_categories',
          {'sort_order': i},
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
      }
    });
  }

  // ---------- استعلامات مرتبطة بالأقسام ----------

  static Future<List<Map<String, dynamic>>> getDrinksByModule(
    int moduleId, {
    String? temperature,
  }) async {
    final db = await database;
    if (temperature != null) {
      return db.query(
        'drinks',
        where: 'module_id = ? AND temperature = ?',
        whereArgs: [moduleId, temperature],
      );
    }
    return db.query('drinks', where: 'module_id = ?', whereArgs: [moduleId]);
  }

  static Future<List<int>> getEnabledModuleIds() async {
    final db = await database;
    final rows = await db.query(
      'app_modules',
      columns: ['id'],
      where: 'is_enabled = 1',
    );
    return rows.map((r) => r['id'] as int).toList();
  }

  static const String kShishaCigarettesEnabledKey = 'shisha_cigarettes_enabled';

  /// افتراضيًا مقفولة لحد ما تتفعّل من شاشة الإعدادات
  static Future<bool> isShishaCigarettesEnabled() async {
    final v = await getSetting(kShishaCigarettesEnabledKey);
    return v == '1';
  }

  static Future<void> setShishaCigarettesEnabled(bool enabled) async {
    await setSetting(kShishaCigarettesEnabledKey, enabled ? '1' : '0');
  }

  /// المشروبات القابلة للبيع فعلاً — بتستبعد الشيشة/السجاير لو الميزة مقفولة
  /// المشروبات القابلة للبيع فعلاً — بتستبعد السجائر/الشيشة لو الميزة مقفولة
  static Future<List<Map<String, dynamic>>> getSellableDrinks() async {
    final db = await database;
    final enabled = await AppSettings.getShishaCigarettesEnabled();
    if (enabled) {
      return await db.query('drinks');
    }
    return await db.query(
      'drinks',
      where: "temperature NOT IN ('shisha','cigarette')",
    );
  }

  static Future<void> addShishaCostColumnToInvoices() async {
    final db = await database;
    final columns = await db.rawQuery("PRAGMA table_info(invoices)");
    if (!columns.any((c) => c['name'] == 'shisha_cost')) {
      await db.execute(
        'ALTER TABLE invoices ADD COLUMN shisha_cost REAL DEFAULT 0',
      );
      print('✅ Added column shisha_cost to invoices');
    }
  }

  // ---------- Shifts + Reports ----------
  static Future<List<Map<String, dynamic>>> getAllShifts({
    DateTime? date,
  }) async {
    final db = await database;

    String dateFilter = '';
    List<String> args = [];

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      dateFilter = 'WHERE s.shift_date >= ? AND s.shift_date < ?';
      args = [startOfDay.toIso8601String(), endOfDay.toIso8601String()];
    }

    final res = await db.rawQuery('''
    SELECT
      s.id,
      s.user_id,
      u.username AS staff_name,
      s.shift_date,
      s.check_in,
      s.check_out,
      s.total_hours,
      s.late_minutes,
      s.is_absent,
      COALESCE(SUM(inv.total_cost), 0) AS total_sales
    FROM shifts s
    LEFT JOIN users u ON u.id = s.user_id
    LEFT JOIN invoices inv
      -- 🎯 الربط برقم الشِفت الأول وواحد — فاتورة اتحولت (تسليم شيفت)
      -- بتحصى في شِفتها الحالي بس مش في شِفت اللي فتحها. فرع الاسم/
      -- التوقيت جاره لسكّ الفواتير القديمة اللي مش مربوطة بشِفت أصلًا.
      ON inv.shift_id = s.id
      OR (
        COALESCE(inv.shift_id, 0) = 0
        AND inv.staff_name = u.username
        AND (
          (inv.start_time BETWEEN s.check_in AND COALESCE(s.check_out, datetime('now')))
          OR (inv.end_time BETWEEN s.check_in AND COALESCE(s.check_out, datetime('now')))
        )
      )
    $dateFilter
    GROUP BY s.id
    ORDER BY s.id DESC
  ''', args);

    return res;
  }

  static Future<Map<String, dynamic>?> getStaffSettings(int userId) async {
    final db = await database;
    final res = await db.query(
      'staff_settings',
      where: 'user_id=?',
      whereArgs: [userId],
    );
    return res.isNotEmpty ? res.first : null;
  }

  static Future<int> checkIn(
    int userId,
    String date,
    String checkInTime,
  ) async {
    final db = await database;
    try {
      final id = await db.insert('shifts', {
        'user_id': userId,
        'shift_date': date,
        'check_in': checkInTime,
      });
      print(
        '✅ تم فتح شيفت جديد برقم ID: $id للمستخدم $userId في التاريخ $date',
      );
      return id;
    } catch (e) {
      print('❌ خطأ أثناء إنشاء الشيفت: $e');
      return 0; // نرجع 0 بدل null
    }
  }

  static Future<int> checkOut(int shiftId, String checkOutTime) async {
    final db = await database;
    // احسب الساعات
    final shift =
        (await db.query('shifts', where: 'id=?', whereArgs: [shiftId])).first;
    final checkIn = DateTime.parse(shift['check_in'].toString());
    final checkOut = DateTime.parse(checkOutTime);
    final totalHours = checkOut.difference(checkIn).inMinutes / 60.0;

    return await db.update(
      'shifts',
      {'check_out': checkOutTime, 'total_hours': totalHours},
      where: 'id=?',
      whereArgs: [shiftId],
    );
  }

  /// 🔧 هيل اتساق الفواتير مع أصحاب الشيفتات: فاتورة لازم اسم الكاشير
  /// بتاعها = مالك الشيفت اللي مسجلة عليه — الفواتير المنقولة بتسليم
  /// شيفت قديم (قبل الفكس) كان اسمها لسه على الكاشير القديم فكانت بترجع
  /// تظهر في تقاريره غلط. idempotent + الفواتير اللي شيفته اتمسح أو
  /// مستخدمه اتمسح مش بتتلمس خالص.
  static Future<void> healInvoiceStaffNames() async {
    final db = await database;
    // 🛡️ القواعد القديمة ممكن تكون من غير جدول shifts لسه — اسبسك بالسلام
    try {
      final hasShifts = await db.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'shifts'",
      );
      if (hasShifts.isEmpty) return;

      await db.execute('''
        UPDATE invoices
        SET staff_name = (
          SELECT u.username
          FROM shifts s
          LEFT JOIN users u ON u.id = s.user_id
          WHERE s.id = invoices.shift_id
        )
        WHERE shift_id IN (
          SELECT s2.id FROM shifts s2 JOIN users u2 ON u2.id = s2.user_id
        )
      ''');
    } catch (e) {
      print('Heal invoice staff names error: $e');
    }
  }

  /// 🤝 تسليم الشيفت: ينقل الفواتير المفتوحة (ترابيزات + بلايستيشن + أي جلسة
  /// شغالة) لشيفت موظف تاني — لو له شيفت مفتوح بيستكمل عليه، وإلا بينفتح له
  /// شيفت جديد — وكمان ينقل الموظفين الفرعيين الشغالين تحت الشيفت.
  ///
  /// كل الخطوات في transaction واحدة عشان ما يبقاش فيه وضع نص نص:
  /// إما الشغلانة كلها تنجح أو كلها ترجع زي ما كانت.
  ///
  /// يرجع {'moved': عدد الفواتير المنقولة, 'newShiftId': رقم الشيفت الجديد}.
  static Future<Map<String, Object?>> handoverShift({
    required int oldShiftId,
    required int targetUserId,
    required String targetUserName,
  }) async {
    final db = await database;
    return db.transaction<Map<String, Object?>>((txn) async {
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 1️⃣ شيفت مفتوح للموظف اللي هنسلّم له؟
      final open = await txn.query(
        'shifts',
        where: 'check_out IS NULL AND user_id = ?',
        whereArgs: [targetUserId],
      );

      int newShiftId;
      if (open.isNotEmpty) {
        newShiftId = open.first['id'] as int; // بيستكمل على شيفته الحالي
      } else {
        newShiftId = await txn.insert('shifts', {
          'user_id': targetUserId,
          'shift_date': date,
          'check_in': now.toIso8601String(),
          'total_hours': 0,
          'late_minutes': 0,
          'is_absent': 0,
        });
      }

      // 2️⃣ نقل كل الفواتير المفتوحة (اللي لسه متقفلت) للشيفت الجديد
      // — مع تغيير staff_name لاسم الموظف الجديد عشان تقارير الشيفت
      // (اللي بيشترطوا staff_name في نطاق زمن الشيفت) ميرجعوش تحسبها
      // على الكاشير القديم تاني.
      final moved = await txn.update(
        'invoices',
        {'shift_id': newShiftId, 'staff_name': targetUserName},
        where: 'shift_id = ? AND end_time IS NULL',
        whereArgs: [oldShiftId],
      );

      // 3️⃣ نقل الموظفين الفرعيين اللي لسه بيشغلوا تحت الشيفت (دفاعي —
      // عادة بيكونوا اتقفلوا قبل التسليم في فلو القفل الطبيعي)
      await txn.update(
        'sub_staff',
        {'supervisor_shift_id': newShiftId},
        where: 'supervisor_shift_id = ? AND shift_end IS NULL',
        whereArgs: [oldShiftId],
      );

      // 3️⃣ب شيفتات الموظفين الفرعيين المفتوحة في النظام الجديد
      // (staff_shifts.supervisor_shift_id) — بتتنقل لنفس الشيفت الجديد
      // عشان اللي هيكمل الشيفت يشوفهم ويقدر يقفلهم.
      await txn.update(
        'staff_shifts',
        {'supervisor_shift_id': newShiftId},
        where: 'supervisor_shift_id = ? AND end_time IS NULL',
        whereArgs: [oldShiftId],
      );

      // 4️⃣ هيل اتساق تاريخي (idempotent): أي فاتورة اسم الكاشير بتاعها
      // مش مطابق لمالك الشيفت اللي مسجلة عليه — نتيجة تسليم قديم اتعمل
      // قبل الفكس ده — بتترجع لصاحبها الحقيقي هنا. الفواتير اللي شيفتها
      // اتمسح أو مستخدمه اتمسح مش بتتلمس خالص.
      await txn.rawUpdate('''
        UPDATE invoices
        SET staff_name = (
          SELECT u.username
          FROM shifts s
          LEFT JOIN users u ON u.id = s.user_id
          WHERE s.id = invoices.shift_id
        )
        WHERE shift_id IN (
          SELECT s2.id FROM shifts s2 JOIN users u2 ON u2.id = s2.user_id
        )
      ''');

      return {'moved': moved, 'newShiftId': newShiftId};
    });
  }

  static Future<double> calculateMonthlySalary(int userId, String month) async {
    final db = await database;

    final settings = await getStaffSettings(userId);
    if (settings == null) return 0.0;

    final salaryPerHour = settings['salary_per_hour'] as double;

    // هات كل الشيفتات في الشهر
    final res = await db.rawQuery(
      '''
    SELECT * FROM shifts 
    WHERE user_id = ? AND shift_date LIKE ?
  ''',
      [userId, '$month%'],
    ); // مثال month = "2025-10"

    double totalHours = 0;
    int totalLate = 0;
    int absentDays = 0;

    for (final row in res) {
      totalHours += (row['total_hours'] as num?)?.toDouble() ?? 0;
      totalLate += row['late_minutes'] as int? ?? 0;
      absentDays += row['is_absent'] as int? ?? 0;
    }

    // احسب المرتب النهائي
    double baseSalary = totalHours * salaryPerHour;
    double latePenalty = totalLate * (salaryPerHour / 60);
    double absentPenalty =
        absentDays * settings['work_hours_per_day'] * salaryPerHour;

    double net = baseSalary - latePenalty - absentPenalty;

    await db.insert('payrolls', {
      'user_id': userId,
      'month': month,
      'total_hours': totalHours,
      'total_late_minutes': totalLate,
      'total_absent_days': absentDays,
      'net_salary': net,
    });

    return net;
  }

  // ---------- Users ----------
  static Future<Map<String, dynamic>?> getUser(
    String username,
    String password,
  ) async {
    final db = _db!;
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  static Future<int> insertUser(Map<String, dynamic> user) async {
    return await _db!.insert('users', user);
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await _db!.query('users');
  }

  /// 🌿 شجرة التعيينات كاملة — بتفرض إن جدول الفروع موجود وبترجع لكل ويتر
  /// كل المشرفين اللي اشتغل تحتهم (صف لكل تعيين). بستخدمها في شاشة إدارة
  /// المستخدمين عشان الشجرة تبنى من سطر واحد.
  static Future<List<Map<String, dynamic>>> getAllStaffAssignments() async {
    final db = _db!;
    await ensureSubStaffAssignments();
    return db.query(
      'sub_staff_assignments',
      columns: ['waiter_id', 'supervisor_id'],
      orderBy: 'created_at ASC',
    );
  }

  // ---------- Consoles ----------
  static Future<int> insertConsole(ConsoleModel c) async {
    return await _db!.insert('consoles', c.toMap());
  }

  static Future<int> updateConsole(ConsoleModel c) async {
    return await _db!.update(
      'consoles',
      c.toMap(),
      where: 'id=?',
      whereArgs: [c.id],
    );
  }

  static Future<int> deleteConsole(int id) async {
    return await _db!.delete('consoles', where: 'id=?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getAllConsoles() async {
    return await _db!.query('consoles');
  }

  // ---------- Drinks ----------
  static Future<int> insertDrink(DrinkModel d) async {
    return await _db!.insert('drinks', d.toMap());
  }

  static Future<int> updateDrink(DrinkModel d) async {
    return await _db!.update(
      'drinks',
      d.toMap(),
      where: 'id=?',
      whereArgs: [d.id],
    );
  }

  static Future<int> deleteDrink(int id) async {
    return await _db!.delete('drinks', where: 'id=?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getAllDrinks() async {
    return await _db!.query('drinks');
  }

  // ---------- Invoices ----------
  static Future<int> createInvoice(
    int consoleId,
    String startTime, {
    String? staffName,
    String? customerName,
    int? shiftId,
    // 🆕 إضافات السعر الثابت
    bool isFixedPrice = false,
    double fixedPrice = 0.0,
  }) async {
    return await _db!.insert('invoices', {
      'console_id': consoleId,
      'start_time': startTime,
      'end_time': null,
      'device_cost': 0,
      'drinks_cost': 0,
      'total_cost': 0,
      'customer_name': customerName ?? '',
      'staff_name': staffName,
      'shift_id': shiftId,
      // ✅ السعر الثابت
      'is_fixed_price': isFixedPrice ? 1 : 0,
      'fixed_price': fixedPrice,
    });
  }

  static Future<int> endInvoice(
    int invoiceId,
    String endTime,
    double deviceCost,
    double drinksCost, {
    double discount = 0,
    bool addToCashDrawer = false,
    String paymentType = 'paid',
    int? shiftId,
  }) async {
    // 🔹 جلب الفاتورة
    final rows = await _db!.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );

    if (rows.isEmpty) return 0;

    final invoice = rows.first;

    // ✅ لو سعر ثابت → تجاهل حساب الوقت
    final bool isFixed = invoice['is_fixed_price'] == 1;
    final double finalDeviceCost =
        isFixed
            ? (invoice['fixed_price'] as num?)?.toDouble() ?? 0.0
            : deviceCost;

    final total = (finalDeviceCost + drinksCost - discount).clamp(
      0,
      double.infinity,
    );
    // ضمان عدم السالب

    // تحديث الفاتورة
    final updateData = <String, dynamic>{
      'end_time': endTime,
      'device_cost': deviceCost,
      'drinks_cost': drinksCost,
      'discount': discount, // ✅ حفظ الخصم
      'total_cost': total,
      'payment_type': paymentType, // 👈 نوع الدفع
    };
    if (shiftId != null) {
      updateData['shift_id'] = shiftId; // ✅ حفظ الشيفت بشكل مؤكد
    }

    final result = await _db!.update(
      'invoices',
      updateData,
      where: 'id = ?',
      whereArgs: [invoiceId],
    );

    // 🆕 تصحيح تقسيم الأعمدة (مشروبات/منتجات/سجاير/شيشة) وحساب الإجمالي الصحيح
    await updateInvoiceDrinksCost(invoiceId);

    // لو كان دفع فعلاً → أضف للكاش
    if (addToCashDrawer) {
      await _db!.insert('cash_drawer', {
        'amount': total,
        'type': 'income',
        'source': 'invoice',
        'invoice_id': invoiceId,
        'shift_id': shiftId,
        'date': DateTime.now().toIso8601String(),
      });
    }

    return result;
  }

  /*
  static Future<int> endInvoice(
    int invoiceId,
    String endTime,
    double deviceCost,
    double drinksCost,
  ) async {
    final total = deviceCost + drinksCost;
    return await _db!.update(
      'invoices',
      {
        'end_time': endTime,
        'device_cost': deviceCost,
        'drinks_cost': drinksCost,
        'total_cost': total,
      },
      where: 'id=?',
      whereArgs: [invoiceId],
    );
  }
*/

  static Future<List<Map<String, dynamic>>> getActiveInvoices() async {
    return await _db!.query('invoices', where: 'end_time IS NULL');
  }

  static Future<List<Map<String, dynamic>>> getAllInvoices() async {
    return await _db!.query('invoices');
  }

  // ---------- Invoice items ----------
  static Future<int> addInvoiceItem(
    int invoiceId,
    int drinkId,
    int qty,
    double price,
    String drinkName,
  ) async {
    final db = _db!;

    final total = price * qty; // ✅ الحساب هنا

    final existing = await db.query(
      'invoice_items',
      where: 'invoice_id = ? AND drink_id = ? AND item_type = ?',
      whereArgs: [invoiceId, drinkId, 'drink'],
      limit: 1,
    );

    int result;

    if (existing.isNotEmpty) {
      final currentQty = existing.first['qty'] as int;
      final currentTotal = (existing.first['total'] as num).toDouble();

      result = await db.update(
        'invoice_items',
        {'qty': currentQty + qty, 'total': currentTotal + total},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      result = await db.insert('invoice_items', {
        'invoice_id': invoiceId,
        'drink_id': drinkId,
        'drink_name': drinkName,
        'qty': qty,
        'price': price,
        'total': total,
        'item_type': 'drink',
        'hours': 0,
      });
    }

    // 🔻 خصم من المخزون
    final drinkRow = await db.query(
      'drinks',
      where: 'id = ?',
      whereArgs: [drinkId],
    );

    if (drinkRow.isNotEmpty) {
      final currentStock = drinkRow.first['qty'] as int? ?? 0;
      await db.update(
        'drinks',
        {'qty': currentStock - qty},
        where: 'id = ?',
        whereArgs: [drinkId],
      );
    }

    return result;
  }

  // داخل DBHelper
  static Future<void> deleteAllInvoices() async {
    final db = await DBHelper.database;
    await db.delete('invoices');
    await db.delete(
      'invoice_items',
    ); // لو عندك جدول للمشروبات المرتبطة بالفواتير
  }

  /*
  static Future<List<Map<String, dynamic>>> getItemsForInvoice(
    int invoiceId,
  ) async {
    return await _db!.rawQuery(
      '''
      SELECT ii.*, d.name as drink_name, d.price as drink_price
      FROM invoice_items ii
      LEFT JOIN drinks d ON d.id = ii.drink_id
      WHERE ii.invoice_id = ?
    ''',
      [invoiceId],
    );
  }
*/
  static Future<List<Map<String, dynamic>>> getItemsForInvoice(
    int invoiceId,
  ) async {
    // لو الفاتورة مرتبطة بدين، الأصناف الفعلية (بعد أي تعديل) موجودة
    // في debt_items فقط — دي المصدر الوحيد الصحيح، من غير دمج مع invoice_items
    // (لأن invoice_items بتفضل زي ما كانت وقت إنشاء الدين، ومش بتتحدث بعد كده)
    final debts = await _db!.query(
      'debts',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );

    if (debts.isNotEmpty) {
      final debtId = debts.first['id'] as int;
      final debtItems = await _db!.query(
        'debt_items',
        where: 'debt_id = ?',
        whereArgs: [debtId],
      );

      return debtItems.map((item) {
        return {
          ...item,
          'drink_name': item['drink_name'] ?? 'شحن رصيد'.tr(),
          'drink_price': item['price'] ?? 0,
        };
      }).toList();
    }

    // مفيش دين مرتبط → المصدر invoice_items عادي
    return await _db!.rawQuery(
      '''
    SELECT ii.*, d.name as drink_name, d.price as drink_price
    FROM invoice_items ii
    LEFT JOIN drinks d ON d.id = ii.drink_id
    WHERE ii.invoice_id = ?
    ''',
      [invoiceId],
    );
  }

  static Future<int> updateInvoiceItemQty(
    int invoiceItemId,
    int newQty,
    double newTotal,
  ) async {
    return await _db!.update(
      'invoice_items',
      {'qty': newQty, 'total': newTotal},
      where: 'id = ?',
      whereArgs: [invoiceItemId],
    );
  }

  static Future<void> deleteInvoiceItem(int itemId) async {
    final db = await database; // افترض أن عندك getter اسمه database
    await db.delete(
      'invoice_items', // اسم جدول المشروبات في الفاتورة
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// مسح كل البيانات المتعلقة بشيفت محدد
  static Future<void> clearShiftData(
    int shiftId,
    String staffName,
    DateTime checkIn,
    DateTime? checkOut,
  ) async {
    final db = await database;
    final endTime =
        checkOut?.toIso8601String() ?? DateTime.now().toIso8601String();

    // -------------------------------
    // 1️⃣ مسح machine_balance_logs الخاصة بالشيفت
    // -------------------------------
    await db.delete(
      'machine_balance_logs',
      where: 'date >= ? AND date <= ?',
      whereArgs: [checkIn.toIso8601String(), endTime],
    );

    // -------------------------------
    // 2️⃣ جلب الفواتير الخاصة بالشيفت
    // -------------------------------
    final invoices = await db.query(
      'invoices',
      where: 'staff_name = ? AND start_time >= ? AND start_time <= ?',
      whereArgs: [staffName, checkIn.toIso8601String(), endTime],
    );

    final invoiceIds = invoices.map((e) => e['id']).toList();

    // -------------------------------
    // 3️⃣ مسح invoice_items المرتبطة بالفواتير
    // -------------------------------
    if (invoiceIds.isNotEmpty) {
      final idsString = invoiceIds.join(',');
      await db.rawDelete(
        'DELETE FROM invoice_items WHERE invoice_id IN ($idsString)',
      );
    }

    // -------------------------------
    // 4️⃣ مسح الفواتير نفسها
    // -------------------------------
    await db.delete(
      'invoices',
      where: 'staff_name = ? AND start_time >= ? AND start_time <= ?',
      whereArgs: [staffName, checkIn.toIso8601String(), endTime],
    );

    // -------------------------------
    // 5️⃣ مسح المصروفات الخاصة بالشيفت
    // -------------------------------
    await db.delete('expenses', where: 'shift_id = ?', whereArgs: [shiftId]);

    // -------------------------------
    // 6️⃣ حذف سجل الشيفت نفسه
    // -------------------------------
    await db.delete('shifts', where: 'id = ?', whereArgs: [shiftId]);
  }

  static Future<void> clearAllExpenses() async {
    final db = await database;
    await db.delete('expenses'); // حذف كل الصفوف بدون شروط
  }

  static Future<void> clearAllData() async {
    final db = await DBHelper.database;

    // مسح كل الفواتير
    await db.delete('invoices');

    // مسح كل عناصر الفواتير
    await db.delete('invoice_items');
    await db.delete('cash_drawer');
    await db.delete('expenses');
  }

  // الحصول على كل الترابيزات
  static Future<List<Map<String, dynamic>>> getAllTables() async {
    return await _db!.query('tables');
  }

  // إضافة ترابيزة
  static Future<int> addTable(String name) async {
    return await _db!.insert('tables', {'name': name});
  }

  // صرف راتب موظف (صافي الرواتب المتراكمة) وتصفير الرصيد
  static Future<void> paySalary(int userId, String month) async {
    final db = await DBHelper.database;

    // جلب الراتب المتراكم لهذا الشهر
    final net = await calculateMonthlySalary(userId, month);

    if (net > 0) {
      // أضف سجل صرف في جدول expenses أو salaries_paid
      await db.insert('salaries_paid', {
        'user_id': userId,
        'month': month,
        'amount': net,
        'paid_at': DateTime.now().toIso8601String(),
      });

      // تصفير الرواتب المتراكمة للشهر الحالي (يعتمد على جدول shifts أو sub_staff_shifts)
      await db.update(
        'sub_staff',
        {'advance': 0.0}, // أو أي حقل محتسب الراتب المتراكم
        where: 'id = ?',
        whereArgs: [userId],
      );
    }
  }

  static Future<void> markSalaryPaid(int userId, String month) async {
    final db = await database;
    await db.update(
      'staff_due_salaries',
      {'is_paid': 1}, // تعليمها كمدفوعة
      where: 'staff_id=? AND strftime("%Y-%m", date)=?',
      whereArgs: [userId, month],
    );
  }

  static Future<bool> isSalaryPaid(int userId, String month) async {
    final db = await database; // افترض أن عندك قاعدة بيانات جاهزة
    final result = await db.query(
      'salaries',
      where: 'user_id = ? AND month = ? AND paid = ?',
      whereArgs: [userId, month, 1], // 1 يعني مدفوع
    );
    return result.isNotEmpty;
  }

  // في DBHelper.dart
  static Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  // تحديث حالة الجلسة (active_invoice_id)
  static Future<int> updateTableInvoice(int tableId, int? invoiceId) async {
    return await _db!.update(
      'tables',
      {'active_invoice_id': invoiceId},
      where: 'id=?',
      whereArgs: [tableId],
    );
  }

  static Future<int> insertTable(String name) async {
    return await _db!.insert('tables', {'name': name});
  }

  static Future<int> updateTableActiveInvoice(
    int tableId,
    int? invoiceId,
  ) async {
    return await _db!.update(
      'tables',
      {'active_invoice_id': invoiceId},
      where: 'id=?',
      whereArgs: [tableId],
    );
  }

  // ---------- Invoice items ----------

  // الاسم القديم — إجمالي كل الأصناف عدا البلايستيشن (مشروبات+سجاير+شيشة+منتجات)
  // مستخدمة كـ"إجمالي مؤقت قبل الحفظ" في شاشات الدفع
  static Future<double> getDrinksCostForInvoice(int invoiceId) async {
    final res = await _db!.rawQuery(
      "SELECT SUM(total) as s FROM invoice_items WHERE invoice_id = ? AND item_type != 'playstation'",
      [invoiceId],
    );
    if (res.isNotEmpty && res.first['s'] != null) {
      return (res.first['s'] as num).toDouble();
    }
    return 0.0;
  }

  // 🆕 مشروبات فقط (hot/cold/normal) — لو محتاج الرقم الحقيقي بدون سجاير/شيشة/منتجات
  static Future<double> getPureDrinksCostForInvoice(int invoiceId) async {
    final res = await _db!.rawQuery(
      '''
    SELECT SUM(ii.total) as s
    FROM invoice_items ii
    JOIN drinks d ON d.id = ii.drink_id
    WHERE ii.invoice_id = ?
      AND d.temperature IS NOT NULL
      AND d.temperature NOT IN ('prodect', 'cigarette', 'shisha')
    ''',
      [invoiceId],
    );
    if (res.isNotEmpty && res.first['s'] != null) {
      return (res.first['s'] as num).toDouble();
    }
    return 0.0;
  }

  // ===================== إضافات المصروفات =====================
  static Future<int> addExpense({
    required String description,
    required double amount,
    required String addedBy, // اسم الكاشير أو admin
    required int shiftId,
  }) async {
    final db = await database;

    // 1️⃣ إضافة المصروف في جدول expenses
    final expenseId = await db.insert('expenses', {
      'description': description,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'added_by': addedBy,
      'shift_id': shiftId,
    });

    // 2️⃣ خصم المبلغ من درج الكاش
    await db.insert('cash_drawer', {
      'type': 'expense', // نوع الحركة
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'source': 'expense_$addedBy', // لتحديد مصدر المصروف
    });

    return expenseId;
  }

  static Future<List<Map<String, dynamic>>> getExpensesByShift(
    int shiftId,
  ) async {
    final db = await database;
    return await db.query(
      'expenses',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
    );
  }

  // ===================== إضافات العملاء =====================
  /// يضمن وجود جدول العملاء — قواعد البيانات القديمة اللي اتعملت قبل
  /// إضافة الجدول كانت بتفشل في تسجيل أي عميل جديد.
  static Future<void> ensureCustomersTable() async {
    final db = await database;
    await _ensureCustomersTableOn(db);
  }

  static Future<void> _ensureCustomersTableOn(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        balance REAL DEFAULT 0
      )
    ''');
  }

  /// تسجيل عميل — بيتنادى من ديالوج الدفع الآجل الجديد عشان أي اسم
  /// يكتبه المستخدم يفضل محفوظ ويظهر في المرات الجاية.
  static Future<int> addCustomer(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 0;
    // AdminCash حساب كاش داخلي — مش عميل.
    if (trimmed.toLowerCase() == 'admincash') return 0;
    final db = await database;
    await _ensureCustomersTableOn(db);
    return await db.insert('customers', {
      'name': trimmed,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// كل أسماء العملاء المسجّلين — من جدول العملاء + العملاء اللي عليهم
  /// أجل + أي اسم اتسجل على فاتورة. ده اللي بيظهر في ديالوجات الدفع
  /// الآجل، بدل ما القايمة كانت بتقرأ جدول الديون بس.
  /// (AdminCash حساب كاش داخلي مش عميل حقيقي — مستبعد.)
  static Future<List<String>> getAllCustomerNames() async {
    final db = await database;
    await _ensureCustomersTableOn(db);
    final rows = await db.rawQuery('''
      SELECT name AS n FROM customers
        WHERE TRIM(COALESCE(name, '')) != ''
          AND LOWER(TRIM(name)) != 'admincash'
      UNION
      SELECT customer_name AS n FROM debts
        WHERE TRIM(COALESCE(customer_name, '')) != ''
          AND LOWER(TRIM(customer_name)) != 'admincash'
      UNION
      SELECT customer_name AS n FROM invoices
        WHERE TRIM(COALESCE(customer_name, '')) != ''
          AND LOWER(TRIM(customer_name)) != 'admincash'
      ORDER BY n COLLATE NOCASE ASC
    ''');
    final names = <String>[];
    for (final row in rows) {
      final name = (row['n'] ?? '').toString().trim();
      if (name.isNotEmpty) names.add(name);
    }
    return names;
  }

  static Future<void> updateCustomerBalance(String name, double amount) async {
    final db = await database;
    final res = await db.query(
      'customers',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (res.isNotEmpty) {
      final current = (res.first['balance'] as num).toDouble();
      await db.update(
        'customers',
        {'balance': current + amount},
        where: 'name = ?',
        whereArgs: [name],
      );
    } else {
      await db.insert('customers', {'name': name, 'balance': amount});
    }
  }

  static Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return await db.query('customers');
  }

  // ===================== موظفين الشيفت =====================
  static Future<int> addStaffToShift(int shiftId, int staffId) async {
    final db = await database;
    return await db.insert('shift_staff', {
      'shift_id': shiftId,
      'staff_id': staffId,
    });
  }

  static Future<List<Map<String, dynamic>>> getShiftStaff(int shiftId) async {
    final db = await database;
    return await db.query(
      'shift_staff',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
    );
  }

  static Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await database;
    return await db.query('expenses', orderBy: 'date DESC');
  }

  static Future<List<Map<String, dynamic>>> getExpensesByDate(
    DateTime date,
  ) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return await db.query(
      'expenses',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
  }

  // إذا عندك جدول customers أو cash_summary
  static Future<int> addAdminExpenseAndDeduct({
    required String description,
    required double amount,
  }) async {
    final db = await database;

    // 1️⃣ إضافة المصروف في جدول المصروفات
    final expenseId = await db.insert('expenses', {
      'description': description,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'added_by': 'admin',
      'shift_id': null,
    });

    // 2️⃣ خصم المبلغ من AdminCash في جدول العملاء
    final res = await db.query(
      'customers',
      where: 'name = ?',
      whereArgs: ['AdminCash'],
    );

    if (res.isNotEmpty) {
      final current = (res.first['balance'] as num).toDouble();
      await db.update(
        'customers',
        {'balance': current - amount},
        where: 'name = ?',
        whereArgs: ['AdminCash'],
      );
    } else {
      await db.insert('customers', {'name': 'AdminCash', 'balance': -amount});
    }

    // 3️⃣ إضافة الخصم في cash_drawer بحيث يظهر في الرصيد
    await db.insert('cash_drawer', {
      'type': 'expense', // لأنه مصروف
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'source': 'admin_expense', // علشان تعرف مصدره
    });

    return expenseId;
  }

  static Future<int> addDebt(String personName, double totalAmount) async {
    final db = await database;
    return await db.insert('debts', {
      'person_name': personName,
      'total_amount': totalAmount,
      'date': DateTime.now().toIso8601String(),
    });
  }

  /// إغلاق شيفتات الموظفين الفرعيين المفتوحة.
  ///
  /// 🌿 بنسخة الفروع: لما الكاشير يقفل شيفته، بنقفل شيفتات الفروع اللي كانت
  /// شغالة تحت شيفت الكاشير ده **بس** — الشيفتات الشغالة عند كاشير تاني في
  /// نفس الوقت ما بتتقفلش بالغلط ولا بيتحاسب عليها كاشير تاني.
  /// هنا فروع قديمة من غير مشرف بالمقابلة (supervisor_shift_id IS NULL)
  /// بتترجع للكاشير اللي قفل زي النظام القديم.
  static Future<int> closeAllOpenSubStaffShifts({int? supervisorShiftId}) async {
    final db = await DBHelper.database;
    final count = await db.update(
      'staff_shifts',
      {'end_time': DateTime.now().toIso8601String()},
      where:
          supervisorShiftId != null
              ? 'end_time IS NULL AND (supervisor_shift_id = ? OR supervisor_shift_id IS NULL)'
              : 'end_time IS NULL',
      whereArgs: supervisorShiftId != null ? [supervisorShiftId] : null,
    );
    return count;
  }

  static Future<List<Map<String, dynamic>>> getInvoicesByShift(
    int shiftId,
  ) async {
    final db = await database;

    // 🆕 ربط تلقائي لأي فواتير في نطاق هذا الشيفت كان shift_id فيها فارغاً
    try {
      final shiftRows = await db.rawQuery(
        '''
        SELECT s.*, u.username AS staff_name
        FROM shifts s
        LEFT JOIN users u ON u.id = s.user_id
        WHERE s.id = ?
      ''',
        [shiftId],
      );

      if (shiftRows.isNotEmpty) {
        final staffName = shiftRows.first['staff_name'] as String?;
        final checkIn = shiftRows.first['check_in'] as String?;
        final checkOut = shiftRows.first['check_out'] as String?;

        if (staffName != null && checkIn != null) {
          if (checkOut != null) {
            await db.rawUpdate(
              '''
              UPDATE invoices
              SET shift_id = ?
              WHERE (shift_id IS NULL OR shift_id = 0)
                AND staff_name = ?
                AND start_time >= ?
                AND start_time <= ?
            ''',
              [shiftId, staffName, checkIn, checkOut],
            );
          } else {
            await db.rawUpdate(
              '''
              UPDATE invoices
              SET shift_id = ?
              WHERE (shift_id IS NULL OR shift_id = 0)
                AND staff_name = ?
                AND start_time >= ?
            ''',
              [shiftId, staffName, checkIn],
            );
          }
        }
      }
    } catch (e) {
      print('Auto-heal shift invoices error: $e');
    }

    return await db.rawQuery(
      '''
    SELECT i.*, c.name AS console_name
    FROM invoices i
    LEFT JOIN consoles c ON c.id = i.console_id
    WHERE i.shift_id = ?  -- ربط مباشر بالشيفت
    ORDER BY i.start_time ASC
  ''',
      [shiftId],
    );
  }

  // 🆕 جلب ملخص تجميعي لكافة المنتجات والأصناف المباعة في الشيفت
  static Future<List<Map<String, dynamic>>> getShiftProductsSummary(
    int shiftId,
  ) async {
    final db = await database;

    // معالجة أي فواتير لم ترتبط بالشيفت أولاً
    await getInvoicesByShift(shiftId);

    return await db.rawQuery(
      '''
      SELECT 
        COALESCE(NULLIF(TRIM(ii.drink_name), ''), TRIM(d.name), 'صنف غير محدد') AS product_name,
        SUM(ii.qty) AS total_qty,
        CASE 
          WHEN SUM(ii.qty) > 0 THEN ROUND(SUM(ii.total) / SUM(ii.qty), 2)
          ELSE AVG(ii.price)
        END AS unit_price,
        SUM(ii.total) AS total_amount,
        COALESCE(d.temperature, ii.item_type, 'drink') AS category
      FROM invoice_items ii
      JOIN invoices i ON i.id = ii.invoice_id
      LEFT JOIN drinks d ON d.id = ii.drink_id
      WHERE i.shift_id = ?
        AND (i.payment_type IS NULL OR i.payment_type != 'ملغي')
        AND (ii.item_type IS NULL OR ii.item_type != 'playstation')
        AND ii.qty > 0
      GROUP BY COALESCE(NULLIF(TRIM(ii.drink_name), ''), TRIM(d.name), 'صنف غير محدد')
      ORDER BY total_amount DESC, total_qty DESC
      ''',
      [shiftId],
    );
  }

  static Future<void> addDebtItems(
    int debtId,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await database;
    for (var item in items) {
      await db.insert('debt_items', {
        'debt_id': debtId,
        'drink_name': item['drink_name'],
        'qty': item['qty'],
        'price': item['drink_price'],
        'total': item['total'],
      });
    }
  }

  static Future<List<Map<String, dynamic>>> getAllDebts() async {
    final db = await database;

    return await db.query('debts', orderBy: 'date DESC');
  }

  static Future<List<Map<String, dynamic>>> getDebtItems(int debtId) async {
    final db = await database;
    final items = await db.query(
      'debt_items',
      where: 'debt_id = ?',
      whereArgs: [debtId],
    );
    return items ?? []; // لو رجعت null خليها قائمة فارغة
  }

  static Future<void> saveDebtItemsFromInvoice(
    int invoiceId,
    int debtId,
  ) async {
    final db = await database;

    final drinks = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );

    for (var d in drinks) {
      await db.insert('debt_items', {
        'debt_id': debtId,
        'drink_id': d['drink_id'], // 🆕
        'drink_name': d['item_name'] ?? d['drink_name'] ?? '',
        'qty': d['qty'] ?? 0,
        'price': d['price'] ?? 0.0,
        'total': d['total'] ?? 0.0,
      });
    }
  }

  static Future<int> addCashDrawerEntry(
    double amount,
    String type,
    String source, {
    int? invoiceId,
    String? cashier,
    int? shiftId,
  }) async {
    final db = await database;
    return await db.insert('cash_drawer', {
      'amount': amount,
      'type': type,
      'source': source,
      'invoice_id': invoiceId,
      'cashier': cashier, // اسم الكاشير
      'shift_id': shiftId,
      'date': DateTime.now().toIso8601String(),
    });
  }

  static Future<int?> getLastOpenShiftId() async {
    final db = await database;
    final rows = await db.query(
      'shifts',
      where: 'check_out IS NULL',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['id'] as num).toInt();
  }

  static Future<void> addTemperatureColumn() async {
    final db = await database;

    // نجيب كل الأعمدة الخاصة بجدول drinks
    final columns = await db.rawQuery('PRAGMA table_info(drinks)');

    // نتحقق لو العمود موجود
    final exists = columns.any((col) => col['name'] == 'temperature');

    if (!exists) {
      // لو مش موجود نضيفه
      await db.execute(
        'ALTER TABLE drinks ADD COLUMN temperature TEXT DEFAULT "normal";',
      );
      print('✅ تم إضافة عمود temperature');
    } else {
      print('ℹ️ العمود temperature موجود بالفعل — لن يتم إضافته');
    }
  }

  static Future<void> addSupervisorShiftIdColumn() async {
    final db = await database;
    final columns = await db.rawQuery('PRAGMA table_info(staff_shifts)');
    if (columns.any((c) => c['name'] == 'supervisor_shift_id')) {
      print('ℹ️ العمود supervisor_shift_id موجود بالفعل — لن يتم إضافته');
      return;
    }
    try {
      await db.execute(
        'ALTER TABLE staff_shifts ADD COLUMN supervisor_shift_id INTEGER;',
      );
      print('✅ تم إضافة عمود supervisor_shift_id');
    } catch (e) {
      print('❌ تعذر إضافة supervisor_shift_id: $e');
    }
  }

  static Future<void> addSupervisorIdColumn() async {
    final db = await database;
    final columns = await db.rawQuery('PRAGMA table_info(users)');
    if (columns.any((c) => c['name'] == 'supervisor_id')) {
      print('ℹ️ العمود supervisor_id موجود بالفعل — لن يتم إضافته');
      return;
    }
    try {
      await db.execute('ALTER TABLE users ADD COLUMN supervisor_id INTEGER;');
      print('✅ تم إضافة عمود supervisor_id');
    } catch (e) {
      print('❌ تعذر إضافة supervisor_id: $e');
    }
  }

  /// 🌿 علاقة كثير-لكثير: الموظف الفرعي (الويتر) يقدر يتعيّن عند أكتر من
  /// كاشير في نفس الوقت — التعيين من شاشة كاشير ما بيشيلوش من كاشير تاني.
  ///
  /// الجدول ده هو مرجع التعيين بقالب مضمن (idempotent):
  /// بيتعمل لو مش موجود، وبيرحّل تاريخيًا أي ويتر كان ليه مشرف واحد في
  /// العمود القديم users.supervisor_id (من غير ما نلمس العمود نفسه).
  static Future<void> ensureSubStaffAssignments() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sub_staff_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        waiter_id INTEGER NOT NULL,
        supervisor_id INTEGER NOT NULL,
        created_at TEXT,
        UNIQUE(waiter_id, supervisor_id)
      )
    ''');
    // ترحيل تاريخي: الويترات اللي ليه مشرف واحد في العمود القديم → فرع تعيين.
    await db.execute('''
      INSERT OR IGNORE INTO sub_staff_assignments (waiter_id, supervisor_id, created_at)
      SELECT u.id, u.supervisor_id, datetime('now')
      FROM users u
      WHERE u.role = 'waiter' AND u.supervisor_id IS NOT NULL
    ''');
  }

  /// ➕ تعيين ويتر عند كاشير — إضافة فرع جديدة بدل النقل:
  /// لو هو متعيين عند كاشير تاني بيفضل متعيين عنده برضه.
  /// الكاشير ده كمان بيبقى المشرف "الأولي" لو كان الويتر من غير مشرف أصلاً
  /// (عشان شرائح إدارة المستخدمين وشاشات الإدارة تفضل شغالة زي ما هي).
  static Future<void> assignWaiterToSupervisor({
    required int waiterId,
    required int supervisorId,
  }) async {
    final db = await database;
    // 🌿 فرع التعيين الجديد — التكرار ما بيتسجلش مرتين (UNIQUE pair).
    await db.insert('sub_staff_assignments', {
      'waiter_id': waiterId,
      'supervisor_id': supervisorId,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    // المشرف الأولي بيتسجل بس لو الويتر كان لسه من غير مشرف —
    // كده ما بنشيلش فرع المشرف اللي أنشئ تحته في إدارة المستخدمين.
    await db.execute('''
      UPDATE users SET supervisor_id = ?
      WHERE id = ? AND supervisor_id IS NULL
    ''', [supervisorId, waiterId]);
  }

  /// ➖ شيل الويتر من عند الكاشير ده بس — فروع تانية عند كاشيرات تانيين ما بتتأثرش.
  static Future<void> unassignWaiterFromSupervisor({
    required int waiterId,
    required int supervisorId,
  }) async {
    final db = await database;
    await db.delete(
      'sub_staff_assignments',
      where: 'waiter_id = ? AND supervisor_id = ?',
      whereArgs: [waiterId, supervisorId],
    );
  }

  /// شيل كل فروع التعيين بتاعة الويتر (بتُستخدم لما الأدمن يظبطه
  /// «ويتر مستقل بدون مشرف» من إدارة المستخدمين).
  static Future<void> unassignAllWaiters(int waiterId) async {
    final db = await database;
    await db.delete(
      'sub_staff_assignments',
      where: 'waiter_id = ?',
      whereArgs: [waiterId],
    );
  }

  /// تنظيف فروع التعيين عند حذف مستخدم — سواء كان ويتر (فروع من ناحية
  /// waiter_id) أو كاشير/مشرف (فروع من ناحية supervisor_id).
  static Future<void> deleteUserAssignments(int userId) async {
    final db = await database;
    await db.delete(
      'sub_staff_assignments',
      where: 'waiter_id = ? OR supervisor_id = ?',
      whereArgs: [userId, userId],
    );
  }

  /// آخر شيفت مفتوح لليوزر من جدول shifts (شيفت الكاشير نفسه) — أو null.
  static Future<int?> getOpenShiftId(int userId) async {
    final db = await database;
    final res = await db.query(
      'shifts',
      where: 'user_id = ? AND check_out IS NULL',
      whereArgs: [userId],
      orderBy: 'id DESC',
      limit: 1,
    );
    return res.isNotEmpty ? res.first['id'] as int : null;
  }

  static Future<List<Map<String, dynamic>>> getSubStaff(
    int supervisorId,
  ) async {
    final db = await database;
    // 🌿 التعيين بيرجع من جدول الفروع sub_staff_assignments — فالويتر يقدر
    // يظهر عند أكتر من كاشير في نفس الوقت. سجل الشيفت المفتوح بيتنسب
    // للكاشير ده بس (supervisor_shift_id = شيفت الكاشير ده المفتوح)
    // — عشان صفوف فروع كاشيرات تانيين ما تظهرش هنا وتتحسب غلط.
    //
    // بنختار أحدث صف شيفت مفتوح «متاح للفرع ده» (مرتبط بشيفت الكاشير ده
    // أو صف قديم غير مرتبط) — من غير ما نتأثر بشيفتات فروع كاشيرات تانيين.
    return await db.rawQuery(
      '''
    SELECT u.*, s.salary_per_hour, s.work_hours_per_day,
      sh.start_time as shift_start, sh.end_time as shift_end,
      (SELECT COUNT(*) FROM sub_staff_assignments c WHERE c.waiter_id = u.id)
        AS assign_count
    FROM sub_staff_assignments a
    JOIN users u ON u.id = a.waiter_id
    LEFT JOIN staff_settings s ON s.user_id = u.id
    LEFT JOIN staff_shifts sh ON sh.id = (
      SELECT sh2.id FROM staff_shifts sh2
      WHERE sh2.staff_id = u.id
        AND sh2.end_time IS NULL
        AND (sh2.supervisor_shift_id IS NULL OR sh2.supervisor_shift_id = (
              SELECT MAX(sh0.id) FROM shifts sh0
              WHERE sh0.user_id = a.supervisor_id AND sh0.check_out IS NULL))
      ORDER BY sh2.id DESC
      LIMIT 1
    )
    WHERE a.supervisor_id = ?
    ORDER BY u.username
  ''',
      [supervisorId],
    );
  }

  /// موظفو الطلبات (الويترات) المتاحين للتعيين كموظفين فرعيين عند الكاشير —
  /// كل الويترات اللي مش متعيينين عند الكاشير ده (حتى لو متعيينين عند
  /// غيره — التعيين إضافي مش نقلي: بيتضاف للكاشير ده بدون ما يتشال
  /// من غيره). assign_count = عدد الكاشيرات المتعيين عندهم أصلاً.
  static Future<List<Map<String, dynamic>>> getAssignableWaiters(
    int supervisorId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT u.*,
      (SELECT COUNT(*) FROM sub_staff_assignments a2 WHERE a2.waiter_id = u.id)
        AS assign_count
    FROM users u
    WHERE u.role = 'waiter'
      AND u.id NOT IN (
        SELECT waiter_id FROM sub_staff_assignments WHERE supervisor_id = ?
      )
    ORDER BY u.username
  ''',
      [supervisorId],
    );
  }

  // في DBHelper
  static Future<void> endShiftForSubStaff({
    required int staffId,
    required String endTime,
    int? supervisorShiftId,
  }) async {
    final db = await DBHelper.database;
    await db.update(
      'staff_shifts',
      {'end_time': endTime},
      where:
          supervisorShiftId == null
              ? 'staff_id = ? AND end_time IS NULL'
              : supervisorShiftId == 0
              ? // 🌿 مشرف صفر = صفوف قديمة مش مربوطة بمشرف، بس (إدارة بدون شيفت كاشير مفتوح).
                'staff_id = ? AND end_time IS NULL AND supervisor_shift_id IS NULL'
              : // 🌿 ملزمة مشرف: بنقفل شيفت الموظف تحت الكاشير ده بس —
                // صفوف فروع كاشيرات تانيين (supervisor_shift_id مختلف) ما بتتقفلش غلط.
                // حماية: صفوف قديمة من غير مشرف بتقفل مع الكاشير ده احتياطي.
                'staff_id = ? AND end_time IS NULL AND (supervisor_shift_id = ? OR supervisor_shift_id IS NULL)',
      whereArgs:
          supervisorShiftId != null && supervisorShiftId > 0
              ? [staffId, supervisorShiftId]
              : [staffId],
    );
  }

  static Future<void> startStaffShift(int staffId, DateTime startTime) async {
    final db = await database;
    await db.insert('staff_shifts', {
      'staff_id': staffId,
      'start_time': startTime.toIso8601String(),
    });
  }

  ///newww
  static Future<void> consumeRecipe(int drinkId, int soldQty) async {
    final db = await database;

    final recipes = await db.query(
      'drink_recipes',
      where: 'drink_id=?',
      whereArgs: [drinkId],
    );

    for (final r in recipes) {
      final materialId = r['material_id'] as int;

      final recipeQty = (r['qty'] as num).toDouble();

      final consumedQty = recipeQty * soldQty;

      await db.rawUpdate(
        '''
      UPDATE raw_materials
      SET qty = ROUND(qty - ?, 4)
      WHERE id = ?
      ''',
        [consumedQty, materialId],
      );

      await db.insert('material_transactions', {
        'material_id': materialId,
        'qty': consumedQty,
        'type': 'OUT',
        'notes': 'بيع منتج رقم $drinkId',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<void> restoreRecipe(int drinkId, int qtyToRestore) async {
    final db = await database;

    final recipes = await db.query(
      'drink_recipes',
      where: 'drink_id = ?',
      whereArgs: [drinkId],
    );

    for (final r in recipes) {
      final materialId = r['material_id'] as int;

      final recipeQty = (r['qty'] as num).toDouble();

      final restoredQty = recipeQty * qtyToRestore;

      await db.rawUpdate(
        '''
      UPDATE raw_materials
      SET qty = ROUND(qty + ?, 4)
      WHERE id = ?
      ''',
        [restoredQty, materialId],
      );

      await db.insert('material_transactions', {
        'material_id': materialId,
        'qty': restoredQty,
        'type': 'IN',
        'notes': 'إرجاع مخزون من منتج رقم $drinkId',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<bool> canConsumeRecipe(int drinkId, int qty) async {
    final db = await database;

    final recipe = await db.query(
      'drink_recipes',
      where: 'drink_id = ?',
      whereArgs: [drinkId],
    );

    for (final item in recipe) {
      print(item);
      final materialId = item['material_id'] as int;

      final needed = (item['qty'] as num).toDouble() * qty;

      final material = await db.query(
        'raw_materials',
        where: 'id = ?',
        whereArgs: [materialId],
      );
      final recipes = await db.query('drink_recipes');
      print(recipes);
      print('Searching material id = $materialId');
      print('Result = $material');
      final materials = await db.query('raw_materials');
      print(materials);

      if (material.isEmpty) {
        print('Material not found: $materialId');
        return false;
      }

      final name = material.first['name'];

      final available = (material.first['qty'] as num).toDouble();

      print('Material: $name | Available: $available | Needed: $needed');

      const epsilon = 0.0001;
      if (available < needed - epsilon) {
        print('FAILED => $name');
        return false;
      }
    }

    return true;
  }

  static Future<List<Map<String, dynamic>>> getMaterials() async {
    final db = await database;

    return db.query('raw_materials', orderBy: 'name');
  }

  /// 🧠 توحيد اسم الخامة للمقارنة: بيشيل المسافات الزيادة والتشكيل
  /// والتطويل، ويوحّد الحروف العربية (أ/إ/آ→ا، ى→ي، ة→ه، ؤ→و، ئ→ي)
  /// ويحوّل الإنجليزي لحروف صغيرة — عشان «سكر» و«سكّر» و«Sugar»/«sugar»
  /// يتعاملوا كخامة واحدة.
  static String normalizeMaterialName(String name) {
    var s = name.trim().toLowerCase();
    // تشكيل عربي + تطويل
    s = s.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');
    const arabicMap = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ٱ': 'ا',
      'ى': 'ي',
      'ة': 'ه',
      'ؤ': 'و',
      'ئ': 'ي',
    };
    arabicMap.forEach((from, to) => s = s.replaceAll(from, to));
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  /// 🔎 يدوّر على خامة مسجّلة بنفس الاسم (عربي/إنجليزي، مع تجاهل
  /// التشكيل والمسافات وحالة الحروف) — بيرجع الصف الموجود أو null.
  static Future<Map<String, dynamic>?> findMaterialByName(String name) async {
    final db = await database;
    final rows = await db.query('raw_materials', orderBy: 'id ASC');
    final target = normalizeMaterialName(name);
    if (target.isEmpty) return null;
    for (final row in rows) {
      final rowName = (row['name'] ?? '').toString();
      if (normalizeMaterialName(rowName) == target) return row;
    }
    return null;
  }

  static Future<void> addMaterialStock(int materialId, double qty) async {
    final db = await database;

    await db.rawUpdate(
      '''
    UPDATE raw_materials
    SET qty = ROUND(qty + ?, 4)
    WHERE id = ?
    ''',
      [qty, materialId],
    );

    await db.insert('material_transactions', {
      'material_id': materialId,
      'qty': qty,
      'type': 'IN',
      'notes': 'توريد خامة',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<int> insertMaterial(MaterialModel m) async {
    final db = await database;

    final id = await db.insert('raw_materials', m.toMap());

    if (m.qty > 0) {
      await db.insert('material_transactions', {
        'material_id': id,
        'qty': m.qty,
        'type': 'IN',
        'notes': 'رصيد افتتاحي',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return id;
  }

  static Future updateMaterial(MaterialModel m) async {
    final db = await database;

    final old = await db.query(
      'raw_materials',
      where: 'id=?',
      whereArgs: [m.id],
    );

    final oldQty = (old.first['qty'] as num).toDouble();

    final diff = m.qty - oldQty;

    await db.update(
      'raw_materials',
      m.toMap(),
      where: 'id=?',
      whereArgs: [m.id],
    );

    if (diff != 0) {
      await db.insert('material_transactions', {
        'material_id': m.id,
        'qty': diff.abs(),
        'type': diff > 0 ? 'IN' : 'OUT',
        'notes': 'تعديل يدوي',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future deleteMaterial(int id) async {
    final db = await database;
    final recipes = await db.query(
      'drink_recipes',
      where: 'material_id = ?',
      whereArgs: [id],
    );

    print('Used in ${recipes.length} drinks');
    // حذف الخامة من جميع الوصفات
    await db.delete('drink_recipes', where: 'material_id = ?', whereArgs: [id]);

    // حذف الخامة نفسها
    await db.delete('raw_materials', where: 'id = ?', whereArgs: [id]);
  }

  static Future addRecipe(int drinkId, int materialId, double qty) async {
    final db = await database;

    await db.insert('drink_recipes', {
      'drink_id': drinkId,
      'material_id': materialId,
      'qty': qty,
    });
  }
  //////////////////////////////

  static Future<void> endStaffShift(
    int staffId,
    DateTime endTime, {
    int? supervisorShiftId,
  }) async {
    final db = await database;
    await db.update(
      'staff_shifts',
      {'end_time': endTime.toIso8601String()},
      // 🌿 ملزمة مشرف: بنقفل شيفت الموظف تحت الكاشير ده بس.
      // مشرف صفر = صفوف قديمة مش مربوطة بمشرف، بس. null = بدون فلتر (نظام قديم).
      where:
          supervisorShiftId == null
              ? 'staff_id = ? AND end_time IS NULL'
              : supervisorShiftId == 0
              ? 'staff_id = ? AND end_time IS NULL AND supervisor_shift_id IS NULL'
              : 'staff_id = ? AND end_time IS NULL AND (supervisor_shift_id = ? OR supervisor_shift_id IS NULL)',
      whereArgs:
          supervisorShiftId != null && supervisorShiftId > 0
              ? [staffId, supervisorShiftId]
              : [staffId],
    );
  }

  static Future<List<Map<String, dynamic>>> getTransactionsByShift(
    int shiftId,
  ) async {
    final db = await initDB();
    return await db.query(
      'transactions', // أو اسم جدولك الخاص بالمعاملات العادية
      where: 'shift_id = ?',
      whereArgs: [shiftId],
      orderBy: 'date DESC',
    );
  }

  static Future<void> startShiftForSubStaff({
    required int staffId,
    required int supervisorShiftId,
    required String startTime,
  }) async {
    final db = await DBHelper.database;
    await db.insert('staff_shifts', {
      'staff_id': staffId,
      'supervisor_shift_id': supervisorShiftId,
      'start_time': startTime,
      'end_time': null,
    });
  }

  static Future<List<Map<String, dynamic>>> getSubStaffWithShifts(
    int staffId,
  ) async {
    final db = await DBHelper.database;
    final result = await db.rawQuery(
      '''
    SELECT s.*, ss.start_time AS shift_start, ss.end_time AS shift_end
    FROM sub_staff s
    LEFT JOIN staff_shifts ss
      ON s.id = ss.staff_id
      AND ss.end_time IS NULL
    WHERE s.staff_id = ?
  ''',
      [staffId],
    );

    return result;
  }

  // ===================== ملخص الشيفت =====================
  static Future<Map<String, dynamic>> getShiftSummary(int shiftId) async {
    final db = await database;

    final sales = await db.rawQuery(
      "SELECT SUM(total_cost) as total_sales FROM invoices WHERE shift_id = ? AND payment_type != 'ملغي'",
      [shiftId],
    );
    final expenses = await db.rawQuery(
      'SELECT SUM(amount) as total_expenses FROM expenses WHERE shift_id = ?',
      [shiftId],
    );

    final totalSales = (sales.first['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalExpenses =
        (expenses.first['total_expenses'] as num?)?.toDouble() ?? 0.0;

    return {
      'total_sales': totalSales,
      'total_expenses': totalExpenses,
      'net_cash': totalSales - totalExpenses,
    };
  }

  // ===================== تقارير العملاء =====================
  static Future<DateTime> getShiftStartTime() async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT start_time FROM shifts ORDER BY start_time DESC LIMIT 1',
    );

    if (res.isNotEmpty) {
      return DateTime.parse(res.first['start_time'] as String);
    }
    // لو ما في أي شيفت مسجل، ارجع الوقت الحالي
    return DateTime.now();
  }

  // 🧾 1. تجيب كل الفواتير الخاصة بعميل معين خلال شهر
  static Future<List<Map<String, dynamic>>> getCustomerInvoicesWithDetails(
    String customerName,
    String month,
  ) async {
    final db = await database;

    final invoices = await db.rawQuery(
      '''
    SELECT 
      i.id,
      i.start_time,
      i.end_time,
      i.device_cost,
      i.drinks_cost,
      i.total_cost,
      c.name AS console_name
    FROM invoices i
    LEFT JOIN consoles c ON c.id = i.console_id
    WHERE i.customer_name = ? AND i.start_time LIKE ?
    ORDER BY i.start_time DESC
  ''',
      [customerName, '$month%'],
    );

    final List<Map<String, dynamic>> result = [];

    for (var invoice in invoices) {
      final mutableInvoice = Map<String, dynamic>.from(invoice);

      // 🧃 المشروبات
      final drinks = await db.rawQuery(
        '''
      SELECT d.name, ii.qty, ii.total
      FROM invoice_items ii
      LEFT JOIN drinks d ON d.id = ii.drink_id
      WHERE ii.invoice_id = ?
    ''',
        [invoice['id']],
      );
      mutableInvoice['drinks'] = drinks;

      // 🎮 حساب المدة وتفاصيل الجلسة
      double hours = 0;
      if (invoice['start_time'] != null && invoice['end_time'] != null) {
        final start = DateTime.tryParse(invoice['start_time'].toString());
        final end = DateTime.tryParse(invoice['end_time'].toString());
        if (start != null && end != null) {
          hours = end.difference(start).inMinutes / 60.0;
        }
      }

      // ✅ تحويل القيمة الرقمية لتفادي null أو نوع غير رقمي
      final deviceCost =
          (invoice['device_cost'] is num)
              ? invoice['device_cost'] as num
              : num.tryParse(invoice['device_cost']?.toString() ?? '0') ?? 0;

      mutableInvoice['session'] = {
        'console_name': invoice['console_name'] ?? 'غير معروف'.tr(),
        'start_time': invoice['start_time'],
        'end_time': invoice['end_time'],
        'duration': hours,
        'device_cost': deviceCost,
      };

      result.add(mutableInvoice);
    }

    return result;
  }

  static Future<double> getMachineBalance() async {
    final db = await initDB();
    final res = await db.query('machine_balance', limit: 1);
    if (res.isEmpty) return 0.0;
    return (res.first['balance'] as num).toDouble();
  }

  static Future<void> setMachineBalance(double value) async {
    final db = await initDB();
    final exists = await db.query('machine_balance', limit: 1);
    if (exists.isEmpty) {
      await db.insert('machine_balance', {'balance': value});
    } else {
      await db.update(
        'machine_balance',
        {'balance': value},
        where: 'id = ?',
        whereArgs: [exists.first['id']],
      );
    }
  }

  static Future<void> addToMachineBalance(double value) async {
    final db = await initDB();
    await db.rawUpdate('UPDATE machine_balance SET balance = balance + ?', [
      value,
    ]);
  }

  static Future<void> updateDrinkQty(int id, int qty) async {
    final db = await database;
    await db.update('drinks', {'qty': qty}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> subtractFromMachineBalance(double value) async {
    final db = await initDB();
    await db.rawUpdate('UPDATE machine_balance SET balance = balance - ?', [
      value,
    ]);
  }

  // داخل DBHelper
  static Future<void> deleteAllTransactions() async {
    final db = await database;
    await db.delete('transactions'); // افترض أن جدول العمليات اسمه transactions
  }

  static Future<int> recordTransaction({
    required double cost,
    required double received,
    required int shiftId, // 🔥 جديد
  }) async {
    final db = await initDB();

    final profit = received - cost;

    // حفظ العملية في transactions مع shiftId
    final id = await db.insert('transactions', {
      'cost': cost,
      'received': received,
      'profit': profit,
      'date': DateTime.now().toIso8601String(),
      'shift_id': shiftId, // ⚡ ربط بالشيفت
    });

    // خصم التكلفة من رصيد المكنة
    await subtractFromMachineBalance(cost);

    // احسب الرصيد الحالي للدرج
    double drawerBalance = await getCashDrawerBalance();
    print('رصيد درج الكاش الحالي: $drawerBalance');

    return id;
  }

  static Future<double> getCashDrawerBalance({DateTime? date}) async {
    final db = await initDB();

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      whereClause = 'WHERE date >= ? AND date < ?';
      whereArgs = [startOfDay.toIso8601String(), endOfDay.toIso8601String()];
    }

    final result = await db.rawQuery('''
    SELECT SUM(CASE WHEN type = "income" THEN amount ELSE -amount END) as balance
    FROM cash_drawer
    $whereClause
  ''', whereArgs);

    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await initDB();
    return await db.query('transactions', orderBy: 'date DESC');
  }

  static Future<Map<String, dynamic>> getSummary() async {
    final db = await initDB();
    final res = await db.rawQuery('''
SELECT
COUNT(*) AS total_ops,
COALESCE(SUM(cost),0) AS total_cost,
COALESCE(SUM(received),0) AS total_received,
COALESCE(SUM(profit),0) AS total_profit
FROM transactions
''');

    if (res.isEmpty)
      return {
        'total_ops': 0,
        'total_cost': 0.0,
        'total_received': 0.0,
        'total_profit': 0.0,
      };
    final row = res.first;
    return {
      'total_ops': row['total_ops'] as int,
      'total_cost': (row['total_cost'] as num).toDouble(),
      'total_received': (row['total_received'] as num).toDouble(),
      'total_profit': (row['total_profit'] as num).toDouble(),
    };
  }

  // دفع راتب موظف
  static Future<void> payStaffSalary(int userId, String month) async {
    final db = await database;

    await db.insert('salaries', {
      'user_id': userId,
      'month': month,
      'paid_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /* static Future<List<String>> getDebtorsNames() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT customer_name FROM debts WHERE customer_name IS NOT NULL');
    return rows.map((e) => e['customer_name'].toString()).toList();
  }
*/
  static Future<List<String>> getDebtorsNames() async {
    // 🔧 بنرجّع كل العملاء المسجّلين (عملاء + أجل + فواتير) مش اللي
    // عليهم ديون بس — كانت دي أسباب إن العملاء المسجلين ما يظهرونش
    // في ديالوجات الدفع الآجل.
    return getAllCustomerNames();
  }

  // جلب تاريخ الرواتب المدفوعة
  static Future<List<Map<String, dynamic>>> getSalaryHistory(int userId) async {
    final db = await database;

    return await db.query(
      'salaries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'paid_at DESC',
    );
  }

  static Future<void> deleteCustomerInvoices(
    String customerName,
    String month,
  ) async {
    final db = await DBHelper.database;
    await db.delete(
      'invoices',
      where: 'customer_name = ? AND start_time LIKE ?',
      whereArgs: [customerName, '$month%'],
    );
  }

  // داخل DBHelper
  static Future<List<Map<String, dynamic>>> getDebtsByShift(int shiftId) async {
    final db = await DBHelper.database;
    return db.query(
      'debts',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
      orderBy: 'date ASC',
    );
  }

  static Future<void> clearDrinks() async {
    final db = await database;
    await db.delete('drinks');
  }
  // sotp time PS

  // ⏸️ إيقاف الجلسة
  // ⏸️ إيقاف الجلسة
  static Future<void> pauseInvoice(int invoiceId) async {
    final rows = await _db!.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );

    // ✅ لو الفاتورة متوقفة بالفعل، متعملش حاجة عشان متضيعش وقت التوقف الأصلي
    if (rows.isNotEmpty && rows.first['paused_at'] != null) {
      return;
    }

    await _db!.update(
      'invoices',
      {'paused_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  // ▶️ استئناف الجلسة
  static Future<void> resumeInvoice(int invoiceId) async {
    final rows = await _db!.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );

    if (rows.isEmpty) return;

    final pausedAt = rows.first['paused_at'];
    if (pausedAt == null) return;

    final pausedTime = DateTime.parse(pausedAt as String);
    final pausedSeconds = DateTime.now().difference(pausedTime).inSeconds;

    await _db!.update(
      'invoices',
      {
        'paused_at': null,
        'total_paused_seconds':
            ((rows.first['total_paused_seconds'] as int?) ?? 0) + pausedSeconds,
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  ///////////////////////////////////////////////////////////////////////////
  static Future<DrinkModel?> getDrinkByUnique(
    String name,
    double price,
    String temperature,
  ) async {
    final db = await database;
    final res = await db.query(
      'drinks',
      where: 'name = ? AND price = ? AND temperature = ?',
      whereArgs: [name, price, temperature],
    );

    if (res.isNotEmpty) {
      return DrinkModel.fromMap(res.first);
    }
    return null;
  }

  // 💰 2. تجيب إجمالي الدخل الشهري لكل عميل
  static Future<List<Map<String, dynamic>>> getMonthlyCustomerTotals(
    String month,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT 
      COALESCE(customer_name, 'بدون اسم') AS customer_name,
      COUNT(*) AS invoice_count,
      SUM(total_cost) AS total_income
    FROM invoices
    WHERE start_time LIKE ?
    GROUP BY customer_name
    ORDER BY total_income DESC
  ''',
      ['$month%'],
    );

    return result;
  } ////////////////////////////////////////////

  // ===================== إنشاء طلب جديد =====================
  static Future<int> createOrder({
    required int tableId,
    required String tableName,
    required List<Map<String, dynamic>> items,
    // items: [{drink_id, drink_name, qty, price}]
    int? shiftId,
    String? note,
  }) async {
    final db = await DBHelper.database;

    final orderId = await db.insert('orders', {
      'table_id': tableId,
      'table_name': tableName,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'shift_id': shiftId,
      'note': note,
    });

    for (final item in items) {
      final total = (item['price'] as double) * (item['qty'] as int);
      await db.insert('order_items', {
        'order_id': orderId,
        'drink_id': item['drink_id'],
        'drink_name': item['drink_name'],
        'qty': item['qty'],
        'price': item['price'],
        'total': total,
      });
    }

    return orderId;
  }

  // ===================== جلب طلبات pending =====================
  static Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final db = await DBHelper.database;
    return await db.query(
      'orders',
      where: "status = 'pending'",
      orderBy: 'created_at ASC',
    );
  }

  // ===================== جلب كل الطلبات =====================
  static Future<List<Map<String, dynamic>>> getAllOrders({
    String? status,
  }) async {
    final db = await DBHelper.database;
    if (status != null) {
      return await db.query(
        'orders',
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'created_at DESC',
      );
    }
    return await db.query('orders', orderBy: 'created_at DESC');
  }

  // ===================== جلب عناصر طلب معين =====================
  static Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await DBHelper.database;
    return await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  // ===================== تحديث حالة الطلب =====================
  static Future<void> updateOrderStatus(int orderId, String status) async {
    final db = await DBHelper.database;
    await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ===================== قبول الطلب + إضافته للفاتورة =====================
  /// يقبل الطلب ويضيف عناصره لفاتورة الترابيزة الحالية
  static Future<void> acceptOrder({
    required int orderId,
    required int invoiceId,
    required String staffName,
    required int shiftId,
  }) async {
    final db = await DBHelper.database;

    final items = await getOrderItems(orderId);

    for (final item in items) {
      final drinkId = item['drink_id'] as int;
      final qty = item['qty'] as int;
      final price = (item['price'] as num).toDouble();
      final drinkName = item['drink_name'] as String;

      // أضف للفاتورة
      await DBHelper.addInvoiceItem(invoiceId, drinkId, qty, price, drinkName);

      // اخصم من المخزون الخام
      await DBHelper.consumeRecipe(drinkId, qty);
    }

    // حدّث حالة الطلب + ربطه بالفاتورة
    await db.update(
      'orders',
      {'status': 'accepted', 'invoice_id': invoiceId},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ===================== إلغاء الطلب =====================
  static Future<void> cancelOrder(int orderId) async {
    await updateOrderStatus(orderId, 'cancelled');
  }

  // ===================== إجمالي طلبات الشيفت =====================
  static Future<double> getOrdersTotalByShift(int shiftId) async {
    final db = await DBHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(oi.total) as total
      FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      WHERE o.shift_id = ? AND o.status = 'accepted'
    ''',
      [shiftId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ===================== طلبات ترابيزة معينة =====================
  static Future<List<Map<String, dynamic>>> getOrdersByTable(
    int tableId,
  ) async {
    final db = await DBHelper.database;
    return await db.query(
      'orders',
      where: "table_id = ? AND status NOT IN ('cancelled', 'done')",
      whereArgs: [tableId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<void> addColumnsToDebtPayments() async {
    final db = await database;
    final columns = await db.rawQuery("PRAGMA table_info(debt_payments)");

    if (!columns.any((c) => c['name'] == 'customer_name')) {
      await db.execute(
        'ALTER TABLE debt_payments ADD COLUMN customer_name TEXT',
      );
      print('✅ Added column customer_name to debt_payments');
    }

    if (!columns.any((c) => c['name'] == 'invoice_id')) {
      await db.execute(
        'ALTER TABLE debt_payments ADD COLUMN invoice_id INTEGER',
      );
      print('✅ Added column invoice_id to debt_payments');
    }

    // 🆕 إضافة عمود shift_id
    if (!columns.any((c) => c['name'] == 'shift_id')) {
      await db.execute('ALTER TABLE debt_payments ADD COLUMN shift_id INTEGER');
      print('✅ Added column shift_id to debt_payments');
    }
    // 🆕 إضافة عمود discount — كان ناقص من هنا، وده اللي كان بيمنع
    // حفظ الخصم على أي قاعدة بيانات قديمة (جهاز كاشير) اتعملت قبل
    // ما عمود discount يتضاف لـ _onCreate
    if (!columns.any((c) => c['name'] == 'discount')) {
      await db.execute(
        'ALTER TABLE debt_payments ADD COLUMN discount REAL DEFAULT 0',
      );
      print('✅ Added column discount to debt_payments');
    }
  }

  static Future<void> addDrinkIdColumnToDebtItems() async {
    final db = await database;
    final columns = await db.rawQuery("PRAGMA table_info(debt_items)");
    if (!columns.any((c) => c['name'] == 'drink_id')) {
      await db.execute('ALTER TABLE debt_items ADD COLUMN drink_id INTEGER');
      print('✅ Added column drink_id to debt_items');
    }
  }
  // ---------- 3) دوال مساعدة داخلية لإرجاع/خصم المخزون ----------

  /// بيحاول ياخد drink_id من العنصر نفسه، ولو مش موجود (بيانات قديمة)
  /// بيدوّر عليه بالاسم في جدول drinks.
  static Future<int?> _resolveDrinkId(Map<String, dynamic> item) async {
    if (item['drink_id'] != null) return item['drink_id'] as int;
    final name = item['drink_name'] as String?;
    if (name == null || name.trim().isEmpty) return null;
    final db = await database;
    final rows = await db.query(
      'drinks',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
  }

  /// إرجاع كمية لصنف واحد للمخزون (drinks.qty) + الخامات المرتبطة بالوصفة.
  static Future<void> _restoreStockForItem(int? drinkId, int qty) async {
    if (drinkId == null || qty <= 0) return;
    final db = await database;

    final rows = await db.query(
      'drinks',
      where: 'id = ?',
      whereArgs: [drinkId],
    );
    if (rows.isNotEmpty) {
      final current = (rows.first['qty'] as num?)?.toInt() ?? 0;
      await db.update(
        'drinks',
        {'qty': current + qty},
        where: 'id = ?',
        whereArgs: [drinkId],
      );
    }

    await restoreRecipe(drinkId, qty);
  }

  /// خصم كمية من المخزون (drinks.qty) + الخامات المرتبطة بالوصفة.
  static Future<void> _consumeStockForItem(int drinkId, int qty) async {
    if (qty <= 0) return;
    final db = await database;

    final rows = await db.query(
      'drinks',
      where: 'id = ?',
      whereArgs: [drinkId],
    );
    if (rows.isNotEmpty) {
      final current = (rows.first['qty'] as num?)?.toInt() ?? 0;
      await db.update(
        'drinks',
        {'qty': current - qty},
        where: 'id = ?',
        whereArgs: [drinkId],
      );
    }

    await consumeRecipe(drinkId, qty);
  }

  static Future<void> _recalculateDebtTotal(int debtId) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT SUM(total) as s FROM debt_items WHERE debt_id = ?',
      [debtId],
    );
    final total = (res.first['s'] as num?)?.toDouble() ?? 0.0;
    await db.update(
      'debts',
      {'total_amount': total},
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  // ---------- 4) تعديل دين قائم ----------
  /// بيتأكد إن مخزون الصنف نفسه (drinks.qty) كفاية للكمية المطلوبة
  static Future<bool> _hasEnoughDrinkStock(int drinkId, int qty) async {
    final db = await database;
    final rows = await db.query(
      'drinks',
      where: 'id = ?',
      whereArgs: [drinkId],
    );
    if (rows.isEmpty) return false;
    final current = (rows.first['qty'] as num?)?.toInt() ?? 0;
    return current >= qty;
  }

  /// بيزامن جدول invoices مع الدين بعد أي تعديل (إضافة/حذف/تعديل كمية)
  static Future<void> _syncInvoiceFromDebt(int debtId) async {
    final db = await database;
    final debtRows = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
    if (debtRows.isEmpty) return;
    final debt = debtRows.first;

    final invoiceId = debt['invoice_id'] as int?;
    if (invoiceId == null) return;

    await _syncInvoiceItemsFromDebt(debtId);

    final invoiceRows = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
    if (invoiceRows.isEmpty) return;

    final newTotal = (debt['total_amount'] as num?)?.toDouble() ?? 0.0;

    final debtItems = await db.query(
      'debt_items',
      where: 'debt_id = ?',
      whereArgs: [debtId],
    );

    double drinksOnlyTotal = 0.0;
    double cigarettesTotal = 0.0;
    double shishaTotal = 0.0;
    double productsTotal = 0.0;

    for (final item in debtItems) {
      final name = (item['drink_name'] ?? '').toString();
      if (name == 'خصم' || name == 'دفعة مقدمة') continue;
      if (name.startsWith('Playstation')) continue;

      final total = (item['total'] as num?)?.toDouble() ?? 0.0;

      // 🆕 نجيب نوع الصنف (temperature) عشان نحدد نضيفه فين
      String? temperature;
      final drinkId = item['drink_id'] as int?;
      if (drinkId != null) {
        final drinkRows = await db.query(
          'drinks',
          where: 'id = ?',
          whereArgs: [drinkId],
          limit: 1,
        );
        if (drinkRows.isNotEmpty) {
          temperature = drinkRows.first['temperature'] as String?;
        }
      }
      // fallback بالاسم لو مفيش drink_id (بيانات قديمة)
      if (temperature == null && name.isNotEmpty) {
        final drinkRows = await db.query(
          'drinks',
          where: 'name = ?',
          whereArgs: [name],
          limit: 1,
        );
        if (drinkRows.isNotEmpty) {
          temperature = drinkRows.first['temperature'] as String?;
        }
      }

      switch (temperature) {
        case 'cigarette':
          cigarettesTotal += total;
          break;
        case 'shisha':
          shishaTotal += total;
          break;
        case 'prodect':
          productsTotal += total;
          break;
        default:
          // hot / cold / normal / null (غير معروف) → بتتحسب مشروبات
          drinksOnlyTotal += total;
      }
    }

    await db.update(
      'invoices',
      {
        'drinks_cost': drinksOnlyTotal,
        'cigarettes_cost': cigarettesTotal,
        'shisha_cost': shishaTotal,
        'products_cost': productsTotal,
        'total_cost': newTotal.clamp(0, double.infinity).toDouble(),
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  static Future<bool> updateDebtItemQty({
    required int debtId,
    required int debtItemId,
    required int newQty,
    required String changedBy,
  }) async {
    final db = await database;
    final rows = await db.query(
      'debt_items',
      where: 'id = ?',
      whereArgs: [debtItemId],
    );
    if (rows.isEmpty) return false;

    final item = rows.first;
    final oldQty = (item['qty'] as num?)?.toInt() ?? 0;
    final itemName = (item['drink_name'] ?? 'صنف'.tr()).toString();
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final drinkId = await _resolveDrinkId(item);
    final diff = newQty - oldQty;

    if (diff > 0) {
      if (drinkId == null) return false;
      final hasStock = await _hasEnoughDrinkStock(drinkId, diff);
      final canMakeRecipe = await canConsumeRecipe(drinkId, diff);
      if (!hasStock || !canMakeRecipe) return false;
      await _consumeStockForItem(drinkId, diff);
    } else if (diff < 0) {
      await _restoreStockForItem(drinkId, -diff);
    }

    if (newQty <= 0) {
      await db.delete('debt_items', where: 'id = ?', whereArgs: [debtItemId]);
    } else {
      await db.update(
        'debt_items',
        {'qty': newQty, 'total': price * newQty},
        where: 'id = ?',
        whereArgs: [debtItemId],
      );
    }

    await _recalculateDebtTotal(debtId);
    await _syncInvoiceFromDebt(debtId); // 🆕
    // 🆕 بعد نجاح التحديث، سجّل التغيير
    final debtRow =
        (await db.query('debts', where: 'id = ?', whereArgs: [debtId])).first;
    await logInvoiceChange(
      invoiceId: debtRow['invoice_id'] as int?,
      customerName: (debtRow['customer_name'] ?? '').toString(),
      action: 'تعديل كمية'.tr(),
      details: '{itemName}: من {oldQty} إلى {newQty}'.tr({
        'itemName': itemName,
        'oldQty': oldQty,
        'newQty': newQty,
      }),
      changedBy: changedBy,
    );
    return true;
  }

  static Future<void> deleteDebtItem({
    required int debtId,
    required int debtItemId,
    required String changedBy,
  }) async {
    final db = await database;
    final rows = await db.query(
      'debt_items',
      where: 'id = ?',
      whereArgs: [debtItemId],
    );

    String itemName = 'صنف'.tr();
    int qty = 0;

    if (rows.isNotEmpty) {
      final item = rows.first;
      qty = (item['qty'] as num?)?.toInt() ?? 0;
      itemName = (item['drink_name'] ?? 'صنف'.tr()).toString();
      final drinkId = await _resolveDrinkId(item);
      await _restoreStockForItem(drinkId, qty);
    }

    await db.delete('debt_items', where: 'id = ?', whereArgs: [debtItemId]);
    await _recalculateDebtTotal(debtId);
    await _syncInvoiceFromDebt(debtId); // 🆕

    // 🆕 سجّل التغيير — هات بيانات الدين عشان invoice_id واسم العميل
    final debtRows = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
    final invoiceId =
        debtRows.isNotEmpty ? debtRows.first['invoice_id'] as int? : null;
    final customerName =
        debtRows.isNotEmpty
            ? (debtRows.first['customer_name'] ?? '').toString()
            : '';

    await logInvoiceChange(
      invoiceId: invoiceId,
      customerName: customerName,
      action: 'حذف صنف'.tr(),
      details: '$itemName ×$qty',
      changedBy: changedBy,
    );
  }

  static Future<bool> addItemToDebt({
    required int debtId,
    required int drinkId,
    required String drinkName,
    required int qty,
    required double price,
    required String changedBy, // 🆕
  }) async {
    final hasStock = await _hasEnoughDrinkStock(drinkId, qty);
    final canMake = await canConsumeRecipe(drinkId, qty);
    if (!hasStock || !canMake) return false;

    final db = await database;
    await db.insert('debt_items', {
      'debt_id': debtId,
      'drink_id': drinkId,
      'drink_name': drinkName,
      'qty': qty,
      'price': price,
      'total': price * qty,
    });

    await _consumeStockForItem(drinkId, qty);
    await _recalculateDebtTotal(debtId);
    await _syncInvoiceFromDebt(debtId); // 🆕

    // 🆕 سجّل التغيير
    final debtRows = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
    final invoiceId =
        debtRows.isNotEmpty ? debtRows.first['invoice_id'] as int? : null;
    final customerName =
        debtRows.isNotEmpty
            ? (debtRows.first['customer_name'] ?? '').toString()
            : '';

    await logInvoiceChange(
      invoiceId: invoiceId,
      customerName: customerName,
      action: 'إضافة صنف'.tr(),
      details: '$drinkName ×$qty',
      changedBy: changedBy,
    );

    return true;
  }

  /// تعديل اسم العميل بتاع الدين.
  static Future<void> updateDebtCustomerName(int debtId, String name) async {
    final db = await database;
    await db.update(
      'debts',
      {'customer_name': name},
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  /// تعديل كمية صنف داخل دين — بيستهلك/يرجّع الفرق من المخزون تلقائيًا.
  /// لو newQty <= 0 بيمسح الصنف بالكامل ويرجّع كميته للمخزون.
  /// بيرجع false لو المخزون/الخامات مش كافية للزيادة المطلوبة.

  // ---------- 5) إلغاء دين/فاتورة آجلة بالكامل ----------

  /// إلغاء دين بالكامل (له صف في جدول debts):
  /// - بيرجّع مخزون كل الأصناف المسجلة فيه.
  /// - بيحوّل الفاتورة المرتبطة (لو موجودة) لحالة "ملغي" عشان متتحسبش فلوس.
  /// - بيمسح debt_payments و debt_items و debts نفسها.
  ///
  /// ⚠️ لو كان فيه تحصيل جزئي سابق (debt_payments)، الدالة دي مش بترجعه —
  /// المفروض تتأكد من الكاشير قبل ما تنادي الدالة دي (اعرضله المبلغ المحصّل).
  static Future<void> cancelDebt(int debtId) async {
    final db = await database;

    final debtRows = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
    if (debtRows.isEmpty) return;
    final debt = debtRows.first;

    final items = await db.query(
      'debt_items',
      where: 'debt_id = ?',
      whereArgs: [debtId],
    );
    for (final item in items) {
      final qty = (item['qty'] as num?)?.toInt() ?? 0;
      final drinkId = await _resolveDrinkId(item);
      await _restoreStockForItem(drinkId, qty);
    }

    // 🆕 حساب أي مبلغ اتحصّل فعليًا (من debt_payments) قبل الحذف
    final payments = await db.query(
      'debt_payments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
    );
    final collected = payments.fold<double>(
      0.0,
      (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0),
    );

    final invoiceId = debt['invoice_id'] as int?;
    if (invoiceId != null) {
      await db.update(
        'invoices',
        {'payment_type': 'ملغي'},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
    }

    // 🆕 خصم المبلغ المحصّل من درج الكاش (استرداد للعميل)
    if (collected > 0) {
      await db.insert('cash_drawer', {
        'amount': collected,
        'type': 'expense',
        'source': 'debt_cancel_refund',
        'invoice_id': invoiceId,
        'date': DateTime.now().toIso8601String(),
      });
    }

    await db.delete('debt_payments', where: 'debt_id = ?', whereArgs: [debtId]);
    await db.delete('debt_items', where: 'debt_id = ?', whereArgs: [debtId]);
    await db.delete('debts', where: 'id = ?', whereArgs: [debtId]);
  }

  static Future<void> cancelDebtInvoiceDirect(int invoiceId) async {
    final db = await database;

    final items = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );

    for (final item in items) {
      final drinkId = item['drink_id'] as int?;
      final qty = (item['qty'] as num?)?.toInt() ?? 0;
      if (drinkId != null) {
        await _restoreStockForItem(drinkId, qty);
      }
    }

    // 🆕 استرداد أي دفعة جزئية اتحصّلت قبل الإلغاء
    final collected = await getPartialPaymentsTotal(invoiceId);
    if (collected > 0) {
      await db.insert('cash_drawer', {
        'amount': collected,
        'type': 'expense',
        'source': 'invoice_cancel_refund',
        'invoice_id': invoiceId,
        'date': DateTime.now().toIso8601String(),
      });
    }

    await db.update(
      'invoices',
      {'payment_type': 'ملغي'},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  /// إلغاء فاتورة "علي الحساب" مباشرة لما مفيش صف مقابل ليها في جدول debts
  /// (يعني الأصناف موجودة في invoice_items بس).
  /// بيرجّع مخزون كل الأصناف وبيحوّل الفاتورة لحالة "ملغي".

  static Future<int> addPartialPayment({
    required int invoiceId,
    required double amount,
    required int shiftId,
    String? cashier,
  }) async {
    final db = await database;
    return await db.insert('cash_drawer', {
      'amount': amount,
      'type': 'income',
      'source': 'partial_payment',
      'invoice_id': invoiceId,
      'shift_id': shiftId,
      'cashier': cashier,
      'date': DateTime.now().toIso8601String(),
    });
  }

  static Future<double> getPartialPaymentsTotal(int invoiceId) async {
    final db = await database;
    final res = await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as s FROM cash_drawer WHERE invoice_id = ? AND source = 'partial_payment'",
      [invoiceId],
    );
    return (res.first['s'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<List<Map<String, dynamic>>> getPartialPayments(
    int invoiceId,
  ) async {
    final db = await database;
    return await db.query(
      'cash_drawer',
      where: 'invoice_id = ? AND source = ?',
      whereArgs: [invoiceId, 'partial_payment'],
      orderBy: 'date ASC',
    );
  }

  /// 💰 الدفعات الجزئية (تحصيل فاتورة مفتوحة) اللي اتحصّلت خلال شيفت
  /// معيّن. الفاتورة نفسها ممكن تكون اتحوّلت لشيفت تاني بتسليم شيفت،
  /// لكن الفلوس بتفضل محسوبة على الشيفت اللي اتحصّلت فيه فعلاً.
  /// بنشمل الدفعات اللي اتحوّلت لدين كمان (partial_payment_migrated)
  /// لأن التحويل بيتم وقت تسجيل الدين — بعد ما الفلوس دخلت الشيفت.
  static Future<List<Map<String, dynamic>>> getShiftPartialPayments(
    int shiftId,
  ) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT cd.*, i.customer_name
      FROM cash_drawer cd
      LEFT JOIN invoices i ON i.id = cd.invoice_id
      WHERE cd.source IN ('partial_payment', 'partial_payment_migrated')
        AND cd.shift_id = ?
      ORDER BY cd.date ASC
    ''', [shiftId]);
  }

  /// 💰 إجمالي الدفعات الجزئية لكل فاتورة — من أي شيفت.
  /// تقفيل الشيفت اللي استلم الفاتورة بيخصم اللي اتحصّل قبل كده عشان
  /// الفلوس ما تتحسبش مرتين على شيفتين. [excludeShiftId] بيستثني دفعات
  /// الشيفت اللي بنعمله تقفيله دلوقتي (دي بتتحسب في نفس الشيفت).
  static Future<Map<int, double>> getPartialsByInvoice({
    List<int>? invoiceIds,
    int? excludeShiftId,
  }) async {
    final db = await database;
    final conditions = <String>[
      "source = 'partial_payment'",
      'invoice_id IS NOT NULL',
    ];
    final args = <Object?>[];
    if (excludeShiftId != null) {
      conditions.add('(shift_id IS NULL OR shift_id != ?)');
      args.add(excludeShiftId);
    }
    if (invoiceIds != null && invoiceIds.isNotEmpty) {
      final placeholders = List.filled(invoiceIds.length, '?').join(', ');
      conditions.add('invoice_id IN ($placeholders)');
      args.addAll(invoiceIds);
    }
    final rows = await db.rawQuery(
      '''
      SELECT invoice_id, SUM(amount) AS total
      FROM cash_drawer
      WHERE ${conditions.join(' AND ')}
      GROUP BY invoice_id
      ''',
      args,
    );
    final result = <int, double>{};
    for (final row in rows) {
      final id = row['invoice_id'];
      if (id == null) continue;
      result[(id as num).toInt()] =
          (row['total'] as num?)?.toDouble() ?? 0.0;
    }
    return result;
  }

  static Future<void> migratePartialPaymentsToDebt({
    required int invoiceId,
    required int debtId,
    required String customerName,
  }) async {
    final db = await database;

    final partials = await db.query(
      'cash_drawer',
      where: 'invoice_id = ? AND source = ?',
      whereArgs: [invoiceId, 'partial_payment'],
    );

    for (final p in partials) {
      await db.insert('debt_payments', {
        'debt_id': debtId,
        'amount': (p['amount'] as num?)?.toDouble() ?? 0.0,
        'paid_at': p['date'],
        'discount': 0,
        'customer_name': customerName,
        'invoice_id': invoiceId,
      });
    }

    // 🆕 نغيّر الـ source عشان متتحسبش تاني كـ "دفعة جزئية لترابيزة مفتوحة"
    await db.update(
      'cash_drawer',
      {'source': 'partial_payment_migrated'},
      where: 'invoice_id = ? AND source = ?',
      whereArgs: [invoiceId, 'partial_payment'],
    );
  }

  // 🆕 يعيد بناء بنود invoice_items (نوع drink فقط) من debt_items الحالية
  static Future<void> _syncInvoiceItemsFromDebt(int debtId) async {
    final db = await database;
    final debtRows = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
    if (debtRows.isEmpty) return;
    final invoiceId = debtRows.first['invoice_id'] as int?;
    if (invoiceId == null) return;

    final debtItems = await db.query(
      'debt_items',
      where: 'debt_id = ?',
      whereArgs: [debtId],
    );

    // 🆕 لو فيه أي صنف قابل للمزامنة أصلاً، نكمل. لو القائمة فاضية بالكامل
    // بسبب مشكلة قراءة، منمسحش الموجود عشان ما نضيعش البيانات.
    await db.transaction((txn) async {
      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ? AND item_type = ?',
        whereArgs: [invoiceId, 'drink'],
      );

      for (final item in debtItems) {
        var drinkId = item['drink_id'] as int?;
        final name = (item['drink_name'] ?? '').toString();

        // لو مفيش drink_id، حاول تدور بالاسم
        if (drinkId == null && name.isNotEmpty) {
          final rows = await txn.query(
            'drinks',
            where: 'name = ?',
            whereArgs: [name],
            limit: 1,
          );
          if (rows.isNotEmpty) drinkId = rows.first['id'] as int?;
        }

        final qty = (item['qty'] as num?)?.toInt() ?? 0;
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final total = (item['total'] as num?)?.toDouble() ?? (price * qty);

        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'drink_id': drinkId, // ممكن يفضل null لو "خصم"/"دفعة مقدمة" — طبيعي
          'drink_name': name,
          'qty': qty,
          'price': price,
          'total': total,
          'item_type': 'drink',
          'hours': 0,
        });
      }
    });
  }

  static Future<void> fixMaterialQty(int materialId, double correctQty) async {
    final db = await database;
    final old = await db.query(
      'raw_materials',
      where: 'id=?',
      whereArgs: [materialId],
    );
    final oldQty = (old.first['qty'] as num).toDouble();
    final diff = correctQty - oldQty;

    await db.update(
      'raw_materials',
      {'qty': correctQty},
      where: 'id=?',
      whereArgs: [materialId],
    );

    await db.insert('material_transactions', {
      'material_id': materialId,
      'qty': diff.abs(),
      'type': diff > 0 ? 'IN' : 'OUT',
      'notes': 'تصحيح خطأ تراكم عشري',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> cleanupAllMaterialQuantities() async {
    final db = await database;

    final materials = await db.query('raw_materials');

    for (final m in materials) {
      final id = m['id'] as int;
      final qty = (m['qty'] as num).toDouble();

      // أي رقم قريب من الصفر (زي e-13) بيتحول لصفر بالظبط
      // أي رقم تاني بيتقرب لـ 4 خانات عشرية
      final fixed =
          qty.abs() < 0.0001 ? 0.0 : double.parse(qty.toStringAsFixed(4));

      if (fixed != qty) {
        await db.update(
          'raw_materials',
          {'qty': fixed},
          where: 'id=?',
          whereArgs: [id],
        );
        print('✅ تم تصحيح $id من $qty إلى $fixed');
      }
    }
  }

  static Future<void> ensureAuditLogTable() async {
    final db = await database;
    await db.execute('''
  CREATE TABLE IF NOT EXISTS audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id INTEGER,
    customer_name TEXT,
    action TEXT,
    details TEXT,
    changed_by TEXT,
    changed_at TEXT
  )
  ''');
  }

  static Future<void> logInvoiceChange({
    int? invoiceId,
    String? customerName,
    required String
    action, // مثلاً: "تعديل كمية"، "حذف صنف"، "إضافة صنف"، "خصم"
    required String details, // نص واضح للتغيير: "شاي: من 2 إلى 3"
    required String changedBy, // اسم الكاشير
  }) async {
    final db = await database;
    await db.insert('audit_log', {
      'invoice_id': invoiceId,
      'customer_name': customerName,
      'action': action,
      'details': details,
      'changed_by': changedBy,
      'changed_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getAuditLog({
    int? invoiceId,
  }) async {
    final db = await database;
    if (invoiceId != null) {
      return await db.query(
        'audit_log',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
        orderBy: 'changed_at DESC',
      );
    }
    return await db.query('audit_log', orderBy: 'changed_at DESC');
  }

  static Future<void> ensureVodafoneCashTable() async {
    final db = await database;
    await db.execute('''
  CREATE TABLE IF NOT EXISTS vodafone_cash_notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shift_id INTEGER,
    amount REAL,
    note TEXT,
    added_by TEXT,
    created_at TEXT
  )
  ''');
  }

  static Future<int> addVodafoneCashNote({
    required int shiftId,
    required double amount,
    String? note,
    required String addedBy,
  }) async {
    final db = await database;
    return await db.insert('vodafone_cash_notes', {
      'shift_id': shiftId,
      'amount': double.parse(amount.toStringAsFixed(2)), // تقريب فلوس
      'note': note ?? '',
      'added_by': addedBy,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getVodafoneCashNotes(
    int shiftId,
  ) async {
    final db = await database;
    return await db.query(
      'vodafone_cash_notes',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<double> getVodafoneCashTotal(int shiftId) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) as s FROM vodafone_cash_notes WHERE shift_id = ?',
      [shiftId],
    );
    return (res.first['s'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<void> closeDB() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  static Future<void> ensureOrdersTables() async {
    final db = await database;
    await db.execute('''
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      table_id INTEGER NOT NULL,
      table_name TEXT NOT NULL,
      status TEXT DEFAULT 'pending',
      created_at TEXT NOT NULL,
      shift_id INTEGER,
      invoice_id INTEGER,
      note TEXT
    )
  ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL,
      drink_id INTEGER NOT NULL,
      drink_name TEXT NOT NULL,
      qty INTEGER NOT NULL,
      price REAL NOT NULL,
      total REAL NOT NULL,
      FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE
    )
  ''');
  }

  // ===================== عدد الطلبات الجديدة (للبادج) =====================
  static Future<int> getPendingOrdersCount() async {
    final db = await DBHelper.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM orders WHERE status = 'pending'",
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  ///////////////////////////////////////////////
}
