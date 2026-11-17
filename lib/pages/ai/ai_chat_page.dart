import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saber/components/ai/math_text.dart';
import 'package:saber/data/ai/ai_client.dart';
import 'package:saber/data/ai/ai_settings.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/handwriting_ocr.dart';

/// Morisnote: "Tanya AI" tab — a chat that streams answers from an
/// OpenAI-compatible endpoint (9router by default) and renders LaTeX.
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _ChatMessage {
  _ChatMessage({required this.fromUser, required this.text});
  final bool fromUser;
  String text;
}

class _Attachment {
  const _Attachment({required this.name, required this.text});
  final String name;
  final String text;
}

class _AiChatPageState extends State<AiChatPage> {
  static const _systemPrompt =
      'Kamu tutor matematika untuk mahasiswa Indonesia. Jawab dalam bahasa '
      'Indonesia, ringkas, dan langkah demi langkah. Tulis semua rumus dalam '
      r'LaTeX: inline $...$ dan blok $$...$$. Jangan memakai gambar.';

  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  StreamSubscription<String>? _subscription;
  bool _sending = false;
  String? _error;
  _Attachment? _attachment;

  @override
  void initState() {
    super.initState();
    AiSettings.load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _sending) return;

    if (!AiSettings.isConfigured) {
      await _openSettings();
      if (!AiSettings.isConfigured) return;
    }

    _controller.clear();
    final answer = _ChatMessage(fromUser: false, text: '');
    setState(() {
      _error = null;
      _messages.add(_ChatMessage(fromUser: true, text: prompt));
      _messages.add(answer);
      _sending = true;
    });

    final request = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      if (_attachment != null)
        {
          'role': 'system',
          'content': 'Catatan siswa "${_attachment!.name}" (hasil OCR '
              'tulisan tangan, mungkin ada salah baca):\n${_attachment!.text}',
        },
      for (final message in _messages.sublist(0, _messages.length - 1))
        {'role': message.fromUser ? 'user' : 'assistant', 'content': message.text},
    ];

    final buffer = StringBuffer();
    await _subscription?.cancel();
    _subscription = AiClient.streamChat(request).listen(
      (delta) {
        buffer.write(delta);
        setState(() => answer.text = buffer.toString());
        _scrollToEnd();
      },
      onError: (Object error) {
        setState(() {
          _error = '$error';
          _sending = false;
        });
      },
      onDone: () {
        setState(() => _sending = false);
        _scrollToEnd();
      },
      cancelOnError: true,
    );
    _scrollToEnd();
  }

  Future<void> _attachNote() async {
    final paths = await FileManager.getRecentlyAccessed();
    final notes = <_Attachment>[];
    for (final path in paths) {
      final text = await HandwritingOcr.readText(path);
      if (text == null || text.trim().isEmpty) continue;
      notes.add(_Attachment(name: path.split('/').last, text: text));
    }
    if (!mounted) return;

    if (notes.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada catatan bertekstur OCR. Buka catatan → ikon translate → '
            '"Simpan untuk pencarian", lalu coba lagi.',
          ),
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<_Attachment>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Lampirkan catatan sebagai konteks'),
          ),
          for (final note in notes)
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(note.name),
              subtitle: Text(
                note.text.replaceAll('\n', ' ').trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(sheetContext).pop(note),
            ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _attachment = picked);
  }

  Future<void> _openSettings() async {
    final urlController = TextEditingController(text: AiSettings.baseUrl.value);
    final modelController = TextEditingController(text: AiSettings.model.value);
    final keyController = TextEditingController(text: AiSettings.apiKey ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Koneksi AI'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://…/v1',
                ),
              ),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API key',
                  helperText: 'Disimpan di keystore perangkat',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              await AiSettings.save(
                baseUrl: urlController.text,
                model: modelController.text,
                apiKey: keyController.text,
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (mounted) setState(() {});
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    urlController.dispose();
    modelController.dispose();
    keyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attachment = _attachment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanya AI'),
        actions: [
          IconButton(
            tooltip: 'Lampirkan catatan',
            onPressed: _sending ? null : _attachNote,
            icon: const Icon(Icons.attach_file),
          ),
          IconButton(
            tooltip: 'Koneksi AI',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Bersihkan percakapan',
            onPressed: _sending
                ? null
                : () => setState(() {
                      _messages.clear();
                      _error = null;
                    }),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState(onExample: (example) {
                    _controller.text = example;
                    _send();
                  })
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isLast = index == _messages.length - 1;
                      return Align(
                        alignment: message.fromUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: const BoxConstraints(maxWidth: 560),
                          decoration: BoxDecoration(
                            color: message.fromUser
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: message.fromUser
                              ? SelectableText(message.text)
                              : message.text.isEmpty && isLast && _sending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : MathText(message.text),
                        ),
                      );
                    },
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (attachment != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Chip(
                    avatar: const Icon(Icons.description_outlined, size: 16),
                    label: Text(attachment.name),
                    onDeleted: () => setState(() => _attachment = null),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Tanya soal matematika…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onExample});

  final void Function(String example) onExample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.auto_awesome, size: 44, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text('Tutor matematika', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Tanya konsep, minta langkah penyelesaian, atau lampirkan catatan '
          'tulisan tanganmu sebagai konteks. Rumus dirender rapi.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        for (final example in const [
          'Jelaskan aturan rantai dengan contoh.',
          r'Hitung $\int x^2 e^x\,dx$ langkah demi langkah.',
          'Buat 5 soal latihan limit beserta pembahasannya.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => onExample(example),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(example),
              ),
            ),
          ),
      ],
    );
  }
}
