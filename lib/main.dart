import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:app_links/app_links.dart';
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
final followedCategoriesNotifier = ValueNotifier<Set<String>>({});
final inAppNotificationsNotifier =
    ValueNotifier<List<Map<String, dynamic>>>([]);
final lastNewsCheckNotifier = ValueNotifier<String>('');
final readArticlesNotifier =
    ValueNotifier<List<Map<String, dynamic>>>([]);
final readingStatsNotifier = ValueNotifier<Map<String, dynamic>>({});
final accentNotifier = ValueNotifier<Color>(const Color(0xff1a2b47));

/* ==================== REFINED COLOR SYSTEM V2 ==================== */

/// 🎨 رنگ‌های اصلی برند
const Color kPrimaryNavy = Color(0xff1a2b47);
const Color kPrimaryNavyLight = Color(0xff2c4470);
const Color kPrimaryNavyDark = Color(0xff0f1a2e);
const Color kPrimaryNavySoft = Color(0xff4a6fa5);

/// 🎨 طلایی
const Color kAccentGold = Color(0xffc9a961);
const Color kAccentGoldLight = Color(0xffe0c987);
const Color kAccentGoldDark = Color(0xffa88840);
const Color kAccentGoldSoft = Color(0xfff0e4c0);

/// 🎨 رنگ‌های معنایی
const Color kUrgent = Color(0xffc1121f);
const Color kUrgentDark = Color(0xff9a0e17);
const Color kSuccess = Color(0xff059669);
const Color kSuccessLight = Color(0xff34d399);
const Color kWarning = Color(0xffd97706);
const Color kInfo = Color(0xff2563eb);
const Color kInfoLight = Color(0xff60a5fa);

/// 🎨 رنگ اخبار فوری (Breaking News Red)
const Color kNewsRed = Color(0xffdc2626);
const Color kNewsRedDark = Color(0xff991b1b);

/// 🎨 رنگ آبی روشن اخبار (News Blue)
const Color kNewsBlue = Color(0xff0ea5e9);
const Color kNewsBlueLight = Color(0xff38bdf8);
const Color kNewsBlueDark = Color(0xff0284c7);
const Color kNewsBlueSoft = Color(0xffe0f2fe);

/// 🎨 رنگ تب‌ها
const Color kTabHome = Color(0xff1a2b47);
const Color kTabArticles = Color(0xff1e40af);
const Color kTabNews = Color(0xffc1121f);
const Color kTabShop = Color(0xffd97706);
const Color kTabAccount = Color(0xff0d9488);

/// 🎨 رنگ کوئیز
const Color kQuizColor = Color(0xff7b2d26);
const Color kQuizColorDark = Color(0xff5c1f19);

/// 🌙 سطوح تیره
const Color kDarkBg = Color(0xff0a121e);
const Color kDarkCard = Color(0xff1a2538);
const Color kDarkCard2 = Color(0xff25334a);
const Color kDarkCard3 = Color(0xff30405a);
const Color kDarkBorder = Color(0xff344864);
const Color kDarkText = Color(0xfff0f4f8);
const Color kDarkTextMuted = Color(0xff94a3b8);

/// ☀️ سطوح روشن
const Color kLightBg = Color(0xfff5f7fa);
const Color kLightCard = Color(0xffffffff);
const Color kLightCard2 = Color(0xffeef2f7);
const Color kLightCard3 = Color(0xffe3e9f0);
const Color kLightBorder = Color(0xffdde3ea);
const Color kLightText = Color(0xff0f1419);
const Color kLightTextMuted = Color(0xff5c6370);

const List<Color> accentPalette = [
  Color(0xff1a2b47),
  Color(0xff2c4470),
  Color(0xff046a38),
  Color(0xff7b2d26),
  Color(0xff4a148c),
  Color(0xff00695c),
  Color(0xff8b6914),
  Color(0xff0f1a2e),
];

/* ==================== QUIZ MODEL ==================== */

final quizNotifier = ValueNotifier<List<QuizQuestion>>([]);
final answeredQuizNotifier = ValueNotifier<Map<String, int>>({});

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      };

  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
        id: m['id'].toString(),
        question: m['question'].toString(),
        options: (m['options'] as List).map((e) => e.toString()).toList(),
        correctIndex: m['correctIndex'] as int,
        explanation: m['explanation']?.toString(),
      );
}

Future<void> loadQuiz() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('quiz_questions');
    if (data != null && data.isNotEmpty) {
      final list = (json.decode(data) as List)
          .map((e) => QuizQuestion.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      quizNotifier.value = list;
    }
  } catch (_) {}
}

Future<void> saveQuiz() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'quiz_questions',
      json.encode(quizNotifier.value.map((q) => q.toMap()).toList()),
    );
  } catch (_) {}
}

Future<void> addQuizQuestion(QuizQuestion q) async {
  final list = List<QuizQuestion>.from(quizNotifier.value);
  list.add(q);
  quizNotifier.value = list;
  await saveQuiz();
}

Future<void> removeQuizQuestion(String id) async {
  final list = quizNotifier.value.where((q) => q.id != id).toList();
  quizNotifier.value = list;
  await saveQuiz();
}

Future<void> clearAllQuiz() async {
  quizNotifier.value = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quiz_questions');
  } catch (_) {}
}

/* ==================== QUIZ ANSWERS STORAGE ==================== */

Future<void> loadQuizAnswers() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('quiz_answers');
    if (data != null && data.isNotEmpty) {
      final map = <String, int>{};
      final decoded = json.decode(data) as Map<String, dynamic>;
      decoded.forEach((k, v) {
        map[k] = (v as num).toInt();
      });
      answeredQuizNotifier.value = map;
    }
  } catch (_) {}
}

Future<void> saveQuizAnswers() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'quiz_answers',
      json.encode(answeredQuizNotifier.value),
    );
  } catch (_) {}
}

Future<void> saveUserAnswer(String questionId, int selectedIndex) async {
  final map = Map<String, int>.from(answeredQuizNotifier.value);
  map[questionId] = selectedIndex;
  answeredQuizNotifier.value = map;
  await saveQuizAnswers();
}

Future<void> resetQuizAnswers() async {
  answeredQuizNotifier.value = {};
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quiz_answers');
  } catch (_) {}
}
/* ==================== THEME COLORS ==================== */

/// 🎨 پس‌زمینه‌ها
Color get bgC => darkModeNotifier.value ? kDarkBg : kLightBg;
Color get bgGrad1 => darkModeNotifier.value ? kDarkBg : kLightBg;
Color get bgGrad2 => darkModeNotifier.value
    ? const Color(0xff141d2e)
    : const Color(0xffeef2f7);

/// 🎨 کارت‌ها
Color get pnl => darkModeNotifier.value ? kDarkCard : kLightCard;
Color get pnl2 => darkModeNotifier.value ? kDarkCard2 : kLightCard2;
Color get pnl3 => darkModeNotifier.value ? kDarkCard3 : kLightCard3;

/// 🎨 متن‌ها
Color get txtC => darkModeNotifier.value ? kDarkText : kLightText;
Color get mutC =>
    darkModeNotifier.value ? kDarkTextMuted : kLightTextMuted;
Color get inkSoft => darkModeNotifier.value
    ? const Color(0xffa0aec0)
    : const Color(0xff4a5568);

/// 🎨 رنگ‌های اصلی
Color get accentGreen => accentNotifier.value;
Color get accentGreen2 => kAccentGold;
Color get accentBlue => kPrimaryNavySoft;
Color get accentBlue2 => kPrimaryNavyDark;
Color get gold => kAccentGold;
Color get rose => kUrgent;
Color get purple => const Color(0xff6d28d9);

/// 🎨 مرزها
Color get lineC => darkModeNotifier.value ? kDarkBorder : kLightBorder;
Color get softLine => darkModeNotifier.value
    ? const Color(0xff1c242e)
    : const Color(0xffefece5);

/// 🎨 نوار پایین
Color get navBg => darkModeNotifier.value ? kDarkCard : kLightCard;

/// 🎨 Skeleton
Color get skeletonBase =>
    darkModeNotifier.value ? kDarkCard : const Color(0xffeae7e0);
Color get skeletonHi =>
    darkModeNotifier.value ? kDarkCard2 : const Color(0xfff5f3ed);

/// 🎨 چیپ‌ها
Color get chipBg => darkModeNotifier.value
    ? kPrimaryNavy.withOpacity(0.35)
    : kAccentGold.withOpacity(0.18);
Color get chipFg =>
    darkModeNotifier.value ? kAccentGold : kPrimaryNavy;

/* ==================== MODELS ==================== */

class Cat {
  final String n;
  final String s;
  final IconData i;
  final Color c;
  const Cat(this.n, this.s, this.i, this.c);
}

