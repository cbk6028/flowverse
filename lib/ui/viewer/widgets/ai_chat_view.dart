import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io' show Platform;
import 'dart:developer' as developer;

class AIChatView extends StatefulWidget {
  const AIChatView({super.key});

  @override
  State<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView> {
  late final WebViewController controller;
  final List<Map<String, String>> aiSites = [
    {'name': 'Qwen', 'url': 'https://chat.qwen.ai'},
    {'name': 'ChatGPT', 'url': 'https://chat.openai.com'},
    {'name': 'Deepseek', 'url': 'https://chat.deepseek.com'},
  ];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
            'Mozilla/5.0 (Linux; Android 15; XT2303-2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Mobile Safari/537.36')
        ..loadRequest(Uri.parse(aiSites[_currentIndex]['url']!))
        ..enableZoom(false)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              controller.runJavaScript('''
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width,initial-scale=1,maximum-scale=1,viewport-fit=cover';
                document.getElementsByTagName('head')[0].appendChild(meta);

                // 重写console对象以捕获日志输出
                window.console = {
                  log: function(message) {
                    window.flutter_inappwebview.callHandler('console', 'log', JSON.stringify(message));
                  },
                  error: function(message) {
                    window.flutter_inappwebview.callHandler('console', 'error', JSON.stringify(message));
                  },
                  warn: function(message) {
                    window.flutter_inappwebview.callHandler('console', 'warn', JSON.stringify(message));
                  },
                  info: function(message) {
                    window.flutter_inappwebview.callHandler('console', 'info', JSON.stringify(message));
                  }
                };
              ''');
            },
            onPageFinished: (String url) {
              controller.runJavaScript('''
                document.body.style.overflow = 'auto';
                document.documentElement.style.overflow = 'auto';
                var html = document.documentElement.outerHTML;
                console.log('Page HTML:', html);
              ''');
            },
          ),
        )
        ..addJavaScriptChannel(
          'console',
          onMessageReceived: (JavaScriptMessage message) {
            developer.log('WebView Console: ${message.message}');
          },
        );
    }
  }

  void _switchAISite(int index) {
    setState(() {
      _currentIndex = index;
      controller.loadRequest(Uri.parse(aiSites[index]['url']!));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) {
      return const Center(
        child: Text('AI对话功能仅支持macOS平台'),
      );
    }

    var theme = Theme.of(context);
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          border: Border(
            left: BorderSide(
              color: Colors.grey.withOpacity(0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                for (var i = 0; i < aiSites.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: () => _switchAISite(i),
                      style: TextButton.styleFrom(
                        backgroundColor: _currentIndex == i
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.transparent,
                        foregroundColor:
                            _currentIndex == i ? Colors.blue : Colors.black87,
                      ),
                      child: Text(aiSites[i]['name']!),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height - 250,
            child: WebViewWidget(controller: controller),
          ),
        ]));
  }
}
