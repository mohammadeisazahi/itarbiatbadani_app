import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
final themeModeNotifier = ValueNotifier<String>('auto');
final bookmarkNotifier = ValueNotifier<Set<String>>({});
final newsBookmarkNotifier = ValueNotifier<Set<String>>({});
final productBookmarkNotifier = ValueNotifier<Set<String>>({});
final offlineArticlesNotifier = ValueNotifier<Set<String>>({});
final followedCategoriesNotifier = ValueNotifier<Set<String>>({});
final inAppNotificationsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
final lastNewsCheckNotifier = ValueNotifier<String>('');
final accentNotifier = ValueNotifier<Color>(const Color(0xff1e3a5f));

/* ==================== ACADEMIC UNIVERSITY COLORS ==================== */

const Color kAcademicNavy = Color(0xff1e3a5f);
const Color kAcademicNavyDark = Color(0xff152a47);
const Color kAcademicNavyLight = Color(0xff2d5080);
const Color kAcademicGold = Color(0xffc9a961);
const Color kAcademicGoldDark = Color(0xffa88840);
const Color kAcademicGoldLight = Color(0xffe0c987);
const Color kAcademicBurgundy = Color(0xff7b2d26);
const Color kAcademicCream = Color(0xfff5f0e6);
const Color kAcademicCream2 = Color(0xfffaf7f0);
const Color kAcademicLeather = Color(0xff5c4033);
const Color kAcademicInk = Color(0xff1a1a1a);
const Color kAcademicParchment = Color(0xfff0e8d8);

const Color kDarkBg = Color(0xff0f1b2d);
const Color kDarkCard = Color(0xff1a2a42);
const Color kDarkCard2 = Color(0xff243651);
const Color kDarkLine = Color(0xff2d4260);

const Color kLightBg = Color(0xfff8f5ed);
const Color kLightCard = Color(0xffffffff);
const Color kLightCard2 = Color(0xfff5f0e6);
const Color kLightLine = Color(0xffe5dcc8);

const List<Color> accentPalette = [
  Color(0xff1e3a5f),
  Color(0xff046a38),
  Color(0xff7b2d26),
  Color(0xff003d7a),
  Color(0xff5c4033),
  Color(0xff00695c),
  Color(0xff4a148c),
  Color(0xff8b6914),
];
/* ==================== THEME COLORS ==================== */

Color get bgC => darkModeNotifier.value ? kDarkBg : kLightBg;
Color get bgGrad1 => darkModeNotifier.value ? kDarkBg : kLightBg;
Color get bgGrad2 =>
    darkModeNotifier.value ? const Color(0xff152a47) : kAcademicCream;

Color get pnl => darkModeNotifier.value ? kDarkCard : kLightCard;
Color get pnl2 => darkModeNotifier.value ? kDarkCard2 : kLightCard2;
Color get pnl3 =>
    darkModeNotifier.value ? const Color(0xff2e4265) : kAcademicParchment;

Color get txtC =>
    darkModeNotifier.value ? const Color(0xfff0e8d8) : kAcademicInk;
Color get mutC =>
    darkModeNotifier.value ? const Color(0xff8794ac) : const Color(0xff6b6b6b);

Color get accentGreen => accentNotifier.value;
Color get accentGreen2 => kAcademicGold;
Color get accentBlue => kAcademicNavyLight;
Color get accentBlue2 => kAcademicNavyDark;
Color get gold => kAcademicGold;
Color get rose => kAcademicBurgundy;
Color get purple => const Color(0xff4a148c);
Color get lineC => darkModeNotifier.value ? kDarkLine : kLightLine;
Color get navBg => darkModeNotifier.value ? kDarkCard : kLightCard;
Color get skeletonBase =>
    darkModeNotifier.value ? kDarkCard : const Color(0xffefeae0);
Color get skeletonHi =>
    darkModeNotifier.value ? kDarkCard2 : kAcademicCream;
Color get inkSoft =>
    darkModeNotifier.value ? const Color(0xff9db0ca) : const Color(0xff6b6b6b);
Color get softLine => darkModeNotifier.value ? kDarkLine : kLightLine;
Color get chipBg => darkModeNotifier.value
    ? kAcademicNavy.withOpacity(0.25)
    : kAcademicGold.withOpacity(0.15);
Color get chipFg =>
    darkModeNotifier.value ? kAcademicGold : kAcademicNavy;

/* ==================== MODELS ==================== */

class Cat {
  final String n;
  final String s;
  final IconData i;
  final Color c;
  const Cat(this.n, this.s, this.i, this.c);
}

const cats = <Cat>[
  Cat('رشته تربیت بدنی و علوم ورزشی', 'physical-education-sport-sciences', Icons.sports_soccer_rounded, Color(0xff1e3a5f)),
  Cat('علوم ورزشی', 'sports-science', Icons.science_rounded, Color(0xff4a148c)),
  Cat('منابع آزمون‌ها', 'sports-science-exam-resources', Icons.menu_book_rounded, Color(0xffc9a961)),
  Cat('تغذیه ورزشی', 'sports-nutrition', Icons.restaurant_rounded, Color(0xff046a38)),
  Cat('اخبار و رویدادها', 'sports-news-and-events', Icons.newspaper_rounded, Color(0xff7b2d26)),
  Cat('ورزش همگانی', 'public-exercise-health-and-wellness', Icons.favorite_rounded, Color(0xff00695c)),
  Cat('پژوهش در تربیت بدنی', 'research-in-physical-education', Icons.search_rounded, Color(0xff003d7a)),
  Cat('تربیت بدنی و آموزش', 'physical-education-and-training', Icons.school_rounded, Color(0xff2d5080)),
  Cat('منابع و کتب مرجع', 'introduction-to-sources-and-reference-books', Icons.library_books_rounded, Color(0xff5c4033)),
  Cat('اصول ورزش', 'principles-of-exercise-and-physical-activity', Icons.fitness_center_rounded, Color(0xff8b6914)),
  Cat('آزمون‌های استخدامی', 'employment-tests', Icons.assignment_rounded, Color(0xff8b2d26)),
  Cat('معرفی رشته‌ها', 'introduction-to-sports-disciplines', Icons.sports_handball_rounded, Color(0xff1d4ed8)),
  Cat('ورزش گروه‌های ویژه', 'exercise-for-special-groups-and-needs', Icons.accessibility_new_rounded, Color(0xff6d28d9)),
  Cat('تکنولوژی در ورزش', 'technology-and-innovation-in-sports', Icons.memory_rounded, Color(0xff0f766e)),
];
/* ==================== THEME MODE ==================== */

Future<void> loadThemeMode() async {
  try {
    final saved = await _storage.read(key: 'theme_mode');
    if (saved != null && saved.isNotEmpty) {
      themeModeNotifier.value = saved;
    } else {
      themeModeNotifier.value = 'auto';
    }
    _applyThemeMode();
  } catch (_) {
    _applyThemeMode();
  }
}

void _applyThemeMode() {
  final mode = themeModeNotifier.value;
  if (mode == 'auto') {
    final hour = DateTime.now().hour;
    darkModeNotifier.value = (hour >= 18 || hour < 6);
  } else if (mode == 'dark') {
    darkModeNotifier.value = true;
  } else {
    darkModeNotifier.value = false;
  }
}

Future<void> setThemeMode(String mode) async {
  themeModeNotifier.value = mode;
  _applyThemeMode();
  try {
    await _storage.write(key: 'theme_mode', value: mode);
    await _storage.write(
        key: 'dark_mode', value: darkModeNotifier.value.toString());
  } catch (_) {}
}

/* ==================== ACCENT COLOR ==================== */

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

/* ==================== BOOKMARKS ==================== */

Future<void> loadBookmarks() async {
  try {
    final saved = await _storage.read(key: 'bookmarks');
    if (saved != null && saved.isNotEmpty) {
      final list = (json.decode(saved) as List).cast<String>();
      bookmarkNotifier.value = list.toSet();
    }
    final savedNews = await _storage.read(key: 'bookmarks_news');
    if (savedNews != null && savedNews.isNotEmpty) {
      final list = (json.decode(savedNews) as List).cast<String>();
      newsBookmarkNotifier.value = list.toSet();
    }
    final savedProducts = await _storage.read(key: 'bookmarks_products');
    if (savedProducts != null && savedProducts.isNotEmpty) {
      final list = (json.decode(savedProducts) as List).cast<String>();
      productBookmarkNotifier.value = list.toSet();
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

Future<void> toggleNewsBookmark(String id) async {
  final set = Set<String>.from(newsBookmarkNotifier.value);
  if (set.contains(id)) {
    set.remove(id);
  } else {
    set.add(id);
  }
  newsBookmarkNotifier.value = set;
  try {
    await _storage.write(
        key: 'bookmarks_news', value: json.encode(set.toList()));
  } catch (_) {}
}

bool isNewsBookmarked(String id) =>
    newsBookmarkNotifier.value.contains(id);

Future<void> toggleProductBookmark(String id) async {
  final set = Set<String>.from(productBookmarkNotifier.value);
  if (set.contains(id)) {
    set.remove(id);
  } else {
    set.add(id);
  }
  productBookmarkNotifier.value = set;
  try {
    await _storage.write(
        key: 'bookmarks_products', value: json.encode(set.toList()));
  } catch (_) {}
}

bool isProductBookmarked(String id) =>
    productBookmarkNotifier.value.contains(id);

Future<void> clearAllBookmarks() async {
  bookmarkNotifier.value = {};
  newsBookmarkNotifier.value = {};
  productBookmarkNotifier.value = {};
  try {
    await _storage.delete(key: 'bookmarks');
    await _storage.delete(key: 'bookmarks_news');
    await _storage.delete(key: 'bookmarks_products');
  } catch (_) {}
}

/* ==================== OFFLINE ARTICLES ==================== */

Future<void> loadOfflineArticles() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('offline_articles_list') ?? [];
    offlineArticlesNotifier.value = list.toSet();
  } catch (_) {}
}

Future<void> saveOfflineArticle(dynamic post) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final id = pId(post);
    final article = {
      'id': id,
      'title': pTitle(post),
      'content': clean(post['content']?['rendered'] ?? ''),
      'excerpt': pExcerpt(post, maxChars: 500),
      'image': pImg(post),
      'category': pCategory(post),
      'author': pAuthor(post),
      'date': post['date'] ?? '',
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString('offline_article_$id', json.encode(article));
    final list = prefs.getStringList('offline_articles_list') ?? [];
    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList('offline_articles_list', list);
    }
    offlineArticlesNotifier.value = list.toSet();
  } catch (e) {
    rethrow;
  }
}

Future<void> removeOfflineArticle(String id) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_article_$id');
    final list = prefs.getStringList('offline_articles_list') ?? [];
    list.remove(id);
    await prefs.setStringList('offline_articles_list', list);
    offlineArticlesNotifier.value = list.toSet();
  } catch (_) {}
}

bool isOfflineSaved(String id) =>
    offlineArticlesNotifier.value.contains(id);

Future<Map<String, dynamic>?> getOfflineArticle(String id) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('offline_article_$id');
    if (data == null) return null;
    return json.decode(data) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Future<List<Map<String, dynamic>>> getAllOfflineArticles() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('offline_articles_list') ?? [];
    final articles = <Map<String, dynamic>>[];
    for (final id in list) {
      final data = prefs.getString('offline_article_$id');
      if (data != null) {
        articles.add(json.decode(data) as Map<String, dynamic>);
      }
    }
    articles.sort((a, b) {
      final da = a['savedAt'] ?? '';
      final db = b['savedAt'] ?? '';
      return db.compareTo(da);
    });
    return articles;
  } catch (_) {
    return [];
  }
}

/* ==================== FOLLOWED CATEGORIES ==================== */

Future<void> loadFollowedCategories() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('followed_categories') ?? [];
    followedCategoriesNotifier.value = list.toSet();
  } catch (_) {}
}

Future<void> toggleFollowCategory(String slug) async {
  final set = Set<String>.from(followedCategoriesNotifier.value);
  if (set.contains(slug)) {
    set.remove(slug);
  } else {
    set.add(slug);
  }
  followedCategoriesNotifier.value = set;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('followed_categories', set.toList());
  } catch (_) {}
}

bool isCategoryFollowed(String slug) =>
    followedCategoriesNotifier.value.contains(slug);

Future<void> clearFollowedCategories() async {
  followedCategoriesNotifier.value = {};
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('followed_categories');
  } catch (_) {}
}

/* ==================== IN-APP NOTIFICATIONS ==================== */

Future<void> loadInAppNotifications() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('in_app_notifications');
    if (data != null && data.isNotEmpty) {
      final list = (json.decode(data) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (list.length > 50) {
        list.removeRange(50, list.length);
      }
      inAppNotificationsNotifier.value = list;
    }
    lastNewsCheckNotifier.value =
        prefs.getString('last_news_check') ?? '';
  } catch (_) {}
}

Future<void> _saveInAppNotifications() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'in_app_notifications',
      json.encode(inAppNotificationsNotifier.value),
    );
  } catch (_) {}
}

Future<void> _saveLastNewsCheck(DateTime time) async {
  try {
    final iso = time.toIso8601String();
    lastNewsCheckNotifier.value = iso;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_news_check', iso);
  } catch (_) {}
}

