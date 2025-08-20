// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/Material.dart';
import 'package:flutter/gestures.dart';
import 'package:imcalcio/classes/coach.dart';
import 'package:imcalcio/classes/formation.dart';
import 'package:imcalcio/classes/player.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/formations_info_page.dart';
import 'package:imcalcio/player_page.dart';
import 'package:imcalcio/results_match_page.dart';
import 'package:imcalcio/classes/match.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/pair.dart';
import 'package:imcalcio/staffer_page.dart';

String formatName(final String surname, final String name) {
  final String fullName = "$surname $name";
  List<String> parts = fullName.trim().split(" ");

  if (parts.length < 2) {
    // Return the original name if it doesn't fit the "Name Surname" format.
    return fullName;
  }

  List<String> surnameParts = surname.trim().split(" ");
  if (surnameParts.length == 1 || surnameParts.length == 2 && surnameParts[0].length <= 2) //For surnames like Di Lorenzo
    return "$surname ${parts[1][0]}.";
  else if (parts.length >= 3)
    return "${parts[0]} ${parts[1][0]}. ${parts[2][0]}.";

  return "${parts[0]} ${parts[1][0]}.";
}

String getSetString(final int setNo) {
  //debugPrint("SET: $setNo");
  final List<String> sets = ["PT", "ST", "PS", "SS"];
  final String set = setNo >= 1 && sets.length > setNo-1 ? sets[setNo-1] : "PT";
  return set;
}

class FormationsPage extends StatefulWidget {
  const FormationsPage(this.tabIndex, {super.key, required Widget resultsMatchPage, required State matchListener, required this.refreshCondition})
      : resultsMatchPage = resultsMatchPage as ResultsMatchPage
      , matchListener = matchListener as ResultsMatchPageState; //Widget in order to remove IDE error

  final ResultsMatchPage resultsMatchPage;
  final ResultsMatchPageState matchListener;
  final bool Function() refreshCondition;
  final int tabIndex;

  @override
  State<FormationsPage> createState() => FormationsPageState();

}

class FormationsPageState extends State<FormationsPage>
    with AutomaticKeepAliveClientMixin, PageDownloaderMixin {
  static Image? footballImage;
  static Image personImage = Image.asset("images/match/person_icon.png");
  static Image redFlagImage = Image.asset("images/match/red_flag_m.png");
  static Image yellowFlagImage = Image.asset("images/match/yellow_flag_m.png");
  static Image ballImage = Image.asset("images/match/ball.png");
  static Image substitutionEnterImage = Image.asset("images/match/substitution_enter.png");
  static Image substitutionExitImage = Image.asset("images/match/substitution_exit.png");
  static Image substitutionImage = Image.asset("images/match/substitution2.png");

  late final Match match; //widget match

  String nameCoach1 = "Allenatore sconosciuto";
  int? coach1;
  String nameCoach2 = "Allenatore sconosciuto";
  int? coach2;
  Formation? formation;

  @override
  void initState() {
    super.initState();
    match = widget.resultsMatchPage.beginMatch;
    pageDownloaderInit();
    widget.matchListener.addTabRefreshCallback(this, widget.tabIndex);
  }

  @override
  bool refreshCondition()
  {
    return widget.refreshCondition();
  }

  @override
  /*String get downloadUrl => "$defaultEndpointURL/getFormation.php"
      "?matchID=${widget.resultsMatchPage.beginMatch.id}";*/
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/matches/${widget.resultsMatchPage.beginMatch.id}/formation/"
                                         : "$defaultEndpointURL/getFormation.php?matchID=${widget.resultsMatchPage.beginMatch.id}";

  @override
  int get downloadTries => 3;

  @override
  Future<bool> parseDownloadedData(final String body) async {
    debugPrint(
        "Downloading formation of match ${widget.resultsMatchPage.beginMatch.id}");

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
      if (!json.containsKey("formations")) {
        throw Exception("Key formations does not exist.");
      }
    } on Exception catch (_, e) {
      debugPrint("Json error: $e");
      return false;
    }

    try {
      if (json.containsKey("LastName1")) nameCoach1 = json["LastName1"] ?? "";
      if (json.containsKey("FirstName1") && json["FirstName1"] != null) nameCoach1 += " ${json["FirstName1"]}";
      if (json.containsKey("LastName2")) nameCoach2 = json["LastName2"] ?? "";
      if (json.containsKey("FirstName2") && json["FirstName2"] != null) nameCoach2 += " ${json["FirstName2"]}";

      if (json.containsKey("Coach1")) coach1 = int.tryParse(json["Coach1"].toString());
      if (json.containsKey("Coach2")) coach2 = int.tryParse(json["Coach2"].toString());

      if (json.containsKey("coach_1")) coach1 = int.tryParse(json["coach_1"].toString());
      if (json.containsKey("coach_2")) coach2 = int.tryParse(json["coach_2"].toString());

      if (!json.containsKey("formations")) {
        debugPrint("Error: response does not contain formations key.");
        return false;
      }
      if (!json.containsKey("goals")) {
        debugPrint("Error: response does not contain goals key.");
        return false;
      }
      if (!json.containsKey("referees")) {
        debugPrint("Error: response does not contain referees key.");
        return false;
      }
      formation = Formation.fromJson(match, json);
    } on Exception catch (d, e) {
      debugPrint("Decode error: $d\n$e");
      return false;
    }
    return true;
  }

