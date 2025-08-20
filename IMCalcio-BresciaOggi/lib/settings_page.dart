// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:http/http.dart' as http;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}


class _SettingsPageState extends State<SettingsPage> {


  @override
  void initState()
  {
    super.initState();
  }

  @override
  void dispose()
  {
    super.dispose();
  }

  Widget _getBody()
  {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Le impostazioni arriveranno presto!")
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      displayBannerAd: false,
      child: Scaffold(
        appBar: const MyAppBar(title: Text("Impostazioni"), centerTitle: true),
        body: _getBody(),
      ),
    );
  }
}
