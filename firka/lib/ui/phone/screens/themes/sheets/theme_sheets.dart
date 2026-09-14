import "dart:io";
import "dart:ui" as ui;
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";
import "package:mobile_scanner/mobile_scanner.dart";
import "package:path_provider/path_provider.dart";
import "package:share_plus/share_plus.dart";

import "package:firka/app/app_state.dart";
import "package:firka/core/snowflake.dart";
import "package:firka/l10n/app_localizations.dart";
import "package:firka/ui/phone/screens/themes/user_theme.dart";
import "package:firka/ui/phone/screens/themes/widgets/theme_qr_card.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/ui/components/firka_card.dart";
import "package:firka_common/ui/theme/theme_binary_format.dart";

Future<String?> showThemeNameSheet(
  BuildContext context,
  AppLocalizations l10n,
) {
  return _showCenteredInputSheet(
    context: context,
    l10n: l10n,
    icon: Majesticon.plusLine,
    title: l10n.s_c_themes_create_title,
    subtitle: l10n.s_c_themes_create_subtitle,
    placeholder: l10n.s_c_themes_create_placeholder,
    confirmLabel: l10n.s_c_themes_continue,
  );
}

Future<bool> showThemeDeleteSheet(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    builder: (context) {
      return _ThemeConfirmSheet(
        icon: Majesticon.deleteBinLine,
        title: l10n.s_c_themes_delete_title,
        subtitle: l10n.s_c_themes_delete_subtitle,
        confirmLabel: l10n.s_c_themes_delete_confirm,
        cancelLabel: l10n.cancel,
        confirmColor: appStyle.colors.accent,
        onConfirm: () => context.pop(true),
        onCancel: () => context.pop(false),
      );
    },
  );
  return result ?? false;
}

String buildThemeShareUrl(UserTheme theme) => theme.shareUrl;

Future<void> showThemeShareSheet(
  BuildContext context, {
  required UserTheme theme,
  required AppInitialization data,
}) {
  return showModalBottomSheet<void>(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    builder: (context) {
      return _ThemeShareSheet(
        theme: theme,
        shareUrl: theme.shareUrl,
        l10n: data.l10n,
      );
    },
  );
}

Future<void> showThemeImportSheet(
  BuildContext context, {
  required AppInitialization data,
  required Future<void> Function(UserTheme theme) onImport,
}) {
  return showModalBottomSheet<void>(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _ThemeImportSheet(
          l10n: data.l10n,
          onImport: onImport,
        ),
      );
    },
  );
}

class _ThemeShareSheet extends StatefulWidget {
  final UserTheme theme;
  final String shareUrl;
  final AppLocalizations l10n;

  const _ThemeShareSheet({
    required this.theme,
    required this.shareUrl,
    required this.l10n,
  });

  @override
  State<_ThemeShareSheet> createState() => _ThemeShareSheetState();
}

