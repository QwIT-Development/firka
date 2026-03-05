import 'dart:async';

import 'package:firka/app/app_state.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Lightweight in-app browser used outside the login flow (e.g. privacy policy).
///
/// This deliberately contains only generic WebView behaviour, keeping all
/// login/token handling inside `login_webview.dart`.
class DomainBrowserWebviewWidget extends StatefulWidget {
  final AppInitialization? data;
  final String? url;

  const DomainBrowserWebviewWidget({
    super.key,
    this.data,
    this.url,
  });

  @override
  State<DomainBrowserWebviewWidget> createState() =>
      _DomainBrowserWebviewWidgetState();
}

class _DomainBrowserWebviewWidgetState
    extends FirkaState<DomainBrowserWebviewWidget>
    with TickerProviderStateMixin {
  late WebViewController _webViewController;
  bool _isLoading = true;
  AnimationController? _fadeAnimationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_fadeAnimationController!);

    assert(widget.data != null && widget.url != null,
        'DomainBrowserWebviewWidget requires non-null data and url');

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url!))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            Timer(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _fadeAnimationController?.forward().then((_) {
                  _fadeAnimationController?.reset();
                });
              }
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _fadeAnimationController?.reset();
          },
        ),
      );
  }

  @override
  void dispose() {
    _fadeAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null || widget.url == null) {
      return const SizedBox.shrink();
    }

    final data = widget.data!;
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;
    final displayUrl = (widget.url ?? '').replaceFirst(RegExp(r'^https?://'), '');
    final displayParts = displayUrl.split('/');
    final host = displayParts.isNotEmpty ? displayParts.first : displayUrl;
    final path = displayParts.length > 1
        ? '/${displayParts.sublist(1).join('/')}'
        : '';

    return Material(
      color: appStyle.colors.background,
      child: Padding(
        padding: EdgeInsets.only(
          top: 61 + safePadding.top,
          left: 12,
          right: 12,
          bottom: safePadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: SvgPicture.asset(
                    "assets/icons/dave.svg",
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.data?.l10n.runningInDomainBrowser ??
                        'Domain Browser',
                    style: appStyle.fonts.B_16R.copyWith(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: appStyle.colors.buttonSecondaryFill,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: appStyle.colors.shadowColor,
                          offset: const Offset(0, 1),
                          blurRadius: appStyle.colors.shadowBlur.toDouble(),
                        ),
                      ],
                    ),
                    child: Majesticon(
                      Majesticon.multiplySolid,
                      color: appStyle.colors.accent,
                      size: 16,
                    ),
                    ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    WebViewWidget(
                      controller: _webViewController,
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                    ),
                    if (_fadeAnimationController != null &&
                        _fadeAnimation != null)
                      IgnorePointer(
                        ignoring: !_isLoading,
                        child: AnimatedBuilder(
                          animation: _fadeAnimationController!,
                          builder: (context, child) => AnimatedOpacity(
                            opacity: _isLoading
                                ? 1.0
                                : _fadeAnimationController!.isAnimating
                                    ? _fadeAnimation!.value
                                    : 0.0,
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              color: appStyle.colors.background,
                              child: Center(
                                child: Image.asset(
                                  "assets/images/logos/loading.gif",
                                  width: 50,
                                  height: 50,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: appStyle.colors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            text: host,
                            style: appStyle.fonts.B_14R.copyWith(
                              fontSize: 16,
                              color: appStyle.colors.textPrimary,
                            ),
                            children: [
                              TextSpan(
                                text: path,
                                style: appStyle.fonts.B_14R.copyWith(
                                  fontSize: 16,
                                  color: appStyle.colors.textTeritary ??
                                      appStyle.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: appStyle.colors.buttonSecondaryFill,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: appStyle.colors.shadowColor,
                        offset: const Offset(0, 1),
                        blurRadius: appStyle.colors.shadowBlur.toDouble(),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/icons/button/colorwheel.png",
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: appStyle.colors.buttonSecondaryFill,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: appStyle.colors.shadowColor,
                        offset: const Offset(0, 1),
                        blurRadius: appStyle.colors.shadowBlur.toDouble(),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Majesticon(
                      Majesticon.chevronLeftLine,
                      color: appStyle.colors.secondary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: appStyle.colors.buttonSecondaryFill,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: appStyle.colors.shadowColor,
                        offset: const Offset(0, 1),
                        blurRadius: appStyle.colors.shadowBlur.toDouble(),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Majesticon(
                      Majesticon.menuLine,
                      color: appStyle.colors.secondary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
