// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';

import 'package:flutter/Material.dart';
import 'package:http/http.dart' as http;
import 'package:imcalcio/classes/api_auth.dart';


const String emulatorEndpointURL = "http://10.0.2.2:8000";
const String deviceEndpointURL = "http://127.0.0.1:8000";

const String defaultEndpointURL = emulatorEndpointURL;
const String remoteAPIURL = "https://calcioevai.it/api/v1";

const bool useRemoteAPI = true;

///
/// Interface for pages that download content.
/// The pages need to override downloadFromDB, async function that returns true or false
/// whether the download and parsing was successful or not.
/// Then, getEntirePage can be used as Scaffold body to display the content of the page:
/// it will be displayed downloadOK(), downloadFailed() or downloading() based on the download status.
/// getEntireRefreshablePage is a special version of getEntirePage that includes a RefreshIndicator that downloads the page again.
/// pageDownloaderInit() needs to be called in initState.
///
enum DownloadStatus {ok, error500, genericError}

mixin PageDownloaderMixin<T extends StatefulWidget> on State<T> {

  late Future<DownloadStatus> downloadFuture;

  Future<DownloadStatus> downloadFromDB() async
  {
    debugPrint("DownloadFromDB: $downloadUrl");
    http.Response response;
    int tries = 0;
    while (true) {
      tries++; //Riprova
      try {
        if (downloadUrl.contains("calcioevai")) {
          if (!ApiAuth.getInstance().getAuthStatus())
            await ApiAuth.getInstance().auth();
        }

        response = await http.get(Uri.parse(downloadUrl),
            headers: {
              "Connection": "keep-alive",
              "Authorization": "Bearer ${ApiAuth.getInstance().getToken()}",
              "FromMobileApp": "1"
            }
        )
            .timeout(const Duration(seconds: 5));
      } on Exception catch (e, s) {
        debugPrint("Download error: $e, $s");
        await Future.delayed(const Duration(seconds: 1));
        if (tries >= downloadTries)
          return DownloadStatus.genericError;
        else
          continue;
      }

      debugPrint("Response from DB length: ${response.body.length}");
      if (response.statusCode != 200) {
        debugPrint("Downloaded statusCode = ${response.statusCode}");
        debugPrint("Downloaded error data = ${response.body}");
        if (response.statusCode == 403) {
          debugPrint("API Authentication failed: resetting it");
          ApiAuth.getInstance().resetAuthentication();
        }
        else if (response.statusCode == 500)
          return DownloadStatus.error500;
        return DownloadStatus.genericError;
      }

      if (tries >= downloadTries) break;

      if (response.headers.containsKey("content-length")) {
        int? len = int.tryParse(response.headers["content-length"]!);
        debugPrint("Real content length: $len");
        if (len != null && len == response.body.length) {
          break;
        }
        debugPrint("Download length error. Retrying $tries ...");
        await Future.delayed(const Duration(seconds: 1));
      } else
        break;
    }

    return parseDownloadedData(utf8.decode(response.bodyBytes))
        .then((bool result) => result ? DownloadStatus.ok : DownloadStatus.genericError,
          onError: (o) => DownloadStatus.genericError);
  }

  String get downloadUrl; //Unimplemented if overriding downloadFromDB
  int get downloadTries => 1; //Download tries, if > 1 checks content length every time

  Future<bool> parseDownloadedData(final String body);

  void pageDownloaderInit()
  {
    downloadFuture = downloadFromDB();
  }

  Widget downloadOK();
  Widget downloadFailed()
  {
    return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
             const Text(
              "Errore: controlla la tua connessione ad internet e riprova.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
              softWrap: true,
            ),
            const Padding(padding: EdgeInsets.all(10)),
            ElevatedButton(
              style: const ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.white)),
              onPressed: () async {
                downloadFuture = downloadFromDB();
                await downloadFuture;
                setState(() { });
              },
              child: const Text("Riprova", style: TextStyle(fontSize: 18))
            )
          ],
        ));
  }

  Widget downloadError500()
  {
    return Container(
        padding: const EdgeInsets.all(20),
        child: const Column(
          children: [
            Text(
              "I dati sono in fase di aggiornamento.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
              softWrap: true,
            )
          ],
        ));
  }

  Widget downloading()
  {
    return const Center(child: CircularProgressIndicator());
  }

  FutureBuilder getEntirePage()
  {
    return FutureBuilder<DownloadStatus>(
        future: downloadFuture,
        builder: (BuildContext context, AsyncSnapshot<DownloadStatus> snapshot) {
          if (snapshot.hasData && snapshot.data! == DownloadStatus.ok) {
            //If download OK
            return downloadOK();
          } else if (snapshot.hasData && snapshot.data! == DownloadStatus.error500) { //If status code is error 500
            return downloadError500();
          } else if (snapshot.hasData && snapshot.data! == DownloadStatus.genericError || //If another error
              snapshot.hasError) //If download error or has downloaded something wrong
            return downloadFailed();
          else //Is downloading
            return downloading();
        });
  }

  Future<void> refresh() async
  {
    if (!refreshCondition())
      return;
    downloadFuture = downloadFromDB();
    await downloadFuture;
    setState(() { });
  }

  Widget wrapIntoRefreshIndicator(Widget Function() fn)
  {
    return RefreshIndicator(
        onRefresh: refresh,
        child: fn()
    );
  }

  Widget getEntireRefreshablePage()
  {
    return RefreshIndicator(
      onRefresh: refresh,
      child: getEntirePage()
    );
  }

  /// When onRefresh, this condition is checked before actually refreshing the content.
  /// Done due to https://github.com/flutter/flutter/issues/62833
  bool refreshCondition()
  {
    return true;
  }
}

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}