//#region Football Pitch
  static Widget buildPlayerFlag(final FormationPlayer player, final Color color,
      final String text) //For avatar in footballPitch
  {
    return Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(width: 0.5)),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 8.5)));
  }

  //Goals and exits
  static Widget getGoalsWidget(final int goals, {String rightText = ""}) //Goals or Exit
  {
    const double fontSize = 11.0;
    return IntrinsicWidth(
      child: Stack(
          //mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: fontSize+8,
              height: fontSize+6,
              child: ballImage,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.all(0.5),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: goals > 1 ? Text("$goals", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: fontSize-2, color: Colors.white)) : const SizedBox()
              ),
            ),
            if (rightText.isNotEmpty) Align(
              alignment: Alignment.topRight,
              child: Container(
                  padding: const EdgeInsets.all(0.5),
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child:
                  Text(rightText, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize-2, color: Colors.white))
              ),
            ),
          ],
        ),
    );
  }

  static Widget getExitWidget(String leftText) //Goals or Exit
  {
    const double fontSize = 10;
    return IntrinsicWidth(
      child: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            width: fontSize+10,
            child: SizedBox(
              width: fontSize+10,
              height: fontSize+18,
              child: substitutionExitImage,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8)
                ),
                child: Text(leftText, textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize-2, color: Colors.white))

            ),
          ),
        ],
      ),
    );
  }

  static Widget getMonitionFlag() //Monition flag, only for football pitch when there is no minute / set
  {
    const double size = 16.0;
    return IntrinsicWidth(
      child: SizedBox(
        width: size+2,
        height: size,
        child: yellowFlagImage,
      ),
    );
  }

  static Widget buildPlayerMarker(final BuildContext context, final FormationPlayer player, final Team team, {FormationsPage? widget}) //For football pitch
  {
    List<Widget> flags = [];
    if (player.monitionMinute > 0) {
      flags.add(buildPlayerFlag(player, const Color.fromARGB(255, 255, 255, 90),
          "${player.monitionMinute} ${getSetString(player.monitionSet)}"));
    }
    else if (player.monitionX){
      flags.add(getMonitionFlag());
    }
    if (player.evictionMinute > 0) {
      flags.add(buildPlayerFlag(player, const Color.fromARGB(255, 255, 90, 90),
          "${player.evictionMinute} ${getSetString(player.evictionSet)}"));
    }
    if (player.exitMinute > 0)
        flags.add(getExitWidget("${player.exitMinute}${getSetString(player.exitSet)}"));

    final int normalGoals = FormationGoal.countNormalGoals(player.goals, team.id);
    final int autoGoals = FormationGoal.countAutoGoals(player.goals, team.id);
    final int penalties = FormationGoal.countPenalties(player.goals);
    String formattedName = formatName(player.lastName, player.firstName);

    return GestureDetector(
      onTap: () {
        if (widget == null) return;
        final SearchPlayer sp = SearchPlayer(player.id, player.firstName, player.lastName, teamID: team.id,
            teamName: team.name, champID: widget.resultsMatchPage.selectedChampionshipID, champName: widget.resultsMatchPage.selectedChampionship);
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlayerPage(searchPlayer: sp, season: widget.resultsMatchPage.selectedSeason)));
      },
      child: Container(
          //color: Colors.red,
          alignment: Alignment.bottomCenter,
          height: 60,
          width: 65,
          child: Stack(children: [
            //Center the avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: SizedBox(width: 36, height: 36, child: PlayerInfo.getPlayerIcon(player.id)),
                  ),
                ),
              ],
            ),
            //Flags
            Align(
                alignment: Alignment.topRight,
                child: Container(
                    padding: const EdgeInsets.only(right: 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: flags,
                    ))),
            //Goals + substitution
            Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      normalGoals <= 0 ? const Row() : getGoalsWidget(normalGoals),
                      penalties <= 0 ? const Row() : getGoalsWidget(penalties, rightText: "R"),
                      autoGoals <= 0 ? const Row() : getGoalsWidget(autoGoals, rightText: "A"),
                    ],
                  ),
                )),
            //Name
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(1.0),
                decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(7))),
                child: AutoSizeText(
                  formattedName,
                  minFontSize: 9.0,
                  maxFontSize: 11.0,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
              ),
            ),
          ]),
      ),
    );
  }

  Widget _buildPlayerRows(final List<FormationPlayer> players,
      final FormationType type, final double fieldHeight, final Team team,
      {final bool reverse = false}) {
    List<Widget> rows = [];

    rows.add(Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildPlayerMarker(context, players.first, team, widget: widget),
      ],
    )); //Portiere

    int nextPlayerI = 1;

    final int rowsNo = type.getRows();

    for (int i = 0; i < rowsNo; i++) {
      final int rowLength = type.getRowLength(i);
      //debugPrint("ROWLENGTH: $rowLength");
      List<FormationPlayer> row = [];
      for (int j = 0; j < rowLength; j++) {
        if (reverse)
          row.insert(0, players[nextPlayerI]);
        else
          row.add(players[nextPlayerI]);

        nextPlayerI++;
      }

      Row rowWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: row.map((player) => buildPlayerMarker(context, player, team, widget: widget)).toList(),
      );

      if (reverse)
        rows.insert(0, rowWidget);
      else
        rows.add(rowWidget);
    }

    return SizedBox(
      height: fieldHeight / 2.2, //Lascia un po' di margine in centro
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: rows,
      ),
    );
  }

  Widget _getFootballField() {
    final double imageWidth = MediaQuery.of(context).size.width;
    final double imageHeight = imageWidth / 775 * 1615;//1415;//1075;

    footballImage ??= Image.asset("images/match/football_field_noborder_thinlines_long_long.png",
          fit: BoxFit.cover);

    Widget fieldContainer = IntrinsicHeight(
      child: Container(
        //color: Colors.red,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 2, bottom: 2, right: 10, left: 10),
        child: Stack(
          children: [
            Container(width: imageWidth, height: imageHeight - 4, child: footballImage!),
            if (formation!.playersTeam1.isNotEmpty) Align( //Modulo, display it only if the formation exists
              alignment: Alignment.topLeft,
              child: Text("Modulo: ${formation!.typeTeam1.name}",
                  style: const TextStyle(fontWeight: FontWeight.w500, backgroundColor: Colors.white)),
            ),
            if (formation!.playersTeam1.isNotEmpty) Align(
              alignment: Alignment.bottomRight,
              child: Container(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text("Modulo: ${formation!.typeTeam2.name}",
                      style: const TextStyle(fontWeight: FontWeight.w500, backgroundColor: Colors.white))
              )
            ),
          ],
        ),
      ),
    );

    Widget ret;
    if (formation!.playersTeam1.isNotEmpty &&
        formation!.playersTeam2.isNotEmpty) {
      ret = Stack(
        children: [
          fieldContainer,
          _buildPlayerRows(
            formation!.playersTeam1, formation!.typeTeam1, imageHeight, match.team1),
          Positioned.fill(
            top: imageHeight - imageHeight / 2.1,
            child: _buildPlayerRows(
              formation!.playersTeam2, formation!.typeTeam2, imageHeight, match.team2,
              reverse: true))
        ],
      );
    } else
    {
      ret = Stack(
        children: [
          fieldContainer,
          const Center(
            child: Text("Formazione non registrata.",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: Colors.red,
                backgroundColor: Colors.white)))
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.transparent),
            Expanded(
              child: Center(
                child: _getTeamSnippet(match.team1, nameCoach1, coach1),
              )
            ),
            IconButton(onPressed: () {
              showDialog(context: context, builder: (context) => const FormationsInfoPage());
            }, icon: const Icon(Icons.info_outline))
          ],
        ),
        ret,
        _getTeamSnippet(match.team2, nameCoach2, coach2),
      ],
    );
  }

  Widget _getTeamSnippet(final Team team, final String coachName, final int? coachID) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector( //Team logo -> Team page
          onTap: () => widget.resultsMatchPage.goToTeamPage(context, team),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * .11,
            height: MediaQuery.of(context).size.width * .11,
            child: team.icon),
        ),
        const Padding(padding: EdgeInsets.only(left: 8)),
        Column(children: [
          GestureDetector( //Team text -> Team page
            onTap: () => widget.resultsMatchPage.goToTeamPage(context, team),
            child: Text(team.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
          const Padding(padding: EdgeInsets.only(top: 3)),
          GestureDetector(
            onTap: () {
              if (coachID == null) return;
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) =>
                      StafferPage(StafferType.coach, stafferID: coachID, stafferFullName: coachName)));
            },
            child: Text(coachName,
                style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16)),
          )
        ])
      ]),
    );
  }

