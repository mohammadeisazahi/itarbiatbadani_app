import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const String site = 'https://itarbiatbadani.ir';
const String api = '$site/wp-json/wp/v2';
const String wcKey = 'YOUR_WC_KEY';
const String wcSecret = 'YOUR_WC_SECRET';
const String logo = 'assets/images/logo.png';
const String logoNet = '$site/wp-content/uploads/2025/07/1000073463.png';
const String heroImg = '$site/wp-content/uploads/2025/08/file_00000000b12862439589872d238e031b-1.png';
const int perPageSize = 10;

final _storage = const FlutterSecureStorage();
final darkModeNotifier = ValueNotifier<bool>(true);

// ===== رنگ‌های پویا (شب و روز) =====
Color get bgC => darkModeNotifier.value ? const Color(0xff0a1929) : const Color(0xfff5f9fc);
Color get pnl => darkModeNotifier.value ? const Color(0xff132f4c) : const Color(0xffffffff);
Color get pnl2 => darkModeNotifier.value ? const Color(0xff1a3a5c) : const Color(0xffeef4fa);
Color get txtC => darkModeNotifier.value ? const Color(0xffffffff) : const Color(0xff0a1929);
Color get mutC => darkModeNotifier.value ? const Color(0xff8899aa) : const Color(0xff5a6b7c);
Color get accentGreen => darkModeNotifier.value ? const Color(0xff4caf50) : const Color(0xff2e7d32);
Color get accentBlue => darkModeNotifier.value ? const Color(0xff42a5f5) : const Color(0xff1976d2);
Color get gold => darkModeNotifier.value ? const Color(0xfffbc531) : const Color(0xffd4a017);
Color get lineC => darkModeNotifier.value ? const Color(0x404caf50) : const Color(0x332e7d32);
Color get navBg => darkModeNotifier.value ? const Color(0xff0d1f33) : const Color(0xffffffff);
Color get skeletonC => darkModeNotifier.value ? const Color(0xff1a3a5c) : const Color(0xffe0e8f0);

class Cat {
  final String n;
  final String s;
  final IconData i;
  const Cat(this.n, this.s, this.i);
}

const cats = <Cat>[
  Cat('رشته تربیت بدنی و علوم ورزشی', 'physical-education-sport-sciences', Icons.sports_soccer),
  Cat('علوم ورزشی', 'sports-science', Icons.science_outlined),
  Cat('منابع آزمون‌های علوم ورزشی', 'sports-science-exam-resources', Icons.menu_book_outlined),
  Cat('تغذیه ورزشی', 'sports-nutrition', Icons.restaurant_outlined),
  Cat('اخبار و رویدادها', 'sports-news-and-events', Icons.newspaper_outlined),
  Cat('ورزش همگانی، سلامت و تندرستی', 'public-exercise-health-and-wellness', Icons.favorite_outline),
  Cat('پژوهش در تربیت بدنی', 'research-in-physical-education', Icons.search_outlined),
  Cat('تربیت بدنی و آموزش', 'physical-education-and-training', Icons.school_outlined),
  Cat('معرفی منابع و کتب مرجع', 'introduction-to-sources-and-reference-books', Icons.library_books_outlined),
  Cat('اصول ورزش و فعالیت بدنی', 'principles-of-exercise-and-physical-activity', Icons.fitness_center_outlined),
  Cat('آزمون‌های استخدامی', 'employment-tests', Icons.assignment_outlined),
  Cat('معرفی رشته‌های ورزشی', 'introduction-to-sports-disciplines', Icons.sports_handball_outlined),
  Cat('ورزش برای گروه‌ها و نیازهای ویژه', 'exercise-for-special-groups-and-needs', Icons.accessibility_new_outlined),
  Cat('فناوری و نوآوری در ورزش', 'technology-and-innovation-in-sports-sports-science', Icons.memory_outlined),
];

Future<void> openUrl(String url) async {
  if (url.isEmpty) return;
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

String clean(String v) => v
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#8217;', '’')
    .replaceAll('&#8220;', '“')
    .replaceAll('&#8221;', '”')
    .trim();

String pTitle(dynamic p) {
  try { return clean(p['title']['rendered'] ?? ''); } catch (_) { return ''; }
}

String pLink(dynamic p) {
  try { return p['link'] ?? ''; } catch (_) { return ''; }
}

String pImg(dynamic p) {
  try {
    final m = p['_embedded']?['wp:featuredmedia'];
    if (m is List && m.isNotEmpty) return m[0]['source_url'] ?? '';
  } catch (_) {}
  return '';
}

String pDate(dynamic p) {
  try {
    final d = DateTime.parse(p['date']).toLocal();
    final j = _toJalali(d.year, d.month, d.day);
    return '${j[0]}/${j[1].toString().padLeft(2, '0')}/${j[2].toString().padLeft(2, '0')}';
  } catch (_) { return ''; }
}

List<int> _toJalali(int gy, int gm, int gd) {
  const gdm = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  const jdm = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];
  var gy2 = (gm > 2) ? (gy + 1) : gy;
  var days = 355666 + (365 * gy) + ((gy2 + 3) ~/ 4) - ((gy2 + 99) ~/ 100) + ((gy2 + 399) ~/ 400) + gd;
  for (var i = 0; i < gm - 1; i++) days += gdm[i];
  var jy = -1595 + (33 * (days ~/ 12053));
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) { jy += (days - 1) ~/ 365; days = (days - 1) % 365; }
  var jm = 0;
  var jd = days + 1;
  for (var i = 0; i < 12; i++) {
    if (jd <= jdm[i]) { jm = i + 1; break; }
    jd -= jdm[i];
  }
  return [jy, jm, jd];
}

