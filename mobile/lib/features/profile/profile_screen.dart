import 'package:flutter/material.dart';

import '../../core/state/app_scope.dart';
import '../../shared/ui.dart';
import '../../core/utils/image_url.dart';
import '../auth/login_screen.dart';
import '../admin/admin_center_screen.dart';
import '../info/info_pages.dart';
import 'edit_profile_screen.dart';
import '../listings/listing_editor_screen.dart';
import '../seller/seller_center_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                const CircleAvatar(
                    radius: 30, child: Icon(Icons.person_rounded, size: 30)),
                const SizedBox(height: 12),
                Text(
                  'Profilinize ulaşmak için giriş yapın',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text('Giriş Yap'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text('Kayıt Ol'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FutureBuilder(
      future: controller.api.me(),
      builder: (context, snapshot) {
        final current = snapshot.data ?? user;
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            GlassPanel(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundImage: current.profileImageUrl.isNotEmpty
                        ? NetworkImage(resolveImageUrl(
                            controller.api.baseUrl, current.profileImageUrl))
                        : null,
                    child: current.profileImageUrl.isEmpty
                        ? Text(current.fullName.isNotEmpty
                            ? current.fullName.substring(0, 1)
                            : '?')
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          current.email,
                          style: const TextStyle(color: Color(0xFFA9B3C8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          current.role,
                          style: const TextStyle(
                              color: Color(0xFFF0CC7D),
                              fontWeight: FontWeight.w700),
                        ),
                      ],
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
                    title: 'Hesap İşlemleri',
                    subtitle: 'Profil, satıcı ve oturum işlemleri.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()),
                        ),
                        child: const Text('Profili Düzenle'),
                      ),
                      if (current.role == 'Admin')
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AdminCenterScreen()),
                          ),
                          child: const Text('Admin Paneli'),
                        ),
                      if (current.isSellerApproved || current.role == 'Admin')
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SellerCenterScreen()),
                          ),
                          child: const Text('Satıcı Merkezi'),
                        ),
                      if (current.isSellerApproved || current.role == 'Admin')
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ListingEditorScreen()),
                          ),
                          child: const Text('İlan Ver'),
                        ),
                      TextButton(
                        onPressed: () async {
                          await controller.logout();
                        },
                        child: const Text('Çıkış Yap'),
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
                    title: 'Yardım ve Bilgi',
                    subtitle: 'Kurumsal ve bilgilendirici sayfalar.',
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
                          MaterialPageRoute(builder: (_) => const FaqScreen()),
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
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Hakkımda',
                    subtitle: 'Profil biyografisi ve iletişim bilgileri.',
                  ),
                  const SizedBox(height: 12),
                  Text(current.bio.isEmpty
                      ? 'Henüz bir açıklama eklenmemiş.'
                      : current.bio),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Telefon', value: current.phoneNumber),
                  _InfoRow(
                      label: 'Onay',
                      value: current.isSellerApproved
                          ? 'Satıcı onaylı'
                          : 'Beklemede'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child:
                Text(label, style: const TextStyle(color: Color(0xFFA9B3C8))),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