Future<void> checkForNewNotifications() async {
  try {
    final list = await getNewNewsList();
    if (list.isEmpty) return;

    final lastCheck = lastNewsCheckNotifier.value.isNotEmpty
        ? DateTime.tryParse(lastNewsCheckNotifier.value)
        : null;

    final now = DateTime.now();
    final existing = List<Map<String, dynamic>>.from(
        inAppNotificationsNotifier.value);
    final existingIds = existing.map((e) => e['id'].toString()).toSet();

    final newOnes = <Map<String, dynamic>>[];

    for (final news in list) {
      final id = pId(news);
      if (id.isEmpty || existingIds.contains(id)) continue;
      if (lastCheck != null) {
        try {
          final newsDate = DateTime.parse(news['date']).toLocal();
          if (newsDate.isBefore(lastCheck)) continue;
        } catch (_) {
          continue;
        }
      }
      newOnes.add({
        'id': id,
        'title': pTitle(news),
        'excerpt': pExcerpt(news, maxChars: 100),
        'link': pLink(news),
        'image': pImg(news),
        'date': news['date'] ?? '',
        'read': false,
        'createdAt': now.toIso8601String(),
      });
    }

    if (newOnes.isNotEmpty) {
      final updated = [...newOnes, ...existing];
      if (updated.length > 50) {
        updated.removeRange(50, updated.length);
      }
      inAppNotificationsNotifier.value = updated;
      await _saveInAppNotifications();
    }

    await _saveLastNewsCheck(now);
  } catch (_) {}
}

int getUnreadNotificationsCount() {
  return inAppNotificationsNotifier.value
      .where((e) => e['read'] != true)
      .length;
}

Future<void> markNotificationRead(String id) async {
  final list = List<Map<String, dynamic>>.from(
      inAppNotificationsNotifier.value);
  final index = list.indexWhere((e) => e['id'].toString() == id);
  if (index != -1) {
    list[index] = {...list[index], 'read': true};
    inAppNotificationsNotifier.value = list;
    await _saveInAppNotifications();
  }
}

Future<void> markAllNotificationsRead() async {
  final list = inAppNotificationsNotifier.value
      .map((e) => {...e, 'read': true})
      .toList();
  inAppNotificationsNotifier.value = list;
  await _saveInAppNotifications();
}

Future<void> clearAllNotifications() async {
  inAppNotificationsNotifier.value = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('in_app_notifications');
  } catch (_) {}
}
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

/// اشتراک‌گذاری خبر همراه با تصویر
Future<void> sharePostWithImage(
  String url,
  String title, {
  String? imageUrl,
}) async {
  if (url.isEmpty) return;

  try {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(imageUrl))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final fileName =
              'share_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);

          await Share.shareXFiles(
            [XFile(file.path)],
            text: '$title\n\n$url',
          );

          Future.delayed(const Duration(seconds: 30), () {
            try {
              if (file.existsSync()) file.deleteSync();
            } catch (_) {}
          });
          return;
        }
      } catch (_) {}
    }

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
          error ? const Color(0xffe10600) : kAcademicNavy,
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
const int _cacheNewsSeconds = 30;
const int _cachePostsSeconds = 300;
const int _cacheProductsSeconds = 1800;
const int _cacheCategoriesSeconds = 86400;

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

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final cacheKey = 'products_$u';
  if (_postsCache.containsKey(cacheKey) &&
      _postsCacheTime.containsKey(cacheKey) &&
      (now - _postsCacheTime[cacheKey]!) < _cacheProductsSeconds) {
    return _postsCache[cacheKey]!;
  }

  try {
    final r = await http.get(Uri.parse(u));
    if (r.statusCode == 400) return [];
    if (r.statusCode != 200) throw Exception('خطای ${r.statusCode}');
    final list = json.decode(r.body) as List;
    _postsCache[cacheKey] = list;
    _postsCacheTime[cacheKey] = now;
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

Future<List> searchExact(String query, {String? categorySlug}) async {
  var url = '$api/posts?search=${Uri.encodeComponent(query)}'
      '&per_page=50'
      '&_embed=wp:featuredmedia,wp:term,author'
      '&_fields=id,link,title,date,excerpt,content,_embedded,_links';

  final r = await http.get(Uri.parse(url));
  if (r.statusCode != 200) throw Exception('خطای ${r.statusCode}');
  final list = json.decode(r.body) as List;

  final words = query
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  List<dynamic> filtered = list.where((p) {
    final title = clean((p['title']?['rendered'] ?? '')).toLowerCase();
    final excerpt =
        clean((p['excerpt']?['rendered'] ?? '')).toLowerCase();
    return words.every(
      (w) => title.contains(w) || excerpt.contains(w),
    );
  }).toList();

  if (categorySlug != null && categorySlug.isNotEmpty) {
    final catId = await getCatIdBySlug(categorySlug);
    if (catId != null) {
      filtered = filtered.where((p) {
        final terms = p['_embedded']?['wp:term'];
        if (terms is List && terms.isNotEmpty) {
          final catList = terms[0];
          if (catList is List) {
            return catList.any((c) => c['id'] == catId);
          }
        }
        return false;
      }).toList();
    }
  }

  return filtered;
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

/* ==================== MEDIA UPLOAD ==================== */

Future<Map<String, dynamic>> uploadMedia({
  required String username,
  required String appPassword,
  required String filePath,
  required String fileName,
}) async {
  final auth = _basicAuth(username, appPassword);
  final uri = Uri.parse('$api/media');

  try {
    final bytes = await File(filePath).readAsBytes();

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    );

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Basic $auth';
    request.headers['Accept'] = 'application/json';
    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map) return Map<String, dynamic>.from(data);
      throw Exception('پاسخ نامعتبر');
    }
    if (response.statusCode == 401) {
      throw Exception('نام کاربری یا رمز اشتباه است.');
    }
    if (response.statusCode == 403) {
      throw Exception('شما اجازه آپلود فایل ندارید.');
    }
    if (response.statusCode == 413) {
      throw Exception('حجم فایل بیش از حد مجاز است.');
    }
    throw Exception('خطا در آپلود (${response.statusCode})');
  } catch (e) {
    if (e.toString().contains('Exception')) rethrow;
    throw Exception('خطا در آپلود فایل: $e');
  }
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
    await loadBookmarks();
    await loadAccentColor();
    await loadThemeMode();
    await loadOfflineArticles();
    await loadFollowedCategories();
    await loadInAppNotifications();
    Future.delayed(const Duration(seconds: 2), () {
      checkForNewNotifications();
    });
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
                    kDarkBg,
                    const Color(0xff152a47),
                    kAcademicNavyDark,
                  ]
                : [
                    kLightBg,
                    kAcademicCream,
                    kAcademicParchment,
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
                              kAcademicGold,
                              accentNotifier.value,
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
                              color: kAcademicGold.withOpacity(0.3),
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
                                  Icons.school_rounded,
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
                            'مرجع تخصصی تربیت بدنی و علوم ورزشی',
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
                color: kAcademicGold.withOpacity(0.3 + scale * 0.7),
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

/* ==================== PREMIUM NAV BAR ==================== */

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
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? kDarkLine : kLightLine,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.6)
                  : accentNotifier.value.withOpacity(0.15),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: kAcademicGold.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 78,
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
                    child: _PremiumNavItem(
                      item: item,
                      selected: selected,
                      isDark: isDark,
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
      color: kAcademicNavy,
    ),
    _NavItem(
      icon: Icons.article_outlined,
      activeIcon: Icons.article_rounded,
      label: 'مقالات',
      color: kAcademicNavyLight,
    ),
    _NavItem(
      icon: Icons.newspaper_outlined,
      activeIcon: Icons.newspaper_rounded,
      label: 'اخبار',
      color: kAcademicBurgundy,
    ),
    _NavItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      label: 'فروشگاه',
      color: kAcademicGold,
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'حساب من',
      color: Color(0xff4a148c),
    ),
  ];
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}

class _PremiumNavItem extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final bool isDark;
  const _PremiumNavItem({
    required this.item,
    required this.selected,
    required this.isDark,
  });

  @override
  State<_PremiumNavItem> createState() => _PremiumNavItemState();
}

class _PremiumNavItemState extends State<_PremiumNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    if (widget.selected) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_PremiumNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final selected = widget.selected;
    final isDark = widget.isDark;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: selected ? 46 : 42,
              height: selected ? 46 : 42,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          item.color,
                          item.color.withOpacity(0.7),
                        ],
                      )
                    : null,
                color: selected
                    ? null
                    : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(15),
                border: selected
                    ? Border.all(
                        color: kAcademicGold.withOpacity(0.4),
                        width: 1.5,
                      )
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: item.color.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: kAcademicGold.withOpacity(0.25),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) {
                      return ScaleTransition(
                        scale: anim,
                        child: FadeTransition(
                          opacity: anim,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      selected ? item.activeIcon : item.icon,
                      key: ValueKey(selected),
                      color: selected
                          ? Colors.white
                          : (isDark ? txtC.withOpacity(0.7) : mutC),
                      size: selected ? 24 : 22,
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: kAcademicGold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kAcademicGold.withOpacity(0.8),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                color: selected
                    ? item.color
                    : (isDark ? txtC.withOpacity(0.6) : mutC),
                fontSize: selected ? 11.5 : 10.5,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              ),
              child: Text(item.label),
            ),
          ],
        );
      },
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
      await checkForNewNotifications();
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
                color: kAcademicGold,
                size: 250,
                duration: const Duration(seconds: 10),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -100,
              child: _AnimatedBlob(
                color: kAcademicNavyLight,
                size: 220,
                duration: const Duration(seconds: 12),
              ),
            ),
            RefreshIndicator(
              color: accentNotifier.value,
              backgroundColor: pnl,
              strokeWidth: 3,
              displacement: 80,
              edgeOffset: 10,
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
                    child: FollowedCategoriesSection(
                      allPostsFuture: _f,
                    ),
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

/* ==================== MODERN HEADER ==================== */

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
                  kAcademicGold,
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
                      Icons.school_rounded,
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
                    colors: [txtC, kAcademicGold],
                  ).createShader(bounds),
                  child: Text(
                    t ?? 'تربیت بدنی و علوم ورزشی',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
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
                        color: kAcademicGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kAcademicGold.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'مرجع تخصصی علوم ورزشی',
                      style: TextStyle(
                        color: mutC,
                        fontSize: 10,
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 🔔 اعلان‌ها با Badge
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: inAppNotificationsNotifier,
            builder: (c, list, __) {
              final unread =
                  list.where((e) => e['read'] != true).length;
              return Stack(
                children: [
                  _HeaderIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const NotificationsPage()),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xffe10600),
                              Color(0xffbe123c),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: pnl, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffe10600)
                                  .withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          unread > 9 ? '۹+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
          // 📥 ذخیره آفلاین
          ValueListenableBuilder<Set<String>>(
            valueListenable: offlineArticlesNotifier,
            builder: (c, set, __) => Stack(
              children: [
                _HeaderIconButton(
                  icon: Icons.download_done_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OfflineArticlesPage()),
                  ),
                ),
                if (set.isNotEmpty)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: kAcademicGold,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: pnl, width: 1.5),
                      ),
                      child: Text(
                        '${set.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // 🔖 نشان‌شده‌ها
          _HeaderIconButton(
            icon: Icons.bookmark_outline_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookmarksPage()),
            ),
          ),
          const SizedBox(width: 4),
          _HeaderIconButton(
            icon: Icons.brightness_6_rounded,
            onTap: () => _showThemeModePicker(context),
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(13),
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
        child: Icon(icon, color: color ?? txtC, size: 19),
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
      _titles = list.take(5).map((e) => pTitle(e)).toList();
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
                  kAcademicBurgundy.withOpacity(0.3),
                  kAcademicNavyDark.withOpacity(0.3),
                ]
              : [
                  kAcademicCream,
                  kAcademicParchment,
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kAcademicBurgundy.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: kAcademicBurgundy.withOpacity(0.12),
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
              gradient: LinearGradient(
                colors: [
                  kAcademicBurgundy,
                  kAcademicBurgundy.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: kAcademicBurgundy.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WhiteLiveDotSmall(),
                SizedBox(width: 5),
                Text(
                  'خبر فوری',
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

/* ==================== THEME MODE PICKER ==================== */

void _showThemeModePicker(BuildContext context) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: pnl,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kAcademicNavy, kAcademicGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kAcademicNavy.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.brightness_6_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'حالت نمایش',
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
          _themeOption(
            icon: Icons.light_mode_rounded,
            label: 'روشن',
            subtitle: 'همیشه در حالت روشن',
            color: kAcademicGold,
            value: 'light',
            ctx: ctx,
          ),
          const SizedBox(height: 10),
          _themeOption(
            icon: Icons.dark_mode_rounded,
            label: 'تاریک',
            subtitle: 'همیشه در حالت تاریک',
            color: kAcademicNavy,
            value: 'dark',
            ctx: ctx,
          ),
          const SizedBox(height: 10),
          _themeOption(
            icon: Icons.brightness_auto_rounded,
            label: 'خودکار',
            subtitle: 'بر اساس ساعت روز',
            color: accentNotifier.value,
            value: 'auto',
            ctx: ctx,
          ),
        ],
      ),
    ),
  );
}

