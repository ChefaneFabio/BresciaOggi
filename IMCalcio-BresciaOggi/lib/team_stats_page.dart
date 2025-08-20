// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/pair.dart';
import 'package:imcalcio/classes/team.dart';

class TeamStatsPage extends StatefulWidget {
  const TeamStatsPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamStatsPage> createState() => _TeamStatsPageState();
}

class _TeamStatsPageState extends State<TeamStatsPage> with AutomaticKeepAliveClientMixin, PageDownloaderMixin {

  String? points;
  String? position;
  String? gamesPlayed;
  String? victories;
  String? losses;
  String? draws;
  String? goalsFor;
  String? goalsAgainst;
  String? goalDifference;
  String? penalty;
  String? goalOnPenalties;
  String? meanAge;

  String? monitions;
  String? evictions;


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return getEntireRefreshablePage();
  }

  @override
  void initState()
  {
    super.initState();
    pageDownloaderInit();
  }

  static const TextStyle categoryStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black);
  static const TextStyle typeStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black);
  static const TextStyle valueStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.black);
  TableRow _getSimpleTableRow(final String category, final IconData icon, final String? value)
  {
    return TableRow(
      children: [
        Row(
          children: [
            Icon(icon),
            const Padding(padding: EdgeInsets.only(left: 2.0)),
            Text(category, style: categoryStyle),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
          child: Align(alignment: Alignment.centerRight, child: Text(value!, style: valueStyle)),
        ),
      ]
    );
  }

  TableRow _getComplexTableRow(final String category, final IconData icon, final List<Pair<String, String?>> values)
  {
    return TableRow(
      children: [
        Row(
          children: [
            Icon(icon),
            const Padding(padding: EdgeInsets.only(left: 2.0)),
            Text(category, style: categoryStyle),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values.map((Pair<String, String?> p) {
              return Padding(
                padding: const EdgeInsets.only(top: 1.0, bottom: 1.0),
                child: RichText(
                  text: TextSpan(
                    text: "${p.first}:  ",
                    style: typeStyle,
                    children: [
                      TextSpan(
                        text: p.second,
                        style: valueStyle
                      )
                    ]
                  ),
                ),
              );
            }).toList()
          ),
        )
      ]
    );
  }

  Widget _getStatsTable()
  {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
          children: [
            _getSimpleTableRow("Punti", Icons.score, points),
            _getSimpleTableRow("Posizione", Icons.format_list_numbered, position),
            _getComplexTableRow("Partite", Icons.event, [Pair("Giocate", gamesPlayed),
                                            Pair("Vinte", victories),
                                            Pair("Pareggiate", draws),
                                            Pair("Perse", losses)]),
            _getComplexTableRow("Gol", Icons.sports_soccer, [Pair("Segnati", goalsFor),
                                        Pair("Subiti", goalsAgainst),
                                        Pair("Diff. Gol", goalDifference),
                                        Pair("Su rigore", goalOnPenalties)]),
            _getSimpleTableRow("Penalità", Icons.report_problem, penalty),
            _getComplexTableRow("Cartellini", Icons.square_rounded, [Pair("Gialli", monitions),
                                               Pair("Rossi", evictions)]),
            if (meanAge != null) _getSimpleTableRow("Età media", Icons.numbers, meanAge)
          ]
        ),
      ),
    );
  }

  @override
  Widget downloadOK() {
    const double fontSize = 18.0;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), //For RefreshIndicator
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Campionato: ", style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize)),
              Text(widget.team.championship ?? "-", style: const TextStyle(fontSize: fontSize))
            ],
          ),
          const Padding(padding: EdgeInsets.only(top: 8.0)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Stagione: ", style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize)),
              Text(widget.team.season ?? "-", style: const TextStyle(fontSize: fontSize))
            ],
          ),
          const Padding(padding: EdgeInsets.only(top: 8.0)),
          _getStatsTable()
        ],
      ),
    );
  }

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/teams/${widget.team.id}/stats/?"
        "&campionato_id=${widget.team.championshipID}&group_id=${widget.team.groupID}&season=${widget.team.season}"
      : "$defaultEndpointURL/getTeamStats.php?teamID=${widget.team.id}"
        "&champ=${widget.team.championship}&group=${widget.team.group}&season=${widget.team.season}";

  @override
  Future<bool> parseDownloadedData(String body) async {

    Map<String, dynamic> json;

    if (body == "[]")
      body = "{}";

    try {
      json = jsonDecode(body);
      points = (json["points"] ?? "-").toString();
      position = json["position"] != null ? "${json["position"].toString()}°" : "-°";
      gamesPlayed = (json["gamesPlayed"] ?? "-").toString();
      victories = (json["victories"] ?? "-").toString();
      losses = (json["losses"] ?? "-").toString();
      draws = (json["draws"] ?? "-").toString();
      goalsFor = (json["goalsFor"] ?? "-").toString();
      goalsAgainst =  (json["goalsAgainst"] ?? "-").toString();
      goalDifference = (json["goalDifference"] ?? "-").toString();
      penalty = (json["penalty"] ?? "-").toString();
      goalOnPenalties = (json["goalsPenalty"] ?? "-").toString();
      meanAge = json["meanAge"] ?. json["meanAge"].toString(); //Displayed only if not null
      monitions = (json["monitions"] ?? "-").toString();
      evictions = (json["evictions"] ?? "-").toString();
    }
    on Exception catch (e)
    {
      debugPrint("Team info json decode error: $e");
      return false;
    }

    return true;
  }

  @override
  bool get wantKeepAlive => true;
}
