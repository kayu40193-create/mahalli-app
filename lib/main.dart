import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dmlvymwzsmbzfxgqyafx.supabase.co',
    publishableKey: 'sb_publishable_CiJl0yHA-MI24qCo-BKeDg_BNqPt5Na',
  );
   try {
    final products = await Supabase.instance.client
        .from('products')
        .select('id')
        .limit(1);

    debugPrint('نجح الاتصال بـ Supabase! عدد النتائج: ${products.length}');
  } catch (error) {
    debugPrint('فشل اختبار Supabase: $error');
  }


  runApp(const MahalliApp());
}

const Color mahalliGreen = Color(0xFF087F5B);
const Color backgroundColor = Color(0xFFF6F8F7);

class MahalliApp extends StatelessWidget {
  const MahalliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محلّي',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: mahalliGreen),
        scaffoldBackgroundColor: backgroundColor,
        fontFamily: 'Roboto',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    );
  }
}

class Product {
  final String name;
  final String? imageUrl;
  final String category;
  final String store;
  final double price;
  final IconData icon;
  final Color color;

  const Product({
    required this.name,
    this.imageUrl,
    required this.category,
    required this.store,
    required this.price,
    required this.icon,
    required this.color,
  });
}

const List<Product> products = [
  Product(
    name: 'سماعات لاسلكية',
    category: 'إلكترونيات',
    store: 'متجر التقنية',
    price: 15,
    icon: Icons.headphones,
    color: Color(0xFFE0EAFE),
  ),
  Product(
    name: 'حقيبة أنيقة',
    category: 'أزياء',
    store: 'أناقة ستور',
    price: 12,
    icon: Icons.shopping_bag,
    color: Color(0xFFFFE7D6),
  ),
  Product(
    name: 'ساعة يد',
    category: 'إكسسوارات',
    store: 'لمسة فاخرة',
    price: 20,
    icon: Icons.watch,
    color: Color(0xFFE8E0FF),
  ),
  Product(
    name: 'نبات منزلي',
    category: 'المنزل',
    store: 'حديقة البيت',
    price: 5,
    icon: Icons.yard,
    color: Color(0xFFDDF4E4),
  ),
  Product(
    name: 'حذاء رياضي',
    category: 'أزياء',
    store: 'أناقة ستور',
    price: 25,
    icon: Icons.directions_run,
    color: Color(0xFFFFE4E4),
  ),
  Product(
    name: 'مصباح مكتبي',
    category: 'المنزل',
    store: 'بيت العائلة',
    price: 8,
    icon: Icons.light,
    color: Color(0xFFFFF0C9),
  ),
];

