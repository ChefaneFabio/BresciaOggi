import 'dart:io';

import 'package:flutter/material.dart';
import 'package:imcalcio/classes/image_loader.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/formations_page.dart';
import 'package:path_provider/path_provider.dart';


class SearchPlayer
{
  final int id;
  final String firstName;
  final String lastName;
  final int teamID;
  final String teamName;
  final int champID;
  final String champName;
  final int? matricola;

  const SearchPlayer(this.id, this.firstName, this.lastName, {required this.teamID, required this.teamName, required this.champID,
    required this.champName, this.matricola});
}

class PlayerInfo
{
  static const String imagesFolderName = "playerImages";
  static const Duration imageRefreshPeriod = Duration(days: 30); //Duration(seconds: 10);

  static late LazyIconDownloader _iconDownloader;

  static void initIconLoader() async
  {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    _iconDownloader = LazyIconDownloader(imagesFolderName: imagesFolderName, imageRefreshPeriod: imageRefreshPeriod,
        debugName: "player", appDocDirectory: appDocDirectory, getImageURL: (final String id) => "$defaultEndpointURL/playerImgs/$id.png",
        placeholder: FormationsPageState.personImage);
  }

  final int playerID;
  final String? birthday;
  final String? sex;
  final String? city;
  final String? weight;
  final String? height;
  final String? role; //a, c, d, ...
  final String? age;
  final int groupID;
  final String groupName;
  final String? feet;
  final int? shirtNumber;

  Widget get icon => _iconDownloader.getIcon(playerID.toString(), placeholderOnFail: false);

  static Widget getPlayerIcon(final int id)
  {
    return _iconDownloader.getIcon(id.toString(), placeholderOnFail: true);
  }

  const PlayerInfo(this.playerID, {required this.birthday, required this.age, required this.sex, required this.city,
  required this.weight, required this.height, required this.role, required this.groupID,
    required this.groupName, this.feet, this.shirtNumber});
}

class PlayerStats
{
  final int goals;
  final int attendancesHolder;
  final int attendancesReserve;
  final int monitions;
  final int evictions;
  final int minutes;
  const PlayerStats({required this.goals, required this.monitions, required this.evictions, required this.minutes, required this.attendancesHolder, required this.attendancesReserve});
}

class Player //Used in team page
{
  final int id;
  final String firstName;
  final String lastName;
  final int? age;
  final int? height;
  final String? role;
  final int? monitions;
  final int? evictions;
  final int? shirtNumber;

  const Player(this.id, this.firstName, this.lastName, {this.age, this.height, this.role, this.monitions, this.evictions, this.shirtNumber});

  static List<Player> listFromJson(final Map<String, dynamic> json)
  {
    final List<Map<String, dynamic>> playersJson = List.from(json["players"]);

    List<Player> ret = playersJson.map((e) => _fromJson(e)).whereType<Player>().toList();
    return ret;
  }

  static Player? _fromJson(final Map<String, dynamic> json)
  {
    try {
      return Player(
        int.parse(json["playerID"].toString()),
        json["firstName"],
        json["lastName"],
        age: int.tryParse((json["age"] ?? "-").toString()),
        height: int.tryParse((json["height"] ?? "-").toString()),
        role: json["role"],
        monitions: int.tryParse((json["monitions"] ?? "-").toString()),
        evictions: int.tryParse((json["evictions"] ?? "-").toString()),
        shirtNumber: int.tryParse((json["shirtNumber"] ?? "-").toString())
      );
    }
    on Exception catch (e)
    {
      return null;
    }
  }
}

class Staffer {
  final int id;
  final String firstName;
  final String lastName;

  const Staffer(this.id, this.firstName, this.lastName);

  static Staffer? _fromJson(final Map<String, dynamic> json)
  {
    try {
      return Staffer(
          int.parse((json["id"] ?? "").toString()),
          json["firstName"],
          json["lastName"],
      );
    }
    on Exception catch (e)
    {
      return null;
    }
  }

  static List<Staffer> listFromJson(final Map<String, dynamic> json, final String jsonKey)
  {
    final List<Map<String, dynamic>> playersJson = List.from(json[jsonKey]);

    List<Staffer> ret = playersJson.map((e) => _fromJson(e)).whereType<Staffer>().toList();
    return ret;
  }
}

class Scorer
{
  final int id;
  final String firstName;
  final String lastName;
  final int goals;
  final int autoGoals;
  final int penalties;
  final int? assists;
  final int? shirtNumber;

  const Scorer(this.id, this.firstName, this.lastName, this.goals, this.autoGoals, this.penalties, this.assists, this.shirtNumber);

  static Scorer? _fromJson(final Map<String, dynamic> json)
  {
    try {
      return Scorer(
        int.parse(json["playerID"].toString()),
        json["firstName"],
        json["lastName"],
        int.parse(json["goals"].toString()),
        int.parse(json["autogoals"].toString()),
        int.parse(json["penalties"].toString()),
        int.tryParse((json["assists"] ?? "").toString()),
        int.tryParse((json["shirtNumber"] ?? "").toString())
      );
    }
    on Exception catch (e)
    {
      return null;
    }
  }

  static List<Scorer> listFromJson(final Map<String, dynamic> json)
  {
    final List<Map<String, dynamic>> playersJson = List.from(json["players"]);

    List<Scorer> ret = playersJson.map((e) => _fromJson(e)).whereType<Scorer>().toList();
    return ret;
  }
}