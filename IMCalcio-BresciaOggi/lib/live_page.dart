// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/championship.dart';
import 'package:imcalcio/classes/image_loader.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/match.dart';
import 'package:imcalcio/results_category_page.dart';
import 'package:imcalcio/results_match_list_page.dart';

class LiveMatchInfo {
  final Match match;
  final Championship championship;
  final String committeeName;
  final String groupName;
  final int groupID;
  final int day;
  final int numDays;

  const LiveMatchInfo(this.match, this.championship, this.committeeName, this.groupName, this.groupID, this.day, this.numDays);
}

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> with PageDownloaderMixin {
  
  Map<int, List<LiveMatchInfo>> matches = {};

  @override
  void initState()
  {
    super.initState();
    pageDownloaderInit();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: const MyAppBar(title: const Text("Partite live"), centerTitle: true),
        body: getEntireRefreshablePage(),
      ),
    );
  }

  void _championshipClicked(final Championship matchInfo, final Match match)
  {

  }

  @override
  Widget downloadOK() {

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), //For refresh indicator
      padding: const EdgeInsets.all(4.0),
      child: matches.isEmpty ? const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text("Non ci sono partite live in questo momento.",
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 25, color: Colors.red)),
      ) : Column(
        children: matches.map((id, matches) => MapEntry(id, LiveChampionshipDropdown(matches: matches, onClicked: _championshipClicked))).values.toList()
      )
    );
  }

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/matches/live/" : "$defaultEndpointURL/getLiveMatches.php";

  @override
  Future<bool> parseDownloadedData(String body) async {
    Map<String,dynamic> json;
    try {
      json = jsonDecode(body);
    } catch (e) {
      debugPrint("Decode error: $e");
      return false;
    }

    List<LiveMatchInfo> newMatches = [];

    List<Map<String,dynamic>> jsons = List.from(json["liveMatches"]);
    for (Map<String,dynamic> matchJson in jsons)
    {
      try {
        Match? match = Match.fromJson(matchJson);
        if (match == null) {
          debugPrint("Match is null");
          continue;
        }

        Championship championship = Championship(
            matchJson["ChampionshipName"], int.parse(matchJson["ChampionshipID"].toString()));
        String committeeName = matchJson["CommitteeName"];
        String groupName = matchJson["GroupName"];
        int groupID = int.parse(matchJson["GroupID"].toString());
        int day = int.parse((matchJson["day"] ?? matchJson["Day"]).toString());
        int maxDays = int.parse((matchJson["NumDays"] ?? matchJson["MaxDay"]).toString());

        newMatches.add(LiveMatchInfo(match, championship, committeeName, groupName, groupID, day, maxDays));
      } catch (e, f) {
        debugPrint("Error of live match json decoding: $e, $f");
        continue;
      }
    }
    matches = {};
    for (LiveMatchInfo lm in newMatches)
    {
      if (matches.containsKey(lm.championship.id))
        matches[lm.championship.id]!.add(lm);
      else
        matches[lm.championship.id] = [lm];
    }

    return true;
  }
}

class LiveChampionshipDropdown extends StatefulWidget {
  const LiveChampionshipDropdown(
      {super.key, required this.matches, required this.onClicked});

  final List<LiveMatchInfo> matches;
  final void Function(Championship, Match) onClicked; //Callback

  @override
  State<LiveChampionshipDropdown> createState() =>
      _LiveChampionshipDropdownState();
}

class _LiveChampionshipDropdownState extends State<LiveChampionshipDropdown>
    with TickerProviderStateMixin {

  static const double fontSize = 18.0;

  static const double padding = 5.0;

  static _LiveChampionshipDropdownState? _openMenu; //The Championship that is open. Only one championship at time can be open.

  bool _open = false;

  late final String season;

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

  @override
  void initState()
  {
    super.initState();
    season = getCurrentSeason();
  }

  Widget _getDecoratedCard(bool topPadding, Widget child, bool top) {
    return Card(
        margin: EdgeInsets.only(top: (topPadding ? padding : 0.0), right: padding, left: padding),
        shape: RoundedRectangleBorder(
          borderRadius: top ? const BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)) :
                              const BorderRadius.only(bottomLeft: Radius.circular(20.0), bottomRight: Radius.circular(20.0)),
          side: const BorderSide(
            color: Colors.white30,
            width: 2.0,
          ),
        ),
        color: Colors.white,
        elevation: 2.0,
        child: child);
  }

  @override
  Widget build(BuildContext context) {
    final Championship champ = widget.matches[0].championship; //They are all the same
    final String committeeName = widget.matches[0].committeeName;
    final String groupName = widget.matches[0].groupName;
    return Padding(
      padding: const EdgeInsets.only(left: padding, right: padding, top: padding),
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
                  if (champ.getIcon(season) != ImageLoader.instance().placeholder)
                    SizedBox(
                        width: 0, //TODO INSERT 60 WHEN CHAMPIONSHIP'S LOGO PRESENT
                        height: 60,
                        child: champ.getIcon(season)
                    ),
                    Expanded(
                      child: Text(committeeName.isEmpty ? champ.name : "$committeeName\n${champ.name} $groupName",
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                              fontSize: fontSize, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: _open
                    ? const Icon(Icons.keyboard_arrow_down)
                    : const Icon(Icons.keyboard_arrow_right),
                onPressed: _toggleCard,
              )), true //TOP
          ),
          _getDecoratedCard(false, AnimatedSize(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: _open ? null : 0, // Set height based on _open state
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: widget.matches.map((m) =>
                  ResultsDayPageState.getMatchWidget(context, m.match, season, m.championship.id, m.championship.name,
                    m.groupID, m.groupName, m.day - 1 < m.numDays / 2 ? "${m.day}/A" : "${m.day}/R",
                      headerColor: const Color.fromARGB(255, 200, 200, 200))).toList()
            )),
          ), false),
        ],
      ),
    );
  }
}

