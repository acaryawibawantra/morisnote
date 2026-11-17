import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saber/components/canvas/_stroke.dart';
import 'package:saber/data/handwriting_ocr.dart';

/// Morisnote: "kenali tulisan" dialog — turns the strokes of the current page
/// into text, so a handwritten note can be searched and copied.
class OcrSheet extends StatefulWidget {
  const OcrSheet({
    super.key,
    required this.notePath,
    required this.strokes,
  });

  final String notePath;
  final List<Stroke> strokes;

  @override
  State<OcrSheet> createState() => _OcrSheetState();
}

class _OcrSheetState extends State<OcrSheet> {
  String _language = 'en';
  bool _busy = false;
  String? _text;
  String? _error;

  Future<void> _recognize() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final text = await HandwritingOcr.recognizeStrokes(
        widget.strokes,
        languageCode: _language,
      );
      if (!mounted) return;
      setState(() => _text = text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final text = _text;
    if (text == null || text.isEmpty) return;
    await HandwritingOcr.saveText(widget.notePath, text);
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Teks disimpan — catatan ini bisa dicari dari beranda'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    return SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.translate, size: 20),
              const SizedBox(width: 8),
              const Text('Bahasa tulisan'),
              const Spacer(),
              DropdownButton<String>(
                value: _language,
                isDense: true,
                underline: const SizedBox(),
                items: [
                  for (final entry in HandwritingOcr.languages.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value != null) setState(() => _language = value);
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy || widget.strokes.isEmpty ? null : _recognize,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.text_fields),
            label: Text(
              widget.strokes.isEmpty
                  ? 'Halaman ini belum ada tulisan'
                  : 'Kenali tulisan halaman ini',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (text != null) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  text.isEmpty ? 'Tidak ada teks yang dikenali.' : text,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _save(),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Simpan untuk pencarian'),
                  ),
                const Spacer(),
                if (text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (!context.mounted) return;
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(content: Text('Teks disalin')),
                      );
                    },
                    icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                    label: const Text('Salin'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
