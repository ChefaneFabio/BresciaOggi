// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/match.dart';

class FormationGoal {
  final int minute;
  final int set;

  final bool penalty;
  final int advantagedTeamID; //To know if it is an auto goal

  static int countPenalties(final List<FormationGoal> goals)
  {
    return goals.fold(0, (v, e) => v + (e.penalty ? 1 : 0));
  }

  static int countAutoGoals(final List<FormationGoal> goals, final int playerTeamID)
  {
    return goals.fold(0, (v, e) => v + (e.advantagedTeamID != playerTeamID ? 1 : 0));
  }

  static int countNormalGoals(final List<FormationGoal> goals, final int playerTeamID)
  {
    return goals.length - countPenalties(goals) - countAutoGoals(goals, playerTeamID);
  }

  const FormationGoal(this.minute, this.set, this.penalty, this.advantagedTeamID);
}

class FormationPlayer //Used only in formations
{
  final String firstName;
  final String lastName;
  final int id; //DB id
  final int teamID;
  final int number;
  final int entranceMinute;
  final int entranceSet;
  final int exitMinute;
  final int exitSet; //Primo o secondo (P, S, PS, SS)

  final int minutesPlayed;

  final int substitutedWithID; //ID del giocatore con il cui è stato sostituito
  final int substitutedNumber; //Numero del giocatore con il cui è stato sostituito

  final int monitionMinute;
  final int monitionSet;
  final bool monitionX; //Because on the DB there is only an X for monitions

  final int evictionMinute;
  final int evictionSet;

  final String monitionReason;
  final String substitutionReason;
  final String evictionReason;

  final List<FormationGoal> goals;

  const FormationPlayer(this.firstName, this.lastName, this.number, this.id, this.teamID, this.entranceMinute, this.entranceSet, this.exitMinute, this.exitSet, this.minutesPlayed,
      this.substitutedWithID, this.substitutedNumber, this.monitionMinute, this.monitionSet, this.monitionX, this.evictionMinute, this.evictionSet,
      this.monitionReason, this.substitutionReason, this.evictionReason, this.goals);
}

class FormationType
{
  static FormationType getDefault()
  {
    return fromString("4-4-2", isUnknown: true);
  }

  const FormationType(this.name, this.playerDivision, this.unknown);

  final List<int> playerDivision;
  final String name;
  final bool unknown; //Se la formazione è sconosciuta, quindi si usa quella di default.

  static FormationType fromString(final String id, {bool isUnknown = false}) //"4-4-2" to [4,4,2]
  {
    List<int> division = [];
    for (int i = 0; i < id.length; i++)
    {
      if (id.substring(i,i+1) == "-")
        continue;
      int currRow = int.tryParse(id.substring(i,i+1)) ?? 2;
      division.add(currRow);
    }

    return FormationType(id, division, isUnknown);
  }

  int getRows()
  {
    return playerDivision.length;
  }

  int getRowLength(final int row)
  {
    return playerDivision[row];
  }
}

class FormationReferee
{
  final int id;
  final String name;

  static const List<String> types = ["Direttore di gara", "Secondo Arbitro", "Terzo Arbitro", "Quarto Arbitro", "Arbitro VAR"];

  FormationReferee(this.id, this.name);
}

class Formation
{
  final List<FormationPlayer> playersTeam1;
  final List<FormationPlayer> playersTeam2;

  late final FormationType typeTeam1;
  late final FormationType typeTeam2;

  Formation(this.playersTeam1, this.playersTeam2, this.typeTeam1, this.typeTeam2, this.referees);

  late final Map<int,FormationReferee> referees; //type (first, second, VAR..) -> Referee

