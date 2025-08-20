import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/match.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/results_match_list_page.dart';

class TeamResultsPage extends StatefulWidget {
  const TeamResultsPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamResultsPage> createState() => _TeamResultsPageState();
}

class _TeamResultsPageState extends State<TeamResultsPage> with AutomaticKeepAliveClientMixin, PageDownloaderMixin {

  late MatchList matches;
  late int numDays;

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
    if (matches.matches.isNotEmpty) {
      return ListView(
          shrinkWrap: true,
          children: matches.matches.reversed.take(10).map((e) => //Last 10 matches (Already filtered)
          ResultsDayPageState.getMatchWidget(
              context, e, widget.team.season!, widget.team.championshipID!,
              widget.team.championship!, widget.team.groupID!, widget.team.group!,
              e.day - 1 < numDays / 2 ? "${e.day}/A" : "${e.day}/R")).toList()
      );
    }
    else {
      //If there are no matches for this day
      return const Center(
        child: AutoSizeText("Le partite sono in fase di aggiornamento", minFontSize: 10, maxFontSize: 30, style: TextStyle(fontSize: 25), textAlign: TextAlign.center),
      );
    }
  }

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/matches/?season=${widget.team.season}"
      "&group_id=${widget.team.groupID}&campionato_id=${widget.team.championshipID}&team_id=${widget.team.id}"
      : "$defaultEndpointURL/getMatchList.php"
      "?season=${widget.team.season}&group_id=${widget.team.groupID}"
      "&championship_id=${widget.team.championshipID}&team=${widget.team.id}";

  @override
  Future<bool> parseDownloadedData(String body) async {
    MatchList newMatches;
    Map<String,dynamic> json;
    try {
      json = jsonDecode(body);
      numDays = int.parse(json["numDays"].toString());
      newMatches = MatchList.fromJson(json);
      //Take only the old ones
      newMatches.matches.retainWhere((e) => e.date != null && e.date!.isBefore(DateTime.now()));
    }
    on Exception catch (e) {
      debugPrint("Team results json error: $e");
      return false;
    }

    matches = newMatches;
    return true;
  }

  @override
  bool get wantKeepAlive => true;
}
