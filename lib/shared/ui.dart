import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/listing.dart';
import '../core/utils/image_url.dart';

class LuxuryBackdrop extends StatelessWidget {
  const LuxuryBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _LuxuryBackground(),
        child,
      ],
    );
  }
}

class _LuxuryBackground extends StatelessWidget {
  const _LuxuryBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.85, -0.85),
            radius: 1.4,
            colors: [
              const Color(0xFFD6B367).withValues(alpha: 0.13),
              Colors.transparent,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -120,
              child:
                  _Glow(color: const Color(0xFFD6B367).withValues(alpha: 0.14)),
            ),
            Positioned(
              bottom: -140,
              right: -140,
              child:
                  _Glow(color: const Color(0xFF78D2DE).withValues(alpha: 0.12)),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF090B10),
                      Color(0xFF0B1017),
                      Color(0xFF090C14),
                    ],
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

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = 22,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF3E2B9),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFA9B3C8),
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.baseUrl,
    this.onTap,
  });

  final Listing listing;
  final String baseUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###', 'tr');
    final image = resolveImageUrl(baseUrl, listing.imageUrl);
    final gallery =
        listing.galleryImages.isNotEmpty ? listing.galleryImages : [image];

    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        padding: EdgeInsets.zero,
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: gallery.isEmpty || gallery.first.isEmpty
                        ? Container(color: const Color(0xFF121722))
                        : gallery.length == 1
                            ? Image.network(gallery.first, fit: BoxFit.cover)
                            : PageView.builder(
                                itemCount: gallery.length,
                                itemBuilder: (context, index) {
                                  return Image.network(gallery[index],
                                      fit: BoxFit.cover);
                                },
                              ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _Badge(
                      label: listing.purposeLabel.toUpperCase(),
                      tone: listing.purposeLabel == 'Satılık'
                          ? const Color(0xFF1561BC)
                          : const Color(0xFF39B885),
                    ),
                  ),
                  if (listing.isRented)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child:
                          _Badge(label: 'KİRALANDI', tone: Color(0xFFD43F4F)),
                    ),
                  if (listing.isDailyRecommended)
                    Positioned(
                      top: listing.isRented ? 46 : 10,
                      right: 10,
                      child: const _Badge(
                          label: 'GÜNÜN TAVSİYESİ', tone: Color(0xFF78D2DE)),
                    ),
                  if (listing.isAdminRecommended)
                    const Positioned(
                      bottom: 10,
                      left: 10,
                      child: _Badge(label: 'ÖNERİLEN', tone: Color(0xFFD6B367)),
                    ),
                  if (gallery.length > 1)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: _Badge(
                          label: '${gallery.length} FOTO',
                          tone: const Color(0xFF78D2DE)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _TinyChip(label: listing.propertyType),
                      _TinyChip(label: listing.roomCount),
                      _TinyChip(label: '${listing.netSquareMeters} m²'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${listing.province} / ${listing.district}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFA9B3C8),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${money.format(listing.monthlyPrice)} TL',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFFF0CC7D),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              listing.purposeLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFFA9B3C8),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFD6B367)),
                    ],
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: Color(0xFF16110A),
        ),
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  const _TinyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
