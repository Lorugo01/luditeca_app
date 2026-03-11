import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReaderWebViewPage extends StatefulWidget {
  final String slidebookUrl;

  const ReaderWebViewPage({super.key, required this.slidebookUrl});

  @override
  State<ReaderWebViewPage> createState() => _ReaderWebViewPageState();
}

class _ReaderWebViewPageState extends State<ReaderWebViewPage> {
  bool _isLoading = true;

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.slidebookUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