const cats = <Cat>[
  Cat('رشته تربیت بدنی و علوم ورزشی', 'physical-education-sport-sciences',
      Icons.sports_soccer_rounded, kPrimaryNavy),
  Cat('علوم ورزشی', 'sports-science', Icons.science_rounded,
      Color(0xff4a148c)),
  Cat('منابع آزمون‌ها', 'sports-science-exam-resources',
      Icons.menu_book_rounded, kAccentGold),
  Cat('تغذیه ورزشی', 'sports-nutrition', Icons.restaurant_rounded,
      Color(0xff046a38)),
  Cat('اخبار و رویدادها', 'sports-news-and-events',
      Icons.newspaper_rounded, Color(0xff7b2d26)),
  Cat('ورزش همگانی', 'public-exercise-health-and-wellness',
      Icons.favorite_rounded, Color(0xff00695c)),
  Cat('پژوهش در تربیت بدنی', 'research-in-physical-education',
      Icons.search_rounded, Color(0xff003d7a)),
  Cat('تربیت بدنی و آموزش', 'physical-education-and-training',
      Icons.school_rounded, kPrimaryNavyLight),
  Cat('منابع و کتب مرجع',
      'introduction-to-sources-and-reference-books',
      Icons.library_books_rounded, Color(0xff5c4033)),
  Cat('اصول ورزش',
      'principles-of-exercise-and-physical-activity',
      Icons.fitness_center_rounded, Color(0xff8b6914)),
  Cat('آزمون‌های استخدامی', 'employment-tests',
      Icons.assignment_rounded, Color(0xff8b2d26)),
  Cat('معرفی رشته‌ها', 'introduction-to-sports-disciplines',
      Icons.sports_handball_rounded, Color(0xff1d4ed8)),
  Cat('ورزش گروه‌های ویژه',
      'exercise-for-special-groups-and-needs',
      Icons.accessibility_new_rounded, Color(0xff6d28d9)),
  Cat('تکنولوژی در ورزش', 'technology-and-innovation-in-sports',
      Icons.memory_rounded, Color(0xff0f766e)),
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
/* ==================== READING STATS ==================== */

Future<void> trackArticleRead(dynamic post, {String? fromCategory}) async {
  try {
    final id = pId(post);
    if (id.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final data = prefs.getString('read_articles') ?? '[]';
    final list = (json.decode(data) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final existingIndex = list.indexWhere((e) => e['id'] == id);
    if (existingIndex != -1) {
      list[existingIndex]['lastRead'] = now.toIso8601String();
      list[existingIndex]['readCount'] =
          ((list[existingIndex]['readCount'] as int?) ?? 1) + 1;
    } else {
      final wordCount = clean(post['content']?['rendered'] ?? '')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
      final readTime = (wordCount / 200).ceil();

      list.insert(0, {
        'id': id,
        'title': pTitle(post),
        'image': pImg(post),
        'category': fromCategory ?? pCategory(post),
        'link': pLink(post),
        'readTime': readTime < 1 ? 1 : readTime,
        'firstRead': now.toIso8601String(),
        'lastRead': now.toIso8601String(),
        'readCount': 1,
      });
    }

    if (list.length > 200) {
      list.removeRange(200, list.length);
    }

    await prefs.setString('read_articles', json.encode(list));
    readArticlesNotifier.value = list;
    await _updateReadingStats();
    await _trackReadingDay(todayKey, list.length);
  } catch (_) {}
}

Future<void> _updateReadingStats() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('read_articles') ?? '[]';
    final list = (json.decode(data) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    int totalRead = list.length;
    int weekCount = 0;
    int monthCount = 0;
    int totalReadTime = 0;
    int weekReadTime = 0;
    Map<String, int> categoryCount = {};
    Map<String, int> dailyCount = {};

    for (final item in list) {
      try {
        final lastRead = DateTime.parse(item['lastRead'] ?? '');
        final readTime = (item['readTime'] as int?) ?? 1;
        final cat = item['category']?.toString() ?? 'سایر';

        totalReadTime += readTime;

        if (lastRead.isAfter(weekAgo)) {
          weekCount++;
          weekReadTime += readTime;
        }
        if (lastRead.isAfter(monthAgo)) {
          monthCount++;
        }

        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;

        final dayKey = '${lastRead.year}-${lastRead.month}-${lastRead.day}';
        dailyCount[dayKey] = (dailyCount[dayKey] ?? 0) + 1;
      } catch (_) {}
    }

    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      if (dailyCount.containsKey(key)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    final stats = {
      'totalRead': totalRead,
      'weekCount': weekCount,
      'monthCount': monthCount,
      'totalReadTime': totalReadTime,
      'weekReadTime': weekReadTime,
      'streak': streak,
      'categoryCount': categoryCount,
      'dailyCount': dailyCount,
    };

    readingStatsNotifier.value = stats;
  } catch (_) {}
}

Future<void> _trackReadingDay(String todayKey, int count) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getStringList('reading_days') ?? [];
    if (!days.contains(todayKey)) {
      days.add(todayKey);
      if (days.length > 90) {
        days.removeRange(0, days.length - 90);
      }
      await prefs.setStringList('reading_days', days);
    }
  } catch (_) {}
}

Future<void> loadReadingStats() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('read_articles');
    if (data != null && data.isNotEmpty) {
      final list = (json.decode(data) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      readArticlesNotifier.value = list;
      await _updateReadingStats();
    }
  } catch (_) {}
}

Future<void> clearReadingStats() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('read_articles');
    await prefs.remove('reading_days');
    readArticlesNotifier.value = [];
    readingStatsNotifier.value = {};
  } catch (_) {}
}

/* ==================== NAVIGATION ==================== */

Future<void> openUrl(BuildContext context, String url,
    {String title = 'مشاهده', dynamic post}) async {
  if (url.isEmpty) return;

  // 📊 ثبت آمار مطالعه
  if (post != null) {
    trackArticleRead(post);
  }

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
      backgroundColor: error ? kUrgent : kPrimaryNavy,
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

/* ==================== PERSIAN TO FINGLISH (SLUG) ==================== */

String persianToFinglish(String input) {
  if (input.isEmpty) return '';

  String text = input
      .replaceAll('\u200c', ' ')
      .replaceAll('‌', ' ')
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک');

  const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  for (int i = 0; i < persianDigits.length; i++) {
    text = text.replaceAll(persianDigits[i], i.toString());
  }

  const replacements = {
    'آ': 'a', 'ا': 'a', 'ب': 'b', 'پ': 'p', 'ت': 't', 'ث': 's',
    'ج': 'j', 'چ': 'ch', 'ح': 'h', 'خ': 'kh', 'د': 'd', 'ذ': 'z',
    'ر': 'r', 'ز': 'z', 'ژ': 'zh', 'س': 's', 'ش': 'sh', 'ص': 's',
    'ض': 'z', 'ط': 't', 'ظ': 'z', 'ع': 'a', 'غ': 'gh', 'ف': 'f',
    'ق': 'gh', 'ک': 'k', 'گ': 'g', 'ل': 'l', 'م': 'm', 'ن': 'n',
    'و': 'v', 'ه': 'h', 'ی': 'y', 'ء': '', 'ئ': 'y', 'أ': 'a',
    'إ': 'e', 'ؤ': 'o', 'ة': 'h',
  };

  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    final ch = text[i];
    if (replacements.containsKey(ch)) {
      buffer.write(replacements[ch]);
    } else {
      buffer.write(ch);
    }
  }

  String result = buffer.toString().toLowerCase();
  result = result.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
  result = result.replaceAll(RegExp(r'\s+'), '-');
  result = result.replaceAll(RegExp(r'-+'), '-');
  result = result.trim().replaceAll(RegExp(r'^-|-$'), '');

  if (result.length > 80) {
    result = result.substring(0, 80);
    if (result.endsWith('-')) {
      result = result.substring(0, result.length - 1);
    }
  }

  return result;
}

String generateSlug(String title) {
  final slug = persianToFinglish(title);
  if (slug.isEmpty) {
    return 'news-${DateTime.now().millisecondsSinceEpoch}';
  }
  return slug;
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

Future<List> getProductsPaged(
    {int perPage = perPageSize, int page = 1}) async {
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
  final slug = generateSlug(title);

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
      'slug': slug,
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
  final slug = generateSlug(title);

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
      'slug': slug,
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
    await loadFollowedCategories();
    await loadInAppNotifications();
    await loadReadingStats();
    await loadQuiz();
    await loadQuizAnswers();
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
                    const Color(0xff10161f),
                    kPrimaryNavyDark,
                  ]
                : [
                    kLightBg,
                    const Color(0xffeef2f7),
                    kAccentGoldSoft,
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
                              kAccentGold,
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
                              color: kAccentGold.withOpacity(0.3),
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
                color: kAccentGold.withOpacity(0.3 + scale * 0.7),
              ),
            );
          }),
        );
      },
    );
  }
}
/* ==================== ROOT (WITH DEEP LINKING) ==================== */

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  int _i = 0;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  static const _pages = <Widget>[
    Home(),
    ArticlesPage(),
    NewsPage(),
    ShopPage(),
    AccountPage(),
  ];

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && mounted) {
        _handleDeepLink(initialUri);
      }

      _linkSub = _appLinks.uriLinkStream.listen(
        (uri) {
          if (mounted) _handleDeepLink(uri);
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _handleDeepLink(Uri uri) async {
    try {
      final host = uri.host.toLowerCase();
      if (!host.contains('itarbiatbadani.ir')) return;

      final pathSegments = uri.pathSegments
          .where((s) => s.isNotEmpty)
          .toList();
      if (pathSegments.isEmpty) return;

      final fullUrl = uri.toString();
      final slug = pathSegments.last;

      if (mounted) {
        showSnack(context, 'در حال باز کردن لینک...');
      }

      try {
        final url = '$api/posts?slug=${Uri.encodeComponent(slug)}'
            '&_embed=wp:featuredmedia,wp:term,author';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final list = json.decode(response.body) as List;
          if (list.isNotEmpty && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ModernWebPage(
                  url: pLink(list.first),
                  title: pTitle(list.first),
                ),
              ),
            );
            return;
          }
        }

        final newsUrl = '$api/new_news?slug=${Uri.encodeComponent(slug)}'
            '&_embed=wp:featuredmedia,wp:term,author&_fields=id,link,title,date,excerpt,content,_embedded,_links';
        final newsResponse = await http.get(Uri.parse(newsUrl));
        if (newsResponse.statusCode == 200) {
          final newsList = json.decode(newsResponse.body) as List;
          if (newsList.isNotEmpty && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    UrgentNewsDetailPage(news: newsList.first),
              ),
            );
            return;
          }
        }
      } catch (_) {}

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModernWebPage(
              url: fullUrl,
              title: 'مشاهده',
            ),
          ),
        );
      }
    } catch (_) {}
  }

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
            color: isDark ? kDarkBorder : kLightBorder,
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
              color: kAccentGold.withOpacity(0.08),
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
      color: kTabHome,
    ),
    _NavItem(
      icon: Icons.article_outlined,
      activeIcon: Icons.article_rounded,
      label: 'مقالات',
      color: kTabArticles,
    ),
    _NavItem(
      icon: Icons.newspaper_outlined,
      activeIcon: Icons.newspaper_rounded,
      label: 'اخبار',
      color: kTabNews,
    ),
    _NavItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      label: 'فروشگاه',
      color: kTabShop,
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'حساب من',
      color: kTabAccount,
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
                          Color.lerp(item.color, Colors.black, 0.15)!,
                        ],
                      )
                    : null,
                color: selected
                    ? null
                    : (isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(15),
                border: selected
                    ? Border.all(
                        color: kAccentGold.withOpacity(0.4),
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
                          color: kAccentGold.withOpacity(0.25),
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
                          : (isDark
                              ? Color.lerp(
                                  item.color, Colors.white, 0.55)!
                              : mutC),
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
                          color: kAccentGold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kAccentGold.withOpacity(0.8),
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
                    ? (isDark
                        ? Color.lerp(item.color, Colors.white, 0.35)!
                        : item.color)
                    : (isDark ? txtC.withOpacity(0.7) : mutC),
                fontSize: selected ? 12.5 : 11.5,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
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
        checkForNewNotifications();
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
                color: kAccentGold,
                size: 250,
                duration: const Duration(seconds: 10),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -100,
              child: _AnimatedBlob(
                color: kPrimaryNavySoft,
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
                      title: 'دسته‌بندی‌ها',
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
                  kAccentGold,
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
                    colors: [txtC, kAccentGold],
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
                        color: kAccentGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kAccentGold.withOpacity(0.6),
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
          // 🔔 اعلان‌ها
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
                          builder: (_) => const NotificationsPage()),
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
                            colors: [kUrgent, kUrgentDark],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: pnl, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: kUrgent.withOpacity(0.5),
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
          // 🌗 تغییر تم
          _HeaderIconButton(
            icon: Icons.brightness_6_rounded,
            onTap: () => _showThemeModePicker(context),
          ),
          const SizedBox(width: 4),
          // 🔍 جستجو
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
              ? Colors.white.withOpacity(0.10)
              : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.18)
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
        child: Icon(
          icon,
          color: color ?? (isDark ? kAccentGold : txtC),
          size: 19,
        ),
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
                  kUrgent.withOpacity(0.15),
                  kPrimaryNavyDark.withOpacity(0.3),
                ]
              : [
                  const Color(0xfffff5f5),
                  const Color(0xfff5f0e6),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kUrgent.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: kUrgent.withOpacity(0.12),
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
                colors: [kUrgent, kUrgentDark],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: kUrgent.withOpacity(0.4),
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
  final Color? color;
  const _WhiteLiveDotSmall({this.color});

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
    final dotColor = widget.color ?? Colors.white;
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
                  color: dotColor.withOpacity(opacity * 0.6),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
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
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: pnl,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: lineC),
        ),
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24 + MediaQuery.of(ctx).padding.bottom,
            ),
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
                          colors: [kPrimaryNavy, kAccentGold],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryNavy.withOpacity(0.4),
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
                  color: kAccentGold,
                  value: 'light',
                  ctx: ctx,
                ),
                const SizedBox(height: 10),
                _themeOption(
                  icon: Icons.dark_mode_rounded,
                  label: 'تاریک',
                  subtitle: 'همیشه در حالت تاریک',
                  color: kPrimaryNavy,
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
        ),
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
                width: 48,
                height: 48,
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
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: mutC,
                        fontSize: 11.5,
                        height: 1.5,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected
                      ? LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        )
                      : null,
                  border: Border.all(
                    color: selected
                        ? color
                        : mutC.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
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
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: followedCategoriesNotifier,
      builder: (context, followed, _) {
        final followedCats = cats
            .where((cat) => followed.contains(cat.s))
            .toList();

        return Container(
          margin: const EdgeInsets.only(top: 4, bottom: 6),
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: 5 + followedCats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (c, i) {
              // ❤️ دسته‌های دنبال‌شده ابتدا نمایش داده می‌شوند
              if (i < followedCats.length) {
                final cat = followedCats[i];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
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
                    showSnack(context, 'لغو دنبال کردن «${cat.n}»');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cat.c, cat.c.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: cat.c.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.i, color: Colors.white, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          cat.n.length > 18
                              ? '${cat.n.substring(0, 16)}...'
                              : cat.n,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final actionIndex = i - followedCats.length;

              // 🎯 کوئیز ورزشی
              if (actionIndex == 0) {
                return ValueListenableBuilder<List<QuizQuestion>>(
                  valueListenable: quizNotifier,
                  builder: (c, questions, __) {
                    return _actionChip(
                      icon: Icons.quiz_rounded,
                      label: 'کوئیز ورزشی',
                      color: kQuizColor,
                      badge: questions.isNotEmpty
                          ? '${questions.length}'
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const QuizPage()),
                        );
                      },
                    );
                  },
                );
              }

              // 🏋️ ماشین‌حساب BMI
              if (actionIndex == 1) {
                return _actionChip(
                  icon: Icons.calculate_rounded,
                  label: 'تناسب اندام',
                  color: kTabShop,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BMICalculatorPage()),
                    );
                  },
                );
              }

              // 📊 آمار مطالعه
              if (actionIndex == 2) {
                return ValueListenableBuilder<Map<String, dynamic>>(
                  valueListenable: readingStatsNotifier,
                  builder: (c, stats, __) {
                    final count = stats['totalRead'] ?? 0;
                    return _actionChip(
                      icon: Icons.insights_rounded,
                      label: 'آمار مطالعه',
                      color: kSuccess,
                      badge: count > 0 ? '$count' : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReadingStatsPage()),
                        );
                      },
                    );
                  },
                );
              }

              // 🔖 نشان‌شده‌ها
              if (actionIndex == 3) {
                return _actionChip(
                  icon: Icons.bookmark_rounded,
                  label: 'نشان‌شده‌ها',
                  color: kAccentGold,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BookmarksPage()),
                    );
                  },
                );
              }

              // ❤️ دسته‌های من (آخر)
              final count = followed.length;
              final hasItems = count > 0;
              final isDark = darkModeNotifier.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FollowedCategoriesPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: hasItems
                        ? const LinearGradient(
                            colors: [kPrimaryNavy, kAccentGold])
                        : null,
                    color: hasItems
                        ? null
                        : (isDark ? kDarkCard2 : kLightCard),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: hasItems
                          ? kAccentGold.withOpacity(0.6)
                          : (isDark ? kDarkBorder : kLightBorder),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasItems
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: hasItems
                            ? Colors.white
                            : (isDark ? txtC : kPrimaryNavy),
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'دسته‌های من',
                        style: TextStyle(
                          color: hasItems ? Colors.white : txtC,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      if (hasItems) ...[
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
            },
          ),
        );
      },
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: color,
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
}
/* ==================== COMPACT HERO CAROUSEL ==================== */