class _ThemeShareSheetState extends State<_ThemeShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _copied = false;
  bool _isSharing = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.shareUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("RenderRepaintBoundary not found");
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("Could not encode image to PNG");
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final sanitizedName = widget.theme.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final safeName = sanitizedName.isEmpty ? 'firka' : sanitizedName;
      final file = File('${tempDir.path}/firka_theme_$safeName.png');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: widget.theme.name,
        ),
      );
    } catch (e) {
      await SharePlus.instance.share(
        ShareParams(
          text: widget.shareUrl,
          subject: widget.theme.name,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ThemeSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _cardKey,
            child: ThemeQrCard(
              theme: widget.theme,
              shareData: widget.shareUrl,
            ),
          ),
          const SizedBox(height: 20),
          _sheetButton(
            label: _copied ? widget.l10n.copied : "Kód másolása",
            color: appStyle.colors.accent,
            onTap: _copy,
          ),
          const SizedBox(height: 8),
          _sheetButton(
            label: _isSharing ? "Kép generálása..." : "Megosztás",
            color: appStyle.colors.buttonSecondaryFill,
            onTap: _isSharing ? () {} : _share,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

enum _ImportMode { camera, image, text }

class _ThemeImportSheet extends StatefulWidget {
  final AppLocalizations l10n;
  final Future<void> Function(UserTheme theme) onImport;

  const _ThemeImportSheet({
    required this.l10n,
    required this.onImport,
  });

  @override
  State<_ThemeImportSheet> createState() => _ThemeImportSheetState();
}

class _ThemeImportSheetState extends State<_ThemeImportSheet> {
  _ImportMode _mode = _ImportMode.camera;
  final _controller = TextEditingController();
  ThemeBinaryData? _previewData;
  String? _extractedName;
  String? _error;
  bool _isAnalyzingImage = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _processImportString(String raw, {bool silent = false}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return false;

    final payload = trimmed.parseThemeSharePayload();
    final decoded = payload.code.tryDecodeThemeData();

    if (decoded != null) {
      setState(() {
        _controller.text = trimmed;
        _previewData = decoded;
        _extractedName = payload.name;
        _error = null;
      });
      return true;
    } else {
      if (!silent) {
        setState(() {
          _error = "Érvénytelen témakód";
        });
      }
      return false;
    }
  }

  void _onTextChanged() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _previewData = null;
        _extractedName = null;
        _error = null;
      });
      return;
    }
    _processImportString(raw, silent: true);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!;
      _processImportString(data.text!);
    }
  }

  Future<void> _pickImageAndScan() async {
    setState(() {
      _isAnalyzingImage = true;
      _error = null;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }

      final capture = await MobileScannerPlatform.instance.analyzeImage(picked.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        bool found = false;
        for (final barcode in capture.barcodes) {
          final raw = barcode.rawValue;
          if (raw != null && raw.isNotEmpty) {
            if (_processImportString(raw)) {
              found = true;
              HapticFeedback.mediumImpact();
              break;
            }
          }
        }
        if (!found) {
          setState(() {
            _error = "A képen nem található érvényes téma QR kód.";
          });
        }
      } else {
        setState(() {
          _error = "Nem található QR kód a kiválasztott képen.";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Hiba a kép beolvasásakor: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isAnalyzingImage = false);
      }
    }
  }

  Future<void> _import() async {
    final preview = _previewData;
    if (preview == null) return;

    final themeName = _extractedName != null && _extractedName!.isNotEmpty
        ? _extractedName!
        : widget.l10n.s_c_themes_imported_label;

    final List<Color> swatch;
    if (preview.isFullTheme) {
      swatch = [
        preview.lightSlot(ThemeColorSlot.accent) ?? appStyle.colors.accent,
        preview.lightSlot(ThemeColorSlot.textPrimary) ?? appStyle.colors.textPrimary,
        preview.lightSlot(ThemeColorSlot.background) ?? appStyle.colors.background,
      ];
    } else {
      swatch = preview.colors.length >= 3
          ? preview.colors.take(3).toList()
          : (preview.colors.isNotEmpty
              ? preview.colors
              : [appStyle.colors.accent, appStyle.colors.textPrimary, appStyle.colors.background]);
    }

    final theme = UserTheme(
      id: Snowflake.nextId(),
      name: themeName,
      origin: ThemeOrigin.downloaded,
      swatch: swatch,
    );

    await widget.onImport(theme);
    if (!mounted) return;
    context.pop();
  }

  Widget _modeTab({
    required String label,
    required Object icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? appStyle.colors.accent.withValues(alpha: 0.15)
                : appStyle.colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? appStyle.colors.accent
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Majesticon(
                icon as Uint8List,
                color: selected
                    ? appStyle.colors.accent
                    : appStyle.colors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: appStyle.fonts.B_12R.copyWith(
                  fontFamily: 'Figtree',
                  color: selected
                      ? appStyle.colors.accent
                      : appStyle.colors.textSecondary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ThemeSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetIcon(Majesticon.arrowDownCircleLine),
          const SizedBox(height: 16),
          Text(
            widget.l10n.s_c_themes_import,
            textAlign: TextAlign.center,
            style: appStyle.fonts.H_H2.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          if (_previewData != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: appStyle.colors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: appStyle.colors.accent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _extractedName != null && _extractedName!.isNotEmpty
                        ? _extractedName!
                        : widget.l10n.s_c_themes_imported_label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      color: appStyle.colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final color in (_previewData!.isFullTheme
                          ? [
                              _previewData!.lightSlot(ThemeColorSlot.accent) ?? appStyle.colors.accent,
                              _previewData!.lightSlot(ThemeColorSlot.textPrimary) ?? appStyle.colors.textPrimary,
                              _previewData!.lightSlot(ThemeColorSlot.background) ?? appStyle.colors.background,
                            ]
                          : _previewData!.colors.take(4)))
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: appStyle.colors.textPrimary.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _previewData!.isFullTheme
                        ? "Teljes téma (32 szín)"
                        : "${_previewData!.colors.length} szín",
                    style: appStyle.fonts.B_12R.apply(
                      color: appStyle.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sheetButton(
              label: widget.l10n.s_c_themes_import,
              color: appStyle.colors.accent,
              onTap: _import,
            ),
            const SizedBox(height: 8),
            _sheetButton(
              label: "Másik beolvasása",
              color: appStyle.colors.buttonSecondaryFill,
              onTap: () {
                setState(() {
                  _previewData = null;
                  _extractedName = null;
                  _controller.clear();
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 8),
          ] else ...[
            Row(
              children: [
                _modeTab(
                  label: "Kamera",
                  icon: Majesticon.cameraLine,
                  selected: _mode == _ImportMode.camera,
                  onTap: () {
                    setState(() {
                      _mode = _ImportMode.camera;
                      _error = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _modeTab(
                  label: "Kép",
                  icon: Majesticon.imageLine,
                  selected: _mode == _ImportMode.image,
                  onTap: () {
                    setState(() {
                      _mode = _ImportMode.image;
                      _error = null;
                    });
                    _pickImageAndScan();
                  },
                ),
                const SizedBox(width: 8),
                _modeTab(
                  label: "Szöveg",
                  icon: Majesticon.textboxLine,
                  selected: _mode == _ImportMode.text,
                  onTap: () {
                    setState(() {
                      _mode = _ImportMode.text;
                      _error = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_mode == _ImportMode.camera) ...[
              _CameraScannerView(
                onScanned: (raw) {
                  if (_previewData != null) return;
                  if (_processImportString(raw)) {
                    HapticFeedback.mediumImpact();
                  }
                },
              ),
              const SizedBox(height: 10),
              Text(
                "Irányítsd a kamerát egy téma QR kódra",
                textAlign: TextAlign.center,
                style: appStyle.fonts.B_12R.apply(
                  color: appStyle.colors.textSecondary,
                ),
              ),
            ] else if (_mode == _ImportMode.image) ...[
              GestureDetector(
                onTap: _isAnalyzingImage ? null : _pickImageAndScan,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: appStyle.colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: appStyle.colors.accent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: _isAnalyzingImage
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: appStyle.colors.accent,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Kép elemzése...",
                                style: appStyle.fonts.B_14SB.apply(
                                  color: appStyle.colors.textSecondary,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: appStyle.colors.accent.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Majesticon(
                                  Majesticon.imageLine,
                                  color: appStyle.colors.accent,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Koppints a kép kiválasztásához",
                                style: appStyle.fonts.B_14SB.apply(
                                  color: appStyle.colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Válassz QR kódot tartalmazó képet a galériából",
                                style: appStyle.fonts.B_12R.apply(
                                  color: appStyle.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ] else if (_mode == _ImportMode.text) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: appStyle.colors.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textAlign: TextAlign.start,
                        textInputAction: TextInputAction.done,
                        cursorColor: appStyle.colors.accent,
                        style: appStyle.fonts.B_16R.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: "Témakód vagy link...",
                          hintStyle: appStyle.fonts.B_16R.apply(
                            color: appStyle.colors.textTertiary,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.paste, size: 18),
                      color: appStyle.colors.accent,
                      onPressed: _paste,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _sheetButton(
                label: "Beillesztés a vágólapról",
                color: appStyle.colors.buttonSecondaryFill,
                onTap: _paste,
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: appStyle.fonts.B_14R.apply(
                  color: appStyle.colors.errorAccent,
                ),
              ),
            ],

            const SizedBox(height: 12),
            _sheetButton(
              label: widget.l10n.cancel,
              color: appStyle.colors.buttonSecondaryFill,
              onTap: () => context.pop(),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CameraScannerView extends StatefulWidget {
  final ValueChanged<String> onScanned;

  const _CameraScannerView({required this.onScanned});

  @override
  State<_CameraScannerView> createState() => _CameraScannerViewState();
}

class _CameraScannerViewState extends State<_CameraScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final raw = barcode.rawValue;
                  if (raw != null && raw.isNotEmpty) {
                    widget.onScanned(raw);
                    break;
                  }
                }
              },
              errorBuilder: (context, error) {
                return Container(
                  color: appStyle.colors.card,
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Majesticon(
                          Majesticon.cameraOffLine,
                          color: appStyle.colors.textSecondary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Kamera nem elérhető",
                          textAlign: TextAlign.center,
                          style: appStyle.fonts.B_14SB.apply(
                            color: appStyle.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Használd a Kép vagy Szöveg opciót.",
                          textAlign: TextAlign.center,
                          style: appStyle.fonts.B_12R.apply(
                            color: appStyle.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: appStyle.colors.accent.withValues(alpha: 0.8),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Majesticon(
                  Majesticon.lightningBoltSolid,
                  color: Colors.white,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                ),
                onPressed: () => _controller.toggleTorch(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _showCenteredInputSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required Object icon,
  required String title,
  required String subtitle,
  required String placeholder,
  required String confirmLabel,
}) {
  return showModalBottomSheet<String>(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _ThemeNameInputSheet(
          icon: icon,
          title: title,
          subtitle: subtitle,
          placeholder: placeholder,
          confirmLabel: confirmLabel,
          cancelLabel: l10n.cancel,
        ),
      );
    },
  );
}

class _ThemeNameInputSheet extends StatefulWidget {
  final Object icon;
  final String title;
  final String subtitle;
  final String placeholder;
  final String confirmLabel;
  final String cancelLabel;

  const _ThemeNameInputSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.placeholder,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  State<_ThemeNameInputSheet> createState() => _ThemeNameInputSheetState();
}

class _ThemeNameInputSheetState extends State<_ThemeNameInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    context.pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return _ThemeSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetIcon(widget.icon),
          const SizedBox(height: 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: appStyle.fonts.H_H2.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: appStyle.fonts.B_16R.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: appStyle.colors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              cursorColor: appStyle.colors.accent,
              style: appStyle.fonts.B_16R.apply(
                color: appStyle.colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: appStyle.fonts.B_16R.apply(
                  color: appStyle.colors.textTertiary,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sheetButton(
            label: widget.confirmLabel,
            color: appStyle.colors.accent,
            onTap: _submit,
          ),
          const SizedBox(height: 8),
          _sheetButton(
            label: widget.cancelLabel,
            color: appStyle.colors.buttonSecondaryFill,
            onTap: () => context.pop(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ThemeConfirmSheet extends StatelessWidget {
  final Object icon;
  final String title;
  final String subtitle;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ThemeConfirmSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmColor,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return _ThemeSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetIcon(icon),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: appStyle.fonts.H_H2.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: appStyle.fonts.B_16R.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _sheetButton(
            label: confirmLabel,
            color: confirmColor,
            onTap: onConfirm,
          ),
          const SizedBox(height: 8),
          _sheetButton(
            label: cancelLabel,
            color: appStyle.colors.buttonSecondaryFill,
            onTap: onCancel,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ThemeSheetShell extends StatelessWidget {
  final Widget child;

  const _ThemeSheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              color: appStyle.colors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  heightFactor: 0,
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 18),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: appStyle.colors.shadowColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                child,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _sheetIcon(Object icon) {
  return Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: appStyle.colors.accent.withValues(alpha: 0.25),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: appStyle.colors.accent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: FirkaIconWidget(
            FirkaIconType.majesticons,
            icon,
            size: 20,
            color: appStyle.colors.textPrimaryLight,
          ),
        ),
      ),
    ),
  );
}

Widget _sheetButton({
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: double.infinity,
    child: GestureDetector(
      onTap: onTap,
      child: FirkaCard(
        color: color,
        left: const [],
        center: [
          Text(
            label,
            style: appStyle.fonts.B_16SB.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
