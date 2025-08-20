// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';

import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/image_loader.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/pair.dart';
import 'package:path_provider/path_provider.dart';

class Group
{
  final String champName;
  final int champID;
  final int id;
  final String name;
  final String committee;
  final int committeeID;
  final String season;
  final String category;

  const Group({required this.champName, required this.champID, required this.id, required this.committee, required this.season,
    required this.name, required this.category, required this.committeeID});
}

class Championship
{
  static late LazyIconDownloader _iconDownloader;

  static const String imagesFolderName = "champImages";
  static const Duration imageRefreshPeriod = Duration(days: 32); //Duration(seconds: 10);

  static void initIconDownloader() async
  {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    _iconDownloader = LazyIconDownloader(imagesFolderName: imagesFolderName, imageRefreshPeriod: imageRefreshPeriod,
        debugName: "championship", appDocDirectory: appDocDirectory,
        getImageURL: (final String seasonChampID) {
          return !ImageLoader.removeLogos() ? "$defaultEndpointURL/champImgs/$seasonChampID.png" : "";
        },
        placeholder: ImageLoader.instance().getImage("championshipGeneric")
        ); //ES: 2023-2024/39184
  }

  late final String name;
  late final int id;
  List<Pair<int,String>> _groups = []; //Gironi, id -> name
  List<Pair<int,String>> get groups {
    return List.from(_groups);
  }

  Championship(this.name, this.id);

  Widget getIcon(final String season, {bool placeholderOnFail = false}) {
    return _iconDownloader.getIcon("$season-$id", placeholderOnFail: placeholderOnFail);
  }

  Championship.fromJson(Map<String, dynamic> map)
  {
    /*
  json:
  {name: "Name", id: "1234" groups: [{id: "12", name:"A"},{id: "13", name:"B"}]}
   */
    name = map["name"];
    id = map["id"] is int ? map["id"] : int.parse(map["id"]);
    List<Map<String, dynamic>> groups = List.from(map["groups"]); //id, name

    List<Pair<int,String>> newGroups = [];
    for (Map<String, dynamic> group in groups)
    {
      String? name = group["name"];
      int? id = null;
      if (group["id"] != null)
        id = (group["id"] is int) ? group["id"] : int.tryParse(group["id"] ?? "");
      if (name == null || id == null)
        continue;

      newGroups.add(Pair(id, name));
    }

    _groups = newGroups;
  }

  static List<Championship> getChampionshipList(final Map<String, dynamic> json)
  {
    /* json: {
    championships: [Championship1, Championship2, ...]
  } */
    List<Map<String,dynamic>> lists = List.from(json["championships"]);
    return lists.map((e) => Championship.fromJson(e)).toList();
  }
}
