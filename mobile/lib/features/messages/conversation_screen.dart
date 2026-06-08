import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/models/message.dart';
import '../../core/network/api_client.dart';
import '../../core/state/app_scope.dart';
import '../../core/utils/image_url.dart';
import '../../shared/ui.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  final int partnerId;
  final String partnerName;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _imagePicker = ImagePicker();
  Future<ConversationDetail>? _future;
  bool _sending = false;
  _MessageAttachment? _attachment;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).api.conversation(widget.partnerId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = AppScope.of(context).api.conversation(widget.partnerId);
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _attachment == null) || _sending) return;

    final controller = AppScope.of(context);
    setState(() => _sending = true);
    try {
      String? imageUrl;
      if (_attachment != null) {
        imageUrl = await controller.api.uploadImage(
          bytes: _attachment!.bytes,
          fileName: _attachment!.name,
          category: 'messages',
        );
      }
      await controller.api.sendMessage(
        toUserId: widget.partnerId,
        content: text,
        imageUrl: imageUrl,
      );
      _messageController.clear();
      if (mounted) setState(() => _attachment = null);
      _reload();
      await controller.refreshSession();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAttachment(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null) return;
      final attachment = _MessageAttachment(
        name: file.name,
        bytes: await file.readAsBytes(),
      );
      if (mounted) setState(() => _attachment = attachment);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel seçilemedi: $e')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () => _pickAttachment(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Fotoğraf çek'),
              onTap: () => _pickAttachment(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMessageActions(MessageItem message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            if (message.content.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Mesajı düzenle'),
                onTap: () => Navigator.of(sheetContext).pop('edit'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Mesajı sil'),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _editMessage(message);
    } else {
      await _deleteMessage(message);
    }
  }

  Future<void> _editMessage(MessageItem message) async {
    final editor = TextEditingController(text: message.content);
    final content = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mesajı Düzenle'),
        content: TextField(
          controller: editor,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Mesaj'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(editor.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    editor.dispose();
    if (content == null || content.isEmpty) return;

    try {
      await AppScope.of(context).api.editMessage(
            messageId: message.id,
            content: content,
          );
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj düzenlenemedi: $e')),
        );
      }
    }
  }

  Future<void> _deleteMessage(MessageItem message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mesajı Sil'),
        content: const Text('Bu mesajı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AppScope.of(context).api.deleteMessage(message.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj silinemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.partnerName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<ConversationDetail>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 42, color: Color(0xFFD6B367)),
                            const SizedBox(height: 12),
                            Text(
                              'Sohbet yüklenemedi\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final detail = snapshot.data;
                  if (detail == null || detail.messages.isEmpty) {
                    return const Center(
                      child: Text('Henüz mesaj yok. İlk mesajı siz gönderin.'),
                    );
                  }
                  return ListView.separated(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final message =
                          detail.messages[detail.messages.length - 1 - index];
                      final mine =
                          controller.currentUser?.id == message.fromUserId;
                      return Row(
                        mainAxisAlignment: mine
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: GestureDetector(
                              onLongPress: mine && !message.isDeleted
                                  ? () => _showMessageActions(message)
                                  : null,
                              child: GlassPanel(
                                borderColor: mine
                                    ? const Color(0x55D6B367)
                                    : Colors.white.withValues(alpha: 0.08),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (message.isDeleted)
                                      const Text(
                                        'Bu mesaj silindi.',
                                        style: TextStyle(
                                          color: Color(0xFFA9B3C8),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    else ...[
                                      if (message.content.isNotEmpty)
                                        Text(message.content,
                                            style:
                                                const TextStyle(height: 1.45)),
                                      if (message.imageUrl.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            resolveImageUrl(
                                                controller.api.baseUrl,
                                                message.imageUrl),
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox(
                                              height: 96,
                                              child: Center(
                                                  child: Icon(Icons
                                                      .broken_image_outlined)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      '${DateFormat('dd MMM HH:mm', 'tr').format(message.createdAt.toLocal())}'
                                      '${message.isEdited ? ' · düzenlendi' : ''}',
                                      style: const TextStyle(
                                          color: Color(0xFFA9B3C8),
                                          fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: detail.messages.length,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GlassPanel(
                child: Column(
                  children: [
                    if (_attachment != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _attachment!.bytes,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton.filled(
                              tooltip: 'Eki kaldır',
                              onPressed: () =>
                                  setState(() => _attachment = null),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Fotoğraf ekle',
                          onPressed: _sending ? null : _showAttachmentOptions,
                          icon: const Icon(Icons.attach_file_rounded),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Mesaj yazın',
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _sending ? null : _sendMessage,
                          child: _sending
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageAttachment {
  const _MessageAttachment({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}
