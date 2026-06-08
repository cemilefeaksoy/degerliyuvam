import 'package:flutter/material.dart';

import '../../core/models/listing.dart';
import '../../core/state/app_scope.dart';
import '../../shared/ui.dart';
import 'listing_detail_screen.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final _searchController = TextEditingController();
  final _cityController = TextEditingController();
  String _purpose = '';
  String _query = '';
  late Future<List<Listing>> _listingsFuture;
  bool _hasLoaded = false;

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
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
    return controller.api.getListings(
      city: _cityController.text.isEmpty ? null : _cityController.text,
      purpose: _purpose.isEmpty ? null : _purpose,
    );
  }

  void _refreshListings() {
    setState(() {
      _listingsFuture = _loadListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return FutureBuilder<List<Listing>>(
      future: _listingsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: Center(
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
                          onPressed: _refreshListings,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final listings = snapshot.data ?? const <Listing>[];
        final filtered = _query.isEmpty
            ? listings
            : listings.where((item) {
                final needle = _query.toLowerCase();
                return item.title.toLowerCase().contains(needle) ||
                    item.province.toLowerCase().contains(needle) ||
                    item.district.toLowerCase().contains(needle);
              }).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'İlanlar',
                  subtitle:
                      'Filtreleyin, kıyaslayın ve detay sayfasından işlemi başlatın.',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: GlassPanel(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {
                          _query = value;
                        }),
                        decoration: const InputDecoration(
                          hintText: 'İlan, şehir veya ilçe ara',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _purpose.isEmpty ? null : _purpose,
                              decoration:
                                  const InputDecoration(hintText: 'Tip'),
                              items: const [
                                DropdownMenuItem(
                                    value: '', child: Text('Tümü')),
                                DropdownMenuItem(
                                    value: 'Kiralık', child: Text('Kiralık')),
                                DropdownMenuItem(
                                    value: 'Satılık', child: Text('Satılık')),
                              ],
                              onChanged: (value) {
                                setState(() => _purpose = value ?? '');
                                _refreshListings();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _cityController,
                              onSubmitted: (_) => _refreshListings(),
                              decoration: const InputDecoration(
                                hintText: 'Şehir',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _refreshListings,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Filtreyi Uygula'),
                        ),
                      ),
                    ],
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
                  child: Text('Bu filtrelerde ilan bulunamadı.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final count = width >= 900
                        ? 3
                        : width >= 620
                            ? 2
                            : 1;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        childAspectRatio: count == 1 ? 0.76 : 0.72,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filtered[index];
                          return ListingCard(
                            listing: item,
                            baseUrl: controller.api.baseUrl,
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
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