const List<String> categories = [
  'الكل',
  'إلكترونيات',
  'أزياء',
  'المنزل',
  'إكسسوارات',
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? currentUser = Supabase.instance.client.auth.currentUser;
  int selectedTab = 0;
  String selectedCategory = 'الكل';
  String searchText = '';
  final Set<String> favorites = {};
  final Map<String, int> cart = {};
    List<Product> databaseProducts = [];

  @override
  void initState() {
    super.initState();
    loadDatabaseProducts();
  }

  Future<void> loadDatabaseProducts() async {
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select('name, description, price, category, image_url');
      final loadedProducts = data.map<Product>((item) {
        final category = item['category']?.toString() ?? 'أخرى';

        return Product(
          name: item['name']?.toString() ?? 'منتج',
          imageUrl: item['image_url']?.toString(),
          category: category,
          store: 'متجر محلّي',
          price: (item['price'] as num?)?.toDouble() ?? 0,
          icon: category == 'إلكترونيات'
              ? Icons.devices
              : category == 'أزياء'
                  ? Icons.shopping_bag
                  : category == 'المنزل'
                      ? Icons.home
                      : Icons.shopping_bag_outlined,
          color: const Color(0xFFE0EAFE),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        databaseProducts = loadedProducts;
      });

      debugPrint('تم تحميل ${loadedProducts.length} منتج من Supabase');
    } catch (error) {
      debugPrint('تعذر تحميل المنتجات من Supabase: $error');
    }
  }
 List<Product> get filteredProducts {
    final sourceProducts =
        databaseProducts.isNotEmpty ? databaseProducts : products;

    return sourceProducts.where((product) {
      final matchesCategory = selectedCategory == 'الكل' ||
          product.category == selectedCategory;
      final query = searchText.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.store.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);

      final matchesTab = selectedTab != 1 ||
          favorites.contains(product.name);
      final matchesCart = selectedTab != 2 || (cart[product.name] ?? 0) > 0;

      return matchesCategory &&
          matchesSearch &&
          matchesTab &&
          matchesCart;
    }).toList();
  }

  int get cartCount =>
      cart.values.fold(0, (total, quantity) => total + quantity);

  double get cartTotal {
    double total = 0;
    for (final product in products) {
      total += product.price * (cart[product.name] ?? 0);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: mahalliGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'محلّي',
              style: TextStyle(
                color: mahalliGreen,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'الإشعارات',
            onPressed: () => showMessage('ستتوفر الإشعارات لاحقًا'),
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 6),
        ],
      ),
       body: selectedTab == 4
    ? buildAccountPage()
    : selectedTab == 3
        ? buildMyStorePage()
        : buildShoppingPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        backgroundColor: Colors.white,
        indicatorColor: mahalliGreen.withValues(alpha: 0.12),
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'المفضلة',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'السلة',
          ),
          const NavigationDestination(
  icon: Icon(Icons.storefront_outlined),
  selectedIcon: Icon(Icons.storefront),
  label: 'متجري',
),
const NavigationDestination(
  icon: Icon(Icons.person_outline),
  selectedIcon: Icon(Icons.person),
  label: 'حسابي',
),
        ],
      ),
    );
  }

  Widget buildShoppingPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF087F5B), Color(0xFF20A879)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'كل ما تحب، في محلّي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'اكتشف متاجر ومنتجات تناسبك',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.local_mall, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'تسوّق من مكانك بسهولة',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (value) => setState(() => searchText = value),
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج أو متجر...',
            prefixIcon: const Icon(Icons.search, color: mahalliGreen),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        sectionTitle('التصنيفات', 'اكتشف ما يناسبك'),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = selectedCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: selected,
                selectedColor: mahalliGreen,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) {
                  setState(() => selectedCategory = category);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        sectionTitle(
          selectedTab == 1
              ? 'منتجاتك المفضلة'
              : selectedTab == 2
                  ? 'سلة مشترياتك'
                  : 'منتجات مميزة',
          'الأسعار بالدينار الأردني',
        ),
        const SizedBox(height: 14),
        if (selectedTab == 2 && cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'إجمالي السلة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${cartTotal.toStringAsFixed(2)} د.أ',
                  style: const TextStyle(
                    color: mahalliGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        if (filteredProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(35),
            child: Column(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 55,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  selectedTab == 1
                      ? 'لم تضف منتجات إلى المفضلة بعد'
                      : selectedTab == 2
                          ? 'سلة المشتريات فارغة'
                          : 'لا توجد منتجات مطابقة للبحث',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return productCard(product);
            },
          ),
      ],
    );
  }

  Widget sectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget productCard(Product product) {
    final isFavorite = favorites.contains(product.name);
    final quantity = cart[product.name] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECEFED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: product.color,
                  child: product.imageUrl != null &&
        product.imageUrl!.isNotEmpty
    ? Image.network(
        product.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            product.icon,
            size: 76,
            color: mahalliGreen,
          );
        },
      )
    : Icon(
        product.icon,
        size: 76,
        color: mahalliGreen,
      ),
                ),
                Positioned(
                  top: 7,
                  left: 7,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                      onPressed: () {
                        setState(() {
                          if (isFavorite) {
                            favorites.remove(product.name);
                          } else {
                            favorites.add(product.name);
                          }
                        });
                      },
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.black54,
                      ),
                    ),
                  ),
                ),
                if (quantity > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: mahalliGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'في السلة: $quantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              product.store,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${product.price.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(
                      color: mahalliGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton.filled(
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: mahalliGreen,
                    ),
                    onPressed: () {
                      setState(() {
                        cart[product.name] = quantity + 1;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('أُضيف ${product.name} إلى السلة'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedTab == 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (quantity <= 1) {
                          cart.remove(product.name);
                        } else {
                          cart[product.name] = quantity - 1;
                        }
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$quantity'),
                  IconButton(
                    onPressed: () {
                      (() {
                        cart[product.name] = quantity + 1;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget buildMyStorePage() {
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 64,
              color: mahalliGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'سجّل الدخول أولًا لإنشاء متجرك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() => selectedTab = 4);
              },
              child: const Text('الذهاب إلى حسابي'),
            ),
          ],
        ),
      ),
    );
  }

  return StoreSetupPage(
    userId: user.id,
    onMessage: showMessage,
  );
}
  Widget buildAccountPage() {
    Future<void> showAuthDialog(bool isRegister) async {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      bool isLoading = false;
      String? errorMessage;

      try {
        await showDialog(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text(
                    isRegister ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pop(dialogContext),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final email = emailController.text.trim();
                              final password = passwordController.text;

                              if (email.isEmpty || password.isEmpty) {
                                setDialogState(() {
                                  errorMessage =
                                      'أدخل البريد الإلكتروني وكلمة المرور';
                                });
                                return;
                              }

                              setDialogState(() {
                                isLoading = true;
                                errorMessage = null;
                              });

                              try {
                                if (isRegister) {
                                  final response = await Supabase
                                      .instance.client.auth
                                      .signUp(
                                    email: email,
                                    password: password,
                                  );

                                  if (response.session == null) {
                                    if (!dialogContext.mounted) return;
                                    Navigator.pop(dialogContext);
                                    showMessage(
                                      'تم إنشاء الحساب. تحقق من بريدك الإلكتروني لتفعيله.',
                                    );
                                    return;
                                  }
                                } else {
                                  await Supabase.instance.client.auth
                                      .signInWithPassword(
                                    email: email,
                                    password: password,
                                  );
                                }

  if (!mounted || !dialogContext.mounted) return;

Navigator.pop(dialogContext);

setState(() {
  currentUser = Supabase.instance.client.auth.currentUser;
});

showMessage(
  isRegister
      ? 'تم إنشاء الحساب بنجاح'
      : 'تم تسجيل الدخول بنجاح',
);                             
                              } catch (error) {
                                setDialogState(() {
                                  errorMessage =
                                      'تعذر إتمام العملية. تحقق من البيانات وحاول مجددًا.';
                                  isLoading = false;
                                });
                              }
                            },
                      child: Text(
                        isLoading
                            ? 'يرجى الانتظار...'
                            : isRegister
                                ? 'إنشاء الحساب'
                                : 'دخول',
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      } finally {
        emailController.dispose();
        passwordController.dispose();
      }
    }

    if (currentUser != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 25),
          const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFFDDF4E4),
            child: Icon(Icons.person, size: 48, color: mahalliGreen),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'أهلًا بك في محلّي',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(currentUser!.email ?? '')),
          const SizedBox(height: 25),
          FilledButton.icon(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              setState(() {
                currentUser = null;
              });
              showMessage('تم تسجيل الخروج');
            },
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
          const SizedBox(height: 12),
          accountOption(
            Icons.receipt_long,
            'طلباتي',
            'قريبًا',
          ),
          accountOption(
            Icons.support_agent,
            'المساعدة والدعم',
            'قريبًا',
          ),
          accountOption(
            Icons.info_outline,
            'عن محلّي',
            'سوق المتاجر المحلي',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 25),
        const CircleAvatar(
          radius: 42,
          backgroundColor: Color(0xFFDDF4E4),
          child: Icon(Icons.person, size: 48, color: mahalliGreen),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'أهلًا بك في محلّي',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'سجّل دخولك لتجربة تسوق أفضل',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 25),
        FilledButton.icon(
          onPressed: () => showAuthDialog(false),
          icon: const Icon(Icons.login),
          label: const Text('تسجيل الدخول'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => showAuthDialog(true),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('إنشاء حساب جديد'),
        ),
        const SizedBox(height: 20),
        accountOption(
          Icons.support_agent,
          'المساعدة والدعم',
          'قريبًا',
        ),
        accountOption(
          Icons.info_outline,
          'عن محلّي',
          'سوق المتاجر المحلي',
        ),
      ],
    );
  }

  Widget accountOption(IconData icon, String title, String subtitle) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: mahalliGreen),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => showMessage('$title: ستتم إضافتها في المرحلة القادمة'),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}


