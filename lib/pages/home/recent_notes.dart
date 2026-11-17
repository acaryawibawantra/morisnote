import 'dart:async';

import 'package:collapsible/collapsible.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:saber/components/home/delete_note_button.dart';
import 'package:saber/components/home/export_note_button.dart';
import 'package:saber/components/home/home_layout_button.dart';
import 'package:saber/components/home/masonry_files.dart';
import 'package:saber/components/home/move_note_button.dart';
import 'package:saber/components/home/new_note_button.dart';
import 'package:saber/components/home/rename_note_button.dart';
import 'package:saber/components/home/syncing_button.dart';
import 'package:saber/components/home/focus_chip.dart';
import 'package:saber/components/home/streak_chip.dart';
import 'package:saber/components/home/welcome.dart';
import 'package:saber/components/theming/saber_theme.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/handwriting_ocr.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/i18n/strings.g.dart';

class const RecentPage({super.key}) extends StatefulHookWidget {
  @override
  State<RecentPage> createState() => _RecentPageState();
}

class _RecentPageState extends State<RecentPage> {
  final List<String> filePaths = [];
  var failed = false;

  final ValueNotifier<List<String>> selectedFiles = ValueNotifier([]);

  /// Morisnote: filter notes by name (and recognized handwriting) from the
  /// home app bar.
  bool _searching = false;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _ocrText = {};
  bool _ocrLoaded = false;

  final log = Logger('RecentPage');

  /// Mitigates a bug where files got imported starting with `null/` instead of `/`.
  ///
  /// This caused them to be written to `Documents/Sabernull/...` instead of `Documents/Saber/...`.
  ///
  /// See https://github.com/saber-notes/saber/issues/996
  /// and https://github.com/saber-notes/saber/pull/977.
  void moveIncorrectlyImportedFiles() async {
    for (final filePath in stows.recentFiles.value) {
      if (filePath.startsWith('/')) continue;

      final String newFilePath;
      if (filePath.startsWith('null/')) {
        newFilePath = await FileManager.suffixFilePathToMakeItUnique(
          filePath.substring('null'.length),
        );
      } else {
        newFilePath = await FileManager.suffixFilePathToMakeItUnique(
          '/$filePath',
        );
      }

      log.warning(
        'Found incorrectly imported file at `$filePath`; moving to `$newFilePath`',
      );
      await FileManager.moveFile(filePath, newFilePath);
    }
  }

  @override
  void initState() {
    findRecentlyAccessedNotes();
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );
    selectedFiles.addListener(_setState);

    super.initState();
    moveIncorrectlyImportedFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    selectedFiles.removeListener(_setState);
    fileWriteSubscription?.cancel();
    super.dispose();
  }

  StreamSubscription? fileWriteSubscription;
  void fileWriteListener(FileOperation event) {
    findRecentlyAccessedNotes(fromFileListener: true);
  }

  void _setState() => setState(() {});

  /// The note's display name, without its `.sbn`/`.sbn2` extension.
  /// Matches the note name, or the handwriting recognized into its `.ocr`
  /// sidecar (see HandwritingOcr).
  bool _matchesQuery(String filePath) {
    final query = _query.toLowerCase();
    if (_noteName(filePath).toLowerCase().contains(query)) return true;
    final ocr = _ocrText[filePath];
    return ocr != null && ocr.toLowerCase().contains(query);
  }

  /// Loads every note's recognized text once, when the search bar opens.
  Future<void> _loadOcrText() async {
    if (_ocrLoaded) return;
    _ocrLoaded = true;

    final loaded = await Future.wait([
      for (final filePath in filePaths)
        HandwritingOcr.readText(filePath)
            .then((text) => MapEntry(filePath, text)),
    ]);
    if (!mounted) return;
    setState(() {
      for (final entry in loaded) {
        final text = entry.value;
        if (text != null && text.trim().isNotEmpty) {
          _ocrText[entry.key] = text;
        }
      }
    });
  }

  String _noteName(String filePath) =>
      filePath.split('/').last.replaceAll(RegExp(r'\.sbn2?$'), '');

  Future findRecentlyAccessedNotes({bool fromFileListener = false}) async {
    if (!mounted) return;

    if (fromFileListener) {
      // don't refresh if we're not on the home page
      final location = GoRouterState.of(context).uri.toString();
      if (!location.startsWith(RoutePaths.prefixOfHome)) return;
    }

    final children = await FileManager.getRecentlyAccessed();
    filePaths.clear();
    if (children.isEmpty) {
      failed = true;
    } else {
      failed = false;
      filePaths.addAll(children);
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final platform = Theme.of(context).platform;
    final crossAxisCount = MediaQuery.sizeOf(context).width ~/ 300 + 1;
    useListenable(stows.homeLayout);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const .only(bottom: 8),
            sliver: SliverAppBar(
              collapsedHeight: kToolbarHeight,
              expandedHeight: platform.isMaterialNative ? 200 : null,
              pinned: true,
              scrolledUnderElevation: 1,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  t.home.titles.home,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 16,
                  bottom: 16,
                ),
              ),
              actions: [
                const FocusChip(),
                const StreakChip(),
                IconButton(
                  tooltip: 'Cari catatan',
                  icon: Icon(_searching ? Icons.search_off : Icons.search),
                  onPressed: () {
                    setState(() {
                      _searching = !_searching;
                      _query = '';
                      _searchController.clear();
                    });
                    if (_searching) _loadOcrText();
                  },
                ),
                const HomeLayoutButton(),
                const SyncingButton(),
              ],
            ),
          ),
          if (_searching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Cari catatan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            ),
          if (failed) ...[
            const SliverSafeArea(sliver: SliverToBoxAdapter(child: Welcome())),
          ] else ...[
            SliverSafeArea(
              minimum: const .only(
                // Allow space for the FloatingActionButton
                bottom: 70,
              ),
              sliver: MasonryFiles(
                crossAxisCount: crossAxisCount,
                files: [
                  for (final filePath in filePaths)
                    if (_query.isEmpty || _matchesQuery(filePath))
                      filePath,
                ],
                selectedFiles: selectedFiles,
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: NewNoteButton(cupertino: platform.isCupertino),
      persistentFooterButtons: selectedFiles.value.isEmpty
          ? null
          : [
              Collapsible(
                axis: CollapsibleAxis.vertical,
                collapsed: selectedFiles.value.length != 1,
                child: RenameNoteButton(
                  existingPath: selectedFiles.value.isEmpty
                      ? ''
                      : selectedFiles.value.first,
                  unselectNotes: () => selectedFiles.value = [],
                ),
              ),
              MoveNoteButton(
                filesToMove: selectedFiles.value,
                unselectNotes: () => selectedFiles.value = [],
              ),
              DeleteNoteButton(
                filesToDelete: selectedFiles.value,
                unselectNotes: () => selectedFiles.value = [],
              ),
              ExportNoteButton(selectedFiles: selectedFiles.value),
            ],
    );
  }
}
