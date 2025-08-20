import 'dart:io';

import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/image_loader.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:path_provider/path_provider.dart';

class SearchCoach {
  final int id;
  final String? firstName;
  final String lastName;
  final String? championship;
  final String? committee;
  final int? teamID;
  final String? teamName;
  final String? birthday;
  final String season;

  const SearchCoach(this.id, {required this.firstName, required this.lastName, required this.championship,
    required this.committee, required this.teamID, required this.teamName, required this.birthday, required this.season});
}

enum StafferType
{
  coach("Coach","dell'allenatore","getCoachInfo.php", "coaches", Coach.new),
  manager("Manager","del dirigente","getManagerInfo.php", "managers", Manager.new);

  const StafferType(this.name, this.italianName, this.localWebPageName, this.newAPIWebPageName, this.buildStaffer);

  final String name;
  final String italianName;
  final String localWebPageName;
  final String newAPIWebPageName;

  final Function buildStaffer;
}

abstract class Staffer {
  final int id;
  final String? firstName;
  final String lastName;
  final String? birthday;
  final String? city;
  final int? age;

  Widget get icon;

  const Staffer(this.id, {required this.firstName, required this.lastName, required this.birthday, required this.city, required this.age});
}

class Coach extends Staffer {
  const Coach(super.id, {required super.firstName, required super.lastName, required super.birthday, required super.city, required super.age});

  static late LazyIconDownloader _iconDownloader;

  static const String imagesFolderName = "coachImages";
  static const Duration imageRefreshPeriod = Duration(days: 34); //Duration(seconds: 10);

  static void initIconDownloader() async
  {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    _iconDownloader = LazyIconDownloader(imagesFolderName: imagesFolderName, imageRefreshPeriod: imageRefreshPeriod,
        debugName: "coach", appDocDirectory: appDocDirectory,
        getImageURL: (final String id) => "$defaultEndpointURL/coachImgs/$id.png");
  }

  @override
  Widget get icon => _iconDownloader.getIcon(id.toString(), placeholderOnFail: false);
}

class Manager extends Staffer {
  const Manager(super.id, {required super.firstName, required super.lastName, required super.birthday, required super.city, required super.age});

  static late LazyIconDownloader _iconDownloader;

  static const String imagesFolderName = "managerImages";
  static const Duration imageRefreshPeriod = Duration(days: 34); //Duration(seconds: 10);

  static void initIconDownloader() async
  {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    _iconDownloader = LazyIconDownloader(imagesFolderName: imagesFolderName, imageRefreshPeriod: imageRefreshPeriod,
        debugName: "manager", appDocDirectory: appDocDirectory,
        getImageURL: (final String id) => "$defaultEndpointURL/managerImgs/$id.png");
  }

  @override
  Widget get icon => _iconDownloader.getIcon(id.toString(), placeholderOnFail: false);
}