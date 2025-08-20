// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/Material.dart';

enum ScoreboardType
{
  totale, casa, trasferta;
}

class ScoreboardEntry
{
  final int teamID;
  final String teamName;
  final int points;
  final int gamesPlayed;
  final int losses;
  final int victories;
  final int draws;
  final int goalsAgainst;
  final int goalsFor;
  final int goalDifference;
  final int penalty;
  int? _position;
  List<String> _shape = [];

  void setPosition(final int pos)
  {
    _position = pos;
  }

  void setShape(final String shape)
  {
    _shape = shape.split('').reversed.take(5).toList().reversed.toList(); //Take the last 5 elements max.
  }

  List<String> get shape => _shape;

  int? get position => _position;

  ScoreboardEntry({required this.teamID, required this.teamName, required this.points, required this.gamesPlayed,
                        required this.losses, required this.victories, required this.draws, required this.goalsAgainst,
                        required this.goalsFor, required this.goalDifference, required this.penalty});

  ScoreboardEntry operator +(final ScoreboardEntry second)
  {
    if (teamID != second.teamID)
      debugPrint("Warning: summing wrong scoreboard entries. ID1 = $teamID, ID2 = ${second.teamID}");
    return ScoreboardEntry(
      teamID: teamID,
      teamName: teamName,
      points: points + second.points,
      gamesPlayed: gamesPlayed + second.gamesPlayed,
      losses: losses + second.losses,
      victories: victories + second.victories,
      draws: draws + second.draws,
      goalsAgainst: goalsAgainst + second.goalsAgainst,
      goalsFor: goalsFor + second.goalsFor,
      goalDifference: goalDifference + second.goalDifference,
      penalty: penalty + second.penalty
    );
  }

  ScoreboardEntry.empty(this.teamID, this.teamName) //Creates an empty ScoreboardEntry
  : points = 0, gamesPlayed = 0, losses = 0, victories = 0, draws = 0,
    goalsAgainst = 0, goalsFor = 0, goalDifference = 0, penalty = 0;

  String getSignedDifference()
  {
    return goalDifference > 0 ? "+$goalDifference" : goalDifference.toString();
  }

  static ScoreboardEntry fromJson(final Map<String, dynamic> entry)
  {
    return ScoreboardEntry(
      teamID: int.tryParse((entry["id"] ?? "0").toString()) ?? 0,
      teamName: entry["name"] ?? "",
      points: int.tryParse((entry["points"] ?? "0").toString()) ?? 0,
      gamesPlayed: int.tryParse((entry["gamesPlayed"] ?? "0").toString()) ?? 0,
      losses: int.tryParse((entry["losses"] ?? "0").toString()) ?? 0,
      victories: int.tryParse((entry["victories"] ?? "0").toString()) ?? 0,
      draws: int.tryParse((entry["draws"] ?? "0").toString()) ?? 0,
      goalsAgainst: int.tryParse((entry["goalsAgainst"] ?? "0").toString()) ?? 0,
      goalsFor: int.tryParse((entry["goalsFor"] ?? "0").toString()) ?? 0,
      goalDifference: int.tryParse((entry["goalDifference"] ?? "0").toString()) ?? 0,
      penalty: int.tryParse((entry["penalty"] ?? "0").toString()) ?? 0
    );
  }
}

class ScoreboardCategory { //Promozione, retrocessione, ...
  final int positionMin; //Starting position in the scoreboard
  final int positionMax; //Ending position in the scoreboard
  final Color color; //Color of the category (left row in position and category list)
  final String name; //Name of the category (bottom in category list)

  const ScoreboardCategory({required this.positionMin, required this.positionMax, required this.color, required this.name});

  static Color getColorCategory(final int position, final List<ScoreboardCategory> categories)
  {
    try {
      final ScoreboardCategory selectedCategory = categories.firstWhere((e) =>
      e.positionMin <= position && position <= e.positionMax);
      return selectedCategory.color;
    }
    catch (e)
    {
      return Colors.transparent;
    }
  }