class HeroCarousel extends StatefulWidget {
  final Future<List>? postsFuture;
  const HeroCarousel({super.key, required this.postsFuture});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _pageCtrl = PageController(viewportFraction: 0.92);
  Timer? _timer;
  Timer? _progressTimer;
  int _current = 0;
  int _count = 0;
  double _autoProgress = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _progressTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startAuto(int count) {
    _timer?.cancel();
    _progressTimer?.cancel();
    if (count <= 1) return;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _autoProgress += 0.01;
        if (_autoProgress >= 1.0) _autoProgress = 0;
      });
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final next = (_current + 1) % count;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _autoProgress = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: widget.postsFuture,
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return Container(
            height: 260,
            margin: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            decoration: BoxDecoration(
              color: pnl,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: lineC),
            ),
            child: const ShimmerBox(height: 260, radius: 22),
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
          margin: const EdgeInsets.only(top: 14, bottom: 6),
          child: Column(
            children: [
              SizedBox(
                height: 260,
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: (i) {
                    setState(() {
                      _current = i;
                      _autoProgress = 0;
                    });
                  },
                  itemCount: posts.length,
                  itemBuilder: (c, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _CarouselCard(
                      post: posts[i],
                      isActive: i == _current,
                    ),
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
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _pageCtrl.animateToPage(
              i,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 30 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: active
                  ? kAccentGold
                  : mutC.withOpacity(0.25),
              borderRadius: BorderRadius.circular(999),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: kAccentGold.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: active
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: _autoProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.9),
                                  kAccentGoldLight,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }
}

/* ==================== COMPACT CAROUSEL CARD ==================== */

class _CarouselCard extends StatefulWidget {
  final dynamic post;
  final bool isActive;
  const _CarouselCard({
    required this.post,
    this.isActive = false,
  });

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
      duration: const Duration(seconds: 10),
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
    final excerpt = pExcerpt(widget.post, maxChars: 70);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        openUrl(context, link, post: widget.post);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 400),
        scale: widget.isActive ? 1.0 : 0.95,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: widget.isActive ? 1.0 : 0.7,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                      widget.isActive ? 0.30 : 0.12),
                  blurRadius: widget.isActive ? 30 : 18,
                  offset: Offset(0, widget.isActive ? 12 : 6),
                ),
                if (widget.isActive)
                  BoxShadow(
                    color: kAccentGold.withOpacity(0.12),
                    blurRadius: 40,
                    spreadRadius: -8,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
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
                                const Duration(milliseconds: 500),
                            fadeOutDuration:
                                const Duration(milliseconds: 250),
                            placeholder: (_, __) =>
                                Container(color: pnl2),
                            errorWidget: (_, __, ___) => Container(
                              color: pnl2,
                              child: Icon(Icons.article_rounded,
                                  color: accentNotifier.value,
                                  size: 60),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [kPrimaryNavy, kPrimaryNavyDark],
                        ),
                      ),
                      child: Icon(Icons.article_rounded,
                          color: Colors.white.withOpacity(0.3),
                          size: 60),
                    ),

                  // Cinematic gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.95),
                        ],
                        stops: const [0.0, 0.35, 0.6, 1.0],
                      ),
                    ),
                  ),

                  // Gold accent bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kPrimaryNavy,
                            kAccentGold,
                            kAccentGoldLight,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top row
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 14,
                    child: Row(
                      children: [
                        if (cat.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    kAccentGold.withOpacity(0.95),
                                    kAccentGoldDark.withOpacity(0.95),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: kAccentGold.withOpacity(0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white
                                              .withOpacity(0.8),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
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
                                ],
                              ),
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
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
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom content
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.5,
                            fontFamily: 'Vazirmatn',
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 12,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        if (excerpt.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            excerpt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 11,
                              fontFamily: 'Vazirmatn',
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    kAccentGold,
                                    kAccentGoldDark,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: kAccentGold
                                        .withOpacity(0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'مطالعه کامل',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                    size: 13,
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
        ),
      ),
    );
  }
}

/* ==================== MODERN HERO BANNER ==================== */

class ModernHeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: lineC),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
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
        final isDark = darkModeNotifier.value;

        return Container(
          margin: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    // Red vertical bar
                    Container(
                      width: 4,
                      height: 26,
                      decoration: BoxDecoration(
                        color: kNewsRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Live dot
                    const ModernLiveDot(),
                    const SizedBox(width: 8),
                    // Title
                    Text(
                      'اخبار فوری',
                      style: TextStyle(
                        color: txtC,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // News Cards
              ...items
                  .map((news) => ModernUrgentNewsCard(news: news))
                  .toList(),

              // View all button
              if (list.length > 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
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
                            horizontal: 20, vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark
                              ? kNewsRed.withOpacity(0.15)
                              : kNewsRed.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: kNewsRed.withOpacity(0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مشاهده همه اخبار فوری',
                              style: TextStyle(
                                color: kNewsRed,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_back_ios_new_rounded,
                                color: kNewsRed, size: 11),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
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
      'color': kPrimaryNavy,
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
      'color': kAccentGold,
      'url': '$site/manabe-konkur-doctori-tarbiat-badani/',
    },
    {
      'title': 'منابع استخدامی',
      'icon': Icons.assignment_rounded,
      'color': kUrgent,
      'url': '$site/employment-tests/',
    },
    {
      'title': 'دانشگاه‌های برتر',
      'icon': Icons.account_balance_rounded,
      'color': kPrimaryNavySoft,
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
      'color': const Color(0xff5c4033),
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
                      colors: [kPrimaryNavy, kAccentGold],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.auto_awesome_rounded,
                    color: kAccentGold, size: 20),
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
    final isDark = darkModeNotifier.value;
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
                color: isDark
                    ? color.withOpacity(0.28)
                    : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: isDark
                    ? Border.all(
                        color: color.withOpacity(0.55),
                        width: 1.2,
                      )
                    : null,
              ),
              child: Icon(
                item['icon'] as IconData,
                color: isDark
                    ? Color.lerp(color, Colors.white, 0.55)!
                    : color,
                size: 24,
              ),
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
      onTap: () => openUrl(context, link, post: post),
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
                  ? [kDarkCard, kDarkCard2]
                  : [Colors.white, kLightCard2],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed
                  ? kAccentGold.withOpacity(0.6)
                  : (isDark ? kDarkBorder.withOpacity(0.5) : lineC),
              width: _pressed ? 1.5 : 1,
            ),
            boxShadow: [
              if (_pressed)
                BoxShadow(
                  color: kAccentGold.withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: -3,
                ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
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
                          kAccentGold.withOpacity(
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
                                        color: chipBg,
                                        borderRadius:
                                            BorderRadius.circular(7),
                                        border: Border.all(
                                          color: chipFg
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
                                              color: chipFg,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              cat,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              softWrap: false,
                                              style: TextStyle(
                                                color: chipFg,
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
                                              ? kAccentGold
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
                                              ? kAccentGold
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
    final isDark = darkModeNotifier.value;

    return GestureDetector(
      onTap: () => openUrl(context, link, post: post),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [kDarkCard, kDarkCard2]
                : [Colors.white, kLightCard2],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? kDarkBorder.withOpacity(0.5) : lineC,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
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
                                    ? kAccentGold
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
                    Container(
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
                              maxLines: 2,
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
                          color: kAccentGold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مطالعه',
                              style: TextStyle(
                                color: kAccentGoldDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_back_rounded,
                                color: kAccentGoldDark, size: 12),
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
      onTap: () => openUrl(context, link, post: post),
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
                        Flexible(
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
                                    softWrap: false,
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
                                    ? kAccentGold.withOpacity(0.15)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                set.contains(id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: set.contains(id)
                                    ? kAccentGold
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
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: darkModeNotifier.value
                ? [kDarkCard, kDarkCard2]
                : [Colors.white, kLightCard2],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: darkModeNotifier.value
                ? kDarkBorder.withOpacity(0.5)
                : lineC,
          ),
          boxShadow: [
            BoxShadow(
              color: kAccentGold.withOpacity(
                  darkModeNotifier.value ? 0.10 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(
                  darkModeNotifier.value ? 0.3 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
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
                            gradient: const LinearGradient(
                              colors: [kUrgent, kUrgentDark],
                            ),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: kUrgent.withOpacity(0.5),
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
                              ? kSuccess
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
                                  ? kAccentGold.withOpacity(0.15)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              set.contains(pId(p))
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: set.contains(pId(p))
                                  ? kAccentGold
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
                        color: kSuccess,
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
                      color: kAccentGold
                          .withOpacity(inStock ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kAccentGold
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
                          color: kAccentGold
                              .withOpacity(inStock ? 1 : 0.5),
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          inStock ? 'خرید' : 'مشاهده',
                          style: TextStyle(
                            color: kAccentGold
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
                              color: darkModeNotifier.value
                                  ? cat.c.withOpacity(0.28)
                                  : cat.c.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: darkModeNotifier.value
                                  ? Border.all(
                                      color: cat.c.withOpacity(0.55),
                                      width: 1.2,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              cat.i,
                              color: darkModeNotifier.value
                                  ? Color.lerp(
                                      cat.c, Colors.white, 0.55)!
                                  : cat.c,
                              size: 22,
                            ),
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
                                  border:
                                      Border.all(color: pnl, width: 1.5),
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

/* ==================== ALL CATEGORIES PAGE ==================== */

class AllCategoriesPage extends StatelessWidget {
  const AllCategoriesPage({super.key});

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
                    colors: [kPrimaryNavy, kAccentGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryNavy.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.grid_view_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'همه دسته‌بندی‌ها',
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
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          child: const ModernCatGrid(),
        ),
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
        kAccentGold
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
                    colors: [kPrimaryNavy, kAccentGold],
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
                  colors: [kPrimaryNavy, kAccentGold],
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
                  color: kNewsRed.withOpacity(opacity * 0.5),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kNewsRed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
/* ==================== PROFESSIONAL URGENT NEWS CARD ==================== */

class ModernUrgentNewsCard extends StatefulWidget {
  final dynamic news;
  final bool compact;
  const ModernUrgentNewsCard({
    super.key,
    required this.news,
    this.compact = false,
  });

  @override
  State<ModernUrgentNewsCard> createState() => _ModernUrgentNewsCardState();
}

class _ModernUrgentNewsCardState extends State<ModernUrgentNewsCard> {
  bool _pressed = false;

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

  bool _isFresh(dynamic news) {
    try {
      final d = DateTime.parse(news['date']).toLocal();
      final diff = DateTime.now().difference(d);
      return diff.inHours < 6;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.news;
    final title = pTitle(news);
    final date = pTimeAgo(news);
    final excerpt = pExcerpt(news, maxChars: 130);
    final readTime = _readTimeMinutes(news);
    final isFresh = _isFresh(news);
    final isDark = darkModeNotifier.value;
    final id = pId(news);
    final img = pImg(news);
    final cat = pCategory(news);

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
          color: isDark ? kDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed
                ? kNewsRed.withOpacity(0.5)
                : (isDark
                    ? kDarkBorder.withOpacity(0.6)
                    : const Color(0xffe5e7eb)),
            width: _pressed ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
              blurRadius: _pressed ? 24 : 16,
              offset: const Offset(0, 4),
            ),
            if (isFresh)
              BoxShadow(
                color: kNewsRed.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Red breaking bar at top
              Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kNewsRed, kNewsRedDark],
                  ),
                ),
              ),

              // Image
              if (img.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        memCacheWidth: 1080,
                        memCacheHeight: 620,
                        maxWidthDiskCache: 1080,
                        maxHeightDiskCache: 620,
                        placeholder: (_, __) => Container(
                          color: isDark ? kDarkCard2 : kLightCard2,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: isDark ? kDarkCard2 : kLightCard2,
                          child: Icon(Icons.newspaper_rounded,
                              color: mutC, size: 40),
                        ),
                      ),
                      // Bottom gradient for readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 70,
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

                      // "Breaking News" badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: kNewsRed,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: kNewsRed.withOpacity(0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _WhiteLiveDotSmall(color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'فوری',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Category badge (if exists)
                      if (cat.isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ),

                      // Time badge (bottom-right)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  color: Colors.white70, size: 10),
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

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: txtC,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.65,
                        fontFamily: 'Vazirmatn',
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Excerpt
                    if (excerpt.isNotEmpty)
                      Text(
                        excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: mutC,
                          fontSize: 12,
                          height: 1.7,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Divider
                    Container(
                      height: 1,
                      color: isDark
                          ? kDarkBorder.withOpacity(0.5)
                          : const Color(0xfff1f5f9),
                    ),
                    const SizedBox(height: 10),

                    // Bottom meta row
                    Row(
                      children: [
                        // Read time
                        Icon(Icons.access_time_rounded,
                            color: mutC, size: 13),
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

                        // Share button
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
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xfff3f4f6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.ios_share_rounded,
                                color: mutC, size: 14),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Bookmark button
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
                            builder: (c, set, __) {
                              final saved = set.contains(id);
                              return Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: saved
                                      ? kAccentGold.withOpacity(0.15)
                                      : (isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : const Color(0xfff3f4f6)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  saved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  color: saved ? kAccentGold : mutC,
                                  size: 14,
                                ),
                              );
                            },
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
                                kPrimaryNavy,
                                kAccentGold,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.favorite_rounded,
                            color: kUrgent,
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
                              color: kPrimaryNavy
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'مدیریت',
                              style: TextStyle(
                                color: kPrimaryNavy,
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
                              color: kPrimaryNavyLight,
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
                                          color: kPrimaryNavyLight,
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
                  colors: [kPrimaryNavy, kPrimaryNavyLight],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryNavy.withOpacity(0.4),
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
/* ==================== PREMIUM NEWS PAGE ==================== */

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
      'color': kSuccess,
    },
    {
      'key': 'week',
      'label': 'این هفته',
      'icon': Icons.date_range_rounded,
      'color': kPrimaryNavyLight,
    },
    {
      'key': 'month',
      'label': 'این ماه',
      'icon': Icons.calendar_month_rounded,
      'color': Color(0xff6d28d9),
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
                              color: kUrgent,
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
                                            color: kUrgent),
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
                    kUrgent,
                    kUrgent.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kUrgent.withOpacity(0.4),
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
              child: Row(
                children: [
                  Text(
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
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: kUrgent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kUrgent.withOpacity(0.7),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
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
                      kPrimaryNavy,
                      kPrimaryNavy.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryNavy.withOpacity(0.4),
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
      onTap: () => openUrl(context, link, post: post),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark
                ? [
                    kUrgent.withOpacity(0.15),
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
                ? kUrgent.withOpacity(0.6)
                : lineC,
            width: _pressed ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _pressed
                  ? kUrgent.withOpacity(0.2)
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
                                color: kUrgent.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: pnl2,
                          child: Icon(Icons.newspaper_rounded,
                              color: kUrgent,
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
                                  kUrgent,
                                  kUrgent.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: kUrgent.withOpacity(0.5),
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
                                kUrgent,
                                kUrgent.withOpacity(0.8),
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
                          color: kUrgent.withOpacity(0.6),
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
                      color: isDark
                          ? kUrgent.withOpacity(0.22)
                          : kUrgent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: isDark
                          ? Border.all(
                              color: kUrgent.withOpacity(0.45),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 6, color: kUrgent),
                        const SizedBox(width: 6),
                        Text(
                          'مشاهده خبر',
                          style: TextStyle(
                            color: isDark ? Colors.white : kUrgent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_back_ios_new_rounded,
                            color: isDark ? Colors.white : kUrgent,
                            size: 10),
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
                              color: kAccentGold,
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
                                            color: kAccentGold),
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
                    kAccentGold,
                    kAccentGoldDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kAccentGold.withOpacity(0.4),
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
            GestureDetector(
              onTap: () => openUrl(context, '$site/cart/',
                  title: 'سبد خرید'),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kAccentGold.withOpacity(0.15),
                      kAccentGold.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: kAccentGold.withOpacity(0.3),
                  ),
                ),
                child: const Icon(Icons.shopping_cart_rounded,
                    color: kAccentGold, size: 20),
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
                        kAccentGold,
                        kAccentGoldDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kAccentGold.withOpacity(0.4),
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
                        kPrimaryNavy,
                        kPrimaryNavy.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryNavy.withOpacity(0.4),
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
            color: kPrimaryNavy,
            title: 'هنوز مقاله‌ای نشان نکرده‌اید',
            subtitle:
                'با زدن آیکون نشان روی کارت مقالات، اینجا ذخیره می‌شوند',
          );
        }
        return RefreshIndicator(
          color: kPrimaryNavy,
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
            color: kAccentGold,
            title: 'هنوز محصولی نشان نکرده‌اید',
            subtitle:
                'با زدن آیکون نشان روی کارت محصولات، اینجا ذخیره می‌شوند',
          );
        }
        return RefreshIndicator(
          color: kAccentGold,
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
                                kPrimaryNavy,
                                kPrimaryNavy.withOpacity(0.7),
                              ],
                            )
                          : null,
                      color: selected ? null : pnl,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? kPrimaryNavy
                            : lineC,
                        width: 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: kPrimaryNavy
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
                            kAccentGold,
                            kAccentGoldDark,
                          ],
                        )
                      : null,
                  color: _selectedCategory != null ? null : pnl,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedCategory != null
                        ? kAccentGold
                        : lineC,
                    width: 1,
                  ),
                  boxShadow: _selectedCategory != null
                      ? [
                          BoxShadow(
                            color: kAccentGold
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
                              size: 10, color: kAccentGold),
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
                    colors: [kAccentGold, kAccentGoldDark],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: kAccentGold.withOpacity(0.3),
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
                          kAccentGold,
                          kAccentGoldDark,
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
                      color: kPrimaryNavy,
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
                    color: kTabAccount,
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
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      kTabAccount,
                                      kPrimaryNavy,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kTabAccount
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
                              SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: kTabAccount,
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
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
                    kTabAccount,
                    kPrimaryNavy,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kTabAccount.withOpacity(0.4),
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
                      kAccentGold.withOpacity(0.15),
                      kAccentGold.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: kAccentGold.withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: kAccentGold,
                  size: 20,
                ),
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

/* ==================== URGENT NEWS DETAIL PAGE (Blue Theme) ==================== */

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
                          _WhiteLiveDotSmall(color: kUrgent),
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
                    Expanded(
                      child: _infoChip(
                        icon: Icons.calendar_today_rounded,
                        label: date,
                        color: const Color(0xff0ea5e9),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _infoChip(
                        icon: Icons.access_time_rounded,
                        label: '$readTime دقیقه',
                        color: const Color(0xff38bdf8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _infoChip(
                        icon: Icons.text_fields_rounded,
                        label: '$words کلمه',
                        color: const Color(0xff0284c7),
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

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = darkModeNotifier.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? color.withOpacity(0.15)
            : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.30 : 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: isDark ? color.withOpacity(0.95) : color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'Vazirmatn',
              ),
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
                      kPrimaryNavy,
                      kPrimaryNavyLight,
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
    final isDark = darkModeNotifier.value;

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: kNewsRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const ModernLiveDot(),
              const SizedBox(width: 8),
              Text(
                'اخبار فوری',
                style: TextStyle(
                  color: txtC,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
        ),
        body: RefreshIndicator(
          color: kNewsRed,
          backgroundColor: isDark ? kDarkCard : Colors.white,
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
                return const EmptyWidget(
                    text: 'هنوز خبری منتشر نشده است.');
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
                itemBuilder: (c, i) => ModernUrgentNewsCard(
                  news: list[i],
                ),
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
                      kAccentGold.withOpacity(0.2),
                      kAccentGold.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: kAccentGold.withOpacity(0.3)),
                ),
                child: Icon(Icons.lock_rounded,
                    color: kAccentGold, size: 42),
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
                'برای مدیریت اخبار و کوئیز وارد شوید',
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
                  color: kPrimaryNavy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: kPrimaryNavy.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_rounded,
                        color: kPrimaryNavy, size: 18),
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

  PlatformFile? _selectedFile;
  bool _uploadingFile = false;
  String? _uploadedFileUrl;
  String? _uploadedFileName;
  String? _uploadedMediaId;

  // Quiz design variables
  final _quizQuestionCtrl = TextEditingController();
  final _quizExplanationCtrl = TextEditingController();
  final _quizOptionsCtrls =
      List.generate(4, (_) => TextEditingController());
  int _quizCorrectIndex = 0;

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

  String _getSlugPreview() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return '';
    return generateSlug(title);
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
      if (file.size > 30 * 1024 * 1024) {
        showSnack(context, 'حجم فایل نباید بیش از ۳۰ مگابایت باشد.',
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
              '\n\n<p style="margin-top:20px; padding:12px; background:#f5f0e6; border-radius:10px; text-align:center;"><a href="$_uploadedFileUrl" target="_blank" style="color:#1a2b47; font-weight:bold; text-decoration:none; font-size:15px;">$icon دانلود فایل: $_uploadedFileName</a></p>';
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

  Future<void> _addQuizQuestion() async {
    final question = _quizQuestionCtrl.text.trim();
    final options = _quizOptionsCtrls.map((c) => c.text.trim()).toList();

    if (question.isEmpty) {
      showSnack(context, 'متن سوال را وارد کنید.', error: true);
      return;
    }
    for (int i = 0; i < options.length; i++) {
      if (options[i].isEmpty) {
        showSnack(context, 'گزینه ${i + 1} را وارد کنید.', error: true);
        return;
      }
    }

    final q = QuizQuestion(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      question: question,
      options: options,
      correctIndex: _quizCorrectIndex,
      explanation: _quizExplanationCtrl.text.trim().isEmpty
          ? null
          : _quizExplanationCtrl.text.trim(),
    );

    await addQuizQuestion(q);

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    showSnack(context, '✅ سوال با موفقیت اضافه شد!');

    setState(() {
      _quizQuestionCtrl.clear();
      _quizExplanationCtrl.clear();
      for (final c in _quizOptionsCtrls) {
        c.clear();
      }
      _quizCorrectIndex = 0;
    });
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
                              color: kPrimaryNavyLight
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.edit_rounded,
                                color: kPrimaryNavyLight, size: 20),
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
                                backgroundColor: kPrimaryNavyLight,
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
    _quizQuestionCtrl.dispose();
    _quizExplanationCtrl.dispose();
    for (final c in _quizOptionsCtrls) {
      c.dispose();
    }
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
      return kSuccess;
    }
    if (ext == 'pdf') return kUrgent;
    if (['doc', 'docx'].contains(ext)) return const Color(0xff2b579a);
    if (['xls', 'xlsx'].contains(ext)) return const Color(0xff217346);
    if (['ppt', 'pptx'].contains(ext)) return const Color(0xffd24726);
    if (['zip', 'rar', '7z'].contains(ext)) {
      return kAccentGold;
    }
    if (['mp4', 'avi', 'mov', 'mkv'].contains(ext)) {
      return const Color(0xff6d28d9);
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
            'پنل مدیریت',
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
              // ========== بخش اخبار فوری ==========
              _sectionBanner(
                icon: Icons.newspaper_rounded,
                title: 'انتشار خبر فوری',
                subtitle:
                    'خبر جدید با فایل ضمیمه حداکثر ۳۰ مگابایت',
                color: kPrimaryNavy,
              ),
              const SizedBox(height: 18),
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
                  onChanged: (v) => setState(() {}),
                  style: TextStyle(
                      color: txtC,
                      fontSize: 14,
                      fontFamily: 'Vazirmatn'),
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
              if (_titleCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kPrimaryNavy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: kPrimaryNavy.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link_rounded,
                          color: kPrimaryNavy, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$site/new-news/${_getSlugPreview()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: kPrimaryNavy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    backgroundColor: kPrimaryNavyLight,
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
              const SizedBox(height: 20),

              // ========== بخش طراحی کوئیز ==========
              _sectionBanner(
                icon: Icons.quiz_rounded,
                title: 'طراحی کوئیز ورزشی',
                subtitle:
                    'سوال چهارگزینه‌ای بساز، پاسخ درست و توضیحات آموزشی رو مشخص کن',
                color: kQuizColor,
              ),
              const SizedBox(height: 18),
              Text(
                'متن سوال',
                style: TextStyle(
                  color: kQuizColor,
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
                  controller: _quizQuestionCtrl,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  style: TextStyle(
                    color: txtC,
                    fontSize: 13.5,
                    height: 1.7,
                    fontFamily: 'Vazirmatn',
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'مثلاً: کدام ماده معدنی برای سلامت استخوان ضروری است؟',
                    hintStyle: TextStyle(
                        color: mutC, fontFamily: 'Vazirmatn'),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'گزینه‌ها (روی حرف گزینه بزن تا به‌عنوان پاسخ صحیح انتخاب شود)',
                style: TextStyle(
                  color: kQuizColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(4, (i) {
                final isCorrect = _quizCorrectIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? kSuccess.withOpacity(0.08)
                          : pnl,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCorrect ? kSuccess : lineC,
                        width: isCorrect ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _quizCorrectIndex = i);
                          },
                          child: Container(
                            width: 52,
                            height: 62,
                            decoration: BoxDecoration(
                              gradient: isCorrect
                                  ? const LinearGradient(
                                      colors: [
                                        kSuccess,
                                        kSuccessLight
                                      ])
                                  : null,
                              color: isCorrect
                                  ? null
                                  : (darkModeNotifier.value
                                      ? kDarkCard2
                                      : kLightCard2),
                              borderRadius:
                                  const BorderRadius.horizontal(
                                      right: Radius.circular(13)),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    ['الف', 'ب', 'پ', 'ت'][i],
                                    style: TextStyle(
                                      color: isCorrect
                                          ? Colors.white
                                          : txtC,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  if (isCorrect) ...[
                                    const SizedBox(height: 2),
                                    const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 12),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _quizOptionsCtrls[i],
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: txtC,
                              fontSize: 13,
                              fontFamily: 'Vazirmatn',
                            ),
                            decoration: InputDecoration(
                              hintText: 'گزینه ${i + 1}',
                              hintStyle: TextStyle(
                                  color: mutC,
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kSuccess.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: kSuccess, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'پاسخ صحیح انتخاب‌شده: گزینه «${['الف', 'ب', 'پ', 'ت'][_quizCorrectIndex]}»',
                        style: TextStyle(
                          color: kSuccess,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kInfo.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kInfo.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: kInfo, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'توضیحات آموزشی بعد از پاسخ کاربر (چه درست چه اشتباه) نمایش داده می‌شود.',
                        style: TextStyle(
                          color: kInfo,
                          fontSize: 10.5,
                          height: 1.6,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'توضیحات آموزشی (توصیه‌شده)',
                style: TextStyle(
                  color: kQuizColor,
                  fontSize: 13,
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
                  controller: _quizExplanationCtrl,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  style: TextStyle(
                    color: txtC,
                    fontSize: 13,
                    height: 1.7,
                    fontFamily: 'Vazirmatn',
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'مثلاً: کلسیم نقش کلیدی در استحکام استخوان‌ها دارد. منابع خوب کلسیم شامل شیر، ماست، پنیر و سبزیجات برگ سبز است.',
                    hintStyle: TextStyle(
                        color: mutC,
                        fontFamily: 'Vazirmatn',
                        fontSize: 12),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _addQuizQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kQuizColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'افزودن سوال به کوئیز',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ========== لیست سوالات کوئیز ==========
              ValueListenableBuilder<List<QuizQuestion>>(
                valueListenable: quizNotifier,
                builder: (c, questions, __) {
                  if (questions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: pnl2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: lineC),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.quiz_outlined,
                              color: mutC, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'هنوز سوالی اضافه نشده است',
                              style: TextStyle(
                                color: mutC,
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list_alt_rounded,
                              color: kQuizColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'سوالات کوئیز (${questions.length})',
                            style: TextStyle(
                              color: txtC,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...questions.map((q) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: pnl,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: lineC),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          kSuccess.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'پاسخ: ${['الف', 'ب', 'پ', 'ت'][q.correctIndex % 4]}',
                                      style: TextStyle(
                                        color: kSuccess,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () async {
                                      final confirm =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: pnl,
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    20),
                                          ),
                                          title: Text(
                                            'حذف سوال',
                                            style: TextStyle(
                                              color: txtC,
                                              fontWeight:
                                                  FontWeight.w900,
                                              fontFamily:
                                                  'Vazirmatn',
                                            ),
                                          ),
                                          content: Text(
                                            'آیا این سوال حذف شود؟',
                                            style: TextStyle(
                                                color: mutC,
                                                fontFamily:
                                                    'Vazirmatn'),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      ctx, false),
                                              child: Text('انصراف',
                                                  style: TextStyle(
                                                      color: mutC,
                                                      fontFamily:
                                                          'Vazirmatn')),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      ctx, true),
                                              child: Text('حذف',
                                                  style: TextStyle(
                                                      color: rose,
                                                      fontWeight:
                                                          FontWeight
                                                              .w900,
                                                      fontFamily:
                                                          'Vazirmatn')),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await removeQuizQuestion(
                                            q.id);
                                        if (mounted) {
                                          showSnack(context,
                                              'سوال حذف شد');
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding:
                                          const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons
                                            .delete_outline_rounded,
                                        color: rose,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                q.question,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: txtC,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.6,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              if (q.explanation != null &&
                                  q.explanation!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.lightbulb_rounded,
                                        color: kInfo, size: 12),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        q.explanation!,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: mutC,
                                          fontSize: 10.5,
                                          fontFamily: 'Vazirmatn',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
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
                                color: kPrimaryNavyLight,
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

  Widget _sectionBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: color.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
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
                    kPrimaryNavy.withOpacity(0.25),
                    kPrimaryNavy.withOpacity(0.1),
                  ]
                : [
                    kAccentGold.withOpacity(0.15),
                    kAccentGold.withOpacity(0.05),
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
              'PDF، تصویر، ویدیو، Word، Excel، ZIP و...\nحداکثر ۳۰ مگابایت',
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
                          color: kSuccess.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: kSuccess, size: 10),
                            SizedBox(width: 3),
                            Text(
                              'آپلود شده',
                              style: TextStyle(
                                color: kSuccess,
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
                        colors: [kSuccess, kSuccessLight],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kSuccess.withOpacity(0.4),
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
                            color: kUrgent,
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
                        color: kSuccess,
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
                    kSuccess.withOpacity(0.10),
                    kSuccess.withOpacity(0.02),
                  ],
                )
              : null,
          color: isRead ? pnl : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !isRead
                ? kSuccess.withOpacity(0.35)
                : lineC,
            width: !isRead ? 1.5 : 1,
          ),
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
                        color: kUrgent,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgC, width: 2),
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
                    kSuccess.withOpacity(0.15),
                    kSuccess.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kSuccess.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                color: kSuccess,
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
          final followedCats = cats
              .where((cat) => followed.contains(cat.s))
              .toList();

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
                        colors: [kPrimaryNavy, kAccentGold],
                      ),
                      borderRadius: BorderRadius.circular(12),
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
            body: followedCats.isEmpty
                ? _buildEmptyState(context)
                : Column(
                    children: [
                      Container(
                        margin:
                            const EdgeInsets.fromLTRB(14, 8, 14, 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimaryNavy.withOpacity(0.12),
                              kAccentGold.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: kPrimaryNavy.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kPrimaryNavy, kAccentGold],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.white,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${followed.length} دسته‌بندی دنبال می‌شود',
                                style: TextStyle(
                                  color: txtC,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AllCategoriesPage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kPrimaryNavy
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded,
                                        color: kPrimaryNavy, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'افزودن',
                                      style: TextStyle(
                                        color: kPrimaryNavy,
                                        fontSize: 11,
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
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(14, 0, 14, 100),
                          itemCount: followedCats.length,
                          itemBuilder: (c, i) {
                            final cat = followedCats[i];
                            return _categoryCard(cat);
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

  Widget _categoryCard(Cat cat) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryPostsPage(c: cat),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              cat.c.withOpacity(0.15),
              cat.c.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cat.c.withOpacity(0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: cat.c.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cat.c, cat.c.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: cat.c.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(cat.i, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cat.n,
                style: TextStyle(
                  color: txtC,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1.5,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                toggleFollowCategory(cat.s);
                showSnack(context, 'لغو دنبال کردن «${cat.n}»');
              },
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
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                    kAccentGold.withOpacity(0.15),
                    kAccentGold.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kAccentGold.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: kAccentGold,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'هنوز دسته‌ای دنبال نمی‌کنید',
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'با زدن دکمه زیر، از لیست دسته‌ها آن‌هایی که\nموردعلاقه‌تان است را دنبال کنید',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutC,
                fontSize: 12,
                height: 1.7,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AllCategoriesPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryNavy, kAccentGold],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryNavy.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'انتخاب دسته‌بندی',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
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
/* ==================== BMI CALCULATOR PAGE ==================== */

class BMICalculatorPage extends StatefulWidget {
  const BMICalculatorPage({super.key});
  @override
  State<BMICalculatorPage> createState() => _BMICalculatorPageState();
}

class _BMICalculatorPageState extends State<BMICalculatorPage> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'moderate';

  double? _bmi;
  String _bmiCategory = '';
  Color _bmiColor = kSuccess;
  int? _bmr;
  int? _tdee;
  int? _idealWeightMin;
  int? _idealWeightMax;
  bool _hasCalculated = false;

  final List<Map<String, dynamic>> _activityLevels = [
    {'key': 'sedentary', 'label': 'کم‌تحرک', 'mult': 1.2, 'desc': 'بدون ورزش'},
    {'key': 'light', 'label': 'سبک', 'mult': 1.375, 'desc': '۱-۳ روز در هفته'},
    {'key': 'moderate', 'label': 'متوسط', 'mult': 1.55, 'desc': '۳-۵ روز در هفته'},
    {'key': 'active', 'label': 'فعال', 'mult': 1.725, 'desc': '۶-۷ روز در هفته'},
    {'key': 'veryActive', 'label': 'خیلی فعال', 'mult': 1.9, 'desc': 'ورزشکار حرفه‌ای'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _heightCtrl.text = prefs.getString('bmi_height') ?? '';
      _weightCtrl.text = prefs.getString('bmi_weight') ?? '';
      _ageCtrl.text = prefs.getString('bmi_age') ?? '';
      _gender = prefs.getString('bmi_gender') ?? 'male';
      _activityLevel = prefs.getString('bmi_activity') ?? 'moderate';
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bmi_height', _heightCtrl.text);
      await prefs.setString('bmi_weight', _weightCtrl.text);
      await prefs.setString('bmi_age', _ageCtrl.text);
      await prefs.setString('bmi_gender', _gender);
      await prefs.setString('bmi_activity', _activityLevel);
    } catch (_) {}
  }

  void _calculate({bool fromButton = false}) {
    final height = double.tryParse(_heightCtrl.text) ?? 0;
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    final age = int.tryParse(_ageCtrl.text) ?? 0;

    if (height < 50 || weight < 10 || age < 5) {
      setState(() {
        _bmi = null;
        _bmr = null;
        _tdee = null;
        _hasCalculated = false;
      });
      return;
    }

    if (fromButton) {
      setState(() => _hasCalculated = true);
    } else if (!_hasCalculated) {
      return;
    }

    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);

    String category;
    Color color;
    if (bmi < 18.5) {
      category = 'کم‌وزن';
      color = const Color(0xff3b82f6);
    } else if (bmi < 25) {
      category = 'وزن نرمال';
      color = kSuccess;
    } else if (bmi < 30) {
      category = 'اضافه وزن';
      color = kWarning;
    } else if (bmi < 35) {
      category = 'چاقی درجه ۱';
      color = const Color(0xffea580c);
    } else if (bmi < 40) {
      category = 'چاقی درجه ۲';
      color = kUrgent;
    } else {
      category = 'چاقی مفرط';
      color = kUrgentDark;
    }

    int bmr;
    if (_gender == 'male') {
      bmr = (10 * weight + 6.25 * height - 5 * age + 5).round();
    } else {
      bmr = (10 * weight + 6.25 * height - 5 * age - 161).round();
    }

    final mult = _activityLevels.firstWhere(
      (a) => a['key'] == _activityLevel,
      orElse: () => _activityLevels[2],
    )['mult'] as double;
    final tdee = (bmr * mult).round();

    final idealMin = (18.5 * heightM * heightM).round();
    final idealMax = (24.9 * heightM * heightM).round();

    setState(() {
      _bmi = bmi;
      _bmiCategory = category;
      _bmiColor = color;
      _bmr = bmr;
      _tdee = tdee;
      _idealWeightMin = idealMin;
      _idealWeightMax = idealMax;
    });

    _save();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
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
                    colors: [kTabShop, kAccentGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kTabShop.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.calculate_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'ماشین‌حساب تناسب اندام',
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
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputSection(),
              const SizedBox(height: 16),
              if (_hasCalculated && _bmi != null) ...[
                _buildBMIResult(),
                const SizedBox(height: 14),
                _buildCalorieResult(),
                const SizedBox(height: 14),
                _buildIdealWeight(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader('اطلاعات شما', Icons.person_rounded),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _genderBtn(
                  label: 'آقا',
                  icon: Icons.male_rounded,
                  value: 'male',
                  color: const Color(0xff2563eb),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _genderBtn(
                  label: 'خانم',
                  icon: Icons.female_rounded,
                  value: 'female',
                  color: const Color(0xffec4899),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _inputField(
                  controller: _heightCtrl,
                  label: 'قد',
                  suffix: 'cm',
                  icon: Icons.straighten_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inputField(
                  controller: _weightCtrl,
                  label: 'وزن',
                  suffix: 'kg',
                  icon: Icons.monitor_weight_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _inputField(
            controller: _ageCtrl,
            label: 'سن',
            suffix: 'سال',
            icon: Icons.cake_rounded,
          ),
          const SizedBox(height: 18),
          Text(
            'سطح فعالیت',
            style: TextStyle(
              color: txtC,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 10),
          ..._activityLevels
              .map((level) => _activityOption(level))
              .toList(),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _calculate(fromButton: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kTabShop,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.calculate_rounded, size: 20),
              label: const Text(
                'محاسبه',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kTabShop, kAccentGold],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: kTabShop, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: txtC,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ],
    );
  }

  Widget _genderBtn({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _gender = value);
        if (_hasCalculated) _calculate();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                )
              : null,
          color: selected ? null : pnl2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : lineC,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : color,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: pnl2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineC),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: kTabShop, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              onChanged: (_) {
                if (_hasCalculated) _calculate();
              },
              style: TextStyle(
                color: txtC,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: mutC,
                  fontSize: 12,
                  fontFamily: 'Vazirmatn',
                ),
                suffixText: suffix,
                suffixStyle: TextStyle(
                  color: mutC,
                  fontSize: 11,
                  fontFamily: 'Vazirmatn',
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityOption(Map<String, dynamic> level) {
    final selected = _activityLevel == level['key'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activityLevel = level['key'] as String);
          if (_hasCalculated) _calculate();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      kTabShop.withOpacity(0.15),
                      kTabShop.withOpacity(0.05),
                    ],
                  )
                : null,
            color: selected ? null : pnl2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? kTabShop : lineC,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? kTabShop : Colors.transparent,
                  border: Border.all(
                    color: selected ? kTabShop : mutC,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level['label'] as String,
                      style: TextStyle(
                        color: txtC,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    Text(
                      level['desc'] as String,
                      style: TextStyle(
                        color: mutC,
                        fontSize: 10.5,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '×${level['mult']}',
                style: TextStyle(
                  color: selected ? kTabShop : mutC,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBMIResult() {
    final bmiValue = _bmi!.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            _bmiColor.withOpacity(0.15),
            _bmiColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _bmiColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _bmiColor.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_bmiColor, _bmiColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _bmiColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.monitor_weight_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شاخص توده بدنی (BMI)',
                      style: TextStyle(
                        color: txtC,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _bmiCategory,
                      style: TextStyle(
                        color: _bmiColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                bmiValue,
                style: TextStyle(
                  color: _bmiColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBMIScale(),
        ],
      ),
    );
  }

  Widget _buildBMIScale() {
    return Column(
      children: [
        Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [
                Color(0xff3b82f6),
                Color(0xff059669),
                Color(0xffd97706),
                Color(0xffea580c),
                Color(0xffc1121f),
                Color(0xff9a0e17),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('کم‌وزن', style: _scaleTextStyle()),
            Text('نرمال', style: _scaleTextStyle()),
            Text('اضافه', style: _scaleTextStyle()),
            Text('چاق', style: _scaleTextStyle()),
          ],
        ),
      ],
    );
  }

  TextStyle _scaleTextStyle() {
    return TextStyle(
      color: mutC,
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      fontFamily: 'Vazirmatn',
    );
  }

  Widget _buildCalorieResult() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            kTabShop.withOpacity(0.15),
            kTabShop.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kTabShop.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kTabShop, kTabShop.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'کالری مورد نیاز روزانه',
                      style: TextStyle(
                        color: txtC,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    Text(
                      'بر اساس سطح فعالیت شما',
                      style: TextStyle(
                        color: mutC,
                        fontSize: 10.5,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$_tdee',
                style: TextStyle(
                  color: kTabShop,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'کالری',
                style: TextStyle(
                  color: kTabShop,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pnl2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: kTabShop, size: 18),
                const SizedBox(width: 8),
                Text(
                  'BMR (سوخت‌وساز پایه):',
                  style: TextStyle(
                    color: mutC,
                    fontSize: 11,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const Spacer(),
                Text(
                  '$_bmr کالری',
                  style: TextStyle(
                    color: txtC,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _calorieGoal(
                  label: 'کاهش وزن',
                  value: _tdee! - 500,
                  color: kSuccess,
                  icon: Icons.trending_down_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _calorieGoal(
                  label: 'تثبیت',
                  value: _tdee!,
                  color: kTabShop,
                  icon: Icons.balance_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _calorieGoal(
                  label: 'افزایش',
                  value: _tdee! + 500,
                  color: const Color(0xff2563eb),
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calorieGoal({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdealWeight() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineC),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kSuccess, kSuccess.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وزن ایده‌آل شما',
                  style: TextStyle(
                    color: txtC,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'بر اساس BMI نرمال (18.5 - 24.9)',
                  style: TextStyle(
                    color: mutC,
                    fontSize: 10.5,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$_idealWeightMin - $_idealWeightMax',
            style: TextStyle(
              color: kSuccess,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'kg',
            style: TextStyle(
              color: kSuccess,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== QUIZ PAGE ==================== */

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentIndex = 0;
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) =>
          ValueListenableBuilder<List<QuizQuestion>>(
        valueListenable: quizNotifier,
        builder: (context, questions, ___) {
          return ValueListenableBuilder<Map<String, int>>(
            valueListenable: answeredQuizNotifier,
            builder: (context, answers, ____) {
              final totalQuestions = questions.length;
              final answeredCount = questions
                  .where((q) => answers.containsKey(q.id))
                  .length;
              final correctCount = questions.where((q) {
                final ans = answers[q.id];
                return ans != null && ans == q.correctIndex;
              }).length;

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
                            colors: [kQuizColor, kAccentGold],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kQuizColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.quiz_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'کوئیز ورزشی',
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
                    if (questions.isNotEmpty) ...[
                      if (_showResult)
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _showResult = false);
                          },
                          icon: Icon(Icons.list_alt_rounded,
                              color: kQuizColor, size: 18),
                          label: Text(
                            'سوالات',
                            style: TextStyle(
                              color: kQuizColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _showResult = true);
                          },
                          icon: Icon(Icons.bar_chart_rounded,
                              color: kQuizColor, size: 18),
                          label: Text(
                            'نتیجه',
                            style: TextStyle(
                              color: kQuizColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
                body: questions.isEmpty
                    ? _buildEmpty()
                    : _showResult
                        ? _buildResult(
                            totalQuestions,
                            answeredCount,
                            correctCount,
                            questions,
                            answers,
                          )
                        : _buildQuestionList(
                            questions, answers, answeredCount),
              );
            },
          );
        },
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
                    kQuizColor.withOpacity(0.15),
                    kQuizColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kQuizColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.quiz_outlined,
                color: kQuizColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'هنوز سوالی ثبت نشده',
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'به‌زودی از طرف مدیریت، سوالات کوئیز اضافه خواهد شد',
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

  Widget _buildQuestionList(
    List<QuizQuestion> questions,
    Map<String, int> answers,
    int answeredCount,
  ) {
    return Column(
      children: [
        // Progress Bar
        Container(
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Column(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: lineC,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: questions.isNotEmpty
                      ? (_currentIndex + 1) / questions.length
                      : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kQuizColor, kAccentGold],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kQuizColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'سوال ${_currentIndex + 1} از ${questions.length}',
                      style: TextStyle(
                        color: kQuizColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kSuccess.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'پاسخ‌داده: $answeredCount / ${questions.length}',
                      style: TextStyle(
                        color: kSuccess,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Question
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
            child: _buildQuestion(
              questions[_currentIndex],
              answers,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(
    QuizQuestion q,
    Map<String, int> answers,
  ) {
    final isAlreadyAnswered = answers.containsKey(q.id);
    final savedAnswer = answers[q.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: darkModeNotifier.value
                  ? [kDarkCard, kDarkCard2]
                  : [Colors.white, kLightCard2],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAlreadyAnswered
                  ? kSuccess.withOpacity(0.4)
                  : kQuizColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isAlreadyAnswered ? kSuccess : kQuizColor)
                    .withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAlreadyAnswered
                            ? [kSuccess, kSuccessLight]
                            : [kQuizColor, kAccentGold],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isAlreadyAnswered
                          ? Icons.check_circle_rounded
                          : Icons.help_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سوال ${_currentIndex + 1}',
                          style: TextStyle(
                            color: isAlreadyAnswered
                                ? kSuccess
                                : kQuizColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        if (isAlreadyAnswered)
                          Text(
                            'قبلاً به این سوال پاسخ داده‌اید',
                            style: TextStyle(
                              color: mutC,
                              fontSize: 10.5,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                q.question,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: txtC,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.8,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Options
        ...List.generate(q.options.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child:
                _buildOption(q, i, isAlreadyAnswered, savedAnswer),
          );
        }),

        // Feedback
        if (isAlreadyAnswered) ...[
          const SizedBox(height: 16),
          _buildAnswerFeedback(q, savedAnswer ?? 0),
        ],

        // Navigation Buttons
        const SizedBox(height: 20),
        Row(
          children: [
            if (_currentIndex > 0)
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex--);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kQuizColor,
                      side: BorderSide(
                          color: kQuizColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded,
                        size: 20),
                    label: const Text(
                      'قبلی',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                ),
              ),
            if (_currentIndex > 0) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isAlreadyAnswered
                      ? () {
                          HapticFeedback.selectionClick();
                          if (_currentIndex <
                              quizNotifier.value.length - 1) {
                            setState(() => _currentIndex++);
                          } else {
                            setState(() => _showResult = true);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kQuizColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: lineC,
                    disabledForegroundColor: mutC,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    _currentIndex < quizNotifier.value.length - 1
                        ? Icons.arrow_back_rounded
                        : Icons.bar_chart_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _currentIndex < quizNotifier.value.length - 1
                        ? 'سوال بعدی'
                        : 'مشاهده نتیجه',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (!isAlreadyAnswered) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kWarning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: kWarning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'توجه: بعد از انتخاب گزینه، پاسخ شما ثبت می‌شود و دیگر قابل تغییر نیست.',
                    style: TextStyle(
                      color: kWarning,
                      fontSize: 10.5,
                      height: 1.6,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOption(
    QuizQuestion q,
    int index,
    bool isAlreadyAnswered,
    int? savedAnswer,
  ) {
    final isCorrect = index == q.correctIndex;
    final isSelected = savedAnswer == index;
    final isDark = darkModeNotifier.value;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? icon;
    Color? iconColor;

    if (!isAlreadyAnswered) {
      bgColor = pnl;
      borderColor = lineC;
      textColor = txtC;
      icon = null;
      iconColor = null;
    } else if (isCorrect) {
      bgColor = kSuccess.withOpacity(0.15);
      borderColor = kSuccess;
      textColor = kSuccess;
      icon = Icons.check_circle_rounded;
      iconColor = kSuccess;
    } else if (isSelected) {
      bgColor = kUrgent.withOpacity(0.15);
      borderColor = kUrgent;
      textColor = kUrgent;
      icon = Icons.cancel_rounded;
      iconColor = kUrgent;
    } else {
      bgColor = pnl;
      borderColor = lineC;
      textColor = mutC;
      icon = null;
      iconColor = null;
    }

    return GestureDetector(
      onTap: isAlreadyAnswered
          ? null
          : () async {
              HapticFeedback.mediumImpact();
              await saveUserAnswer(q.id, index);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: (isCorrect && isAlreadyAnswered) ||
                    (isSelected && isAlreadyAnswered)
                ? 1.8
                : 1.2,
          ),
          boxShadow: isAlreadyAnswered && (isCorrect || isSelected)
              ? [
                  BoxShadow(
                    color: (isCorrect ? kSuccess : kUrgent)
                        .withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: !isAlreadyAnswered
                    ? LinearGradient(
                        colors: [
                          kQuizColor.withOpacity(0.12),
                          kQuizColor.withOpacity(0.05),
                        ],
                      )
                    : isCorrect
                        ? const LinearGradient(
                            colors: [kSuccess, kSuccessLight])
                        : isSelected
                            ? const LinearGradient(
                                colors: [kUrgent, kUrgentDark])
                            : null,
                color: isAlreadyAnswered &&
                        !isCorrect &&
                        !isSelected
                    ? (isDark ? kDarkCard2 : kLightCard2)
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  ['الف', 'ب', 'پ', 'ت'][index % 4],
                  style: TextStyle(
                    color: !isAlreadyAnswered
                        ? kQuizColor
                        : (isCorrect || isSelected)
                            ? Colors.white
                            : mutC,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                q.options[index],
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight:
                      (isCorrect && isAlreadyAnswered) ||
                              (isSelected && isAlreadyAnswered)
                          ? FontWeight.w900
                          : FontWeight.w700,
                  height: 1.6,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, color: iconColor, size: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerFeedback(QuizQuestion q, int selectedIndex) {
    final isCorrect = selectedIndex == q.correctIndex;
    final correctLetter =
        ['الف', 'ب', 'پ', 'ت'][q.correctIndex % 4];
    final correctText = q.options[q.correctIndex];

    final Color feedbackColor = isCorrect ? kSuccess : kUrgent;
    final Color feedbackDark = isCorrect ? kSuccess : kUrgentDark;
    final IconData feedbackIcon = isCorrect
        ? Icons.celebration_rounded
        : Icons.sentiment_dissatisfied_rounded;
    final String feedbackTitle = isCorrect
        ? 'آفرین! پاسخ درست بود 🎉'
        : 'متأسفانه پاسخ اشتباه بود';
    final String feedbackSubtitle = isCorrect
        ? 'توضیحات این سوال رو بخون:'
        : 'پاسخ درست رو با دقت بخون و یاد بگیر:';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            feedbackColor.withOpacity(0.12),
            feedbackColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: feedbackColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: feedbackColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [feedbackColor, feedbackDark],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(feedbackIcon,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedbackTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feedbackSubtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 10.5,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kSuccess.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kSuccess, kSuccessLight],
                          ),
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: kSuccess.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'پاسخ صحیح: گزینه «$correctLetter»',
                              style: const TextStyle(
                                color: kSuccess,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              correctText,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: txtC,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                height: 1.6,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (q.explanation != null &&
                    q.explanation!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kInfo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kInfo.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: kInfo.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.lightbulb_rounded,
                                color: kInfo,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'توضیحات آموزشی',
                              style: TextStyle(
                                color: kInfo,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          q.explanation!,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: txtC,
                            fontSize: 13,
                            height: 1.9,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(
    int total,
    int answered,
    int correct,
    List<QuizQuestion> questions,
    Map<String, int> answers,
  ) {
    final wrong = answered - correct;
    final percent = total > 0 ? (correct / total * 100).round() : 0;
    final unanswered = total - answered;

    Color resultColor;
    String resultText;
    IconData resultIcon;
    String motivationalText;

    if (answered == 0) {
      resultColor = kQuizColor;
      resultText = 'هنوز شروع نکردی';
      resultIcon = Icons.play_circle_rounded;
      motivationalText = 'برای دیدن نتیجه، به سوالات پاسخ بده';
    } else if (percent >= 80) {
      resultColor = kSuccess;
      resultText = 'عالی بود! 🎉';
      resultIcon = Icons.emoji_events_rounded;
      motivationalText = 'دانش ورزشی شما فوق‌العاده است';
    } else if (percent >= 50) {
      resultColor = kWarning;
      resultText = 'خوب بود! 👍';
      resultIcon = Icons.thumb_up_rounded;
      motivationalText = 'با کمی تمرین بیشتر، بهتر هم می‌شی';
    } else {
      resultColor = kUrgent;
      resultText = 'نیاز به تمرین بیشتر';
      resultIcon = Icons.school_rounded;
      motivationalText =
          'اشکالی نداره، با مرور توضیحات بهتر می‌شی';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 100),
      child: Column(
        children: [
          // Result Card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  resultColor.withOpacity(0.15),
                  resultColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: resultColor.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: resultColor.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        resultColor,
                        resultColor.withOpacity(0.7)
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: resultColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(resultIcon,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  resultText,
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  motivationalText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutC,
                    fontSize: 12,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: pnl,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: resultColor, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent٪',
                        style: TextStyle(
                          color: resultColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      Text(
                        'امتیاز',
                        style: TextStyle(
                          color: mutC,
                          fontSize: 11,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.list_alt_rounded,
                  label: 'کل سوالات',
                  value: '$total',
                  color: kQuizColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.edit_note_rounded,
                  label: 'پاسخ داده',
                  value: '$answered',
                  color: kInfo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.check_circle_rounded,
                  label: 'صحیح',
                  value: '$correct',
                  color: kSuccess,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.cancel_rounded,
                  label: 'اشتباه',
                  value: '$wrong',
                  color: kUrgent,
                ),
              ),
            ],
          ),
          if (unanswered > 0) ...[
            const SizedBox(height: 10),
            _statCard(
              icon: Icons.pending_actions_rounded,
              label: 'بدون پاسخ',
              value: '$unanswered',
              color: kWarning,
            ),
          ],

          const SizedBox(height: 24),

          // Go to questions button
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                int firstUnanswered = 0;
                for (int i = 0; i < questions.length; i++) {
                  if (!answers.containsKey(questions[i].id)) {
                    firstUnanswered = i;
                    break;
                  }
                }
                setState(() {
                  _currentIndex = firstUnanswered;
                  _showResult = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kQuizColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                unanswered > 0
                    ? Icons.play_arrow_rounded
                    : Icons.list_alt_rounded,
                size: 20,
              ),
              label: Text(
                unanswered > 0
                    ? 'ادامه پاسخ‌دهی'
                    : 'مشاهده سوالات',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineC),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: mutC,
                    fontSize: 11,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== READING STATS PAGE ==================== */

class ReadingStatsPage extends StatelessWidget {
  const ReadingStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) =>
          ValueListenableBuilder<Map<String, dynamic>>(
        valueListenable: readingStatsNotifier,
        builder: (context, stats, ___) {
          final totalRead = stats['totalRead'] ?? 0;
          final weekCount = stats['weekCount'] ?? 0;
          final monthCount = stats['monthCount'] ?? 0;
          final totalReadTime = stats['totalReadTime'] ?? 0;
          final streak = stats['streak'] ?? 0;
          final categoryCount =
              (stats['categoryCount'] as Map<String, int>?) ?? {};
          final dailyCount =
              (stats['dailyCount'] as Map<String, int>?) ?? {};

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
                        colors: [kSuccess, kSuccessLight],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kSuccess.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.insights_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'آمار مطالعه',
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
                if (totalRead > 0)
                  IconButton(
                    tooltip: 'پاک کردن آمار',
                    onPressed: () => _confirmClear(context),
                    icon: Icon(Icons.delete_sweep_rounded,
                        color: rose, size: 22),
                  ),
              ],
            ),
            body: totalRead == 0
                ? _buildEmpty()
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(14, 14, 14, 100),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        _buildStreakCard(streak),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.article_rounded,
                                label: 'کل مقالات',
                                value: '$totalRead',
                                color: kPrimaryNavyLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.calendar_today_rounded,
                                label: 'این هفته',
                                value: '$weekCount',
                                color: kTabShop,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.date_range_rounded,
                                label: 'این ماه',
                                value: '$monthCount',
                                color: kTabArticles,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.access_time_rounded,
                                label: 'زمان کل (دقیقه)',
                                value: '$totalReadTime',
                                color: kSuccess,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildWeeklyChart(dailyCount),
                        const SizedBox(height: 14),
                        if (categoryCount.isNotEmpty)
                          _buildTopCategories(categoryCount),
                        const SizedBox(height: 14),
                        _buildRecentArticles(),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            kTabShop.withOpacity(0.15),
            kTabShop.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kTabShop.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kTabShop, kAccentGold],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: kTabShop.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'روزهای پیوسته',
                  style: TextStyle(
                    color: mutC,
                    fontSize: 12,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$streak',
                      style: TextStyle(
                        color: kTabShop,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 6, right: 4),
                      child: Text(
                        'روز',
                        style: TextStyle(
                          color: kTabShop,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: txtC,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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

  Widget _buildWeeklyChart(Map<String, int> dailyCount) {
    final now = DateTime.now();
    final days = <Map<String, dynamic>>[];
    int maxCount = 1;

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      final count = dailyCount[key] ?? 0;
      if (count > maxCount) maxCount = count;
      days.add({
        'label': _getDayLabel(day.weekday),
        'count': count,
        'isToday': i == 0,
      });
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kSuccess, kSuccessLight],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.bar_chart_rounded,
                  color: kSuccess, size: 18),
              const SizedBox(width: 6),
              Text(
                'مطالعه هفته گذشته',
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
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final count = d['count'] as int;
                final isToday = d['isToday'] as bool;
                final heightPercent = maxCount > 0
                    ? (count / maxCount).clamp(0.1, 1.0)
                    : 0.1;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: count > 0 ? kSuccess : mutC,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 28,
                      height: 100 * heightPercent,
                      decoration: BoxDecoration(
                        gradient: count > 0
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isToday
                                    ? [kTabShop, kAccentGold]
                                    : [kSuccess, kSuccessLight],
                              )
                            : null,
                        color: count == 0
                            ? lineC.withOpacity(0.5)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: count > 0
                            ? [
                                BoxShadow(
                                  color: (isToday
                                          ? kTabShop
                                          : kSuccess)
                                      .withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d['label'] as String,
                      style: TextStyle(
                        color: isToday ? kTabShop : mutC,
                        fontSize: 10.5,
                        fontWeight: isToday
                            ? FontWeight.w900
                            : FontWeight.w700,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(int weekday) {
    const days = ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'];
    return days[(weekday - 1) % 7];
  }

  Widget _buildTopCategories(Map<String, int> categoryCount) {
    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final maxVal = top.isNotEmpty ? top.first.value : 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kTabArticles, kPrimaryNavyLight],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.trending_up_rounded,
                  color: kTabArticles, size: 18),
              const SizedBox(width: 6),
              Text(
                'دسته‌های موردعلاقه شما',
                style: TextStyle(
                  color: txtC,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...top.map((entry) {
            final percent = maxVal > 0 ? entry.value / maxVal : 0.0;
            final cat = cats.firstWhere(
              (c) => c.n == entry.key,
              orElse: () => const Cat('سایر', 'other',
                  Icons.category_rounded, Color(0xff6b7280)),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cat.c.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(cat.i, color: cat.c, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: txtC,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          color: cat.c,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 6,
                      color: lineC,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerRight,
                        widthFactor: percent,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cat.c,
                                cat.c.withOpacity(0.7)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentArticles() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: readArticlesNotifier,
      builder: (context, articles, _) {
        if (articles.isEmpty) return const SizedBox.shrink();
        final recent = articles.take(5).toList();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: pnl,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: lineC),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kSuccess, kSuccessLight],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.history_rounded,
                      color: kSuccess, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'آخرین مقالات خوانده‌شده',
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
              ...recent.map((article) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: pnl2,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: lineC, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        if ((article['image'] ?? '')
                            .toString()
                            .isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: CachedNetworkImage(
                                imageUrl:
                                    article['image'].toString(),
                                fit: BoxFit.cover,
                                memCacheWidth: 150,
                                placeholder: (_, __) =>
                                    Container(color: pnl),
                                errorWidget: (_, __, ___) =>
                                    Container(
                                  color: pnl,
                                  child: Icon(
                                      Icons.article_rounded,
                                      color: mutC,
                                      size: 20),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: pnl,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.article_rounded,
                                color: mutC, size: 20),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                article['title']?.toString() ??
                                    '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: txtC,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.5,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${article['readTime']} دقیقه مطالعه',
                                style: TextStyle(
                                  color: mutC,
                                  fontSize: 10,
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
              }).toList(),
            ],
          ),
        );
      },
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
                    kSuccess.withOpacity(0.15),
                    kSuccess.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kSuccess.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: kSuccess,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'هنوز آماری وجود ندارد',
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'با خواندن مقالات، آمار مطالعه شما اینجا نمایش داده می‌شود',
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
          'پاک کردن آمار',
          style: TextStyle(
            color: txtC,
            fontWeight: FontWeight.w900,
            fontFamily: 'Vazirmatn',
          ),
        ),
        content: Text(
          'آیا می‌خواهید همه آمار مطالعه را پاک کنید؟',
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
      await clearReadingStats();
      if (context.mounted) showSnack(context, 'آمار پاک شد');
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
                ShimmerBox(height: 108, width: 108, radius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 14, width: 90, radius: 7),
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
                ShimmerBox(height: 130, width: 110, radius: 14),
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
                ShimmerBox(height: 100, width: 100, radius: 14),
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
