import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/listing_detail.dart';
import '../../core/models/listing_form.dart';
import '../../core/state/app_scope.dart';
import '../../core/utils/image_url.dart';
import '../../shared/ui.dart';

class ListingEditorScreen extends StatefulWidget {
  const ListingEditorScreen({super.key, this.listingId});

  final int? listingId;

  @override
  State<ListingEditorScreen> createState() => _ListingEditorScreenState();
}

class _ListingEditorScreenState extends State<ListingEditorScreen> {
  final _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _province = TextEditingController();
  final _district = TextEditingController();
  final _propertyType = TextEditingController(text: 'Daire');
  final _listingPurpose = TextEditingController(text: 'Kiralık');
  final _roomCount = TextEditingController(text: '2+1');
  final _gross = TextEditingController(text: '100');
  final _net = TextEditingController(text: '80');
  final _age = TextEditingController(text: '5');
  final _floor = TextEditingController(text: '1');
  final _totalFloors = TextEditingController(text: '5');
  final _bathrooms = TextEditingController(text: '1');
  final _heatingType = TextEditingController(text: 'Kombi Doğalgaz');
  final _monthlyPrice = TextEditingController(text: '25000');
  final _deposit = TextEditingController(text: '0');
  final _dues = TextEditingController(text: '0');
  final _coverImage = TextEditingController();
  final _galleryImages = TextEditingController();
  bool _furnished = false;
  bool _balcony = false;
  bool _elevator = false;
  bool _parking = false;
  bool _inSite = false;
  bool _hasPool = false;
  bool _isAdminRecommended = false;
  bool _loading = false;
  bool _loaded = false;
  ListingDetailResponse? _detail;
  final List<_LocalImage> _localImages = [];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _province.dispose();
    _district.dispose();
    _propertyType.dispose();
    _listingPurpose.dispose();
    _roomCount.dispose();
    _gross.dispose();
    _net.dispose();
    _age.dispose();
    _floor.dispose();
    _totalFloors.dispose();
    _bathrooms.dispose();
    _heatingType.dispose();
    _monthlyPrice.dispose();
    _deposit.dispose();
    _dues.dispose();
    _coverImage.dispose();
    _galleryImages.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    if (widget.listingId != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final api = AppScope.of(context).api;
    try {
      final detail = await api.getListing(widget.listingId!);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        final listing = detail.listing;
        _title.text = listing.title;
        _description.text = listing.description;
        _province.text = listing.province;
        _district.text = listing.district;
        _propertyType.text = listing.propertyType;
        _listingPurpose.text = listing.listingPurpose;
        _roomCount.text = listing.roomCount;
        _gross.text = listing.grossSquareMeters.toString();
        _net.text = listing.netSquareMeters.toString();
        _age.text = listing.buildingAge.toString();
        _floor.text = listing.floor.toString();
        _totalFloors.text = listing.totalFloors.toString();
        _bathrooms.text = listing.bathroomCount.toString();
        _heatingType.text = listing.heatingType;
        _monthlyPrice.text = listing.monthlyPrice.toString();
        _deposit.text = listing.deposit.toString();
        _dues.text = listing.dues.toString();
        _coverImage.text = detail.galleryImages.isNotEmpty
            ? detail.galleryImages.first
            : listing.imageUrl;
        _galleryImages.text = detail.galleryImages.length > 1
            ? detail.galleryImages.skip(1).join('\n')
            : '';
        _furnished = listing.furnished;
        _balcony = listing.balcony;
        _elevator = listing.elevator;
        _parking = listing.parking;
        _inSite = listing.inSite;
        _hasPool = listing.hasPool;
        _isAdminRecommended = listing.isAdminRecommended;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('İlan yüklenemedi: $e')));
    }
  }

  List<String> _parseGallery() {
    final values = <String>[];
    void add(String value) {
      final normalized = value.trim();
      if (normalized.isNotEmpty && !values.contains(normalized)) {
        values.add(normalized);
      }
    }

    add(_coverImage.text);
    for (final line in _galleryImages.text.split(RegExp(r'[\n,]'))) {
      add(line);
    }
    return values;
  }

  Future<void> _pickGalleryImages() async {
    try {
      final files = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (files.isEmpty) return;
      final images = <_LocalImage>[];
      for (final file in files) {
        images
            .add(_LocalImage(name: file.name, bytes: await file.readAsBytes()));
      }
      if (mounted) setState(() => _localImages.addAll(images));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraflar seçilemedi: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null) return;
      final image =
          _LocalImage(name: file.name, bytes: await file.readAsBytes());
      if (mounted) setState(() => _localImages.add(image));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera açılamadı: $e')),
        );
      }
    }
  }

  Future<List<String>> _uploadLocalImages() async {
    final api = AppScope.of(context).api;
    final uploaded = <String>[];
    for (final image in _localImages) {
      uploaded.add(
        await api.uploadImage(
          bytes: image.bytes,
          fileName: image.name,
          category: 'listings',
        ),
      );
    }
    return uploaded;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isEdit = widget.listingId != null;
    final gallery = _parseGallery();

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'İlan Düzenle' : 'Yeni İlan')),
      body: SafeArea(
        child: _loaded && widget.listingId != null && _detail == null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'İlan Bilgileri',
                            subtitle:
                                'Başlık, konum, fiyat ve teknik alanları doldurun.',
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _title,
                            decoration:
                                const InputDecoration(labelText: 'Başlık'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Başlık gerekli'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _description,
                            maxLines: 4,
                            decoration:
                                const InputDecoration(labelText: 'Açıklama'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Açıklama gerekli'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _province,
                                  decoration:
                                      const InputDecoration(labelText: 'İl'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _district,
                                  decoration:
                                      const InputDecoration(labelText: 'İlçe'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _propertyType,
                                  decoration: const InputDecoration(
                                      labelText: 'Gayrimenkul Tipi'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _listingPurpose,
                                  decoration: const InputDecoration(
                                      labelText: 'İlan Türü'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                  child: TextFormField(
                                      controller: _roomCount,
                                      decoration: const InputDecoration(
                                          labelText: 'Oda Sayısı'))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: TextFormField(
                                      controller: _heatingType,
                                      decoration: const InputDecoration(
                                          labelText: 'Isıtma'))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                  child: TextFormField(
                                      controller: _gross,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Brüt m²'))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: TextFormField(
                                      controller: _net,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Net m²'))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                  child: TextFormField(
                                      controller: _age,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Bina Yaşı'))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: TextFormField(
                                      controller: _floor,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Bulunduğu Kat'))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: TextFormField(
                                      controller: _totalFloors,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Kat Sayısı'))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                  child: TextFormField(
                                      controller: _bathrooms,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Banyo'))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: TextFormField(
                                      controller: _monthlyPrice,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Fiyat'))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: TextFormField(
                                      controller: _deposit,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Depozito'))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: TextFormField(
                                      controller: _dues,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Aidat'))),
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
                            title: 'Özellikler',
                            subtitle: 'Konfor ve site özelliklerini seçin.',
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _CheckChip(
                                  label: 'Eşyalı',
                                  value: _furnished,
                                  onChanged: (v) =>
                                      setState(() => _furnished = v)),
                              _CheckChip(
                                  label: 'Balkon',
                                  value: _balcony,
                                  onChanged: (v) =>
                                      setState(() => _balcony = v)),
                              _CheckChip(
                                  label: 'Asansör',
                                  value: _elevator,
                                  onChanged: (v) =>
                                      setState(() => _elevator = v)),
                              _CheckChip(
                                  label: 'Otopark',
                                  value: _parking,
                                  onChanged: (v) =>
                                      setState(() => _parking = v)),
                              _CheckChip(
                                  label: 'Site İçinde',
                                  value: _inSite,
                                  onChanged: (v) =>
                                      setState(() => _inSite = v)),
                              _CheckChip(
                                  label: 'Havuz',
                                  value: _hasPool,
                                  onChanged: (v) =>
                                      setState(() => _hasPool = v)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (controller.currentUser?.role == 'Admin')
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _isAdminRecommended,
                              onChanged: (value) =>
                                  setState(() => _isAdminRecommended = value),
                              title: const Text('Admin önerisi'),
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
                            title: 'Fotoğraflar',
                            subtitle:
                                'Galeriden seçin, kamerayla çekin veya görsel URL’si ekleyin.',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: _loading ? null : _pickGalleryImages,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Galeriden Seç'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _loading ? null : _takePhoto,
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Fotoğraf Çek'),
                              ),
                            ],
                          ),
                          if (_localImages.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 116,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _localImages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final image = _localImages[index];
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          image.bytes,
                                          width: 116,
                                          height: 116,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: IconButton.filled(
                                          tooltip: 'Fotoğrafı kaldır',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => setState(() =>
                                              _localImages.removeAt(index)),
                                          icon: const Icon(Icons.close_rounded,
                                              size: 18),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _coverImage,
                            decoration: const InputDecoration(
                                labelText: 'Kapak Fotoğraf URL'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _galleryImages,
                            maxLines: 6,
                            decoration: const InputDecoration(
                                labelText:
                                    'Ek Fotoğraf URL’leri (her satır bir URL)'),
                          ),
                          const SizedBox(height: 14),
                          if (gallery.isNotEmpty)
                            SizedBox(
                              height: 180,
                              child: PageView.builder(
                                itemCount: gallery.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        resolveImageUrl(controller.api.baseUrl,
                                            gallery[index]),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: const Color(0xFF10141C),
                                          child: const Icon(Icons
                                              .image_not_supported_outlined),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _loading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final existingGallery = _parseGallery();
                              if (existingGallery.isEmpty &&
                                  _localImages.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'En az bir fotoğraf seçin veya URL girin.')));
                                return;
                              }

                              setState(() => _loading = true);
                              try {
                                final uploadedImages =
                                    await _uploadLocalImages();
                                final gallery = <String>[
                                  ...uploadedImages,
                                  ...existingGallery.where(
                                      (item) => !uploadedImages.contains(item)),
                                ];
                                final draft = ListingDraft(
                                  id: widget.listingId,
                                  ownerUserId: controller.currentUser?.id,
                                  title: _title.text,
                                  description: _description.text,
                                  province: _province.text,
                                  district: _district.text,
                                  propertyType: _propertyType.text,
                                  listingPurpose: _listingPurpose.text,
                                  roomCount: _roomCount.text,
                                  grossSquareMeters:
                                      int.tryParse(_gross.text) ?? 0,
                                  netSquareMeters: int.tryParse(_net.text) ?? 0,
                                  buildingAge: int.tryParse(_age.text) ?? 0,
                                  floor: int.tryParse(_floor.text) ?? 0,
                                  totalFloors:
                                      int.tryParse(_totalFloors.text) ?? 0,
                                  bathroomCount:
                                      int.tryParse(_bathrooms.text) ?? 1,
                                  heatingType: _heatingType.text,
                                  furnished: _furnished,
                                  balcony: _balcony,
                                  elevator: _elevator,
                                  parking: _parking,
                                  inSite: _inSite,
                                  hasPool: _hasPool,
                                  monthlyPrice:
                                      num.tryParse(_monthlyPrice.text) ?? 0,
                                  deposit: num.tryParse(_deposit.text) ?? 0,
                                  dues: num.tryParse(_dues.text) ?? 0,
                                  imageUrl: gallery.first,
                                  imageUrls: gallery,
                                  isAdminRecommended: _isAdminRecommended,
                                );

                                final savedListing = widget.listingId == null
                                    ? await controller.api.createListing(draft)
                                    : await controller.api.updateListing(draft);

                                if (mounted) {
                                  Navigator.of(context).pop(savedListing);
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
                      icon: const Icon(Icons.save_rounded),
                      label: Text(_loading
                          ? 'Kaydediliyor...'
                          : (isEdit ? 'Güncelle' : 'Yayınla')),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _LocalImage {
  const _LocalImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class _CheckChip extends StatelessWidget {
  const _CheckChip(
      {required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: value,
      label: Text(label),
      onSelected: onChanged,
    );
  }
}
