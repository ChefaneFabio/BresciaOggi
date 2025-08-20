// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:autoscale_tabbarview/autoscale_tabbarview.dart';
import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/championship.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/player.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/team_page.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.searchPlayer, required this.season});

  final SearchPlayer searchPlayer;
  final String season;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

const Map<String, String> roleMap = {
  'c' : "Centrocampista",
  'a' : "Attaccante",
  'd' : "Difensore",
  'p' : "Portiere"
};

String formatDateTime(final String dateTime)
{
  List<String> elements = dateTime.split("-");
  if (elements.length != 3)
    return dateTime;
  return "${elements[2]}-${elements[1]}-${elements[0]}";
}

class _PlayerPageState extends State<PlayerPage> with PageDownloaderMixin, TickerProviderStateMixin {

  late PlayerInfo playerInfo;
  late PlayerStats champStats;
  late PlayerStats totalStats;

  late TabController _tabController;
  int selectedTab = 0;

  bool _totalStatsSelected = false; //Display only current championship stats or total stats

  @override
  void initState()
  {
    super.initState();
    pageDownloaderInit();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
          appBar: MyAppBar(
            title: Text("${widget.searchPlayer.firstName} ${widget.searchPlayer.lastName}"),
            centerTitle: true,
          ),
          body: getEntireRefreshablePage()
      ),
    );
  }
  
  void _navigateToTeam()
  {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => TeamPage(
      team: Team.getTeam(widget.searchPlayer.teamName, id: widget.searchPlayer.teamID,
        championship: widget.searchPlayer.champName, championshipID: widget.searchPlayer.champID,
        groupID: playerInfo.groupID, group: playerInfo.groupName, season: widget.season)
    )));
  }

  Widget _getPlayerCard()
  {
    final Team team = Team.getTeam(widget.searchPlayer.teamName, id: widget.searchPlayer.teamID);
    final Championship championship = Championship(widget.searchPlayer.champName, widget.searchPlayer.champID);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row( //Team, Player and championship icons
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => _navigateToTeam(),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * .25,
                    height: MediaQuery.of(context).size.width * .25,
                    child: team.icon,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .3,
                  height: MediaQuery.of(context).size.width * .3,
                  child: playerInfo.icon,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .25,
                  height: MediaQuery.of(context).size.width * .25,
                  child: championship.getIcon(widget.season),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.only(top: 8.0)),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("${widget.searchPlayer.firstName} ${widget.searchPlayer.lastName}",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
                GestureDetector(
                  onTap: () => _navigateToTeam(),
                  child: Text(team.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                ),
                Text("${championship.name} - ${widget.season}",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      )
    );
  }

  Widget _getStatsRow(final String name, final String value)
  {
    const double fontSize = 17;
    return Padding(
      padding: const EdgeInsets.only(top: 3.0, bottom: 3.0, left: 5.0, right: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize)),
          Text(value, style: const TextStyle(fontSize: fontSize))
        ],
      ),
    );
  }

  Widget _getPlayerRegistryTab()
  {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getStatsRow("Data di nascita:", formatDateTime(playerInfo.birthday ?? "-")),
          const Divider(),
          _getStatsRow("Età:" ,playerInfo.age ?? "-"),
          const Divider(),
          _getStatsRow("Ruolo:", (playerInfo.role != null && roleMap.containsKey(playerInfo.role)) ? roleMap[playerInfo.role]! : "-"),
          const Divider(),
          _getStatsRow("Altezza:", playerInfo.height != null ? "${playerInfo.height} cm" : "-"),
          const Divider(),
          _getStatsRow("Peso:", playerInfo.weight != null ? "${playerInfo.weight} kg" : "-"),
          const Divider(),
          _getStatsRow("Piede:", playerInfo.feet ?? "-"),
          const Divider(),
          _getStatsRow("Numero maglia:", (playerInfo.shirtNumber == null) ? "-" : playerInfo.shirtNumber.toString()),
          const Divider(),
          _getStatsRow("Città di nascita:", playerInfo.city ?? "-"),
        ],
      ),
    );
  }

  Widget _getStatsModeSelector()
  {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: SegmentedButton<bool>(
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
              ButtonSegment<bool>(
                  value: false,
                  label: Text("Statistiche campionato"),
                  icon: Icon(Icons.emoji_events)
              ),
              ButtonSegment<bool>(
                  value: true,
                  label: Text("Statistiche totali"),
                  icon: Icon(Icons.description)
              )
            ],
            selected: {!_totalStatsSelected},
            onSelectionChanged: (Set<bool> newValue) {
              setState(() {
                _totalStatsSelected = !newValue.first;
              });
            }),
      ),
    );
  }

  Widget _getPlayerStatsTab()
  {

    PlayerStats stats = _totalStatsSelected ? totalStats : champStats;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getStatsModeSelector(),
          const Padding(padding: EdgeInsets.only(top: 8)),
          _getStatsRow("Gol:", stats.goals.toString()),
          const Divider(),
          _getStatsRow("Presenze da titolare:", stats.attendancesHolder.toString()),
          const Divider(),
          _getStatsRow("Presenze da riserva:", stats.attendancesReserve.toString()),
          const Divider(),
          _getStatsRow("Ammonizioni:", stats.monitions.toString()),
          const Divider(),
          _getStatsRow("Espulsioni:", stats.evictions.toString()),
          const Divider(),
          _getStatsRow("Minuti giocati:", stats.minutes.toString()),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget downloadOK() {
    const double tabFontSize = 17.0;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getPlayerCard(),
          const Padding(padding: EdgeInsets.only(top: 8)),
          TabBar(controller: _tabController,
            onTap: (index) {
              setState(() {
                selectedTab = index;
              });
            },
            tabs: const [Tab(child: Text("Statistiche", style: TextStyle(fontSize: tabFontSize))),
              Tab(child: Text("Anagrafica", style: TextStyle(fontSize: tabFontSize)))]),
          AutoScaleTabBarView(
            controller: _tabController,
            children: [
              _getPlayerStatsTab(),
              _getPlayerRegistryTab()])
        ]
      ),
    );
  }

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/players/${widget.searchPlayer.id}/?champ_id=${widget.searchPlayer.champID}"
                              "&season=${widget.season}"
                            : "$defaultEndpointURL/getPlayerInfo.php?id=${widget.searchPlayer.id}"
                                "&champID=${widget.searchPlayer.champID}&season=${widget.season}";

  @override
  Future<bool> parseDownloadedData(String body) async {
    debugPrint("Downloading player info of ${widget.searchPlayer.id}");

    List<Map<String, dynamic>> jsonl;
    try {
      jsonl = List.from(jsonDecode(body));
      Map<String,dynamic> json = jsonl[0]; //Workaround
      playerInfo = PlayerInfo(widget.searchPlayer.id,
        birthday: json["birthday"],
        age: json["age"],
        sex: json["sex"],
        city: json["city"],
        weight: json["weight"],
        height: json["height"],
        role: json["role"],
        shirtNumber: int.tryParse(json["shirtNumber"].toString()),
        feet: json["feet"],
        groupID: int.parse(json["groupID"].toString()),
        groupName: json["groupName"],
      );

      champStats = PlayerStats(
        attendancesHolder: int.tryParse((json["attendancesHolder"] ?? "").toString()) ?? 0,
        attendancesReserve: int.tryParse((json["attendancesReserve"] ?? "").toString()) ?? 0,
        goals: int.tryParse((json["goals"] ?? "0").toString()) ?? 0,
        monitions: int.tryParse((json["monitions"] ?? "").toString()) ?? 0,
        evictions: int.tryParse((json["evictions"] ?? "").toString()) ?? 0,
        minutes: int.tryParse((json["minutes"] ?? "").toString()) ?? 0,
      );

      if (json["totalAttendancesHolder"] == null)
        totalStats = champStats; //Retrocompatibility
      else {
        totalStats = PlayerStats(
          attendancesHolder: int.tryParse(
              (json["totalAttendancesHolder"] ?? "").toString()) ?? 0,
          attendancesReserve: int.tryParse(
              (json["totalAttendancesReserve"] ?? "").toString()) ?? 0,
          goals: int.tryParse((json["totalGoals"] ?? "0").toString()) ?? 0,
          monitions: int.tryParse((json["totalMonitions"] ?? "").toString()) ?? 0,
          evictions: int.tryParse((json["totalEvictions"] ?? "").toString()) ?? 0,
          minutes: int.tryParse((json["totalMinutes"] ?? "").toString()) ?? 0,
        );
      }
    } on Exception catch (_, e) {
      debugPrint("Json error: $e");
      return false;
    }

    return true;
  }
  
  
}
