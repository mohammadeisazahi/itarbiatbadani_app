import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
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
final bookmarkNotifier = ValueNotifier<Set<String>>({});

/* ==================== THEME COLORS ==================== */

Color get bgC => darkModeNotifier.value ? const Color(0xff0b1220) : const Color(0xfff6f8fb);
Color get bgGrad1 => darkModeNotifier.value ? const Color(0xff0b1220) : const Color(0xfff6f8fb);
Color get bgGrad2 => darkModeNotifier.value ? const Color(0xff101a2e) : const Color(0xffeef3fb);
Color get pnl => darkModeNotifier.value ? const Color(0xff141f36) : const Color(0xffffffff);
Color get pnl2 => darkModeNotifier.value ? const Color(0xff1c2b48) : const Color(0xffeef3fa);
Color get pnl3 => darkModeNotifier.value ? const Color(0xff243456) : const Color(0xffe3ecf7);
Color get txtC => darkModeNotifier.value ? const Color(0xfff1f5fb) : const Color(0xff0c1a2b);
Color get mutC => darkModeNotifier.value ? const Color(0xff8fa3bf) : const Color(0xff5c6b83);
Color get accentGreen => const Color(0xff10b981);
Color get accentGreen2 => const Color(0xff059669);
Color get accentBlue => const Color(0xff3b82f6);
Color get accentBlue2 => const Color(0xff1d4ed8);
Color get gold => darkModeNotifier.value ? const Color(0xfffbbf24) : const Color(0xffd97706);
Color get rose => const Color(0xfff43f5e);
Color get purple => const Color(0xff8b5cf6);
Color get lineC => darkModeNotifier.value ? const Color(0xff223252) : const Color(0xffe4ebf4);
Color get navBg => darkModeNotifier.value ? const Color(0xff0f1a2e) : const Color(0xffffffff);
Color get skeletonBase => darkModeNotifier.value ? const Color(0xff1a2740) : const Color(0xffeaf0f8);
Color get skeletonHi => darkModeNotifier.value ? const Color(0xff253556) : const Color(0xfff5f9ff);
Color get inkSoft => darkModeNotifier.value ? const Color(0xff9db0ca) : const Color(0xff54637a);
Color get softLine => darkModeNotifier.value ? const Color(0xff223252) : const Color(0xffeef3fa);
Color get chipBg => darkModeNotifier.value ? const Color(0xff132a45) : const Color(0xffecfdf5);
Color get chipFg => darkModeNotifier.value ? const Color(0xff34d399) : const Color(0xff047857);

/* ==================== MODELS ==================== */

class Cat {
  final String n;
  final String s;
  final IconData i;
  final Color c;
  const Cat(this.n, this.s, this.i, this.c);
}

const cats = <Cat>[
  Cat('رشته تربیت بدنی و علوم ورزشی', 'physical-education-sport-sciences', Icons.sports_soccer_rounded, Color(0xff3b82f6)),
  Cat('علوم ورزشی', 'sports-science', Icons.science_rounded, Color(0xff8b5cf6)),
  Cat('منابع آزمون‌ها', 'sports-science-exam-resources', Icons.menu_book_rounded, Color(0xfff59e0b)),
  Cat('تغذیه ورزشی', 'sports-nutrition', Icons.restaurant_rounded, Color(0xff10b981)),
  Cat('اخبار و رویدادها', 'sports-news-and-events', Icons.newspaper_rounded, Color(0xffef4444)),
  Cat('ورزش همگانی', 'public-exercise-health-and-wellness', Icons.favorite_rounded, Color(0xffec4899)),
  Cat('پژوهش در تربیت بدنی', 'research-in-physical-education', Icons.search_rounded, Color(0xff06b6d4)),
  Cat('تربیت بدنی و آموزش', 'physical-education-and-training', Icons.school_rounded, Color(0xff6366f1)),
  Cat('منابع و کتب مرجع', 'introduction-to-sources-and-reference-books', Icons.library_books_rounded, Color(0xff14b8a6)),
  Cat('اصول ورزش', 'principles-of-exercise-and-physical-activity', Icons.fitness_center_rounded, Color(0xfff97316)),
  Cat('آزمون‌های استخدامی', 'employment-tests', Icons.assignment_rounded, Color(0xffe11d48)),
  Cat('معرفی رشته‌ها', 'introduction-to-sports-disciplines', Icons.sports_handball_rounded, Color(0xff0ea5e9)),
  Cat('ورزش گروه‌های ویژه', 'exercise-for-special-groups-and-needs', Icons.accessibility_new_rounded, Color(0xffa855f7)),
  Cat('تکنولوژی در ورزش', 'technology-and-innovation-in-sports', Icons.memory_rounded, Color(0xff22c55e)),
];
/* ==================== BOOKMARKS ==================== */

Future<void> loadBookmarks() async {
  try {
    final saved = await _storage.read(key: 'bookmarks');
    if (saved != null && saved.isNotEmpty) {
      final list = (json.decode(saved) as List).cast<String>();
      bookmarkNotifier.value = list.toSet();
    }
  } catch (_) {}
}

Future<void> toggleBookmark(String id) async {
  final set = Set<String>.from(bookmarkNotifier.value);
  if (set.contains(id)) {
    set.remove(id);
  } else {
    set.add(id);
  }
  bookmarkNotifier.value = set;
  try {
    await _storage.write(key: 'bookmarks', value: json.encode(set.toList()));
  } catch (_) {}
}

bool isBookmarked(String id) => bookmarkNotifier.value.contains(id);

/* ==================== NAVIGATION ==================== */

Future<void> openUrl(BuildContext context, String url,
    {String title = 'مشاهده'}) async {
  if (url.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ModernWebPage(url: url, title: title),
    ),
  );
}

Future<void> openExternalUrl(String url) async {
  if (url.isEmpty) return;
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> sharePost(String url, String title) async {
  if (url.isEmpty) return;
  try {
    await Share.share('$title\n\n$url');
  } catch (_) {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

void showSnack(BuildContext context, String msg, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      backgroundColor:
          error ? const Color(0xfff43f5e) : const Color(0xff059669),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 2),
    ),
  );
}

/* ==================== TEXT HELPERS ==================== */

String clean(String v) => v
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#8217;', '’')
    .replaceAll('&#8220;', '“')
    .replaceAll('&#8221;', '”')
    .replaceAll('&#8230;', '…')
    .trim();

String pTitle(dynamic p) {
  try {
    return clean(p['title']['rendered'] ?? '');
  } catch (_) {
    return '';
  }
}

String pLink(dynamic p) {
  try {
    return p['link'] ?? '';
  } catch (_) {
    return '';
  }
}

String pId(dynamic p) {
  try {
    return (p['id'] ?? '').toString();
  } catch (_) {
    return '';
  }
}

String pImg(dynamic p) {
  try {
    final m = p['_embedded']?['wp:featuredmedia'];
    if (m is List && m.isNotEmpty) {
      final item = m[0];
      final sizes = item['media_details']?['sizes'];
      if (sizes != null) {
        final ml = sizes['medium_large']?['source_url'];
        if (ml != null && ml.toString().isNotEmpty) return ml;
        final lg = sizes['large']?['source_url'];
        if (lg != null && lg.toString().isNotEmpty) return lg;
      }
      return item['source_url'] ?? '';
    }
  } catch (_) {}
  return '';
}

String pImgFull(dynamic p) {
  try {
    final m = p['_embedded']?['wp:featuredmedia'];
    if (m is List && m.isNotEmpty) {
      final sizes = m[0]['media_details']?['sizes'];
      if (sizes != null) {
        final full = sizes['full']?['source_url'];
        if (full != null && full.toString().isNotEmpty) return full;
      }
      return m[0]['source_url'] ?? '';
    }
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
  } catch (_) {
    return '';
  }
}