  static Formation fromJson(final Match match, final Map<String,dynamic> json)
  {
    debugPrint("formation fromJson");
    final List<Map<String, dynamic>> formationJson = List.from(json["formations"]);
    final List<Map<String, dynamic>> goalsJson = List.from(json["goals"]);
    final Map<String, dynamic> refereeJson = json["referees"];

    String schema1 = (json.containsKey("Modulo1") ? json["Modulo1"] : "") ?? "";
    String schema2 = (json.containsKey("Modulo2") ? json["Modulo2"] : "") ?? "";

    FormationType type1 = schema1.isNotEmpty ? FormationType.fromString(schema1) : FormationType.getDefault();
    FormationType type2 = schema2.isNotEmpty ? FormationType.fromString(schema2) : FormationType.getDefault();

    List<FormationPlayer> players1 = [];
    List<FormationPlayer> players2 = [];

    Map<int, List<FormationGoal>> playerGoals = {}; //Map from player ID to goals

    Map<int,FormationReferee> referees = {};

    for (Map<String, dynamic> gj in goalsJson)
    {
      final int goalPlayerID = int.parse((gj["PlayerID"] ?? "-1").toString());
      final int goalMinute = int.parse((gj["Minute"] ?? "-1").toString());
      final int goalSet = int.parse((gj["Set"] ?? "-1").toString());
      final int advantagedTeamID = int.parse((gj["TeamFavID"] ?? "-1").toString());
      final String goalType = gj["Type"] ?? "Goal";
      FormationGoal goal = FormationGoal(goalMinute, goalSet, goalType == "Penalty", advantagedTeamID);
      if (playerGoals.containsKey(goalPlayerID))
        playerGoals[goalPlayerID]!.add(goal);
      else
        playerGoals[goalPlayerID] = [goal];
    }

    //Referees
    for (int i = 1; i <= 5; i++)
    {
      int id = int.parse((refereeJson["ID$i"] ?? "-1").toString()); //Parse every ID1 ... ID5
      if (id == -1)
        continue;

      String name = refereeJson["Name$i"] ?? "-"; //Parse every Name1 .. Name5
      FormationReferee referee = FormationReferee(id, name);
      referees[i] = referee;
    }

    for (Map<String, dynamic> f in formationJson) {
      String firstName = f["FirstName"] ?? "Giocatore";
      //debugPrint("FirstName: ${f["FirstName"]}");
      String lastName = f["LastName"] ?? "Giocatore";

      int playerID = int.parse((f["playerID"] ?? "-1").toString());
      int number = int.parse((f["number"] ?? "-1").toString());
      int entranceMinute = int.parse((f["entranceMinute"] ?? "-1").toString());
      int entranceSet = int.parse((f["entranceSet"] ?? "-1").toString());
      int exitMinute = int.parse((f["exitMinute"] ?? "-1").toString());
      int exitSet = int.parse((f["exitSet"] ?? "-1").toString());
      int minutesPlayed = int.parse((f["minutesPlayed"] ?? "-1").toString());
      int substitutedWithID = int.parse((f["substitutedWithID"] ?? "-1").toString());
      int substitutedNumber = int.parse((f["substitutedNumber"] ?? "-1").toString());
      int monitionMinute = int.parse((f["monitionMinute"] ?? "-1").toString());
      int monitionSet = int.parse((f["monitionSet"] ?? "-1").toString());
      int evictionMinute = int.parse((f["evictionMinute"] ?? "-1").toString());
      int evictionSet = int.parse((f["evictionSet"] ?? "-1").toString());
      String monitionReason = f["monitionReason"] ?? "";
      String substitutionReason = f["substitutionReason"] ?? "";
      String evictionReason = f["evictionReason"] ?? "";
      int teamID = int.parse((f["teamID"] ?? "-1").toString());
      bool monitionX = f["monitionX"] != null && f["monitionX"].toString().isNotEmpty;
      //debugPrint("PlayerID: $playerID");

      List<FormationGoal> goals = playerGoals.containsKey(playerID) ? playerGoals[playerID]! : [];

      FormationPlayer player = FormationPlayer(firstName, lastName, number, playerID, teamID, entranceMinute, entranceSet, exitMinute, exitSet, minutesPlayed, substitutedWithID,
          substitutedNumber, monitionMinute, monitionSet, monitionX, evictionMinute, evictionSet, monitionReason, substitutionReason, evictionReason, goals);
      if (teamID == match.team1.id)
        players1.add(player);
      else
        players2.add(player);
    }

    players1.sort((a,b) => a.number.compareTo(b.number));
    players2.sort((a,b) => a.number.compareTo(b.number));

    debugPrint("End Formation fromJson");
    debugPrint("PlayerGoals: $playerGoals");

    return Formation(players1, players2, type1, type2, referees);
  }

  /*static Formation test()
  {
    Formation ret = Formation();
    ret.typeTeam1 = FormationType.fromString("442");
    ret.typeTeam2 = FormationType.fromString("4312");

    for (int i = 0; i < 20; i++) {
      ret.playersTeam1.add(FormationPlayer("P$i", (i + 1), i * 10));
      ret.playersTeam2.add(FormationPlayer("P$i", (i + 1), i * 10));
    }

    return ret;
  }*/
}