Future<List> getPostsPaged({int perPage = perPageSize, int page = 1, int? catId}) async {
  var u = '$api/posts?per_page=$perPage&page=$page&_embed=wp:featuredmedia';
  if (catId != null) u += '&categories=$catId';
  final r = await http.get(Uri.parse(u));
  if (r.statusCode == 400) return [];
  if (r.statusCode != 200) throw Exception('خطای ${r.statusCode}');
  return json.decode(r.body) as List;
}

Future<List> getProductsPaged({int perPage = perPageSize, int page = 1}) async {
  final u = '$site/wp-json/wc/v3/products?per_page=$perPage&page=$page&consumer_key=$wcKey&consumer_secret=$wcSecret';
  final r = await http.get(Uri.parse(u));
  if (r.statusCode == 400) return [];
  if (r.statusCode != 200) throw Exception('خطای ${r.statusCode}');
  return json.decode(r.body) as List;
}

Future<int?> getCatIdBySlug(String slug) async {
  try {
    final r = await http.get(Uri.parse('$api/categories?slug=$slug'));
    if (r.statusCode == 200) {
      final list = json.decode(r.body);
      if (list is List && list.isNotEmpty) return list[0]['id'];
    }
  } catch (_) {}
  return null;
}

Future<List> searchExact(String query) async {
  final r = await http.get(
    Uri.parse('$api/posts?search=${Uri.encodeComponent(query)}&per_page=50&_embed=wp:featuredmedia'),
  );
  if (r.statusCode != 200) throw Exception('خطای ${r.statusCode}');
  final list = json.decode(r.body) as List;
  final words = query.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return list.where((p) {
    final title = clean((p['title']?['rendered'] ?? '')).toLowerCase();
    return words.every((w) => title.contains(w));
  }).toList();
}

String formatPrice(String price) {
  if (price.isEmpty) return '';
  final n = int.tryParse(price);
  if (n == null) return price;
  final s = n.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return '$buffer تومان';
}

/* ==================== ⭐ NEW NEWS API (CPT: new_news) ==================== */

String _newNewsUrl({int perPage = 10, int page = 1}) {
  return '$api/new_news?per_page=$perPage&page=$page&orderby=date&order=desc&_embed=wp:featuredmedia';
}

Future<Map<String, dynamic>?> getNewNews() async {
  try {
    final r = await http.get(Uri.parse(_newNewsUrl(perPage: 1)));
    if (r.statusCode != 200) return null;
    final list = json.decode(r.body) as List;
    if (list.isEmpty) return null;
    return Map<String, dynamic>.from(list.first);
  } catch (_) {
    return null;
  }
}

Future<List> getNewNewsList() async {
  try {
    final r = await http.get(Uri.parse(_newNewsUrl(perPage: 20)));
    if (r.statusCode != 200) return [];
    return json.decode(r.body) as List;
  } catch (_) {
    return [];
  }
}

String _basicAuth(String user, String pass) {
  final clean = pass.replaceAll(' ', '');
  return base64Encode(utf8.encode('$user:$clean'));
}

Future<Map<String, dynamic>> postNewNews({
  required String username,
  required String appPassword,
  required String title,
  required String content,
}) async {
  final auth = _basicAuth(username, appPassword);
  final uri = Uri.parse('$api/new_news');

  final r = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic $auth',
    },
    body: jsonEncode({
      'title': title,
      'content': content,
      'status': 'publish',
    }),
  );

  if (r.statusCode == 201 || r.statusCode == 200) {
    final d = jsonDecode(r.body);
    if (d is Map) return Map<String, dynamic>.from(d);
    throw Exception('پاسخ نامعتبر');
  }
  if (r.statusCode == 401) throw Exception('نام کاربری یا رمز اشتباه است.');
  if (r.statusCode == 403) throw Exception('شما اجازه ارسال ندارید.');
  throw Exception('خطا در ارسال (${r.statusCode})');
}

Future<void> deleteNews({
  required String username,
  required String appPassword,
  required int postId,
}) async {
  final auth = _basicAuth(username, appPassword);
  final uri = Uri.parse('$api/new_news/$postId?force=true');
  final r = await http.delete(
    uri,
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Basic $auth',
    },
  );
  if (r.statusCode == 200 || r.statusCode == 201) return;
  if (r.statusCode == 401) throw Exception('نام کاربری یا رمز اشتباه است.');
  if (r.statusCode == 403) throw Exception('شما اجازه حذف ندارید.');
  throw Exception('خطا در حذف (${r.statusCode})');
}

