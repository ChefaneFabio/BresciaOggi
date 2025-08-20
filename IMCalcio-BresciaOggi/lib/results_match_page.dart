// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/Material.dart';
import 'package:imcalcio/add_match_photo_page.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/match.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/django_auth.dart';
import 'package:imcalcio/formations_page.dart';
import 'package:imcalcio/report_page.dart';
import 'package:imcalcio/results_match_list_page.dart';
import 'package:imcalcio/events_page.dart';
import 'package:imcalcio/scoreboard_page.dart';
import 'package:imcalcio/team_page.dart';

import 'package:intl/intl.dart';

class ResultsMatchPage extends StatefulWidget {
  const ResultsMatchPage(
      {super.key,
      required this.selectedSeason,

      required this.selectedChampionship,
      required this.selectedChampionshipID,
      required this.selectedGroup,
      required this.selectedGroupID,
      required this.matchDay,
      required this.beginMatch,
      required this.matchDayString});

  final String selectedSeason;

  final String selectedChampionship;
  final int selectedChampionshipID;
  final String selectedGroup;
  final int selectedGroupID;
  final int matchDay;
  final Match beginMatch; //Match that is not updated
  final String matchDayString;

  void goToTeamPage(final BuildContext context, final Team partialTeam)
  {
    Team completeTeam = Team.getTeam(partialTeam.name, id: partialTeam.id, championship: selectedChampionship,
        championshipID: selectedChampionshipID, group: selectedGroup, groupID: selectedGroupID, season: selectedSeason);
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => TeamPage(team: completeTeam)));
  }

  @override
  State<ResultsMatchPage> createState() => ResultsMatchPageState();
}