Widget _themeOption({
  required IconData icon,
  required String label,
  required String subtitle,
  required Color color,
  required String value,
  required BuildContext ctx,
}) {
  return ValueListenableBuilder<String>(
    valueListenable: themeModeNotifier,
    builder: (context, current, _) {
      final selected = current == value;
      return GestureDetector(
        onTap: () async {
          HapticFeedback.selectionClick();
          await setThemeMode(value);
          if (ctx.mounted) Navigator.pop(ctx);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.15),
                      color.withOpacity(0.05),
                    ],
                  )
                : null,
            color: selected ? null : pnl2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : lineC,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        )
                      : null,
                  color: selected ? null : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? color : txtC,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: mutC,
                        fontSize: 11,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: color, size: 24),
            ],
          ),
        ),
      );
    },
  );
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
    return ValueListenableBuilder<Set<String>>(
      valueListenable: followedCategoriesNotifier,
      builder: (context, followed, _) {
        return Container(
          margin: const EdgeInsets.only(top: 4, bottom: 6),
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: cats.length + 2,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (c, i) {
              // 🎯 دکمه «دسته‌های من»
              if (i == 0) {
                final count = followed.length;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const FollowedCategoriesPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kAcademicNavy
                              .withOpacity(count > 0 ? 1 : 0.15),
                          kAcademicGold
                              .withOpacity(count > 0 ? 1 : 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: kAcademicNavy
                            .withOpacity(count > 0 ? 1 : 0.3),
                        width: 1.2,
                      ),
                      boxShadow: count > 0
                          ? [
                              BoxShadow(
                                color: kAcademicGold
                                    .withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: count > 0
                              ? Colors.white
                              : kAcademicNavy,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'دسته‌های من',
                          style: TextStyle(
                            color: count > 0
                                ? Colors.white
                                : kAcademicNavy,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
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

              if (i == 1) {
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

              final cat = cats[i - 2];
              final sel = _selected == i - 2;
              final isFollowed = followed.contains(cat.s);
              return _chip(
                label: cat.n.length > 20
                    ? '${cat.n.substring(0, 18)}...'
                    : cat.n,
                icon: cat.i,
                color: cat.c,
                selected: sel,
                isFollowed: isFollowed,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = i - 2);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryPostsPage(c: cat),
                    ),
                  );
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  toggleFollowCategory(cat.s);
                  showSnack(
                    context,
                    isFollowed
                        ? 'لغو دنبال کردن «${cat.n}»'
                        : 'دنبال کردن «${cat.n}»',
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    bool isFollowed = false,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final isDark = darkModeNotifier.value;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
                : (isFollowed
                    ? color.withOpacity(0.5)
                    : (isDark
                        ? Colors.white.withOpacity(0.10)
                        : Colors.black.withOpacity(0.06))),
            width: selected || isFollowed ? 1.5 : 1.2,
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
            if (isFollowed && !selected) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ],
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
                ? kAcademicGold
                : mutC.withOpacity(0.3),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: kAcademicGold.withOpacity(0.5),
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
                        memCacheHeight: 720,
                        maxWidthDiskCache: 1080,
                        maxHeightDiskCache: 720,
                        fadeInDuration:
                            const Duration(milliseconds: 400),
                        fadeOutDuration:
                            const Duration(milliseconds: 200),
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
                                  kAcademicGold,
                                  kAcademicGoldDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: kAcademicGold
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
                          colors: [kAcademicNavy, kAcademicGold],
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
                          color: kAcademicNavy.withOpacity(.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: kAcademicNavy.withOpacity(.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.list_alt_rounded,
                                color: kAcademicNavy, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'مشاهده همه اخبار فوری',
                              style: TextStyle(
                                color: kAcademicNavy,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_back_ios_new_rounded,
                                color: kAcademicNavy, size: 12),
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

/* ==================== MODERN SERVICES SECTION ==================== */

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
      'color': kAcademicNavy,
      'url':
          '$site/introduction-to-the-field-of-physical-education-and-sports-sciences/',
    },
    {
      'title': 'گرایش‌های ارشد',
      'icon': Icons.layers_rounded,
      'color': const Color(0xff4a148c),
      'url':
          '$site/%da%af%d8%b1%d8%a7%db%8c%d8%b4%d9%87%d8%a7%db%8c-%da%a9%d8%a7%d8%b1%d8%b4%d9%86%d8%a7%d8%b3%db%8c-%d8%a7%d8%b1%d8%b4%d8%af-%d8%aa%d8%b1%d8%a8%db%8c%d8%aa-%d8%a8%d8%af%d9%86%db%8c-%d9%88/',
    },
    {
      'title': 'گرایش‌های دکتری',
      'icon': Icons.school_rounded,
      'color': const Color(0xff003d7a),
      'url': '$site/sports-science-phd-exam-resources/',
    },
    {
      'title': 'منابع ارشد',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xff046a38),
      'url': '$site/master-of-sports-science-resources/',
    },
    {
      'title': 'منابع دکتری',
      'icon': Icons.auto_stories_rounded,
      'color': kAcademicGold,
      'url': '$site/manabe-konkur-doctori-tarbiat-badani/',
    },
    {
      'title': 'منابع استخدامی',
      'icon': Icons.assignment_rounded,
      'color': kAcademicBurgundy,
      'url': '$site/employment-tests/',
    },
    {
      'title': 'دانشگاه‌های برتر',
      'icon': Icons.account_balance_rounded,
      'color': kAcademicNavyLight,
      'url': '$site/physical-education-sports-science/',
    },
    {
      'title': 'بازار کار',
      'icon': Icons.work_outline_rounded,
      'color': const Color(0xff00695c),
      'url':
          '$site/job-market-in-physical-education-and-sports-sciences/',
    },
    {
      'title': 'طرح درس',
      'icon': Icons.slideshow_rounded,
      'color': const Color(0xff6d28d9),
      'url':
          '$site/product-category/%d8%b7%d8%b1%d8%ad-%d8%af%d8%b1%d8%b3-%d8%b1%d9%88%d8%b2%d8%a7%d9%86%d9%87-%d9%85%d8%a7%d9%87%d8%a7%d9%86%d9%87-%d8%b3%d8%a7%d9%84%d8%a7%d9%86%d9%87/',
    },
    {
      'title': 'پاورپوینت',
      'icon': Icons.file_present_rounded,
      'color': kAcademicLeather,
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
                      colors: [kAcademicNavy, kAcademicGold],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.auto_awesome_rounded,
                    color: kAcademicGold, size: 20),
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
              child:
                  Icon(item['icon'] as IconData, color: color, size: 24),
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

/* ==================== PREMIUM POST CARD ==================== */

class ModernPostCard extends StatefulWidget {
  final dynamic post;
  final bool showBookmark;
  const ModernPostCard(
      {super.key, required this.post, this.showBookmark = true});

  @override
  State<ModernPostCard> createState() => _ModernPostCardState();
}

class _ModernPostCardState extends State<ModernPostCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final title = pTitle(post);
    final link = pLink(post);
    final img = pImg(post);
    final cat = pCategory(post);
    final date = pTimeAgo(post);
    final id = pId(post);
    final isDark = darkModeNotifier.value;

    return GestureDetector(
      onTapDown: (_) {
        _ctrl.forward();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        _ctrl.reverse();
        setState(() => _pressed = false);
      },
      onTapCancel: () {
        _ctrl.reverse();
        setState(() => _pressed = false);
      },
      onTap: () => openUrl(context, link),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? [kDarkCard, kDarkBg]
                  : [Colors.white, kAcademicCream2],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed
                  ? kAcademicGold.withOpacity(0.5)
                  : lineC,
              width: _pressed ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _pressed
                    ? kAcademicGold.withOpacity(0.2)
                    : Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: _pressed ? 20 : 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          kAcademicGold.withOpacity(
                              isDark ? 0.15 : 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 108,
                          height: 108,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (img.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: img,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 500,
                                  memCacheHeight: 500,
                                  maxWidthDiskCache: 500,
                                  maxHeightDiskCache: 500,
                                  fadeInDuration: const Duration(
                                      milliseconds: 250),
                                  fadeOutDuration: const Duration(
                                      milliseconds: 150),
                                  placeholder: (_, __) =>
                                      Container(color: pnl2),
                                  errorWidget: (_, __, ___) => Container(
                                    color: pnl2,
                                    child: Icon(Icons.article_rounded,
                                        color: accentNotifier.value,
                                        size: 32),
                                  ),
                                )
                              else
                                Container(
                                  color: pnl2,
                                  child: Icon(Icons.article_rounded,
                                      color: accentNotifier.value,
                                      size: 32),
                                ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.5),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withOpacity(0.25),
                                    borderRadius:
                                        BorderRadius.circular(7),
                                    border: Border.all(
                                      color: Colors.white
                                          .withOpacity(0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(4, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (cat.isNotEmpty)
                                  Flexible(
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            accentNotifier.value
                                                .withOpacity(0.15),
                                            accentNotifier.value
                                                .withOpacity(0.08),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(7),
                                        border: Border.all(
                                          color: accentNotifier.value
                                              .withOpacity(0.25),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color:
                                                  accentNotifier.value,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: accentNotifier
                                                      .value
                                                      .withOpacity(0.5),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              cat,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: accentNotifier
                                                    .value,
                                                fontSize: 9.5,
                                                fontWeight:
                                                    FontWeight.w900,
                                                fontFamily: 'Vazirmatn',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                // 📤 Share
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    sharePostWithImage(link, title,
                                        imageUrl: img);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.ios_share_rounded,
                                      color: mutC,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // 📥 Offline
                                GestureDetector(
                                  onTap: () async {
                                    HapticFeedback.lightImpact();
                                    if (isOfflineSaved(id)) {
                                      await removeOfflineArticle(id);
                                      if (context.mounted) {
                                        showSnack(context,
                                            'از آفلاین حذف شد');
                                      }
                                    } else {
                                      await saveOfflineArticle(post);
                                      if (context.mounted) {
                                        showSnack(context,
                                            'برای مطالعه آفلاین ذخیره شد ✅');
                                      }
                                    }
                                  },
                                  child: ValueListenableBuilder<
                                      Set<String>>(
                                    valueListenable:
                                        offlineArticlesNotifier,
                                    builder: (c, set, __) => Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: set.contains(id)
                                            ? kAcademicGold
                                                .withOpacity(0.15)
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        set.contains(id)
                                            ? Icons
                                                .download_done_rounded
                                            : Icons.download_outlined,
                                        color: set.contains(id)
                                            ? kAcademicGold
                                            : mutC,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // 🔖 Bookmark
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
                                    child: ValueListenableBuilder<
                                        Set<String>>(
                                      valueListenable: bookmarkNotifier,
                                      builder: (c, set, __) => Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: set.contains(id)
                                              ? kAcademicGold
                                                  .withOpacity(0.15)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          set.contains(id)
                                              ? Icons.bookmark_rounded
                                              : Icons
                                                  .bookmark_border_rounded,
                                          color: set.contains(id)
                                              ? kAcademicGold
                                              : mutC,
                                          size: 16,
                                        ),
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
                                fontWeight: FontWeight.w900,
                                height: 1.5,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: pnl2,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule_rounded,
                                          color: mutC, size: 10),
                                      const SizedBox(width: 4),
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
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                        memCacheHeight: 640,
                        maxWidthDiskCache: 1080,
                        maxHeightDiskCache: 640,
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
                                    ? kAcademicGold
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
                          color: kAcademicGold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مطالعه',
                              style: TextStyle(
                                color: kAcademicGoldDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_back_rounded,
                                color: kAcademicGoldDark, size: 12),
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
                      // 📤 Share
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          sharePostWithImage(link, title, imageUrl: img);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.ios_share_rounded,
                            color: mutC,
                            size: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (showBookmark)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            toggleBookmark(id);
                          },
                          child: ValueListenableBuilder<Set<String>>(
                            valueListenable: bookmarkNotifier,
                            builder: (c, set, __) => Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: set.contains(id)
                                    ? kAcademicGold.withOpacity(0.15)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                set.contains(id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: set.contains(id)
                                    ? kAcademicGold
                                    : mutC,
                                size: 15,
                              ),
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
                        memCacheHeight: 400,
                        maxWidthDiskCache: 400,
                        maxHeightDiskCache: 400,
                        fadeInDuration:
                            const Duration(milliseconds: 200),
                        fadeOutDuration:
                            const Duration(milliseconds: 100),
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

/* ==================== PREMIUM PRODUCT CARD ==================== */

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

    int discountPercent = 0;
    if (isOnSale) {
      final rp = int.tryParse(regularPrice) ?? 0;
      final sp = int.tryParse(salePrice) ?? 0;
      if (rp > 0) {
        discountPercent = ((rp - sp) / rp * 100).round();
      }
    }

    return GestureDetector(
      onTap: () => openUrl(context, link, title: name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(20),
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
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 110,
                height: 130,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    img.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            memCacheWidth: 500,
                            memCacheHeight: 600,
                            maxWidthDiskCache: 500,
                            maxHeightDiskCache: 600,
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
                    if (isOnSale && discountPercent > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kAcademicBurgundy,
                                kAcademicBurgundy.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: kAcademicBurgundy
                                    .withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$discountPercent٪',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: inStock
                              ? const Color(0xff046a38)
                              : const Color(0xff6b7280),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inStock ? 'موجود' : 'ناموجود',
                          style: const TextStyle(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: txtC,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            height: 1.5,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 📤 Share
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          sharePostWithImage(link, name, imageUrl: img);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.ios_share_rounded,
                            color: mutC,
                            size: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 🔖 Bookmark
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          toggleProductBookmark(pId(p));
                          showSnack(
                            context,
                            isProductBookmarked(pId(p))
                                ? 'به نشان‌شده‌ها اضافه شد'
                                : 'از نشان‌شده‌ها حذف شد',
                          );
                        },
                        child: ValueListenableBuilder<Set<String>>(
                          valueListenable: productBookmarkNotifier,
                          builder: (c, set, __) => Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: set.contains(pId(p))
                                  ? kAcademicGold.withOpacity(0.15)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              set.contains(pId(p))
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: set.contains(pId(p))
                                  ? kAcademicGold
                                  : mutC,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (isOnSale) ...[
                    Text(
                      formatPrice(salePrice),
                      style: const TextStyle(
                        color: Color(0xff046a38),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatPrice(regularPrice),
                      style: TextStyle(
                        color: mutC,
                        fontSize: 10.5,
                        decoration: TextDecoration.lineThrough,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ] else if (regularPrice.isNotEmpty)
                    Text(
                      formatPrice(regularPrice),
                      style: TextStyle(
                        color: txtC,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    )
                  else
                    Text(
                      'قیمت نامشخص',
                      style: TextStyle(color: mutC, fontSize: 11),
                    ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kAcademicGold.withOpacity(inStock ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kAcademicGold
                            .withOpacity(inStock ? 0.3 : 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          inStock
                              ? Icons.shopping_bag_rounded
                              : Icons.visibility_rounded,
                          color: kAcademicGold
                              .withOpacity(inStock ? 1 : 0.5),
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          inStock ? 'خرید' : 'مشاهده',
                          style: TextStyle(
                            color: kAcademicGold
                                .withOpacity(inStock ? 1 : 0.6),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
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
            onLongPress: () {
              HapticFeedback.mediumImpact();
              final isFollowed = isCategoryFollowed(cat.s);
              toggleFollowCategory(cat.s);
              showSnack(
                c,
                isFollowed
                    ? 'لغو دنبال کردن «${cat.n}»'
                    : 'دنبال کردن «${cat.n}»',
              );
            },
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: followedCategoriesNotifier,
              builder: (ctx, followed, __) {
                final isFollowed = followed.contains(cat.s);
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: pnl,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isFollowed ? cat.c : lineC,
                      width: isFollowed ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isFollowed
                            ? cat.c.withOpacity(0.2)
                            : Colors.black.withOpacity(0.03),
                        blurRadius: isFollowed ? 14 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
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
                          if (isFollowed)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: cat.c,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: pnl, width: 1.5),
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 9),
                              ),
                            ),
                        ],
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
                );
              },
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
        kAcademicGold
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
                    colors: [kAcademicNavy, kAcademicGold],
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
                  colors: [kAcademicNavy, kAcademicGold],
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
                  color: kAcademicBurgundy.withOpacity(opacity * 0.5),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kAcademicBurgundy,
                ),
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

  static const Color _blue1 = Color(0xff38bdf8);
  static const Color _blue2 = Color(0xff0ea5e9);
  static const Color _blue3 = Color(0xff0284c7);
  static const Color _blueSoft = Color(0xffbae6fd);

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
    final id = pId(news);

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
                    const Color(0xff082f49),
                    const Color(0xff0c4a6e),
                    kDarkCard,
                  ]
                : [
                    const Color(0xffe0f2fe),
                    const Color(0xfff0f9ff),
                    Colors.white,
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed
                ? _blue2
                : _blue1.withOpacity(isDark ? 0.5 : 0.4),
            width: _pressed ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _blue2.withOpacity(_pressed ? 0.4 : 0.22),
              blurRadius: _pressed ? 28 : 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: _blue1.withOpacity(_pressed ? 0.3 : 0.12),
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
                        _blue2.withOpacity(isDark ? 0.4 : 0.22),
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
                        _blue1.withOpacity(isDark ? 0.3 : 0.18),
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
                            _blue2.withOpacity(glow),
                            _blue1,
                            _blueSoft,
                            _blue1,
                            _blue2.withOpacity(glow),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _blue2.withOpacity(glow * 0.7),
                            blurRadius: 14,
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
                              colors: [_blue1, _blue2, _blue3],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _blue2.withOpacity(0.55),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
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
                              colors: [_blue2, _blue3],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: _blue2.withOpacity(0.45),
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
                                'خبر فوری',
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
                        // 📤 Share
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            sharePostWithImage(
                              pLink(news),
                              pTitle(news),
                              imageUrl: pImg(news),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.ios_share_rounded,
                              color: mutC,
                              size: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 🔖 Bookmark
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            toggleNewsBookmark(id);
                            showSnack(
                              context,
                              isNewsBookmarked(id)
                                  ? 'به نشان‌شده‌ها اضافه شد'
                                  : 'از نشان‌شده‌ها حذف شد',
                            );
                          },
                          child: ValueListenableBuilder<Set<String>>(
                            valueListenable: newsBookmarkNotifier,
                            builder: (c, set, __) => Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: set.contains(id)
                                    ? kAcademicGold.withOpacity(0.2)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                set.contains(id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: set.contains(id)
                                    ? kAcademicGold
                                    : mutC,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                                  color: _blue2.withOpacity(0.2),
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
                            ? const Color(0xff082f49)
                            : _blueSoft.withOpacity(0.5),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: freshness,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_blue1, _blue2, _blue3],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _blue2.withOpacity(0.5),
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
                      color: _blue2.withOpacity(isDark ? 0.2 : 0.15),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 12, color: _blue2),
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
                              colors: [_blue2, _blue3],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: _blue2.withOpacity(0.35),
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

/* ==================== FOLLOWED CATEGORIES SECTION ==================== */

class FollowedCategoriesSection extends StatefulWidget {
  final Future<List>? allPostsFuture;
  const FollowedCategoriesSection({
    super.key,
    this.allPostsFuture,
  });

  @override
  State<FollowedCategoriesSection> createState() =>
      _FollowedCategoriesSectionState();
}

class _FollowedCategoriesSectionState
    extends State<FollowedCategoriesSection> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: followedCategoriesNotifier,
      builder: (context, followed, _) {
        if (followed.isEmpty) return const SizedBox.shrink();

        return FutureBuilder<List>(
          future: widget.allPostsFuture,
          builder: (c, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final all = snapshot.data ?? [];

            final filtered = all.where((post) {
              final catName = pCategory(post);
              return cats.any((cat) =>
                  cat.n == catName && followed.contains(cat.s));
            }).take(5).toList();

            if (filtered.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                kAcademicNavy,
                                kAcademicGold,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.favorite_rounded,
                            color: kAcademicBurgundy,
                            size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'مطالب موردعلاقه شما',
                          style: TextStyle(
                            color: txtC,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const FollowedCategoriesPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: kAcademicNavy
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'مدیریت',
                              style: TextStyle(
                                color: kAcademicNavy,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...filtered.map((post) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                            14, 0, 14, 10),
                        child: SidePostCard(
                          post: post,
                          showBookmark: true,
                        ),
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
/* ==================== PREMIUM ARTICLES PAGE ==================== */

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
          if (_posts.length > 150) _posts.removeRange(0, 50);
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
            _buildHeader(context),
            Expanded(
              child: _posts.isEmpty && _loading
                  ? const ArticlesSkeleton()
                  : _posts.isEmpty && _error != null
                      ? ErrorBox(
                          message: 'خطا در دریافت مقالات.\n$_error',
                          onRetry: _refresh,
                        )
                      : _posts.isEmpty
                          ? const EmptyWidget(text: 'مقاله‌ای پیدا نشد.')
                          : RefreshIndicator(
                              color: kAcademicNavyLight,
                              backgroundColor: pnl,
                              strokeWidth: 3,
                              onRefresh: _refresh,
                              child: ListView.builder(
                                controller: _scroll,
                                cacheExtent: 800,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                    14, 8, 14, 120),
                                itemCount:
                                    _posts.length + (_hasMore ? 1 : 0),
                                itemBuilder: (c, i) {
                                  if (i >= _posts.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: kAcademicNavyLight,
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

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kAcademicNavy, kAcademicNavyLight],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kAcademicNavy.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.article_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [kAcademicNavy, kAcademicGold],
                    ).createShader(bounds),
                    child: Text(
                      'مقالات تخصصی',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: txtC,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'مطالب علمی و آموزشی',
                    style: TextStyle(
                      color: mutC,
                      fontSize: 11,
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              ),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: pnl,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: lineC),
                ),
                child: Icon(Icons.search_rounded,
                    color: txtC, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== CATEGORY POSTS PAGE ==================== */

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
              actions: [
                ValueListenableBuilder<Set<String>>(
                  valueListenable: followedCategoriesNotifier,
                  builder: (c, followed, _) {
                    final isFollowed = followed.contains(widget.c.s);
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          toggleFollowCategory(widget.c.s);
                          showSnack(
                            context,
                            isFollowed
                                ? 'لغو دنبال کردن'
                                : 'دنبال کردن «${widget.c.n}»',
                          );
                        },
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isFollowed
                                ? LinearGradient(
                                    colors: [
                                      widget.c.c,
                                      widget.c.c.withOpacity(0.7),
                                    ],
                                  )
                                : null,
                            color: isFollowed
                                ? null
                                : widget.c.c.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.c.c
                                  .withOpacity(isFollowed ? 1 : 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isFollowed
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                color: isFollowed
                                    ? Colors.white
                                    : widget.c.c,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isFollowed ? 'دنبال می‌شود' : 'دنبال کن',
                                style: TextStyle(
                                  color: isFollowed
                                      ? Colors.white
                                      : widget.c.c,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
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
                  color: accentNotifier.value,
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
/* ==================== PREMIUM NEWS PAGE (WITH TIME FILTER) ==================== */

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});
  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _posts = <dynamic>[];
  final _allPosts = <dynamic>[];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int? _catId;
  final _scroll = ScrollController(keepScrollOffset: false);
  String _timeFilter = 'all';

  final List<Map<String, dynamic>> _timeFilters = [
    {
      'key': 'all',
      'label': 'همه',
      'icon': Icons.apps_rounded,
      'color': Color(0xff6b7280),
    },
    {
      'key': 'today',
      'label': 'امروز',
      'icon': Icons.today_rounded,
      'color': Color(0xff046a38),
    },
    {
      'key': 'week',
      'label': 'این هفته',
      'icon': Icons.date_range_rounded,
      'color': kAcademicNavyLight,
    },
    {
      'key': 'month',
      'label': 'این ماه',
      'icon': Icons.calendar_month_rounded,
      'color': Color(0xff4a148c),
    },
  ];

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

  List<dynamic> _applyTimeFilter() {
    if (_timeFilter == 'all') return _allPosts;
    final now = DateTime.now();
    DateTime cutoff;
    if (_timeFilter == 'today') {
      cutoff = DateTime(now.year, now.month, now.day);
    } else if (_timeFilter == 'week') {
      cutoff = now.subtract(const Duration(days: 7));
    } else if (_timeFilter == 'month') {
      cutoff = now.subtract(const Duration(days: 30));
    } else {
      return _allPosts;
    }
    return _allPosts.where((post) {
      try {
        final date = DateTime.parse(post['date']).toLocal();
        return date.isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();
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
          _allPosts.addAll(list);
          if (_allPosts.length > 150) _allPosts.removeRange(0, 50);
          _posts.clear();
          _posts.addAll(_applyTimeFilter());
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
      _allPosts.clear();
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
            _buildPremiumNewsHeader(context),
            _buildTimeFilterBar(),
            Expanded(
              child: _posts.isEmpty && _loading
                  ? const NewsSkeleton()
                  : _posts.isEmpty && _error != null
                      ? ErrorBox(
                          message: 'خطا در دریافت اخبار.\n$_error',
                          onRetry: _refresh)
                      : _posts.isEmpty
                          ? _timeFilter != 'all' && _allPosts.isNotEmpty
                              ? _buildEmptyFilter()
                              : const EmptyWidget(
                                  text: 'خبری پیدا نشد.')
                          : RefreshIndicator(
                              color: kAcademicBurgundy,
                              backgroundColor: pnl,
                              strokeWidth: 3,
                              onRefresh: _refresh,
                              child: ListView.builder(
                                controller: _scroll,
                                cacheExtent: 800,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                    14, 8, 14, 120),
                                itemCount:
                                    _posts.length + (_hasMore ? 1 : 0),
                                itemBuilder: (c, i) {
                                  if (i >= _posts.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            color: kAcademicBurgundy),
                                      ),
                                    );
                                  }
                                  return _PremiumNewsCard(
                                      post: _posts[i]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumNewsHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kAcademicBurgundy,
                    kAcademicBurgundy.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kAcademicBurgundy.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.newspaper_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            kAcademicBurgundy,
                            kAcademicGold,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'اخبار و رویدادها',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: txtC,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: kAcademicBurgundy,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kAcademicBurgundy
                                  .withOpacity(0.7),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'آخرین اخبار ورزشی ایران و جهان',
                    style: TextStyle(
                      color: mutC,
                      fontSize: 10.5,
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              ),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: pnl,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: lineC),
                ),
                child: Icon(Icons.search_rounded,
                    color: txtC, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterBar() {
    final isDark = darkModeNotifier.value;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 0, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _timeFilters.map((filter) {
            final selected = _timeFilter == filter['key'];
            final color = filter['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _timeFilter = filter['key'] as String;
                    _posts.clear();
                    _posts.addAll(_applyTimeFilter());
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              color,
                              color.withOpacity(0.7),
                            ],
                          )
                        : null,
                    color: selected ? null : pnl,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? color
                          : (isDark
                              ? Colors.white.withOpacity(0.08)
                              : lineC),
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        color: selected ? Colors.white : color,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter['label'] as String,
                        style: TextStyle(
                          color: selected ? Colors.white : txtC,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      if (selected && _posts.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_posts.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyFilter() {
    final filter = _timeFilters.firstWhere(
      (f) => f['key'] == _timeFilter,
      orElse: () => _timeFilters.first,
    );
    final color = filter['color'] as Color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                filter['icon'] as IconData,
                color: color,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'خبری در «${filter['label']}» پیدا نشد',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _timeFilter = 'all';
                  _posts.clear();
                  _posts.addAll(_applyTimeFilter());
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kAcademicNavy,
                      kAcademicNavy.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: kAcademicNavy.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.apps_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'نمایش همه اخبار',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
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

/* ==================== PREMIUM NEWS CARD ==================== */

class _PremiumNewsCard extends StatefulWidget {
  final dynamic post;
  const _PremiumNewsCard({required this.post});

  @override
  State<_PremiumNewsCard> createState() => _PremiumNewsCardState();
}

class _PremiumNewsCardState extends State<_PremiumNewsCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final title = pTitle(post);
    final link = pLink(post);
    final img = pImg(post);
    final cat = pCategory(post);
    final date = pTimeAgo(post);
    final excerpt = pExcerpt(post, maxChars: 110);
    final isDark = darkModeNotifier.value;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => openUrl(context, link),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark
                ? [
                    kAcademicBurgundy.withOpacity(0.15),
                    kDarkCard,
                  ]
                : [
                    const Color(0xfffff5f5),
                    Colors.white,
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed
                ? kAcademicBurgundy.withOpacity(0.6)
                : lineC,
            width: _pressed ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _pressed
                  ? kAcademicBurgundy.withOpacity(0.2)
                  : Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: _pressed ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (img.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        memCacheWidth: 1080,
                        memCacheHeight: 540,
                        maxWidthDiskCache: 1080,
                        maxHeightDiskCache: 540,
                        fadeInDuration:
                            const Duration(milliseconds: 300),
                        fadeOutDuration:
                            const Duration(milliseconds: 200),
                        placeholder: (_, __) => Container(
                          color: pnl2,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kAcademicBurgundy
                                    .withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: pnl2,
                          child: Icon(Icons.newspaper_rounded,
                              color: kAcademicBurgundy,
                              size: 48),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.75),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (cat.isNotEmpty)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  kAcademicBurgundy,
                                  kAcademicBurgundy.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: kAcademicBurgundy
                                      .withOpacity(0.5),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  cat,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
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
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (img.isEmpty && cat.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kAcademicBurgundy,
                                kAcademicBurgundy.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cat,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                      if (img.isEmpty) const Spacer(),
                      Icon(Icons.newspaper_rounded,
                          color: kAcademicBurgundy.withOpacity(0.6),
                          size: 16),
                    ],
                  ),
                  if (img.isEmpty && cat.isNotEmpty)
                    const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: txtC,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      height: 1.55,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kAcademicBurgundy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 6, color: kAcademicBurgundy),
                        const SizedBox(width: 6),
                        Text(
                          'مشاهده خبر',
                          style: TextStyle(
                            color: kAcademicBurgundy,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_back_ios_new_rounded,
                            color: kAcademicBurgundy, size: 10),
                      ],
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
}

/* ==================== PREMIUM SHOP PAGE ==================== */

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
          if (_products.length > 150) _products.removeRange(0, 50);
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
            _buildPremiumShopHeader(context),
            Expanded(
              child: _products.isEmpty && _loading
                  ? const ShopSkeleton()
                  : _products.isEmpty && _error != null
                      ? ErrorBox(
                          message: 'خطا در دریافت محصولات.\n$_error',
                          onRetry: _refresh)
                      : _products.isEmpty
                          ? const EmptyWidget(text: 'محصولی پیدا نشد.')
                          : RefreshIndicator(
                              color: kAcademicGold,
                              backgroundColor: pnl,
                              strokeWidth: 3,
                              onRefresh: _refresh,
                              child: ListView.builder(
                                controller: _scroll,
                                cacheExtent: 800,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                    14, 8, 14, 120),
                                itemCount: _products.length +
                                    (_hasMore ? 1 : 0),
                                itemBuilder: (c, i) {
                                  if (i >= _products.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            color: kAcademicGold),
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

  Widget _buildPremiumShopHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kAcademicGold,
                    kAcademicGoldDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kAcademicGold.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        kAcademicGold,
                        kAcademicNavy,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'فروشگاه تخصصی',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: txtC,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'منابع، کتب و محصولات ورزشی',
                    style: TextStyle(
                      color: mutC,
                      fontSize: 10.5,
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => openUrl(context, '$site/cart/',
                  title: 'سبد خرید'),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kAcademicGold.withOpacity(0.15),
                      kAcademicGold.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: kAcademicGold.withOpacity(0.3),
                  ),
                ),
                child: const Icon(Icons.shopping_cart_rounded,
                    color: kAcademicGold, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/* ==================== PREMIUM BOOKMARKS PAGE (3 TABS) ==================== */

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});
  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _allPosts = <dynamic>[];
  final _allNews = <dynamic>[];
  final _allProducts = <dynamic>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      try {
        final list = await getPostsPaged(perPage: 50, page: 1);
        _allPosts.clear();
        _allPosts.addAll(list);
      } catch (_) {}
      try {
        final news = await getNewNewsList();
        _allNews.clear();
        _allNews.addAll(news);
      } catch (_) {}
      try {
        final products =
            await getProductsPaged(perPage: 50, page: 1);
        _allProducts.clear();
        _allProducts.addAll(products);
      } catch (_) {}
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: bgC,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kAcademicGold,
                        kAcademicGoldDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kAcademicGold.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'نشان‌شده‌ها',
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
            actions: [
              ValueListenableBuilder<Set<String>>(
                valueListenable: bookmarkNotifier,
                builder: (c, b1, __) {
                  return ValueListenableBuilder<Set<String>>(
                    valueListenable: newsBookmarkNotifier,
                    builder: (c, b2, __) {
                      return ValueListenableBuilder<Set<String>>(
                        valueListenable: productBookmarkNotifier,
                        builder: (c, b3, __) {
                          final total =
                              b1.length + b2.length + b3.length;
                          if (total == 0) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            tooltip: 'پاک کردن همه',
                            onPressed: () =>
                                _confirmClearAll(context),
                            icon: Icon(
                              Icons.delete_sweep_rounded,
                              color: rose,
                              size: 22,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                height: 44,
                decoration: BoxDecoration(
                  color: pnl,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: lineC),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kAcademicNavy,
                        kAcademicNavy.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: kAcademicNavy.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding:
                      const EdgeInsets.symmetric(horizontal: 4),
                  labelColor: Colors.white,
                  unselectedLabelColor: txtC.withOpacity(0.7),
                  labelStyle: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: [
                    _tabItem(
                      icon: Icons.article_rounded,
                      label: 'مقالات',
                      count: bookmarkNotifier.value.length,
                    ),
                    _tabItem(
                      icon: Icons.bolt_rounded,
                      label: 'اخبار',
                      count: newsBookmarkNotifier.value.length,
                    ),
                    _tabItem(
                      icon: Icons.shopping_bag_rounded,
                      label: 'محصولات',
                      count: productBookmarkNotifier.value.length,
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: _loading
              ? const ArticlesSkeleton()
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildPostsTab(),
                    _buildNewsTab(),
                    _buildProductsTab(),
                  ],
                ),
        );
      },
    );
  }

  Widget _tabItem({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: bookmarkNotifier,
      builder: (context, bookmarks, __) {
        final saved = _allPosts
            .where((p) => bookmarks.contains(pId(p)))
            .toList();
        if (saved.isEmpty) {
          return _emptyTab(
            icon: Icons.article_outlined,
            color: kAcademicNavy,
            title: 'هنوز مقاله‌ای نشان نکرده‌اید',
            subtitle:
                'با زدن آیکون نشان روی کارت مقالات، اینجا ذخیره می‌شوند',
          );
        }
        return RefreshIndicator(
          color: kAcademicNavy,
          backgroundColor: pnl,
          strokeWidth: 3,
          onRefresh: _loadAll,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
            itemCount: saved.length,
            itemBuilder: (c, i) => ModernPostCard(
              post: saved[i],
              showBookmark: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsTab() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: newsBookmarkNotifier,
      builder: (context, bookmarks, __) {
        final saved = _allNews
            .where((p) => bookmarks.contains(pId(p)))
            .toList();
        if (saved.isEmpty) {
          return _emptyTab(
            icon: Icons.bolt_outlined,
            color: const Color(0xff38bdf8),
            title: 'هنوز خبری نشان نکرده‌اید',
            subtitle:
                'با زدن آیکون نشان روی کارت اخبار فوری، اینجا ذخیره می‌شوند',
          );
        }
        return RefreshIndicator(
          color: const Color(0xff38bdf8),
          backgroundColor: pnl,
          strokeWidth: 3,
          onRefresh: _loadAll,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 100),
            itemCount: saved.length,
            itemBuilder: (c, i) =>
                ModernUrgentNewsCard(news: saved[i]),
          ),
        );
      },
    );
  }

  Widget _buildProductsTab() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: productBookmarkNotifier,
      builder: (context, bookmarks, __) {
        final saved = _allProducts
            .where((p) => bookmarks.contains(pId(p)))
            .toList();
        if (saved.isEmpty) {
          return _emptyTab(
            icon: Icons.shopping_bag_outlined,
            color: kAcademicGold,
            title: 'هنوز محصولی نشان نکرده‌اید',
            subtitle:
                'با زدن آیکون نشان روی کارت محصولات، اینجا ذخیره می‌شوند',
          );
        }
        return RefreshIndicator(
          color: kAcademicGold,
          backgroundColor: pnl,
          strokeWidth: 3,
          onRefresh: _loadAll,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
            itemCount: saved.length,
            itemBuilder: (c, i) => ModernProductCard(
              product: saved[i],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyTab({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: color, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutC,
                fontSize: 12,
                height: 1.7,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pnl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: rose, size: 24),
            const SizedBox(width: 8),
            Text(
              'پاک کردن همه',
              style: TextStyle(
                color: txtC,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید همه نشان‌شده‌ها را پاک کنید؟',
          style: TextStyle(
            color: mutC,
            fontFamily: 'Vazirmatn',
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'انصراف',
              style: TextStyle(
                color: mutC,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'پاک کن',
              style: TextStyle(
                color: rose,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await clearAllBookmarks();
      if (mounted) showSnack(context, 'همه نشان‌شده‌ها پاک شد');
    }
  }
}

/* ==================== PREMIUM SEARCH PAGE ==================== */

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
  String? _selectedCategory;
  String _sortBy = 'relevance';
  Timer? _debounce;
  List<String> _history = [];

  final List<Map<String, dynamic>> _sortOptions = [
    {
      'key': 'relevance',
      'label': 'مرتبط‌ترین',
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'key': 'newest',
      'label': 'جدیدترین',
      'icon': Icons.schedule_rounded,
    },
    {
      'key': 'oldest',
      'label': 'قدیمی‌ترین',
      'icon': Icons.history_rounded,
    },
  ];

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
        _f = _runSearch(q);
      });
      _saveHistory(q);
    });
  }

  Future<List> _runSearch(String q) async {
    var list = await searchExact(q, categorySlug: _selectedCategory);
    if (_sortBy == 'newest' || _sortBy == 'oldest') {
      list = List.from(list);
      list.sort((a, b) {
        final da = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
        return _sortBy == 'newest'
            ? db.compareTo(da)
            : da.compareTo(db);
      });
    }
    return list;
  }

  void _applyFilters() {
    if (_q.isNotEmpty) {
      setState(() {
        _f = _runSearch(_q);
      });
    }
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
        body: Column(
          children: [
            _buildPremiumSearchHeader(),
            if (_q.isNotEmpty) _buildFiltersBar(),
            Expanded(
              child: _f == null
                  ? _buildHistory()
                  : FutureBuilder<List>(
                      future: _f,
                      builder: (c, s) {
                        if (s.connectionState ==
                            ConnectionState.waiting) {
                          return const SearchSkeleton();
                        }
                        if (s.hasError) {
                          return ErrorBox(
                              message: 'خطا در جستجو.\n${s.error}',
                              onRetry: null);
                        }
                        final posts = s.data ?? [];
                        if (posts.isEmpty) {
                          return _buildEmptyResult();
                        }
                        return Column(
                          children: [
                            _buildResultsCount(posts.length),
                            Expanded(
                              child: ListView.builder(
                                cacheExtent: 800,
                                physics:
                                    const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                    14, 4, 14, 100),
                                itemCount: posts.length,
                                itemBuilder: (c, i) => ModernPostCard(
                                  post: posts[i],
                                  showBookmark: true,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSearchHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: pnl,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: lineC),
                ),
                child: Icon(Icons.arrow_forward_rounded,
                    color: txtC, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentNotifier.value.withOpacity(0.08),
                      pnl,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _focus.hasFocus
                        ? accentNotifier.value.withOpacity(0.5)
                        : lineC,
                    width: _focus.hasFocus ? 1.5 : 1,
                  ),
                  boxShadow: _focus.hasFocus
                      ? [
                          BoxShadow(
                            color: accentNotifier.value
                                .withOpacity(0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                  style: TextStyle(
                      color: txtC,
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'جستجو در مقالات و اخبار...',
                    hintStyle: TextStyle(
                        color: mutC,
                        fontFamily: 'Vazirmatn',
                        fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: accentNotifier.value),
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
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 0, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            ..._sortOptions.map((opt) {
              final selected = _sortBy == opt['key'];
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _sortBy = opt['key']);
                    _applyFilters();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                              colors: [
                                kAcademicNavy,
                                kAcademicNavy.withOpacity(0.7),
                              ],
                            )
                          : null,
                      color: selected ? null : pnl,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? kAcademicNavy
                            : lineC,
                        width: 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: kAcademicNavy
                                    .withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt['icon'] as IconData,
                          color: selected ? Colors.white : mutC,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          opt['label'] as String,
                          style: TextStyle(
                            color: selected ? Colors.white : txtC,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showCategoryPicker,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: _selectedCategory != null
                      ? LinearGradient(
                          colors: [
                            kAcademicGold,
                            kAcademicGoldDark,
                          ],
                        )
                      : null,
                  color: _selectedCategory != null ? null : pnl,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedCategory != null
                        ? kAcademicGold
                        : lineC,
                    width: 1,
                  ),
                  boxShadow: _selectedCategory != null
                      ? [
                          BoxShadow(
                            color: kAcademicGold
                                .withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_rounded,
                      color: _selectedCategory != null
                          ? Colors.white
                          : mutC,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _selectedCategory != null
                          ? 'دسته‌بندی فعال'
                          : 'دسته‌بندی',
                      style: TextStyle(
                        color: _selectedCategory != null
                            ? Colors.white
                            : txtC,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    if (_selectedCategory != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = null);
                          _applyFilters();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 10, color: kAcademicGold),
                        ),
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

  Widget _buildResultsCount(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentNotifier.value.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: accentNotifier.value, size: 12),
                const SizedBox(width: 4),
                Text(
                  '$count نتیجه',
                  style: TextStyle(
                    color: accentNotifier.value,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'برای «$_q»',
            style: TextStyle(
              color: mutC,
              fontSize: 11,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentNotifier.value.withOpacity(0.15),
                    accentNotifier.value.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentNotifier.value.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: accentNotifier.value,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'نتیجه‌ای پیدا نشد',
              style: TextStyle(
                color: txtC,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'برای «$_q» نتیجه‌ای پیدا نشد.\nلطفاً کلمه دیگری را امتحان کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutC,
                fontSize: 12.5,
                height: 1.8,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentNotifier.value.withOpacity(0.15),
                      accentNotifier.value.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentNotifier.value.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: accentNotifier.value,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'جستجو کنید',
                style: TextStyle(
                  color: txtC,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'عبارت مورد نظر خود را وارد کنید\nتا در مقالات و اخبار جستجو شود',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mutC,
                  fontSize: 12.5,
                  height: 1.8,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kAcademicGold, kAcademicGoldDark],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: kAcademicGold.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.history_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'جستجوهای اخیر',
                style: TextStyle(
                  color: txtC,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearHistory,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: rose.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'پاک کردن',
                    style: TextStyle(
                      color: rose,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (c, i) {
                final q = _history[i];
                return GestureDetector(
                  onTap: () => _searchFromHistory(q),
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
                        Icon(Icons.history_rounded,
                            color: mutC, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            q,
                            style: TextStyle(
                              color: txtC,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                        Icon(Icons.north_west_rounded,
                            color: mutC, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: pnl,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: lineC),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: mutC.withOpacity(0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kAcademicGold,
                          kAcademicGoldDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.filter_alt_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'انتخاب دسته‌بندی',
                    style: TextStyle(
                      color: txtC,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.fromLTRB(14, 0, 14, 20),
                itemCount: cats.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (c, i) {
                  if (i == 0) {
                    return _categoryItem(
                      icon: Icons.apps_rounded,
                      label: 'همه دسته‌ها',
                      color: kAcademicNavy,
                      selected: _selectedCategory == null,
                      onTap: () {
                        setState(() => _selectedCategory = null);
                        Navigator.pop(ctx);
                        _applyFilters();
                      },
                    );
                  }
                  final cat = cats[i - 1];
                  final selected = _selectedCategory == cat.s;
                  return _categoryItem(
                    icon: cat.i,
                    label: cat.n,
                    color: cat.c,
                    selected: selected,
                    onTap: () {
                      setState(() => _selectedCategory = cat.s);
                      Navigator.pop(ctx);
                      _applyFilters();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                )
              : null,
          color: selected ? null : pnl,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : lineC,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      )
                    : null,
                color: selected ? null : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? color : txtC,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w900 : FontWeight.w700,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

/* ==================== PREMIUM ACCOUNT PAGE ==================== */

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage>
    with SingleTickerProviderStateMixin {
  InAppWebViewController? _controller;
  bool _l = true;
  double _progress = 0;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    ));
    _entryCtrl.forward();
    _restore();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
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
            _buildPremiumAccountHeader(context),
            if (_l && _progress > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: lineC,
                    color: const Color(0xff4a148c),
                    minHeight: 4,
                  ),
                ),
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
                      cacheEnabled: true,
                      clearCache: false,
                      transparentBackground: true,
                      supportZoom: true,
                      allowsInlineMediaPlayback: true,
                      mediaPlaybackRequiresUserGesture: false,
                      useHybridComposition: true,
                      domStorageEnabled: true,
                      databaseEnabled: true,
                      isFraudulentWebsiteWarningEnabled: true,
                      safeBrowsingEnabled: true,
                      disableContextMenu: false,
                      disableVerticalScroll: false,
                      disableHorizontalScroll: false,
                      verticalScrollBarEnabled: true,
                      horizontalScrollBarEnabled: false,
                      textZoom: 100,
                      useWideViewPort: true,
                      loadWithOverviewMode: true,
                      thirdPartyCookiesEnabled: true,
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
                    onReceivedError: (controller, request, error) {
                      if (request.isForMainFrame ?? false) {
                        setState(() {
                          _l = false;
                          _progress = 0;
                        });
                      }
                    },
                    onReceivedHttpError:
                        (controller, request, response) {
                      debugPrint(
                          'Account WebView HTTP Error: ${response.statusCode}');
                    },
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
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        color: bgC,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xff4a148c),
                                      kAcademicNavy,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xff4a148c)
                                          .withOpacity(0.4),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 42,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'در حال بارگذاری...',
                                style: TextStyle(
                                  color: txtC,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'لطفاً منتظر بمانید',
                                style: TextStyle(
                                  color: mutC,
                                  fontSize: 12,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(height: 20),
                              const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Color(0xff4a148c),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildPremiumAccountHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xff4a148c),
                        kAcademicNavy,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff4a148c)
                            .withOpacity(0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            const Color(0xff4a148c),
                            kAcademicNavy,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'حساب کاربری',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: txtC,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'سفارش‌ها، اطلاعات و پنل ادمین',
                        style: TextStyle(
                          color: mutC,
                          fontSize: 10.5,
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminLoginPage()),
                    );
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kAcademicGold.withOpacity(0.15),
                          kAcademicGold.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: kAcademicGold.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: kAcademicGold,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _quickActionBtn(
                        context,
                        icon: Icons.receipt_long_rounded,
                        label: 'سفارش‌ها',
                        color: const Color(0xff4a148c),
                        url: '$site/my-account/orders/',
                      ),
                      const SizedBox(width: 8),
                      _quickActionBtn(
                        context,
                        icon: Icons.location_on_rounded,
                        label: 'آدرس‌ها',
                        color: kAcademicNavyLight,
                        url: '$site/my-account/edit-address/',
                      ),
                      const SizedBox(width: 8),
                      _quickActionBtn(
                        context,
                        icon: Icons.favorite_rounded,
                        label: 'علاقه‌مندی‌ها',
                        color: kAcademicBurgundy,
                        url: '$site/my-account/wishlist/',
                      ),
                      const SizedBox(width: 8),
                      _quickActionBtn(
                        context,
                        icon: Icons.settings_rounded,
                        label: 'تنظیمات',
                        color: const Color(0xff046a38),
                        url: '$site/my-account/edit-account/',
                      ),
                      const SizedBox(width: 8),
                      _quickActionBtn(
                        context,
                        icon: Icons.headset_mic_rounded,
                        label: 'پشتیبانی',
                        color: kAcademicGold,
                        url: '$site/contact/',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _quickActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (_controller != null) {
          _controller!.loadUrl(
              urlRequest: URLRequest(url: WebUri(url)));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
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
            onPressed: () async {
              HapticFeedback.selectionClick();
              await _controller?.reload();
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
              color: accentNotifier.value,
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
              cacheEnabled: true,
              clearCache: false,
              transparentBackground: true,
              allowsInlineMediaPlayback: true,
              useHybridComposition: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              disableVerticalScroll: false,
              disableHorizontalScroll: false,
              verticalScrollBarEnabled: true,
              horizontalScrollBarEnabled: false,
              textZoom: 100,
              useWideViewPort: true,
              loadWithOverviewMode: true,
              thirdPartyCookiesEnabled: true,
            ),
            onWebViewCreated: (c) => _controller = c,
            onLoadStart: (c, url) => setState(() => _l = true),
            onLoadStop: (c, url) {
              setState(() {
                _l = false;
                _progress = 0;
              });
            },
            onProgressChanged: (c, p) =>
                setState(() => _progress = p / 100),
            onReceivedError: (controller, request, error) {
              if (request.isForMainFrame ?? false) {
                setState(() {
                  _l = false;
                  _progress = 0;
                });
              }
            },
            onReceivedHttpError: (controller, request, response) {
              debugPrint(
                  'HTTP Error: ${response.statusCode} - ${request.url}');
            },
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
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentNotifier.value.withOpacity(0.15),
                      accentNotifier.value.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentNotifier.value.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: accentNotifier.value,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
                                  Color(0xff38bdf8),
                                  Color(0xff0ea5e9),
                                  Color(0xff0284c7),
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
                ? kDarkBg.withOpacity(0.85)
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
                onTap: () => sharePostWithImage(
                  pLink(widget.news),
                  pTitle(widget.news),
                  imageUrl: pImg(widget.news),
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
                  const Color(0xff082f49),
                  const Color(0xff0c4a6e),
                  kDarkCard,
                ]
              : [
                  const Color(0xffe0f2fe),
                  const Color(0xfff0f9ff),
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xff0ea5e9).withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0ea5e9).withOpacity(0.25),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xff38bdf8).withOpacity(0.15),
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
                      const Color(0xff0ea5e9)
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
                      const Color(0xff38bdf8)
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
                            Color(0xff38bdf8),
                            Color(0xff0ea5e9),
                            Color(0xff0284c7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff0ea5e9)
                                .withOpacity(0.55),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                          BoxShadow(
                            color: const Color(0xff38bdf8)
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
                            Color(0xff0ea5e9),
                            Color(0xff0284c7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff0ea5e9)
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
                        color: const Color(0xff38bdf8).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xff38bdf8).withOpacity(0.4),
                        ),
                      ),
                      child: Icon(
                        Icons.newspaper_rounded,
                        color: const Color(0xff38bdf8).withOpacity(0.9),
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
                              color: const Color(0xff0ea5e9)
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
                        const Color(0xff0ea5e9).withOpacity(0.6),
                        const Color(0xff38bdf8).withOpacity(0.4),
                        const Color(0xff0284c7).withOpacity(0.2),
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
                      color: const Color(0xff0ea5e9),
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      icon: Icons.access_time_rounded,
                      label: '$readTime دقیقه',
                      color: const Color(0xff38bdf8),
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      icon: Icons.text_fields_rounded,
                      label: '$words کلمه',
                      color: const Color(0xff0284c7),
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
                            Color(0xff0ea5e9),
                            Color(0xff0284c7),
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
                      kAcademicNavy,
                      kAcademicNavyLight,
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
    final imageUrl = pImg(widget.news);
    final excerpt = pExcerpt(widget.news, maxChars: 100);

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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff0ea5e9),
                          Color(0xff0284c7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff0ea5e9)
                              .withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.ios_share_rounded,
                        color: Colors.white, size: 20),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pnl2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: lineC),
                ),
                child: Row(
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
                            placeholder: (_, __) =>
                                Container(color: pnl),
                            errorWidget: (_, __, ___) => Container(
                              color: pnl,
                              child: Icon(Icons.newspaper_rounded,
                                  color: mutC, size: 24),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: pnl,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.newspaper_rounded,
                            color: mutC, size: 24),
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
                            style: TextStyle(
                              color: txtC,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              height: 1.5,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          if (excerpt.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              excerpt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: mutC,
                                fontSize: 10,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                        'mailto:?subject=${Uri.encodeComponent(title)}&body=${Uri.encodeComponent(link)}',
                      );
                    },
                  ),
                  _sheetOption(
                    icon: Icons.share_rounded,
                    label: 'سایر',
                    color: purple,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await sharePostWithImage(link, title,
                          imageUrl: imageUrl);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pnl2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lineC),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentNotifier.value,
                                accentNotifier.value.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.link_rounded,
                              color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'لینک خبر',
                          style: TextStyle(
                            color: txtC,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: link));
                            HapticFeedback.lightImpact();
                            showSnack(context, 'لینک کپی شد ✅');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentNotifier.value,
                                  accentNotifier.value
                                      .withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded,
                                    color: Colors.white, size: 11),
                                SizedBox(width: 4),
                                Text(
                                  'کپی',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bgC,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color:
                              accentNotifier.value.withOpacity(0.2),
                        ),
                      ),
                      child: SelectableText(
                        link,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: txtC,
                          fontSize: 11.5,
                          height: 1.5,
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w600,
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
                          Color(0xff0ea5e9),
                          Color(0xff0284c7),
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
                              color: const Color(0xff0ea5e9)
                                  .withOpacity(.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xff0ea5e9),
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
          color: const Color(0xff0ea5e9),
          backgroundColor: pnl,
          onRefresh: _refresh,
          child: FutureBuilder<List>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const NewsSkeleton();
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
                      kAcademicGold.withOpacity(0.2),
                      kAcademicGold.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: kAcademicGold.withOpacity(0.3)),
                ),
                child: Icon(Icons.lock_rounded,
                    color: kAcademicGold, size: 42),
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
                  color: kAcademicNavy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: kAcademicNavy.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_rounded,
                        color: kAcademicNavy, size: 18),
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

/* ==================== ADMIN PANEL WITH FILE UPLOAD ==================== */

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

  PlatformFile? _selectedFile;
  bool _uploadingFile = false;
  String? _uploadedFileUrl;
  String? _uploadedFileName;
  String? _uploadedMediaId;

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

  Future<void> _pickFile() async {
    HapticFeedback.selectionClick();
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: false,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) {
        showSnack(context, 'خطا در دسترسی به فایل', error: true);
        return;
      }
      if (file.size > 20 * 1024 * 1024) {
        showSnack(context, 'حجم فایل نباید بیش از ۲۰ مگابایت باشد.',
            error: true);
        return;
      }
      setState(() {
        _selectedFile = file;
        _uploadedFileUrl = null;
        _uploadedFileName = null;
        _uploadedMediaId = null;
      });
    } catch (e) {
      showSnack(context, 'خطا: $e', error: true);
    }
  }

  void _removeFile() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFile = null;
      _uploadedFileUrl = null;
      _uploadedFileName = null;
      _uploadedMediaId = null;
    });
  }

  Future<bool> _uploadFileIfNeeded() async {
    if (_selectedFile == null) return true;
    if (_uploadedFileUrl != null) return true;
    if (_selectedFile!.path == null) return false;
    setState(() => _uploadingFile = true);

    try {
      final result = await uploadMedia(
        username: widget.username,
        appPassword: widget.password,
        filePath: _selectedFile!.path!,
        fileName: _selectedFile!.name,
      );

      final sourceUrl = result['source_url']?.toString() ?? '';
      final mediaId = result['id']?.toString() ?? '';

      if (sourceUrl.isEmpty) {
        throw Exception('URL فایل یافت نشد');
      }

      setState(() {
        _uploadedFileUrl = sourceUrl;
        _uploadedFileName = _selectedFile!.name;
        _uploadedMediaId = mediaId;
      });
      return true;
    } catch (e) {
      if (mounted) {
        showSnack(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
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
      final fileOk = await _uploadFileIfNeeded();
      if (!fileOk) {
        if (mounted) setState(() => _sending = false);
        return;
      }

      String finalContent = content;
      if (_uploadedFileUrl != null) {
        final ext =
            _uploadedFileName?.toLowerCase().split('.').last ?? '';
        String icon = '📎';
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
          finalContent +=
              '\n\n<img src="$_uploadedFileUrl" alt="$_uploadedFileName" style="max-width:100%; height:auto; border-radius:12px; margin-top:16px;" />';
        } else {
          if (ext == 'pdf') icon = '📄';
          if (['doc', 'docx'].contains(ext)) icon = '📝';
          if (['xls', 'xlsx'].contains(ext)) icon = '📊';
          if (['ppt', 'pptx'].contains(ext)) icon = '📽';
          if (['zip', 'rar'].contains(ext)) icon = '🗜';
          if (['mp4', 'avi', 'mov'].contains(ext)) icon = '🎬';
          if (['mp3', 'wav'].contains(ext)) icon = '🎵';

          finalContent +=
              '\n\n<p style="margin-top:20px; padding:12px; background:#f5f0e6; border-radius:10px; text-align:center;"><a href="$_uploadedFileUrl" target="_blank" style="color:#1e3a5f; font-weight:bold; text-decoration:none; font-size:15px;">$icon دانلود فایل: $_uploadedFileName</a></p>';
        }
      }

      await postNewNews(
        username: widget.username,
        appPassword: widget.password,
        title: title,
        content: finalContent,
      );

      if (!mounted) return;
      showSnack(context, '✅ خبر فوری با موفقیت منتشر شد!');
      _titleCtrl.clear();
      _contentCtrl.clear();
      setState(() {
        _selectedFile = null;
        _uploadedFileUrl = null;
        _uploadedFileName = null;
        _uploadedMediaId = null;
      });
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
                              color: kAcademicNavyLight
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.edit_rounded,
                                color: kAcademicNavyLight, size: 20),
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
                                      setDialogState(
                                          () => saving = true);
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
                                backgroundColor: kAcademicNavyLight,
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

  IconData _fileIcon(String ext) {
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(ext)) {
      return Icons.image_rounded;
    }
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx'].contains(ext)) return Icons.description_rounded;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart_rounded;
    if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow_rounded;
    if (['zip', 'rar', '7z'].contains(ext)) return Icons.archive_rounded;
    if (['mp4', 'avi', 'mov', 'mkv'].contains(ext)) {
      return Icons.videocam_rounded;
    }
    if (['mp3', 'wav', 'm4a'].contains(ext)) {
      return Icons.audiotrack_rounded;
    }
    if (ext == 'txt') return Icons.text_snippet_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _fileColor(String ext) {
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(ext)) {
      return const Color(0xff046a38);
    }
    if (ext == 'pdf') return const Color(0xffe10600);
    if (['doc', 'docx'].contains(ext)) return const Color(0xff2b579a);
    if (['xls', 'xlsx'].contains(ext)) return const Color(0xff217346);
    if (['ppt', 'pptx'].contains(ext)) return const Color(0xffd24726);
    if (['zip', 'rar', '7z'].contains(ext)) {
      return kAcademicGold;
    }
    if (['mp4', 'avi', 'mov', 'mkv'].contains(ext)) {
      return const Color(0xff4a148c);
    }
    if (['mp3', 'wav', 'm4a'].contains(ext)) {
      return const Color(0xffec4899);
    }
    return const Color(0xff6b7280);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
                  color: kAcademicNavy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: kAcademicNavy.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: kAcademicNavy, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'خبر فوری پس از انتشار، بالای صفحه اصلی اپ نمایش داده می‌شود. می‌توانید فایل ضمیمه (PDF، تصویر، ویدیو، ZIP و...) هم اضافه کنید.',
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
              const SizedBox(height: 18),
              Text(
                'فایل ضمیمه (اختیاری)',
                style: TextStyle(
                  color: accentNotifier.value,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedFile == null)
                _buildFilePickerButton()
              else
                _buildSelectedFileCard(),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      (_sending || _uploadingFile) ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAcademicNavyLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: (_sending || _uploadingFile)
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
                    _uploadingFile
                        ? 'در حال آپلود فایل...'
                        : (_sending
                            ? 'در حال ارسال...'
                            : 'انتشار خبر فوری'),
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
                                color: kAcademicNavyLight,
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

  Widget _buildFilePickerButton() {
    final isDark = darkModeNotifier.value;
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    kAcademicNavy.withOpacity(0.25),
                    kAcademicNavy.withOpacity(0.1),
                  ]
                : [
                    kAcademicGold.withOpacity(0.15),
                    kAcademicGold.withOpacity(0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentNotifier.value.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentNotifier.value,
                    accentNotifier.value.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentNotifier.value.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'انتخاب فایل ضمیمه',
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF، تصویر، ویدیو، Word، Excel، ZIP و...\nحداکثر ۲۰ مگابایت',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutC,
                fontSize: 11,
                height: 1.6,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileCard() {
    final file = _selectedFile!;
    final ext = file.name.toLowerCase().split('.').last;
    final color = _fileColor(ext);
    final icon = _fileIcon(ext);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: txtC,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        ext.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatSize(file.size),
                      style: TextStyle(
                        color: mutC,
                        fontSize: 10.5,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    if (_uploadedFileUrl != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xff046a38)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Color(0xff046a38), size: 10),
                            SizedBox(width: 3),
                            Text(
                              'آپلود شده',
                              style: TextStyle(
                                color: Color(0xff046a38),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _uploadingFile ? null : _removeFile,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rose.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: rose.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.close_rounded,
                color: rose,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
/* ==================== OFFLINE ARTICLES PAGE ==================== */

class OfflineArticlesPage extends StatefulWidget {
  const OfflineArticlesPage({super.key});
  @override
  State<OfflineArticlesPage> createState() => _OfflineArticlesPageState();
}

class _OfflineArticlesPageState extends State<OfflineArticlesPage> {
  List<Map<String, dynamic>> _articles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final articles = await getAllOfflineArticles();
    if (mounted) {
      setState(() {
        _articles = articles;
        _loading = false;
      });
    }
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff046a38),
                      Color(0xff00b140),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff046a38)
                          .withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.download_done_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'مطالعه آفلاین',
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
        body: _loading
            ? const ArticlesSkeleton()
            : _articles.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    color: const Color(0xff046a38),
                    backgroundColor: pnl,
                    strokeWidth: 3,
                    onRefresh: _load,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          14, 14, 14, 100),
                      itemCount: _articles.length,
                      itemBuilder: (c, i) =>
                          _offlineCard(_articles[i]),
                    ),
                  ),
      ),
    );
  }

  Widget _offlineCard(Map<String, dynamic> article) {
    final id = article['id']?.toString() ?? '';
    final title = article['title']?.toString() ?? '';
    final excerpt = article['excerpt']?.toString() ?? '';
    final image = article['image']?.toString() ?? '';
    final category = article['category']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OfflineReaderPage(article: article),
        ),
      ).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: lineC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          placeholder: (_, __) =>
                              Container(color: pnl2),
                          errorWidget: (_, __, ___) => Container(
                            color: pnl2,
                            child: Icon(Icons.article_rounded,
                                color: mutC, size: 28),
                          ),
                        )
                      : Container(
                          color: pnl2,
                          child: Icon(Icons.article_rounded,
                              color: mutC, size: 28),
                        ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xff046a38)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download_done_rounded,
                                  color: Color(0xff046a38),
                                  size: 10),
                              SizedBox(width: 3),
                              Text(
                                'آفلاین',
                                style: TextStyle(
                                  color: Color(0xff046a38),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _remove(id);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: rose.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.delete_outline_rounded,
                                color: rose, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        excerpt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: mutC,
                          fontSize: 10.5,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        category,
                        style: TextStyle(
                          color: accentNotifier.value,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Vazirmatn',
                        ),
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

  Future<void> _remove(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pnl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'حذف از آفلاین',
          style: TextStyle(
            color: txtC,
            fontWeight: FontWeight.w900,
            fontFamily: 'Vazirmatn',
          ),
        ),
        content: Text(
          'آیا می‌خواهید این مقاله را از ذخیره آفلاین حذف کنید؟',
          style: TextStyle(
            color: mutC,
            fontFamily: 'Vazirmatn',
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('انصراف',
                style: TextStyle(
                    color: mutC, fontFamily: 'Vazirmatn')),
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
    if (confirm == true) {
      await removeOfflineArticle(id);
      _load();
      if (mounted) showSnack(context, 'مقاله حذف شد');
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xff046a38).withOpacity(0.15),
                    const Color(0xff046a38).withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xff046a38).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.download_outlined,
                color: Color(0xff046a38),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'هنوز مقاله‌ای ذخیره نکرده‌اید',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'با زدن آیکون دانلود روی کارت مقالات،\nمی‌توانید آن‌ها را برای مطالعه آفلاین ذخیره کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutC,
                fontSize: 12,
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

/* ==================== OFFLINE READER PAGE ==================== */

class OfflineReaderPage extends StatefulWidget {
  final Map<String, dynamic> article;
  const OfflineReaderPage({super.key, required this.article});

  @override
  State<OfflineReaderPage> createState() => _OfflineReaderPageState();
}

class _OfflineReaderPageState extends State<OfflineReaderPage> {
  double _fontSize = 16;
  double _lineHeight = 2.1;
  String _fontFamily = 'Vazirmatn';
  bool _isSepia = false;
  final _scroll = ScrollController();
  double _readingProgress = 0;
  bool _showToolbar = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _scroll.addListener(() {
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

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _fontSize = prefs.getDouble('reader_font_size') ?? 16;
        _lineHeight = prefs.getDouble('reader_line_height') ?? 2.1;
        _fontFamily = prefs.getString('reader_font') ?? 'Vazirmatn';
        _isSepia = prefs.getBool('reader_sepia') ?? false;
      });
    } catch (_) {}
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('reader_font_size', _fontSize);
      await prefs.setDouble('reader_line_height', _lineHeight);
      await prefs.setString('reader_font', _fontFamily);
      await prefs.setBool('reader_sepia', _isSepia);
    } catch (_) {}
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final title = article['title']?.toString() ?? '';
    final content = article['content']?.toString() ?? '';
    final category = article['category']?.toString() ?? '';
    final author = article['author']?.toString() ?? '';
    final date = article['date']?.toString() ?? '';

    final paragraphs = content
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    Color bgReader;
    Color txtReader;
    if (_isSepia) {
      bgReader = darkModeNotifier.value
          ? const Color(0xff2a1f0f)
          : const Color(0xfff4ecd8);
      txtReader = darkModeNotifier.value
          ? const Color(0xfff0e8d8)
          : const Color(0xff3a2f1f);
    } else {
      bgReader = bgC;
      txtReader = txtC;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgReader,
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accentNotifier.value
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: accentNotifier.value,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: txtReader,
                            fontSize: _fontSize + 4,
                            fontWeight: FontWeight.w900,
                            height: 1.6,
                            fontFamily: _fontFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (author.isNotEmpty) ...[
                              Icon(Icons.person_rounded,
                                  color: mutC, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                author,
                                style: TextStyle(
                                  color: mutC,
                                  fontSize: 11,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                            if (author.isNotEmpty && date.isNotEmpty)
                              const SizedBox(width: 12),
                            if (date.isNotEmpty) ...[
                              Icon(Icons.calendar_today_rounded,
                                  color: mutC, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                pDate({'date': date}),
                                style: TextStyle(
                                  color: mutC,
                                  fontSize: 11,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentNotifier.value,
                                accentNotifier.value.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: paragraphs.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            p,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: txtReader,
                              fontSize: _fontSize,
                              height: _lineHeight,
                              fontWeight: FontWeight.w500,
                              fontFamily: _fontFamily,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentNotifier.value,
                              accentNotifier.value.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildGlassAppBar(bgReader),
            if (_showToolbar) _buildSettingsSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassAppBar(Color bgReader) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: MediaQuery.of(context).padding.top + 56,
      decoration: BoxDecoration(
        color: bgReader.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: lineC.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _glassBtn(
                icon: Icons.arrow_forward_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              _glassBtn(
                icon: Icons.text_fields_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showToolbar = !_showToolbar);
                },
              ),
              const SizedBox(width: 4),
              _glassBtn(
                icon: _isSepia
                    ? Icons.brightness_1_rounded
                    : Icons.brightness_2_outlined,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isSepia = !_isSepia);
                  _savePrefs();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lineC),
        ),
        child: Icon(icon, color: txtC, size: 20),
      ),
    );
  }

  Widget _buildSettingsSheet() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          border: Border.all(color: lineC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                Icon(Icons.text_fields_rounded,
                    color: accentNotifier.value, size: 20),
                const SizedBox(width: 8),
                Text(
                  'اندازه فونت',
                  style: TextStyle(
                    color: txtC,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const Spacer(),
                Text(
                  '${_fontSize.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: accentNotifier.value,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _fontSize,
              min: 12,
              max: 24,
              divisions: 12,
              activeColor: accentNotifier.value,
              inactiveColor: lineC,
              onChanged: (v) {
                setState(() => _fontSize = v);
              },
              onChangeEnd: (_) => _savePrefs(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.format_line_spacing_rounded,
                    color: accentNotifier.value, size: 20),
                const SizedBox(width: 8),
                Text(
                  'فاصله خطوط',
                  style: TextStyle(
                    color: txtC,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const Spacer(),
                Text(
                  '${_lineHeight.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: accentNotifier.value,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _lineHeight,
              min: 1.5,
              max: 3.0,
              divisions: 15,
              activeColor: accentNotifier.value,
              inactiveColor: lineC,
              onChanged: (v) {
                setState(() => _lineHeight = v);
              },
              onChangeEnd: (_) => _savePrefs(),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== NOTIFICATIONS PAGE ==================== */

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _loading = true);
    try {
      await checkForNewNotifications();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<
          List<Map<String, dynamic>>>(
        valueListenable: inAppNotificationsNotifier,
        builder: (context, notifications, ___) {
          final unread =
              notifications.where((e) => e['read'] != true).length;

          return Scaffold(
            backgroundColor: bgC,
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff046a38),
                          Color(0xff00b140),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff046a38)
                              .withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اعلان‌ها',
                        style: TextStyle(
                          color: txtC,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      if (unread > 0)
                        Text(
                          '$unread جدید',
                          style: TextStyle(
                            color: kAcademicBurgundy,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              backgroundColor: bgC,
              foregroundColor: txtC,
              elevation: 0,
              actions: [
                if (notifications.isNotEmpty) ...[
                  IconButton(
                    tooltip: 'خوانده‌شده کردن همه',
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await markAllNotificationsRead();
                      if (context.mounted) {
                        showSnack(context,
                            'همه اعلان‌ها خوانده‌شده شد');
                      }
                    },
                    icon: Icon(Icons.done_all_rounded,
                        color: accentNotifier.value, size: 22),
                  ),
                  IconButton(
                    tooltip: 'حذف همه',
                    onPressed: () => _confirmClear(context),
                    icon: Icon(Icons.delete_sweep_rounded,
                        color: rose, size: 22),
                  ),
                ],
              ],
            ),
            body: _loading
                ? const SearchSkeleton()
                : notifications.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: const Color(0xff046a38),
                        backgroundColor: pnl,
                        strokeWidth: 3,
                        onRefresh: _check,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              14, 14, 14, 100),
                          itemCount: notifications.length,
                          itemBuilder: (c, i) =>
                              _notificationCard(notifications[i]),
                        ),
                      ),
          );
        },
      ),
    );
  }

  Widget _notificationCard(Map<String, dynamic> n) {
    final isRead = n['read'] == true;
    final id = n['id'].toString();
    final title = n['title']?.toString() ?? '';
    final excerpt = n['excerpt']?.toString() ?? '';
    final image = n['image']?.toString() ?? '';
    final dateStr = n['date']?.toString() ?? '';

    DateTime? date;
    try {
      date = DateTime.parse(dateStr).toLocal();
    } catch (_) {}

    final timeAgo = date != null
        ? pTimeAgo({'date': date.toIso8601String()})
        : '';

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await markNotificationRead(id);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UrgentNewsDetailPage(
              news: {
                'id': id,
                'title': {'rendered': title},
                'content': {'rendered': excerpt},
                'link': n['link'],
                'date': dateStr,
                '_embedded': {
                  'wp:featuredmedia': [
                    {'source_url': image}
                  ],
                },
              },
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: !isRead
              ? LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    const Color(0xff046a38).withOpacity(0.10),
                    const Color(0xff046a38).withOpacity(0.02),
                  ],
                )
              : null,
          color: isRead ? pnl : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !isRead
                ? const Color(0xff046a38).withOpacity(0.35)
                : lineC,
            width: !isRead ? 1.5 : 1,
          ),
          boxShadow: !isRead
              ? [
                  BoxShadow(
                    color: const Color(0xff046a38)
                        .withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: pnl2,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
                            placeholder: (_, __) =>
                                Container(color: pnl2),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.newspaper_rounded,
                              color: mutC,
                              size: 24,
                            ),
                          )
                        : Icon(
                            Icons.newspaper_rounded,
                            color: mutC,
                            size: 24,
                          ),
                  ),
                ),
                if (!isRead)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: kAcademicBurgundy,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgC, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: kAcademicBurgundy
                                .withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: txtC,
                      fontSize: 13,
                      fontWeight: isRead
                          ? FontWeight.w700
                          : FontWeight.w900,
                      height: 1.5,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  if (excerpt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      excerpt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: mutC,
                        fontSize: 11,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          color: mutC, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        timeAgo,
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xff046a38).withOpacity(0.15),
                    const Color(0xff046a38).withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xff046a38).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                color: Color(0xff046a38),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'اعلان جدیدی ندارید',
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'خبرهای فوری جدید اپ در اینجا نمایش داده می‌شود',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutC,
                fontSize: 12,
                height: 1.7,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pnl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'حذف همه اعلان‌ها',
          style: TextStyle(
            color: txtC,
            fontWeight: FontWeight.w900,
            fontFamily: 'Vazirmatn',
          ),
        ),
        content: Text(
          'آیا می‌خواهید همه اعلان‌ها را حذف کنید؟',
          style: TextStyle(
            color: mutC,
            fontFamily: 'Vazirmatn',
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('انصراف',
                style: TextStyle(
                    color: mutC, fontFamily: 'Vazirmatn')),
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
    if (confirm == true) {
      await clearAllNotifications();
      if (context.mounted) {
        showSnack(context, 'همه اعلان‌ها حذف شد');
      }
    }
  }
}

/* ==================== FOLLOWED CATEGORIES PAGE ==================== */

class FollowedCategoriesPage extends StatefulWidget {
  const FollowedCategoriesPage({super.key});
  @override
  State<FollowedCategoriesPage> createState() =>
      _FollowedCategoriesPageState();
}

class _FollowedCategoriesPageState
    extends State<FollowedCategoriesPage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<Set<String>>(
        valueListenable: followedCategoriesNotifier,
        builder: (context, followed, ___) {
          return Scaffold(
            backgroundColor: bgC,
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          kAcademicNavy,
                          kAcademicGold,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kAcademicNavy.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'دسته‌بندی‌های من',
                    style: TextStyle(
                      color: txtC,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
              backgroundColor: bgC,
              foregroundColor: txtC,
              elevation: 0,
              actions: [
                if (followed.isNotEmpty)
                  IconButton(
                    tooltip: 'پاک کردن همه',
                    onPressed: () => _confirmClear(context),
                    icon: Icon(Icons.delete_sweep_rounded,
                        color: rose, size: 22),
                  ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kAcademicNavy.withOpacity(0.12),
                        kAcademicGold.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: kAcademicNavy.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kAcademicNavy,
                              kAcademicGold,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              followed.isEmpty
                                  ? 'هنوز دسته‌ای دنبال نمی‌کنید'
                                  : '${followed.length} دسته‌بندی دنبال می‌شود',
                              style: TextStyle(
                                color: txtC,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'با دنبال کردن، در صفحه اصلی مطالب موردعلاقه‌تان را می‌بینید',
                              style: TextStyle(
                                color: mutC,
                                fontSize: 10.5,
                                height: 1.5,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                    itemCount: cats.length,
                    itemBuilder: (c, i) {
                      final cat = cats[i];
                      final isFollowed = followed.contains(cat.s);
                      return _categoryToggleCard(cat, isFollowed);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _categoryToggleCard(Cat cat, bool isFollowed) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        toggleFollowCategory(cat.s);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isFollowed
              ? LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    cat.c.withOpacity(0.18),
                    cat.c.withOpacity(0.05),
                  ],
                )
              : null,
          color: isFollowed ? null : pnl,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFollowed ? cat.c : lineC,
            width: isFollowed ? 1.5 : 1,
          ),
          boxShadow: isFollowed
              ? [
                  BoxShadow(
                    color: cat.c.withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isFollowed
                    ? LinearGradient(
                        colors: [cat.c, cat.c.withOpacity(0.7)],
                      )
                    : null,
                color: isFollowed ? null : cat.c.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isFollowed
                    ? [
                        BoxShadow(
                          color: cat.c.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                cat.i,
                color: isFollowed ? Colors.white : cat.c,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cat.n,
                style: TextStyle(
                  color: isFollowed ? cat.c : txtC,
                  fontSize: 13,
                  fontWeight:
                      isFollowed ? FontWeight.w900 : FontWeight.w700,
                  height: 1.5,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isFollowed
                    ? LinearGradient(
                        colors: [cat.c, cat.c.withOpacity(0.7)],
                      )
                    : null,
                color: isFollowed ? null : cat.c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFollowed ? cat.c : cat.c.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFollowed
                        ? Icons.check_rounded
                        : Icons.add_rounded,
                    color: isFollowed ? Colors.white : cat.c,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isFollowed ? 'دنبال می‌شود' : 'دنبال کن',
                    style: TextStyle(
                      color: isFollowed ? Colors.white : cat.c,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
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

  Future<void> _confirmClear(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pnl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'لغو دنبال کردن همه',
          style: TextStyle(
            color: txtC,
            fontWeight: FontWeight.w900,
            fontFamily: 'Vazirmatn',
          ),
        ),
        content: Text(
          'آیا می‌خواهید همه دسته‌بندی‌ها را از دنبال‌شده‌ها حذف کنید؟',
          style: TextStyle(
            color: mutC,
            fontFamily: 'Vazirmatn',
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('انصراف',
                style: TextStyle(
                    color: mutC, fontFamily: 'Vazirmatn')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('پاک کن',
                style: TextStyle(
                    color: rose,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await clearFollowedCategories();
      if (context.mounted) showSnack(context, 'همه حذف شد');
    }
  }
}

/* ==================== SKELETON: ARTICLES ==================== */

class ArticlesSkeleton extends StatelessWidget {
  const ArticlesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: pnl,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: lineC),
            ),
            child: Row(
              children: const [
                ShimmerBox(
                    height: 108, width: 108, radius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                          height: 14, width: 90, radius: 7),
                      SizedBox(height: 10),
                      ShimmerBox(height: 14),
                      SizedBox(height: 6),
                      ShimmerBox(height: 14, width: 160),
                      SizedBox(height: 12),
                      ShimmerBox(
                          height: 12, width: 70, radius: 6),
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
}

/* ==================== SKELETON: NEWS ==================== */

class NewsSkeleton extends StatelessWidget {
  const NewsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        children: List.generate(
          4,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: pnl,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: lineC),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                  child: ShimmerBox(height: 160, radius: 0),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(
                          height: 12, width: 80, radius: 6),
                      SizedBox(height: 10),
                      ShimmerBox(height: 15),
                      SizedBox(height: 6),
                      ShimmerBox(height: 15, width: 200),
                      SizedBox(height: 10),
                      ShimmerBox(height: 12),
                      SizedBox(height: 12),
                      ShimmerBox(
                          height: 30, width: 120, radius: 8),
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
}

/* ==================== SKELETON: SHOP ==================== */

class ShopSkeleton extends StatelessWidget {
  const ShopSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: pnl,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: lineC),
            ),
            child: Row(
              children: const [
                ShimmerBox(
                    height: 130, width: 110, radius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 14),
                      SizedBox(height: 6),
                      ShimmerBox(height: 14, width: 140),
                      SizedBox(height: 12),
                      ShimmerBox(
                          height: 16, width: 100, radius: 8),
                      SizedBox(height: 10),
                      ShimmerBox(
                          height: 26, width: 90, radius: 8),
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
}

/* ==================== SKELETON: SEARCH ==================== */

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        children: List.generate(
          4,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: pnl,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: lineC),
            ),
            child: Row(
              children: const [
                ShimmerBox(
                    height: 100, width: 100, radius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                          height: 12, width: 70, radius: 6),
                      SizedBox(height: 10),
                      ShimmerBox(height: 14),
                      SizedBox(height: 6),
                      ShimmerBox(height: 14, width: 150),
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
