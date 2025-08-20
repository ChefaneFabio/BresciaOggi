// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/scoreboard.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/team_page.dart';

//Used both for scoreboard "standalone" and scoreboard in the tabs of match page
class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key, required this.selectedChampionship, required this.selectedChampionshipID,
    required this.selectedGroup, required this.selectedGroupID,
    required this.selectedSeason, this.refreshCondition = defaultRefreshCondition,
    this.standalone = false, this.standaloneTitle});

  final bool Function() refreshCondition;

  final String selectedChampionship;
  final int selectedChampionshipID;
  final String selectedSeason;

  final String selectedGroup;
  final int selectedGroupID;

  final bool standalone; //true if this widget is not opened as a tab in match page
  final Widget Function()? standaloneTitle;

  static bool defaultRefreshCondition() => false;

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> with AutomaticKeepAliveClientMixin, PageDownloaderMixin {

  final Map<ScoreboardType, Scoreboard> _scoreboards = {};

  ScoreboardType _selectedScoreboard = ScoreboardType.totale;
  bool _expandedScoreboard = true;

  List<ScoreboardCategory> _scoreboardCategories = [];

  int? lastGroupPhaseDay; //Last day of the 'Fase a gironi' of this championship, i.e. the last day counted in scoreboard. (Fase a eliminazione does not need scoreboard)
  //^^ If null: all 'Fase a gironi', if 0: all 'fase a eliminazione'
  int? maxDay;

  @override
/*  String get downloadUrl => "$defaultEndpointURL/getScoreboard.php"
      "?championshipID=${widget.selectedChampionshipID}"
      "&season=${widget.selectedSeason}"
      "&groupID=${widget.selectedGroupID}";*/
 String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/champs/scoreboard/"
                                          "?campionato_id=${widget.selectedChampionshipID}"
                                          "&season=${widget.selectedSeason}"
                                          "&group_id=${widget.selectedGroupID}"
                                        : "$defaultEndpointURL/getScoreboard.php"
                                          "?championshipID=${widget.selectedChampionshipID}"
                                          "&season=${widget.selectedSeason}"
                                          "&groupID=${widget.selectedGroupID}";

  @override
  int get downloadTries => 3;

  @override
  bool refreshCondition()
  {
    return widget.refreshCondition();
  }

  @override
  void initState()
  {
    super.initState();
    pageDownloaderInit();

    _scoreboardCategories = ScoreboardCategory.getCategoryListForChampionship(widget.selectedChampionship);

  }

  @override
  Future<bool> parseDownloadedData(String body) async {
    debugPrint("Downloading scoreboard of ${widget.selectedChampionship}");
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
      if (!json.containsKey("house")) 
        throw Exception("Key house does not exist.");
      else if (!json.containsKey("transfer"))
        throw Exception("Key transfer does not exist.");
      else if (!json.containsKey("shapes"))
        throw Exception("Key shapes does not exist.");
    } on Exception catch (_, e) {
      debugPrint("Json error: $e");
      return false;
    }

    List<ScoreboardEntry> emptyScoreboardEntries = []; //Create an empty scoreboard from the list of all teams
    try {
      if (json.containsKey("team_list")) {
        List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
            json["team_list"]);
        for (Map<String, dynamic> team in list) { //{"id":"3067","name":"Napoli"}
          emptyScoreboardEntries.add(ScoreboardEntry.empty(
              int.parse(team["id"].toString()), team["name"]));
        }
        debugPrint(list.toString());
      }
    } on Exception catch (e, f) {
      debugPrint("Error decoding scoreboard teamList: $e, $f");
    }

    try {
      if (json.containsKey("last_group_phase_day"))
        lastGroupPhaseDay = int.parse(json["last_group_phase_day"].toString());
    } on Exception catch (e, f) {
      debugPrint("Error on decoding scoreboard lastGroupPhaseDay: $e, $f");
    }

    try {
      if (json.containsKey("max_day"))
        maxDay = int.parse(json["max_day"].toString());
    } on Exception catch (e, f) {
      debugPrint("Error on decoding scoreboard maxDay: $e, $f");
    }

    Scoreboard emptyScoreboard = Scoreboard(emptyScoreboardEntries);

    try {

      Scoreboard houseScores = emptyScoreboard + Scoreboard.fromJson(List<Map<String,dynamic>>.from(json["house"]));
      Scoreboard transferScores = emptyScoreboard + Scoreboard.fromJson(List<Map<String,dynamic>>.from(json["transfer"]));
      Scoreboard total;
      if (json.containsKey("total"))
        total = emptyScoreboard + Scoreboard.fromJson(List<Map<String, dynamic>>.from(json["total"])); //Sum order is important for ties order. emptyScoreboard goes first.
      else
        total = houseScores + transferScores;
      Scoreboard.setScoreboardShapes(houseScores, transferScores, total, List<Map<String,dynamic>>.from(json["shapes"]));
      _scoreboards[ScoreboardType.totale] = total;
      _scoreboards[ScoreboardType.casa] = houseScores;
      _scoreboards[ScoreboardType.trasferta] = transferScores;
    } on Exception catch (d, e) {
      debugPrint("Decode error: $d\n$e");
      return false;
    }
    return true;
  }

  Scoreboard _getCurrentScoreboard()
  {
    return _scoreboards[_selectedScoreboard]!;
  }

  Widget _getScoreboardSelector()
  {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Center(
        child: SegmentedButton<ScoreboardType>(
            style: ButtonStyle(
                elevation: MaterialStateProperty.all(4),
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected))
                    return const Color.fromARGB(255, 200, 200, 200);
                  return const Color.fromARGB(255, 240, 240, 240);
                }),
                foregroundColor: MaterialStateProperty.all(Colors.black),
                visualDensity: VisualDensity.compact
            ),
            segments: const [
              ButtonSegment<ScoreboardType>(
                  value: ScoreboardType.totale,
                  label: FittedBox(fit: BoxFit.scaleDown, child: Text("Totale")),
                  icon: Icon(Icons.scoreboard)
              ),
              ButtonSegment<ScoreboardType>(
                  value: ScoreboardType.casa,
                  label: FittedBox(fit: BoxFit.scaleDown, child: Text("Casa")),
                  icon: Icon(Icons.house)
              ),
              ButtonSegment<ScoreboardType>(
                  value: ScoreboardType.trasferta,
                  label: FittedBox(fit: BoxFit.scaleDown, child: Text("Trasferta")),
                  icon: Icon(Icons.holiday_village)
              )
            ],
            selected: {_selectedScoreboard},
            onSelectionChanged: (Set<ScoreboardType> newValue) {
              setState(() {
                _selectedScoreboard = newValue.first;
              });
            }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!widget.standalone)
      return getEntireRefreshablePage();

    //Standalone
    return BackgroundContainer(
      child: Scaffold(
        appBar: MyAppBar(
          title: widget.standaloneTitle!(),
          centerTitle: true,
        ),
        body: getEntireRefreshablePage(),
      ),
    );
  }

  List<Widget> getWidgetsAfterSeason()
  {
    if (lastGroupPhaseDay == null || maxDay == null || lastGroupPhaseDay! >= maxDay!) //ALL Group phase day -> All days forms this scoreboard
    {
      return [_getScoreboardSelector(),
        const Padding(padding: EdgeInsets.only(top: 8)),
        _getScoreboardWidget(_getCurrentScoreboard()),
        const Padding(padding: EdgeInsets.only(top: 8)),
        _getCategoriesLegendWidget()];
    }

    if (lastGroupPhaseDay! < maxDay!) //Some Group phase days, some elimination phase
    {
      return [
        const Text("Classifica fase a gironi", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
        _getScoreboardSelector(),
        const Padding(padding: EdgeInsets.only(top: 8)),
        _getScoreboardWidget(_getCurrentScoreboard()),
        const Padding(padding: EdgeInsets.only(top: 8)),
        _getCategoriesLegendWidget()];
    }

    return [ //Only elimination phase
      const Padding(padding: EdgeInsets.only(top: 30.0)),
      const Center(
        child: AutoSizeText("La classifica non è disponibile per i campionati ad eliminazione diretta.", maxLines: 2,
            maxFontSize: 30, minFontSize: 10, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))
      )
    ];
  }

  @override
  Widget downloadOK() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("Stagione ${widget.selectedSeason}", style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            ),
            ...getWidgetsAfterSeason()
          ],
        ),
      ),
    );
  }

  Widget _getCategoriesLegendWidget()
  {
    if (_scoreboardCategories.isEmpty)
      return const SizedBox();

    return Column(
      children: _scoreboardCategories.expand((e) => [Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            color: e.color,
          ),
          const Padding(padding: EdgeInsets.only(left: 8.0)),
          Text(e.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16))
        ],
        ), const Padding(padding: EdgeInsets.only(top: 5.0),)]).toList()

    );
  }

  Widget _getScoreboardWidget(final Scoreboard scoreboard)
  {
    if (scoreboard.entries.isNotEmpty) {
      return Column(
        children: [
          Table( //Legenda
            children: [_getScoreboardLegend()],
            border: null,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(0.7 + 1.4 + 4.5),
            },
          ),
          Table( //Values
            children: scoreboard.entries.map((e) => _getScoreboardRow(e))
                .toList(),
            border: TableBorder.all(width: 0.5, color: Colors.grey),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(0.7),
              1: FlexColumnWidth(1.4),
              2: FlexColumnWidth(4.5)
            },
          ),
        ],
      );
    }
    
    return const Center(
      child: AutoSizeText("La classifica è in aggiornamento", minFontSize: 12, maxFontSize: 24, style: TextStyle(fontSize: 24), textAlign: TextAlign.center,)
    );
  }

  TableRow _getScoreboardLegend()
  {
    const TextStyle textStyle = TextStyle(fontWeight: FontWeight.w500, fontSize: 14);
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        TableCell(child: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _expandedScoreboard = !_expandedScoreboard;
              });
            },
            style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
                side: BorderSide(color: Theme.of(context).primaryColor))
              ),
              backgroundColor: MaterialStatePropertyAll(Theme.of(context).canvasColor)
            ),
            child: AutoSizeText(
              _expandedScoreboard ? "Vedi meno dati" : "Vedi più dati", textAlign: TextAlign.center, maxLines: 1,
            ),
          ),
        )),
        const Text("Pt", style: textStyle, textAlign: TextAlign.center),
        if (_expandedScoreboard) const Text("G", style: textStyle, textAlign: TextAlign.center),
        const Text("V", style: textStyle, textAlign: TextAlign.center),
        const Text("N", style: textStyle, textAlign: TextAlign.center),
        const Text("P", style: textStyle, textAlign: TextAlign.center),
        if (_expandedScoreboard) const Text("F", style: textStyle, textAlign: TextAlign.center),
        if (_expandedScoreboard) const Text("S", style: textStyle, textAlign: TextAlign.center),
        if (_expandedScoreboard) const Text("DR", style: textStyle, textAlign: TextAlign.center),
        const Text("PP", style: textStyle, textAlign: TextAlign.center),
      ]
    );
  }

  _getShapeRow(final List<String> shape) //Forma della squadra
  {
    const Map<String, Color> colors = {"P" : Colors.red, "N" : Colors.yellow, "V" : Colors.green};
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: shape.expand((e) => [
          Container(
            width: 13,
            height: 13,
            color: colors[e],
            child: Center(
              child: Text(e, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
            ),
          ),
          const Padding(padding: EdgeInsets.only(left: 2.0, right: 2.0))
        ]).toList(),
      ),
    );
  }

  bool isEven = true; //Static
  TableRow _getScoreboardRow(final ScoreboardEntry entry)
  {
    isEven = !isEven;
    final Team team = Team.getTeam(entry.teamName, id: entry.teamID, group: widget.selectedGroup, groupID: widget.selectedGroupID,
        championship: widget.selectedChampionship, championshipID: widget.selectedChampionshipID, season: widget.selectedSeason);
    const double textSize = 12;
    const double teamTextSize = textSize + 1;
    const TextStyle textStyle = TextStyle(fontSize: textSize);
    const TextStyle boldTextStyle = TextStyle(fontWeight: FontWeight.w500, fontSize: textSize);
    return TableRow(
      decoration: BoxDecoration(
        color: isEven ? const Color.fromARGB(255, 230, 230, 230) : Colors.white
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.fill,
          child: Container(
            color: ScoreboardCategory.getColorCategory(entry.position ?? -1, _scoreboardCategories),
            child: Container(
              color: const Color.fromARGB(30, 255, 255, 255),
              child: Center(child: Text(entry.position != null ? "${entry.position}" : "", textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: textSize, color: Colors.black))),
            )
          ),
        ),
        Padding(padding: const EdgeInsets.all(4.0),
            child: team.icon),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => TeamPage(team: team)));
          },
          child: Column(
            children: [
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Text(team.name, style: const TextStyle(fontSize: teamTextSize, fontWeight: FontWeight.w500)),
                )),
              if (entry.shape.isNotEmpty) _getShapeRow(entry.shape)
            ],
          ),
        ),
        Text("${entry.points}", textAlign: TextAlign.center, style: boldTextStyle),
        if (_expandedScoreboard) Text("${entry.gamesPlayed}", textAlign: TextAlign.center, style: textStyle),
        Text("${entry.victories}", textAlign: TextAlign.center, style: textStyle),
        Text("${entry.draws}", textAlign: TextAlign.center, style: textStyle),
        Text("${entry.losses}", textAlign: TextAlign.center, style: textStyle),
        if (_expandedScoreboard) Text("${entry.goalsFor}", textAlign: TextAlign.center, style: textStyle),
        if (_expandedScoreboard) Text("${entry.goalsAgainst}", textAlign: TextAlign.center, style: textStyle),
        if (_expandedScoreboard) Text(entry.getSignedDifference(), textAlign: TextAlign.center, style: textStyle),
        Text("${entry.penalty}", textAlign: TextAlign.center, style: boldTextStyle),
      ]
    );
  }

  @override
  bool get wantKeepAlive => true;
}
