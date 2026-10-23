import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/mascot_controller.dart';
import '../models/character_model.dart';

class MascotView extends StatefulWidget {
  final MascotController controller;
  final double size;

  const MascotView({
    super.key,
    required this.controller,
    this.size = 280,
  });

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> {
  WebViewController? _webViewController;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // When running in headless widget/unit tests, WebViewPlatform.instance may be null
    if (WebViewPlatform.instance == null) {
      widget.controller.onMascotReady();
      return;
    }

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..addJavaScriptChannel(
          'MascotBridge',
          onMessageReceived: (JavaScriptMessage message) {
            widget.controller.handleBridgeMessage(message.message);
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (!mounted) return;
              setState(() {
                _isLoaded = true;
              });
              widget.controller.onMascotReady();
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('[MascotView] WebResourceError: ${error.description}');
            },
          ),
        )
        ..loadFlutterAsset('assets/avatar/avatar.html');

      _webViewController = controller;
      widget.controller.attachController(controller);
    } catch (e) {
      debugPrint('[MascotView] WebView initialization exception: $e');
      widget.controller.onMascotReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    final character = CharacterModel.findByName(widget.controller.currentCharacter);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient soft aura
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            width: widget.size * 0.75,
            height: widget.size * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: character.bodyColor.withValues(alpha: 0.22),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // The Mascot Procedural Vector Engine inside transparent WebView
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.size / 2),
            child: _webViewController != null && WebViewPlatform.instance != null
                ? WebViewWidget(controller: _webViewController!)
                : Center(
                    child: Icon(
                      Icons.smart_toy_rounded,
                      size: widget.size * 0.45,
                      color: character.bodyColor,
                    ),
                  ),
          ),

          // Loading placeholder before WebView is ready
          if (!_isLoaded && _webViewController != null)
            Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(character.bodyColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