class ResultsMatchPageState extends State<ResultsMatchPage>
    with TickerProviderStateMixin, PageDownloaderMixin {
  static const List<String> tabNames = [
    "Formazioni",
    "Eventi e Gol",
    "Cronaca",
    "Classifica",
    "Commenti"
  ];
  late final double matchCardHeight; //It was 180
  late TabController _tabController;

  late Match match; //Can be updated

  @override
  void initState() {
    super.initState();
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    matchCardHeight = view.physicalSize.height / view.devicePixelRatio * .2;
    debugPrint("MatchCardHeight: $matchCardHeight");
    _tabController = TabController(length: tabNames.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    match = widget.beginMatch;
    pageDownloaderInit();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  Widget _getTeamWidget(final Team team) { //Square container in the top box with the other team
    return GestureDetector(
      onTap: () {
        widget.goToTeamPage(context, team);
      },
      child: SizedBox(
        height: matchCardHeight / 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: team.icon,
            ),
            const Padding(padding: EdgeInsets.only(top: 10)),
            Text(team.name,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                textAlign: TextAlign.center)
          ],
        ),
      ),
    );
  }

  Padding _getRichText(final String key, final String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, top: 3.0, bottom: 3.0),
      child: RichText(
        softWrap: true,
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
                text: key,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    overflow: TextOverflow.ellipsis)),
            TextSpan(
                text: value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  TabBar _getTabsWidget() {
    return TabBar(
        isScrollable: true,
        controller: _tabController,
        tabs: List.generate(tabNames.length, (index) {
          return Tab(
              child: Text(tabNames[index],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)));
        }));
  }

  bool Function() _getTabRefreshCondition(final int index)
  {
    return () => _tabController.index == index;
  }

  Widget _getTabsBody() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(tabNames.length, (index) {
        switch (index) {
          case 0: //Formations
            return FormationsPage(0, resultsMatchPage: widget, matchListener: this, refreshCondition: _getTabRefreshCondition(0));
          case 1: //Scorers
            return EventsGoalsPage(1, resultsMatchPage: widget, matchListener: this, refreshCondition: _getTabRefreshCondition(1));
          case 2: //Report
            return ReportPage(2, resultsMatchPage: widget, matchListener: this, refreshCondition: _getTabRefreshCondition(2));
          case 3: //Classification
            return ScoreboardPage(selectedGroup: widget.selectedGroup, selectedGroupID: widget.selectedGroupID,
                selectedChampionship: widget.selectedChampionship, selectedChampionshipID: widget.selectedChampionshipID, selectedSeason: widget.selectedSeason,
                refreshCondition: _getTabRefreshCondition(3), standalone: false);
          case 4: //Comments
            return const Center(
              child: AutoSizeText("I commenti saranno presto disponibili.", maxLines: 1, minFontSize: 15, maxFontSize: 25),
            );
          default:
            debugPrint("Error: missing tab for index $index");
            return const Placeholder();
        }
      }));
  }

  Widget _getMatchCard(final Team team1, final Team team2) {
    return this.wrapIntoRefreshIndicator(() => Card(
      child: ClipRect(
        child: Container(
          height: matchCardHeight,
          padding: const EdgeInsets.all(10),
          width: MediaQuery.of(context).size.width,
          child: ListView(
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: MediaQuery.of(context).size.width * .3,
                      child: _getTeamWidget(team1)),
                  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.width * .08),
                    child: Builder(builder: (BuildContext context) {
                      final String scoreText = match.getScoreText();
                      if (match.isLive())
                        return LiveScoreText(score: scoreText, size: 30);
                      //Score Text
                      return InkWell(
                        onLongPress: editScoreClicked,
                        child: Text(scoreText, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 30))
                      );
                    }),
                  ),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * .3,
                      child: _getTeamWidget(team2))
                ],
              ),
              const Padding(padding: EdgeInsets.only(top: 10.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _getRichText("Girone: ", widget.selectedGroup),
                  _getRichText("Giornata: ", "${widget.matchDayString}   "),
                ],
              ),
              Center(child: _getRichText("Campionato: ", widget.selectedChampionship)),
            ],
          )),
      ),
    ));
  }

  Widget getBody() {
    Team team1 = match.team1;
    Team team2 = match.team2;

    return Padding(
        padding: const EdgeInsets.only(top: 11.0, left: 3.0, right: 3.0),
        child: Column(
          children: [
            Text(match.date == null ? "Data da definirsi"
                : capitalizeFirstMonth(DateFormat("dd MMMM yyyy ore HH:mm","it").format(match.postponed == null ? match.date! : match.postponed!))),
            const Padding(padding: EdgeInsets.only(top: 4.0)),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverHeaderDelegate(
                        child: _getMatchCard(team1, team2),
                        expandedHeight: matchCardHeight,
                        minHeight: 0, // This will allow it to collapse fully.
                      ),
                    ),
                  ];
                },
                body: Card(
                  child: Column(
                    children: [
                      _getTabsWidget(),
                      Expanded(child: _getTabsBody()),
                    ],
                  ),
                ),
              )
    )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
          appBar: MyAppBar(
            title: const Text("Dettagli partita"),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_a_photo),
                onPressed: addDistintaClicked
              )],
            ),
          body: getEntireRefreshablePage()),
    );
  }

  void addDistintaClicked() async
  {
    final NavigatorState navigator = Navigator.of(context);
    final bool authOk = await DjangoAuth.instance.ensureDjangoAuthentication(context);
    if (!authOk) return;
    if (DjangoAuth.instance.userIsAdmin || DjangoAuth.instance.champsCanEdit.contains(widget.selectedChampionshipID))
      navigator.push(MaterialPageRoute(builder: (context) => AddMatchPhotoPage(match)));
    else
    {
      if (!mounted)
        return;
      showErrorDialog("Non hai i permessi per aggiungere distinte a questo campionato.");
    }
  }

  void showErrorDialog(final String reason) //Shown if you want to edit score or add distinta and do not have permissions
  {
    showDialog(context: context, builder: (context) =>
        AlertDialog(
            backgroundColor: Theme.of(context).canvasColor,
            title: const Text("Errore", textAlign: TextAlign.center),
            content: Text(
                reason,
                style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
            actions: [
              TextButton(
                  child: const Text(
                      "Annulla", style: TextStyle(fontSize: 16)),
                  onPressed: () => Navigator.of(context).pop()
              )
            ]
        )
    );
  }

  EditableScore? _editableScore; //For edit score dialog
  final GlobalKey<_EditableScoreState> _editableScoreState = GlobalKey<_EditableScoreState>();

  void editScoreClicked() async
  {
    final bool authOk = await DjangoAuth.instance.ensureDjangoAuthentication(context);
    _editableScore = EditableScore(key: _editableScoreState, initialScore1: match.score1, initialScore2: match.score2, matchID: match.id);
    if (!authOk || !mounted) return;
    if (DjangoAuth.instance.userIsAdmin || DjangoAuth.instance.champsCanEdit.contains(widget.selectedChampionshipID)) {
      //Permissions OK: Open edit dialog
      showDialog(context: context, builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).canvasColor,
        title: const Text("Modifica risultato"),
        content: _editableScore,
        actions: [
          TextButton(
            child: const Text(
              "Annulla", style: TextStyle(fontSize: 18)),
            onPressed: () => Navigator.of(context).pop()
          ),
          ElevatedButton(
            onPressed: () async {
              NavigatorState navigator = Navigator.of(context);
              showDialog(barrierDismissible: false, context: context, builder: (BuildContext context) => const Center(child: CircularProgressIndicator()));
              final bool ok = await _editableScoreState.currentState!.performRequest();
              if (!mounted)
                return;
              navigator.pop(); //Remove circularProgressIndicator
              navigator.pop(); //Close dialog
              if (ok)
              {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Risultato modificato con successo.")));
                super.refresh();
              }
              else
                showErrorDialog("Non hai i permessi per modificare questo risultato.");

            },
            child: const Text("Modifica", style: TextStyle(fontSize: 18)),
          ),
        ],
      ));
    }
    else
    {
      showErrorDialog("Non hai i permessi per modificare le partite di questo campionato.");
    }
  }

  @override
  Widget downloadOK() {
    return getBody();
  }

  @override
  //String get downloadUrl => "$defaultEndpointURL/getMatch.php?id=${widget.beginMatch.id}";
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/matches/${widget.beginMatch.id}/"
                                         : "$defaultEndpointURL/getMatch.php?id=${widget.beginMatch.id}";

  @override
  Future<bool> parseDownloadedData(String body) async {

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
      match = Match.fromJson(json)!;
    }
    catch (e, f)
    {
      debugPrint("Error decoding json: $e, $f");
      return false;
    }

    return true;
  }

  @override
  Future<void> refresh() async
  {
    super.refresh();

    //Refresh the current tab
    final int currentTab = _tabController.index;
    debugPrint("CurrentTab: ${currentTab}");

    //Main page has been refreshed, refresh the current tab
    if (!tabRefreshMixins.containsKey(currentTab))
      return;
    tabRefreshMixins[currentTab]!.refresh();
    tabsToRefresh[currentTab] = false;
    for (int tab in tabsToRefresh.keys)
      tabsToRefresh[tab] = true;
  }

  final Map<int, PageDownloaderMixin> tabRefreshMixins = {}; //Callbacks used to refresh the pages
  final Map<int, bool> tabsToRefresh = {};

  void addTabRefreshCallback(final PageDownloaderMixin mixin, final int tab)
  {
    debugPrint("Added callback of tab $tab");
    tabRefreshMixins[tab] = mixin;
    tabsToRefresh[tab] = true;
  }

  void _onTabChanged()
  {
    final int newTab = _tabController.index;
    if (!tabsToRefresh.containsKey(newTab))
      return;

    if (tabsToRefresh[newTab]!)
      tabRefreshMixins[newTab]!.refresh();
    tabsToRefresh[newTab] = false;
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double expandedHeight;
  final double minHeight;

  _SliverHeaderDelegate({
    required this.child,
    required this.expandedHeight,
    required this.minHeight,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class EditableScore extends StatefulWidget { //Used in edit score dialog

  const EditableScore({super.key, required this.initialScore1, required this.initialScore2, required this.matchID});

  final String initialScore1;
  final String initialScore2;
  final int matchID;

  @override
  State<EditableScore> createState() => _EditableScoreState();
}

class _EditableScoreState extends State<EditableScore> {

  static const List<String> possibleScores = ["0","1","2","3","4","5","6","7","8","9"];

  late String _score1;
  late String _score2;

  String getScore1() => _score1;
  String getScore2() => _score2;

  @override
  void initState()
  {
    super.initState();
    _score1 = widget.initialScore1;
    _score2 = widget.initialScore2;
  }

  DropdownButton<String> _buildScoreDropdown(final String value, void Function(String) setValueFn)
  {
    return DropdownButton<String>(
      value: value,
      style: style,
      icon: const Icon(Icons.edit),
      items: possibleScores.map((x) => DropdownMenuItem<String>(
          value: x,
          child: Text(x))).toList(),
      onChanged: (String? value) {
        setState(() {
          setValueFn(value!);
        });
      },
    );
  }

  static const TextStyle style = TextStyle(fontSize: 30, color: Colors.black);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildScoreDropdown(_score1, (value) {_score1 = value;}),
        const Text(":", style: style),
        _buildScoreDropdown(_score2, (value) {_score2 = value;})
      ],
    );
  }

  Future<bool> performRequest() async
  {
    final String url = "https://calcioevai.it/api/v1/matches/${widget.matchID}/result/";

    String? response = await DjangoAuth.instance.performRequest(HTTPRequestMethod.patch, url, {"score_1" : _score1, "score_2" : _score2});

    debugPrint(response);
    try {
      Map<String, dynamic> json = jsonDecode(response!);
      bool ret = json["success"] == true;
      return ret;
    }
    catch (e,f)
    {
      debugPrint("Error: $e, $f");
      return false;
    }
  }
}
