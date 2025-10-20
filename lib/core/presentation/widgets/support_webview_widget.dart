import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snip_fair/core/presentation/widgets/custom_appbar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as image;

class SupportWebViewWidget extends StatefulWidget {
  const SupportWebViewWidget({
    required this.supportUrl,
    required this.authToken,
    this.title = 'Support',
    super.key,
  });

  final String supportUrl;
  final String authToken;
  final String title;

  @override
  State<SupportWebViewWidget> createState() => _SupportWebViewWidgetState();
}

class _SupportWebViewWidgetState extends State<SupportWebViewWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    // Create controller with platform-specific parameters
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) async {
            setState(() => _isLoading = false);
          },
        ),
      );
    // Enable file picking on Android
    if (_controller.platform is AndroidWebViewController) {
      final androidController = _controller.platform as AndroidWebViewController
        ..setOnShowFileSelector(_androidFilePicker);
    }

    // Load the page - cookies will be sent automatically
    await _controller.loadRequest(
      Uri.parse('${widget.supportUrl}?auth_token=${widget.authToken}'),
    );
  }

  /// Execute custom JavaScript with query selectors
  Future<void> _executeCustomScripts() async {
    await _controller.runJavaScript('''
      const main = document.querySelector('main');
      if (main) {
        // Clone main element
        const mainClone = main.cloneNode(true);
        
        // Clear body and add only main
        document.body.innerHTML = '';
        document.body.appendChild(mainClone);
        
        // Style for full display
        document.body.style.margin = '0';
        document.body.style.padding = '0';
        mainClone.style.width = '100%';
        mainClone.style.minHeight = '100vh';
      }
    ''');
  }

  Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
    if (params.acceptTypes.any((type) => true)) {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.gallery);

      if (photo == null) {
        return [];
      }

      final imageData = await photo.readAsBytes();
      final decodedImage = image.decodeImage(imageData)!;
      final scaledImage = image.copyResize(decodedImage, width: 500);
      final jpg = image.encodeJpg(scaledImage, quality: 90);

      final filePath = (await getTemporaryDirectory()).uri.resolve(
            './image_${DateTime.now().microsecondsSinceEpoch}.jpg',
          );
      final file = await File.fromUri(filePath).create(recursive: true);
      await file.writeAsBytes(jpg, flush: true);

      return [file.uri.toString()];
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
