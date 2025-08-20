// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/image_loader.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/pair.dart';
import 'package:imcalcio/results_championship_page.dart';

//Submenu for "Nazionale" and "Estero"
class ResultsSubcategoryPage extends StatefulWidget {
  const ResultsSubcategoryPage({super.key, required this.categoryName, required this.selectedSeason});

  final String categoryName;
  final String selectedSeason;

  @override
  State<ResultsSubcategoryPage> createState() => _ResultsSubcategoryPageState();
}

class _ResultsSubcategoryPageState extends State<ResultsSubcategoryPage> with PageDownloaderMixin {

  late final List<Pair<int,String>> _subcategories = []; //Pair of id, name

  @override
  void initState()
  {
    super.initState();
    pageDownloaderInit();
  }

  @override
  /*String get downloadUrl => "$defaultEndpointURL/getSubcategory.php"
      "?season=${widget.selectedSeason}"
      "&category=${widget.categoryName}";*/
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/committees/subcategories/"
                                            "?season=${widget.selectedSeason}"
                                            "&category=${widget.categoryName}"
                                         : "$defaultEndpointURL/getSubcategory.php"
                                            "?season=${widget.selectedSeason}"
                                            "&category=${widget.categoryName}";

  @override
  Future<bool> parseDownloadedData(final String body) async
  {
    debugPrint("Body: $body");
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
      if (!json.containsKey("subcategories")) {
        throw Exception("Key subcategories does not exist.");
      }
    } on Exception catch (_,e) {
      debugPrint("Json error: $e");
      return false;
    }

    try {
      List<Map<String, dynamic>> jsons = List.from(json["subcategories"]);
      for (Map<String, dynamic> m in jsons)
      {
        final int id = int.parse(m["id"].toString());
        final String name = m["name"];
        _subcategories.add(Pair(id, name));
      }
    } on Exception catch (_, e) {
      debugPrint("Exception on reading subcategories: $e");
      return false;
    }
    debugPrint("Subcategories downloaded successfully.");
    return true;
  }

  Widget getSubcategoryButton(Pair<int, String> subcategory)
  {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
        ResultsChampionshipPage(selectedRegion: "", selectedSeason: widget.selectedSeason, selectedCategoryName: widget.categoryName, selectedCommittee: subcategory))),
      child: Card(
        color: Colors.white,
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(flex: 2, child: ImageLoader.instance().getImage("comitati/${subcategory.second}", placeholder: "committeeGeneric")),
              Flexible(child:
                AutoSizeText(
                  subcategory.second, textAlign: TextAlign.center,
                  maxLines: 2,
                  maxFontSize: 16,
                  minFontSize: 10,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,

                  ),
                )
              )
            ],
          ),
        )
      ),
    );
  }

  Widget getSubcategoriesBody()
  {
    if (_subcategories.isEmpty)
      return const Padding(
        padding: EdgeInsets.only(top: 20, left: 10, right: 10),
        child: Text("Non sono disponibili categorie per i criteri di ricerca selezionati.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600, fontSize: 20),
          softWrap: true,
        ),
      );
          
    return GridView.count(
        primary: false,
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        padding: const EdgeInsets.all(20),
        childAspectRatio: (1 / .9),
        children: _subcategories.map((e) => getSubcategoryButton(e)).toList()
    );
  }

  @override
  Widget downloadOK()
  {
    return getSubcategoriesBody();
  }


  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: MyAppBar(title: const Text("Comitato"), centerTitle: true),
        body: getEntirePage(),
      ),
    );
  }
}