class StoreSetupPage extends StatefulWidget {
  final String userId;
  final void Function(String) onMessage;

  const StoreSetupPage({
    super.key,
    required this.userId,
    required this.onMessage,
  });

  @override
  State<StoreSetupPage> createState() => _StoreSetupPageState();
}

class _StoreSetupPageState extends State<StoreSetupPage> {
  final storeNameController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool storeExists = false;

  List<Map<String, dynamic>> myProducts = [];
  bool isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    loadStore();
    loadMyProducts();
  }

  Future<void> loadStore() async {
    try {
      final result = await Supabase.instance.client
          .from('seller_stores')
          .select('store_name, description')
          .eq('id', widget.userId)
          .maybeSingle();

      if (!mounted) return;

      if (result != null) {
        storeNameController.text =
            result['store_name']?.toString() ?? '';
        descriptionController.text =
            result['description']?.toString() ?? '';
        storeExists = true;
      }
    } catch (error) {
      widget.onMessage('تعذر تحميل بيانات المتجر');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> loadMyProducts() async {
    if (!mounted) return;

    setState(() => isLoadingProducts = true);

    try {
      final result = await Supabase.instance.client
          .from('products')
          .select('id, name, description, price, category, image_url')
          .eq('seller_id', widget.userId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        myProducts = List<Map<String, dynamic>>.from(result);
        isLoadingProducts = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoadingProducts = false);
      widget.onMessage('تعذر تحميل المنتجات: $error');
    }
  }

  Future<void> saveStore() async {
    final name = storeNameController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty) {
      widget.onMessage('اكتب اسم المتجر أولًا');
      return;
    }

    setState(() => isSaving = true);

    try {
      final data = {
        'id': widget.userId,
        'store_name': name,
        'description': description,
      };

      if (storeExists) {
        await Supabase.instance.client
            .from('seller_stores')
            .update({
              'store_name': name,
              'description': description,
            })
            .eq('id', widget.userId);
      } else {
        await Supabase.instance.client
            .from('seller_stores')
            .insert(data);
        storeExists = true;
      }

      if (!mounted) return;

      setState(() {});
      widget.onMessage('تم حفظ بيانات المتجر بنجاح');
    } catch (error) {
      widget.onMessage('فشل الحفظ: $error');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text(
          'هل تريد حذف "${product['name']}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('products')
          .delete()
          .eq('id', product['id'])
          .eq('seller_id', widget.userId);

      await loadMyProducts();
      widget.onMessage('تم حذف المنتج');
    } catch (error) {
      widget.onMessage('تعذر حذف المنتج: $error');
    }
  }

  Future<void> editProduct(Map<String, dynamic> product) async {
    final nameController = TextEditingController(
      text: product['name']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: product['price']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: product['description']?.toString() ?? '',
    );

    final categories = [
      'إلكترونيات',
      'أزياء',
      'المنزل',
      'إكسسوارات',
      'أخرى',
    ];

    String category = categories.contains(product['category'])
        ? product['category'].toString()
        : 'أخرى';

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('تعديل المنتج'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المنتج',
                        ),
                      ),
                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'السعر بالدينار',
                        ),
                      ),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'الوصف',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(
                          labelText: 'التصنيف',
                        ),
                        items: categories.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => category = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final price = double.tryParse(
                        priceController.text.trim(),
                      );

                      if (name.isEmpty || price == null || price <= 0) {
                        widget.onMessage('تحقق من اسم المنتج والسعر');
                        return;
                      }

                      try {
                        await Supabase.instance.client
                            .from('products')
                            .update({
                              'name': name,
                              'price': price,
                              'description':
                                  descriptionController.text.trim(),
                              'category': category,
                            })
                            .eq('id', product['id'])
                            .eq('seller_id', widget.userId);

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await loadMyProducts();
                        widget.onMessage('تم تعديل المنتج بنجاح');
                      } catch (error) {
                        widget.onMessage('تعذر تعديل المنتج: $error');
                      }
                    },
                    child: const Text('حفظ التعديل'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      priceController.dispose();
      descriptionController.dispose();
    }
  }

  @override
  void dispose() {
    storeNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(
          Icons.storefront,
          size: 72,
          color: mahalliGreen,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            storeExists ? 'إدارة متجري' : 'أنشئ متجرك الخاص',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'أدخل معلومات متجرك، ثم احفظها.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: storeNameController,
          decoration: const InputDecoration(
            labelText: 'اسم المتجر',
            prefixIcon: Icon(Icons.store),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'وصف المتجر (اختياري)',
            prefixIcon: Icon(Icons.description_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: isSaving ? null : saveStore,
          icon: const Icon(Icons.save_outlined),
          label: Text(
            isSaving ? 'جارٍ الحفظ...' : 'حفظ بيانات المتجر',
          ),
        ),
        if (storeExists) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProductPage(
                    userId: widget.userId,
                    onSaved: () {
                      loadMyProducts();
                      widget.onMessage('تم تحديث المنتجات');
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('إضافة منتج جديد'),
          ),
          const SizedBox(height: 20),
          const Card(
            child: ListTile(
              leading: Icon(
                Icons.check_circle_outline,
                color: mahalliGreen,
              ),
              title: Text('تم إنشاء متجرك'),
              subtitle: Text(
                'يمكنك تعديل بيانات المتجر وإدارة منتجاتك.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'منتجات متجري',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (isLoadingProducts)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (myProducts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('لم تضف أي منتجات بعد'),
              ),
            )
          else
            ...myProducts.map((product) {
              final imageUrl = product['image_url']?.toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 55,
                            height: 55,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.inventory_2_outlined,
                              );
                            },
                          ),
                        )
                      : const Icon(Icons.inventory_2_outlined),
                  title: Text(product['name']?.toString() ?? ''),
                  subtitle: Text(
                    '${product['price']} د.أ - ${product['category']}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        editProduct(product);
                      } else if (value == 'delete') {
                        deleteProduct(product);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('تعديل'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('حذف'),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ],
    );
  }
}

class AddProductPage extends StatefulWidget {
  final String userId;
  final VoidCallback onSaved;

  const AddProductPage({
    super.key,
    required this.userId,
    required this.onSaved,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  final picker = ImagePicker();
  String category = 'إلكترونيات';
  XFile? selectedImage;
  bool saving = false;

  final categories = [
    'إلكترونيات',
    'أزياء',
    'المنزل',
    'إكسسوارات',
    'أخرى',
  ];

  Future<void> chooseImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() => selectedImage = image);
    }
  }

  Future<void> saveProduct() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim());

    if (name.isEmpty || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل اسم المنتج وسعرًا صحيحًا')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final supabase = Supabase.instance.client;
      String? imageUrl;

      if (selectedImage != null) {
        final bytes = await selectedImage!.readAsBytes();
        final path =
            '${widget.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        await supabase.storage
            .from('product-images')
            .uploadBinary(path, bytes);

        imageUrl = supabase.storage
            .from('product-images')
            .getPublicUrl(path);
      }

      await supabase.from('products').insert({
        'name': name,
        'price': price,
        'description': descriptionController.text.trim(),
        'category': category,
        'image_url': imageUrl,
        'seller_id': widget.userId,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة المنتج بنجاح')),
      );

      widget.onSaved();
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشلت إضافة المنتج: $error')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'اسم المنتج',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'السعر بالدينار الأردني',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'وصف المنتج',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(
              labelText: 'التصنيف',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => category = value);
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: chooseImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(
              selectedImage == null
                  ? 'اختيار صورة المنتج'
                  : 'تم اختيار الصورة',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : saveProduct,
            child: Text(saving ? 'جارٍ الحفظ...' : 'حفظ المنتج'),
          ),
        ],
      ),
    );
  }
}
