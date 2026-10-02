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
Color get inkSoft => darkModeNotifier.value ? const Color(0xff9fb0bd) : const Color(0xff526478);
Color get softLine => darkModeNotifier.value ? const Color(0xff1a3a5c) : const Color(0xfff4f7fb);

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
  Cat('تکنولوژی و نوآوری در ورزش', 'technology-and-innovation-in-sports', Icons.memory_outlined),
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

String pExcerpt(dynamic p, {int maxChars = 200}) {
  try {
    String raw = p['excerpt']?['rendered'] ?? '';
    if (raw.isEmpty) raw = p['content']?['rendered'] ?? '';
    final text = clean(raw);
    if (text.length > maxChars) return '${text.substring(0, maxChars)}...';
    return text;
  } catch (_) { return ''; }
}

String pCategory(dynamic p) {
  try {
    final terms = p['_embedded']?['wp:term'];
    if (terms is List && terms.isNotEmpty) {
      final catList = terms[0];
      if (catList is List && catList.isNotEmpty) return catList[0]['name'] ?? '';
    }
  } catch (_) {}
  return '';
}

String pAuthor(dynamic p) {
  try {
    final a = p['_embedded']?['author'];
    if (a is List && a.isNotEmpty) return a[0]['name'] ?? '';
  } catch (_) {}
  return '';
}

String pAuthorAvatar(dynamic p) {
  try {
    final a = p['_embedded']?['author'];
    if (a is List && a.isNotEmpty) return a[0]['avatar_urls']?['48'] ?? '';
  } catch (_) {}
  return '';
}

String pDate(dynamic p) {
  try {
    final d = DateTime.parse(p['date']).toLocal();
    final j = _toJalali(d.year, d.month, d.day);
    return '${j[2]} ${_monthName(j[1])} ${j[0]}';
  } catch (_) { return ''; }
}

