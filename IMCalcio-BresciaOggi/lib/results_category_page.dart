// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/image_loader.dart';
import 'package:imcalcio/classes/sidebar_stuff.dart';
import 'package:imcalcio/results_committee_page.dart';
import 'package:imcalcio/results_regions_page.dart';
import 'package:imcalcio/results_subcategory_page.dart';
import 'package:imcalcio/search_page.dart';
import 'package:imcalcio/season_selector_dialog.dart';

//TEMPLATE 1

class ResultsCategoryPage extends StatefulWidget {
  const ResultsCategoryPage({super.key});

  @override
  State<ResultsCategoryPage> createState() => _ResultsCategoryPageState();
}

String getCurrentSeason()
{
  final DateTime now = DateTime.now();
  final int year = now.year;

  if (now.isAfter(DateTime(year, 7, 30)))   //If today is after July 30, select next season.
    return "$year-${year + 1}";
  else
    return "${year - 1}-$year";
}

class _ResultsCategoryPageState extends State<ResultsCategoryPage> {
  static const Image proprietaryImageBrescia = Image(image: AssetImage("images/categories/Brescia.png"));

  static List<String> categoryNames = ["Brescia"];
  static List<Image> categoryImages = [proprietaryImageBrescia];

  late String selectedSeason;

  @override
  void initState()
  {
    super.initState();
    selectedSeason = getCurrentSeason();
  }

  Widget buildCategory(BuildContext context, String categoryName, Image categoryImage)
  {
    double totalHeight = MediaQuery.of(context).size.height;
    return ElevatedButton(onPressed: (){
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ResultsCommitteePage(selectedCategoryName: "Provinciale", selectedRegion: "Lombardia", selectedSeason: selectedSeason)));

    },
        style: ButtonStyle(
          shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: const BorderSide(color: Colors.black, width: 1.0)
              )
          ),
          backgroundColor: const MaterialStatePropertyAll(Colors.white),
        ),
        child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: totalHeight / 10),
            child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 35,
                          minHeight: 35,
                          maxWidth: 70,
                          maxHeight: 70
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: categoryImage,
                        )
                    ),
                  ),
                  Expanded(
                    //width: MediaQuery.of(context).size.width * .5,
                    flex: 3,
                    child: /*AutoSizeText("   $categoryName",  maxFontSize: 40, style: const TextStyle(
                        color: Colors.black,
                      ), textAlign: TextAlign.start
                    ),*/ AutoSizeText(" $categoryName",
                      maxFontSize: 40,
                      minFontSize: 18,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 40
                      ),
                      textAlign: TextAlign.start
                    )
                  ),
                ],
              ),
            )
    );
  }

  Widget getSeasonTextSelector()
  {
    const Text seasonText = Text(
      "Stagione ",
      style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800
      ),
    );

    Widget currentSeasonText = Text(
        selectedSeason,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.black,
          fontWeight: FontWeight.w400
        )
    );

    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 15),
      child: InkWell(
        onTap: () async {
        String? newSeason = await Navigator.of(context)
            .push(MaterialPageRoute<String>(builder: (context) => SeasonSelectorDialog(initialCurrentSeason: selectedSeason)));
        if (newSeason != null) {
          setState(() {
            selectedSeason = newSeason;
          });
        }
      },

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [seasonText, currentSeasonText, const Icon(Icons.arrow_drop_down)]
        ),
      ),
    );
  }

  Widget getBody(BuildContext context)
  {
    List<Widget> list = [];

    for (int i = 0; i < categoryImages.length; i++)
    {
      Widget category = buildCategory(context, categoryNames[i], categoryImages[i]);
      list.add(category);
      list.add(const Padding(padding: EdgeInsets.only(top: 30.0)));
    }

    ListView resultsList = ListView(
      shrinkWrap: true,
      children: list,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 15.0, bottom: 30.0),
      //alignment: Alignment.topCenter,
      child: Stack(
        children: [
          Column(
            children: [
              getSeasonTextSelector(),
              const Padding(padding: EdgeInsets.only(top: 15.0),),
              resultsList
            ],
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      displayBannerAd: false,
      child: ScaffoldWithSidebar(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("SportBrescia", textAlign: TextAlign.center),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SearchPage(startingSeason: selectedSeason)));
              },
            )
          ]
        ),
        body: getBody(context),
      ),
    );
  }
}
