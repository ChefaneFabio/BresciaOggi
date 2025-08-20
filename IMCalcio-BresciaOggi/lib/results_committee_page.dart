// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/pair.dart';
import 'package:imcalcio/results_championship_page.dart';

//TEMPLATE 3

class ResultsCommitteePage extends StatefulWidget {
  const ResultsCommitteePage(
      {super.key,
      required this.selectedSeason,
      required this.selectedRegion,
      required this.selectedCategoryName});

  final String selectedSeason;
  final String selectedRegion;
  final String selectedCategoryName;

  @override
  State<ResultsCommitteePage> createState() => _ResultsCommitteePageState();
}

class _ResultsCommitteePageState extends State<ResultsCommitteePage> with PageDownloaderMixin {

  late List<Pair<int,String>> _sectors; //pair ID, name
  late List<IconData> _sectorIcons;


  @override
  String get downloadUrl => "$remoteAPIURL/champs/search/province/?name=Brescia";//Era getSector.php

  @override
  Future<bool> parseDownloadedData(String body) async {
    debugPrint("Body: $body");
    List<dynamic> json;
    List<Map<String, dynamic>> jsons;
    try {
      json = jsonDecode(body);
      jsons = json.map((g) => Map<String, dynamic>.from(g)).toList();
    } on Exception catch (_,e) {
      debugPrint("Json error: $e");
      return false;
    }
    _sectors = [];
    try {
      for (Map<String, dynamic> m in jsons)
      {
        final int id = int.parse(m["comitatoID"].toString());
        final String name = m["comitatoName"];
        if (_sectors.where((Pair<int,String> e) => e.first == id).isEmpty) //Removes group duplicates
          _sectors.add(Pair(id, name));
      }
     _sectorIcons = List.filled(_sectors.length, Icons.flag);
    } on Exception catch (_, e) {
      debugPrint("Exception on reading sectorNames: $e");
      return false;
    }
    debugPrint("Categories downloaded successfully.");
    return true;
  }

  @override
  void initState() {
    super.initState();
    pageDownloaderInit();
  }

  Widget buildCommittee(
      BuildContext context, Pair<int, String> committee, IconData categoryIcon) {
    double totalHeight = MediaQuery.of(context).size.height;
    return ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
              ResultsChampionshipPage(selectedSeason: widget.selectedSeason, selectedRegion: widget.selectedRegion,
                  selectedCategoryName: widget.selectedCategoryName, selectedCommittee: committee)));
        },
        style: ButtonStyle(
          shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: const BorderSide(color: Colors.black, width: 1.0))),
          backgroundColor: const MaterialStatePropertyAll(Colors.white),
        ),
        child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: totalHeight / 12),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(categoryIcon, size: 20, color: Colors.black),
                Flexible(
                  child: Text(
                    "   ${committee.second}",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 19,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
              ],
            )));
  }

  Widget getCategoryBody(BuildContext context) { //Once the categories have been downloaded

    if (_sectors.isEmpty)
        return const Padding(
          padding: EdgeInsets.all(20.0),
          child:  Text("Non sono disponibili comitati per i criteri di ricerca selezionati.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.w600, fontSize: 20),
            softWrap: true,
          ),
        );

    List<Widget> list = [];

    for (int i = 0; i < _sectors.length; i++) {
      Widget category = buildCommittee(context, _sectors[i], _sectorIcons[i]);
      list.add(category);
      list.add(const Padding(padding: EdgeInsets.only(top: 15.0)));
    }

    ListView resultsList = ListView(
      shrinkWrap: true,
      children: list,
    );

    return Container(
      padding: const EdgeInsets.only(
          left: 30.0, right: 30.0, top: 20.0, bottom: 20.0),
      alignment: Alignment.topCenter,
      child: resultsList,
    );
  }

  @override
  Widget downloadOK()
  {
    return getCategoryBody(context);
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: const MyAppBar(
          title: Text("Comitato"),
          centerTitle: true,
        ),
        body: getEntirePage(),
      ),
    );
  }
}
