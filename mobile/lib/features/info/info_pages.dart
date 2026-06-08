import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/state/app_scope.dart';
import '../../shared/ui.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Değerli Yuvam',
                  subtitle:
                      'Emlak ilanı, mesajlaşma ve yönetim akışlarını tek merkezde buluşturan platform.',
                ),
                const SizedBox(height: 16),
                Text(
                  'Platform; kullanıcı kayıt/giriş, ilan listeleme, ilan detayları, teklif verme, kiralama talebi, yorum, puanlama, satıcı merkezi ve admin yönetimi gibi tüm temel emlak işlemlerini bir araya getirir.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _MiniInfo(label: 'MVC Backend', value: 'ASP.NET Core'),
                    _MiniInfo(label: 'Mobil', value: 'Flutter'),
                    _MiniInfo(label: 'Veri Tabanı', value: 'SQLite'),
                    _MiniInfo(label: 'Kimlik', value: 'Session + Cookie'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SectionHeader(
                  title: 'Ne Sunuyor?',
                  subtitle: 'Kullanıcı, satıcı ve yönetici akışları.',
                ),
                SizedBox(height: 12),
                _Bullet(text: 'İlan görüntüleme ve filtreleme'),
                _Bullet(text: 'Teklif ve kiralama talebi'),
                _Bullet(text: 'Mesajlaşma ve okunmamış sayaçlar'),
                _Bullet(text: 'Satıcı ilan yönetimi'),
                _Bullet(text: 'Admin kullanıcı ve rapor yönetimi'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İletişim')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SectionHeader(
                  title: 'Bize Ulaşın',
                  subtitle:
                      'Sorular, öneriler ve destek talepleri için iletişim kanalları.',
                ),
                SizedBox(height: 12),
                _ContactLine(
                    icon: Icons.phone_rounded,
                    title: 'Telefon',
                    value: '+90 (555) 000 00 00'),
                _ContactLine(
                    icon: Icons.email_rounded,
                    title: 'E-posta',
                    value: 'destek@degerliyuvam.com'),
                _ContactLine(
                    icon: Icons.location_on_rounded,
                    title: 'Adres',
                    value: 'Türkiye'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Mesaj Gönder',
                  subtitle: 'İstersen kısa bir form bırakabilirsin.',
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Ad Soyad')),
                const SizedBox(height: 10),
                TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'E-posta')),
                const SizedBox(height: 10),
                TextField(
                    controller: _subject,
                    decoration: const InputDecoration(labelText: 'Konu')),
                const SizedBox(height: 10),
                TextField(
                    controller: _message,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Mesaj')),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Mesajınız alındı. En kısa sürede dönüş yapılacaktır.')),
                      );
                    },
                    child: const Text('Gönder'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_FaqItem>[
      _FaqItem(
        question: 'Nasıl kayıt olurum?',
        answer:
            'Giriş/Kayıt ekranından ad, e-posta, telefon ve şifre bilgilerini girerek kayıt olabilirsin.',
      ),
      _FaqItem(
        question: 'İlan vermek için ne gerekiyor?',
        answer:
            'Satıcı onayı gerekiyor. Admin onayı sonrası satıcı merkezi üzerinden ilan verebilirsin.',
      ),
      _FaqItem(
        question: 'Teklif ve kiralama talebi nasıl çalışır?',
        answer:
            'İlan detay ekranından teklif gönderebilir veya kiralama talebi oluşturabilirsin. Bu kayıtlar satıcı panelinde görünür.',
      ),
      _FaqItem(
        question: 'Mesajlar nerede?',
        answer:
            'Alt menüdeki Mesajlar sekmesi üzerinden konuşmalarına ulaşabilirsin.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Sık Sorulan Sorular')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Yardım Merkezi',
                  subtitle: 'En sık sorulan sorular ve cevaplar.',
                ),
                const SizedBox(height: 8),
                ...items.map(
                  (item) => ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(item.question,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    children: [
                      Text(item.answer,
                          style: const TextStyle(
                              color: Color(0xFFC8D4F0), height: 1.55)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik Politikası')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Gizlilik',
                  subtitle:
                      'Kullanıcı verileri ve oturum bilgileri ile ilgili kısa bilgilendirme.',
                ),
                SizedBox(height: 12),
                _Bullet(text: 'Oturum bilgileri backend session ile tutulur.'),
                _Bullet(
                    text:
                        'Remember me seçilirse cookie ile 180 güne kadar oturum korunabilir.'),
                _Bullet(
                    text:
                        'Mesaj, ilan ve profil bilgileri yalnızca uygulama akışı için kullanılır.'),
                _Bullet(
                    text:
                        'Kullanıcı verileri MVC backend üzerinden servis edilir.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RentalPaymentScreen extends StatefulWidget {
  const RentalPaymentScreen({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.monthlyPrice,
  });

  final int listingId;
  final String listingTitle;
  final num monthlyPrice;

  @override
  State<RentalPaymentScreen> createState() => _RentalPaymentScreenState();
}

class _RentalPaymentScreenState extends State<RentalPaymentScreen> {
  final _cardHolder = TextEditingController();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _cardHolder.dispose();
    _cardNumber.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###', 'tr');

    return Scaffold(
      appBar: AppBar(title: const Text('Kiralama / Ödeme')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Ödeme Bilgileri',
                  subtitle: 'Kiralama talebi için kart bilgilerini gir.',
                ),
                const SizedBox(height: 12),
                Text(widget.listingTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${money.format(widget.monthlyPrice)} TL / ay',
                    style: const TextStyle(color: Color(0xFFF0CC7D))),
                const SizedBox(height: 16),
                TextField(
                    controller: _cardHolder,
                    decoration: const InputDecoration(
                        labelText: 'Kart Üzerindeki İsim')),
                const SizedBox(height: 10),
                TextField(
                    controller: _cardNumber,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Kart Numarası')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: _expiry,
                            decoration: const InputDecoration(
                                labelText: 'Son Kullanım'))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                            controller: _cvv,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'CVV'))),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            final last4 = _cardNumber.text
                                .replaceAll(RegExp(r'[^0-9]'), '');
                            if (last4.length < 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Kart numarasının en az son 4 hanesini girin.')),
                              );
                              return;
                            }
                            setState(() => _loading = true);
                            try {
                              await AppScope.of(context)
                                  .api
                                  .createRentalRequest(
                                    listingId: widget.listingId,
                                    cardLast4:
                                        last4.substring(last4.length - 4),
                                  );
                              if (mounted) {
                                Navigator.of(context).pop(true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Kiralama talebi gönderildi.')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')));
                              }
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                    child: Text(_loading ? 'Gönderiliyor...' : 'Talebi Gönder'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Color(0xFFA9B3C8), fontSize: 11)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ',
              style: TextStyle(color: Color(0xFFF0CC7D), fontSize: 18)),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFFF0CC7D)),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}

class _FaqItem {
  _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}
