// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/championship.dart';
import 'package:imcalcio/classes/image_loader.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/pair.dart';
import 'package:imcalcio/details_dispatcher_page.dart';

//TEMPLATE 3

class ResultsChampionshipPage extends StatefulWidget {
  const ResultsChampionshipPage(
      {super.key,
      required this.selectedSeason,
      required this.selectedRegion,
      required this.selectedCategoryName,
      required this.selectedCommittee});

  final String selectedSeason;
  final String selectedRegion;
  final String selectedCategoryName;
  final Pair<int, String> selectedCommittee;

  @override
  State<ResultsChampionshipPage> createState() =>
      _ResultsChampionshipPageState();
}

class _ResultsChampionshipPageState extends State<ResultsChampionshipPage> with PageDownloaderMixin {

  late List<Championship> _championships;

  static const double groupFontSize = 17.0;
  static const double championshipFontSize = 24.0;

  @override
  void initState() {
    super.initState();
    pageDownloaderInit();
  }

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/champs/championships/"
                              "?season=${widget.selectedSeason}"
                              "&region=${widget.selectedRegion}"
                              "&category=${widget.selectedCategoryName}"
                              "&committee_id=${widget.selectedCommittee.first}"
                          : "$defaultEndpointURL/getChampionship.php"
                              "?season=${widget.selectedSeason}"
                              "&region=${widget.selectedRegion}"
                              "&category=${widget.selectedCategoryName}"
                              "&committeeID=${widget.selectedCommittee.first}";


  @override
  int get downloadTries => 1;

  @override
  Future<bool> parseDownloadedData(final String body) async
  {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
      if (!json.containsKey("championships")) {
        throw Exception("Key championships does not exist.");
      }
    } on Exception catch (_,e) {
      debugPrint("Json error: $e");
      return false;
    }

    try {
      _championships = Championship.getChampionshipList(json);
    } on Exception catch (_, e) {
      debugPrint("Exception on reading sectorNames: $e");
      return false;
    }
    debugPrint("Championships downloaded successfully.");
    return true;
  }

  void _championshipClicked(final int championshipID, final String championshipName, final int groupID, final String groupName) async
  {
    ChampionshipDetailsPage? chosen = await openChooseDetailsPageDialog(groupName, championshipName, context);

    if (chosen == null)
      return;

    goToNextPage(championshipID, championshipName, groupID, groupName, chosen);
  }

  void goToNextPage(final int championshipID, final String championship, final int groupID, final String group, final ChampionshipDetailsPage nextPage)
  {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
        ChampionshipDetailsDispatcherPage(initialPage: nextPage, selectedSeason: widget.selectedSeason,
            selectedCommittee: widget.selectedCommittee.second, selectedCommitteeID: widget.selectedCommittee.first,
            selectedCategory: widget.selectedCategoryName, selectedChampionship: championship, selectedChampionshipID: championshipID,
            selectedGroup: group, selectedGroupID: groupID)));
  }

  Widget getChampionshipsBody(BuildContext context) //When download success
  {
    if (_championships.isEmpty)
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child:  Text("Non sono disponibili campionati per i criteri di ricerca selezionati.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.w600, fontSize: 20),
          softWrap: true,
        ),
      );

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      shrinkWrap: true,
      children: _championships.map((c) => ChampionshipDropdownMenu(championship: c, season: widget.selectedSeason, onClicked: _championshipClicked)).toList(),
    );
  }

  @override
  Widget downloadOK()
  {
    return getChampionshipsBody(context);
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: const MyAppBar(
          title: Text("Campionato"),
          centerTitle: true,
        ),
        body: getEntirePage(),
      ),
    );
  }
}

class ChampionshipDropdownMenu extends StatefulWidget {
  const ChampionshipDropdownMenu(
      {super.key, required this.championship, required this.season, required this.onClicked});

  final Championship championship;
  final String season;
  final void Function(int, String, int, String) onClicked; //Callback

  @override
  State<ChampionshipDropdownMenu> createState() =>
      _ChampionshipDropdownMenuState();
}

class _ChampionshipDropdownMenuState extends State<ChampionshipDropdownMenu>
    with TickerProviderStateMixin {

  static _ChampionshipDropdownMenuState? _openMenu; //The Championship that is open. Only one championship at time can be open.

  bool _open = false;

  void _toggleCard() {
    if (_open)
      _closeDropdown();
    else
      _openDropdown();
  }

  void _closeDropdown()
  {
    setState(() {
      _open = false;
    });
    if (_openMenu == this)
      _openMenu = null;
  }

  void _openDropdown()
  {
    setState(() {
      _open = true;
    });
    if (_openMenu != null) //Close the open dropdown.
      _openMenu!._closeDropdown();
    _openMenu = this;
  }

  @override
  void dispose()
  {
    super.dispose();
    if (_openMenu == this)
      _openMenu = null;
  }

  Widget _buildGroups() {
    List<Widget> groupTiles = [];
    for (Pair<int,String> group in widget.championship.groups) {
      Widget tile = ListTile(
        onTap: () => widget.onClicked(widget.championship.id, widget.championship.name, group.first, group.second),
        minVerticalPadding: 0.0,
        dense: false,
        title: Text("Girone ${group.second}", style: const TextStyle(fontSize: _ResultsChampionshipPageState.groupFontSize)), //todo
        contentPadding: const EdgeInsets.only(left: 15, right: 15, bottom: 0),
        visualDensity: VisualDensity.compact,
        trailing: IconButton(icon: const Icon(Icons.keyboard_arrow_right),
          onPressed: () => widget.onClicked(widget.championship.id, widget.championship.name, group.first, group.second)),

      );
      groupTiles.add(tile);
      groupTiles.add(const Divider(height: 1, thickness: 2));
    }
    groupTiles.removeLast(); //Remove the last Divider

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: groupTiles,
    );
  }

  Widget _getDecoratedCard(bool topPadding, Widget child) {
    return Card(
      margin: EdgeInsets.only(top: (topPadding ? 10.0 : 0.0), right: 10.0, left: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: const BorderSide(
          color: Colors.black,
          width: 1.0,
        ),
      ),
      color: Colors.white,
      elevation: 2.0,
      child: child);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _getDecoratedCard(true, ListTile(
                onTap: _toggleCard,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (widget.championship.getIcon(widget.season, placeholderOnFail: true) != ImageLoader.instance().placeholder)
                        SizedBox(
                            width: 60,
                            height: 60,
                            child: widget.championship.getIcon(widget.season, placeholderOnFail: true)
                        ),
                    Expanded(
                      child: Text(widget.championship.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: _ResultsChampionshipPageState.championshipFontSize, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: _open
                      ? const Icon(Icons.keyboard_arrow_down)
                      : const Icon(Icons.keyboard_arrow_right),
                  onPressed: _toggleCard,
                )),
          ),
          _getDecoratedCard(false, AnimatedSize(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: SizedBox(
                height: _open ? null : 0, // Set height based on _open state
                width: MediaQuery.of(context).size.width * .5,
                child: _buildGroups()),
          )),
        ],
      ),
    );
  }
}
