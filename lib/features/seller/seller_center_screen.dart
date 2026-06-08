import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/dashboard.dart';
import '../../core/models/listing.dart';
import '../../core/models/offer.dart';
import '../../core/state/app_scope.dart';
import '../../core/utils/image_url.dart';
import '../../shared/ui.dart';
import '../auth/login_screen.dart';
import '../listings/listing_detail_screen.dart';
import '../listings/listing_editor_screen.dart';

class SellerCenterScreen extends StatefulWidget {
  const SellerCenterScreen({super.key});

  @override
  State<SellerCenterScreen> createState() => _SellerCenterScreenState();
}

class _SellerCenterScreenState extends State<SellerCenterScreen> {
  late Future<SellerDashboard> _dashboardFuture;
  late Future<List<Listing>> _listingsFuture;
  late Future<List<Offer>> _offersFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _reload();
  }

  void _reload() {
    final api = AppScope.of(context).api;
    setState(() {
      _dashboardFuture = api.sellerDashboard();
      _listingsFuture = api.getMyListings();
      _offersFuture = api.sellerOffers();
    });
  }

  Future<void> _refreshAll() async {
    _reload();
    await Future.wait([_dashboardFuture, _listingsFuture, _offersFuture]);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.currentUser;

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_outlined, size: 42),
                const SizedBox(height: 10),
                Text(
                  'Satıcı merkezini görmek için giriş yapın',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Giriş Yap'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!user.isSellerApproved && user.role != 'Admin') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_bottom_rounded, size: 42),
                const SizedBox(height: 10),
                Text(
                  'Satıcı onayı bekleniyor',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'İlan vermek ve satıcı panelini kullanmak için admin onayı gerekiyor.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Satıcı Merkezi'),
          actions: [
            IconButton(
              tooltip: 'İlan Ver',
              onPressed: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                        builder: (_) => const ListingEditorScreen()),
                  )
                  .then((_) => _refreshAll()),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Özet', icon: Icon(Icons.space_dashboard_rounded)),
              Tab(text: 'İlanlarım', icon: Icon(Icons.list_alt_rounded)),
              Tab(text: 'Teklifler', icon: Icon(Icons.local_offer_outlined)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context)
              .push(
                MaterialPageRoute(builder: (_) => const ListingEditorScreen()),
              )
              .then((_) => _refreshAll()),
          icon: const Icon(Icons.add_rounded),
          label: const Text('İlan Ver'),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(
              dashboardFuture: _dashboardFuture,
              onRefresh: _refreshAll,
            ),
            _ListingsTab(
              listingsFuture: _listingsFuture,
              apiBaseUrl: controller.api.baseUrl,
              onRefresh: _refreshAll,
            ),
            _OffersTab(
              offersFuture: _offersFuture,
              onRefresh: _refreshAll,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.dashboardFuture, required this.onRefresh});

  final Future<SellerDashboard> dashboardFuture;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###', 'tr');

    return FutureBuilder<SellerDashboard>(
      future: dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Satıcı paneli yüklenemedi: ${snapshot.error}'));
        }

        final dashboard = snapshot.data!;
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            children: [
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Satıcı Özeti',
                      subtitle: 'İlanlar, teklif akışı ve dönüşüm durumu.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Metric(
                            value: '${dashboard.totalListings}',
                            label: 'Toplam İlan'),
                        _Metric(
                            value: '${dashboard.rentedListings}',
                            label: 'Kiralanan'),
                        _Metric(
                            value: '${dashboard.pendingOffers}',
                            label: 'Bekleyen Teklif'),
                        _Metric(
                            value: '%${dashboard.conversionRate}',
                            label: 'Dönüşüm'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'İlan Özeti',
                      subtitle: 'Kendi ilanlarınızdan son kayıtlar.',
                    ),
                    const SizedBox(height: 12),
                    if (dashboard.myListings.isEmpty)
                      const Text('Henüz ilan yok.')
                    else
                      ...dashboard.myListings.take(5).map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.title),
                              subtitle:
                                  Text('${item.province} / ${item.district}'),
                              trailing:
                                  Text('${money.format(item.monthlyPrice)} TL'),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => ListingDetailScreen(
                                        listingId: item.id)),
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
}

class _ListingsTab extends StatelessWidget {
  const _ListingsTab({
    required this.listingsFuture,
    required this.apiBaseUrl,
    required this.onRefresh,
  });

  final Future<List<Listing>> listingsFuture;
  final String apiBaseUrl;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Listing>>(
      future: listingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('İlanlar yüklenemedi: ${snapshot.error}'));
        }

        final listings = snapshot.data ?? const <Listing>[];
        if (listings.isEmpty) {
          return const Center(child: Text('Henüz ilan oluşturulmamış.'));
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = listings[index];
              return GlassPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.3,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22)),
                        child: Image.network(
                          resolveImageUrl(apiBaseUrl, item.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF111620),
                            child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 40),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('${item.province} / ${item.district}',
                              style: const TextStyle(color: Color(0xFFA9B3C8))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MiniChip(text: item.purposeLabel),
                              _MiniChip(text: item.roomCount),
                              _MiniChip(text: '${item.netSquareMeters} m²'),
                              if (item.isRented)
                                const _MiniChip(
                                    text: 'Kiralandı', danger: true),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => ListingDetailScreen(
                                            listingId: item.id)),
                                  ),
                                  child: const Text('Detay'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                            builder: (_) => ListingEditorScreen(
                                                listingId: item.id)),
                                      )
                                      .then((_) => onRefresh()),
                                  child: const Text('Düzenle'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('İlanı sil'),
                                      content: Text(
                                          '"${item.title}" ilanı silinsin mi?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dialogContext)
                                                  .pop(false),
                                          child: const Text('Vazgeç'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(dialogContext)
                                                  .pop(true),
                                          child: const Text('Sil'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  try {
                                    await AppScope.of(context)
                                        .api
                                        .deleteListing(item.id);
                                    await onRefresh();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                              SnackBar(content: Text('$e')));
                                    }
                                  }
                                },
                                child: const Text('Sil'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _OffersTab extends StatelessWidget {
  const _OffersTab({required this.offersFuture, required this.onRefresh});

  final Future<List<Offer>> offersFuture;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###', 'tr');

    return FutureBuilder<List<Offer>>(
      future: offersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Teklifler yüklenemedi: ${snapshot.error}'));
        }

        final offers = snapshot.data ?? const <Offer>[];
        if (offers.isEmpty) {
          return const Center(child: Text('Henüz teklif yok.'));
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final pending = offer.status == 'Beklemede';
              return GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.listingTitle,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${money.format(offer.amount)} TL',
                          style: const TextStyle(
                              color: Color(0xFFF0CC7D),
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${offer.fromUserName} · ${offer.type} · ${offer.status}',
                      style: const TextStyle(
                          color: Color(0xFFA9B3C8), fontSize: 12),
                    ),
                    if (offer.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(offer.note),
                    ],
                    if (pending) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  _updateOffer(context, offer.offerId, true),
                              child: const Text('Kabul Et'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _updateOffer(context, offer.offerId, false),
                              child: const Text('Reddet'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _updateOffer(
      BuildContext context, int offerId, bool accepted) async {
    try {
      await AppScope.of(context)
          .api
          .updateOfferStatus(offerId: offerId, accepted: accepted);
      await onRefresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF0CC7D))),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Color(0xFFA9B3C8), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: danger
            ? const Color(0xFFD43F4F).withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
