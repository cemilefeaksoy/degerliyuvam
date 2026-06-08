import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/seller_profile.dart';
import '../../core/state/app_scope.dart';
import '../../core/utils/image_url.dart';
import '../../shared/ui.dart';
import '../listings/listing_detail_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({super.key, required this.sellerId});

  final int sellerId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final money = NumberFormat('#,###', 'tr');

    return Scaffold(
      appBar: AppBar(title: const Text('Satıcı Profili')),
      body: FutureBuilder<SellerProfileResponse>(
        future: controller.api.sellerProfile(sellerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Satıcı yüklenemedi: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final user = data.user;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              GlassPanel(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: user.profileImageUrl.isNotEmpty
                          ? NetworkImage(resolveImageUrl(
                              controller.api.baseUrl, user.profileImageUrl))
                          : null,
                      child: user.profileImageUrl.isEmpty
                          ? Text(user.fullName.isNotEmpty
                              ? user.fullName.substring(0, 1)
                              : '?')
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(user.bio.isEmpty ? 'Açıklama yok' : user.bio),
                          const SizedBox(height: 4),
                          Text(user.phoneNumber,
                              style: const TextStyle(color: Color(0xFFA9B3C8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Metric(value: '${data.totalListings}', label: 'İlan'),
                    _Metric(
                        value: '${data.rentedListings}', label: 'Kiralandı'),
                    _Metric(value: '${data.pendingOffers}', label: 'Bekleyen'),
                    _Metric(value: '%${data.conversionRate}', label: 'Dönüşüm'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'İlanlar',
                      subtitle: 'Satıcıya ait aktif ilanlar.',
                    ),
                    const SizedBox(height: 12),
                    ...data.listings.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.title),
                        subtitle: Text('${item.province} / ${item.district}'),
                        trailing: Text('${money.format(item.monthlyPrice)} TL'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  ListingDetailScreen(listingId: item.id)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
      width: 150,
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