String pCategory(dynamic p) {
  try {
    final terms = p['_embedded']?['wp:term'];
    if (terms is List && terms.isNotEmpty) {
      final catList = terms[0];
      if (catList is List && catList.isNotEmpty) {
        final lastCat = catList.last;
        return lastCat['name']?.toString() ?? '';
      }
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
    if (a is List && a.isNotEmpty) return a[0]['avatar_urls']?['96'] ?? '';
  } catch (_) {}
  return '';
}

String pDate(dynamic p) {
  try {
    final d = DateTime.parse(p['date']).toLocal();
    final j = _toJalali(d.year, d.month, d.day);
    return '${j[2]} ${_monthName(j[1])} ${j[0]}';
  } catch (_) {
    return '';
  }
}

String pTimeAgo(dynamic p) {
  try {
    final d = DateTime.parse(p['date']).toLocal();
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes} دقیقه پیش';
    if (diff.inHours < 24) return '${diff.inHours} ساعت پیش';
    if (diff.inDays < 30) return '${diff.inDays} روز پیش';
    return pDate(p);
  } catch (_) {
    return '';
  }
}

String _monthName(int m) {
  const months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];
  if (m >= 1 && m <= 12) return months[m - 1];
  return '';
}

List<int> _toJalali(int gy, int gm, int gd) {
  const gdm = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  const jdm = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];
  var gy2 = (gm > 2) ? (gy + 1) : gy;
  var days = 355666 +
      (365 * gy) +
      ((gy2 + 3) ~/ 4) -
      ((gy2 + 99) ~/ 100) +
      ((gy2 + 399) ~/ 400) +
      gd;
  for (var i = 0; i < gm - 1; i++) days += gdm[i];
  var jy = -1595 + (33 * (days ~/ 12053));
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  var jm = 0;
  var jd = days + 1;
  for (var i = 0; i < 12; i++) {
    if (jd <= jdm[i]) {
      jm = i + 1;
      break;
    }
    jd -= jdm[i];
  }
  return [jy, jm, jd];
}

/* ==================== API & CACHE ==================== */

final Map<String, List> _postsCache = {};
final Map<String, int> _postsCacheTime = {};
const int _cacheDurationSeconds = 300;

Future<List> getPostsPaged({
  int perPage = perPageSize,
  int page = 1,
  int? catId,
}) async {
  var u = '$api/posts?per_page=$perPage&page=$page'
      '&_embed=wp:featuredmedia,wp:term,author'
      '&_fields=id,link,title,date,excerpt,_embedded,_links';
  if (catId != null) u += '&categories=$catId';

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  if (_postsCache.containsKey(u) &&
      _postsCacheTime.containsKey(u) &&
      (now - _postsCacheTime[u]!) < _cacheDurationSeconds) {
    return _postsCache[u]!;
  }

  try {
    final r = await http.get(Uri.parse(u));
    if (r.statusCode == 400) return [];
    if (r.statusCode != 200) throw Exception('خطای ${r.statusCode}');
    final list = json.decode(r.body) as List;
    _postsCache[u] = list;
    _postsCacheTime[u] = now;
    try {
      await _storage.write(key: 'cache_$u', value: r.body);
    } catch (_) {}
    return list;
  } catch (e) {
    try {
      final cached = await _storage.read(key: 'cache_$u');
      if (cached != null && cached.isNotEmpty) {
        return json.decode(cached) as List;
      }
    } catch (_) {}
    rethrow;
  }
}

Future<List> getProductsPaged({int perPage = perPageSize, int page = 1}) async {
  final u =
      '$site/wp-json/wc/v3/products?per_page=$perPage&page=$page&consumer_key=$wcKey&consumer_secret=$wcSecret';
  try {
    final r = await http.get(Uri.parse(u));
    if (r.statusCode == 400) return [];
    if (r.statusCode != 200) throw Exception('خطای ${r.statusCode}');
    try {
      await _storage.write(key: 'cache_$u', value: r.body);
    } catch (_) {}
    return json.decode(r.body) as List;
  } catch (e) {
    try {
      final cached = await _storage.read(key: 'cache_$u');
      if (cached != null && cached.isNotEmpty) {
        return json.decode(cached) as List;
      }
    } catch (_) {}
    rethrow;
  }
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
    Uri.parse(
        '$api/posts?search=${Uri.encodeComponent(query)}&per_page=50&_embed=wp:featuredmedia,wp:term,author&_fields=id,link,title,date,excerpt,_embedded,_links'),
  );
  if (r.statusCode != 200) throw Exception('خطای ${r.statusCode}');
  final list = json.decode(r.body) as List;
  final words = query
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
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

/* ==================== NEWS API ==================== */

String _newNewsUrl({int perPage = 10, int page = 1}) {
  return '$api/new_news?per_page=$perPage&page=$page&orderby=date&order=desc&_embed=wp:featuredmedia,wp:term,author&_fields=id,link,title,date,excerpt,content,_embedded,_links';
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

/* ==================== ADMIN API ==================== */

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

Future<Map<String, dynamic>> updateNews({
  required String username,
  required String appPassword,
  required int postId,
  required String title,
  required String content,
}) async {
  final auth = _basicAuth(username, appPassword);
  final uri = Uri.parse('$api/new_news/$postId');
  final r = await http.put(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic $auth',
    },
    body: jsonEncode({
      'title': title,
      'content': content,
    }),
  );
  if (r.statusCode == 200 || r.statusCode == 201) {
    final d = jsonDecode(r.body);
    if (d is Map) return Map<String, dynamic>.from(d);
    throw Exception('پاسخ نامعتبر');
  }
  if (r.statusCode == 401) throw Exception('نام کاربری یا رمز اشتباه است.');
  if (r.statusCode == 403) throw Exception('شما اجازه ویرایش ندارید.');
  throw Exception('خطا در ویرایش (${r.statusCode})');
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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  try {
    final saved = await _storage.read(key: 'dark_mode');
    darkModeNotifier.value = saved == null ? true : saved == 'true';
    await loadBookmarks();
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
            useMaterial3: true,
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: bgC,
            splashFactory: InkSparkle.splashFactory,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff10b981),
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

/* ==================== ROOT ==================== */

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  int _i = 0;

  static const _pages = [
    Home(),
    ArticlesPage(),
    NewsPage(),
    ShopPage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        extendBody: true,
        body: IndexedStack(index: _i, children: _pages),
        bottomNavigationBar: _ModernNavBar(
          currentIndex: _i,
          onTap: (i) => setState(() => _i = i),
        ),
      ),
    );
  }
}

/* ==================== MODERN NAV BAR ==================== */

class _ModernNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _ModernNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = darkModeNotifier.value;
    return SafeArea(
      bottom: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark
                ? const Color(0xff2a3b5c)
                : const Color(0xffdbe4f0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.5)
                  : const Color(0xff10b981).withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            height: 74,
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == currentIndex;
                final item = _items[i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? accentGreen.withOpacity(0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: selected
                            ? Border.all(
                                color: accentGreen.withOpacity(0.5),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            color: selected
                                ? accentGreen
                                : txtC.withOpacity(0.75),
                            size: selected ? 26 : 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              color: selected
                                  ? accentGreen
                                  : txtC.withOpacity(0.75),
                              fontSize: selected ? 12 : 11,
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  static const _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'خانه',
    ),
    _NavItem(
      icon: Icons.article_outlined,
      activeIcon: Icons.article_rounded,
      label: 'مقالات',
    ),
    _NavItem(
      icon: Icons.newspaper_outlined,
      activeIcon: Icons.newspaper_rounded,
      label: 'اخبار',
    ),
    _NavItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      label: 'فروشگاه',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'حساب من',
    ),
  ];
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/* ==================== HOME ==================== */

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<List>? _f;
  Future<List>? _newsFuture;
  Key _bannerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        precacheImage(NetworkImage(heroImg), context);
      } catch (_) {}
    });
  }

  void _load() {
    _f = getPostsPaged(perPage: 5, page: 1);
    _newsFuture = getNewNewsList();
  }

  Future<void> _refresh() async {
    _postsCache.clear();
    _postsCacheTime.clear();
    setState(() {
      _load();
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
      builder: (context, _, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgGrad1, bgGrad2],
          ),
        ),
        child: RefreshIndicator(
          color: accentGreen,
          backgroundColor: pnl,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: ModernHeader(context)),
              SliverToBoxAdapter(child: HeroCarousel(postsFuture: _f)),
              SliverToBoxAdapter(
                child: ModernNewsBanner(key: _bannerKey, future: _newsFuture),
              ),
              SliverToBoxAdapter(child: ModernServicesSection()),
              SliverToBoxAdapter(
                child: ModernSectionTitle(
                  title: 'دسته‌ها',
                  icon: Icons.grid_view_rounded,
                ),
              ),
              SliverToBoxAdapter(child: ModernCatGrid()),
              SliverToBoxAdapter(child: ModernSocial()),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        ),
      ),
    );
  }
}

