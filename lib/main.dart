import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/* ==================== CONSTANTS ==================== */

const String siteUrl = 'https://itarbiatbadani.ir';
const String apiUrl = '$siteUrl/wp-json/wp/v2';
const String logoAsset = 'assets/images/logo.png';
const String logoNetwork =
    '$siteUrl/wp-content/uploads/2025/07/1000073463.png';

const Color backgroundColor = Color(0xff07131f);
const Color panelColor = Color(0xff0d2233);
const Color panelColor2 = Color(0xff102a3e);
const Color goldColor = Color(0xfffbc531);
const Color blueColor = Color(0xff1687d9);
const Color cyanColor = Color(0xff25b8e8);
const Color textColor = Color(0xfff4f7fa);
const Color mutedColor = Color(0xff9fb0bd);
const Color lineColor = Color(0x17ffffff);

const Duration _httpTimeout = Duration(seconds: 25);
const String newNewsCategorySlug = 'urgent-news';

/* ==================== HELPERS ==================== */

Future<void> openUrl(String url) async {
  if (url.isEmpty || url == '#') return;
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

void openPost(BuildContext context, String url) {
  if (url.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ArticleWebViewPage(url: url)),
  );
}

String cleanHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#8217;', '’')
      .replaceAll('&#8216;', '‘')
      .replaceAll('&#8220;', '“')
      .replaceAll('&#8221;', '”')
      .replaceAll('&#8230;', '…')
      .trim();
}

String postTitle(dynamic post) {
  try {
    return cleanHtml(post['title']['rendered'] ?? 'بدون عنوان');
  } catch (_) {
    return 'بدون عنوان';
  }
}

String postLink(dynamic post) {
  try {
    return post['link'] ?? '';
  } catch (_) {
    return '';
  }
}

String postImage(dynamic post) {
  try {
    final media = post['_embedded']?['wp:featuredmedia'];
    if (media is List && media.isNotEmpty) {
      return media[0]['source_url'] ?? '';
    }
  } catch (_) {}
  return '';
}

String formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso).toLocal();
    const months = [
      'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
    ];
    final j = _gregorianToJalali(dt.year, dt.month, dt.day);
    return '${j[2]} ${months[j[1] - 1]} ${j[0]}';
  } catch (_) {
    return '';
  }
}

List<int> _gregorianToJalali(int gy, int gm, int gd) {
  const gdm = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  const jdm = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];
  var gy2 = (gm > 2) ? (gy + 1) : gy;
  var days = 355666 +
      (365 * gy) +
      ((gy2 + 3) ~/ 4) -
      ((gy2 + 99) ~/ 100) +
      ((gy2 + 399) ~/ 400) +
      gd;
  for (var i = 0; i < gm - 1; i++) {
    days += gdm[i];
  }
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

/* ==================== APP ==================== */

void main() {
  runApp(const ItarbiatbadaniApp());
}

class ItarbiatbadaniApp extends StatelessWidget {
  const ItarbiatbadaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: goldColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تربیت بدنی و علوم ورزشی',
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: base.copyWith(
        textTheme: GoogleFonts.vazirmatnTextTheme(base.textTheme),
      ),
      home: const MainPage(),
    );
  }
}

/* ==================== MAIN PAGE ==================== */

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  static const int _shopIndex = 3;

  final List<Widget> pages = const [
    HomePage(),
    CategoriesPage(),
    NewsPage(),
    SizedBox.shrink(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: const Color(0xff081925),
        indicatorColor: goldColor.withValues(alpha: .18),
        selectedIndex: currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          if (index == _shopIndex) {
            openUrl('$siteUrl/shop/');
            return;
          }
          setState(() => currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.house, size: 20, color: mutedColor),
            selectedIcon:
                FaIcon(FontAwesomeIcons.house, size: 20, color: goldColor),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.layerGroup,
                size: 20, color: mutedColor),
            selectedIcon:
                FaIcon(FontAwesomeIcons.layerGroup, size: 20, color: goldColor),
            label: 'دسته‌ها',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.newspaper,
                size: 20, color: mutedColor),
            selectedIcon:
                FaIcon(FontAwesomeIcons.newspaper, size: 20, color: goldColor),
            label: 'اخبار',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.cartShopping,
                size: 20, color: mutedColor),
            selectedIcon: FaIcon(FontAwesomeIcons.cartShopping,
                size: 20, color: goldColor),
            label: 'فروشگاه',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.user, size: 20, color: mutedColor),
            selectedIcon:
                FaIcon(FontAwesomeIcons.user, size: 20, color: goldColor),
            label: 'حساب من',
          ),
        ],
      ),
    );
  }
}

