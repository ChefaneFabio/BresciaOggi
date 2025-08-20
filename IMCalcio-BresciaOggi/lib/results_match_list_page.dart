// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/match.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/results_match_page.dart';
import 'package:intl/intl.dart';

//TODO: PARTITA LIVE, NON ANCORA INIZIATA, ECC..

class ResultsMatchListPage extends StatefulWidget {
  const ResultsMatchListPage({super.key,
    required this.selectedSeason,
    required this.selectedCategoryName,
    required this.selectedCommittee,
    required this.selectedChampionship,
    required this.selectedChampionshipID,
    required this.selectedGroup,
    required this.selectedGroupID,
    required this.appBarTitle
  });

  final String selectedSeason;
  final String selectedCategoryName;
  final String selectedCommittee;

  final String selectedChampionship;
  final int selectedChampionshipID;
  final String selectedGroup;
  final int selectedGroupID;

  final Widget Function() appBarTitle;

  @override
  State<ResultsMatchListPage> createState() => _ResultsMatchListPageState();
}

class _ResultsMatchListPageState extends State<ResultsMatchListPage> with TickerProviderStateMixin, PageDownloaderMixin {
  TabController? _tabController;

  late List<MatchList> matchDays;

  late int numDays; //Num of days of the championship

  @override
  void initState() {
    super.initState();
    pageDownloaderInit();
  }

  @override
  /*String get downloadUrl => "$defaultEndpointURL/getMatchList.php"
      "?season=${widget.selectedSeason}"
      "&group_id=${widget.selectedGroupID}"
      "&championship_id=${widget.selectedChampionshipID}";*/
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/matches/?season=${widget.selectedSeason}"
                                          "&campionato_id=${widget.selectedChampionshipID}"
                                          "&group_id=${widget.selectedGroupID}"
                                       : "$defaultEndpointURL/getMatchList.php"
                                          "?season=${widget.selectedSeason}"
                                          "&group_id=${widget.selectedGroupID}"
                                          "&championship_id=${widget.selectedChampionshipID}";

  @override
  int get downloadTries => 3;

  @override
  Future<bool> parseDownloadedData(final String body) async
  {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
      if (!json.containsKey("matches")) {
        throw Exception("Key matches does not exist.");
      }
      if (!json.containsKey("numDays")) {
        throw Exception("Key numDays does not exist.");
      }
    } on Exception catch (_, e) {
      debugPrint("Json error: $e");
      return false;
    }

    try {
      matchDays = MatchList.dayListFromJson(json);
      numDays = int.parse(json["numDays"].toString());
    } on Exception catch (d, e) {
      debugPrint("Decode error: $d\n$e");
      return false;
    }

    //Find the nearest in time day
    int dayToSelect = matchDays.length - 1; //Last
    DateTime now = DateTime.now();
    for (int i = 0; i < matchDays.length; i++)
    {
      MatchList mList = matchDays[i];
      if (mList.matches.isEmpty || mList.matches[0].date == null)
        continue;
      DateTime date = mList.matches[0].date!;
      if (date.isAfter(now)) //If This date is after now, select it.
      {
        dayToSelect = i;
        break;
      }
    }
    /*debugger();*/
    _tabController = TabController(length: matchDays.length, vsync: this, initialIndex: dayToSelect);

