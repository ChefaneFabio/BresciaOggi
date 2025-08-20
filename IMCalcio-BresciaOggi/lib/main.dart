import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imcalcio/classes/championship.dart';
import 'package:imcalcio/classes/coach.dart';
import 'package:imcalcio/classes/image_loader.dart';
import 'package:imcalcio/django_auth.dart';
import 'package:imcalcio/classes/player.dart';
import 'package:imcalcio/classes/region.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/results_category_page.dart';
import 'package:imcalcio/classes/api_auth.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  initializeDateFormatting("it","");
  Region.initRegions();
  ImageLoader.loadImages();
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  Team.initIconLoader();
  Championship.initIconDownloader();
  PlayerInfo.initIconLoader();
  Coach.initIconDownloader();
  Manager.initIconDownloader();

  //MobileAds.instance.initialize();

  //AdsManagerState.setupConsent();

  ApiAuth.getInstance().auth();

  DjangoAuth.instance.startupAuthentication();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SportBrescia",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent, background: Colors.transparent),
        fontFamily: "Comfortaa",
        appBarTheme: const AppBarTheme(
          color: Colors.lightBlueAccent,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: "Comfortaa", fontSize: 20, color: Colors.black),
          shadowColor: Colors.blueAccent,
          elevation: 10
        ),
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        //primarySwatch: Colors.blue,
        //primaryColor: Colors.blue,
        secondaryHeaderColor: Colors.blueGrey,
        canvasColor: const Color.fromARGB(255, 167, 191, 225), //A7BFE1
        scaffoldBackgroundColor: Colors.transparent,
        ),
      home: const ResultsCategoryPage()
    );
  }
}
