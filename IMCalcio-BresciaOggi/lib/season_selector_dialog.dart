// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';

class SeasonSelectorDialog extends StatefulWidget {
  const SeasonSelectorDialog({super.key, required this.initialCurrentSeason});

  final String initialCurrentSeason;

  @override
  State<SeasonSelectorDialog> createState() => _SeasonSelectorDialogState();
}

class _SeasonSelectorDialogState extends State<SeasonSelectorDialog> with PageDownloaderMixin {

  List<String> _seasonList = [];

  List<Widget> buildSeasonTile(String season)
  {
    return [ListTile(
      leading: Text(season,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 19),
        textAlign: TextAlign.center,
      ),
      trailing: (season == widget.initialCurrentSeason ? const Icon(Icons.check_circle, size: 25) : null),
      dense: true,
      onTap: () {
        Navigator.of(context).pop(season);
      },
    ),
    const Divider()];
  }
  
  Widget getSeasonsBody(BuildContext context)
  {
    return ListView(
      padding: const EdgeInsets.only(top: 15, left: 5, right: 5),
      shrinkWrap: true,
      children: _seasonList.map((e) => buildSeasonTile(e)).expand((element) => element).toList(),
    );
  }

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/seasons/?param=1"
                                         : "$defaultEndpointURL/getSeasons.php";

  @override
  Future<bool> parseDownloadedData(final String body) async
  {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
      _seasonList = List.from(json.keys);
    } on Exception catch (_, e) {
      debugPrint("Exception on reading seasons: $e");
      return false;
    }
    debugPrint("Seasons downloaded successfully.");
    return true;
  }
  
  @override
  void initState()
  {
    super.initState();
    pageDownloaderInit();
  }

  @override
  Widget downloadOK()
  {
    return getSeasonsBody(context);
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child:Scaffold(
      appBar: MyAppBar(title: const Text("Seleziona Stagione"), centerTitle: true),
      body: getEntireRefreshablePage(),
    ));
  }
}
