//Full news page

import 'package:flutter/Material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FullNewsPage extends StatefulWidget {
  const FullNewsPage({super.key});

  @override
  State<FullNewsPage> createState() => _FullNewsPageState();
}

class _FullNewsPageState extends State<FullNewsPage> {

  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController();
    controller.loadRequest(Uri.parse("https://www.sportevai.it/news/155111558662/il-milan-dei-sogni-della-gazzetta-e-da-scudetto-scoppia-la-polemica-social"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notizie")
      ),
      body: WebViewWidget(
        controller: controller,
      )
    );
  }
}
