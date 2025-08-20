// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/team_page.dart';

class SocietyTeamEntry {
  final int teamID;
  final String teamName;
  final int groupID;
  final String groupName;
  final int championshipID;
  final String championshipName;

  const SocietyTeamEntry({required this.teamID, required this.teamName, required this.groupID, required this.groupName,
                          required this.championshipID, required this.championshipName});
}

class SocietyInfoEntry
{
  final String name;
  final String? value;
  final bool forceDisplay; //Display even if value == null

  const SocietyInfoEntry(this.name, this.value, this.forceDisplay);

  Widget? getEntryWidget()
  {
    if ((value == null || value!.length <= 1) && !forceDisplay)
      return null;

    String valueDisplay = (value != null && value!.length > 1) ? value! : "-"; //length <= 1 for CAP == 0

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text("$name:", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        Expanded(flex: 3, child: Text(valueDisplay, style: const TextStyle(fontSize: 14.5)))
      ],
    );
  }
}

class TeamSocietyPage extends StatefulWidget {
  const TeamSocietyPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamSocietyPage> createState() => _TeamSocietyPageState();
}

class _TeamSocietyPageState extends State<TeamSocietyPage> with AutomaticKeepAliveClientMixin, PageDownloaderMixin {

  List<SocietyInfoEntry> infos = [];
  List<SocietyTeamEntry> societyTeams = [];

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/teams/${widget.team.id}/?season=${widget.team.season}"
                                         : "$defaultEndpointURL/getTeamInfo.php?teamID=${widget.team.id}&season=${widget.team.season}";

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
  Widget downloadOK() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), //For RefreshIndicator
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * .35,
                  height: MediaQuery.of(context).size.width * .35,
                  child: widget.team.icon
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: _societyTeamsButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Button color
                    foregroundColor: Colors.black, // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  ),
                  child: const Text("Squadre della società", style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
          const Padding(padding: EdgeInsets.only(top: 8.0)),
          ...infos.expand<Widget>((e) {
            Widget? n = e.getEntryWidget();
            return n == null ? [] : [n, const Divider()];
          }).toList()
        ],
      ),
    );
  }

  void _societyTeamsButtonPressed()
  {
    const double titleSize = 20.0;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).canvasColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners for the dialog
          ),
          title: const Text(
            "Squadre della società",//$championshipName, $groupName",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: titleSize), // Custom text style for the title
          ),
          content: SizedBox(
            width: 10, //Min width, it will automatically adapt
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: societyTeams.expand((e) => [
                  InkWell(
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    title: Text(e.teamName),
                    subtitle: Text("${e.championshipName} - ${e.groupName}"),
                    trailing: (e.teamID == widget.team.id && widget.team.championshipID == e.championshipID) ? const Icon(Icons.check_circle) : null,
                    onTap: () {
                      if (e.teamID == widget.team.id && widget.team.championshipID == e.championshipID)
                        return Navigator.of(context).pop();
                      Navigator.of(context).pop(); //Close dialog
                      Navigator.of(context).pop(); //Close team page
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => TeamPage(
                        team: Team.getTeam(e.teamName,
                          id: e.teamID,
                          championship: e.championshipName,
                          championshipID: e.championshipID,
                          group: e.groupName,
                          groupID: e.groupID,
                          season: widget.team.season
                        )
                      )));
                    },
                  )),
                  if (societyTeams.last != e) const Divider(thickness: 2.0)
                ]).toList()),
            )
          ),
        );
      },
    );
  }

  @override
  Future<bool> parseDownloadedData(String body) async {

    List<SocietyInfoEntry> newEntries = [];

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
    }
    on Exception catch (e)
    {
      debugPrint("Team info json decode error: $e");
      return false;
    }

    newEntries.add(SocietyInfoEntry("Matricola", json["matricola"].toString(), true));
    newEntries.add(SocietyInfoEntry("Nome società", json["societyName"], true));
    newEntries.add(SocietyInfoEntry("Nome squadra", widget.team.name, true)); //teamDefaultName = json["teamDefaultName"];
    newEntries.add(SocietyInfoEntry("Sigla società", json["societyPrefix"], true));
    newEntries.add(SocietyInfoEntry("Anno fondazione", json["year"], false));
    newEntries.add(SocietyInfoEntry("Comitato regionale", json["committee"], true));
    newEntries.add(SocietyInfoEntry("Indirizzo sede", (json["address"] ?? "") + (json["addressStreet"] == null ? "" : " ${json["addressStreet"]}"), true));
    newEntries.add(SocietyInfoEntry("Località", json["locality"], true));
    newEntries.add(SocietyInfoEntry("Provincia", json["province"], false));
    newEntries.add(SocietyInfoEntry("CAP", json["cap"].toString(), false));

    newEntries.add(SocietyInfoEntry("Nome stadio", json["stadiumName"], false));
    newEntries.add(SocietyInfoEntry("Indirizzo stadio", json["stadiumAddress"], false));
    newEntries.add(SocietyInfoEntry("Località stadio", json["stadiumLocality"], false));
    if (json["stadiumProvince"] == "Altri") json["stadiumProvince"] = "";
    newEntries.add(SocietyInfoEntry("Provincia stadio", json["stadiumProvince"], false));
    newEntries.add(SocietyInfoEntry("CAP stadio", json["stadiumCAP"], false));

    newEntries.add(SocietyInfoEntry("Recapito telefonico", json["telephone"], true));
    newEntries.add(SocietyInfoEntry("Email", json["email"], true));
    newEntries.add(SocietyInfoEntry("Sito ufficiale", json["website"], true));
    newEntries.add(SocietyInfoEntry("Presidente", json["president"], true));
    newEntries.add(SocietyInfoEntry("Telefono presidente", json["presidentTelephone"], false));
    newEntries.add(SocietyInfoEntry("Telefono segretario", json["secretaryTelephone"], false));
    List<String?> colors = [json["color1"], json["color2"], json["color3"]];

    if (colors[0] == colors[1] || colors[0] == colors[2])
      colors.removeAt(0);
    else if (colors[1] == colors[2])
      colors.removeAt(1);

    colors.removeWhere((e) => e == null);

    String? color;
    if (colors.isEmpty)
      color = "-";
    else if (colors.length == 1)
      color = colors[0];
    else if (colors.length == 2)
      color = "${colors[0]}-${colors[1]}";
    else
      color = "${colors[0]}-${colors[1]}-${colors[2]}";

    newEntries.add(SocietyInfoEntry("Colori della squadra", color, true));

    infos = newEntries;

    final String teamDefaultName = json["teamDefaultName"] ?? json["societyName"];

    //Decode society teams
    try {
      List<Map<String, dynamic>> societyTeamsJson = List.from(
          json["societyTeams"]);
      List<SocietyTeamEntry> societyTeams = societyTeamsJson.map((teamJson) =>
          SocietyTeamEntry(
              teamID: int.parse(teamJson["teamID"].toString()),
              teamName: teamJson["teamName"] ?? teamDefaultName,
              championshipID: int.parse(teamJson["champID"].toString()),
              championshipName: teamJson["champName"],
              groupID: int.parse(teamJson["groupID"].toString()),
              groupName: teamJson["groupName"])).toList();

      this.societyTeams = societyTeams;
    } catch (e, d)
    {
      debugPrint("Error: $e, $d");
      return false;
    }

    return true;
  }

  @override
  bool get wantKeepAlive => true;
}
