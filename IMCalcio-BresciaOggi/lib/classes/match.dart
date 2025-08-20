// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';

import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/pair.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:path_provider/path_provider.dart';


class Match {
  final DateTime? date;
  final DateTime? postponed;
  final Team team1;
  final Team team2;

  final int id;

  final String score1;
  final String score2;

  final String? abnormal;

  final int day;

  bool isLive()
  {
    if (date == null)
      return false;

    if (postponed == null)
      return DateTime.now().difference(date!).inMinutes < 100 && DateTime.now().isAfter(date!);
    return DateTime.now().difference(postponed!).inMinutes < 100 && DateTime.now().isAfter(postponed!);
  }

  Match._(this.id, this.date, this.postponed, this.team1, this.team2, this.score1, this.score2, this.abnormal, this.day);

  /*
  $match = [
      "ID" => $row["ID"],
      "Name1" => $row["Name1"],
      "Name2" => $row["Name2"],
      "Score1" => $row["Score1"],
      "Score2" => $row["Score2"],
      "Timestamp" => $row["Timestamp"],
    ];
   */
  static Match? fromJson(final Map<String, dynamic> json, {int? day})
  {
    //debugPrint("Match fromJson.");
    try {
      final int id = int.parse(json["ID"].toString());

      final DateTime? ts = DateTime.tryParse(json["Timestamp"] ?? "");

      final DateTime? postponedTs = DateTime.tryParse(json["Postponed"] ?? "-");

      //debugPrint("ID: $id, ts: $ts");
      String score1 = (json["Score1"] ?? "0").toString();
      String score2 = (json["Score2"] ?? "0").toString();

      final int id1 = int.tryParse(json["ID1"].toString()) ?? -1;
      final int id2 = int.tryParse(json["ID2"].toString()) ?? -1;

      int? jsonDay = int.tryParse((json["day"] ?? "").toString()); //Day can be assigned from the MatchDay or from single matches (like in this case)

      Match ret = Match._(id, ts, postponedTs, Team.getTeam(json["Name1"], id: id1),
          Team.getTeam(json["Name2"].toString(), id: id2), score1, score2, json["Abnormal"], day ?? jsonDay ?? -1);

      //debugPrint("Ret: $ret");
      return ret;
    } on Exception catch (d, e)
    {
      debugPrint("Match fromJson Error: \n$d\n$e");
      return null;
    }
  }

  String getScoreText()
  {
    DateTime? matchDate = postponed ?? this.date;
    String text;

    if (matchDate != null && matchDate.isBefore(DateTime.now()))
      text = (abnormal == null) ? "$score1 : $score2" : abnormal!;
    else
      text = "- : -";
    return text;
  }
}

//Giornata
class MatchList {
  final List<Match> matches;

  MatchList(this.matches);

  static Pair<MatchList,int> dayFromJson(final Map<String, dynamic> json) //Also checks for day and puts it in the matches
  {
    int day = int.parse(json["day"].toString());
    return Pair(fromJson(json, day: day), day);
  }

  static MatchList fromJson(final Map<String, dynamic> json, {int? day}) //Also checks for day and puts it in the matches
  {
    List<Map<String, dynamic>> matches = List.from(json["matches"]);
    MatchList ret = MatchList(
        matches.map((e) => Match.fromJson(e, day: day)).where((e) => e != null).map((e) => e!).toList());
    //debugPrint("Ret: ${ret.toString()}");
    return ret;
  }

  static void writeFile(final String t) async
  {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/my_file.txt');
    debugPrint("Path: ${directory.path}/my_file.txt");
    file.writeAsStringSync(t);
    //debugger();
  }

  static List<MatchList> dayListFromJson(final Map<String, dynamic> json) //List of match days
  {
    List<Map<String, dynamic>> days = List.from(json["matches"]);
    List<Pair<MatchList,int>> matchDays = []; //List + day
    try {
      /*debugger();*/
      //writeFile(json.toString());
      matchDays = days.map((e) => MatchList.dayFromJson(e)).toList();

    } on Exception catch (d, e)
    {
      debugPrint(d.toString());
      debugPrint(e.toString());
    }

    matchDays.sort((Pair<MatchList,int> a, Pair<MatchList,int> b) => a.second.compareTo(b.second));

    return matchDays.map((Pair<MatchList,int> e) => e.first).toList();
  }
}