/* ==================== HEADER ==================== */

class AppHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onSearch;
  final VoidCallback? onLogoLongPress;

  const AppHeader({
    super.key,
    this.title = 'تربیت بدنی و علوم ورزشی',
    this.showBack = false,
    this.onSearch,
    this.onLogoLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(
          color: backgroundColor,
          border: Border(bottom: BorderSide(color: lineColor)),
        ),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_forward, color: textColor),
              ),
            GestureDetector(
              onLongPress: onLogoLongPress,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: goldColor.withValues(alpha: .4),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.network(
                      logoNetwork,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.sports,
                        color: goldColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onSearch,
              icon: const Icon(Icons.search, color: goldColor, size: 27),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== HOME ==================== */

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<dynamic>> postsFuture;
  late Future<List<dynamic>> categoriesFuture;
  Key _bannerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    postsFuture = WordPressApi.getPosts(perPage: 6);
    categoriesFuture = WordPressApi.getCategories();
  }

  Future<void> refresh() async {
    final posts = WordPressApi.getPosts(perPage: 6);
    final cats = WordPressApi.getCategories();
    setState(() {
      postsFuture = posts;
      categoriesFuture = cats;
      _bannerKey = UniqueKey();
    });
    try {
      await Future.wait([posts, cats]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: goldColor,
      backgroundColor: panelColor,
      onRefresh: refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              onLogoLongPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                );
              },
              onSearch: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 18, 14, 6),
              child: _HeroSection(),
            ),
          ),

          SliverToBoxAdapter(
            child: NewNewsBanner(key: _bannerKey),
          ),

          const SliverToBoxAdapter(child: ServicesSection()),

          const SliverToBoxAdapter(
            child: SectionTitle(
              title: 'جدیدترین نوشته‌ها',
              icon: Icons.article_outlined,
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<dynamic>>(
              future: postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingBox();
                }
                if (snapshot.hasError) {
                  return ErrorBox(
                    message: 'دریافت مطالب با مشکل مواجه شد.',
                    onRetry: refresh,
                  );
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const _EmptyBox(text: 'مطلبی پیدا نشد.');
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: posts.map((p) => PostCard(post: p)).toList(),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(
            child: SectionTitle(
              title: 'دسته‌بندی مطالب',
              icon: Icons.grid_view_rounded,
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<dynamic>>(
              future: categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingBox();
                }
                if (snapshot.hasError) {
                  return ErrorBox(
                    message: 'دریافت دسته‌بندی‌ها انجام نشد.',
                    onRetry: refresh,
                  );
                }
                final categories = snapshot.data ?? [];
                final mainCategories =
                    categories.where((c) => c['parent'] == 0).toList();
                if (mainCategories.isEmpty) {
                  return const _EmptyBox(text: 'دسته‌ای پیدا نشد.');
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mainCategories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (context, i) => _HomeCategoryCard(
                      category: mainCategories[i],
                    ),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SocialSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 25)),
        ],
      ),
    );
  }
}

