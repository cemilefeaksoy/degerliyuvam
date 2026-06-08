import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/dashboard.dart';
import '../../core/state/app_scope.dart';
import '../../shared/ui.dart';
import '../listings/listing_detail_screen.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Satıcı Paneli')),
      body: FutureBuilder<SellerDashboard>(
        future: controller.api.sellerDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Panel yüklenemedi: ${snapshot.error}'));
          }

          final dashboard = snapshot.data!;
          final money = NumberFormat('#,###', 'tr');

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Performans',
                      subtitle: 'İlanlar, teklifler ve dönüşüm oranı.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricCard(
                            value: '${dashboard.totalListings}',
                            label: 'Toplam İlan'),
                        _MetricCard(
                            value: '${dashboard.rentedListings}',
                            label: 'Kiralanan'),
                        _MetricCard(
                            value: '${dashboard.pendingOffers}',
                            label: 'Bekleyen Teklif'),
                        _MetricCard(
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
                      title: 'İlanlarım',
                      subtitle: 'İlan detayları ve satış / kiralama durumları.',
                    ),
                    const SizedBox(height: 12),
                    ...dashboard.myListings.map(
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
              const SizedBox(height: 16),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Gelen Teklifler',
                      subtitle: 'Son teklifler ve kiralama talepleri.',
                    ),
                    const SizedBox(height: 12),
                    ...dashboard.incomingOffers.map(
                      (offer) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(offer.listingTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(offer.fromUserName,
                                  style: const TextStyle(
                                      color: Color(0xFFA9B3C8))),
                              const SizedBox(height: 4),
                              Text(
                                '${money.format(offer.amount)} TL · ${offer.type} · ${offer.status}',
                                style: const TextStyle(
                                    color: Color(0xFFF0CC7D),
                                    fontWeight: FontWeight.w700),
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
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label});

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