/* ==================== HERO CAROUSEL ==================== */

class HeroCarousel extends StatefulWidget {
  final Future<List>? postsFuture;
  const HeroCarousel({super.key, required this.postsFuture});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _pageCtrl = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _current = 0;
  int _count = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startAuto(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final next = (_current + 1) % count;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: widget.postsFuture,
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return Container(
            height: 240,
            margin: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            decoration: BoxDecoration(
              color: pnl,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: lineC),
            ),
            child: const ShimmerBox(height: 240, radius: 24),
          );
        }
        final posts = (s.data ?? []).take(5).toList();
        if (posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            child: ModernHeroBanner(),
          );
        }
        _count = posts.length;
        if (_timer == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startAuto(_count);
          });
        }

        return Container(
          margin: const EdgeInsets.only(top: 16, bottom: 12),
          child: Column(
            children: [
              SizedBox(
                height: 240,
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemCount: posts.length,
                  itemBuilder: (c, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _CarouselCard(post: posts[i]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildDots(posts.length),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == _current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xff10b981)
                : mutC.withOpacity(0.3),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final dynamic post;
  const _CarouselCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final title = pTitle(post);
    final img = pImgFull(post);
    final cat = pCategory(post);
    final link = pLink(post);

    return GestureDetector(
      onTap: () => openUrl(context, link),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (img.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: img,
                  fit: BoxFit.cover,
                  memCacheWidth: 1080,
                  fadeInDuration: const Duration(milliseconds: 300),
                  placeholder: (_, __) => Container(color: pnl2),
                  errorWidget: (_, __, ___) => Container(
                    color: pnl2,
                    child: const Icon(
                      Icons.article_rounded,
                      color: Color(0xff10b981),
                      size: 60,
                    ),
                  ),
                )
              else
                Container(color: pnl2),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cat.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff10b981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.5,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white70,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pTimeAgo(post),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'مطالعه',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
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
      ),
    );
  }
}

class ModernHeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lineC),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          heroImg,
          fit: BoxFit.cover,
          width: double.infinity,
          filterQuality: FilterQuality.high,
          cacheWidth: 1080,
          loadingBuilder: (c, ch, pr) {
            if (pr == null) return ch;
            return Container(
              height: 180,
              color: pnl2,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xff10b981),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: 180,
            color: pnl2,
            child: const Icon(Icons.sports_soccer_rounded,
                color: Color(0xff10b981), size: 60),
          ),
        ),
      ),
    );
  }
}
/* ==================== ARTICLES PAGE ==================== */

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
              _scroll.position.maxScrollExtent - 400 &&
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
    _postsCache.clear();
    _postsCacheTime.clear();
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
            ModernHeader(context, 'مقالات'),
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
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(14, 14, 14, 120),
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
                                  return ModernPostCard(
                                    post: _posts[i],
                                    showBookmark: true,
                                  );
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
      final list = await getPostsPaged(perPage: 5, page: 1, catId: _catId);
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
          perPage: 5, page: nextPage, catId: _catId);
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
        body: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: bgC,
              foregroundColor: txtC,
              elevation: 0,
              expandedHeight: 130,
              leading: IconButton(
                icon: Icon(Icons.arrow_forward_rounded, color: txtC),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.c.n,
                  style: TextStyle(
                    color: txtC,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.c.c.withOpacity(0.25),
                        bgC,
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 60, top: 20),
                      child: Icon(
                        widget.c.i,
                        color: widget.c.c.withOpacity(0.35),
                        size: 100,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_posts.isEmpty && _loading)
              const SliverToBoxAdapter(
                child: Padding(
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
                ),
              )
            else if (_posts.isEmpty && _error != null)
              SliverToBoxAdapter(
                child: ErrorBox(
                  message: 'خطا در دریافت مطالب.\n$_error',
                  onRetry: _refresh,
                ),
              )
            else if (_posts.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyWidget(text: 'مطلبی در این دسته پیدا نشد.'),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: FeaturedPostCard(
                      post: _posts.first, showBookmark: true),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (c, i) {
                      final post = _posts[i + 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:
                            SidePostCard(post: post, showBookmark: true),
                      );
                    },
                    childCount: _posts.length - 1,
                  ),
                ),
              ),
              if (_hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
                    child: Center(child: _buildLoadMore()),
                  ),
                ),
              if (!_hasMore && _posts.length > 5)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 60),
                    child: Center(
                      child: Text(
                        'همه مطالب نمایش داده شد.',
                        style: TextStyle(color: mutC, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMore() {
    return GestureDetector(
      onTap: _loadingMore ? null : _loadMore,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: lineC),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loadingMore)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentGreen,
                ),
              )
            else
              Icon(Icons.arrow_back_ios_new_rounded,
                  size: 12, color: txtC),
            const SizedBox(width: 8),
            Text(
              _loadingMore ? 'در حال بارگذاری...' : 'مشاهده بیشتر',
              style: TextStyle(
                color: txtC,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== SUB CATEGORY POSTS ==================== */

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
          perPage: 5, page: 1, catId: widget.categoryId);
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
          perPage: 5, page: nextPage, catId: widget.categoryId);
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

  Future<void> _refresh() async => _loadFirst();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Text(
            widget.categoryName,
            style: const TextStyle(
                fontWeight: FontWeight.w900, fontFamily: 'Vazirmatn'),
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
        ),
        body: SafeArea(
          bottom: true,
          child: RefreshIndicator(
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
                        onRetry: _refresh)
                    : _posts.isEmpty
                        ? const EmptyWidget(text: 'مطلبی پیدا نشد.')
                        : SingleChildScrollView(
                            controller: _scroll,
                            physics: const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(14, 14, 14, 100),
                            child: Column(
                              children: [
                                FeaturedPostCard(
                                    post: _posts.first,
                                    showBookmark: true),
                                const SizedBox(height: 14),
                                ..._posts.skip(1).map((post) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 10),
                                    child: SidePostCard(
                                        post: post,
                                        showBookmark: true),
                                  );
                                }).toList(),
                                if (_hasMore)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 10, bottom: 10),
                                    child: _buildLoadMore(),
                                  ),
                                if (!_hasMore && _posts.length > 5)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 16, bottom: 40),
                                    child: Text(
                                      'همه مطالب نمایش داده شد.',
                                      style: TextStyle(
                                          color: mutC, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMore() {
    return GestureDetector(
      onTap: _loadingMore ? null : _loadMore,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: lineC),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loadingMore)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: accentGreen),
              )
            else
              Icon(Icons.arrow_back_ios_new_rounded,
                  size: 12, color: txtC),
            const SizedBox(width: 8),
            Text(
              _loadingMore ? 'در حال بارگذاری...' : 'مشاهده بیشتر',
              style: TextStyle(
                color: txtC,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== BOOKMARKS PAGE ==================== */

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});
  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  final _allPosts = <dynamic>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final list = await getPostsPaged(perPage: 50, page: 1);
      _allPosts.clear();
      _allPosts.addAll(list);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<Set<String>>(
        valueListenable: bookmarkNotifier,
        builder: (context, bookmarks, __) {
          final saved =
              _allPosts.where((p) => bookmarks.contains(pId(p))).toList();

          return Scaffold(
            backgroundColor: bgC,
            appBar: AppBar(
              title: const Text(
                'نشان‌شده‌ها',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontFamily: 'Vazirmatn'),
              ),
              backgroundColor: bgC,
              foregroundColor: txtC,
              elevation: 0,
            ),
            body: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      children: [
                        PostSkeleton(),
                        PostSkeleton(),
                        PostSkeleton(),
                      ],
                    ),
                  )
                : saved.isEmpty
                    ? const EmptyWidget(
                        text:
                            'هنوز مقاله‌ای را نشان نکرده‌اید.\nبا زدن آیکون نشان روی کارت‌ها، اینجا ذخیره می‌شوند.')
                    : RefreshIndicator(
                        color: accentGreen,
                        backgroundColor: pnl,
                        onRefresh: _loadAll,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(14, 14, 14, 100),
                          itemCount: saved.length,
                          itemBuilder: (c, i) => ModernPostCard(
                              post: saved[i], showBookmark: true),
                        ),
                      ),
          );
        },
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
              _scroll.position.maxScrollExtent - 400 &&
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
          perPage: perPageSize, page: _page, catId: _catId);
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
    _postsCache.clear();
    _postsCacheTime.clear();
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
            ModernHeader(context, 'اخبار و رویدادها'),
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
                          onRetry: _refresh)
                      : _posts.isEmpty
                          ? const EmptyWidget(text: 'خبری پیدا نشد.')
                          : RefreshIndicator(
                              color: accentGreen,
                              backgroundColor: pnl,
                              onRefresh: _refresh,
                              child: ListView.builder(
                                controller: _scroll,
                                cacheExtent: 800,
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(14, 14, 14, 120),
                                itemCount:
                                    _posts.length + (_hasMore ? 1 : 0),
                                itemBuilder: (c, i) {
                                  if (i >= _posts.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            color: accentGreen),
                                      ),
                                    );
                                  }
                                  return ModernPostCard(
                                      post: _posts[i], showBookmark: true);
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
              _scroll.position.maxScrollExtent - 400 &&
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
      final list =
          await getProductsPaged(perPage: perPageSize, page: _page);
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
            ModernHeader(context, 'فروشگاه'),
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
                          onRetry: _refresh)
                      : _products.isEmpty
                          ? const EmptyWidget(text: 'محصولی پیدا نشد.')
                          : RefreshIndicator(
                              color: accentGreen,
                              backgroundColor: pnl,
                              onRefresh: _refresh,
                              child: ListView.builder(
                                controller: _scroll,
                                cacheExtent: 800,
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(14, 14, 14, 120),
                                itemCount: _products.length +
                                    (_hasMore ? 1 : 0),
                                itemBuilder: (c, i) {
                                  if (i >= _products.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            color: accentGreen),
                                      ),
                                    );
                                  }
                                  return ModernProductCard(
                                      product: _products[i]);
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