    return true;
  }

  @override
  void dispose() {
    if (_tabController != null)
      _tabController!.dispose();
    super.dispose();
  }

  Widget getTabsBody()
  {
    return TabBarView(
      controller: _tabController,
      children: List.generate(matchDays.length, (index) {
        return wrapIntoRefreshIndicator(() => ResultsDayPage(selectedChampionship: widget.selectedChampionship,
            selectedGroup: widget.selectedGroup, selectedSeason: widget.selectedSeason, matchDay: matchDays[index],
          stringDay: "${index+1}/${index < numDays / 2 ? "A" : "R"}", selectedChampionshipID: widget.selectedChampionshipID, selectedGroupID: widget.selectedGroupID));
      })
    );
  }

  TabBar getTabs()
  {
    return TabBar(
      isScrollable: true,
      controller: _tabController,
      tabs: List.generate(numDays, (index) {
        String type = index < numDays / 2 ? "A" : "R";
        return Tab(
          child: Row(
            children: [
              const Icon(Icons.calendar_today),
              Text(" Giornata ${index + 1}/$type")
            ],
          ),
        );
      })
    );
  }

  @override
  Widget downloadFailed()
  {
    return wrapIntoRefreshIndicator(super.downloadFailed);
  }

  @override
  Widget downloadError500()
  {
    return wrapIntoRefreshIndicator(super.downloadError500);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: downloadFuture, builder: (BuildContext context, AsyncSnapshot<DownloadStatus> snapshot) {
      if (snapshot.hasData && snapshot.data! == DownloadStatus.ok) { //If download OK
        //Already parsed
        return downloadOK();
      }
      else if (snapshot.hasData && (snapshot.data! == DownloadStatus.error500) || snapshot.hasError) { //If download error or has downloaded something wrong
        return BackgroundContainer(
          child: Scaffold(
              appBar: MyAppBar(title: widget.appBarTitle(), centerTitle: true),
              body: downloadError500()
          ),
        );
      }
      else if (snapshot.hasData && (snapshot.data! == DownloadStatus.genericError) || snapshot.hasError) { //If download error or has downloaded something wrong
        return BackgroundContainer(
          child: Scaffold(
              appBar: MyAppBar(title: widget.appBarTitle(), centerTitle: true),
              body: downloadFailed()
          ),
        );
      }
      else { //Is downloading
        return BackgroundContainer(
          child: Scaffold(
            appBar: MyAppBar(title: widget.appBarTitle(), centerTitle: true),
            body: downloading(),
          ),
        );
      }
    });
  }

  @override
  Widget downloadOK() {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
        appBar: MyAppBar(title: widget.appBarTitle(), centerTitle: true, bottom: getTabs(),
            actions: [
              IconButton(icon: const Icon(Icons.first_page),
                onPressed: () {
                  setState(() {
                    _tabController!.animateTo(0);
                  });
                },
                tooltip: "Andata",
              ),
              IconButton(icon: const Icon(Icons.last_page), onPressed: () {
                setState(() {
                  _tabController!.animateTo((numDays / 2).floor());
                });
                },
                tooltip: "Ritorno",
            )]),
        body: getTabsBody(),
      );

  }
}

String capitalizeFirstMonth(String inputDate) {
  List<String> parts = inputDate.split(" ");

  if (parts.length == 3) {
    String day = parts[0];
    String month = parts[1];
    String year = parts[2];

    if (month.isNotEmpty) {
      // Capitalize the first character of the month
      month = month[0].toUpperCase() + month.substring(1);
    }

    return '$day $month $year';
  } else {
    // Handle invalid input
    return inputDate;
  }
}

class ResultsDayPage extends StatefulWidget { //Singola giornata
  const ResultsDayPage({super.key, required this.selectedSeason, required this.selectedChampionship, required this.selectedChampionshipID,
    required this.selectedGroup, required this.selectedGroupID, required this.matchDay, required this.stringDay});

  final String selectedSeason;
  final String selectedChampionship;
  final int selectedChampionshipID;
  final String selectedGroup;
  final int selectedGroupID;
  final MatchList? matchDay;
  final String stringDay;

  @override
  State<ResultsDayPage> createState() => ResultsDayPageState();
}

class ResultsDayPageState extends State<ResultsDayPage> with AutomaticKeepAliveClientMixin {

  @override
  void initState()
  {
    super.initState();
    debugPrint("ResultsDayPage init");
    debugPrint("matchList: ${widget.matchDay!.matches}");
  }