//#endregion

//#region Reserves
static Widget getGoalReserveCellIcon(final int minute, final int setNo, final String specialGoalType)
  {
    return Stack(
      children: [
        getReserveCellIcon(ballImage, minute: minute, setNo: setNo),
        Align(
          alignment: Alignment.topLeft,
          child: Container(
              padding: const EdgeInsets.all(0.5),
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8)
              ),
              child:
              Text(specialGoalType, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 9, color: Colors.white))
          ),
        ),
      ],
    );
  }

static Widget getReserveCellIcon(final Image image, {final int? minute, final int? setNo}) {
    final String set = setNo != null ? getSetString(setNo) : "";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 20, height: 16, child: image),
        if (setNo != null) const Padding(padding: EdgeInsets.only(top: 3)),
        if (setNo != null) Text("$minute $set",
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))
      ],
    );
  }

  static Widget getReserveCell(final BuildContext context, final FormationPlayer player, final Team team, {FormationsPage? widget}) {
    List<Pair<int,Widget>> pairs = []; //To sort icons based on set + minute
    if (player.monitionMinute >= 0)
      pairs.add(Pair(player.monitionSet * 1000 + player.monitionMinute ,getReserveCellIcon(
          yellowFlagImage, minute: player.monitionMinute, setNo: player.monitionSet)));
    else if (player.monitionX)
      pairs.add(Pair(-1 ,getReserveCellIcon(yellowFlagImage)));
    if (player.evictionMinute >= 0)
      pairs.add(Pair(player.evictionSet * 1000 + player.evictionMinute, getReserveCellIcon(
          redFlagImage, minute: player.evictionMinute, setNo: player.evictionSet)));
    if (player.entranceMinute >= 0)
      pairs.add(Pair(player.entranceSet * 1000 + player.entranceMinute, getReserveCellIcon(
          substitutionEnterImage, minute: player.entranceMinute, setNo: player.entranceSet)));
    if (player.exitMinute >= 0)
      pairs.add(Pair(player.exitSet * 1000 + player.exitMinute, getReserveCellIcon(
          substitutionExitImage, minute: player.exitMinute, setNo: player.exitSet)));

    for (FormationGoal goal in player.goals) {
      if (goal.penalty)
        pairs.add(Pair(goal.set * 1000 + goal.minute, getGoalReserveCellIcon(goal.minute, goal.set, "R")));
      else if (goal.advantagedTeamID != player.teamID)
        pairs.add(Pair(goal.set * 1000 + goal.minute, getGoalReserveCellIcon(goal.minute, goal.set, "A")));
      else
        pairs.add(Pair(goal.set * 1000 + goal.minute, getReserveCellIcon(ballImage, minute: goal.minute, setNo: goal.set)));
    }

    pairs.sort((a,b) => a.first.compareTo(b.first));

    final List<Widget> icons = pairs.map((e) => e.second).toList();

    if (pairs.isEmpty)
      icons.add(const SizedBox(height: 31));

    List<Row> rows = [];
    for (int i = 0; i < icons.length; i += 2)
      rows.add(Row(
       mainAxisSize: MainAxisSize.min, children: icons.sublist(i, (i + 2) <= icons.length ? i + 2 : i + 1),
      ));

    return GestureDetector(
      onTap: () {
        if (widget == null) return;
        SearchPlayer sp = SearchPlayer(player.id, player.firstName, player.lastName,
            teamID: team.id, teamName: team.name,
            champID: widget.resultsMatchPage.selectedChampionshipID, champName: widget.resultsMatchPage.selectedChampionship);
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlayerPage(searchPlayer: sp, season: widget.resultsMatchPage.selectedSeason)));
      },
      child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                  child: Text("${player.lastName} ${player.firstName}",
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.clip)),
              Column(children: rows)//Column of rows of icons + texts for goals and flags
            ],
          ),
        ),
    );
  }

  Widget _getReservesWidget() {
    if (formation!.playersTeam1.isEmpty || formation!.playersTeam2.isEmpty)
      return Container();

    final int rows = (max(formation!.playersTeam1.length, formation!.playersTeam2.length) - 11); //Solo per le riserve

    if (rows < 0) return const Center(child: Text("Non ci sono riserve."));

    List<FormationPlayer> reservesTeam1 = List.from(formation!.playersTeam1
        .getRange(11,
            formation!.playersTeam1.length));
    List<FormationPlayer> reservesTeam2 = List.from(formation!.playersTeam2
        .getRange(11,
            formation!.playersTeam2.length));

    List<Widget> cellsTeam1 = reservesTeam1.map((e) => getReserveCell(context, e, widget.resultsMatchPage.beginMatch.team1,
        widget: widget)).toList();
    List<Widget> cellsTeam2 = reservesTeam2.map((e) => getReserveCell(context, e, widget.resultsMatchPage.beginMatch.team2,
        widget: widget)).toList();

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(
            height: 3,
            thickness: 2,
          ),
          const Padding(padding: EdgeInsets.only(top: 8)),
          const Text(
            "Riserve",
            textAlign: TextAlign.start,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
          ),
          const Padding(padding: EdgeInsets.only(top: 8)),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  flex: 1,
                  child: Text(match.team1.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500))),
              Flexible(
                  flex: 1,
                  child: Text(match.team2.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)))
            ],
          ),
          const Padding(padding: EdgeInsets.only(top: 4)),
          Table(
            border: TableBorder.all(),
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FlexColumnWidth()
            },
            children: List.generate(rows, (rowIndex) {

              Widget c1 = cellsTeam1.length > rowIndex ? cellsTeam1[rowIndex] : Container();
              Widget c2 = cellsTeam2.length > rowIndex ? cellsTeam2[rowIndex] : Container();

              return TableRow(
                children: [c1, c2],
              );
            }),
          )
        ]
      ),
    );
  }