/* ==================== SEARCH ==================== */

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Future<List>? _f;
  String _q = '';
  Timer? _debounce;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  Future<void> _loadHistory() async {
    try {
      final saved = await _storage.read(key: 'search_history');
      if (saved != null && saved.isNotEmpty) {
        _history = (json.decode(saved) as List).cast<String>();
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _saveHistory(String q) async {
    if (q.isEmpty) return;
    _history.remove(q);
    _history.insert(0, q);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    try {
      await _storage.write(
          key: 'search_history', value: json.encode(_history));
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _clearHistory() async {
    _history.clear();
    try {
      await _storage.delete(key: 'search_history');
    } catch (_) {}
    if (mounted) setState(() {});
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
      _saveHistory(q);
    });
  }

  void _searchFromHistory(String q) {
    _ctrl.text = q;
    _onChanged(q);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
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
            'جستجو',
            style: TextStyle(
                fontWeight: FontWeight.w900, fontFamily: 'Vazirmatn'),
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Container(
                decoration: BoxDecoration(
                  color: pnl,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: lineC),
                ),
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                  style: TextStyle(
                      color: txtC, fontFamily: 'Vazirmatn', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'عبارت مورد نظر...',
                    hintStyle:
                        TextStyle(color: mutC, fontFamily: 'Vazirmatn'),
                    prefixIcon:
                        Icon(Icons.search_rounded, color: accentGreen),
                    suffixIcon: _ctrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: mutC, size: 20),
                            onPressed: () {
                              _ctrl.clear();
                              _onChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _f == null
                  ? _buildHistory()
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
                              onRetry: null);
                        }
                        final posts = s.data ?? [];
                        if (posts.isEmpty) {
                          return EmptyWidget(
                              text: 'نتیجه‌ای برای «$_q» پیدا نشد.');
                        }
                        return ListView.builder(
                          cacheExtent: 800,
                          physics: const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(14, 0, 14, 100),
                          itemCount: posts.length,
                          itemBuilder: (c, i) => ModernPostCard(
                              post: posts[i], showBookmark: true),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return const EmptyWidget(text: 'عبارتی برای جستجو وارد کنید');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: mutC, size: 18),
              const SizedBox(width: 6),
              Text(
                'جستجوهای اخیر',
                style: TextStyle(
                  color: txtC,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearHistory,
                child: Text(
                  'پاک کردن',
                  style: TextStyle(
                    color: rose,
                    fontSize: 12,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _history
                .map((q) => GestureDetector(
                      onTap: () => _searchFromHistory(q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: pnl,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: lineC),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_rounded,
                                color: mutC, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              q,
                              style: TextStyle(
                                color: txtC,
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
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
  double _progress = 0;

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
      final cookies =
          await CookieManager.instance().getCookies(url: WebUri(site));
      final loginCookies = cookies
          .where((c) =>
              c.name.startsWith('wordpress_logged_in') ||
              c.name.startsWith('wordpress_sec'))
          .toList();
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

  bool _isTrustedUrl(String url) {
    return url.contains('itarbiatbadani.ir') ||
        url.contains('zarinpal.com') ||
        url.contains('shaparak.ir') ||
        url.contains('sep.shaparak.ir') ||
        url.contains('behpardakht.com') ||
        url.contains('mellatbank.ir') ||
        url.contains('asanpardakht.ir') ||
        url.contains('idpay.ir') ||
        url.contains('pay.ir') ||
        url.contains('sadad.ir') ||
        url.contains('pep.co.ir') ||
        url.contains('parsianbank.ir') ||
        url.contains('sb24.ir') ||
        url.contains('my-account') ||
        url.contains('checkout') ||
        url.contains('cart');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        body: Column(
          children: [
            ModernHeaderWithAdmin(context, 'حساب من'),
            if (_l && _progress > 0)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: lineC,
                color: accentGreen,
                minHeight: 3,
              ),
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest:
                        URLRequest(url: WebUri('$site/my-account/')),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      useOnDownloadStart: true,
                      useShouldOverrideUrlLoading: true,
                      userAgent:
                          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                    ),
                    onWebViewCreated: (c) => _controller = c,
                    onLoadStart: (c, url) => setState(() => _l = true),
                    onLoadStop: (c, url) async {
                      setState(() {
                        _l = false;
                        _progress = 0;
                      });
                      await _save();
                    },
                    onProgressChanged: (c, p) =>
                        setState(() => _progress = p / 100),
                    onDownloadStartRequest: (controller, request) async {
                      await openExternalUrl(request.url.toString());
                    },
                    shouldOverrideUrlLoading: (controller, action) async {
                      final url = action.request.url.toString();
                      if (_isTrustedUrl(url)) {
                        return NavigationActionPolicy.ALLOW;
                      }
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                      }
                      return NavigationActionPolicy.CANCEL;
                    },
                  ),
                  if (_l && _progress == 0)
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

/* ==================== MODERN WEB PAGE ==================== */

class ModernWebPage extends StatefulWidget {
  final String url;
  final String title;
  const ModernWebPage({
    super.key,
    required this.url,
    required this.title,
  });
  @override
  State<ModernWebPage> createState() => _ModernWebPageState();
}

class _ModernWebPageState extends State<ModernWebPage> {
  bool _l = true;
  double _progress = 0;
  InAppWebViewController? _controller;

  bool _isTrustedUrl(String url) {
    return url.contains('itarbiatbadani.ir') ||
        url.contains('zarinpal.com') ||
        url.contains('shaparak.ir') ||
        url.contains('sep.shaparak.ir') ||
        url.contains('behpardakht.com') ||
        url.contains('mellatbank.ir') ||
        url.contains('asanpardakht.ir') ||
        url.contains('idpay.ir') ||
        url.contains('pay.ir') ||
        url.contains('sadad.ir') ||
        url.contains('pep.co.ir') ||
        url.contains('parsianbank.ir') ||
        url.contains('sb24.ir') ||
        url.contains('my-account') ||
        url.contains('checkout') ||
        url.contains('cart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgC,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            fontFamily: 'Vazirmatn',
          ),
        ),
        backgroundColor: bgC,
        foregroundColor: txtC,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => sharePost(widget.url, widget.title),
            icon: Icon(Icons.ios_share_rounded, color: txtC),
            tooltip: 'اشتراک',
          ),
          IconButton(
            onPressed: () {
              _controller?.reload();
            },
            icon: Icon(Icons.refresh_rounded, color: txtC),
            tooltip: 'رفرش',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: AnimatedOpacity(
            opacity: _l ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: lineC,
              color: accentGreen,
              minHeight: 2,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              useOnDownloadStart: true,
              supportZoom: true,
            ),
            onWebViewCreated: (c) => _controller = c,
            onLoadStart: (c, url) => setState(() => _l = true),
            onLoadStop: (c, url) => setState(() {
              _l = false;
              _progress = 0;
            }),
            onProgressChanged: (c, p) =>
                setState(() => _progress = p / 100),
            onDownloadStartRequest: (controller, request) async {
              await openExternalUrl(request.url.toString());
            },
            shouldOverrideUrlLoading: (controller, action) async {
              final url = action.request.url.toString();
              if (_isTrustedUrl(url)) {
                return NavigationActionPolicy.ALLOW;
              }
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              }
              return NavigationActionPolicy.CANCEL;
            },
          ),
          if (_l && _progress == 0)
            Center(child: CircularProgressIndicator(color: accentGreen)),
        ],
      ),
    );
  }
}
/* ==================== MODERN HEADER ==================== */

Widget ModernHeader(BuildContext context, [String? t]) {
  return SafeArea(
    bottom: false,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: lineC),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                logo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  logoNet,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.sports_rounded,
                    color: Color(0xff10b981),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t ?? 'تربیت بدنی و علوم ورزشی',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: txtC,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'به اپلیکیشن خوش آمدید',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: mutC,
                    fontSize: 11,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.bookmark_outline_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookmarksPage()),
            ),
          ),
          const SizedBox(width: 4),
          ValueListenableBuilder<bool>(
            valueListenable: darkModeNotifier,
            builder: (c, isDark, _) => _HeaderIconButton(
              icon: isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              onTap: () async {
                HapticFeedback.lightImpact();
                darkModeNotifier.value = !darkModeNotifier.value;
                await _storage.write(
                  key: 'dark_mode',
                  value: darkModeNotifier.value.toString(),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          _HeaderIconButton(
            icon: Icons.search_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget ModernHeaderWithAdmin(BuildContext context, [String? t]) {
  return SafeArea(
    bottom: false,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: lineC),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                logo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  logoNet,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.sports_rounded,
                    color: Color(0xff10b981),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t ?? 'حساب من',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
          _HeaderIconButton(
            icon: Icons.admin_panel_settings_rounded,
            color: accentBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLoginPage()),
            ),
          ),
          const SizedBox(width: 4),
          ValueListenableBuilder<bool>(
            valueListenable: darkModeNotifier,
            builder: (c, isDark, _) => _HeaderIconButton(
              icon: isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              onTap: () async {
                HapticFeedback.lightImpact();
                darkModeNotifier.value = !darkModeNotifier.value;
                await _storage.write(
                  key: 'dark_mode',
                  value: darkModeNotifier.value.toString(),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          _HeaderIconButton(
            icon: Icons.search_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lineC),
        ),
        child: Icon(icon, color: color ?? txtC, size: 20),
      ),
    );
  }
}

/* ==================== MODERN NEWS BANNER ==================== */

class ModernNewsBanner extends StatefulWidget {
  final Future<List>? future;
  const ModernNewsBanner({super.key, this.future});
  @override
  State<ModernNewsBanner> createState() => _ModernNewsBannerState();
}

class _ModernNewsBannerState extends State<ModernNewsBanner> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: widget.future,
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
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [accentBlue2, accentBlue],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const ModernLiveDot(),
                    const SizedBox(width: 8),
                    Text(
                      'اخبار فوری',
                      style: TextStyle(
                        color: txtC,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...items
                  .map((news) => ModernUrgentNewsCard(news: news))
                  .toList(),
              if (list.length > 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UrgentNewsListPage(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: accentBlue.withOpacity(.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accentBlue.withOpacity(.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.list_alt_rounded,
                                color: accentBlue, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'مشاهده همه اخبار فوری',
                              style: TextStyle(
                                color: accentBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_back_ios_new_rounded,
                                color: accentBlue, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }
}

/* ==================== MODERN SERVICES ==================== */

class ModernServicesSection extends StatefulWidget {
  const ModernServicesSection({super.key});
  @override
  State<ModernServicesSection> createState() =>
      _ModernServicesSectionState();
}

class _ModernServicesSectionState extends State<ModernServicesSection> {
  final ScrollController _scrollCtrl = ScrollController();

  final List<Map<String, dynamic>> _items = [
    {
      'title': 'معرفی رشته',
      'icon': Icons.info_outline_rounded,
      'color': const Color(0xff3b82f6),
      'url':
          '$site/introduction-to-the-field-of-physical-education-and-sports-sciences/',
    },
    {
      'title': 'گرایش‌های ارشد',
      'icon': Icons.layers_rounded,
      'color': const Color(0xff8b5cf6),
      'url':
          '$site/%da%af%d8%b1%d8%a7%db%8c%d8%b4%d9%87%d8%a7%db%8c-%da%a9%d8%a7%d8%b1%d8%b4%d9%86%d8%a7%d8%b3%db%8c-%d8%a7%d8%b1%d8%b4%d8%af-%d8%aa%d8%b1%d8%a8%db%8c%d8%aa-%d8%a8%d8%af%d9%86%db%8c-%d9%88/',
    },
    {
      'title': 'گرایش‌های دکتری',
      'icon': Icons.school_rounded,
      'color': const Color(0xff0891b2),
      'url': '$site/sports-science-phd-exam-resources/',
    },
    {
      'title': 'منابع ارشد',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xff10b981),
      'url': '$site/master-of-sports-science-resources/',
    },
    {
      'title': 'منابع دکتری',
      'icon': Icons.auto_stories_rounded,
      'color': const Color(0xfff59e0b),
      'url': '$site/manabe-konkur-doctori-tarbiat-badani/',
    },
    {
      'title': 'منابع استخدامی',
      'icon': Icons.assignment_rounded,
      'color': const Color(0xffe11d48),
      'url': '$site/employment-tests/',
    },
    {
      'title': 'دانشگاه‌های برتر',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xff2563eb),
      'url': '$site/physical-education-sports-science/',
    },
    {
      'title': 'بازار کار',
      'icon': Icons.work_outline_rounded,
      'color': const Color(0xff0d9488),
      'url':
          '$site/job-market-in-physical-education-and-sports-sciences/',
    },
    {
      'title': 'طرح درس',
      'icon': Icons.slideshow_rounded,
      'color': const Color(0xff9333ea),
      'url':
          '$site/product-category/%d8%b7%d8%b1%d8%ad-%d8%af%d8%b1%d8%b3-%d8%b1%d9%88%d8%b2%d8%a7%d9%86%d9%87-%d9%85%d8%a7%d9%87%d8%a7%d9%86%d9%87-%d8%b3%d8%a7%d9%84%d8%a7%d9%86%d9%87/',
    },
    {
      'title': 'پاورپوینت',
      'icon': Icons.file_present_rounded,
      'color': const Color(0xffea580c),
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
      builder: (context, _, __) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accentBlue2, accentBlue],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.auto_awesome_rounded,
                    color: accentBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'خدمات ما',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: txtC,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 118,
            child: ListView.separated(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (c, i) => _buildCard(_items[i]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final color = item['color'] as Color;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        openUrl(context, item['url'] as String,
            title: item['title'] as String);
      },
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: lineC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item['icon'] as IconData, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  item['title'] as String,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: txtC,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    fontFamily: 'Vazirmatn',
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

/* ==================== MODERN POST CARD ==================== */

class ModernPostCard extends StatefulWidget {
  final dynamic post;
  final bool showBookmark;
  const ModernPostCard(
      {super.key, required this.post, this.showBookmark = true});

  @override
  State<ModernPostCard> createState() => _ModernPostCardState();
}

class _ModernPostCardState extends State<ModernPostCard> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final title = pTitle(post);
    final link = pLink(post);
    final img = pImg(post);
    final cat = pCategory(post);
    final date = pTimeAgo(post);
    final id = pId(post);

    return GestureDetector(
      onTap: () => openUrl(context, link),
      child: Container(
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: lineC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: SizedBox(
                width: 110,
                height: 110,
                child: img.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        memCacheWidth: 500,
                        fadeInDuration:
                            const Duration(milliseconds: 250),
                        placeholder: (_, __) => Container(color: pnl2),
                        errorWidget: (_, __, ___) => Container(
                          color: pnl2,
                          child: const Icon(Icons.article_rounded,
                              color: Color(0xff10b981), size: 32),
                        ),
                      )
                    : Container(
                        color: pnl2,
                        child: const Icon(Icons.article_rounded,
                            color: Color(0xff10b981), size: 32),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (cat.isNotEmpty)
                          ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 180),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: chipFg,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      cat,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: chipFg,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (widget.showBookmark)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              toggleBookmark(id);
                              showSnack(
                                context,
                                isBookmarked(id)
                                    ? 'به نشان‌شده‌ها اضافه شد'
                                    : 'از نشان‌شده‌ها حذف شد',
                              );
                            },
                            child: ValueListenableBuilder<Set<String>>(
                              valueListenable: bookmarkNotifier,
                              builder: (c, set, __) => Icon(
                                set.contains(id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: set.contains(id) ? gold : mutC,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
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
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            color: mutC, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(
                            color: mutC,
                            fontSize: 10,
                            fontFamily: 'Vazirmatn',
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
}
/* ==================== FEATURED POST CARD ==================== */

class FeaturedPostCard extends StatelessWidget {
  final dynamic post;
  final bool showBookmark;
  const FeaturedPostCard(
      {super.key, required this.post, this.showBookmark = true});

  @override
  Widget build(BuildContext context) {
    final title = pTitle(post);
    final link = pLink(post);
    final img = pImg(post);
    final cat = pCategory(post);
    final author = pAuthor(post);
    final avatarUrl = pAuthorAvatar(post);
    final date = pDate(post);
    final excerpt = pExcerpt(post, maxChars: 130);
    final id = pId(post);

    return GestureDetector(
      onTap: () => openUrl(context, link),
      child: Container(
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: lineC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (img.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        memCacheWidth: 1080,
                        fadeInDuration:
                            const Duration(milliseconds: 300),
                        placeholder: (_, __) => Container(color: pnl2),
                        errorWidget: (_, __, ___) => Container(
                          color: pnl2,
                          child: const Icon(Icons.article_rounded,
                              color: Color(0xff10b981), size: 60),
                        ),
                      )
                    else
                      Container(
                        color: pnl2,
                        child: const Icon(Icons.article_rounded,
                            color: Color(0xff10b981), size: 60),
                      ),
                    if (showBookmark)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            toggleBookmark(id);
                            showSnack(
                              context,
                              isBookmarked(id)
                                  ? 'به نشان‌شده‌ها اضافه شد'
                                  : 'از نشان‌شده‌ها حذف شد',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: ValueListenableBuilder<Set<String>>(
                              valueListenable: bookmarkNotifier,
                              builder: (c, set, __) => Icon(
                                set.contains(id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: set.contains(id)
                                    ? gold
                                    : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cat.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: chipFg.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: chipFg,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                cat,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: chipFg,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.45,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  if (excerpt.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: inkSoft,
                        fontSize: 12.5,
                        height: 1.8,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Divider(height: 1, color: softLine),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (avatarUrl.isNotEmpty)
                        ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 34,
                              height: 34,
                              color: pnl2,
                              child: Icon(Icons.person_rounded,
                                  color: mutC, size: 18),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: pnl2,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_rounded,
                              color: mutC, size: 18),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (author.isNotEmpty)
                              Text(
                                author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: txtC,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            if (date.isNotEmpty)
                              Text(
                                date,
                                style: TextStyle(
                                  color: mutC,
                                  fontSize: 10,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: accentGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مطالعه',
                              style: TextStyle(
                                color: accentGreen2,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_back_rounded,
                                color: accentGreen2, size: 12),
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
  final bool showBookmark;
  const SidePostCard(
      {super.key, required this.post, this.showBookmark = true});

  @override
  Widget build(BuildContext context) {
    final title = pTitle(post);
    final link = pLink(post);
    final img = pImg(post);
    final cat = pCategory(post);
    final date = pTimeAgo(post);
    final id = pId(post);

    return GestureDetector(
      onTap: () => openUrl(context, link),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: lineC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (cat.isNotEmpty)
                        ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: 160),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: chipFg,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    cat,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: chipFg,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (showBookmark)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            toggleBookmark(id);
                          },
                          child: ValueListenableBuilder<Set<String>>(
                            valueListenable: bookmarkNotifier,
                            builder: (c, set, __) => Icon(
                              set.contains(id)
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: set.contains(id) ? gold : mutC,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: txtC,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            color: mutC, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          date,
                          style: TextStyle(
                            color: mutC,
                            fontSize: 9.5,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox(
                width: 88,
                height: 72,
                child: img.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        memCacheWidth: 400,
                        fadeInDuration:
                            const Duration(milliseconds: 200),
                        placeholder: (_, __) => Container(color: pnl2),
                        errorWidget: (_, __, ___) => Container(
                          color: pnl2,
                          child: const Icon(Icons.article_rounded,
                              color: Color(0xff10b981), size: 26),
                        ),
                      )
                    : Container(
                        color: pnl2,
                        child: const Icon(Icons.article_rounded,
                            color: Color(0xff10b981), size: 26),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== MODERN PRODUCT CARD ==================== */

class ModernProductCard extends StatelessWidget {
  final dynamic product;
  const ModernProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
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
      onTap: () => openUrl(context, link, title: name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: lineC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: SizedBox(
                width: 110,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    img.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            memCacheWidth: 500,
                            placeholder: (_, __) =>
                                Container(color: pnl2),
                            errorWidget: (_, __, ___) => Container(
                              color: pnl2,
                              child: const Icon(
                                  Icons.shopping_bag_rounded,
                                  color: Color(0xff10b981),
                                  size: 32),
                            ),
                          )
                        : Container(
                            color: pnl2,
                            child: const Icon(
                                Icons.shopping_bag_rounded,
                                color: Color(0xff10b981),
                                size: 32),
                          ),
                    if (isOnSale)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: rose,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'تخفیف',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.5,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isOnSale) ...[
                      Row(
                        children: [
                          Text(
                            formatPrice(salePrice),
                            style: TextStyle(
                              color: accentGreen2,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatPrice(regularPrice),
                            style: TextStyle(
                              color: mutC,
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ] else if (regularPrice.isNotEmpty) ...[
                      Text(
                        formatPrice(regularPrice),
                        style: TextStyle(
                          color: txtC,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ] else ...[
                      Text(
                        'قیمت نامشخص',
                        style: TextStyle(color: mutC, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          inStock
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: inStock ? accentGreen : rose,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          inStock ? 'موجود' : 'ناموجود',
                          style: TextStyle(
                            color: inStock ? accentGreen : rose,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Vazirmatn',
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
}

/* ==================== MODERN CAT GRID ==================== */

class ModernCatGrid extends StatelessWidget {
  const ModernCatGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: cats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 125,
        ),
        itemBuilder: (c, i) {
          final cat = cats[i];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                c,
                MaterialPageRoute(
                    builder: (_) => CategoryPostsPage(c: cat)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pnl,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: lineC),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cat.c.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat.i, color: cat.c, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        cat.n,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: txtC,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ==================== MODERN SOCIAL ==================== */

class ModernSocial extends StatelessWidget {
  const ModernSocial({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      [
        'تلگرام',
        Icons.send_rounded,
        'https://t.me/itarbiatbadani',
        const Color(0xff229ED9)
      ],
      [
        'اینستاگرام',
        Icons.camera_alt_rounded,
        'https://instagram.com/itarbiatbadani',
        const Color(0xffE1306C)
      ],
      [
        'بله',
        Icons.chat_rounded,
        'https://ble.ir/itarbiatbadani',
        const Color(0xff00b4a0)
      ],
      [
        'فروشگاه',
        Icons.shopping_cart_rounded,
        '$site/shop/',
        const Color(0xfff59e0b)
      ],
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accentGreen, accentGreen2],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.connect_without_contact_rounded,
                  color: accentGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ارتباط با ما',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: txtC,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3.0,
            ),
            itemBuilder: (c, i) => GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                openExternalUrl(items[i][2] as String);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: pnl,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: lineC),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[i][1] as IconData,
                        color: items[i][3] as Color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      items[i][0] as String,
                      style: TextStyle(
                        color: txtC,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        fontFamily: 'Vazirmatn',
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
}

/* ==================== MODERN SECTION TITLE ==================== */

class ModernSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const ModernSectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accentGreen, accentGreen2],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: accentGreen, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: txtC,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/* ==================== MODERN LIVE DOT ==================== */

class ModernLiveDot extends StatefulWidget {
  const ModernLiveDot({super.key});
  @override
  State<ModernLiveDot> createState() => _ModernLiveDotState();
}

class _ModernLiveDotState extends State<ModernLiveDot>
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
                  color: rose.withOpacity(opacity * 0.5),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xfff43f5e),
                ),
                child: SizedBox(width: 8, height: 8),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ==================== MODERN URGENT NEWS CARD ==================== */

class ModernUrgentNewsCard extends StatelessWidget {
  final dynamic news;
  const ModernUrgentNewsCard({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final title = pTitle(news);
    final link = pLink(news);
    final date = pDate(news);
    final excerpt = pExcerpt(news, maxChars: 140);

    int readTime = 1;
    try {
      final raw = clean(news['content']['rendered'] ?? '');
      final words =
          raw.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      readTime = (words / 200).ceil();
      if (readTime < 1) readTime = 1;
    } catch (_) {}

    return GestureDetector(
      onTap: () => openUrl(context, link),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: lineC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: -16,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accentBlue2, accentBlue],
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
                    Icon(Icons.schedule_rounded, size: 12, color: mutC),
                    const SizedBox(width: 5),
                    Text(
                      date,
                      style: TextStyle(
                        color: mutC,
                        fontSize: 11,
                        fontFamily: 'Vazirmatn',
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
                    Icon(Icons.access_time_rounded, size: 12, color: mutC),
                    const SizedBox(width: 4),
                    Text(
                      '$readTime دقیقه',
                      style: TextStyle(
                        color: mutC,
                        fontSize: 11,
                        fontFamily: 'Vazirmatn',
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    height: 1.6,
                    fontFamily: 'Vazirmatn',
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
                      color: inkSoft,
                      fontSize: 12,
                      height: 1.8,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(height: 1, color: softLine),
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
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_back_ios_new_rounded,
                            color: accentBlue, size: 11),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: rose.withOpacity(.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xfff43f5e),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'فوری',
                            style: TextStyle(
                              color: Color(0xfff43f5e),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
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
    // 👇 محاسبه پدینگ پایین بر اساس نوار ناوبری سیستم
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              const ModernLiveDot(),
              const SizedBox(width: 8),
              Text(
                'اخبار فوری',
                style: TextStyle(
                  color: txtC,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
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
              if (snapshot.connectionState == ConnectionState.waiting) {
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
                  message: 'خطا در دریافت اخبار.\n${snapshot.error}',
                  onRetry: _refresh,
                );
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const EmptyWidget(text: 'هنوز خبری منتشر نشده است.');
              }
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                // 👇 پدینگ پایین = ارتفاع نوار ناوبری گوشی + 100
                padding: EdgeInsets.fromLTRB(
                  0,
                  14,
                  0,
                  bottomInset + 100,
                ),
                itemCount: list.length,
                itemBuilder: (c, i) => ModernUrgentNewsCard(news: list[i]),
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
      showSnack(context, 'اطلاعات ورود پاک شد.');
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
            style: TextStyle(
                fontWeight: FontWeight.w900, fontFamily: 'Vazirmatn'),
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _clearSavedCredentials,
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: Colors.red),
              tooltip: 'پاک کردن اطلاعات ذخیره‌شده',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gold.withOpacity(0.2),
                      gold.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: gold.withOpacity(0.3)),
                ),
                child: Icon(Icons.lock_rounded, color: gold, size: 42),
              ),
              const SizedBox(height: 22),
              Text(
                'فقط مدیر سایت',
                style: TextStyle(
                  color: txtC,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'برای مدیریت اخبار فوری وارد شوید',
                style: TextStyle(
                  color: mutC,
                  fontSize: 12.5,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 30),
              _buildField(
                controller: _userCtrl,
                icon: Icons.person_rounded,
                hint: 'نام کاربری وردپرس',
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _passCtrl,
                icon: Icons.key_rounded,
                hint: 'Application Password',
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: mutC,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: pnl,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: lineC),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
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
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'مرا به خاطر بسپار',
                        style: TextStyle(
                          color: txtC,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.lock_outline_rounded,
                          color: mutC, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'ذخیره امن',
                        style: TextStyle(
                          color: mutC,
                          fontSize: 10,
                          fontFamily: 'Vazirmatn',
                        ),
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
                    color: rose.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: rose.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: rose, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: rose,
                            fontSize: 12,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: accentBlue.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_rounded,
                        color: accentBlue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'اطلاعات ورود شما به‌صورت رمزنگاری‌شده روی دستگاه ذخیره می‌شود.',
                        style: TextStyle(
                          color: mutC,
                          fontSize: 11,
                          height: 1.6,
                          fontFamily: 'Vazirmatn',
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

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineC),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textDirection: TextDirection.ltr,
        style: TextStyle(color: txtC, fontFamily: 'Vazirmatn'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: mutC, fontFamily: 'Vazirmatn'),
          prefixIcon: Icon(icon, color: accentGreen),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
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
      showSnack(context, 'عنوان و متن خبر را وارد کنید.', error: true);
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
      showSnack(context, 'خبر فوری منتشر شد!');
      _titleCtrl.clear();
      _contentCtrl.clear();
      _reloadList();
    } catch (e) {
      if (!mounted) return;
      showSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // 👇 دیالوگ ویرایش خبر
  Future<void> _showEditDialog(dynamic post) async {
    final titleCtrl = TextEditingController(text: pTitle(post));
    final contentCtrl = TextEditingController(
      text: clean(post['content']?['rendered'] ?? ''),
    );
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: pnl,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: accentBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.edit_rounded,
                                color: accentBlue, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ویرایش خبر فوری',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: txtC,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: saving
                                ? null
                                : () => Navigator.pop(ctx),
                            icon: Icon(Icons.close_rounded,
                                color: mutC, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'عنوان خبر',
                        style: TextStyle(
                          color: accentGreen,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: bgC,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: lineC),
                        ),
                        child: TextField(
                          controller: titleCtrl,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: txtC,
                            fontSize: 13.5,
                            fontFamily: 'Vazirmatn',
                          ),
                          decoration: InputDecoration(
                            hintText: 'عنوان خبر...',
                            hintStyle: TextStyle(
                                color: mutC, fontFamily: 'Vazirmatn'),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'متن کامل خبر',
                        style: TextStyle(
                          color: accentGreen,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: bgC,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: lineC),
                        ),
                        child: TextField(
                          controller: contentCtrl,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          maxLines: 6,
                          style: TextStyle(
                            color: txtC,
                            fontSize: 12.5,
                            height: 1.8,
                            fontFamily: 'Vazirmatn',
                          ),
                          decoration: InputDecoration(
                            hintText: 'متن خبر...',
                            hintStyle: TextStyle(
                                color: mutC, fontFamily: 'Vazirmatn'),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(ctx),
                              style: TextButton.styleFrom(
                                backgroundColor: bgC,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: lineC),
                                ),
                              ),
                              child: Text(
                                'انصراف',
                                style: TextStyle(
                                  color: mutC,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final t = titleCtrl.text.trim();
                                      final c = contentCtrl.text.trim();
                                      if (t.isEmpty || c.isEmpty) {
                                        showSnack(ctx,
                                            'عنوان و متن را وارد کنید.',
                                            error: true);
                                        return;
                                      }
                                      setDialogState(() => saving = true);
                                      try {
                                        await updateNews(
                                          username: widget.username,
                                          appPassword: widget.password,
                                          postId: post['id'],
                                          title: t,
                                          content: c,
                                        );
                                        if (!mounted) return;
                                        Navigator.pop(ctx);
                                        showSnack(context,
                                            '✅ خبر با موفقیت ویرایش شد!');
                                        _reloadList();
                                      } catch (e) {
                                        if (!mounted) return;
                                        setDialogState(() => saving = false);
                                        showSnack(
                                          ctx,
                                          e.toString()
                                              .replaceFirst('Exception: ', ''),
                                          error: true,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: Text(
                                saving ? 'در حال ذخیره...' : 'ذخیره تغییرات',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _delete(dynamic post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pnl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'حذف خبر',
          style: TextStyle(
            color: txtC,
            fontWeight: FontWeight.w900,
            fontFamily: 'Vazirmatn',
          ),
        ),
        content: Text(
          'آیا از حذف «${pTitle(post)}» مطمئن هستید؟',
          style: TextStyle(color: mutC, fontFamily: 'Vazirmatn'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('انصراف',
                style:
                    TextStyle(color: mutC, fontFamily: 'Vazirmatn')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف',
                style: TextStyle(
                    color: rose,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn')),
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
      showSnack(context, 'خبر حذف شد.');
      _reloadList();
    } catch (e) {
      if (!mounted) return;
      showSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 👇 محاسبه پدینگ پایین بر اساس نوار ناوبری سیستم
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: const Text(
            'پنل مدیریت اخبار فوری',
            style: TextStyle(
                fontWeight: FontWeight.w900, fontFamily: 'Vazirmatn'),
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          // 👇 پدینگ پایین = ارتفاع نوار ناوبری گوشی + 120
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: accentBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: accentBlue, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'خبر فوری پس از انتشار، بالای صفحه اصلی اپ نمایش داده می‌شود و تا زمانی که حذف نکنید باقی می‌ماند.',
                        style: TextStyle(
                          color: txtC,
                          fontSize: 12,
                          height: 1.6,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'عنوان خبر',
                style: TextStyle(
                  color: accentGreen,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: pnl,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: lineC),
                ),
                child: TextField(
                  controller: _titleCtrl,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: txtC, fontSize: 14, fontFamily: 'Vazirmatn'),
                  decoration: InputDecoration(
                    hintText: 'مثلاً: ثبت‌نام دوره جدید آغاز شد',
                    hintStyle: TextStyle(
                        color: mutC, fontFamily: 'Vazirmatn'),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.all(15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'متن کامل خبر',
                style: TextStyle(
                  color: accentGreen,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: pnl,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: lineC),
                ),
                child: TextField(
                  controller: _contentCtrl,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 6,
                  style: TextStyle(
                    color: txtC,
                    fontSize: 13,
                    height: 1.8,
                    fontFamily: 'Vazirmatn',
                  ),
                  decoration: InputDecoration(
                    hintText: 'توضیحات کامل خبر...',
                    hintStyle: TextStyle(
                        color: mutC, fontFamily: 'Vazirmatn'),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.all(15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    _sending ? 'در حال ارسال...' : 'انتشار خبر فوری',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Divider(color: lineC),
              const SizedBox(height: 14),
              Text(
                'اخبار منتشر شده',
                style: TextStyle(
                  color: txtC,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
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
                            color: accentGreen),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'خطا: ${snapshot.error}',
                      style: TextStyle(
                          color: rose, fontFamily: 'Vazirmatn'),
                    );
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'هنوز خبری منتشر نشده است.',
                          style: TextStyle(
                              color: mutC,
                              fontFamily: 'Vazirmatn'),
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
                          borderRadius: BorderRadius.circular(14),
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
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: txtC,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.6,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  if (pDate(p).isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      pDate(p),
                                      style: TextStyle(
                                        color: mutC,
                                        fontSize: 10.5,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () => _showEditDialog(p),
                              icon: Icon(
                                Icons.edit_rounded,
                                color: accentBlue,
                                size: 22,
                              ),
                              tooltip: 'ویرایش',
                            ),
                            IconButton(
                              onPressed: () => _delete(p),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: rose,
                                size: 22,
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
/* ==================== SHIMMER BOX ==================== */

class ShimmerBox extends StatefulWidget {
  final double height;
  final double width;
  final double radius;
  const ShimmerBox({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = 16,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value + 1, 0),
              colors: [
                skeletonBase,
                skeletonHi,
                skeletonBase,
              ],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/* ==================== POST SKELETON ==================== */

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lineC),
      ),
      child: Row(
        children: const [
          ShimmerBox(height: 90, width: 90, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 12, width: 80, radius: 6),
                SizedBox(height: 10),
                ShimmerBox(height: 14),
                SizedBox(height: 6),
                ShimmerBox(height: 14, width: 180),
                SizedBox(height: 10),
                ShimmerBox(height: 10, width: 60, radius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== FEATURED SKELETON ==================== */

class FeaturedSkeleton extends StatelessWidget {
  const FeaturedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: lineC),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            child: ShimmerBox(height: 200, radius: 0),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 12, width: 90, radius: 6),
                SizedBox(height: 12),
                ShimmerBox(height: 16),
                SizedBox(height: 8),
                ShimmerBox(height: 16, width: 220),
                SizedBox(height: 14),
                ShimmerBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== EMPTY WIDGET ==================== */

class EmptyWidget extends StatelessWidget {
  final String text;
  const EmptyWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: pnl2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                color: mutC,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutC,
                fontSize: 13,
                height: 1.7,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== ERROR BOX ==================== */

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
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: rose.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: rose,
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: txtC,
                fontSize: 13,
                height: 1.7,
                fontFamily: 'Vazirmatn',
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff10b981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'تلاش مجدد',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