  static void goToMatchPage(final BuildContext context, final Match match, final String season, final int championshipID, final String championship,
      final int groupID, final String group, final String dayString)
  {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
        ResultsMatchPage(selectedSeason: season, selectedChampionship: championship, selectedChampionshipID: championshipID,
            selectedGroup: group, selectedGroupID: groupID, matchDay: match.day, beginMatch: match, matchDayString: dayString)));
  }

  static Widget _getScoreText(final Match match)
  {
    const TextStyle scoreStyle = TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700
    );

    final String text = match.getScoreText();

    if (match.isLive())
      return LiveScoreText(score: text, size: 17.0);
    return Text(text, style: scoreStyle);
  }

  static Widget getMatchWidget(final BuildContext context, final Match match, final String season, final int championshipID,
      final String championship, final int groupID, final String group, final String dayString, {Color headerColor = const Color.fromARGB(255, 255, 192, 100)})
  {
    const double crestWidth = 35.0;
    const double crestHeight = 35.0;
    const TextStyle crestStyle = TextStyle( //Team1, Team2
      fontWeight: FontWeight.w400,
      fontSize: 17,
      color: Color.fromARGB(255, 50, 50, 50)
    );

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          color: headerColor,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            title: Text((){
                if (match.date == null) {
                  return "Data da definirsi";
                }
                if (match.postponed == null) {
                  return capitalizeFirstMonth(DateFormat("dd MMMM yyyy ore HH:mm","it").format(match.date!));
                }
                return capitalizeFirstMonth(DateFormat("dd MMMM yyyy ore HH:mm","it").format(match.postponed!));
              }(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)
            ),
            leading: const Icon(Icons.add, color: Colors.transparent), //To preserve symmetric
            trailing: IconButton(icon: const Icon(Icons.arrow_forward),
                onPressed: () => goToMatchPage(context, match, season, championshipID, championship, groupID, group, dayString)),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
          //color: const Color.fromARGB(255, 255, 192, 100),
          child: GestureDetector(
            onTap: () => goToMatchPage(context, match, season, championshipID, championship, groupID, group, dayString),
            //dense: true,
            child: Row( //Row of name1 icon1 score1 : score2 icon2 team2
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  flex: 3,
                  fit: FlexFit.tight,
                  child: Text(match.team1.name, style: crestStyle, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis), //Name1
                ),
                Container(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                          width: crestWidth,
                          height: crestHeight,
                          child: match.team1.icon //Icon1
                      ),
                      const Padding(padding: EdgeInsets.only(left: 5)),
                      _getScoreText(match), //Handles live or not + date (if match future, returns - : -
                      const Padding(padding: EdgeInsets.only(left: 5)),
                      SizedBox(
                        width: crestWidth,
                        height: crestHeight,
                        child: match.team2.icon
                      )
                    ],
                  )
                ),
                Flexible(
                  //width: MediaQuery.of(context).size.width * .3,
                  flex: 3,
                  fit: FlexFit.tight,
                  child: Text(match.team2.name, style: crestStyle, textAlign: TextAlign.left, overflow: TextOverflow.ellipsis),
                )
              ],
            ),
          ),
        ),
        const Divider(height: 5, thickness: 2, indent: 10, endIndent: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.matchDay != null && widget.matchDay!.matches.isNotEmpty) {
      return ListView(
          shrinkWrap: true,
          children: widget.matchDay != null ? widget.matchDay!.matches
              .map((e) => getMatchWidget(
                  context, e, widget.selectedSeason, widget.selectedChampionshipID,
                  widget.selectedChampionship, widget.selectedGroupID, widget.selectedGroup, widget.stringDay))
              .toList() : [Container()]
      );
    }
    else //If there are no matches for this day
      return const Center(
        child: AutoSizeText("Le partite sono in fase di aggiornamento", minFontSize: 10, maxFontSize: 30, style: TextStyle(fontSize: 25), textAlign: TextAlign.center,),
      );
  }

  @override
  bool get wantKeepAlive => true;
}

class LiveScoreText extends StatefulWidget {
  const LiveScoreText({Key? key, required this.score, required this.size}) : super(key: key);

  final String score;
  final double size;

  @override
  State<LiveScoreText> createState() => _LiveScoreTextState();
}

class _LiveScoreTextState extends State<LiveScoreText> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = Tween(begin: 1.0, end: 0.3).animate(_animationController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _animationController.forward();
        }
      });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FadeTransition(
          opacity: _animation,
          child: Text(
            widget.score,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: widget.size,
            ),
          ),
        ),
        const Text("LIVE", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red))
      ],
    );
  }
}