  static List<ScoreboardCategory> getCategoryListForChampionship(final String championship)
  {
    debugPrint("Championship: _${championship}_");
    if (championship == "Serie A")
    {
      return const [
        ScoreboardCategory(positionMin: 1, positionMax: 1, color: Colors.yellow, name: "Campione"),
        ScoreboardCategory(positionMin: 2, positionMax: 4, color: Colors.blue, name: "Champions League"),
        ScoreboardCategory(positionMin: 5, positionMax: 5, color: Colors.orangeAccent, name: "Europa League"),
        ScoreboardCategory(positionMin: 6, positionMax: 6, color: Colors.green, name: "Conference League"),
        ScoreboardCategory(positionMin: 18, positionMax: 20, color: Colors.red, name: "Retrocessione"),
      ];
    }
    return const [];
  }
}

class Scoreboard
{
  late List<ScoreboardEntry> entries;

  Scoreboard(this.entries);

  Scoreboard operator +(final Scoreboard second)
  {
    List<ScoreboardEntry> ret = List.from(entries);
    for (int i = 0; i < second.entries.length; i++) {
      //Check if there is the same team on the second one
      ScoreboardEntry entry2 = second.entries[i];
      int retEntry = ret.indexWhere((e) => e.teamID == entry2.teamID);
      if (retEntry >= 0) //If exists, sum the two
        ret[retEntry] = ret[retEntry] + entry2;
      else //Add to the list
        ret.add(entry2);
    }

    ret.sort((a, b) { //Firstly, sort by points desc. If tie, sort like the second one. This is because it is assumed that second is the 'total', while first is the empty.
      final int pointComp = b.points.compareTo(a.points);
      if (pointComp != 0)
        return pointComp;
      return second.entries.indexWhere((a1) => a1.teamID == a.teamID).compareTo(second.entries.indexWhere((b1) => b1.teamID == b.teamID));
    });
    for (int i = 0; i < ret.length; i++)
      ret[i].setPosition(i+1);

    return Scoreboard(ret);
  }

  static Scoreboard fromJson(final List<Map<String,dynamic>> json)
  {
    List<ScoreboardEntry> entries = [];
    for (Map<String,dynamic> jsonEntry in json)
    {
      ScoreboardEntry entry = ScoreboardEntry.fromJson(jsonEntry);
      entries.add(entry);
    }

    //entries.sort((a,b) => b.points.compareTo(a.points));
    for (int i = 0; i < entries.length; i++)
      entries[i].setPosition(i+1);

    return Scoreboard(entries);
  }

  void addShape(final Map<int, String> shapes) // id -> shape
  {
    for (ScoreboardEntry e in entries)
    {
      String? shape = shapes[e.teamID];
      if (shape == null)
      {
        debugPrint("Warning: shape of ${e.teamID} is null.");
        continue;
      }
      e.setShape(shape);
    }
  }

  static void setScoreboardShapes(Scoreboard houseBoard, Scoreboard transferBoard,
      Scoreboard totalBoard, final List<Map<String, dynamic>> json)
  {
    Map<int, String> houseShapes = {};
    Map<int, String> transferShapes = {};
    Map<int, String> totalShapes = {};

    for (Map<String, dynamic> entry in json)
    {
      try
      {
        int teamID = int.parse(entry["id"].toString());
        String totalShape = entry["TotalStatuses"]!;
        String houseShape = entry["HouseStatuses"]!;
        String transferShape = entry["TransferStatuses"]!;
        houseShapes[teamID] = houseShape;
        totalShapes[teamID] = totalShape;
        transferShapes[teamID] = transferShape;
      }
      on Exception catch (_)
      {
        debugPrint("Warning: malformed scoreboard shape json: $entry");
        continue;
      }
    }
    houseBoard.addShape(houseShapes);
    transferBoard.addShape(transferShapes);
    totalBoard.addShape(totalShapes);
  }
}
