import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/admin_models.dart';
import '../../core/models/listing.dart';
import '../../core/models/user.dart';
import '../../core/state/app_scope.dart';
import '../../core/utils/image_url.dart';
import '../../shared/ui.dart';
import '../auth/login_screen.dart';
import '../listings/listing_detail_screen.dart';
import '../listings/listing_editor_screen.dart';

class AdminCenterScreen extends StatefulWidget {
  const AdminCenterScreen({super.key});

  @override
  State<AdminCenterScreen> createState() => _AdminCenterScreenState();
}

class _AdminCenterScreenState extends State<AdminCenterScreen> {
  late Future<AdminDashboardResponse> _dashboardFuture;
  late Future<List<User>> _usersFuture;
  late Future<List<Listing>> _listingsFuture;
  late Future<AdminReportResponse> _reportFuture;
  bool _initialized = false;

  String? _reportStart;
  String? _reportEnd;
  int? _reportSellerId;
  String _reportFeature = 'all';
  String _reportEvent = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _reloadAll();
    _reloadReport();
  }

  void _reloadAll() {
    final api = AppScope.of(context).api;
    setState(() {
      _dashboardFuture = api.adminDashboard();
      _usersFuture = api.adminUsers();
      _listingsFuture = api.getListings();
    });
  }

  void _reloadReport() {
    final api = AppScope.of(context).api;
    setState(() {
      _reportFuture = api.adminReports(
        reportStart: _reportStart,
        reportEnd: _reportEnd,
        reportSellerId: _reportSellerId,
        reportFeature: _reportFeature == 'all' ? null : _reportFeature,
        reportEvent: _reportEvent == 'all' ? null : _reportEvent,
      );
    });
  }

  Future<void> _refreshAll() async {
    _reloadAll();
    _reloadReport();
    await Future.wait(
        [_dashboardFuture, _usersFuture, _listingsFuture, _reportFuture]);
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
                const Icon(Icons.admin_panel_settings_outlined, size: 42),
                const SizedBox(height: 10),
                Text(
                  'Admin paneli için giriş yapın',
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

    if (user.role != 'Admin') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_rounded, size: 42),
                const SizedBox(height: 10),
                Text(
                  'Bu alan sadece admin içindir',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                    'Kullanıcı yönetimi, raporlar ve tüm ilanların kontrolü burada yapılır.'),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Paneli'),
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
            IconButton(
              tooltip: 'Yenile',
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Özet', icon: Icon(Icons.space_dashboard_rounded)),
              Tab(text: 'Kullanıcılar', icon: Icon(Icons.people_alt_rounded)),
              Tab(text: 'Raporlar', icon: Icon(Icons.assessment_outlined)),
              Tab(text: 'İlanlar', icon: Icon(Icons.list_alt_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AdminOverviewTab(
              dashboardFuture: _dashboardFuture,
              onRefresh: _refreshAll,
            ),
            _AdminUsersTab(
              usersFuture: _usersFuture,
              onRefresh: _refreshAll,
              onEditUser: _showUserSheet,
              onCreateUser: () => _showUserSheet(),
            ),
            _AdminReportsTab(
              reportFuture: _reportFuture,
              reportStart: _reportStart,
              reportEnd: _reportEnd,
              reportSellerId: _reportSellerId,
              reportFeature: _reportFeature,
              reportEvent: _reportEvent,
              onPickStart: _pickStart,
              onPickEnd: _pickEnd,
              onSellerChanged: (value) =>
                  setState(() => _reportSellerId = value),
              onFeatureChanged: (value) =>
                  setState(() => _reportFeature = value),
              onEventChanged: (value) => setState(() => _reportEvent = value),
              onLoadReport: _reloadReport,
            ),
            _AdminListingsTab(
              listingsFuture: _listingsFuture,
              apiBaseUrl: controller.api.baseUrl,
              onRefresh: _refreshAll,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _reportStart = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _reportEnd = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _showUserSheet({User? user}) async {
    final name = TextEditingController(text: user?.fullName ?? '');
    final email = TextEditingController(text: user?.email ?? '');
    final phone = TextEditingController(text: user?.phoneNumber ?? '');
    final password = TextEditingController();
    final bio = TextEditingController(text: user?.bio ?? '');
    final profileImage =
        TextEditingController(text: user?.profileImageUrl ?? '');
    String role = user?.role ?? 'Customer';
    bool approved = user?.isSellerApproved ?? false;

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
                  Text(
                    user == null ? 'Yeni Kullanıcı' : 'Kullanıcı Düzenle',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
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
                  if (user == null) ...[
                    TextField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Şifre')),
                    const SizedBox(height: 10),
                  ],
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
                    title: const Text('Satıcı Onayı'),
                    value: approved,
                    onChanged: (value) => setState(() => approved = value),
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
                          if (user == null) {
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
                          } else {
                            await AppScope.of(context).api.updateAdminUser(
                                  id: user.id,
                                  fullName: name.text,
                                  email: email.text,
                                  phoneNumber: phone.text,
                                  role: role,
                                  isSellerApproved: approved,
                                  bio: bio.text,
                                  profileImageUrl: profileImage.text,
                                  newPassword: password.text,
                                );
                          }
                          if (mounted) {
                            Navigator.of(sheetContext).pop();
                            _refreshAll();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('$e')));
                          }
                        }
                      },
                      child: Text(user == null ? 'Oluştur' : 'Kaydet'),
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

class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab(
      {required this.dashboardFuture, required this.onRefresh});

  final Future<AdminDashboardResponse> dashboardFuture;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminDashboardResponse>(
      future: dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Admin paneli yüklenemedi: ${snapshot.error}'));
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
                      title: 'Admin Özeti',
                      subtitle:
                          'Sistem istatistikleri, kullanıcılar ve ilanlar.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Metric(
                            value: '${dashboard.totalUsers}',
                            label: 'Kullanıcı'),
                        _Metric(
                            value: '${dashboard.totalListings}', label: 'İlan'),
                        _Metric(
                            value: '${dashboard.pendingSellers}',
                            label: 'Bekleyen Satıcı'),
                        _Metric(
                            value: '${dashboard.totalOffers}', label: 'Teklif'),
                        _Metric(
                            value: '${dashboard.totalMessages}',
                            label: 'Mesaj'),
                        _Metric(
                            value: '${dashboard.totalRentals}',
                            label: 'Kiralama'),
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
                      title: 'Öne Çıkan Şehirler',
                      subtitle: 'İlan yoğunluğuna göre şehir özetleri.',
                    ),
                    const SizedBox(height: 12),
                    ...dashboard.topCities.map(
                      (city) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(city.city),
                        subtitle: Text('${city.count} ilan'),
                        trailing: Text(
                            '${NumberFormat('#,###', 'tr').format(city.avgPrice)} TL'),
                      ),
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
                      title: 'Son Kayıtlar',
                      subtitle: 'En son ilanlar ve kullanıcılar.',
                    ),
                    const SizedBox(height: 12),
                    ...dashboard.latestUsers.take(4).map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.fullName),
                            subtitle: Text(item.email),
                            trailing: Text(item.role),
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

class _AdminUsersTab extends StatelessWidget {
  const _AdminUsersTab({
    required this.usersFuture,
    required this.onRefresh,
    required this.onEditUser,
    required this.onCreateUser,
  });

  final Future<List<User>> usersFuture;
  final Future<void> Function() onRefresh;
  final Future<void> Function({User? user}) onEditUser;
  final Future<void> Function() onCreateUser;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Kullanıcılar yüklenemedi: ${snapshot.error}'));
        }

        final users = snapshot.data ?? const <User>[];
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
                    SectionHeader(
                      title: 'Kullanıcı Yönetimi',
                      subtitle: 'Admin, satıcı ve müşteri hesapları.',
                      trailing: FilledButton(
                        onPressed: onCreateUser,
                        child: const Text('Yeni Kullanıcı'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (users.isEmpty)
                      const Text('Kullanıcı bulunamadı.')
                    else
                      ...users.map((item) => _UserCard(
                            user: item,
                            onRefresh: onRefresh,
                            onEdit: () => onEditUser(user: item),
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
}

class _AdminReportsTab extends StatelessWidget {
  const _AdminReportsTab({
    required this.reportFuture,
    required this.reportStart,
    required this.reportEnd,
    required this.reportSellerId,
    required this.reportFeature,
    required this.reportEvent,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onSellerChanged,
    required this.onFeatureChanged,
    required this.onEventChanged,
    required this.onLoadReport,
  });

  final Future<AdminReportResponse> reportFuture;
  final String? reportStart;
  final String? reportEnd;
  final int? reportSellerId;
  final String reportFeature;
  final String reportEvent;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<int?> onSellerChanged;
  final ValueChanged<String> onFeatureChanged;
  final ValueChanged<String> onEventChanged;
  final VoidCallback onLoadReport;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminReportResponse>(
      future: reportFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final report = snapshot.data;
        return RefreshIndicator(
          onRefresh: () async => onLoadReport(),
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
                      title: 'Raporlar',
                      subtitle:
                          'İşlem filtresi, tarih aralığı ve performans özetleri.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: onPickStart,
                          icon: const Icon(Icons.date_range_rounded),
                          label: Text(reportStart ?? 'Başlangıç Tarihi'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onPickEnd,
                          icon: const Icon(Icons.event_rounded),
                          label: Text(reportEnd ?? 'Bitiş Tarihi'),
                        ),
                        DropdownButton<String>(
                          value: reportFeature,
                          items: const [
                            DropdownMenuItem(
                                value: 'all', child: Text('Tüm Özellikler')),
                            DropdownMenuItem(
                                value: 'balcony', child: Text('Balkon')),
                            DropdownMenuItem(
                                value: 'parking', child: Text('Otopark')),
                            DropdownMenuItem(
                                value: 'elevator', child: Text('Asansör')),
                            DropdownMenuItem(
                                value: 'insite', child: Text('Site')),
                            DropdownMenuItem(
                                value: 'pool', child: Text('Havuz')),
                            DropdownMenuItem(
                                value: 'furnished', child: Text('Eşyalı')),
                            DropdownMenuItem(
                                value: 'admin_recommended',
                                child: Text('Admin Önerisi')),
                            DropdownMenuItem(
                                value: 'daily_recommended',
                                child: Text('Günlük Tavsiye')),
                            DropdownMenuItem(
                                value: 'rented', child: Text('Kiralanan')),
                          ],
                          onChanged: (value) =>
                              onFeatureChanged(value ?? 'all'),
                        ),
                        DropdownButton<String>(
                          value: reportEvent,
                          items: const [
                            DropdownMenuItem(
                                value: 'all', child: Text('Tüm Olaylar')),
                            DropdownMenuItem(
                                value: 'offers', child: Text('Teklifler')),
                            DropdownMenuItem(
                                value: 'comments', child: Text('Yorumlar')),
                            DropdownMenuItem(
                                value: 'ratings', child: Text('Puanlar')),
                            DropdownMenuItem(
                                value: 'sales', child: Text('Satışlar')),
                          ],
                          onChanged: (value) => onEventChanged(value ?? 'all'),
                        ),
                        if (report != null && report.sellerOptions.isNotEmpty)
                          DropdownButton<int?>(
                            value: reportSellerId,
                            items: [
                              const DropdownMenuItem<int?>(
                                  value: null, child: Text('Tüm Satıcılar')),
                              ...report.sellerOptions.map(
                                (seller) => DropdownMenuItem<int?>(
                                  value: seller.sellerId,
                                  child: Text(seller.sellerName),
                                ),
                              ),
                            ],
                            onChanged: onSellerChanged,
                          ),
                        FilledButton.icon(
                          onPressed: onLoadReport,
                          icon: const Icon(Icons.analytics_rounded),
                          label: const Text('Raporu Getir'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (loading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator()))
              else if (snapshot.hasError)
                Center(child: Text('Rapor yüklenemedi: ${snapshot.error}'))
              else if (report != null) ...[
                _AdminMetrics(report: report),
                const SizedBox(height: 16),
                _ReportSection(
                    title: 'Teklifler',
                    children: report.offers
                        .map((e) => _ReportLine(
                              title: e.listingTitle,
                              subtitle:
                                  '${e.customerName} · ${e.offerType} · ${e.status}',
                              trailing:
                                  NumberFormat('#,###', 'tr').format(e.amount),
                            ))
                        .toList()),
                const SizedBox(height: 16),
                _ReportSection(
                    title: 'Yorumlar',
                    children: report.comments
                        .map((e) => _ReportLine(
                              title: e.listingTitle,
                              subtitle:
                                  '${e.authorName} · ${DateFormat('dd MMM HH:mm', 'tr').format(e.createdAt.toLocal())}',
                              trailing: e.content,
                            ))
                        .toList()),
                const SizedBox(height: 16),
                _ReportSection(
                    title: 'Puanlar',
                    children: report.ratings
                        .map((e) => _ReportLine(
                              title: e.listingTitle,
                              subtitle:
                                  '${e.renterName} · İlan ${e.listingScore}/5 · Satıcı ${e.sellerScore}/5',
                              trailing: e.comment,
                            ))
                        .toList()),
                const SizedBox(height: 16),
                _ReportSection(
                    title: 'Satışlar',
                    children: report.sales
                        .map((e) => _ReportLine(
                              title: e.listingTitle,
                              subtitle:
                                  '${e.buyerName} · ${DateFormat('dd MMM HH:mm', 'tr').format(e.soldAt.toLocal())}',
                              trailing:
                                  NumberFormat('#,###', 'tr').format(e.amount),
                            ))
                        .toList()),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AdminListingsTab extends StatelessWidget {
  const _AdminListingsTab({
    required this.listingsFuture,
    required this.apiBaseUrl,
    required this.onRefresh,
  });

  final Future<List<Listing>> listingsFuture;
  final String apiBaseUrl;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###', 'tr');

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
                      aspectRatio: 1.35,
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
                              _MiniChip(
                                  text:
                                      '${money.format(item.monthlyPrice)} TL'),
                              if (item.isDailyRecommended)
                                const _MiniChip(text: 'Günlük'),
                              if (item.isAdminRecommended)
                                const _MiniChip(text: 'Admin'),
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => _toggle(
                                    context,
                                    () => AppScope.of(context)
                                        .api
                                        .toggleAdminRecommendation(item.id)),
                                child: Text(item.isAdminRecommended
                                    ? 'Admin Önerisini Kaldır'
                                    : 'Admin Önerisi Yap'),
                              ),
                              OutlinedButton(
                                onPressed: () => _toggle(
                                    context,
                                    () => AppScope.of(context)
                                        .api
                                        .toggleDailyRecommendation(item.id)),
                                child: Text(item.isDailyRecommended
                                    ? 'Günün Tavsiyesinden Kaldır'
                                    : 'Günün Tavsiyesi Yap'),
                              ),
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
                                  await _toggle(
                                      context,
                                      () => AppScope.of(context)
                                          .api
                                          .deleteListing(item.id));
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

  Future<void> _toggle(
      BuildContext context, Future<void> Function() action) async {
    try {
      await action();
      await onRefresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onRefresh,
    required this.onEdit,
  });

  final User user;
  final Future<void> Function() onRefresh;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                  radius: 22,
                  backgroundImage: user.profileImageUrl.isNotEmpty
                      ? NetworkImage(resolveImageUrl(
                          AppScope.of(context).api.baseUrl,
                          user.profileImageUrl))
                      : null,
                  child: user.profileImageUrl.isEmpty
                      ? Text(user.fullName.isNotEmpty ? user.fullName[0] : '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: const TextStyle(color: Color(0xFFA9B3C8))),
                    ],
                  ),
                ),
                _MiniChip(text: user.role),
                const SizedBox(width: 8),
                _MiniChip(text: user.isSellerApproved ? 'Satıcı' : 'Beklemede'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              user.bio.isEmpty ? 'Biyografi yok.' : user.bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onEdit,
                  child: const Text('Düzenle'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await AppScope.of(context)
                          .api
                          .setSellerApproval(user.id, !user.isSellerApproved);
                      await onRefresh();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: Text(user.isSellerApproved
                      ? 'Satıcı Onayını Kaldır'
                      : 'Satıcı Onayla'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await AppScope.of(context)
                          .api
                          .setAdminRole(user.id, user.role != 'Admin');
                      await onRefresh();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: Text(
                      user.role == 'Admin' ? 'Admini Kaldır' : 'Admin Yap'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Kullanıcıyı sil'),
                        content: Text('"${user.fullName}" hesabı silinsin mi?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Vazgeç'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Sil'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    try {
                      await AppScope.of(context).api.deleteAdminUser(user.id);
                      await onRefresh();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('$e')));
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
    );
  }
}

class _AdminMetrics extends StatelessWidget {
  const _AdminMetrics({required this.report});

  final AdminReportResponse report;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Metric(value: '${report.totalOffers}', label: 'Teklif'),
          _Metric(value: '${report.totalComments}', label: 'Yorum'),
          _Metric(value: '${report.totalRatings}', label: 'Puan'),
          _Metric(value: '${report.totalSales}', label: 'Satış'),
          _Metric(value: '${report.uniqueBuyers}', label: 'Alıcı'),
          _Metric(
              value: '${report.thisMonthOfferCount}', label: 'Bu Ay Teklif'),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (children.isEmpty) const Text('Kayıt yok.') else ...children,
        ],
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFFA9B3C8))),
            const SizedBox(height: 6),
            Text(trailing),
          ],
        ),
      ),
    );
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
  const _MiniChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
