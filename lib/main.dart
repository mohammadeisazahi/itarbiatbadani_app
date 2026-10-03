import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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

/* ==================== ACCENT COLOR ==================== */

final accentNotifier = ValueNotifier<Color>(const Color(0xff10b981));

const List<Color> accentPalette = [
  Color(0xff10b981),
  Color(0xff3b82f6),
  Color(0xff8b5cf6),
  Color(0xfff43f5e),
  Color(0xfff59e0b),
  Color(0xff06b6d4),
  Color(0xffec4899),
  Color(0xff6366f1),
];

Future<void> loadAccentColor() async {
  try {
    final saved = await _storage.read(key: 'accent_color');
    if (saved != null && saved.isNotEmpty) {
      final v = int.tryParse(saved);
      if (v != null) accentNotifier.value = Color(v);
    }
  } catch (_) {}
}

Future<void> saveAccentColor(Color c) async {
  accentNotifier.value = c;
  try {
    await _storage.write(key: 'accent_color', value: c.value.toString());
  } catch (_) {}
}

/* ==================== THEME COLORS ==================== */

Color get bgC => darkModeNotifier.value ? const Color(0xff0b1220) : const Color(0xfff6f8fb);
Color get bgGrad1 => darkModeNotifier.value ? const Color(0xff0b1220) : const Color(0xfff6f8fb);
Color get bgGrad2 => darkModeNotifier.value ? const Color(0xff101a2e) : const Color(0xffeef3fb);
Color get pnl => darkModeNotifier.value ? const Color(0xff141f36) : const Color(0xffffffff);
Color get pnl2 => darkModeNotifier.value ? const Color(0xff1c2b48) : const Color(0xffeef3fa);
Color get pnl3 => darkModeNotifier.value ? const Color(0xff243456) : const Color(0xffe3ecf7);
Color get txtC => darkModeNotifier.value ? const Color(0xfff1f5fb) : const Color(0xff0c1a2b);
Color get mutC => darkModeNotifier.value ? const Color(0xff8fa3bf) : const Color(0xff5c6b83);
Color get accentGreen => accentNotifier.value;
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
    if (saved != null) {
      darkModeNotifier.value = saved == 'true';
    } else {
      final hour = DateTime.now().hour;
      darkModeNotifier.value = (hour >= 18 || hour < 6);
    }
    await loadBookmarks();
    await loadAccentColor();
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
        return ValueListenableBuilder<Color>(
          valueListenable: accentNotifier,
          builder: (c, accent, _) {
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
                  seedColor: accent,
                  brightness: isDark ? Brightness.dark : Brightness.light,
                ),
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android:
                        CupertinoPageTransitionsBuilder(),
                  },
                ),
              ),
              builder: (c, ch) => Directionality(
                textDirection: TextDirection.rtl,
                child: ch ?? const SizedBox(),
              ),
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