Future<void> verifyAdmin({
  required String username,
  required String appPassword,
}) async {
  final auth = _basicAuth(username, appPassword);
  final r = await http.get(
    Uri.parse('$api/users/me'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Basic $auth',
    },
  );
  if (r.statusCode == 200) return;
  if (r.statusCode == 401) throw Exception('نام کاربری یا رمز اشتباه است.');
  throw Exception('خطا در ورود (${r.statusCode})');
}
/* ==================== MAIN ==================== */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final saved = await _storage.read(key: 'dark_mode');
    darkModeNotifier.value = saved == null ? true : saved == 'true';
  } catch (_) {}
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (c, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'تربیت بدنی و علوم ورزشی',
          theme: ThemeData(
            fontFamily: 'Vazirmatn',
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: bgC,
            colorScheme: ColorScheme.fromSeed(
              seedColor: accentGreen,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder()},
            ),
          ),
          builder: (c, ch) => Directionality(
            textDirection: TextDirection.rtl,
            child: ch ?? const SizedBox(),
          ),
          home: const Root(),
        );
      },
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        body: IndexedStack(
          index: _i,
          children: const [Home(), ArticlesPage(), NewsPage(), ShopPage(), AccountPage()],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _i,
          onTap: (i) => setState(() => _i = i),
          backgroundColor: navBg,
          selectedItemColor: gold,
          unselectedItemColor: mutC,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'خانه'),
            BottomNavigationBarItem(icon: Icon(Icons.article_outlined), activeIcon: Icon(Icons.article), label: 'مقالات'),
            BottomNavigationBarItem(icon: Icon(Icons.newspaper_outlined), activeIcon: Icon(Icons.newspaper), label: 'اخبار'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'فروشگاه'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'حساب من'),
          ],
        ),
      ),
    );
  }
}

/* ==================== HOME ==================== */
class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<List>? _f;
  Key _bannerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _f = getPostsPaged(perPage: 6, page: 1);
  }

  Future<void> _refresh() async {
    setState(() {
      _f = getPostsPaged(perPage: 6, page: 1);
      _bannerKey = UniqueKey();
    });
    try { await _f; } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => RefreshIndicator(
        color: accentGreen,
        backgroundColor: pnl,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(context)),

            // ⭐ بنر اخبار جدید (زیر Hero، بالای خدمات ما)
            SliverToBoxAdapter(child: NewNewsBanner(key: _bannerKey)),

            SliverToBoxAdapter(child: _hero()),
            SliverToBoxAdapter(child: _services()),
            const SliverToBoxAdapter(
              child: _SectionTitle('جدیدترین نوشته‌ها', Icons.article_outlined),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List>(
                future: _f,
                builder: (c, s) {
                  if (s.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          _FeaturedSkeleton(),
                          _PostSkeleton(),
                          _PostSkeleton(),
                          _PostSkeleton(),
                        ],
                      ),
                    );
                  }
                  if (s.hasError) {
                    return _ErrorBox('خطا در دریافت مطالب.\n${s.error}', _refresh);
                  }
                  final posts = s.data ?? [];
                  if (posts.isEmpty) return const _Empty('مطلبی پیدا نشد.');
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        _featuredPost(context, posts.first),
                        ...posts.skip(1).map((p) => _post(context, p)).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(
              child: _SectionTitle('دسته‌بندی مقالات', Icons.grid_view_rounded),
            ),
            SliverToBoxAdapter(child: _catGrid()),
            SliverToBoxAdapter(child: _social()),
            const SliverToBoxAdapter(child: SizedBox(height: 25)),
          ],
        ),
      ),
    );
  }
}

