import 'package:flutter/material.dart';

import '../../core/models/listing.dart';
import '../../core/state/app_scope.dart';
import '../../shared/ui.dart';
import '../info/info_pages.dart';
import '../listings/listing_detail_screen.dart';
import '../listings/listings_screen.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  late Future<List<Listing>> _listingsFuture;
  bool _hasLoaded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoaded) return;
    _hasLoaded = true;
    _listingsFuture = _loadListings();
  }

  Future<List<Listing>> _loadListings() {
    final controller = AppScope.of(context);
    return controller.api.getListings();
  }

  void _reloadListings() {
    setState(() {
      _listingsFuture = _loadListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final api = controller.api;

    return FutureBuilder<List<Listing>>(
      future: _listingsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 44, color: Color(0xFFD6B367)),
                  const SizedBox(height: 12),
                  Text(
                    'İlanlar yüklenemedi',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: const Color(0xFFA9B3C8)),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _reloadListings,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final listings = snapshot.data ?? const <Listing>[];
        final dailyListings =
            listings.where((item) => item.isDailyRecommended).take(4).toList();
        final featured = listings.take(4).toList();
        final filtered = _query.isEmpty
            ? featured
            : featured.where((item) {
                final needle = _query.toLowerCase();
                return item.title.toLowerCase().contains(needle) ||
                    item.province.toLowerCase().contains(needle) ||
                    item.district.toLowerCase().contains(needle);
              }).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              sliver: SliverToBoxAdapter(
                child: GlassPanel(
                  padding: const EdgeInsets.all(18),
                  borderColor: Colors.white.withValues(alpha: 0.09),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEGERLIYUVAM',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  letterSpacing: 4,
                                  color: const Color(0xFFD6B367),
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hayalinizdeki Eve\nKapı Aralıyoruz',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.05,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Türkiye'nin dört bir yanındaki seçkin kiralık ve satılık ilanları tek yerde.",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFFC8D4F0),
                              height: 1.55,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: const InputDecoration(
                          hintText: 'Şehir, ilçe veya ilan ara',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ListingsScreen()),
                              );
                            },
                            child: const Text('Tüm İlanları Gör'),
                          ),
                          OutlinedButton(
                            onPressed: controller.currentUser == null
                                ? () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => const LoginScreen()),
                                    )
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const EditProfileScreen()),
                                    ),
                            child: Text(controller.currentUser == null
                                ? 'Giriş Yap'
                                : 'Profili Düzenle'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _StatsRow(listings: listings),
              ),
            ),
            if (dailyListings.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Günün Tavsiyeleri',
                    subtitle: 'Admin tarafından öne çıkarılan günlük ilanlar.',
                    trailing: const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFF0CC7D)),
                  ),
                ),
              ),
            if (dailyListings.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = dailyListings[index];
                      return ListingCard(
                        listing: item,
                        baseUrl: api.baseUrl,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ListingDetailScreen(listingId: item.id),
                          ),
                        ),
                      );
                    },
                    childCount: dailyListings.length,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Bilgi Sayfaları',
                        subtitle:
                            'Platform hakkında kısa bilgi ve yardım sayfaları.',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AboutScreen()),
                            ),
                            child: const Text('Hakkında'),
                          ),
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const FaqScreen()),
                            ),
                            child: const Text('SSS'),
                          ),
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ContactScreen()),
                            ),
                            child: const Text('İletişim'),
                          ),
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const PrivacyScreen()),
                            ),
                            child: const Text('Gizlilik'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Öne Çıkan İlanlar',
                  subtitle:
                      'Uzman seçimi premium evler ve yüksek görünürlükteki ilanlar.',
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ListingsScreen()),
                    ),
                    child: const Text('Tümünü Gör'),
                  ),
                ),
              ),
            ),
            if (snapshot.connectionState == ConnectionState.waiting &&
                listings.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('Aradığınız kriterlere uygun ilan bulunamadı.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      return ListingCard(
                        listing: item,
                        baseUrl: api.baseUrl,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ListingDetailScreen(listingId: item.id),
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.listings});

  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    final cities = listings.map((e) => e.province).toSet().length;
    final users = listings.map((e) => e.ownerUserId).toSet().length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatCard(value: '${listings.length}+', label: 'Aktif İlan'),
        _StatCard(value: '$cities+', label: 'Şehir'),
        _StatCard(value: '$users+', label: 'Satıcı'),
        _StatCard(value: '%4 +KDV', label: 'Komisyon'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFF0CC7D),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFA9B3C8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