/* ==================== SPLASH SCREEN ==================== */

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _ctrl.forward();

    Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, anim, __) => FadeTransition(
              opacity: anim,
              child: const Root(),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = darkModeNotifier.value;
    return Scaffold(
      backgroundColor: bgC,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xff0b1220),
                    const Color(0xff141f36),
                    const Color(0xff1a0f2e),
                  ]
                : [
                    const Color(0xfff6f8fb),
                    const Color(0xffeef3fb),
                    const Color(0xfffff5f7),
                  ],
          ),
        ),
        child: Stack(
          children: [
            ...List.generate(15, (i) => _buildParticle(i)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              accentNotifier.value,
                              accentBlue,
                              purple,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentNotifier.value
                                  .withOpacity(0.45),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: accentBlue.withOpacity(0.25),
                              blurRadius: 60,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              logo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.network(
                                logoNet,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.sports_soccer_rounded,
                                  color: accentNotifier.value,
                                  size: 60,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          Text(
                            'تربیت بدنی و علوم ورزشی',
                            style: TextStyle(
                              color: txtC,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'مرجع تخصصی ورزش ایران',
                            style: TextStyle(
                              color: mutC,
                              fontSize: 13,
                              fontFamily: 'Vazirmatn',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          const _DotsLoader(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticle(int i) {
    final random = math.Random(i);
    final size = 4.0 + random.nextDouble() * 8;
    final left = random.nextDouble();
    final top = random.nextDouble();
    return Positioned(
      left: left * MediaQuery.of(context).size.width,
      top: top * MediaQuery.of(context).size.height,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Opacity(
            opacity: (0.1 + random.nextDouble() * 0.3) *
                (1 - t) *
                (0.5 + math.sin(t * 10 + i) * 0.5),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentPalette[i % accentPalette.length],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DotsLoader extends StatefulWidget {
  const _DotsLoader();
  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = (i * 0.2);
            final v = ((_ctrl.value - offset) % 1.0);
            final scale = v < 0.5 ? (v * 2) : (2 - v * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentNotifier.value
                    .withOpacity(0.3 + scale * 0.7),
              ),
            );
          }),
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
                  : accentNotifier.value.withOpacity(0.15),
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
                            ? accentNotifier.value.withOpacity(0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: selected
                            ? Border.all(
                                color: accentNotifier.value
                                    .withOpacity(0.5),
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
                                ? accentNotifier.value
                                : txtC.withOpacity(0.75),
                            size: selected ? 26 : 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              color: selected
                                  ? accentNotifier.value
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
    HapticFeedback.mediumImpact();
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
        child: Stack(
          children: [
            // Mesh Gradient متحرک
            Positioned(
              top: -100,
              right: -100,
              child: _AnimatedBlob(
                color: accentNotifier.value,
                size: 300,
                duration: const Duration(seconds: 8),
              ),
            ),
            Positioned(
              top: 200,
              left: -120,
              child: _AnimatedBlob(
                color: accentBlue,
                size: 250,
                duration: const Duration(seconds: 10),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -100,
              child: _AnimatedBlob(
                color: purple,
                size: 220,
                duration: const Duration(seconds: 12),
              ),
            ),
            RefreshIndicator(
              color: accentNotifier.value,
              backgroundColor: pnl,
              strokeWidth: 3,
              displacement: 60,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: ModernHeader(context)),
                  SliverToBoxAdapter(
                    child: LiveNewsTicker(future: _newsFuture),
                  ),
                  SliverToBoxAdapter(
                    child: CategoryChipsBar(),
                  ),
                  SliverToBoxAdapter(
                    child: HeroCarousel(postsFuture: _f),
                  ),
                  SliverToBoxAdapter(
                    child: ModernNewsBanner(
                        key: _bannerKey, future: _newsFuture),
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
          ],
        ),
      ),
    );
  }
}

/* ==================== ANIMATED BLOB ==================== */

class _AnimatedBlob extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  const _AnimatedBlob({
    required this.color,
    required this.size,
    required this.duration,
  });

  @override
  State<_AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<_AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = darkModeNotifier.value;
    final opacity = isDark ? 0.10 : 0.06;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final v = _ctrl.value;
        return Transform.translate(
          offset: Offset(
            (v - 0.5) * 40,
            (v - 0.5) * 30,
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withOpacity(opacity),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
/* ==================== MODERN HEADER (PRO) ==================== */

Widget ModernHeader(BuildContext context, [String? t]) {
  return SafeArea(
    bottom: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  accentNotifier.value,
                  accentBlue,
                  accentNotifier.value.withOpacity(0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accentNotifier.value.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  logo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.network(
                    logoNet,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.sports_soccer_rounded,
                      color: accentNotifier.value,
                    ),
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
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [txtC, accentNotifier.value],
                  ).createShader(bounds),
                  child: Text(
                    t ?? 'تربیت بدنی و ورزش',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accentNotifier.value,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentNotifier.value.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'آنلاین • به‌روزرسانی زنده',
                      style: TextStyle(
                        color: mutC,
                        fontSize: 10.5,
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  accentNotifier.value,
                  accentBlue,
                  accentNotifier.value.withOpacity(0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accentNotifier.value.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  logo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.network(
                    logoNet,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.sports_soccer_rounded,
                      color: accentNotifier.value,
                    ),
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
    final isDark = darkModeNotifier.value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: color ?? txtC, size: 20),
      ),
    );
  }
}

/* ==================== LIVE NEWS TICKER ==================== */

class LiveNewsTicker extends StatefulWidget {
  final Future<List>? future;
  const LiveNewsTicker({super.key, this.future});

  @override
  State<LiveNewsTicker> createState() => _LiveNewsTickerState();
}

class _LiveNewsTickerState extends State<LiveNewsTicker> {
  List<String> _titles = [];
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTitles();
  }

  Future<void> _loadTitles() async {
    if (widget.future == null) return;
    try {
      final list = await widget.future!;
      if (!mounted) return;
      _titles = list.take(10).map((e) => pTitle(e)).toList();
      if (_titles.isNotEmpty) _startTicker();
    } catch (_) {}
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _currentIndex = (_currentIndex + 1) % _titles.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_titles.isEmpty) return const SizedBox.shrink();
    final isDark = darkModeNotifier.value;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xff1a0f2e).withOpacity(0.9),
                  const Color(0xff2a0d1a).withOpacity(0.9),
                ]
              : [
                  const Color(0xfffff5f7),
                  const Color(0xfffff8f0),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xfff43f5e).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xfff43f5e).withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xfff43f5e), Color(0xffbe123c)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xfff43f5e).withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WhiteLiveDot(),
                SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
              child: Text(
                _titles[_currentIndex],
                key: ValueKey(_currentIndex),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: txtC,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

/* ==================== CATEGORY CHIPS BAR ==================== */

class CategoryChipsBar extends StatefulWidget {
  const CategoryChipsBar({super.key});

  @override
  State<CategoryChipsBar> createState() => _CategoryChipsBarState();
}

class _CategoryChipsBarState extends State<CategoryChipsBar> {
  int _selected = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: cats.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (c, i) {
          if (i == 0) {
            final sel = _selected == -1;
            return _chip(
              label: 'همه',
              icon: Icons.apps_rounded,
              color: accentNotifier.value,
              selected: sel,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selected = -1);
              },
            );
          }
          final cat = cats[i - 1];
          final sel = _selected == i - 1;
          return _chip(
            label: cat.n.length > 20
                ? '${cat.n.substring(0, 18)}...'
                : cat.n,
            icon: cat.i,
            color: cat.c,
            selected: sel,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selected = i - 1);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryPostsPage(c: cat),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = darkModeNotifier.value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                )
              : null,
          color: selected
              ? null
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? color
                : (isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.06)),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : txtC,
                fontSize: 12,
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

/* ==================== WHITE LIVE DOT ==================== */

class _WhiteLiveDot extends StatefulWidget {
  const _WhiteLiveDot();

  @override
  State<_WhiteLiveDot> createState() => _WhiteLiveDotState();
}

class _WhiteLiveDotState extends State<_WhiteLiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        final scale = 1.0 + (t < 0.5 ? t * 0.6 : (1 - t) * 0.6);
        final opacity = 1.0 - t;
        return SizedBox(
          width: 12,
          height: 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12 * scale,
                height: 12 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(opacity * 0.6),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
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
                ? accentNotifier.value
                : mutC.withOpacity(0.3),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accentNotifier.value.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _CarouselCard extends StatefulWidget {
  final dynamic post;
  const _CarouselCard({required this.post});

  @override
  State<_CarouselCard> createState() => _CarouselCardState();
}

class _CarouselCardState extends State<_CarouselCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ken;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _ken = Tween<double>(begin: 1.0, end: 1.12).animate(
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
    final title = pTitle(widget.post);
    final img = pImgFull(widget.post);
    final cat = pCategory(widget.post);
    final link = pLink(widget.post);
    final date = pTimeAgo(widget.post);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        openUrl(context, link);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (img.isNotEmpty)
                AnimatedBuilder(
                  animation: _ken,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _ken.value,
                      child: CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        memCacheWidth: 1080,
                        fadeInDuration: const Duration(milliseconds: 400),
                        placeholder: (_, __) => Container(color: pnl2),
                        errorWidget: (_, __, ___) => Container(
                          color: pnl2,
                          child: Icon(Icons.article_rounded,
                              color: accentNotifier.value, size: 60),
                        ),
                      ),
                    );
                  },
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
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.2, 0.6, 1.0],
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
                    Row(
                      children: [
                        if (cat.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentNotifier.value,
                                  accentNotifier.value.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: accentNotifier.value
                                      .withOpacity(0.5),
                                  blurRadius: 12,
                                ),
                              ],
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
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  color: Colors.white70, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.5,
                        fontFamily: 'Vazirmatn',
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'مطالعه',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              SizedBox(width: 4),
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
              child: Center(
                child: CircularProgressIndicator(
                  color: accentNotifier.value,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: 180,
            color: pnl2,
            child: Icon(Icons.sports_soccer_rounded,
                color: accentNotifier.value, size: 60),
          ),
        ),
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
                    const _WhiteLiveDotRed(),
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

class _WhiteLiveDotRed extends StatefulWidget {
  const _WhiteLiveDotRed();
  @override
  State<_WhiteLiveDotRed> createState() => _WhiteLiveDotRedState();
}

class _WhiteLiveDotRedState extends State<_WhiteLiveDotRed>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        final scale = 1.0 + (t < 0.5 ? t * 0.6 : (1 - t) * 0.6);
        final opacity = 1.0 - t;
        return SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 14 * scale,
                height: 14 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xfff43f5e).withOpacity(opacity * 0.5),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xfff43f5e),
                ),
              ),
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
                          child: Icon(Icons.article_rounded,
                              color: accentNotifier.value, size: 32),
                        ),
                      )
                    : Container(
                        color: pnl2,
                        child: Icon(Icons.article_rounded,
                            color: accentNotifier.value, size: 32),
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
                          child: Icon(Icons.article_rounded,
                              color: accentNotifier.value, size: 60),
                        ),
                      )
                    else
                      Container(
                        color: pnl2,
                        child: Icon(Icons.article_rounded,
                            color: accentNotifier.value, size: 60),
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
                          color: accentNotifier.value.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مطالعه',
                              style: TextStyle(
                                color: accentNotifier.value,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_back_rounded,
                                color: accentNotifier.value, size: 12),
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
                          child: Icon(Icons.article_rounded,
                              color: accentNotifier.value, size: 26),
                        ),
                      )
                    : Container(
                        color: pnl2,
                        child: Icon(Icons.article_rounded,
                            color: accentNotifier.value, size: 26),
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
                              child: Icon(
                                  Icons.shopping_bag_rounded,
                                  color: accentNotifier.value,
                                  size: 32),
                            ),
                          )
                        : Container(
                            color: pnl2,
                            child: Icon(
                                Icons.shopping_bag_rounded,
                                color: accentNotifier.value,
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
                          color: inStock ? accentGreen2 : rose,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          inStock ? 'موجود' : 'ناموجود',
                          style: TextStyle(
                            color: inStock ? accentGreen2 : rose,
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
                    colors: [accentNotifier.value, accentGreen2],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.connect_without_contact_rounded,
                  color: accentNotifier.value, size: 20),
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
                  colors: [accentNotifier.value, accentGreen2],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: accentNotifier.value, size: 20),
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
                  color: const Color(0xfff43f5e).withOpacity(opacity * 0.5),
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

class ModernUrgentNewsCard extends StatefulWidget {
  final dynamic news;
  const ModernUrgentNewsCard({
    super.key,
    required this.news,
  });

  @override
  State<ModernUrgentNewsCard> createState() => _ModernUrgentNewsCardState();
}

class _ModernUrgentNewsCardState extends State<ModernUrgentNewsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  int _readTimeMinutes(dynamic news) {
    try {
      final raw = clean(news['content']?['rendered'] ?? '');
      final words =
          raw.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final m = (words / 200).ceil();
      return m < 1 ? 1 : m;
    } catch (_) {
      return 1;
    }
  }

  double _freshnessValue(dynamic news) {
    try {
      final d = DateTime.parse(news['date']).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return 1.0;
      if (diff.inHours < 6) return 0.75;
      if (diff.inHours < 24) return 0.5;
      if (diff.inDays < 3) return 0.3;
      return 0.15;
    } catch (_) {
      return 0.2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.news;
    final title = pTitle(news);
    final date = pTimeAgo(news);
    final excerpt = pExcerpt(news, maxChars: 120);
    final readTime = _readTimeMinutes(news);
    final freshness = _freshnessValue(news);
    final isDark = darkModeNotifier.value;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UrgentNewsDetailPage(news: news),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark
                ? [
                    const Color(0xff2a0d1a),
                    const Color(0xff1a0f2e),
                    const Color(0xff141f36),
                  ]
                : [
                    const Color(0xfffff5f7),
                    const Color(0xfffff8f0),
                    const Color(0xffffffff),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed
                ? const Color(0xfff43f5e)
                : const Color(0xfff43f5e).withOpacity(isDark ? 0.35 : 0.25),
            width: _pressed ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xfff43f5e)
                  .withOpacity(_pressed ? 0.35 : 0.15),
              blurRadius: _pressed ? 28 : 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xfffb923c)
                  .withOpacity(_pressed ? 0.25 : 0.10),
              blurRadius: _pressed ? 20 : 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xfff43f5e)
                            .withOpacity(isDark ? 0.35 : 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xfffb923c)
                            .withOpacity(isDark ? 0.22 : 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) {
                    final t = _pulseCtrl.value;
                    final glow = 0.7 + (t < 0.5 ? t : 1 - t) * 0.3;
                    return Container(
                      width: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xfff43f5e).withOpacity(glow),
                            const Color(0xfffb923c),
                            const Color(0xfffbbf24),
                            const Color(0xfffb923c),
                            const Color(0xfff43f5e).withOpacity(glow),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xfff43f5e)
                                .withOpacity(glow * 0.6),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Color(0xfff43f5e),
                                Color(0xfffb923c),
                                Color(0xfffbbf24),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xfff43f5e)
                                    .withOpacity(0.5),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: const Color(0xfffbbf24)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xfff43f5e),
                                Color(0xffbe123c),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xfff43f5e)
                                    .withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _WhiteLiveDotSmall(),
                              SizedBox(width: 6),
                              Text(
                                'فوری',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.schedule_rounded,
                            size: 12, color: mutC),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(
                            color: mutC,
                            fontSize: 10.5,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: txtC,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.6,
                        fontFamily: 'Vazirmatn',
                        shadows: isDark
                            ? [
                                Shadow(
                                  color: const Color(0xfff43f5e)
                                      .withOpacity(0.15),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 4,
                        color: isDark
                            ? const Color(0xff2a1a2e)
                            : const Color(0xffffe4e6),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: freshness,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xfff43f5e),
                                  Color(0xfffb923c),
                                  Color(0xfffbbf24),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xfffbbf24)
                                      .withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: const Color(0xfff43f5e)
                          .withOpacity(isDark ? 0.15 : 0.12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 12, color: Color(0xfffb923c)),
                        const SizedBox(width: 4),
                        Text(
                          '$readTime دقیقه مطالعه',
                          style: TextStyle(
                            color: mutC,
                            fontSize: 10.5,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xfff43f5e),
                                Color(0xfffb923c),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xfff43f5e)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'خواندن کامل',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 10,
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

/* ==================== WHITE LIVE DOT SMALL ==================== */

class _WhiteLiveDotSmall extends StatefulWidget {
  const _WhiteLiveDotSmall();

  @override
  State<_WhiteLiveDotSmall> createState() => _WhiteLiveDotSmallState();
}

class _WhiteLiveDotSmallState extends State<_WhiteLiveDotSmall>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        final scale = 1.0 + (t < 0.5 ? t * 0.6 : (1 - t) * 0.6);
        final opacity = 1.0 - t;
        return SizedBox(
          width: 12,
          height: 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12 * scale,
                height: 12 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(opacity * 0.6),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
/* ==================== URGENT NEWS DETAIL PAGE ==================== */

class UrgentNewsDetailPage extends StatefulWidget {
  final dynamic news;
  const UrgentNewsDetailPage({
    super.key,
    required this.news,
  });

  @override
  State<UrgentNewsDetailPage> createState() => _UrgentNewsDetailPageState();
}

class _UrgentNewsDetailPageState extends State<UrgentNewsDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final _scroll = ScrollController();
  bool _showAppBar = false;
  double _readingProgress = 0;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    ));
    _entryCtrl.forward();

    _scroll.addListener(() {
      final show = _scroll.offset > 120;
      if (show != _showAppBar) {
        setState(() => _showAppBar = show);
      }
      if (_scroll.hasClients) {
        final max = _scroll.position.maxScrollExtent;
        if (max > 0) {
          final p = (_scroll.offset / max).clamp(0.0, 1.0);
          if ((p - _readingProgress).abs() > 0.01) {
            setState(() => _readingProgress = p);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _fullContent(dynamic news) {
    try {
      final raw = news['content']?['rendered'] ?? '';
      return clean(raw);
    } catch (_) {
      return '';
    }
  }

  int _wordCount(String text) {
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  int _readTime(int words) {
    final m = (words / 200).ceil();
    return m < 1 ? 1 : m;
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.news;
    final title = pTitle(news);
    final date = pDate(news);
    final link = pLink(news);
    final content = _fullContent(news);
    final words = _wordCount(content);
    final readTime = _readTime(words);

    final paragraphs = content
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: bgC,
            body: Stack(
              children: [
                CustomScrollView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.top + 60,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: _buildTitleCard(
                              title, date, readTime, words),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: _buildContentCard(paragraphs),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildShareSection(title, link),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildRelatedSection(),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 60),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      height: 3,
                      color: Colors.transparent,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _readingProgress,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xfff43f5e),
                                  Color(0xfffb923c),
                                  Color(0xfffbbf24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildGlassAppBar(title),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassAppBar(String title) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: MediaQuery.of(context).padding.top + 56,
      decoration: BoxDecoration(
        color: _showAppBar
            ? (darkModeNotifier.value
                ? const Color(0xff0b1220).withOpacity(0.85)
                : Colors.white.withOpacity(0.85))
            : Colors.transparent,
        border: _showAppBar
            ? Border(bottom: BorderSide(color: lineC, width: 0.5))
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _glassIconBtn(
                icon: Icons.arrow_forward_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              if (_showAppBar)
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showAppBar ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: txtC,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              _glassIconBtn(
                icon: Icons.ios_share_rounded,
                onTap: () => sharePost(
                  pLink(widget.news),
                  pTitle(widget.news),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassIconBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _showAppBar ? pnl : pnl.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lineC),
        ),
        child: Icon(icon, color: txtC, size: 20),
      ),
    );
  }

  Widget _buildTitleCard(
    String title,
    String date,
    int readTime,
    int words,
  ) {
    final isDark = darkModeNotifier.value;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  const Color(0xff3a0f22),
                  const Color(0xff2a1030),
                  const Color(0xff1a1236),
                ]
              : [
                  const Color(0xffffebee),
                  const Color(0xfffff3e0),
                  const Color(0xfffffff8),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xfff43f5e).withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xfff43f5e).withOpacity(0.25),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xfffbbf24).withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xfff43f5e)
                          .withOpacity(isDark ? 0.4 : 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xfffbbf24)
                          .withOpacity(isDark ? 0.3 : 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Color(0xfff43f5e),
                            Color(0xfffb923c),
                            Color(0xfffbbf24),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xfff43f5e)
                                .withOpacity(0.55),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                          BoxShadow(
                            color: const Color(0xfffbbf24)
                                .withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xfff43f5e),
                            Color(0xffbe123c),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xfff43f5e)
                                .withOpacity(0.5),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _WhiteLiveDotSmall(),
                          SizedBox(width: 6),
                          Text(
                            'خبر فوری',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xfffbbf24).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xfffbbf24).withOpacity(0.4),
                        ),
                      ),
                      child: Icon(
                        Icons.newspaper_rounded,
                        color: const Color(0xfffbbf24).withOpacity(0.9),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: txtC,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.6,
                    fontFamily: 'Vazirmatn',
                    shadows: isDark
                        ? [
                            Shadow(
                              color: const Color(0xfff43f5e)
                                  .withOpacity(0.2),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xfff43f5e).withOpacity(0.6),
                        const Color(0xfffb923c).withOpacity(0.4),
                        const Color(0xfffbbf24).withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _infoChip(
                      icon: Icons.calendar_today_rounded,
                      label: date,
                      color: const Color(0xfff43f5e),
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      icon: Icons.access_time_rounded,
                      label: '$readTime دقیقه',
                      color: const Color(0xfffb923c),
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      icon: Icons.text_fields_rounded,
                      label: '$words کلمه',
                      color: const Color(0xfffbbf24),
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

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = darkModeNotifier.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? color.withOpacity(0.18)
            : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isDark ? color.withOpacity(0.95) : color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(List<String> paragraphs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineC),
      ),
      child: paragraphs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'متنی برای این خبر ثبت نشده است.',
                  style: TextStyle(
                    color: mutC,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xfff43f5e),
                            Color(0xffbe123c),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'متن کامل خبر',
                      style: TextStyle(
                        color: txtC,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...paragraphs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: i == paragraphs.length - 1 ? 0 : 16),
                    child: Text(
                      p,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: txtC,
                        fontSize: 15,
                        height: 2.1,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }

  Widget _buildShareSection(String title, String link) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff3b82f6),
                      Color(0xff1d4ed8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'اشتراک‌گذاری خبر',
                style: TextStyle(
                  color: txtC,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _shareBtn(
                icon: Icons.send_rounded,
                label: 'تلگرام',
                color: const Color(0xff229ED9),
                onTap: () => openExternalUrl(
                  'https://t.me/share/url?url=$link&text=$title',
                ),
              ),
              const SizedBox(width: 8),
              _shareBtn(
                icon: Icons.chat_rounded,
                label: 'واتس‌اپ',
                color: const Color(0xff25D366),
                onTap: () => openExternalUrl(
                  'https://wa.me/?text=$title\n$link',
                ),
              ),
              const SizedBox(width: 8),
              _shareBtn(
                icon: Icons.ios_share_rounded,
                label: 'بیشتر',
                color: purple,
                onTap: () => _showShareSheet(title, link),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showShareSheet(String title, String link) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: pnl,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(color: lineC),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: mutC.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xfff43f5e), Color(0xfffb923c)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.ios_share_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'اشتراک‌گذاری خبر',
                    style: TextStyle(
                      color: txtC,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _sheetOption(
                    icon: Icons.send_rounded,
                    label: 'تلگرام',
                    color: const Color(0xff229ED9),
                    onTap: () {
                      Navigator.pop(ctx);
                      openExternalUrl(
                        'https://t.me/share/url?url=$link&text=$title',
                      );
                    },
                  ),
                  _sheetOption(
                    icon: Icons.chat_rounded,
                    label: 'واتس‌اپ',
                    color: const Color(0xff25D366),
                    onTap: () {
                      Navigator.pop(ctx);
                      openExternalUrl(
                        'https://wa.me/?text=$title\n$link',
                      );
                    },
                  ),
                  _sheetOption(
                    icon: Icons.email_rounded,
                    label: 'ایمیل',
                    color: const Color(0xffea4335),
                    onTap: () {
                      Navigator.pop(ctx);
                      openExternalUrl(
                        'mailto:?subject=$title&body=$link',
                      );
                    },
                  ),
                  _sheetOption(
                    icon: Icons.copy_rounded,
                    label: 'کپی لینک',
                    color: accentNotifier.value,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: link));
                      Navigator.pop(ctx);
                      showSnack(context, 'لینک کپی شد ✅');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pnl2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lineC),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, color: mutC, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        link,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: mutC,
                          fontSize: 11,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: txtC,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedSection() {
    return FutureBuilder<List>(
      future: getNewNewsList(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final list = (snapshot.data ?? [])
            .where((n) => pId(n) != pId(widget.news))
            .take(3)
            .toList();
        if (list.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pnl,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: lineC),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xfff43f5e),
                          Color(0xffbe123c),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'اخبار فوری دیگر',
                    style: TextStyle(
                      color: txtC,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...list.map((n) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UrgentNewsDetailPage(news: n),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: pnl2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: lineC, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xfff43f5e)
                                  .withOpacity(.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xfff43f5e),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              pTitle(n),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: txtC,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                height: 1.6,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_back_ios_new_rounded,
                              color: mutC, size: 12),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
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
          color: accentNotifier.value,
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
                              ? accentNotifier.value
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _rememberMe
                                ? accentNotifier.value
                                : mutC,
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
                    backgroundColor: accentNotifier.value,
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
          prefixIcon: Icon(icon, color: accentNotifier.value),
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
                          color: accentNotifier.value,
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
                          color: accentNotifier.value,
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
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
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
                                        setDialogState(
                                            () => saving = false);
                                        showSnack(
                                          ctx,
                                          e.toString().replaceFirst(
                                              'Exception: ', ''),
                                          error: true,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
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
                                  : const Icon(Icons.save_rounded,
                                      size: 18),
                              label: Text(
                                saving
                                    ? 'در حال ذخیره...'
                                    : 'ذخیره تغییرات',
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
                  color: accentNotifier.value,
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
                  color: accentNotifier.value,
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
                            color: accentNotifier.value),
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
                  backgroundColor: accentNotifier.value,
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
