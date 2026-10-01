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
  var days = 355666 + (365 * gy) + ((gy2 + 3) ~/ 4) -
      ((gy2 + 99) ~/ 100) + ((gy2 + 399) ~/ 400) + gd;
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
            selectedIcon: FaIcon(FontAwesomeIcons.house, size: 20, color: goldColor),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.layerGroup, size: 20, color: mutedColor),
            selectedIcon: FaIcon(FontAwesomeIcons.layerGroup, size: 20, color: goldColor),
            label: 'دسته‌ها',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.newspaper, size: 20, color: mutedColor),
            selectedIcon: FaIcon(FontAwesomeIcons.newspaper, size: 20, color: goldColor),
            label: 'اخبار',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.cartShopping, size: 20, color: mutedColor),
            selectedIcon: FaIcon(FontAwesomeIcons.cartShopping, size: 20, color: goldColor),
            label: 'فروشگاه',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.user, size: 20, color: mutedColor),
            selectedIcon: FaIcon(FontAwesomeIcons.user, size: 20, color: goldColor),
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
                        Icons.sports, color: goldColor,
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

          /* Hero اصلی */
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 18, 14, 6),
              child: _HeroSection(),
            ),
          ),

          /* 📢 بنر اخبار جدید (زیر Hero، بالای خدمات) */
          SliverToBoxAdapter(
            child: NewNewsBanner(key: _bannerKey),
          ),

          /* خدمات ما */
          const SliverToBoxAdapter(child: ServicesSection()),

          /* جدیدترین نوشته‌ها */
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

          /* دسته‌بندی مطالب */
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

          /* ارتباط با ما */
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

/* ==================== 📢 NEW NEWS BANNER ==================== */

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
                width: 60, height: 60,
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
                      Icons.sports_soccer, color: goldColor, size: 30,
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
                    color: goldColor, fontSize: 17, fontWeight: FontWeight.bold,
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
              color: Colors.white, fontSize: 22,
              fontWeight: FontWeight.bold, height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'دسترسی سریع به جدیدترین اخبار، منابع علمی، طرح درس، '
            'پاورپوینت‌های آموزشی و مطالب تخصصی تربیت بدنی و علوم ورزشی — '
            'همه در یک اپلیکیشن ساده و سریع.',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Color(0xffc5d4df), fontSize: 13, height: 1.9,
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
  const ServiceItem({required this.title, required this.icon, required this.url});
}

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  static const List<ServiceItem> services = [
    ServiceItem(
      title: 'معرفی رشته',
      icon: Icons.info_outline,
      url: '$siteUrl/introduction-to-the-field-of-physical-education-and-sports-sciences/',
    ),
    ServiceItem(
      title: 'گرایش‌های ارشد',
      icon: Icons.school_outlined,
      url: '$siteUrl/%da%af%d8%b1%d8%a7%db%8c%d8%b4%d9%87%d8%a7%db%8c-%da%a9%d8%a7%d8%b1%d8%b4%d9%86%d8%a7%d8%b3%db%8c-%d8%a7%d8%b1%d8%b4%d8%af-%d8%aa%d8%b1%d8%a8%db%8c%d8%aa-%d8%a8%d8%af%d9%86%db%8c-%d9%88/',
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
      url: '$siteUrl/product-category/%d8%b7%d8%b1%d8%ad-%d8%af%d8%b1%d8%b3-%d8%b1%d9%88%d8%b2%d8%a7%d9%86%d9%87-%d9%85%d8%a7%d9%87%d8%a7%d9%86%d9%87-%d8%b3%d8%a7%d9%84%d8%a7%d9%86%d9%87/',
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
                    border: Border.all(color: Colors.white.withValues(alpha: .06)),
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
                          color: textColor, fontSize: 12,
                          fontWeight: FontWeight.bold, height: 1.5,
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
  const SectionTitle({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      child: Row(
        children: [
          Container(
            width: 4, height: 25,
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
                color: textColor, fontSize: 18, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