/* ==================== LOADING / EMPTY ==================== */

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(35),
        child: Center(child: CircularProgressIndicator(color: goldColor)),
      );
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Text(text, style: const TextStyle(color: mutedColor)),
        ),
      );
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
    _future = WordPressApi.getNewNews();
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
        final title = postTitle(news);
        final link = postLink(news);
        final date = formatDate(news['date']);

        return GestureDetector(
          onTap: () => openPost(context, link),
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff25b8e8), Color(0xff1687d9)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: cyanColor.withValues(alpha: .25),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_new,
                            color: Color(0xff1687d9), size: 16),
                        SizedBox(width: 3),
                        Text(
                          'جدید',
                          style: TextStyle(
                            color: Color(0xff1687d9),
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
                              color: Colors.white.withValues(alpha: .8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
/* ==================== HERO ==================== */

class _HeroSection extends StatelessWidget {
  const _HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xff0a3d62), Color(0xff102a3e)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: goldColor.withValues(alpha: .15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: goldColor.withValues(alpha: .5),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.sports_soccer,
                      color: goldColor,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'تربیت بدنی و علوم ورزشی',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'اپلیکیشن رسمی مرجع ورزش',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'دسترسی سریع به جدیدترین اخبار، منابع علمی، طرح درس، '
            'پاورپوینت‌های آموزشی و مطالب تخصصی تربیت بدنی و علوم ورزشی — '
            'همه در یک اپلیکیشن ساده و سریع.',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Color(0xffc5d4df),
              fontSize: 13,
              height: 1.9,
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== SERVICES ==================== */

class ServiceItem {
  final String title;
  final IconData icon;
  final String url;
  const ServiceItem({
    required this.title,
    required this.icon,
    required this.url,
  });
}

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  static const List<ServiceItem> services = [
    ServiceItem(
      title: 'معرفی رشته',
      icon: Icons.info_outline,
      url:
          '$siteUrl/introduction-to-the-field-of-physical-education-and-sports-sciences/',
    ),
    ServiceItem(
      title: 'گرایش‌های ارشد',
      icon: Icons.school_outlined,
      url:
          '$siteUrl/%da%af%d8%b1%d8%a7%db%8c%d8%b4%d9%87%d8%a7%db%8c-%da%a9%d8%a7%d8%b1%d8%b4%d9%86%d8%a7%d8%b3%db%8c-%d8%a7%d8%b1%d8%b4%d8%af-%d8%aa%d8%b1%d8%a8%db%8c%d8%aa-%d8%a8%d8%af%d9%86%db%8c-%d9%88/',
    ),
    ServiceItem(
      title: 'گرایش‌های دکتری',
      icon: Icons.account_balance_outlined,
      url: '$siteUrl/sports-science-phd-exam-resources/',
    ),
    ServiceItem(
      title: 'منابع ارشد',
      icon: Icons.menu_book_outlined,
      url: '$siteUrl/master-of-sports-science-resources/',
    ),
    ServiceItem(
      title: 'منابع دکتری',
      icon: Icons.library_books_outlined,
      url: '$siteUrl/manabe-konkur-doctori-tarbiat-badani/',
    ),
    ServiceItem(
      title: 'دانشگاه‌های برتر',
      icon: Icons.account_balance,
      url: '$siteUrl/physical-education-sports-science/',
    ),
    ServiceItem(
      title: 'بازار کار',
      icon: Icons.work_outline,
      url: '$siteUrl/job-market-in-physical-education-and-sports-sciences/',
    ),
    ServiceItem(
      title: 'طرح درس',
      icon: Icons.assignment_outlined,
      url:
          '$siteUrl/product-category/%d8%b7%d8%b1%d8%ad-%d8%af%d8%b1%d8%b3-%d8%b1%d9%88%d8%b2%d8%a7%d9%86%d9%87-%d9%85%d8%a7%d9%87%d8%a7%d9%86%d9%87-%d8%b3%d8%a7%d9%84%d8%a7%d9%86%d9%87/',
    ),
    ServiceItem(
      title: 'پاورپوینت',
      icon: Icons.slideshow_outlined,
      url: '$siteUrl/product-category/powerpoint/',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle(title: 'خدمات ما', icon: Icons.apps),
        SizedBox(
          height: 112,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = services[index];
              return GestureDetector(
                onTap: () => openUrl(item.url),
                child: Container(
                  width: 112,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .06),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: goldColor, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

/* ==================== SECTION TITLE ==================== */

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const SectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 25,
            decoration: BoxDecoration(
              color: goldColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 9),
          Icon(icon, color: goldColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== POST CARD ==================== */

class PostCard extends StatelessWidget {
  final dynamic post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final image = postImage(post);
    final title = postTitle(post);
    final date = formatDate(post['date']);

    return GestureDetector(
      onTap: () => openPost(context, postLink(post)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
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
                child: image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: goldColor,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: mutedColor,
                          size: 35,
                        ),
                      )
                    : Container(
                        color: panelColor2,
                        child: const Icon(
                          Icons.article_outlined,
                          color: goldColor,
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
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.7,
                      ),
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          color: mutedColor,
                          fontSize: 11,
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
}

/* ==================== HOME CATEGORY CARD ==================== */

class _HomeCategoryCard extends StatelessWidget {
  final dynamic category;
  const _HomeCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final name = cleanHtml(category['name'] ?? '');
    final id = category['id'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubCategoriesPage(
              categoryId: id,
              categoryName: name,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.folder_outlined,
                color: goldColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: Text(
                  name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
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
    );
  }
}

/* ==================== SOCIAL ==================== */

class SocialSection extends StatelessWidget {
  const SocialSection({super.key});

  static const List<Map<String, dynamic>> socials = [
    {
      'title': 'تلگرام',
      'icon': FontAwesomeIcons.telegram,
      'url': 'https://t.me/itarbiatbadani',
    },
    {
      'title': 'اینستاگرام',
      'icon': FontAwesomeIcons.instagram,
      'url': 'https://instagram.com/itarbiatbadani',
    },
    {
      'title': 'بله',
      'icon': FontAwesomeIcons.comment,
      'url': 'https://ble.ir/itarbiatbadani',
    },
    {
      'title': 'فروشگاه',
      'icon': FontAwesomeIcons.cartShopping,
      'url': '$siteUrl/shop/',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle(
          title: 'ارتباط با ما',
          icon: Icons.connect_without_contact,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: socials.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3.2,
            ),
            itemBuilder: (context, index) {
              final item = socials[index];
              return GestureDetector(
                onTap: () => openUrl(item['url']),
                child: Container(
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .06),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(item['icon'], color: goldColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        item['title'],
                        style: const TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/* ==================== CATEGORIES PAGE ==================== */

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late Future<List<dynamic>> categoriesFuture;

  @override
  void initState() {
    super.initState();
    categoriesFuture = WordPressApi.getCategories();
  }

  Future<void> _refresh() async {
    final future = WordPressApi.getCategories();
    setState(() => categoriesFuture = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: goldColor,
        backgroundColor: panelColor,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                title: 'دسته‌بندی مطالب',
                onSearch: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchPage()),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<dynamic>>(
                future: categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingBox();
                  }
                  if (snapshot.hasError) {
                    return ErrorBox(
                      message: 'دریافت دسته‌بندی‌ها انجام نشد.',
                      onRetry: _refresh,
                    );
                  }
                  final categories = snapshot.data ?? [];
                  final mains =
                      categories.where((c) => c['parent'] == 0).toList();
                  if (mains.isEmpty) {
                    return const _EmptyBox(text: 'دسته‌ای یافت نشد.');
                  }
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children:
                          mains.map((c) => CategoryTile(category: c)).toList(),
                    ),
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

/* ==================== CATEGORY TILE ==================== */

class CategoryTile extends StatelessWidget {
  final dynamic category;
  const CategoryTile({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final name = cleanHtml(category['name'] ?? '');
    final id = category['id'];
    final count = category['count'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubCategoriesPage(
              categoryId: id,
              categoryName: name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_outlined, color: goldColor),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                  if (count > 0)
                    Text(
                      '$count مطلب',
                      style: const TextStyle(
                        color: mutedColor,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: mutedColor),
          ],
        ),
      ),
    );
  }
}

/* ==================== SUB CATEGORIES ==================== */

class SubCategoriesPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  const SubCategoriesPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });
  @override
  State<SubCategoriesPage> createState() => _SubCategoriesPageState();
}

class _SubCategoriesPageState extends State<SubCategoriesPage> {
  late Future<List<dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = WordPressApi.getSubCategories(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(title: widget.categoryName, showBack: true),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<dynamic>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingBox();
                }
                if (snapshot.hasError) {
                  return const ErrorBox(
                    message: 'دریافت زیر دسته‌ها انجام نشد.',
                  );
                }
                final subs = snapshot.data ?? [];
                if (subs.isEmpty) {
                  return CategoryPostsList(categoryId: widget.categoryId);
                }
                return Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children:
                        subs.map((c) => CategoryTile(category: c)).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== CATEGORY POSTS LIST ==================== */

class CategoryPostsList extends StatefulWidget {
  final int categoryId;
  const CategoryPostsList({super.key, required this.categoryId});
  @override
  State<CategoryPostsList> createState() => _CategoryPostsListState();
}

class _CategoryPostsListState extends State<CategoryPostsList> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = WordPressApi.getPosts(
      perPage: 20,
      category: widget.categoryId,
    );
  }

  Future<void> _refresh() async {
    final f = WordPressApi.getPosts(
      perPage: 20,
      category: widget.categoryId,
    );
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingBox();
        }
        if (snapshot.hasError) {
          return ErrorBox(
            message: 'دریافت مطالب انجام نشد.',
            onRetry: _refresh,
          );
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const _EmptyBox(text: 'در این دسته مطلبی پیدا نشد.');
        }
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: posts.map((p) => PostCard(post: p)).toList(),
          ),
        );
      },
    );
  }
}

/* ==================== NEWS PAGE ==================== */

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});
  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = WordPressApi.getPosts(perPage: 20);
  }

  Future<void> _refresh() async {
    final f = WordPressApi.getPosts(perPage: 20);
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: goldColor,
        backgroundColor: panelColor,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                title: 'اخبار ورزشی',
                onSearch: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchPage()),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingBox();
                  }
                  if (snapshot.hasError) {
                    return ErrorBox(
                      message: 'دریافت اخبار انجام نشد.',
                      onRetry: _refresh,
                    );
                  }
                  final posts = snapshot.data ?? [];
                  if (posts.isEmpty) {
                    return const _EmptyBox(
                      text: 'خبری برای نمایش وجود ندارد.',
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children:
                          posts.map((p) => PostCard(post: p)).toList(),
                    ),
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
/* ==================== ACCOUNT PAGE ==================== */

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: AppHeader(title: 'حساب من')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: goldColor.withValues(alpha: .5),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        logoAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 55,
                          color: goldColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'کاربر مهمان',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'برای دسترسی به امکانات بیشتر وارد شوید',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _AccountTile(
                    icon: Icons.login,
                    title: 'ورود به حساب',
                    onTap: () => openUrl('$siteUrl/wp-login.php'),
                  ),
                  _AccountTile(
                    icon: Icons.person_add_alt,
                    title: 'ثبت‌نام',
                    onTap: () =>
                        openUrl('$siteUrl/wp-login.php?action=register'),
                  ),
                  _AccountTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'سفارش‌های من',
                    onTap: () => openUrl('$siteUrl/my-account/orders/'),
                  ),
                  _AccountTile(
                    icon: Icons.favorite_border,
                    title: 'علاقه‌مندی‌ها',
                    onTap: () => openUrl('$siteUrl/my-account/'),
                  ),
                  _AccountTile(
                    icon: Icons.info_outline,
                    title: 'درباره ما',
                    onTap: () => openUrl('$siteUrl/about-us/'),
                  ),
                  _AccountTile(
                    icon: Icons.support_agent,
                    title: 'تماس با ما',
                    onTap: () => openUrl('$siteUrl/contact/'),
                  ),
                  _AccountTile(
                    icon: Icons.admin_panel_settings,
                    title: 'پنل مدیریت (ادمین)',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminLoginPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: goldColor, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_left, color: mutedColor),
          ],
        ),
      ),
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WordPressApi.verifyAdmin(username: user, appPassword: pass);
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AppHeader(title: 'ورود ادمین', showBack: true),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: .15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: goldColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'فقط مدیر سایت',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'برای مدیریت اخبار جدید وارد شوید',
                    style: TextStyle(color: mutedColor, fontSize: 13),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _userCtrl,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'نام کاربری وردپرس',
                      hintStyle: const TextStyle(color: mutedColor),
                      prefixIcon:
                          const Icon(Icons.person, color: goldColor),
                      filled: true,
                      fillColor: panelColor,
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
                    style: const TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Application Password',
                      hintStyle: const TextStyle(color: mutedColor),
                      prefixIcon: const Icon(Icons.key, color: goldColor),
                      filled: true,
                      fillColor: panelColor,
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
                        color: Colors.red.withValues(alpha: .15),
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
                        backgroundColor: goldColor,
                        foregroundColor: backgroundColor,
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
                                color: backgroundColor,
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
                ],
              ),
            ),
          ),
        ],
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
  late Future<List<dynamic>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = WordPressApi.getNewNewsList();
  }

  void _reloadList() {
    setState(() {
      _newsFuture = WordPressApi.getNewNewsList();
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
      await WordPressApi.postNewNews(
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
        backgroundColor: panelColor,
        title: const Text(
          'حذف خبر',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'آیا از حذف «${postTitle(post)}» مطمئن هستید؟',
          style: const TextStyle(color: mutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'انصراف',
              style: TextStyle(color: mutedColor),
            ),
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
      await WordPressApi.deleteNews(
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AppHeader(title: 'پنل مدیریت', showBack: true),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cyanColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cyanColor.withValues(alpha: .4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: cyanColor,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'خبر جدید پس از انتشار، در سایت و بالای صفحه اصلی اپ نمایش داده می‌شود و تا زمانی که شما حذف نکنید باقی می‌ماند.',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'عنوان خبر',
                    style: TextStyle(
                      color: goldColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'مثلاً: ثبت‌نام دوره جدید آغاز شد',
                      hintStyle: const TextStyle(color: mutedColor),
                      filled: true,
                      fillColor: panelColor,
                      contentPadding: const EdgeInsets.all(15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'متن کامل خبر',
                    style: TextStyle(
                      color: goldColor,
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
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.8,
                    ),
                    decoration: InputDecoration(
                      hintText: 'توضیحات کامل خبر...',
                      hintStyle: const TextStyle(color: mutedColor),
                      filled: true,
                      fillColor: panelColor,
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
                        backgroundColor: cyanColor,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Divider(color: lineColor),
                  const SizedBox(height: 12),

                  const Text(
                    'اخبار منتشر شده',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  FutureBuilder<List<dynamic>>(
                    future: _newsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: goldColor,
                            ),
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
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'هنوز خبری منتشر نشده است.',
                              style: TextStyle(color: mutedColor),
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
                              color: panelColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        postTitle(p),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: textColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          height: 1.6,
                                        ),
                                      ),
                                      if (formatDate(p['date'])
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          formatDate(p['date']),
                                          style: const TextStyle(
                                            color: mutedColor,
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
        ],
      ),
    );
  }
}
/* ==================== SEARCH PAGE ==================== */

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  List<dynamic> results = [];
  bool loading = false;
  bool searched = false;
  String? _error;

  Future<void> search() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      searched = true;
      _error = null;
    });
    try {
      final data = await WordPressApi.getPosts(search: text, perPage: 20);
      if (!mounted) return;
      setState(() {
        results = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        results = [];
        loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              title: 'جستجوی مطالب',
              showBack: Navigator.canPop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
              child: TextField(
                controller: _ctrl,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => search(),
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'عنوان یا موضوع مورد نظر را جستجو کنید...',
                  hintStyle: const TextStyle(
                    color: mutedColor,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: panelColor,
                  prefixIcon: IconButton(
                    onPressed: search,
                    icon: const Icon(Icons.search, color: goldColor),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          if (loading)
            const SliverToBoxAdapter(child: _LoadingBox())
          else if (_error != null)
            SliverToBoxAdapter(
              child: ErrorBox(
                message: 'جستجو با خطا مواجه شد.\n$_error',
                onRetry: search,
              ),
            )
          else if (searched && results.isEmpty)
            const SliverToBoxAdapter(
              child: _EmptyBox(text: 'نتیجه‌ای پیدا نشد.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PostCard(post: results[index]),
                  childCount: results.length,
                ),
              ),
            ),
        ],
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
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: .2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.orange,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: mutedColor,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: goldColor),
                label: const Text(
                  'تلاش دوباره',
                  style: TextStyle(color: goldColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* ==================== ARTICLE WEB VIEW ==================== */

class ArticleWebViewPage extends StatefulWidget {
  final String url;
  const ArticleWebViewPage({super.key, required this.url});

  @override
  State<ArticleWebViewPage> createState() => _ArticleWebViewPageState();
}

class _ArticleWebViewPageState extends State<ArticleWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(backgroundColor)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'مطلب', showBack: true),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== WORDPRESS API ==================== */

class WordPressApi {
  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  };

  /* ---------- عمومی ---------- */

  static Future<List<dynamic>> getPosts({
    int page = 1,
    int perPage = 6,
    String? search,
    int? category,
    bool embed = true,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'orderby': 'date',
      'order': 'desc',
    };
    if (embed) params['_embed'] = 'true';
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (category != null) {
      params['categories'] = category.toString();
    }
    return _getList('$apiUrl/posts', params, 'مطالب');
  }

  static Future<List<dynamic>> getCategories() async {
    return _getList(
      '$apiUrl/categories',
      {
        'per_page': '100',
        'orderby': 'name',
        'order': 'asc',
      },
      'دسته‌ها',
    );
  }

  static Future<List<dynamic>> getSubCategories(int parentId) async {
    return _getList(
      '$apiUrl/categories',
      {
        'per_page': '100',
        'parent': parentId.toString(),
      },
      'زیر دسته‌ها',
    );
  }

  /* ---------- اخبار جدید ---------- */

  static Future<int?> _getNewNewsCategoryId() async {
    final cats = await _getList(
      '$apiUrl/categories',
      {'slug': newNewsCategorySlug},
      'دسته اخبار جدید',
    );
    if (cats.isEmpty) return null;
    return cats.first['id'] as int;
  }

  static Future<Map<String, dynamic>?> getNewNews() async {
    try {
      final id = await _getNewNewsCategoryId();
      if (id == null) return null;
      final posts = await getPosts(perPage: 1, category: id);
      if (posts.isEmpty) return null;
      return posts.first;
    } catch (_) {
      return null;
    }
  }

  static Future<List<dynamic>> getNewNewsList() async {
    try {
      final id = await _getNewNewsCategoryId();
      if (id == null) return [];
      return await getPosts(perPage: 20, category: id, embed: false);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> postNewNews({
    required String username,
    required String appPassword,
    required String title,
    required String content,
  }) async {
    final auth = _basicAuth(username, appPassword);
    final catId = await _getNewNewsCategoryId();
    if (catId == null) {
      throw Exception('دسته «$newNewsCategorySlug» در سایت پیدا نشد.');
    }
    final uri = Uri.parse('$apiUrl/posts');
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Basic $auth',
            'User-Agent': 'FlutterApp/1.0',
          },
          body: jsonEncode({
            'title': title,
            'content': content,
            'status': 'publish',
            'categories': [catId],
          }),
        )
        .timeout(_httpTimeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw Exception('پاسخ نامعتبر از سرور');
    }
    if (response.statusCode == 401) {
      throw Exception('نام کاربری یا رمز عبور اشتباه است.');
    }
    if (response.statusCode == 403) {
      throw Exception('شما اجازه ارسال پست ندارید.');
    }
    throw Exception('خطا در ارسال (${response.statusCode})');
  }

  static Future<void> deleteNews({
    required String username,
    required String appPassword,
    required int postId,
  }) async {
    final auth = _basicAuth(username, appPassword);
    final uri = Uri.parse('$apiUrl/posts/$postId?force=true');
    final response = await http
        .delete(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Basic $auth',
            'User-Agent': 'FlutterApp/1.0',
          },
        )
        .timeout(_httpTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) return;
    if (response.statusCode == 401) {
      throw Exception('نام کاربری یا رمز اشتباه است.');
    }
    if (response.statusCode == 403) {
      throw Exception('شما اجازه حذف ندارید.');
    }
    throw Exception('خطا در حذف (${response.statusCode})');
  }

  static Future<void> verifyAdmin({
    required String username,
    required String appPassword,
  }) async {
    final auth = _basicAuth(username, appPassword);
    final uri = Uri.parse('$apiUrl/users/me');
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Basic $auth',
            'User-Agent': 'FlutterApp/1.0',
          },
        )
        .timeout(_httpTimeout);

    if (response.statusCode == 200) return;
    if (response.statusCode == 401) {
      throw Exception('نام کاربری یا رمز عبور اشتباه است.');
    }
    throw Exception('خطا در ورود (${response.statusCode})');
  }

  /* ---------- INTERNAL ---------- */

  static String _basicAuth(String user, String pass) {
    final clean = pass.replaceAll(' ', '');
    return base64Encode(utf8.encode('$user:$clean'));
  }

  static Future<List<dynamic>> _getList(
    String endpoint,
    Map<String, String> params,
    String label,
  ) async {
    final uri = Uri.parse(endpoint).replace(queryParameters: params);
    debugPrint('🌐 GET: $uri');

    late final http.Response response;
    try {
      response = await http
          .get(uri, headers: _headers)
          .timeout(_httpTimeout);
    } on TimeoutException {
      throw Exception('زمان پاسخ‌دهی سرور به پایان رسید.');
    } catch (e) {
      throw Exception('اتصال به سرور برقرار نشد.');
    }

    debugPrint('📥 ${response.statusCode} | ${response.body.length} bytes');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      throw Exception('پاسخ نامعتبر از وردپرس');
    }

    if (response.statusCode == 400) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map &&
            decoded['code'] == 'rest_post_invalid_page_number') {
          return <dynamic>[];
        }
      } catch (_) {}
    }

    throw Exception('خطا در دریافت $label (کد ${response.statusCode})');
  }
}