/* ==================== ARTICLES ==================== */
class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key});
  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  final _posts = <dynamic>[];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 && !_loading && _hasMore) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() { _loading = true; _error = null; });
    try {
      final list = await getPostsPaged(perPage: perPageSize, page: _page);
      setState(() {
        if (list.isEmpty) {
          _hasMore = false;
        } else {
          _posts.addAll(list);
          _page++;
          if (list.length < perPageSize) _hasMore = false;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _refresh() async {
    setState(() { _posts.clear(); _page = 1; _hasMore = true; _error = null; });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        body: Column(
          children: [
            _header(context, 'مقالات'),
            Expanded(
              child: _posts.isEmpty && _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _PostSkeleton(),
                          _PostSkeleton(),
                          _PostSkeleton(),
                          _PostSkeleton(),
                          _PostSkeleton(),
                        ],
                      ),
                    )
                  : _posts.isEmpty && _error != null
                      ? _ErrorBox('خطا در دریافت مقالات.\n$_error', _refresh)
                      : _posts.isEmpty
                          ? const _Empty('مقاله‌ای پیدا نشد.')
                          : RefreshIndicator(
                              color: accentGreen,
                              backgroundColor: pnl,
                              onRefresh: _refresh,
                              child: ListView.builder(
                                controller: _scroll,
                                cacheExtent: 800,
                                padding: const EdgeInsets.all(14),
                                itemCount: _posts.length + (_hasMore ? 1 : 0),
                                itemBuilder: (c, i) {
                                  if (i >= _posts.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(child: CircularProgressIndicator(color: accentGreen)),
                                    );
                                  }
                                  return _post(context, _posts[i]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== CATEGORY POSTS ==================== */
class CategoryPostsPage extends StatefulWidget {
  final Cat c;
  const CategoryPostsPage({super.key, required this.c});
  @override
  State<CategoryPostsPage> createState() => _CategoryPostsPageState();
}

class _CategoryPostsPageState extends State<CategoryPostsPage> {
  final _posts = <dynamic>[];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int? _catId;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 && !_loading && _hasMore) {
        _load();
      }
    });
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      _catId = await getCatIdBySlug(widget.c.s);
      if (_catId == null) throw Exception('دسته‌بندی یافت نشد');
      await _load();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _load() async {
    if (_loading && _posts.isNotEmpty) return;
    if (!_hasMore) return;
    setState(() { _loading = true; _error = null; });
    try {
      final list = await getPostsPaged(perPage: perPageSize, page: _page, catId: _catId);
      setState(() {
        if (list.isEmpty) {
          _hasMore = false;
        } else {
          _posts.addAll(list);
          _page++;
          if (list.length < perPageSize) _hasMore = false;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _refresh() async {
    setState(() { _posts.clear(); _page = 1; _hasMore = true; _error = null; });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        appBar: AppBar(title: Text(widget.c.n), backgroundColor: bgC, foregroundColor: txtC),
        body: _posts.isEmpty && _loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  children: [
                    _PostSkeleton(),
                    _PostSkeleton(),
                    _PostSkeleton(),
                    _PostSkeleton(),
                  ],
                ),
              )
            : _posts.isEmpty && _error != null
                ? _ErrorBox('خطا در دریافت مطالب.\n$_error', _refresh)
                : _posts.isEmpty
                    ? const _Empty('مطلبی در این دسته پیدا نشد.')
                    : RefreshIndicator(
                        color: accentGreen,
                        backgroundColor: pnl,
                        onRefresh: _refresh,
                        child: ListView.builder(
                          controller: _scroll,
                          cacheExtent: 800,
                          padding: const EdgeInsets.all(14),
                          itemCount: _posts.length + (_hasMore ? 1 : 0),
                          itemBuilder: (c, i) {
                            if (i >= _posts.length) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: Center(child: CircularProgressIndicator(color: accentGreen)),
                              );
                            }
                            return _post(context, _posts[i]);
                          },
                        ),
                      ),
      ),
    );
  }
}

/* ==================== NEWS ==================== */
class NewsPage extends StatefulWidget {
  const NewsPage({super.key});
  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _posts = <dynamic>[];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int? _catId;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 && !_loading && _hasMore) {
        _load();
      }
    });
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      _catId = await getCatIdBySlug('sports-news-and-events');
      if (_catId == null) throw Exception('دسته‌بندی اخبار یافت نشد');
      await _load();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _load() async {
    if (_loading && _posts.isNotEmpty) return;
    if (!_hasMore) return;
    setState(() { _loading = true; _error = null; });
    try {
      final list = await getPostsPaged(perPage: perPageSize, page: _page, catId: _catId);
      setState(() {
        if (list.isEmpty) {
          _hasMore = false;
        } else {
          _posts.addAll(list);
          _page++;
          if (list.length < perPageSize) _hasMore = false;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _refresh() async {
    setState(() { _posts.clear(); _page = 1; _hasMore = true; _error = null; });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Column(
        children: [
          AppBar(title: const Text('اخبار و رویدادها'), backgroundColor: bgC, foregroundColor: txtC),
          Expanded(
            child: _posts.isEmpty && _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _PostSkeleton(),
                        _PostSkeleton(),
                        _PostSkeleton(),
                        _PostSkeleton(),
                      ],
                    ),
                  )
                : _posts.isEmpty && _error != null
                    ? _ErrorBox('خطا در دریافت اخبار.\n$_error', _refresh)
                    : _posts.isEmpty
                        ? const _Empty('خبری پیدا نشد.')
                        : RefreshIndicator(
                            color: accentGreen,
                            backgroundColor: pnl,
                            onRefresh: _refresh,
                            child: ListView.builder(
                              controller: _scroll,
                              cacheExtent: 800,
                              padding: const EdgeInsets.all(14),
                              itemCount: _posts.length + (_hasMore ? 1 : 0),
                              itemBuilder: (c, i) {
                                if (i >= _posts.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Center(child: CircularProgressIndicator(color: accentGreen)),
                                  );
                                }
                                return _post(context, _posts[i]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

/* ==================== SHOP ==================== */
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final _products = <dynamic>[];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 && !_loading && _hasMore) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() { _loading = true; _error = null; });
    try {
      final list = await getProductsPaged(perPage: perPageSize, page: _page);
      setState(() {
        if (list.isEmpty) {
          _hasMore = false;
        } else {
          _products.addAll(list);
          _page++;
          if (list.length < perPageSize) _hasMore = false;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _refresh() async {
    setState(() { _products.clear(); _page = 1; _hasMore = true; _error = null; });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        body: Column(
          children: [
            _header(context, 'فروشگاه'),
            Expanded(
              child: _products.isEmpty && _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _PostSkeleton(),
                          _PostSkeleton(),
                          _PostSkeleton(),
                          _PostSkeleton(),
                        ],
                      ),
                    )
                  : _products.isEmpty && _error != null
                      ? _ErrorBox('خطا در دریافت محصولات.\n$_error', _refresh)
                      : _products.isEmpty
                          ? const _Empty('محصولی پیدا نشد.')
                          : RefreshIndicator(
                              color: accentGreen,
                              backgroundColor: pnl,
                              onRefresh: _refresh,
                              child: ListView.builder(
                                controller: _scroll,
                                cacheExtent: 800,
                                padding: const EdgeInsets.all(14),
                                itemCount: _products.length + (_hasMore ? 1 : 0),
                                itemBuilder: (c, i) {
                                  if (i >= _products.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(child: CircularProgressIndicator(color: accentGreen)),
                                    );
                                  }
                                  return _product(context, _products[i]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== SEARCH (Live) ==================== */
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  Future<List>? _f;
  String _q = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = value.trim();
      if (q.isEmpty) {
        setState(() { _q = ''; _f = null; });
        return;
      }
      setState(() { _q = q; _f = searchExact(q); });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        appBar: AppBar(title: const Text('جستجو'), backgroundColor: bgC, foregroundColor: txtC),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                style: TextStyle(color: txtC),
                decoration: InputDecoration(
                  hintText: 'عبارت مورد نظر...',
                  hintStyle: TextStyle(color: mutC),
                  filled: true,
                  fillColor: pnl,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: accentGreen),
                    onPressed: () => _onChanged(_ctrl.text),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _f == null
                  ? const _Empty('عبارتی برای جستجو وارد کنید')
                  : FutureBuilder<List>(
                      future: _f,
                      builder: (c, s) {
                        if (s.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(14),
                            child: Column(
                              children: [
                                _PostSkeleton(),
                                _PostSkeleton(),
                                _PostSkeleton(),
                              ],
                            ),
                          );
                        }
                        if (s.hasError) return _ErrorBox('خطا در جستجو.\n${s.error}', null);
                        final posts = s.data ?? [];
                        if (posts.isEmpty) return _Empty('نتیجه‌ای برای «$_q» پیدا نشد.');
                        return ListView.builder(
                          cacheExtent: 800,
                          padding: const EdgeInsets.all(14),
                          itemCount: posts.length,
                          itemBuilder: (c, i) => _post(context, posts[i]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
/* ==================== ACCOUNT (Persistent Login + Download) ==================== */
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  InAppWebViewController? _controller;
  bool _l = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final saved = await _storage.read(key: 'wc_cookies');
      if (saved != null && saved.isNotEmpty) {
        final list = json.decode(saved) as List;
        for (var item in list) {
          await CookieManager.instance().setCookie(
            url: WebUri(site),
            name: item['name'],
            value: item['value'],
            domain: item['domain'],
            path: item['path'],
            isHttpOnly: item['httponly'] ?? false,
            isSecure: item['secure'] ?? false,
            expiresDate: item['expiry'] != null
                ? (item['expiry'] as int) * 1000
                : null,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      if (_controller == null) return;
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri(site),
      );

      final loginCookies = cookies.where(
        (c) =>
            c.name.startsWith('wordpress_logged_in') ||
            c.name.startsWith('wordpress_sec'),
      ).toList();

      if (loginCookies.isNotEmpty) {
        final list = loginCookies
            .map((c) => {
                  'name': c.name,
                  'value': c.value,
                  'domain': c.domain,
                  'path': c.path,
                  'httponly': c.isHttpOnly,
                  'secure': c.isSecure,
                  'expiry': c.expiresDate,
                })
            .toList();
        await _storage.write(key: 'wc_cookies', value: json.encode(list));
      } else {
        await _storage.delete(key: 'wc_cookies');
        await CookieManager.instance().deleteAllCookies();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        body: Column(
          children: [
            // هدر با دکمه پنل ادمین
            _headerWithAdmin(context, 'حساب من'),
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri('$site/my-account/')),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      useOnDownloadStart: true,
                      userAgent:
                          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                    ),
                    onWebViewCreated: (c) => _controller = c,
                    onLoadStart: (c, url) => setState(() => _l = true),
                    onLoadStop: (c, url) async {
                      setState(() => _l = false);
                      await _save();
                    },
                    onDownloadStartRequest: (controller, request) async {
                      final url = request.url.toString();
                      await openUrl(url);
                    },
                  ),
                  if (_l) Center(child: CircularProgressIndicator(color: accentGreen)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== WEB PAGE ==================== */
class WebPage extends StatefulWidget {
  final String url;
  final String title;
  final bool fullPage;
  const WebPage({
    super.key,
    required this.url,
    required this.title,
    this.fullPage = false,
  });
  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  bool _l = true;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            userAgent:
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          ),
          onLoadStart: (c, url) => setState(() => _l = true),
          onLoadStop: (c, url) => setState(() => _l = false),
        ),
        if (_l) Center(child: CircularProgressIndicator(color: accentGreen)),
      ],
    );

    if (widget.fullPage) {
      return Scaffold(
        body: Column(
          children: [
            _header(context, widget.title),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: bgC, foregroundColor: txtC),
      body: content,
    );
  }
}

/* ==================== NEW NEWS BANNER ==================== */

class NewNewsBanner extends StatefulWidget {
  const NewNewsBanner({super.key});
  @override
  State<NewNewsBanner> createState() => _NewNewsBannerState();
}

class _NewNewsBannerState extends State<NewNewsBanner> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = getNewNews();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final news = snapshot.data!;
        final title = pTitle(news);
        final link = pLink(news);
        final date = pDate(news);

        return GestureDetector(
          onTap: () => openUrl(link),
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: darkModeNotifier.value
                    ? [const Color(0xff42a5f5), const Color(0xff1976d2)]
                    : [const Color(0xff2196f3), const Color(0xff0d47a1)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: accentBlue.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_new, color: accentBlue, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          'اخبار جدید',
                          style: TextStyle(
                            color: accentBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.6,
                          ),
                        ),
                        if (date.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ==================== ADMIN LOGIN PAGE ==================== */

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (user.isEmpty || pass.isEmpty) {
      setState(() => _error = 'نام کاربری و رمز را وارد کنید.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await verifyAdmin(username: user, appPassword: pass);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminPanelPage(username: user, password: pass),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        appBar: AppBar(
          title: const Text('ورود ادمین'),
          backgroundColor: bgC,
          foregroundColor: txtC,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline, color: gold, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'فقط مدیر سایت',
                style: TextStyle(
                  color: txtC,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'برای مدیریت اخبار جدید وارد شوید',
                style: TextStyle(color: mutC, fontSize: 13),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _userCtrl,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: txtC),
                decoration: InputDecoration(
                  hintText: 'نام کاربری وردپرس',
                  hintStyle: TextStyle(color: mutC),
                  prefixIcon: Icon(Icons.person, color: accentGreen),
                  filled: true,
                  fillColor: pnl,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: txtC),
                decoration: InputDecoration(
                  hintText: 'Application Password',
                  hintStyle: TextStyle(color: mutC),
                  prefixIcon: Icon(Icons.key, color: accentGreen),
                  filled: true,
                  fillColor: pnl,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'ورود',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ==================== ADMIN PANEL PAGE ==================== */

class AdminPanelPage extends StatefulWidget {
  final String username;
  final String password;
  const AdminPanelPage({
    super.key,
    required this.username,
    required this.password,
  });
  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _sending = false;
  late Future<List> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = getNewNewsList();
  }

  void _reloadList() {
    setState(() {
      _newsFuture = getNewNewsList();
    });
  }

  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      _snack('عنوان و متن خبر را وارد کنید.', Colors.orange);
      return;
    }
    setState(() => _sending = true);
    try {
      await postNewNews(
        username: widget.username,
        appPassword: widget.password,
        title: title,
        content: content,
      );
      if (!mounted) return;
      _snack('✅ خبر جدید منتشر شد!', Colors.green);
      _titleCtrl.clear();
      _contentCtrl.clear();
      _reloadList();
    } catch (e) {
      if (!mounted) return;
      _snack('❌ خطا: ${e.toString().replaceFirst('Exception: ', '')}', Colors.red);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(dynamic post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pnl,
        title: Text('حذف خبر', style: TextStyle(color: txtC)),
        content: Text(
          'آیا از حذف «${pTitle(post)}» مطمئن هستید؟',
          style: TextStyle(color: mutC),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('انصراف', style: TextStyle(color: mutC)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await deleteNews(
        username: widget.username,
        appPassword: widget.password,
        postId: post['id'],
      );
      if (!mounted) return;
      _snack('🗑 خبر حذف شد.', Colors.blueGrey);
      _reloadList();
    } catch (e) {
      if (!mounted) return;
      _snack('❌ خطا: ${e.toString().replaceFirst('Exception: ', '')}', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        appBar: AppBar(
          title: const Text('پنل مدیریت'),
          backgroundColor: bgC,
          foregroundColor: txtC,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentBlue.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: accentBlue, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'خبر جدید پس از انتشار، در سایت و بالای صفحه اصلی اپ نمایش داده می‌شود و تا زمانی که شما حذف نکنید باقی می‌ماند.',
                        style: TextStyle(color: txtC, fontSize: 12, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'عنوان خبر',
                style: TextStyle(
                  color: accentGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(color: txtC, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'مثلاً: ثبت‌نام دوره جدید آغاز شد',
                  hintStyle: TextStyle(color: mutC),
                  filled: true,
                  fillColor: pnl,
                  contentPadding: const EdgeInsets.all(15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'متن کامل خبر',
                style: TextStyle(
                  color: accentGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentCtrl,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 6,
                style: TextStyle(color: txtC, fontSize: 14, height: 1.8),
                decoration: InputDecoration(
                  hintText: 'توضیحات کامل خبر...',
                  hintStyle: TextStyle(color: mutC),
                  filled: true,
                  fillColor: pnl,
                  contentPadding: const EdgeInsets.all(15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 22),
                  label: Text(
                    _sending ? 'در حال ارسال...' : 'انتشار خبر جدید',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Divider(color: lineC),
              const SizedBox(height: 12),

              Text(
                'اخبار منتشر شده',
                style: TextStyle(
                  color: txtC,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              FutureBuilder<List>(
                future: _newsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(color: accentGreen),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'خطا: ${snapshot.error}',
                      style: const TextStyle(color: Colors.orange),
                    );
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'هنوز خبری منتشر نشده است.',
                          style: TextStyle(color: mutC),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: list.map((p) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: pnl,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: lineC),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pTitle(p),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: txtC,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      height: 1.6,
                                    ),
                                  ),
                                  if (pDate(p).isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      pDate(p),
                                      style: TextStyle(color: mutC, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _delete(p),
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'حذف',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/* ==================== COMMON WIDGETS ==================== */

// هدر معمولی (بدون دکمه ادمین)
Widget _header(BuildContext context, [String? t]) {
  return SafeArea(
    bottom: false,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgC,
        border: Border(bottom: BorderSide(color: lineC)),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: lineC, width: 1),
            ),
            child: ClipOval(
              child: Image.asset(
                logo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  logoNet,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.sports, color: accentGreen),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t ?? 'اپلیکیشن تربیت بدنی و علوم ورزشی',
              textAlign: TextAlign.right,
              style: TextStyle(color: txtC, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () async {
              darkModeNotifier.value = !darkModeNotifier.value;
              await _storage.write(
                key: 'dark_mode',
                value: darkModeNotifier.value.toString(),
              );
            },
            icon: ValueListenableBuilder<bool>(
              valueListenable: darkModeNotifier,
              builder: (c, isDark, _) => Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: gold,
                size: 26,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
            icon: Icon(Icons.search, color: gold, size: 26),
          ),
        ],
      ),
    ),
  );
}

// هدر با دکمه پنل ادمین (برای صفحه حساب من)
Widget _headerWithAdmin(BuildContext context, [String? t]) {
  return SafeArea(
    bottom: false,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgC,
        border: Border(bottom: BorderSide(color: lineC)),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: lineC, width: 1),
            ),
            child: ClipOval(
              child: Image.asset(
                logo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  logoNet,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.sports, color: accentGreen),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t ?? 'اپلیکیشن تربیت بدنی و علوم ورزشی',
              textAlign: TextAlign.right,
              style: TextStyle(color: txtC, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          // دکمه پنل ادمین
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLoginPage()),
            ),
            icon: Icon(Icons.admin_panel_settings, color: accentBlue, size: 26),
            tooltip: 'پنل مدیریت',
          ),
          IconButton(
            onPressed: () async {
              darkModeNotifier.value = !darkModeNotifier.value;
              await _storage.write(
                key: 'dark_mode',
                value: darkModeNotifier.value.toString(),
              );
            },
            icon: ValueListenableBuilder<bool>(
              valueListenable: darkModeNotifier,
              builder: (c, isDark, _) => Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: gold,
                size: 26,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
            icon: Icon(Icons.search, color: gold, size: 26),
          ),
        ],
      ),
    ),
  );
}

/* ==================== HERO (با عکس) ==================== */
Widget _hero() {
  return Container(
    margin: const EdgeInsets.fromLTRB(14, 18, 14, 10),
    decoration: BoxDecoration(
      color: pnl,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: lineC),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        heroImg,
        fit: BoxFit.cover,
        width: double.infinity,
        filterQuality: FilterQuality.high,
        loadingBuilder: (c, ch, pr) {
          if (pr == null) return ch;
          return Container(
            height: 180,
            color: pnl2,
            child: Center(child: CircularProgressIndicator(color: accentGreen)),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: 180,
          color: pnl2,
          child: Icon(Icons.sports_soccer, color: accentGreen, size: 60),
        ),
      ),
    ),
  );
}

/* ==================== SERVICES ==================== */
Widget _services() {
  final items = [
    ['معرفی رشته', Icons.info_outline, '$site/introduction-to-the-field-of-physical-education-and-sports-sciences/'],
    ['گرایش‌های ارشد', Icons.school_outlined, '$site/master-of-sports-science-resources/'],
    ['گرایش‌های دکتری', Icons.account_balance_outlined, '$site/sports-science-phd-exam-resources/'],
    ['منابع ارشد', Icons.menu_book_outlined, '$site/master-of-sports-science-resources/'],
    ['منابع دکتری', Icons.library_books_outlined, '$site/manabe-konkur-doctori-tarbiat-badani/'],
    ['دانشگاه‌های برتر', Icons.account_balance, '$site/physical-education-sports-science/'],
    ['بازار کار', Icons.work_outline, '$site/job-market-in-physical-education-and-sports-sciences/'],
    ['طرح درس', Icons.assignment_outlined, '$site/product-category/%d8%b7%d8%b1%d8%ad-%d8%af%d8%b1%d8%b3/'],
    ['پاورپوینت', Icons.slideshow_outlined, '$site/product-category/powerpoint/'],
  ];
  return Column(
    children: [
      const _SectionTitle('خدمات ما', Icons.apps),
      SizedBox(
        height: 112,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (c, i) => GestureDetector(
            onTap: () => openUrl(items[i][2] as String),
            child: Container(
              width: 112,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pnl,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: lineC),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(items[i][1] as IconData, color: accentBlue, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    items[i][0] as String,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: txtC, fontSize: 12, fontWeight: FontWeight.bold, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
    ],
  );
}

/* ==================== FEATURED POST ==================== */
Widget _featuredPost(BuildContext context, dynamic p) {
  final img = pImg(p);
  final title = pTitle(p);
  final date = pDate(p);

  return GestureDetector(
    onTap: () => openUrl(pLink(p)),
    child: Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 200,
              child: img.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      placeholder: (_, __) => Container(
                        color: pnl2,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentGreen,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: pnl2,
                        child: Icon(Icons.article_outlined, color: accentGreen, size: 60),
                      ),
                    )
                  : Container(
                      color: pnl2,
                      child: Icon(Icons.article_outlined, color: accentGreen, size: 60),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'جدیدترین',
                    style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: txtC, fontSize: 17, fontWeight: FontWeight.bold, height: 1.6),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: mutC, size: 13),
                      const SizedBox(width: 5),
                      Text(date, style: TextStyle(color: mutC, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/* ==================== POST (لیست معمولی) ==================== */
Widget _post(BuildContext context, dynamic p) {
  final i = pImg(p);
  final date = pDate(p);
  return GestureDetector(
    onTap: () => openUrl(pLink(p)),
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: lineC),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            child: SizedBox(
              width: 125, height: 110,
              child: i.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: i,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (_, __) => Container(
                        color: pnl2,
                        child: Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: accentGreen),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: pnl2,
                        child: Icon(Icons.article_outlined, color: accentGreen, size: 40),
                      ),
                    )
                  : Container(
                      color: pnl2,
                      child: Icon(Icons.article_outlined, color: accentGreen, size: 40),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pTitle(p),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: txtC, fontSize: 14, fontWeight: FontWeight.bold, height: 1.7),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(date, style: TextStyle(color: mutC, fontSize: 11)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/* ==================== PRODUCT ==================== */
Widget _product(BuildContext context, dynamic p) {
  final img = (p['images'] as List?)?.isNotEmpty == true
      ? (p['images'][0]['src'] ?? '')
      : '';
  final name = p['name'] ?? '';
  final link = p['permalink'] ?? '';
  final inStock = p['stock_status'] == 'instock';
  final regularPrice = p['regular_price'] ?? '';
  final salePrice = p['sale_price'] ?? '';
  final isOnSale = salePrice.isNotEmpty && salePrice != regularPrice;

  return GestureDetector(
    onTap: () => openUrl(link),
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: lineC),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            child: SizedBox(
              width: 125, height: 130,
              child: img.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (_, __) => Container(
                        color: pnl2,
                        child: Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: accentGreen),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: pnl2,
                        child: Icon(Icons.shopping_bag_outlined, color: accentGreen, size: 40),
                      ),
                    )
                  : Container(
                      color: pnl2,
                      child: Icon(Icons.shopping_bag_outlined, color: accentGreen, size: 40),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: txtC, fontSize: 14, fontWeight: FontWeight.bold, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  if (isOnSale) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'تخفیف',
                            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatPrice(regularPrice),
                          style: TextStyle(
                            color: mutC,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(salePrice),
                      style: TextStyle(color: txtC, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ] else if (regularPrice.isNotEmpty) ...[
                    Text(
                      formatPrice(regularPrice),
                      style: TextStyle(color: txtC, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ] else ...[
                    Text(
                      'قیمت نامشخص',
                      style: TextStyle(color: mutC, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        inStock ? Icons.check_circle : Icons.cancel,
                        color: inStock ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        inStock ? 'موجود' : 'ناموجود',
                        style: TextStyle(
                          color: inStock ? Colors.green : Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/* ==================== CAT GRID ==================== */
Widget _catGrid() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (c, i) => GestureDetector(
        onTap: () => Navigator.push(
          c,
          MaterialPageRoute(builder: (_) => CategoryPostsPage(c: cats[i])),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: pnl,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: lineC),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cats[i].i, color: accentGreen, size: 24),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: Text(
                    cats[i].n,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: txtC, fontSize: 12, fontWeight: FontWeight.bold, height: 1.5),
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

/* ==================== SOCIAL ==================== */
Widget _social() {
  final items = [
    ['تلگرام', Icons.send, 'https://t.me/itarbiatbadani'],
    ['اینستاگرام', Icons.camera_alt_outlined, 'https://instagram.com/itarbiatbadani'],
    ['بله', Icons.chat_outlined, 'https://ble.ir/itarbiatbadani'],
    ['فروشگاه', Icons.shopping_cart, '$site/shop/'],
  ];
  return Column(
    children: [
      const _SectionTitle('ارتباط با ما', Icons.connect_without_contact),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.2,
          ),
          itemBuilder: (c, i) => GestureDetector(
            onTap: () => openUrl(items[i][2] as String),
            child: Container(
              decoration: BoxDecoration(
                color: pnl,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lineC),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(items[i][1] as IconData, color: accentBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    items[i][0] as String,
                    style: TextStyle(color: txtC, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

/* ==================== SECTION TITLE ==================== */
class _SectionTitle extends StatelessWidget {
  final String t;
  final IconData i;
  const _SectionTitle(this.t, this.i);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (c, _, __) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
        child: Row(
          children: [
            Container(
              width: 4, height: 25,
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 9),
            Icon(i, color: gold, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t,
                textAlign: TextAlign.right,
                style: TextStyle(color: txtC, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== SKELETON LOADING ==================== */
class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBox({this.width = double.infinity, this.height = 16, this.radius = 8});
  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: skeletonC,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class _PostSkeleton extends StatelessWidget {
  const _PostSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: lineC),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            child: const _SkeletonBox(width: 125, height: 110, radius: 0),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SkeletonBox(height: 14, width: double.infinity),
                  SizedBox(height: 8),
                  _SkeletonBox(height: 14, width: 200),
                  SizedBox(height: 8),
                  _SkeletonBox(height: 12, width: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            child: _SkeletonBox(height: 200, radius: 0),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SkeletonBox(height: 16, width: double.infinity),
                SizedBox(height: 8),
                _SkeletonBox(height: 16, width: 220),
                SizedBox(height: 10),
                _SkeletonBox(height: 12, width: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== LOADING / EMPTY / ERROR ==================== */
class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(35),
        child: Center(child: CircularProgressIndicator(color: accentGreen)),
      );
}

class _Empty extends StatelessWidget {
  final String t;
  const _Empty(this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Center(child: Text(t, style: TextStyle(color: mutC))),
      );
}

class _ErrorBox extends StatelessWidget {
  final String m;
  final VoidCallback? r;
  const _ErrorBox(this.m, this.r);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(m, textAlign: TextAlign.center, style: TextStyle(color: txtC)),
          if (r != null) ...[
            const SizedBox(height: 15),
            ElevatedButton(onPressed: r, child: const Text('تلاش مجدد')),
          ],
        ],
      ),
    );
  }
}
