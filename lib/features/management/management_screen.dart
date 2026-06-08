import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/admin_models.dart';
import '../../core/models/dashboard.dart';
import '../../core/models/offer.dart';
import '../../core/models/listing.dart';
import '../../core/models/user.dart';
import '../../core/state/app_scope.dart';
import '../../shared/ui.dart';
import '../auth/login_screen.dart';
import '../admin/admin_center_screen.dart';
import '../listings/listing_detail_screen.dart';
import '../listings/listing_editor_screen.dart';
import '../seller/seller_center_screen.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  late Future<Object?> _future;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _future = _load();
  }

  Future<Object?> _load() {
    final api = AppScope.of(context).api;
    final user = AppScope.of(context).currentUser;
    if (user == null) return Future.value(null);
    if (user.role == 'Admin') {
      return Future.wait<Object>([
        api.adminDashboard(),
        api.adminUsers(),
        api.adminReports(),
      ]);
    }
    return Future.wait<Object>([
      api.sellerDashboard(),
      api.sellerOffers(),
    ]);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
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
                const Icon(Icons.lock_outline_rounded, size: 42),
                const SizedBox(height: 10),
                Text(
                  'Yönetim alanı için giriş yapın',
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

    return FutureBuilder<Object?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Yönetim yüklenemedi: ${snapshot.error}'));
        }

        if (user.role == 'Admin') {
          final data = (snapshot.data as List<Object?>?) ?? const [];
          final dashboard =
              data.isNotEmpty ? data[0] as AdminDashboardResponse : null;
          final users =
              data.length > 1 ? (data[1] as List<User>) : const <User>[];
          final reports =
              data.length > 2 ? data[2] as AdminReportResponse : null;
          if (dashboard == null || reports == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              children: [
                _TopHero(user: user, subtitle: 'Admin ve super admin yönetimi'),
                const SizedBox(height: 16),
                _StatsGrid(items: [
                  _StatItem('Toplam İlan', '${dashboard.totalListings}'),
                  _StatItem('Aktif İlan', '${dashboard.activeListings}'),
                  _StatItem('Kiralanan', '${dashboard.rentedListings}'),
                  _StatItem('Bekleyen Satıcı', '${dashboard.pendingSellers}'),
                  _StatItem('Toplam Kullanıcı', '${dashboard.totalUsers}'),
                  _StatItem('Toplam Teklif', '${dashboard.totalOffers}'),
                ]),
                const SizedBox(height: 16),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Hızlı İşlemler',
                        subtitle:
                            'İlan ekleme, kullanıcı yönetimi ve raporlar.',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ListingEditorScreen()),
                                )
                                .then((_) => _reload()),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('İlan Ekle'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SellerCenterScreen()),
                            ),
                            icon: const Icon(Icons.storefront_outlined),
                            label: const Text('Satıcı Paneli'),
                          ),
                          if (user.role == 'Admin')
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const AdminCenterScreen()),
                              ),
                              icon: const Icon(
                                  Icons.admin_panel_settings_outlined),
                              label: const Text('Admin Paneli'),
                            ),
                          OutlinedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Yenile'),
                          ),
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
                      SectionHeader(
                        title: 'Kullanıcılar',
                        subtitle:
                            'En güncel kullanıcı listesi ve yetki durumu.',
                        trailing: TextButton(
                          onPressed: () => _showCreateUserSheet(context),
                          child: const Text('Yeni Kullanıcı'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...users.take(8).map((item) => _UserRow(
                            user: item,
                            onRefresh: _reload,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Şehirler',
                        subtitle: 'İlan yoğunluğu ve fiyat ortalaması.',
                      ),
                      const SizedBox(height: 12),
                      ...dashboard.topCities.map((city) => _MetricListTile(
                            title: city.city,
                            subtitle:
                                '${city.count} ilan · Ortalama ${NumberFormat('#,###', 'tr').format(city.avgPrice)} TL',
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Rapor Özeti',
                        subtitle: 'Teklif, yorum, puan ve satış rakamları.',
                      ),
                      const SizedBox(height: 12),
                      _StatsGrid(items: [
                        _StatItem('Teklif', '${reports.totalOffers}'),
                        _StatItem('Yorum', '${reports.totalComments}'),
                        _StatItem('Puan', '${reports.totalRatings}'),
                        _StatItem('Satış/Kiralama', '${reports.totalSales}'),
                      ]),
                      const SizedBox(height: 12),
                      ...reports.sellerPerformance
                          .take(5)
                          .map((item) => _MetricListTile(
                                title: item.sellerName,
                                subtitle:
                                    '${item.listingCount} ilan · ${item.offerCount} teklif · ${item.salesCount} satış',
                              )),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final data = (snapshot.data as List<Object?>?) ?? const [];
        final dashboard = data.isNotEmpty ? data[0] as SellerDashboard : null;
        final offers =
            data.length > 1 ? (data[1] as List<Offer>) : const <Offer>[];
        if (dashboard == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _future;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            children: [
              _TopHero(
                  user: user, subtitle: 'Satıcı paneli ve hızlı ilan yönetimi'),
              const SizedBox(height: 16),
              _StatsGrid(items: [
                _StatItem('Toplam İlan', '${dashboard.totalListings}'),
                _StatItem('Kiralanan', '${dashboard.rentedListings}'),
                _StatItem('Bekleyen Teklif', '${dashboard.pendingOffers}'),
                _StatItem('Dönüşüm', '%${dashboard.conversionRate}'),
              ]),
              const SizedBox(height: 16),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Hızlı İşlemler',
                      subtitle: 'İlan ekleme, düzenleme ve teklif yönetimi.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ListingEditorScreen()),
                              )
                              .then((_) => _reload()),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('İlan Ver'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SellerCenterScreen()),
                          ),
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('Satıcı Paneli'),
                        ),
                        if (user.role == 'Admin')
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AdminCenterScreen()),
                            ),
                            icon:
                                const Icon(Icons.admin_panel_settings_outlined),
                            label: const Text('Admin Paneli'),
                          ),
                        OutlinedButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Yenile'),
                        ),
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
                      title: 'İlanlarım',
                      subtitle: 'Kendi ilanlarınızı düzenleyin ve yönetin.',
                    ),
                    const SizedBox(height: 12),
                    ...dashboard.myListings.map((listing) => _ListingRow(
                          listing: listing,
                          onEdit: () => Navigator.of(context)
                              .push(MaterialPageRoute(
                                  builder: (_) => ListingEditorScreen(
                                      listingId: listing.id)))
                              .then((_) => _reload()),
                          onDelete: () => _deleteListing(listing.id),
                          onOpen: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    ListingDetailScreen(listingId: listing.id)),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Gelen Teklifler',
                      subtitle:
                          'Bekleyen, kabul edilen ve reddedilen teklifler.',
                    ),
                    const SizedBox(height: 12),
                    ...offers.map((offer) => _OfferRow(
                          offer: offer,
                          onAccept: offer.status == 'Beklemede'
                              ? () => _setOfferStatus(offer.offerId, true)
                              : null,
                          onReject: offer.status == 'Beklemede'
                              ? () => _setOfferStatus(offer.offerId, false)
                              : null,
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setOfferStatus(int offerId, bool accepted) async {
    final api = AppScope.of(context).api;
    try {
      await api.updateOfferStatus(offerId: offerId, accepted: accepted);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _deleteListing(int id) async {
    final api = AppScope.of(context).api;
    try {
      await api.deleteListing(id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _showCreateUserSheet(BuildContext context) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    final bio = TextEditingController();
    final profileImage = TextEditingController();
    String role = 'Customer';
    bool approved = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: GlassPanel(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Yeni Kullanıcı',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Ad Soyad')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'E-posta')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: phone,
                      decoration: const InputDecoration(labelText: 'Telefon')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: password,
                      decoration: const InputDecoration(labelText: 'Şifre')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(
                          value: 'Customer', child: Text('Müşteri')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    ],
                    onChanged: (value) => role = value ?? 'Customer',
                    decoration: const InputDecoration(labelText: 'Rol'),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: approved,
                    onChanged: (value) => approved = value,
                    title: const Text('Satıcı Onaylı'),
                  ),
                  TextField(
                      controller: bio,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(labelText: 'Biyografi')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: profileImage,
                      decoration: const InputDecoration(
                          labelText: 'Profil Görsel URL')),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        try {
                          await AppScope.of(context).api.createAdminUser(
                                fullName: name.text,
                                email: email.text,
                                phoneNumber: phone.text,
                                password: password.text,
                                role: role,
                                isSellerApproved: approved,
                                bio: bio.text,
                                profileImageUrl: profileImage.text,
                              );
                          if (mounted) {
                            Navigator.of(sheetContext).pop();
                            _reload();
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('$e')));
                        }
                      },
                      child: const Text('Oluştur'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopHero extends StatelessWidget {
  const _TopHero({required this.user, required this.subtitle});

  final dynamic user;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.role == 'Admin' ? 'Yönetim Merkezi' : 'Satıcı Merkezi',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 4,
                    color: const Color(0xFFD6B367),
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 8),
          Text(
            user.fullName,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Color(0xFFA9B3C8))),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((item) => SizedBox(
                width: 165,
                child: GlassPanel(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.value,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF0CC7D))),
                      const SizedBox(height: 4),
                      Text(item.label,
                          style: const TextStyle(
                              color: Color(0xFFA9B3C8), fontSize: 11)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _StatItem {
  _StatItem(this.label, this.value);

  final String label;
  final String value;
}

class _MetricListTile extends StatelessWidget {
  const _MetricListTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.analytics_outlined, color: Color(0xFFD6B367)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFFA9B3C8), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onRefresh});

  final User user;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == 'Admin';
    final isSuperAdmin = user.isSuperAdmin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                    child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0] : '?')),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(user.email,
                          style: const TextStyle(
                              color: Color(0xFFA9B3C8), fontSize: 12)),
                    ],
                  ),
                ),
                if (isSuperAdmin)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child:
                        _Badge(label: 'Super Admin', tone: Color(0xFFD6B367)),
                  )
                else
                  _Badge(
                      label: isAdmin ? 'Admin' : 'Müşteri',
                      tone: isAdmin ? Color(0xFF78D2DE) : Color(0xFF4C7AF0)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: isSuperAdmin
                      ? null
                      : () async {
                          await AppScope.of(context).api.setSellerApproval(
                              user.id, !user.isSellerApproved);
                          onRefresh();
                        },
                  child:
                      Text(user.isSellerApproved ? 'Onayı Kaldır' : 'Onayla'),
                ),
                OutlinedButton(
                  onPressed: isSuperAdmin
                      ? null
                      : () async {
                          await AppScope.of(context)
                              .api
                              .setAdminRole(user.id, !isAdmin);
                          onRefresh();
                        },
                  child: Text(isAdmin ? 'Admin Kaldır' : 'Admin Yap'),
                ),
                TextButton(
                  onPressed: isSuperAdmin
                      ? null
                      : () async {
                          await AppScope.of(context)
                              .api
                              .deleteAdminUser(user.id);
                          onRefresh();
                        },
                  child: const Text('Sil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow(
      {required this.listing,
      required this.onEdit,
      required this.onDelete,
      required this.onOpen});

  final Listing listing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(listing.imageUrl,
                      width: 76, height: 56, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onOpen,
                        child: Text(listing.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 4),
                      Text('${listing.province} / ${listing.district}',
                          style: const TextStyle(
                              color: Color(0xFFA9B3C8), fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                    '${NumberFormat('#,###', 'tr').format(listing.monthlyPrice)} TL',
                    style: const TextStyle(
                        color: Color(0xFFF0CC7D), fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(onPressed: onEdit, child: const Text('Düzenle')),
                TextButton(onPressed: onDelete, child: const Text('Sil')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow(
      {required this.offer, required this.onAccept, required this.onReject});

  final Offer offer;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(offer.listingTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                Text('${NumberFormat('#,###', 'tr').format(offer.amount)} TL',
                    style: const TextStyle(
                        color: Color(0xFFF0CC7D), fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${offer.fromUserName} · ${offer.type} · ${offer.status}',
                style: const TextStyle(color: Color(0xFFA9B3C8), fontSize: 12)),
            if (offer.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(offer.note),
            ],
            if (onAccept != null || onReject != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onAccept != null)
                    FilledButton(
                        onPressed: onAccept, child: const Text('Kabul Et')),
                  if (onReject != null)
                    OutlinedButton(
                        onPressed: onReject, child: const Text('Reddet')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: tone, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
