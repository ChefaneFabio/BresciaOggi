// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:imcalcio/classes/image_loader.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:path_provider/path_provider.dart';

class Team {
  static const String imagesFolderName = "teamImages";
  static const Duration imageRefreshPeriod = Duration(days: 30); //Duration(seconds: 10);

  static late LazyIconDownloader _iconDownloader;

  static void initIconLoader() async
  {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    _iconDownloader = LazyIconDownloader(imagesFolderName: imagesFolderName, imageRefreshPeriod: imageRefreshPeriod,
      debugName: "team", appDocDirectory: appDocDirectory, getImageURL: (final String id) {
          return useRemoteAPI && !ImageLoader.removeLogos()
              ? "$remoteAPIURL/teams/$id/logo/" //"https://calcioevai.it/media/i/teams/logos/$id.png"
              : "$defaultEndpointURL/teamImgs/$id.png";
        }, placeholder: ImageLoader.instance().getImage("teamGeneric")
    );
  }

  late final String name;
  late final int id;

  late final int? championshipID;
  late final String? championship;
  late final String? locality;

  late final int? groupID;
  late final String? group;

  Widget get icon => _iconDownloader.getIcon(id.toString());

  //late final int? societyID;
  late final String? season;

  Team._(this.name, this.id, this.championship, this.locality, this.group, this.championshipID, this.groupID, this.season);

  static Team getTeam(final String name, {final int id = -1, final String? championship,
    final String? locality, final String? group, final int? championshipID, final int? groupID, final String? season})
  {
    return Team._(name, id, championship, locality, group, championshipID, groupID, season);
  }

}