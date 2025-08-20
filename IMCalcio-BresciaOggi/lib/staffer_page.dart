import 'dart:convert';

import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/coach.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/player_page.dart';
import 'package:imcalcio/team_page.dart';


class StafferPage extends StatefulWidget {
  const StafferPage(this.type, {super.key, required this.stafferID, required this.stafferFullName});

  final int stafferID;
  final String stafferFullName;
  final StafferType type;

  @override
  State<StafferPage> createState() => _StafferPageState();
}

class StafferTeam {
  final String season;
  final int societyID;
  final String societyName;
  final int championshipID;
  final String championshipName;
  final int groupID;
  final String groupName;
  final int teamID;
  final String teamName;
  final String? from;
  final String? to;
  final int attendances;
  
  const StafferTeam({required this.season, required this.societyID, required this.societyName, required this.championshipID,
    required this.championshipName, required this.groupID, required this.groupName, required this.teamID, required this.teamName,
    required this.from, required this.to, required this.attendances});
}

class _StafferPageState extends State<StafferPage> with PageDownloaderMixin {

  late Staffer staffer;
  List<StafferTeam> stafferTeams = [];

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
        appBar: MyAppBar(title: Text(widget.stafferFullName), centerTitle: true),
        body: getEntireRefreshablePage(),
      ),
    );
  }

  Widget _getStafferInfoEntry(final String title, final String value) {
    const TextStyle titleStyle = TextStyle(fontSize: 18.5, fontWeight: FontWeight.w500);
    const TextStyle valueStyle = TextStyle(fontSize: 17.5, fontWeight: FontWeight.w400);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(title, style: titleStyle),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(value, style: valueStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStafferTeamEntry(final String title, final String value) {
    const TextStyle titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
    const TextStyle valueStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  Widget _getStafferTeamWidget(final StafferTeam stafferTeam)
  {
    final Team team = Team.getTeam(stafferTeam.teamName, id: stafferTeam.teamID, championship: stafferTeam.championshipName,
        championshipID: stafferTeam.championshipID, groupID: stafferTeam.groupID, group: stafferTeam.groupName, season: stafferTeam.season);
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => TeamPage(team: team)));
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(stafferTeam.teamName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17)),
                Text("${stafferTeam.championshipName} - Girone ${stafferTeam.groupName}" , style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17)),
                _getStafferTeamEntry("Stagione: ", stafferTeam.season),
                _getStafferTeamEntry("Presenze: ", stafferTeam.attendances.toString()),
                _getStafferTeamEntry("Da: ", stafferTeam.from ?? "-"),
                _getStafferTeamEntry("A: ", stafferTeam.to ?? "-"),
              ]
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * .25,
              height: MediaQuery.of(context).size.width * .25,
              child: team.icon,
            )
          ],
        ),
      ),
    );
  }

  Widget _getInfoCard()
  {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * .3,
                maxHeight: screenWidth * .3
              ),
              child: staffer.icon
            ),
            const Padding(padding: EdgeInsets.only(top: 4.0)),
            Text("Info ${widget.type.italianName}:", style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w500)),
            const Padding(padding: EdgeInsets.only(top: 4.0)),
            _getStafferInfoEntry("Città di nascita:", staffer.city ?? "-"),
            _getStafferInfoEntry("Data di nascita:", formatDateTime(staffer.birthday ?? "-")),
            _getStafferInfoEntry("Età:", staffer.age != null ? staffer.age.toString() : "-"),
          ],
        ),
      )
    );
  }

  Widget _getTeamsCard()
  {
    return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Text("Squadre di appartenenza:", style: TextStyle(fontSize: 21, fontWeight: FontWeight.w500)),
              if (stafferTeams.isNotEmpty) ...(stafferTeams.expand((e) => [
                _getStafferTeamWidget(e),
                if (e != stafferTeams.last) const Divider()]).toList()
              ),
              if (stafferTeams.isEmpty) const Text("Non ci sono squadre associate a questo allenatore.",
                  style: TextStyle(color: Colors.red, fontSize: 19, fontWeight: FontWeight.w500)),
            ],
          )
        )
    );
  }

  @override
  Widget downloadOK() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), //For scroll indicator
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _getInfoCard(),
            const Padding(padding: EdgeInsets.only(top: 8.0, bottom: 8.0), child: Divider(thickness: 3.0,)),
            _getTeamsCard()
          ],
        ),
      ),
    );
  }

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/staff/${widget.type.newAPIWebPageName}/${widget.stafferID}/"
                                         : "$defaultEndpointURL/${widget.type.localWebPageName}?id=${widget.stafferID}";

  @override
  Future<bool> parseDownloadedData(String body) async {
    debugPrint("Downloading ${widget.type.name} page of ${widget.stafferFullName} - ID ${widget.stafferID}");
    
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
      
      if (!json.containsKey("info")) {
        debugPrint("Json does not contain the info key");
        return false;
      }
      if (!json.containsKey("teams")) {
        debugPrint("Json does not contain the teams key");
        return false;
      }

      Map<String, dynamic> infoJson = json["info"][0]; //TODO TOGLIERE LO [0], WORKAROUND!
      staffer = widget.type.buildStaffer(widget.stafferID,
        firstName: infoJson["firstName"],
        lastName: infoJson["lastName"],
        birthday: infoJson["birthday"],
        city: infoJson["city"],
        age: int.tryParse(infoJson["age"] ?? "-")
      );

      List<Map<String, dynamic>> teamsJson = List.from(json["teams"]);
      stafferTeams = teamsJson.expand((e) {
        try {
          return [StafferTeam(season: e["season"],
            societyID: int.parse(e["societyID"].toString()),
            societyName: e["societyName"],
            championshipID: int.parse(e["championshipID"].toString()),
            championshipName: e["championshipName"],
            groupID: int.parse(e["groupID"].toString()),
            groupName: e["groupName"],
            teamID: int.parse(e["teamID"].toString()),
            teamName: e["teamName"],
            from: e["from"],
            to: e["to"],
            attendances: int.parse(e["attendances"].toString())
          )];
        } catch (e, f) {
          debugPrint("Coach team json error: $f");
          return <StafferTeam>[];
        }
      }).toList();

    } on Exception catch (e) {
      debugPrint("Json error: $e");
      return false;
    }

    debugPrint(stafferTeams.toString());

    return true;
  }

}