//#endregion

//#region Referees
  Widget _getRefereesWidget() {
    if (formation!.playersTeam1.isEmpty || formation!.playersTeam2.isEmpty)
      return Container();

    List<Widget> refereesWidget = [];

    for (int i = 1; i <= 5; i++)
    {
      String name = formation!.referees.containsKey(i) ? formation!.referees[i]!.name : "-";
      final String type = FormationReferee.types[i-1];

      Widget w = Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: RichText( //Row of "Tipo di arbitro => Arbitro"
          text: TextSpan(
            children: [
              TextSpan(text: "$type: ", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black)),
              TextSpan(text: name, style: const TextStyle(fontSize: 17, color: Colors.black),
                recognizer: TapGestureRecognizer()..onTap = () {
                 //TODO WHEN REFEREES WILL BE IMPLEMENTED OPEN PAGE
                }
              )
            ]
          )
        ),
      );

      refereesWidget.add(w);
    }

    return Container(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(
                height: 3,
                thickness: 2,
              ),
              const Padding(padding: EdgeInsets.only(top: 8)),
              const Text(
                "Arbitri",
                textAlign: TextAlign.start,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
              ),
              ...refereesWidget
            ]));
  }

  @override
  Widget downloadOK() {
    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _getFootballField(),
        _getReservesWidget(),
        _getRefereesWidget()
      ],
    ));
  }

//#endregion

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return getEntireRefreshablePage();
  }

  @override
  bool get wantKeepAlive => true;

}