String _monthName(int m) {
  const months = ['فروردین','اردیبهشت','خرداد','تیر','مرداد','شهریور',
                  'مهر','آبان','آذر','دی','بهمن','اسفند'];
  if (m >= 1 && m <= 12) return months[m - 1];
  return '';
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

/// ⭐ بهینه‌سازی شده: فقط featuredmedia برای کاهش حجم پاسخ
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
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              },
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
        backgroundColor: bgC,
        body: IndexedStack(
          index: _i,
          children: const [
            Home(),
            ArticlesPage(),
            NewsPage(),
            ShopPage(),
            AccountPage(),
          ],
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
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'مقالات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'اخبار',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'فروشگاه',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'حساب من',
            ),
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
    _f = getPostsPaged(perPage: 5, page: 1);
  }

  Future<void> _refresh() async {
    setState(() {
      _f = getPostsPaged(perPage: 5, page: 1);
      _bannerKey = UniqueKey();
    });
    try {
      await _f;
    } catch (_) {}
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
            SliverToBoxAdapter(child: buildHeader(context)),
            SliverToBoxAdapter(child: buildHero()),
            SliverToBoxAdapter(child: NewNewsBanner(key: _bannerKey)),
            const SliverToBoxAdapter(child: ServicesSectionWidget()),
            SliverToBoxAdapter(child: LatestPostsSection(postsFuture: _f)),
            const SliverToBoxAdapter(
              child: SectionTitleWidget(
                title: 'دسته‌بندی مقالات',
                icon: Icons.grid_view_rounded,
              ),
            ),
            SliverToBoxAdapter(child: buildCatGrid()),
            SliverToBoxAdapter(child: buildSocial()),
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
  final _scroll = ScrollController(keepScrollOffset: false);

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
              _scroll.position.maxScrollExtent - 300 &&
          !_loading &&
          _hasMore) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _posts.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        body: Column(
          children: [
            buildHeader(context, 'مقالات'),
            Expanded(
              child: _posts.isEmpty && _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Column(
                        children: [
                          PostSkeleton(),
                          PostSkeleton(),
                          PostSkeleton(),
                          PostSkeleton(),
                          PostSkeleton(),
                        ],
                      ),
                    )
                  : _posts.isEmpty && _error != null
                      ? ErrorBox(
                          message: 'خطا در دریافت مقالات.\n$_error',
                          onRetry: _refresh,
                        )
                      : _posts.isEmpty
                          ? const EmptyWidget(text: 'مقاله‌ای پیدا نشد.')
                          : RefreshIndicator(
                              color: accentGreen,
                              backgroundColor: pnl,
                              onRefresh: _refresh,
                              child: ListView.builder(
                                controller: _scroll,
                                cacheExtent: 800,
                                padding: const EdgeInsets.all(14),
                                itemCount:
                                    _posts.length + (_hasMore ? 1 : 0),
                                itemBuilder: (c, i) {
                                  if (i >= _posts.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: accentGreen,
                                        ),
                                      ),
                                    );
                                  }
                                  return buildPostCard(context, _posts[i]);
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
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int? _catId;
  final _scroll = ScrollController(keepScrollOffset: false);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      _catId = await getCatIdBySlug(widget.c.s);
      if (_catId == null) throw Exception('دسته‌بندی یافت نشد');
      await _loadFirst();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadFirst() async {
    try {
      final list = await getPostsPaged(
        perPage: 5,
        page: 1,
        catId: _catId,
      );
      if (!mounted) return;
      setState(() {
        _posts.clear();
        _posts.addAll(list);
        _page = 1;
        _hasMore = list.length >= 5;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final list = await getPostsPaged(
        perPage: 5,
        page: nextPage,
        catId: _catId,
      );
      if (!mounted) return;
      setState(() {
        if (list.isEmpty) {
          _hasMore = false;
        } else {
          _posts.addAll(list);
          _page = nextPage;
          if (list.length < 5) _hasMore = false;
        }
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _posts.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _loadFirst();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Text(
            widget.c.n,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
        ),
        body: RefreshIndicator(
          color: accentGreen,
          backgroundColor: pnl,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                if (_posts.isNotEmpty || _loading)
                  const SectionTitleWidget(
                    title: 'جدیدترین نوشته‌ها',
                    icon: Icons.article_outlined,
                  ),

                if (_posts.isEmpty && _loading)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      children: [
                        FeaturedSkeleton(),
                        SizedBox(height: 12),
                        PostSkeleton(),
                        SizedBox(height: 12),
                        PostSkeleton(),
                      ],
                    ),
                  )
                else if (_posts.isEmpty && _error != null)
                  ErrorBox(
                    message: 'خطا در دریافت مطالب.\n$_error',
                    onRetry: _refresh,
                  )
                else if (_posts.isEmpty)
                  const EmptyWidget(text: 'مطلبی در این دسته پیدا نشد.')
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        FeaturedPostCard(post: _posts.first),
                        const SizedBox(height: 14),
                        ..._posts.skip(1).map((post) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SidePostCard(post: post),
                          );
                        }).toList(),
                        if (_hasMore)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 6, bottom: 6),
                            child: _buildLoadMoreButton(),
                          ),
                        if (!_hasMore && _posts.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 12, bottom: 30),
                            child: Text(
                              'همه مطالب نمایش داده شد.',
                              style: TextStyle(
                                color: mutC,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    final isDark = darkModeNotifier.value;

    return GestureDetector(
      onTap: _loadingMore ? null : _loadMore,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 26, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? pnl2 : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark ? lineC : const Color(0xffe9edf3),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loadingMore)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xff4caf50),
                ),
              )
            else
              Icon(
                Icons.arrow_back_ios_new,
                size: 12,
                color: isDark ? txtC : const Color(0xff0f1a2b),
              ),
            const SizedBox(width: 8),
            Text(
              _loadingMore ? 'در حال بارگذاری...' : 'مشاهده بیشتر',
              style: TextStyle(
                color: isDark ? txtC : const Color(0xff0f1a2b),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== SUB CATEGORY POSTS PAGE ==================== */

class SubCategoryPostsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String categorySlug;
  const SubCategoryPostsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
  });
  @override
  State<SubCategoryPostsPage> createState() => _SubCategoryPostsPageState();
}

class _SubCategoryPostsPageState extends State<SubCategoryPostsPage> {
  final _posts = <dynamic>[];
  int _page = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  final _scroll = ScrollController(keepScrollOffset: false);

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _loadFirst() async {
    setState(() => _loading = true);
    try {
      final list = await getPostsPaged(
        perPage: 5,
        page: 1,
        catId: widget.categoryId,
      );
      if (!mounted) return;
      setState(() {
        _posts.clear();
        _posts.addAll(list);
        _page = 1;
        _hasMore = list.length >= 5;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final list = await getPostsPaged(
        perPage: 5,
        page: nextPage,
        catId: widget.categoryId,
      );
      if (!mounted) return;
      setState(() {
        if (list.isEmpty) {
          _hasMore = false;
        } else {
          _posts.addAll(list);
          _page = nextPage;
          if (list.length < 5) _hasMore = false;
        }
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    await _loadFirst();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Text(
            widget.categoryName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
        ),
        body: RefreshIndicator(
          color: accentGreen,
          backgroundColor: pnl,
          onRefresh: _refresh,
          child: _posts.isEmpty && _loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    children: [
                      FeaturedSkeleton(),
                      SizedBox(height: 12),
                      PostSkeleton(),
                      SizedBox(height: 12),
                      PostSkeleton(),
                    ],
                  ),
                )
              : _posts.isEmpty && _error != null
                  ? ErrorBox(
                      message: 'خطا در دریافت مطالب.\n$_error',
                      onRetry: _refresh,
                    )
                  : _posts.isEmpty
                      ? const EmptyWidget(text: 'مطلبی پیدا نشد.')
                      : SingleChildScrollView(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Column(
                            children: [
                              FeaturedPostCard(post: _posts.first),
                              const SizedBox(height: 14),
                              ..._posts.skip(1).map((post) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: SidePostCard(post: post),
                                );
                              }).toList(),
                              if (_hasMore)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 6, bottom: 6),
                                  child: _buildLoadMoreButton(),
                                ),
                              if (!_hasMore && _posts.length > 5)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 12, bottom: 30),
                                  child: Text(
                                    'همه مطالب نمایش داده شد.',
                                    style: TextStyle(
                                      color: mutC,
                                      fontSize: 12,
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

  Widget _buildLoadMoreButton() {
    final isDark = darkModeNotifier.value;

    return GestureDetector(
      onTap: _loadingMore ? null : _loadMore,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 26, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? pnl2 : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark ? lineC : const Color(0xffe9edf3),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loadingMore)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xff4caf50),
                ),
              )
            else
              Icon(
                Icons.arrow_back_ios_new,
                size: 12,
                color: isDark ? txtC : const Color(0xff0f1a2b),
              ),
            const SizedBox(width: 8),
            Text(
              _loadingMore ? 'در حال بارگذاری...' : 'مشاهده بیشتر',
              style: TextStyle(
                color: isDark ? txtC : const Color(0xff0f1a2b),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
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
  final _scroll = ScrollController(keepScrollOffset: false);

  @override
  void initState() {
    super.initState();
    _init();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
              _scroll.position.maxScrollExtent - 300 &&
          !_loading &&
          _hasMore) {
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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _load() async {
    if (_loading && _posts.isNotEmpty) return;
    if (!_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await getPostsPaged(
        perPage: perPageSize,
        page: _page,
        catId: _catId,
      );
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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _posts.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        body: Column(
          children: [
            AppBar(
              title: const Text(
                'اخبار و رویدادها',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: bgC,
              foregroundColor: txtC,
              elevation: 0,
            ),
            Expanded(
              child: _posts.isEmpty && _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Column(
                        children: [
                          PostSkeleton(),
                          PostSkeleton(),
                          PostSkeleton(),
                          PostSkeleton(),
                        ],
                      ),
                    )
                  : _posts.isEmpty && _error != null
                      ? ErrorBox(
                          message: 'خطا در دریافت اخبار.\n$_error',
                          onRetry: _refresh,
                        )
                      : _posts.isEmpty
                          ? const EmptyWidget(text: 'خبری پیدا نشد.')
                          : RefreshIndicator(
                              color: accentGreen,
                              backgroundColor: pnl,
                              onRefresh: _refresh,
                              child: ListView.builder(
                                controller: _scroll,
                                cacheExtent: 800,
                                padding: const EdgeInsets.all(14),
                                itemCount:
                                    _posts.length + (_hasMore ? 1 : 0),
                                itemBuilder: (c, i) {
                                  if (i >= _posts.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: accentGreen,
                                        ),
                                      ),
                                    );
                                  }
                                  return buildPostCard(context, _posts[i]);
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
  final _scroll = ScrollController(keepScrollOffset: false);

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
              _scroll.position.maxScrollExtent - 300 &&
          !_loading &&
          _hasMore) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _products.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        body: Column(
          children: [
            buildHeader(context, 'فروشگاه'),
            Expanded(
              child: _products.isEmpty && _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Column(
                        children: [
                          PostSkeleton(),
                          PostSkeleton(),
                          PostSkeleton(),
                          PostSkeleton(),
                        ],
                      ),
                    )
                  : _products.isEmpty && _error != null
                      ? ErrorBox(
                          message: 'خطا در دریافت محصولات.\n$_error',
                          onRetry: _refresh,
                        )
                      : _products.isEmpty
                          ? const EmptyWidget(text: 'محصولی پیدا نشد.')
                          : RefreshIndicator(
                              color: accentGreen,
                              backgroundColor: pnl,
                              onRefresh: _refresh,
                              child: ListView.builder(
                                controller: _scroll,
                                cacheExtent: 800,
                                padding: const EdgeInsets.all(14),
                                itemCount:
                                    _products.length + (_hasMore ? 1 : 0),
                                itemBuilder: (c, i) {
                                  if (i >= _products.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: accentGreen,
                                        ),
                                      ),
                                    );
                                  }
                                  return buildProductCard(
                                      context, _products[i]);
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
        setState(() {
          _q = '';
          _f = null;
        });
        return;
      }
      setState(() {
        _q = q;
        _f = searchExact(q);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: const Text(
            'جستجو',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
        ),
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
                  ? const EmptyWidget(
                      text: 'عبارتی برای جستجو وارد کنید',
                    )
                  : FutureBuilder<List>(
                      future: _f,
                      builder: (c, s) {
                        if (s.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(14),
                            child: Column(
                              children: [
                                PostSkeleton(),
                                PostSkeleton(),
                                PostSkeleton(),
                              ],
                            ),
                          );
                        }
                        if (s.hasError) {
                          return ErrorBox(
                            message: 'خطا در جستجو.\n${s.error}',
                            onRetry: null,
                          );
                        }
                        final posts = s.data ?? [];
                        if (posts.isEmpty) {
                          return EmptyWidget(
                            text: 'نتیجه‌ای برای «$_q» پیدا نشد.',
                          );
                        }
                        return ListView.builder(
                          cacheExtent: 800,
                          padding: const EdgeInsets.all(14),
                          itemCount: posts.length,
                          itemBuilder: (c, i) =>
                              buildPostCard(context, posts[i]),
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
/* ==================== ACCOUNT ==================== */

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
        backgroundColor: bgC,
        body: Column(
          children: [
            buildHeaderWithAdmin(context, 'حساب من'),
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri('$site/my-account/'),
                    ),
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
                      await openUrl(request.url.toString());
                    },
                  ),
                  if (_l)
                    Center(
                      child: CircularProgressIndicator(color: accentGreen),
                    ),
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
  const WebPage({
    super.key,
    required this.url,
    required this.title,
  });
  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  bool _l = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgC,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgC,
        foregroundColor: txtC,
        elevation: 0,
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings:
                InAppWebViewSettings(javaScriptEnabled: true),
            onLoadStart: (c, url) => setState(() => _l = true),
            onLoadStop: (c, url) => setState(() => _l = false),
          ),
          if (_l)
            Center(
              child: CircularProgressIndicator(color: accentGreen),
            ),
        ],
      ),
    );
  }
}

/* ==================== SERVICES SECTION ==================== */

class ServicesSectionWidget extends StatefulWidget {
  const ServicesSectionWidget({super.key});

  @override
  State<ServicesSectionWidget> createState() =>
      _ServicesSectionWidgetState();
}

class _ServicesSectionWidgetState extends State<ServicesSectionWidget> {
  final ScrollController _scrollCtrl = ScrollController();

  final List<Map<String, dynamic>> _items = [
    {
      'title': 'معرفی رشته',
      'icon': Icons.info_outline,
      'color': const Color(0xff1e40af),
      'soft': const Color(0xffeff6ff),
      'url':
          '$site/introduction-to-the-field-of-physical-education-and-sports-sciences/',
    },
    {
      'title': 'گرایش‌های ارشد',
      'icon': Icons.layers_outlined,
      'color': const Color(0xff7c3aed),
      'soft': const Color(0xfff5f3ff),
      'url':
          '$site/%da%af%d8%b1%d8%a7%db%8c%d8%b4%d9%87%d8%a7%db%8c-%da%a9%d8%a7%d8%b1%d8%b4%d9%86%d8%a7%d8%b3%db%8c-%d8%a7%d8%b1%d8%b4%d8%af-%d8%aa%d8%b1%d8%a8%db%8c%d8%aa-%d8%a8%d8%af%d9%86%db%8c-%d9%88/',
    },
    {
      'title': 'گرایش‌های دکتری',
      'icon': Icons.school_outlined,
      'color': const Color(0xff0891b2),
      'soft': const Color(0xffecfeff),
      'url': '$site/sports-science-phd-exam-resources/',
    },
    {
      'title': 'منابع ارشد',
      'icon': Icons.menu_book_outlined,
      'color': const Color(0xff059669),
      'soft': const Color(0xffecfdf5),
      'url': '$site/master-of-sports-science-resources/',
    },
    {
      'title': 'منابع دکتری',
      'icon': Icons.auto_stories_outlined,
      'color': const Color(0xffb45309),
      'soft': const Color(0xfffffbeb),
      'url': '$site/manabe-konkur-doctori-tarbiat-badani/',
    },
    {
      'title': 'منابع استخدامی',
      'icon': Icons.assignment_outlined,
      'color': const Color(0xffe11d48),
      'soft': const Color(0xfffff1f4),
      'url': '$site/employment-tests/',
    },
    {
      'title': 'دانشگاه‌های برتر',
      'icon': Icons.account_balance,
      'color': const Color(0xff2563eb),
      'soft': const Color(0xffeff6ff),
      'url': '$site/physical-education-sports-science/',
    },
    {
      'title': 'بازار کار',
      'icon': Icons.work_outline,
      'color': const Color(0xff0d9488),
      'soft': const Color(0xfff0fdfa),
      'url':
          '$site/job-market-in-physical-education-and-sports-sciences/',
    },
    {
      'title': 'طرح درس',
      'icon': Icons.slideshow_outlined,
      'color': const Color(0xff9333ea),
      'soft': const Color(0xfffaf5ff),
      'url':
          '$site/product-category/%d8%b7%d8%b1%d8%ad-%d8%af%d8%b1%d8%b3-%d8%b1%d9%88%d8%b2%d8%a7%d9%86%d9%87-%d9%85%d8%a7%d9%87%d8%a7%d9%86%d9%87-%d8%b3%d8%a7%d9%84%d8%a7%d9%86%d9%87/',
    },
    {
      'title': 'پاورپوینت',
      'icon': Icons.file_present_outlined,
      'color': const Color(0xffea580c),
      'soft': const Color(0xfffff7ed),
      'url': '$site/product-category/powerpoint/',
    },
  ];

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) {
        final isDark = darkModeNotifier.value;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 22, 14, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Stack(
                  children: [
                    Text(
                      'خدمات ما',
                      style: TextStyle(
                        color: txtC,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: 0,
                      left: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xff1e40af),
                              Color(0xff2563eb),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff2563eb)
                                  .withOpacity(.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: pnl,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: lineC),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0x0c0c2d48),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                    child: SizedBox(
                      height: 130,
                      child: ListView.separated(
                        controller: _scrollCtrl,
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (c, i) =>
                            _buildServiceCard(_items[i]),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: 40,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [pnl, pnl.withOpacity(0)],
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: 40,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [pnl, pnl.withOpacity(0)],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> item) {
    final color = item['color'] as Color;
    final soft = darkModeNotifier.value
        ? color.withOpacity(0.15)
        : item['soft'] as Color;

    return GestureDetector(
      onTap: () => openUrl(item['url'] as String),
      child: Container(
        width: 145,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: darkModeNotifier.value ? pnl2 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: lineC),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: Text(
                  item['title'] as String,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: txtC,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/* ==================== LATEST POSTS SECTION ==================== */

class LatestPostsSection extends StatelessWidget {
  final Future<List>? postsFuture;
  const LatestPostsSection({super.key, required this.postsFuture});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 22, 14, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Stack(
                children: [
                  Text(
                    'جدیدترین نوشته‌ها',
                    style: TextStyle(
                      color: txtC,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: 0,
                    left: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xff059669),
                            Color(0xff047857),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List>(
            future: postsFuture,
            builder: (c, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      FeaturedSkeleton(),
                      SizedBox(height: 12),
                      PostSkeleton(),
                      SizedBox(height: 12),
                      PostSkeleton(),
                    ],
                  ),
                );
              }
              if (s.hasError) {
                return ErrorBox(
                  message: 'خطا در دریافت مطالب.\n${s.error}',
                  onRetry: null,
                );
              }
              final posts = s.data ?? [];
              if (posts.isEmpty) {
                return const EmptyWidget(text: 'مطلبی پیدا نشد.');
              }

              final featured = posts.first;
              final others = posts.skip(1).take(4).toList();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    FeaturedPostCard(post: featured),
                    const SizedBox(height: 14),
                    ...others
                        .map((p) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 10),
                              child: SidePostCard(post: p),
                            ))
                        .toList(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/* ==================== FEATURED POST CARD ==================== */

class FeaturedPostCard extends StatelessWidget {
  final dynamic post;
  const FeaturedPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final title = pTitle(post);
    final link = pLink(post);
    final img = pImg(post);
    final cat = pCategory(post);
    final author = pAuthor(post);
    final avatarUrl = pAuthorAvatar(post);
    final date = pDate(post);
    final excerpt = pExcerpt(post, maxChars: 150);

    return GestureDetector(
      onTap: () => openUrl(link),
      child: Container(
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lineC),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9.5,
                child: img.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: pnl2),
                        errorWidget: (_, __, ___) => Container(
                          color: pnl2,
                          child: Icon(
                            Icons.article_outlined,
                            color: accentGreen,
                            size: 60,
                          ),
                        ),
                      )
                    : Container(
                        color: pnl2,
                        child: Icon(
                          Icons.article_outlined,
                          color: accentGreen,
                          size: 60,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cat.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xffecfdf5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0x3305a669)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xff05a669),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: const TextStyle(
                              color: Color(0xff047857),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: txtC,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.4,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (excerpt.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: inkSoft,
                        fontSize: 13,
                        height: 1.85,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Divider(height: 1, color: softLine),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (avatarUrl.isNotEmpty)
                        ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: pnl2,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person,
                                  color: mutC, size: 20),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: pnl2,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person,
                              color: mutC, size: 20),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (author.isNotEmpty)
                              Text(
                                author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: txtC,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            if (date.isNotEmpty)
                              Text(
                                date,
                                style: TextStyle(
                                  color: mutC,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xffecfdf5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'مطالعه',
                              style: TextStyle(
                                color: Color(0xff047857),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_back,
                              color: Color(0xff047857),
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== SIDE POST CARD ==================== */

class SidePostCard extends StatelessWidget {
  final dynamic post;
  const SidePostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final title = pTitle(post);
    final link = pLink(post);
    final img = pImg(post);
    final cat = pCategory(post);
    final date = pDate(post);

    return GestureDetector(
      onTap: () => openUrl(link),
      child: Container(
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
                  if (cat.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xffecfdf5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xff05a669),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cat,
                            style: const TextStyle(
                              color: Color(0xff047857),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: txtC,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      date,
                      style: TextStyle(
                        color: mutC,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 90,
                height: 70,
                child: img.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: pnl2),
                        errorWidget: (_, __, ___) => Container(
                          color: pnl2,
                          child: Icon(
                            Icons.article_outlined,
                            color: accentGreen,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        color: pnl2,
                        child: Icon(
                          Icons.article_outlined,
                          color: accentGreen,
                          size: 28,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== LIVE DOT ==================== */

class LiveDot extends StatefulWidget {
  const LiveDot({super.key});
  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final scale = 1.0 + (t < 0.5 ? t * 0.5 : (1 - t) * 0.5);
        final opacity = 1.0 - t;
        return SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 16 * scale,
                height: 16 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffff3d00)
                      .withOpacity(opacity * 0.5),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffff3d00),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ==================== URGENT NEWS CARD ==================== */

class UrgentNewsCard extends StatelessWidget {
  final dynamic news;
  const UrgentNewsCard({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final title = pTitle(news);
    final link = pLink(news);
    final date = pDate(news);
    final excerpt = pExcerpt(news, maxChars: 150);

    int readTime = 1;
    try {
      final raw = clean(news['content']['rendered'] ?? '');
      final words = raw
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
      readTime = (words / 200).ceil();
      if (readTime < 1) readTime = 1;
    } catch (_) {}

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => GestureDetector(
        onTap: () => openUrl(link),
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: pnl,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: lineC),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                right: -18,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xff0d47a1),
                        Color(0xff25b8e8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: mutC,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        date,
                        style: TextStyle(
                          color: mutC,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: mutC.withOpacity(.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: mutC,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$readTime دقیقه',
                        style: TextStyle(
                          color: mutC,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: txtC,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.6,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (excerpt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: mutC,
                        fontSize: 12.5,
                        height: 1.8,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: lineC.withOpacity(.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Row(
                        children: [
                          Text(
                            'خواندن کامل',
                            style: TextStyle(
                              color: accentBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_back_ios_new,
                            color: accentBlue,
                            size: 11,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xffff3d00)
                              .withOpacity(.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xffff3d00),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'فوری',
                              style: TextStyle(
                                color: Color(0xffff3d00),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
  late Future<List> _future;

  @override
  void initState() {
    super.initState();
    _future = getNewNewsList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => FutureBuilder<List>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasError) return const SizedBox.shrink();
          final list = snapshot.data ?? [];
          if (list.isEmpty) return const SizedBox.shrink();

          final items = list.take(3).toList();

          return Container(
            margin: const EdgeInsets.only(top: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xff0d47a1),
                                  Color(0xff25b8e8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const LiveDot(),
                          const SizedBox(width: 8),
                          Text(
                            'اخبار فوری',
                            style: TextStyle(
                              color: txtC,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          if (list.length > 3)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const UrgentNewsListPage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      accentBlue.withOpacity(.1),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'مشاهده همه',
                                      style: TextStyle(
                                        color: accentBlue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.arrow_back_ios_new,
                                      color: accentBlue,
                                      size: 11,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: lineC,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...items
                    .map((news) => UrgentNewsCard(news: news))
                    .toList(),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ==================== URGENT NEWS LIST PAGE ==================== */

class UrgentNewsListPage extends StatefulWidget {
  const UrgentNewsListPage({super.key});
  @override
  State<UrgentNewsListPage> createState() => _UrgentNewsListPageState();
}

class _UrgentNewsListPageState extends State<UrgentNewsListPage> {
  late Future<List> _future;

  @override
  void initState() {
    super.initState();
    _future = getNewNewsList();
  }

  Future<void> _refresh() async {
    final f = getNewNewsList();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              const LiveDot(),
              const SizedBox(width: 8),
              Text(
                'اخبار فوری',
                style: TextStyle(
                  color: txtC,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
        ),
        body: RefreshIndicator(
          color: accentGreen,
          backgroundColor: pnl,
          onRefresh: _refresh,
          child: FutureBuilder<List>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      PostSkeleton(),
                      PostSkeleton(),
                      PostSkeleton(),
                    ],
                  ),
                );
              }
              if (snapshot.hasError) {
                return ErrorBox(
                  message:
                      'خطا در دریافت اخبار.\n${snapshot.error}',
                  onRetry: _refresh,
                );
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const EmptyWidget(
                  text: 'هنوز خبری منتشر نشده است.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 14),
                itemCount: list.length,
                itemBuilder: (c, i) =>
                    UrgentNewsCard(news: list[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}
/* ==================== ADMIN LOGIN ==================== */

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _rememberMe = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final savedUser = await _storage.read(key: 'admin_username');
      final savedPass = await _storage.read(key: 'admin_password');
      if (savedUser != null && savedUser.isNotEmpty) {
        _userCtrl.text = savedUser;
        if (savedPass != null && savedPass.isNotEmpty) {
          _passCtrl.text = savedPass;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveCredentials(String user, String pass) async {
    try {
      if (_rememberMe) {
        await _storage.write(key: 'admin_username', value: user);
        await _storage.write(key: 'admin_password', value: pass);
      } else {
        await _storage.delete(key: 'admin_username');
        await _storage.delete(key: 'admin_password');
      }
    } catch (_) {}
  }

  Future<void> _clearSavedCredentials() async {
    try {
      await _storage.delete(key: 'admin_username');
      await _storage.delete(key: 'admin_password');
      _userCtrl.clear();
      _passCtrl.clear();
      setState(() {});
      _snack('اطلاعات ورود پاک شد.');
    } catch (_) {}
  }

  Future<void> _login() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (user.isEmpty || pass.isEmpty) {
      setState(() => _error = 'نام کاربری و رمز را وارد کنید.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await verifyAdmin(username: user, appPassword: pass);
      await _saveCredentials(user, pass);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminPanelPage(
            username: user,
            password: pass,
          ),
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: accentBlue,
        duration: const Duration(seconds: 2),
      ),
    );
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
        backgroundColor: bgC,
        appBar: AppBar(
          title: const Text(
            'ورود ادمین',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _clearSavedCredentials,
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.red,
              ),
              tooltip: 'پاک کردن اطلاعات ذخیره‌شده',
            ),
          ],
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
                child: Icon(
                  Icons.lock_outline,
                  color: gold,
                  size: 40,
                ),
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
                'برای مدیریت اخبار فوری وارد شوید',
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
                  prefixIcon:
                      Icon(Icons.person, color: accentGreen),
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
                obscureText: _obscure,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: txtC),
                decoration: InputDecoration(
                  hintText: 'Application Password',
                  hintStyle: TextStyle(color: mutC),
                  prefixIcon: Icon(Icons.key, color: accentGreen),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: mutC,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: pnl,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () =>
                    setState(() => _rememberMe = !_rememberMe),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: pnl,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _rememberMe
                              ? accentGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _rememberMe ? accentGreen : mutC,
                            width: 1.5,
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'مرا به خاطر بسپار',
                        style: TextStyle(
                          color: txtC,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.lock_outline,
                          color: mutC, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'ذخیره امن',
                        style:
                            TextStyle(color: mutC, fontSize: 10),
                      ),
                    ],
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
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: accentBlue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'اطلاعات ورود شما به‌صورت رمزنگاری‌شده روی دستگاه ذخیره می‌شود.',
                        style: TextStyle(
                          color: mutC,
                          fontSize: 11,
                          height: 1.6,
                        ),
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
}

/* ==================== ADMIN PANEL ==================== */

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
      _snack('✅ خبر فوری منتشر شد!', Colors.green);
      _titleCtrl.clear();
      _contentCtrl.clear();
      _reloadList();
    } catch (e) {
      if (!mounted) return;
      _snack(
        '❌ خطا: ${e.toString().replaceFirst('Exception: ', '')}',
        Colors.red,
      );
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
            child: Text('انصراف',
                style: TextStyle(color: mutC)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.red),
            ),
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
      _snack(
        '❌ خطا: ${e.toString().replaceFirst('Exception: ', '')}',
        Colors.red,
      );
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
        backgroundColor: bgC,
        appBar: AppBar(
          title: const Text(
            'پنل مدیریت اخبار فوری',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
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
                  border: Border.all(
                    color: accentBlue.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: accentBlue, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'خبر فوری پس از انتشار، در سایت و بالای صفحه اصلی اپ نمایش داده می‌شود و تا زمانی که شما حذف نکنید باقی می‌ماند.',
                        style: TextStyle(
                          color: txtC,
                          fontSize: 12,
                          height: 1.6,
                        ),
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
                style: TextStyle(
                  color: txtC,
                  fontSize: 14,
                  height: 1.8,
                ),
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
                    _sending ? 'در حال ارسال...' : 'انتشار خبر فوری',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: accentGreen,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'خطا: ${snapshot.error}',
                      style:
                          const TextStyle(color: Colors.orange),
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
                        margin:
                            const EdgeInsets.only(bottom: 10),
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pTitle(p),
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow.ellipsis,
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
                                      style: TextStyle(
                                        color: mutC,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _delete(p),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
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
/* ==================== HEADER ==================== */

Widget buildHeader(BuildContext context, [String? t]) {
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
            width: 46,
            height: 46,
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
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.sports, color: accentGreen),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t ?? 'اپلیکیشن تربیت بدنی و علوم ورزشی',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: txtC,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
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

Widget buildHeaderWithAdmin(BuildContext context, [String? t]) {
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
            width: 46,
            height: 46,
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
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.sports, color: accentGreen),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t ?? 'اپلیکیشن تربیت بدنی و علوم ورزشی',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: txtC,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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

/* ==================== HERO ==================== */

Widget buildHero() {
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
            child: Center(
              child: CircularProgressIndicator(color: accentGreen),
            ),
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

/* ==================== POST CARD ==================== */

Widget buildPostCard(BuildContext context, dynamic p) {
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
              width: 125,
              height: 110,
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
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentGreen,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: pnl2,
                        child: Icon(
                          Icons.article_outlined,
                          color: accentGreen,
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: pnl2,
                      child: Icon(
                        Icons.article_outlined,
                        color: accentGreen,
                        size: 40,
                      ),
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
                    style: TextStyle(
                      color: txtC,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.7,
                    ),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      date,
                      style: TextStyle(color: mutC, fontSize: 11),
                    ),
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

/* ==================== PRODUCT CARD ==================== */

Widget buildProductCard(BuildContext context, dynamic p) {
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
              width: 125,
              height: 130,
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
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentGreen,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: pnl2,
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: accentGreen,
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: pnl2,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: accentGreen,
                        size: 40,
                      ),
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
                    style: TextStyle(
                      color: txtC,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isOnSale) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'تخفیف',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
                      style: TextStyle(
                        color: txtC,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else if (regularPrice.isNotEmpty) ...[
                    Text(
                      formatPrice(regularPrice),
                      style: TextStyle(
                        color: txtC,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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

Widget buildCatGrid() {
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
                width: 46,
                height: 46,
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
                    style: TextStyle(
                      color: txtC,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
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

Widget buildSocial() {
  final items = [
    ['تلگرام', Icons.send, 'https://t.me/itarbiatbadani'],
    ['اینستاگرام', Icons.camera_alt_outlined,
        'https://instagram.com/itarbiatbadani'],
    ['بله', Icons.chat_outlined, 'https://ble.ir/itarbiatbadani'],
    ['فروشگاه', Icons.shopping_cart, '$site/shop/'],
  ];
  return Column(
    children: [
      const SectionTitleWidget(
        title: 'ارتباط با ما',
        icon: Icons.connect_without_contact,
      ),
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
                    style: TextStyle(
                      color: txtC,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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

class SectionTitleWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  const SectionTitleWidget({
    super.key,
    required this.title,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (c, _, __) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 25,
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 9),
            Icon(icon, color: gold, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: txtC,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== SKELETON ==================== */

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });
  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
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

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

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
            child: const SkeletonBox(width: 125, height: 110, radius: 0),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 14, width: double.infinity),
                  SizedBox(height: 8),
                  SkeletonBox(height: 14, width: 200),
                  SizedBox(height: 8),
                  SkeletonBox(height: 12, width: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeaturedSkeleton extends StatelessWidget {
  const FeaturedSkeleton({super.key});

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
            child: SkeletonBox(height: 200, radius: 0),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 16, width: double.infinity),
                SizedBox(height: 8),
                SkeletonBox(height: 16, width: 220),
                SizedBox(height: 10),
                SkeletonBox(height: 12, width: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== EMPTY / ERROR ==================== */

class EmptyWidget extends StatelessWidget {
  final String text;
  const EmptyWidget({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Text(text, style: TextStyle(color: mutC)),
      ),
    );
  }
}

class ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorBox({
    super.key,
    required this.message,
    this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: txtC),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('تلاش مجدد'),
            ),
          ],
        ],
      ),
    );
  }
}
