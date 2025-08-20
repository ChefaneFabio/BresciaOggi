import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/player.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/formations_page.dart';
import 'package:imcalcio/player_page.dart';
import 'package:imcalcio/team_roster_page.dart';

class TeamScorersPage extends StatefulWidget {
  const TeamScorersPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamScorersPage> createState() => _TeamScorersPageState();
}

class _TeamScorersPageState extends State<TeamScorersPage> with AutomaticKeepAliveClientMixin, PageDownloaderMixin {

  late List<Scorer> scorers;

  static Image roleImage = Image.asset("images/match/assist.png");

  @override
  void initState()
  {
    super.initState();
    pageDownloaderInit();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return getEntireRefreshablePage();
  }

  @override
  String get downloadUrl => useRemoteAPI ?"$remoteAPIURL/teams/scores/?season=${widget.team.season}&group_id=${widget.team.groupID}"
      "&team_id=${widget.team.id}&campionato_id=${widget.team.championshipID}"
      : "$defaultEndpointURL/getTeamScorers.php?season=${widget.team.season}&group=${widget.team.group}"
      "&teamID=${widget.team.id}&champID=${widget.team.championshipID}";

  @override
  Future<bool> parseDownloadedData(String body) async {
    Map<String,dynamic> json;
    try {
      json = jsonDecode(body);
      scorers = Scorer.listFromJson(json);
    }
    on Exception catch (e) {
      debugPrint("Team scorers json error: $e");
      return false;
    }

    return true;
  }

  Widget _buildPaddedText(final String string, final TextStyle style, final TextAlign align, {final double maxWidth = -1})
  {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth > 0 ? maxWidth : double.infinity),
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
        child: AutoSizeText(string, style: style, textAlign: align, maxLines: 2, minFontSize: 6),
      ),
    );
  }

  Widget _getScorersWidget()
  {
    TableRow header = TableRow(
        children: [
          _buildPaddedText("#", TeamRosterPageState.headerStyle, TextAlign.center),
          _buildPaddedText("Nome", TeamRosterPageState.headerStyle, TextAlign.center),
          Align(alignment: Alignment.bottomCenter, child: SizedBox(width: 24, height: 20,
              child: Transform.scale(scale: 1.2, child: FormationsPageState.getGoalsWidget(1)))),
          Align(alignment: Alignment.bottomCenter, child: SizedBox(width: 24, height: 20,
              child: Transform.scale(scale: 1.2, child: FormationsPageState.getGoalsWidget(1, rightText: "A")))),
          Align(alignment: Alignment.bottomCenter, child: SizedBox(width: 24, height: 20,
              child: Transform.scale(scale: 1.2, child: FormationsPageState.getGoalsWidget(1, rightText: "R")))),
          Align(alignment: Alignment.topCenter, child: SizedBox(width: 24, height: 24, child: roleImage)),
        ]
    );

    List<TableRow> scorersPlayers = scorers.asMap().map((i, p) =>
        MapEntry(i, TableRow(
            decoration: BoxDecoration(
                color: (i % 2 == 1) ? Colors.white : const Color.fromARGB(255, 230, 230, 230)
            ),
            children: [
              _buildPaddedText("${p.shirtNumber ?? "#"}", TeamRosterPageState.shirtNumberStyle, TextAlign.center),
              GestureDetector(
                onTap: () {
                  final SearchPlayer sp = SearchPlayer(p.id, p.firstName, p.lastName, teamID: widget.team.id,
                      teamName: widget.team.name, champID: widget.team.championshipID!, champName: widget.team.championship!);
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlayerPage(searchPlayer: sp, season: widget.team.season!)));
                },
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    _buildPaddedText("${p.firstName} ${p.lastName}", TeamRosterPageState.playerStyle, TextAlign.left,
                        maxWidth: MediaQuery.of(context).size.width * .45),
                  ],
                ),
              ),
              _buildPaddedText("${p.goals}", TeamRosterPageState.numberStyle, TextAlign.center),
              _buildPaddedText("${p.autoGoals}", TeamRosterPageState.numberStyle, TextAlign.center),
              _buildPaddedText("${p.penalties}", TeamRosterPageState.numberStyle, TextAlign.center),
              _buildPaddedText("${p.assists ?? "-"}", TeamRosterPageState.numberStyle, TextAlign.center),
            ]
        ))
    ).values.toList();

    return Card(
      elevation: 5.0,
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.only(top: 6.0)),
          const Align(alignment: Alignment.topCenter,
              child: Text("Marcatori", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
          const Padding(padding: EdgeInsets.only(top: 6.0)),
          if (scorersPlayers.isNotEmpty) Table(
            columnWidths: const {0: FlexColumnWidth(0.5), 1: FlexColumnWidth(6)},
            children: [header,
              ...scorersPlayers],
          )
          else ... const[
            Padding(padding: EdgeInsets.only(top: 20)),
            Text("Non sono presenti dati per questa squadra.\n", textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.red))
          ]
        ],
      ),
    );
  }

  @override
  Widget downloadOK() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _getScorersWidget(),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
