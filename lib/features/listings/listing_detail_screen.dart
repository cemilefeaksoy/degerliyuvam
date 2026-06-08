import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/listing.dart';
import '../../core/models/listing_detail.dart';
import '../../core/network/api_client.dart';
import '../../core/state/app_scope.dart';
import '../../shared/ui.dart';
import '../auth/login_screen.dart';
import '../info/info_pages.dart';
import '../messages/conversation_screen.dart';
import '../profile/seller_profile_screen.dart';
import 'listing_editor_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final int listingId;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final PageController _galleryController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final api = controller.api;
    final money = NumberFormat('#,###', 'tr');

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ListingDetailResponse>(
          future: api.getListing(widget.listingId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('İlan yüklenemedi: ${snapshot.error}'));
            }

            final data = snapshot.data!;
            final listing = data.listing;
            final gallery = data.galleryImages.isEmpty
                ? [listing.imageUrl]
                : data.galleryImages;
            final owner = data.owner;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 340,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _galleryController,
                          onPageChanged: (value) =>
                              setState(() => _page = value),
                          itemCount: gallery.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              gallery[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF10151E),
                                child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 42),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _HeroBadge(
                                  label: listing.purposeLabel.toUpperCase()),
                              if (listing.isRented)
                                const _HeroBadge(label: 'KİRALANDI'),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _PageCounter(
                              current: _page + 1, total: gallery.length),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listing.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            height: 1.15,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${listing.province} / ${listing.district}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFFA9B3C8),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${money.format(listing.monthlyPrice)} TL',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: const Color(0xFFF0CC7D),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatChip(label: listing.propertyType),
                              _StatChip(label: listing.roomCount),
                              _StatChip(label: '${listing.netSquareMeters} m²'),
                              _StatChip(
                                  label:
                                      '${listing.floor}/${listing.totalFloors} Kat'),
                              _StatChip(
                                  label: '${listing.bathroomCount} Banyo'),
                              _StatChip(label: listing.heatingType),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            listing.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  height: 1.65,
                                  color: const Color(0xFFDCE4F6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: GlassPanel(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _Amenity(label: 'Eşyalı', enabled: listing.furnished),
                          _Amenity(label: 'Balkon', enabled: listing.balcony),
                          _Amenity(label: 'Asansör', enabled: listing.elevator),
                          _Amenity(label: 'Otopark', enabled: listing.parking),
                          _Amenity(
                              label: 'Site İçinde', enabled: listing.inSite),
                          _Amenity(label: 'Havuz', enabled: listing.hasPool),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'İşlem Başlat',
                            subtitle:
                                'Teklif ver, kiralama talebi oluştur veya satıcıya mesaj at.',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton(
                                onPressed: data.canOffer
                                    ? () => _showOfferSheet(
                                        context, api, listing.id)
                                    : controller.currentUser == null
                                        ? () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const LoginScreen()),
                                            )
                                        : null,
                                child: const Text('Teklif Ver'),
                              ),
                              OutlinedButton(
                                onPressed: data.canRent
                                    ? () => _openRentalPayment(context, listing)
                                    : controller.currentUser == null
                                        ? () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const LoginScreen()),
                                            )
                                        : null,
                                child: const Text('Kiralama Talebi'),
                              ),
                              OutlinedButton(
                                onPressed: data.canRate
                                    ? () => _showRatingSheet(
                                        context, api, listing.id)
                                    : controller.currentUser == null
                                        ? () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const LoginScreen()),
                                            )
                                        : null,
                                child: const Text('Puanla'),
                              ),
                              OutlinedButton(
                                onPressed: owner == null
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ConversationScreen(
                                              partnerId: owner.id,
                                              partnerName: owner.fullName,
                                            ),
                                          ),
                                        ),
                                child: const Text('Mesaj At'),
                              ),
                              TextButton(
                                onPressed: owner == null
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => SellerProfileScreen(
                                                sellerId: owner.id),
                                          ),
                                        ),
                                child: const Text('Satıcı Profili'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (data.canEdit || data.isAdmin)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: 'Yönetim Aksiyonları',
                              subtitle: 'İlanı düzenle, sil veya öne çıkar.',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (data.canEdit)
                                  FilledButton(
                                    onPressed: () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (_) => ListingEditorScreen(
                                                listingId: listing.id)))
                                        .then((_) {
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    }),
                                    child: const Text('Düzenle'),
                                  ),
                                if (data.canEdit)
                                  OutlinedButton(
                                    onPressed: () => _deleteListing(
                                        context, api, listing.id),
                                    child: const Text('Sil'),
                                  ),
                                if (data.isAdmin)
                                  OutlinedButton(
                                    onPressed: () => _toggleAdminRecommendation(
                                        api, listing.id),
                                    child: Text(listing.isAdminRecommended
                                        ? 'Admin Önerisini Kaldır'
                                        : 'Admin Önerisi Yap'),
                                  ),
                                if (data.isAdmin)
                                  OutlinedButton(
                                    onPressed: () => _toggleDailyRecommendation(
                                        api, listing.id),
                                    child: Text(listing.isDailyRecommended
                                        ? 'Günün Tavsiyesinden Kaldır'
                                        : 'Günün Tavsiyesi Yap'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Puanlar',
                            subtitle: 'İlan ve satıcı ortalamaları.',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ScoreCard(
                                  title: 'İlan Puanı',
                                  value: data.listingRatingAverage
                                      .toStringAsFixed(1),
                                  count: data.listingRatingCount,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ScoreCard(
                                  title: 'Satıcı Puanı',
                                  value: data.sellerRatingAverage
                                      .toStringAsFixed(1),
                                  count: data.sellerRatingCount,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Teklifler',
                            subtitle:
                                'İlan sahibinin gördüğü tüm teklif kayıtları.',
                          ),
                          const SizedBox(height: 12),
                          if (data.offers.isEmpty)
                            const Text('Bu ilan için teklif kaydı yok.')
                          else
                            ...data.offers.map(
                              (offer) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.08)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              offer.fromUserName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          Text(
                                            '${money.format(offer.amount)} TL',
                                            style: const TextStyle(
                                                color: Color(0xFFF0CC7D),
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${offer.type} · ${offer.status}',
                                        style: const TextStyle(
                                            color: Color(0xFFA9B3C8),
                                            fontSize: 12),
                                      ),
                                      if (offer.note.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(offer.note),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Detay Bilgiler',
                            subtitle:
                                'Web sürümündeki zengin özellik seti mobilde de burada.',
                          ),
                          const SizedBox(height: 12),
                          _FeatureRow(
                              label: 'Brüt / Net',
                              value:
                                  '${listing.grossSquareMeters} m² / ${listing.netSquareMeters} m²'),
                          _FeatureRow(
                              label: 'Bina Yaşı',
                              value: '${listing.buildingAge}'),
                          _FeatureRow(
                              label: 'Aidat',
                              value: '${money.format(listing.dues)} TL'),
                          _FeatureRow(
                              label: 'Depozito',
                              value: '${money.format(listing.deposit)} TL'),
                          _FeatureRow(
                              label: 'İlan Sahibi', value: listing.ownerName),
                          _FeatureRow(
                              label: 'Yorum Yapılabilir',
                              value: data.canComment ? 'Evet' : 'Hayır'),
                          _FeatureRow(
                              label: 'Puan Verilebilir',
                              value: data.canRate ? 'Evet' : 'Hayır'),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Yorumlar',
                            subtitle: 'İlanı kiralayan kullanıcıların notları.',
                          ),
                          const SizedBox(height: 12),
                          if (data.comments.isEmpty)
                            const Text('Henüz yorum yok.')
                          else
                            ...data.comments.map(
                              (comment) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.08)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(comment.authorName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ),
                                          Text(
                                            DateFormat('dd MMM HH:mm', 'tr')
                                                .format(comment.createdAt
                                                    .toLocal()),
                                            style: const TextStyle(
                                                color: Color(0xFFA9B3C8),
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(comment.content),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Değerlendirmeler',
                            subtitle: 'Puan dağılımı ve kullanıcı yorumları.',
                          ),
                          const SizedBox(height: 12),
                          if (data.ratings.isEmpty)
                            const Text('Henüz puanlama yok.')
                          else
                            ...data.ratings.map(
                              (rating) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.08)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(rating.renterName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ),
                                          Text(
                                            DateFormat('dd MMM HH:mm', 'tr')
                                                .format(
                                                    rating.createdAt.toLocal()),
                                            style: const TextStyle(
                                                color: Color(0xFFA9B3C8),
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'İlan: ${rating.listingScore} / 5 · Satıcı: ${rating.sellerScore} / 5',
                                        style: const TextStyle(
                                            color: Color(0xFFF0CC7D),
                                            fontWeight: FontWeight.w700),
                                      ),
                                      if (rating.comment.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(rating.comment),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showOfferSheet(
      BuildContext context, ApiClient api, int listingId) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Teklif Ver',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Teklif tutarı'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Notunuz'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        await api.createOffer(
                          listingId: listingId,
                          amount: double.tryParse(amountController.text) ?? 0,
                          note: noteController.text,
                        );
                        if (mounted) {
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Teklif gönderildi.')),
                          );
                        }
                      } on ApiException catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      }
                    },
                    child: const Text('Gönder'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openRentalPayment(BuildContext context, Listing listing) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RentalPaymentScreen(
          listingId: listing.id,
          listingTitle: listing.title,
          monthlyPrice: listing.monthlyPrice,
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _showRatingSheet(
      BuildContext context, ApiClient api, int listingId) async {
    final listingScore = ValueNotifier<int>(5);
    final sellerScore = ValueNotifier<int>(5);
    final commentController = TextEditingController();

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Puan ve Yorum',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _ScorePicker(title: 'İlan Puanı', notifier: listingScore),
                const SizedBox(height: 10),
                _ScorePicker(title: 'Satıcı Puanı', notifier: sellerScore),
                const SizedBox(height: 10),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(hintText: 'Yorum (opsiyonel)'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        await api.addRating(
                          listingId: listingId,
                          listingScore: listingScore.value,
                          sellerScore: sellerScore.value,
                          comment: commentController.text,
                        );
                        if (mounted) {
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Puan kaydedildi.')),
                          );
                        }
                      } on ApiException catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      }
                    },
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteListing(
      BuildContext context, ApiClient api, int id) async {
    try {
      await api.deleteListing(id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _toggleAdminRecommendation(ApiClient api, int id) async {
    try {
      await api.toggleAdminRecommendation(id);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _toggleDailyRecommendation(ApiClient api, int id) async {
    try {
      await api.toggleDailyRecommendation(id);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      radius: 999,
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }
}

class _PageCounter extends StatelessWidget {
  const _PageCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      radius: 999,
      child: Text(
        '$current / $total',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _Amenity extends StatelessWidget {
  const _Amenity({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: enabled
            ? const Color(0x1A39B885)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: enabled
              ? const Color(0x5539B885)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: enabled ? const Color(0xFFC6F7DF) : const Color(0xFFA9B3C8),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard(
      {required this.title, required this.value, required this.count});

  final String title;
  final String value;
  final int count;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Color(0xFFA9B3C8), fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                color: Color(0xFFF0CC7D),
                fontSize: 26,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('$count değerlendirme',
              style: const TextStyle(color: Color(0xFFA9B3C8), fontSize: 11)),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFA9B3C8), fontSize: 12.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePicker extends StatelessWidget {
  const _ScorePicker({required this.title, required this.notifier});

  final String title;
  final ValueNotifier<int> notifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final score = index + 1;
                return IconButton(
                  onPressed: () => notifier.value = score,
                  icon: Icon(
                    score <= value
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFF0CC7D),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
