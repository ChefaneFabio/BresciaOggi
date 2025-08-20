// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:collection';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/player.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/formations_page.dart';
import 'package:imcalcio/player_page.dart';

class TeamRosterPage extends StatefulWidget {
  const TeamRosterPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamRosterPage> createState() => TeamRosterPageState();
}

class TeamRosterPageState extends State<TeamRosterPage> with AutomaticKeepAliveClientMixin, PageDownloaderMixin {

  static const TextStyle playerStyle = TextStyle(fontSize: 14.5);
  static const TextStyle numberStyle = TextStyle(fontSize: 14);
  static const TextStyle headerStyle = TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600);
  static const TextStyle shirtNumberStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: Colors.grey);

  late List<Player> players;
  late List<Staffer> managers;
  late List<Staffer> coaches;

  static Image roleImage = Image.asset("images/match/role2.png");

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

  Widget _buildPaddedText(final String string, final TextStyle style, final TextAlign align, {final double maxWidth = -1})
  {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth > 0 ? maxWidth : double.infinity),
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
        child: AutoSizeText(string, style: style, textAlign: align,
          overflow: TextOverflow.ellipsis, maxLines: 2, minFontSize: 10),
      )
    );
  }

  Widget _getRosterWidget()
  {
    TableRow header = TableRow(
      children: [
        _buildPaddedText("#", headerStyle, TextAlign.center),
        _buildPaddedText("Nome", headerStyle, TextAlign.center),
        _buildPaddedText("Età", headerStyle, TextAlign.center),
        _buildPaddedText("CM", headerStyle, TextAlign.center),
        Align(alignment: Alignment.bottomCenter, child: SizedBox(width: 24, height: 24, child: roleImage)),
        Align(alignment: Alignment.bottomCenter, child: SizedBox(width: 16, height: 24, child: FormationsPageState.yellowFlagImage)),
        Align(alignment: Alignment.bottomCenter, child: SizedBox(width: 16, height: 24, child: FormationsPageState.redFlagImage)),
      ]
    );

    List<TableRow> rosterPlayers = players.asMap().map((i, p) =>
      MapEntry(i, TableRow(
        decoration: BoxDecoration(
          color: (i % 2 == 1) ? Colors.white : const Color.fromARGB(255, 230, 230, 230)
        ),
        children: [
          _buildPaddedText("${p.shirtNumber ?? "#"}", shirtNumberStyle, TextAlign.center),
          GestureDetector(
            onTap: () {
              final SearchPlayer sp = SearchPlayer(p.id, p.firstName, p.lastName, teamID: widget.team.id,
                  teamName: widget.team.name, champID: widget.team.championshipID!, champName: widget.team.championship!);
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlayerPage(searchPlayer: sp, season: widget.team.season!)));
            },
            child: Row(
              children: [
                const Icon(Icons.person),
                _buildPaddedText("${p.firstName} ${p.lastName}", playerStyle, TextAlign.left,
                    maxWidth: MediaQuery.of(context).size.width * .42), //Empirical max width
              ],
            ),
          ),
          _buildPaddedText("${p.age ?? "-"}", numberStyle, TextAlign.center),
          _buildPaddedText("${p.height ?? "-"}", numberStyle, TextAlign.center),
          _buildPaddedText(p.role != null ? p.role!.toUpperCase() : "-", numberStyle, TextAlign.center),
          _buildPaddedText("${p.monitions ?? "-"}", numberStyle, TextAlign.center),
          _buildPaddedText("${p.evictions ?? "-"}", numberStyle, TextAlign.center),
        ]
      ))
    ).values.toList();

    return Card(
      elevation: 5.0,
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.only(top: 6.0)),
          const Align(alignment: Alignment.topCenter,
              child: Text("Rosa", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
          const Padding(padding: EdgeInsets.only(top: 6.0)),
          if (rosterPlayers.isNotEmpty) Table(
            columnWidths: const {0: FlexColumnWidth(0.5), 1: FlexColumnWidth(6)},
            children: [header,
            ...rosterPlayers],
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

  Widget _getRoleLegend()
  {
    const TextStyle style = TextStyle(fontSize: 15, fontWeight: FontWeight.w400);
    return const Align(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Legenda ruoli:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            Text("A: Attaccante", style: style),
            Text("C: Centrocampista", style: style),
            Text("D: Difensore", style: style),
            Text("P: Portiere", style: style),
          ],
        ),
      ),
    );
  }

  Widget _getStaffWidget()
  {
    return Card(
      elevation: 5.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.only(top: 4.0)),
            const Align(alignment: Alignment.topCenter,
                child: Text("Staff", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
            const Padding(padding: EdgeInsets.only(top: 6.0)),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Allenatori:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.left),
                  const Padding(padding: EdgeInsets.only(left: 5.0)),
                  Flexible(
                    child: Text((coaches.isEmpty) ? "-" : coaches.map((e) => "${e.firstName} ${e.lastName}").last, //toSet().join(", "), //Before was the list of coaches, now only the last one
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Dirigenti:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.left),
                  const Padding(padding: EdgeInsets.only(left: 5.0)),
                  Flexible(
                    child: Text((managers.isEmpty) ? "-" : managers.map((e) => "${e.firstName} ${e.lastName}").join(", "),
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                  )
                ],
              ),
            ),
          ],
        ),
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
          _getRosterWidget(),
          const Padding(padding: EdgeInsets.only(top: 8.0)),
          _getStaffWidget(),
          _getRoleLegend()
        ],
      ),
    );
  }

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/teams/${widget.team.id}/roster?season=${widget.team.season}&group_id=${widget.team.groupID}"
                            "&campionato_id=${widget.team.championshipID}"
                            : "$defaultEndpointURL/getTeamRoster.php?season=${widget.team.season}&group=${widget.team.group}"
                            "&teamID=${widget.team.id}&champID=${widget.team.championshipID}";

  @override
  Future<bool> parseDownloadedData(String body) async {
    Map<String,dynamic> json;
    try {
      json = jsonDecode(body);
      players = Player.listFromJson(json);
      managers = Staffer.listFromJson(json, "managers");
      coaches = Staffer.listFromJson(json, "coaches");
    }
    on Exception catch (e) {
      debugPrint("Team roster json error: $e");
      return false;
    }

    return true;
  }

  @override
  bool get wantKeepAlive => true;
}
