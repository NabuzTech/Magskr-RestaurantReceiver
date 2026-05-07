import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/get_product_category_list_response_model.dart';
import '../models/get_store_postcode_response_model.dart';
import '../models/get_store_products_response_model.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    // ✅ Initialize for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // ✅ Desktop path
      var databasesPath = await databaseFactory.getDatabasesPath();
      path = join(databasesPath, 'food_app.db');
    } else {
      // ✅ Mobile path
      path = join(await getDatabasesPath(), 'food_app.db');
    }

    return await openDatabase(
      path,
      version: 11,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Stores table
    await db.execute('''
    CREATE TABLE stores(
      id TEXT PRIMARY KEY,
      name TEXT,
      lastUpdated INTEGER
    )
  ''');

    // Categories table
    await db.execute('''
    CREATE TABLE categories(
      id TEXT PRIMARY KEY,
      name TEXT,
      imageUrl TEXT,
      storeId TEXT,
      displayOrder INTEGER,
      lastUpdated INTEGER
    )
  ''');

    // Products table
    await db.execute('''
    CREATE TABLE products(
      id TEXT PRIMARY KEY,
      name TEXT,
      price REAL,
      categoryId TEXT,
      imageUrl TEXT,
      description TEXT,
      isActive INTEGER,
      isSpicy INTEGER,
      isVeg INTEGER,
      storeId TEXT,
      lastUpdated INTEGER
    )
  ''');

    // ✅ NEW: Product Variants table
    await db.execute('''
    CREATE TABLE product_variants(
      id TEXT PRIMARY KEY,
      product_id TEXT,
      name TEXT,
      price REAL,
      item_code TEXT,
      description TEXT,
      FOREIGN KEY (product_id) REFERENCES products(id)
    )
  ''');

    await db.execute('''
  CREATE TABLE order_item_toppings(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_item_id INTEGER,
    topping_id INTEGER,  -- ✅ Add topping_id column
    topping_name TEXT,
    topping_price REAL,
    topping_quantity INTEGER,
    FOREIGN KEY (order_item_id) REFERENCES order_items(id)
  )
''');

    await db.execute('''
  CREATE TABLE variant_topping_groups(
    id TEXT PRIMARY KEY,
    variant_id TEXT,
    name TEXT,
    min_select INTEGER,
    max_select INTEGER,
    is_required INTEGER,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id)
  )
''');

    await db.execute('''
  CREATE TABLE variant_toppings(
    id TEXT PRIMARY KEY,
    topping_group_id TEXT,
    name TEXT,
    description TEXT,
    price REAL,
    store_id TEXT,
    is_active INTEGER,
    FOREIGN KEY (topping_group_id) REFERENCES variant_topping_groups(id)
  )
''');
    // Orders table
    await db.execute('''
    CREATE TABLE orders(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      client_uuid TEXT,
      discount_id TEXT,
      note TEXT,
      order_type INTEGER,
      order_status INTEGER,
      approval_status INTEGER,
      delivery_time TEXT,
      store_id TEXT,
      isActive INTEGER,
      email TEXT,
      captcha_token TEXT,
      created_at INTEGER,
      synced INTEGER DEFAULT 0
    )
  ''');

    // Order Shipping Address table
    await db.execute('''
    CREATE TABLE order_shipping_address(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER,
      type TEXT,
      line1 TEXT,
      city TEXT,
      zip TEXT,
      country TEXT,
      phone TEXT,
      customer_name TEXT,
      FOREIGN KEY (order_id) REFERENCES orders(id)
    )
  ''');

    // Order Items table
    await db.execute('''
    CREATE TABLE order_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER,
      note TEXT,
      product_id INTEGER,
      quantity INTEGER,
      unit_price REAL,
      variant_id INTEGER,
      FOREIGN KEY (order_id) REFERENCES orders(id)
    )
  ''');

    // Order Payment table
    await db.execute('''
    CREATE TABLE order_payment(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER,
      payment_method TEXT,
      status TEXT,
      paid_at TEXT,
      amount REAL,
      FOREIGN KEY (order_id) REFERENCES orders(id)
    )
  ''');

    await db.execute('''
  CREATE TABLE postcodes(
    id TEXT PRIMARY KEY,
    postcode TEXT,
    delivery_time INTEGER,
    store_id TEXT,
    last_updated INTEGER
  )
''');

    await db.execute('''
  CREATE TABLE store_timings(
    id TEXT PRIMARY KEY,
    day_of_week INTEGER,
    opening_time TEXT,
    closing_time TEXT,
    store_id TEXT,
    name TEXT,
    last_updated INTEGER
  )
''');

  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id TEXT PRIMARY KEY,
        name TEXT,
        imageUrl TEXT,
        storeId TEXT,
        displayOrder INTEGER,
        lastUpdated INTEGER
      )
    ''');

      await db.execute('''
      CREATE TABLE IF NOT EXISTS products(
        id TEXT PRIMARY KEY,
        name TEXT,
        price REAL,
        categoryId TEXT,
        imageUrl TEXT,
        description TEXT,
        isActive INTEGER,
        isSpicy INTEGER,
        isVeg INTEGER,
        storeId TEXT,
        lastUpdated INTEGER
      )
    ''');
    }

    if (oldVersion < 3) {
      try {
        var tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='products'");

        if (tables.isNotEmpty) {
          await db.execute('''
          CREATE TABLE products_new(
            id TEXT PRIMARY KEY,
            name TEXT,
            price REAL,
            categoryId TEXT,
            imageUrl TEXT,
            description TEXT,
            isActive INTEGER,
            isSpicy INTEGER,
            isVeg INTEGER,
            storeId TEXT,
            lastUpdated INTEGER
          )
        ''');

          await db.execute('''
          INSERT INTO products_new 
          SELECT id, name, CAST(price AS REAL), categoryId, imageUrl, 
                 description, isActive, isSpicy, isVeg, storeId, lastUpdated
          FROM products
        ''');

          await db.execute('DROP TABLE products');
          await db.execute('ALTER TABLE products_new RENAME TO products');
          print('✅ Products table migrated to use REAL for price');
        }
      } catch (e) {
        print('⚠️ Error migrating products table: $e');
        await db.execute('''
        CREATE TABLE IF NOT EXISTS products(
          id TEXT PRIMARY KEY,
          name TEXT,
          price REAL,
          categoryId TEXT,
          imageUrl TEXT,
          description TEXT,
          isActive INTEGER,
          isSpicy INTEGER,
          isVeg INTEGER,
          storeId TEXT,
          lastUpdated INTEGER
        )
      ''');
      }
    }

    if (oldVersion < 4) {
      try {
        var columns = await db.rawQuery('PRAGMA table_info(categories)');
        bool hasDisplayOrder =
            columns.any((col) => col['name'] == 'displayOrder');

        if (!hasDisplayOrder) {
          await db.execute(
              'ALTER TABLE categories ADD COLUMN displayOrder INTEGER DEFAULT 0');
          print('✅ Added displayOrder column to categories table');
        }
      } catch (e) {
        print('⚠️ Error adding displayOrder column: $e');
      }
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS orders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          discount_id TEXT,
          note TEXT,
          order_type INTEGER,
          order_status INTEGER,
          approval_status INTEGER,
          delivery_time TEXT,
          store_id TEXT,
          isActive INTEGER,
          email TEXT,
          captcha_token TEXT,
          created_at INTEGER,
          synced INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS order_shipping_address(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER,
          type TEXT,
          line1 TEXT,
          city TEXT,
          zip TEXT,
          country TEXT,
          phone TEXT,
          customer_name TEXT,
          FOREIGN KEY (order_id) REFERENCES orders(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS order_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER,
          note TEXT,
          product_id INTEGER,
          quantity INTEGER,
          unit_price REAL,
          variant_id INTEGER,
          FOREIGN KEY (order_id) REFERENCES orders(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS order_payment(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER,
          payment_method TEXT,
          status TEXT,
          paid_at TEXT,
          amount REAL,
          FOREIGN KEY (order_id) REFERENCES orders(id)
        )
      ''');

      print('✅ Order tables created');
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_variants(
          id TEXT PRIMARY KEY,
          product_id TEXT,
          name TEXT,
          price REAL,
          item_code TEXT,
          description TEXT,
          FOREIGN KEY (product_id) REFERENCES products(id)
        )
      ''');
      print('✅ Product variants table created');
    }

    if (oldVersion < 7) {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS variant_topping_groups(
      id TEXT PRIMARY KEY,
      variant_id TEXT,
      name TEXT,
      min_select INTEGER,
      max_select INTEGER,
      is_required INTEGER,
      FOREIGN KEY (variant_id) REFERENCES product_variants(id)
    )
  ''');

      await db.execute('''
    CREATE TABLE IF NOT EXISTS variant_toppings(
      id TEXT PRIMARY KEY,
      topping_group_id TEXT,
      name TEXT,
      description TEXT,
      price REAL,
      store_id TEXT,
      is_active INTEGER,
      FOREIGN KEY (topping_group_id) REFERENCES variant_topping_groups(id)
    )
  ''');
      print('✅ Variant topping tables created');
    }

    if (oldVersion < 8) {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS order_item_toppings(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_item_id INTEGER,
      topping_name TEXT,
      topping_price REAL,
      topping_quantity INTEGER,
      FOREIGN KEY (order_item_id) REFERENCES order_items(id)
    )
  ''');
      print('✅ Order item toppings table created');
    }

    if (oldVersion < 9) {
      await db.execute('ALTER TABLE orders ADD COLUMN client_uuid TEXT');
    }

    if (oldVersion < 10) {
      // Add topping_id column to order_item_toppings
      await db.execute(
          'ALTER TABLE order_item_toppings ADD COLUMN topping_id INTEGER DEFAULT 0');
      print('✅ Added topping_id column to order_item_toppings');
    }

    if (oldVersion < 11) {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS store_timings(
      id TEXT PRIMARY KEY,
      day_of_week INTEGER,
      opening_time TEXT,
      closing_time TEXT,
      store_id TEXT,
      name TEXT,
      last_updated INTEGER
    )
  ''');
    }
  }

  // ==================== STORE METHODS ====================

  Future<void> saveStore(String storeId, String storeName) async {
    final db = await database;
    await db.insert(
      'stores',
      {
        'id': storeId,
        'name': storeName,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getStoreName(String storeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      where: 'id = ?',
      whereArgs: [storeId],
    );

    if (maps.isEmpty) return null;
    return maps.first['name'] as String?;
  }

  Future<void> deleteStore(String storeId) async {
    final db = await database;
    await db.delete('stores', where: 'id = ?', whereArgs: [storeId]);
  }

  Future<void> clearAllStores() async {
    final db = await database;
    await db.delete('stores');
  }

  Future<void> savePostcodes(List<GetStorePostCodesResponseModel> postcodes, String storeId) async {
    final db = await database;
    final batch = db.batch();

    for (var postcode in postcodes) {
      batch.insert(
        'postcodes',
        {
          'id': postcode.id.toString(),
          'postcode': postcode.postcode ?? '',
          'delivery_time': postcode.deliveryTime ?? 0,
          'store_id': storeId,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    print('✅ Saved ${postcodes.length} postcodes to database');
  }

  Future<List<GetStorePostCodesResponseModel>> getPostcodes(String storeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'postcodes',
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'postcode ASC',
    );

    return maps.map((map) {
      return GetStorePostCodesResponseModel(
        id: int.tryParse(map['id']?.toString() ?? '0'),
        postcode: map['postcode'] as String?,
        deliveryTime: map['delivery_time'] as int?,
      );
    }).toList();
  }


  // ==================== CATEGORY METHODS ====================

  Future<void> saveCategories(
      List<GetProductCategoryList> categories, String storeId) async
  {
    final db = await database;
    final batch = db.batch();

    for (int i = 0; i < categories.length; i++) {
      var category = categories[i];
      batch.insert(
        'categories',
        {
          'id': category.id.toString(),
          'name': category.name ?? '',
          'imageUrl': category.imageUrl ?? '',
          'storeId': storeId,
          'displayOrder': i,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    print('✅ Saved ${categories.length} categories to database with order');
  }

  Future<List<GetProductCategoryList>> getCategories(String storeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'storeId = ?',
      whereArgs: [storeId],
      orderBy: 'displayOrder ASC',
    );

    print('📦 Retrieved ${maps.length} categories from database in API order');

    return maps.map((map) {
      return GetProductCategoryList(
        id: int.tryParse(map['id']?.toString() ?? '0'),
        name: map['name'] as String?,
        imageUrl: map['imageUrl'] as String?,
      );
    }).toList();
  }

  // ==================== PRODUCT METHODS ====================
  Future<void> saveProducts(
      List<GetStoreProducts> products, String storeId) async
  {
    final db = await database;
    final batch = db.batch();

    for (var product in products) {
      // Convert price to double for storage
      double? priceValue;
      if (product.price != null) {
        if (product.price is String) {
          priceValue = double.tryParse(product.price.toString());
        } else if (product.price is num) {
          priceValue = (product.price as num).toDouble();
        }
      }

      batch.insert(
        'products',
        {
          'id': product.id.toString(),
          'name': product.name ?? '',
          'price': priceValue ?? 0.0,
          'categoryId': product.categoryId?.toString() ?? '',
          'imageUrl': product.imageUrl ?? '',
          'description': product.description ?? '',
          'isActive': (product.isActive ?? false) ? 1 : 0,
          'isSpicy': 0,
          'isVeg': 0,
          'storeId': storeId,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (product.variants != null && product.variants!.isNotEmpty) {
        for (var variant in product.variants!) {
          // ✅ FIX: Handle price correctly
          double variantPrice = 0.0;
          if (variant.price != null) {
            if (variant.price is double) {
              variantPrice = variant.price as double;
            } else if (variant.price is int) {
              variantPrice = (variant.price as int).toDouble();
            } else if (variant.price is num) {
              variantPrice = (variant.price as num).toDouble();
            }
          }

          print(
              '💾 Saving variant ${variant.id} (${variant.name}) - Price: $variantPrice');

          batch.insert(
            'product_variants',
            {
              'id': variant.id.toString(),
              'product_id': product.id.toString(),
              'name': variant.name ?? '',
              'price': variantPrice,
              'item_code': variant.itemCode ?? '',
              'description': variant.description ?? '',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          if (variant.enrichedToppingGroups != null &&
              variant.enrichedToppingGroups!.isNotEmpty) {
            print(
                '  📦 Variant ${variant.id} has ${variant.enrichedToppingGroups!.length} topping groups');

            for (var group in variant.enrichedToppingGroups!) {
              // ✅ CREATE UNIQUE KEY: variant_id + group_id
              String uniqueGroupId = '${variant.id}_${group.id}';

              print(
                  '    🔹 Saving group $uniqueGroupId (${group.name}) with ${group.toppings?.length ?? 0} toppings');

              batch.insert(
                'variant_topping_groups',
                {
                  'id': uniqueGroupId, // ✅ Use unique key
                  'variant_id': variant.id.toString(),
                  'name': group.name ?? '',
                  'min_select': group.minSelect ?? 0,
                  'max_select': group.maxSelect ?? 0,
                  'is_required': (group.isRequired ?? false) ? 1 : 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              if (group.toppings != null && group.toppings!.isNotEmpty) {
                for (var topping in group.toppings!) {
                  // ✅ CREATE UNIQUE KEY: variant_id + group_id + topping_id
                  String uniqueToppingId =
                      '${variant.id}_${group.id}_${topping.id}';

                  print(
                      '      🍕 Saving topping $uniqueToppingId (${topping.name})');

                  batch.insert(
                    'variant_toppings',
                    {
                      'id': uniqueToppingId, // ✅ Use unique key
                      'topping_group_id':
                          uniqueGroupId, // ✅ Reference unique group key
                      'name': topping.name ?? '',
                      'description': topping.description ?? '',
                      'price': topping.price ?? 0.0,
                      'store_id': topping.storeId.toString(),
                      'is_active': (topping.isActive ?? false) ? 1 : 0,
                    },
                    conflictAlgorithm: ConflictAlgorithm.replace,
                  );
                }
              }
            }
          }
        }
      }
    }
    await batch.commit(noResult: true);
    print('✅ Saved ${products.length} products to database');
  }

  Future<List<GetStoreProducts>> getProducts(String storeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'storeId = ?',
      whereArgs: [storeId],
      orderBy: 'name ASC',
    );

    print('📦 Retrieved ${maps.length} products from database');

    return maps.map((map) {
      double? priceValue;
      if (map['price'] != null) {
        if (map['price'] is double) {
          priceValue = map['price'] as double;
        } else if (map['price'] is int) {
          priceValue = (map['price'] as int).toDouble();
        } else if (map['price'] is String) {
          priceValue = double.tryParse(map['price'] as String);
        }
      }

      return GetStoreProducts(
        id: int.tryParse(map['id']?.toString() ?? '0'),
        name: map['name'] as String?,
        price: priceValue,
        categoryId: int.tryParse(map['categoryId']?.toString() ?? '0'),
        imageUrl: map['imageUrl'] as String?,
        description: map['description'] as String?,
        isActive: map['isActive'] == 1,
      );
    }).toList();
  }

  // ✅ NEW: Get variants for a specific product
  Future<List<Variants>> getProductVariants(String productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'product_variants',
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    print('📦 Retrieved ${maps.length} variants for product $productId');

    return maps.map((map) {
      return Variants(
        id: int.tryParse(map['id']?.toString() ?? '0'),
        name: map['name'] as String?,
        price: (map['price'] as double?)?.toInt(),
        itemCode: map['item_code'] as String?,
        description: map['description'] as String?,
      );
    }).toList();
  }

  Future<List<EnrichedToppingGroups>> getVariantToppingGroups(
      String variantId) async
  {
    final db = await database;

    final groupMaps = await db.query(
      'variant_topping_groups',
      where: 'variant_id = ?',
      whereArgs: [variantId],
    );

    print(
        '📦 Found ${groupMaps.length} topping groups for variant $variantId'); // ADD THIS

    List<EnrichedToppingGroups> groups = [];

    for (var groupMap in groupMaps) {
      final toppingMaps = await db.query(
        'variant_toppings',
        where: 'topping_group_id = ?',
        whereArgs: [groupMap['id']],
      );

      print(
          '🔍 Found ${toppingMaps.length} toppings for group ${groupMap['id']}'); // ADD THIS

      List<Toppings> toppings = toppingMaps.map((map) {
        // Extract the actual topping ID from the composite key
        String compositeId = map['id']?.toString() ?? '';
        int? toppingId;

        // Format is: variant_id_group_id_topping_id
        List<String> parts = compositeId.split('_');
        if (parts.length >= 3) {
          toppingId = int.tryParse(parts[2]); // Get the last part (topping_id)
        }

        return Toppings(
          id: toppingId ?? 0,
          name: map['name'] as String?,
          description: map['description'] as String?,
          price: map['price'] as double?,
          storeId: int.tryParse(map['store_id']?.toString() ?? '0'),
          isActive: map['is_active'] == 1,
        );
      }).toList();

      // Extract group ID from composite key
      String compositeGroupId = groupMap['id']?.toString() ?? '';
      int? groupId;

// Format is: variant_id_group_id
      List<String> groupParts = compositeGroupId.split('_');
      if (groupParts.length >= 2) {
        groupId = int.tryParse(groupParts[1]); // Get the second part (group_id)
      }

      groups.add(EnrichedToppingGroups(
        id: groupId ?? 0,
        name: groupMap['name'] as String?,
        minSelect: groupMap['min_select'] as int?,
        maxSelect: groupMap['max_select'] as int?,
        isRequired: groupMap['is_required'] == 1,
        toppings: toppings,
      ));
    }

    print(
        '✅ Returning ${groups.length} topping groups with toppings'); // ADD THIS
    return groups;
  }

  Future<GetStoreProducts?> getProductById(String productId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final map = maps.first;
      double? priceValue;
      if (map['price'] != null) {
        if (map['price'] is double) {
          priceValue = map['price'] as double;
        } else if (map['price'] is int) {
          priceValue = (map['price'] as int).toDouble();
        } else if (map['price'] is String) {
          priceValue = double.tryParse(map['price'] as String);
        }
      }

      return GetStoreProducts(
        id: int.tryParse(map['id']?.toString() ?? '0'),
        name: map['name'] as String?,
        price: priceValue,
        categoryId: int.tryParse(map['categoryId']?.toString() ?? '0'),
        imageUrl: map['imageUrl'] as String?,
        description: map['description'] as String?,
        isActive: map['isActive'] == 1,
      );
    } catch (e) {
      print('Error getting product by ID: $e');
      return null;
    }
  }

  // ==================== ORDER METHODS ====================
  Future<String> _generateSequentialClientUuid(String storeId) async {
    final db = await database;

    // ✅ Get current count for this store
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE store_id = ?',
        [storeId]
    );

    int orderCount = Sqflite.firstIntValue(result) ?? 0;
    int sequenceNumber = orderCount + 1;

    // ✅ SOLUTION: Use timestamp + store_id for true uniqueness
    DateTime now = DateTime.now();

    // Extract last 4 digits of store_id
    String storeIdSuffix = storeId.length >= 4
        ? storeId.substring(storeId.length - 4)
        : storeId.padLeft(4, '0');

    // Get timestamp components
    String year = now.year.toString().substring(2); // 24
    String month = now.month.toString().padLeft(2, '0'); // 12
    String day = now.day.toString().padLeft(2, '0'); // 19
    String hour = now.hour.toString().padLeft(2, '0'); // 14
    String minute = now.minute.toString().padLeft(2, '0'); // 30
    String second = now.second.toString().padLeft(2, '0'); // 25
    String milli = now.millisecond.toString().padLeft(3, '0'); // 456

    // ✅ Format: 8-4-4-4-12 (total 36 characters with dashes)
    // Part 1 (8): YYMMDD + Seq (2+2+2+2 = 8)
    String part1 = '$year$month$day${sequenceNumber.toString().padLeft(2, '0')}';

    // Part 2 (4): Store ID suffix
    String part2 = storeIdSuffix;

    // Part 3 (4): Hour + Minute
    String part3 = '$hour$minute';

    // Part 4 (4): Second + 2 digits of millisecond
    String part4 = '$second${milli.substring(0, 2)}';

    // Part 5 (12): Millisecond + timestamp micros for extra uniqueness
    String microseconds = now.microsecondsSinceEpoch.toString();
    String part5 = microseconds.substring(microseconds.length - 12);

    String uuid = '$part1-$part2-$part3-$part4-$part5';

    print('✅ Generated unique UUID: $uuid');
    print('   Store ID: $storeId, Sequence: $sequenceNumber');
    print('   Timestamp: ${now.toIso8601String()}');

    return uuid;
  }

  Future<int> saveOrder({
    required String storeId,
    required String orderType,
    required String? note,
    required String customerName,
    required String phone,
    required String email,
    required String address,
    required String? zip,
    required List<Map<String, dynamic>> items,
    required double amount,
    String? discountId,
    DateTime? createdAt,
    String? deliveryTime,
  }) async
  {
    final db = await database;

    // ✅ CHANGED: Use provided Germany time, fallback to Germany time if null
    DateTime orderTime;
    if (createdAt != null) {
      orderTime = createdAt; // ✅ Already Germany time from POS controller
    } else {
      // ✅ Fallback: Calculate Germany time
      DateTime utcNow = DateTime.now().toUtc();
      bool isDST = _isDaylightSavingTimeDb(utcNow);
      int germanyOffset = isDST ? 2 : 1;
      orderTime = utcNow.add(Duration(hours: germanyOffset));
    }

    // ✅ BETTER: Store as UTC milliseconds instead of Germany time
    int timestamp = createdAt!.toUtc().millisecondsSinceEpoch;  // Store UTC

    print('🕐 Saving order as UTC timestamp: $timestamp');
    print('🕐 Original Germany time: $createdAt');

    String clientUuid = await _generateSequentialClientUuid(storeId);
    int orderTypeInt = int.tryParse(orderType) ?? 3;

    int orderId = await db.insert('orders', {
      'client_uuid': clientUuid,
      'discount_id': discountId,
      'note': note ?? '',
      'order_type': orderTypeInt,
      'order_status': 1,
      'approval_status': 1,
      'delivery_time': deliveryTime,
      'store_id': storeId,
      'isActive': 1,
      'email': email.isEmpty ? null : email,
      'captcha_token': '',
      'created_at': timestamp, // ✅ Germany time in milliseconds
      'synced': 0,
    }
    );

    await db.insert('order_shipping_address', {
      'order_id': orderId,
      'type': 'shipping',
      'line1': address,
      'city': '',
      'zip': zip ?? '',
      'country': 'Germany',
      'phone': phone,
      'customer_name': customerName,
    });

    for (var item in items) {

      print('💾 DB SAVE - Item: product_id=${item['product_id']},'
          'variant_id=${item['variant_id']}, qty=${item['quantity']}');

      int itemId = await db.insert('order_items', {
        'order_id': orderId,
        'note': item['note'] ?? '',
        'product_id': item['product_id'],
        'quantity': item['quantity'],
        'unit_price': item['price'],
        'variant_id': item['variant_id'] ?? 0,
      });

      if (item['toppings'] != null && item['toppings'] is List) {
        print('   📝 Saving ${(item['toppings'] as List).length} toppings for item $itemId');

        for (var topping in item['toppings']) {
          print('      🍕 Topping: ${topping['name']} | topping_id=${topping['topping_id']} | price=${topping['price']} | qty=${topping['quantity']}');

          await db.insert('order_item_toppings', {
            'order_item_id': itemId,
            'topping_id': topping['topping_id'] ?? 0,
            'topping_name': topping['name'] ?? '',
            'topping_price': topping['price'] ?? 0.0,
            'topping_quantity': topping['quantity'] ?? 1,
          });
        }
        print('   ✅ Toppings saved for item $itemId');
      }
    }

    await db.insert('order_payment', {
      'order_id': orderId,
      'payment_method': 'cash',
      'status': 'paid',
      'paid_at': orderTime.toIso8601String(), // ✅ Germany time ISO
      'amount': amount,
    });

    print('✅ Order saved with ID: $orderId (Germany time)');
    return orderId;
  }

  bool _isDaylightSavingTimeDb(DateTime dateTime) {
    int year = dateTime.year;

    DateTime marchEnd = DateTime.utc(year, 3, 31);
    while (marchEnd.weekday != DateTime.sunday) {
      marchEnd = marchEnd.subtract(const Duration(days: 1));
    }

    DateTime octoberEnd = DateTime.utc(year, 10, 31);
    while (octoberEnd.weekday != DateTime.sunday) {
      octoberEnd = octoberEnd.subtract(const Duration(days: 1));
    }

    DateTime dstStart = DateTime.utc(year, marchEnd.month, marchEnd.day, 2, 0);
    DateTime dstEnd = DateTime.utc(year, octoberEnd.month, octoberEnd.day, 3, 0);

    return dateTime.isAfter(dstStart) && dateTime.isBefore(dstEnd);
  }


  Future<List<Map<String, dynamic>>> getAllOrders(String storeId) async {
    final db = await database;
    return await db.query(
      'orders',
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    final db = await database;

    final order = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );

    if (order.isEmpty) return null;

    final address = await db.query(
      'order_shipping_address',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    final items = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    List<Map<String, dynamic>> itemsWithToppings = [];
    for (var item in items) {
      final toppings = await db.query(
        'order_item_toppings',
        where: 'order_item_id = ?',
        whereArgs: [item['id']],
      );

      List<Map<String, dynamic>> processedToppings = toppings.map((t) {
        int actualToppingId = t['topping_id'] as int? ?? 0;
        return {
          'id': actualToppingId,
          'topping_id': actualToppingId,
          'topping_name': t['topping_name'],  // ✅ Keep original column name
          'topping_price': t['topping_price'] as double? ?? 0.0,  // ✅ Keep original column name
          'topping_quantity': t['topping_quantity'] as int? ?? 1,  // ✅ Keep original column name
        };
      }).toList();
      print('📦 DB LOAD - Processed ${processedToppings.length} toppings for item ${item['id']}:');
      for (var t in processedToppings) {
        print('   🍕 ${t['topping_name']} | id=${t['topping_id']} | price=${t['topping_price']} | qty=${t['topping_quantity']}');
      }
      Map<String, dynamic> itemWithToppings = Map.from(item);
      itemWithToppings['toppings'] = processedToppings;
      int? variantId = item['variant_id'] as int?;
      if (variantId != null && variantId > 0) {
        final variantData = await db.query(
          'product_variants',
          where: 'id = ?',
          whereArgs: [variantId.toString()],
        );

        if (variantData.isNotEmpty) {
          itemWithToppings['variant'] = {
            'id': int.tryParse(variantData.first['id']?.toString() ?? '0'),
            'name': variantData.first['name'] as String?,
            'price': (variantData.first['price'] as num?)?.toDouble(),
            'item_code': variantData.first['item_code'] as String?,
            'description': variantData.first['description'] as String?,
          };
          print('✅ Loaded variant: ${variantData.first['name']} for item ${item['id']}');
        }
      }
      itemsWithToppings.add(itemWithToppings);
    }

    // ✅ Load payment data
    final payment = await db.query(
      'order_payment',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    return {
      'order': order.first,
      'shipping_address': address.isNotEmpty ? address.first : null,
      'items': itemsWithToppings,
      'payment': payment.isNotEmpty ? payment.first : null,
    };
  }

  Future<List<Map<String, dynamic>>> getUnsyncedOrders(String storeId) async {
    final db = await database;

    // ✅ Add debug log
    final allOrders = await db.query(
      'orders',
      where: 'store_id = ?',
      whereArgs: [storeId],
    );
    print('📊 Total orders in DB: ${allOrders.length}');

    final unsyncedOrders = await db.query(
      'orders',
      where: 'store_id = ? AND synced = 0',  // ✅ Make sure synced column exists
      whereArgs: [storeId],
      orderBy: 'created_at ASC',
    );

    print('📊 Unsynced orders: ${unsyncedOrders.length}');

    return unsyncedOrders;
  }

  Future<void> markOrderAsSynced(int orderId) async {
    final db = await database;

    // ✅ Check current status before update
    final beforeUpdate = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );
    print('🔍 Before update - Order $orderId synced status: ${beforeUpdate.first['synced']}');

    // ✅ Update
    int rowsAffected = await db.update(
      'orders',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [orderId],
    );

    print('✅ Rows affected: $rowsAffected');

    // ✅ Verify after update
    final afterUpdate = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );
    print('✅ After update - Order $orderId synced status: ${afterUpdate.first['synced']}');
  }

  Future<void> deleteOrder(int orderId) async {
    final db = await database;
    await db.delete('order_shipping_address',
        where: 'order_id = ?', whereArgs: [orderId]);
    await db.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    await db
        .delete('order_payment', where: 'order_id = ?', whereArgs: [orderId]);
    await db.delete('orders', where: 'id = ?', whereArgs: [orderId]);
    print('🗑️ Deleted order: $orderId');
  }

  // ==================== UTILITY METHODS ====================

  Future<bool> hasStoredData(String storeId) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'storeId = ?',
      whereArgs: [storeId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> clearStoreData(String storeId) async {
    final db = await database;
    await db.rawDelete('''
      DELETE FROM product_variants 
      WHERE product_id IN (
        SELECT id FROM products WHERE storeId = ?
      )
    ''', [storeId]);

    await db.rawDelete('''
  DELETE FROM variant_toppings 
  WHERE topping_group_id IN (
    SELECT id FROM variant_topping_groups 
    WHERE variant_id IN (
      SELECT id FROM product_variants 
      WHERE product_id IN (
        SELECT id FROM products WHERE storeId = ?
      )
    )
  )
''', [storeId]);

    await db.rawDelete('''
  DELETE FROM variant_topping_groups 
  WHERE variant_id IN (
    SELECT id FROM product_variants 
    WHERE product_id IN (
      SELECT id FROM products WHERE storeId = ?
    )
  )
''', [storeId]);
    await db.delete('categories', where: 'storeId = ?', whereArgs: [storeId]);
    await db.delete('products', where: 'storeId = ?', whereArgs: [storeId]);
    await db.delete('postcodes', where: 'store_id = ?', whereArgs: [storeId]);
    print('🗑️ Cleared all data for store: $storeId');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('product_variants'); // ✅ ADDED
    await db.delete('categories');
    await db.delete('products');
    await db.delete('stores');
    await db.delete('orders');
    await db.delete('order_shipping_address');
    await db.delete('order_items');
    await db.delete('order_payment');
    await db.delete('postcodes');
    print('🗑️ Cleared entire database');
  }

  Future<Map<String, int>> getDataCount(String storeId) async {
    final db = await database;

    final categoryCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM categories WHERE storeId = ?',
            [storeId],
          ),
        ) ??
        0;

    final productCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM products WHERE storeId = ?',
            [storeId],
          ),
        ) ??
        0;

    final orderCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM orders WHERE store_id = ?',
            [storeId],
          ),
        ) ??
        0;

    // ✅ NEW: Get variant count
    final variantCount = Sqflite.firstIntValue(
          await db.rawQuery('''
        SELECT COUNT(*) FROM product_variants 
        WHERE product_id IN (
          SELECT id FROM products WHERE storeId = ?
        )
      ''', [storeId]),
        ) ??
        0;

    return {
      'categories': categoryCount,
      'products': productCount,
      'orders': orderCount,
      'variants': variantCount,
    };
  }
}
