// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/Material.dart';
import 'package:flutter/services.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/match.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/pair.dart';
import 'package:imcalcio/django_auth.dart';
import 'package:dio/dio.dart';

class AddMatchPhotoPage extends StatefulWidget {
  const AddMatchPhotoPage(this.match, {super.key});

  final Match match;

  @override
  State<AddMatchPhotoPage> createState() => _AddMatchPhotoPageState();
}

class _AddMatchPhotoPageState extends State<AddMatchPhotoPage> {

  late String currentMatchImgsPath;

  Future<bool> _loadUploadedImages() async
  {
    //Download the IDs of the uploaded images
    final String url = "$remoteAPIURL/matches/photos/?match_id=${widget.match.id}";
    //Response: {"count":1,"next":null,"previous":null,"results":[{"id":4,"matchID":3394518,"authorID":2,"image":"https://calcioevai.it/media/i/matches/photos/distinta.jpg"}]}
    //debugPrint("Requesting URL: $url");
    String? response = await DjangoAuth.instance.performRequest(HTTPRequestMethod.get, url, {});

    if (response == null)
      return false;
    debugPrint("loadUploadedImages response: $response");
    List<int> imageIDs = [];
    try {
      Map<String, dynamic> json = jsonDecode(response);
      List<Map<String, dynamic>> results = List.from(json["results"]);
      for (Map<String, dynamic> result in results) {
        final int resultID = result["id"];
        imageIDs.add(resultID);
      }
      _imagesFuture = imageIDs.map((e) => _downloadImage(e)).toList();
    }
    on Exception catch (e,f)
    {
      debugPrint("$e - $f");
      return false;
    }

    return true;
  }

  Future<Pair<int, Image?>> _downloadImage(final int id) async
  {
    //Download the image.
    debugPrint("Downloading distinta image $id");
    try {
      final String url = "$remoteAPIURL/matches/photos/$id/download";
      Uint8List? bytes = await DjangoAuth.instance.performGenericRequest<Uint8List>(HTTPRequestMethod.get, url, {}, responseType: ResponseType.bytes);
      Image i = Image.memory(bytes!);
      debugPrint("Distinta $id downloaded!");
      return Pair(id, i);
    }
    on Exception catch (e,f)
    {
      debugPrint("$e - $f");
      return Pair(id, null);
    }
  }

  final picker = ImagePicker();
  late Future<bool> _imagesIDFuture; //Future that completes when the list of images ids (and URLs) is downloaded. Used before the other future
  late List<Future<Pair<int, Image?>>> _imagesFuture; //A future for every image that needs to be downloaded.

  void showPickerErrorDialog(final String reason) //Show if the user did not give permissions
  {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).canvasColor,
        title: const Text("Errore", textAlign: TextAlign.center),
        content: Text(
            "SportBrescia ha bisogno i permessi per $reason.\nVai nelle impostazioni del telefono.",
            style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
        actions: [
          TextButton(
              child: const Text("Annulla", style: TextStyle(fontSize: 16)),
              onPressed: () => Navigator.of(context).pop()
          )
        ]);
    });
  }

  Future<String?> getImageFromGallery() async {
    XFile? pickedFile;
    try {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    }
    on PlatformException catch (e,f)
    {
      showPickerErrorDialog("accedere alle foto");
      return null;
    }
    if (pickedFile == null)
      return null;

    return pickedFile.path;
  }

  Future<String?> getImageFromCamera() async {
    XFile? pickedFile;

    try {
      pickedFile = await picker.pickImage(source: ImageSource.camera);
    }
    on PlatformException catch (e,f)
    {
      showPickerErrorDialog("utilizzare la fotocamera");
      return null;
    }

    if (pickedFile == null)
      return null;

    return pickedFile.path;
  }

  @override
  void initState()
  {
    super.initState();
    _imagesIDFuture = _loadUploadedImages();
  }

  Future<void> uploadImageWithDialogs(final bool isCamera) async
  {
    BuildContext? dialogContext;

    String? imgFilePath = await (isCamera ? getImageFromCamera() : getImageFromGallery());
    if (imgFilePath == null) //User has canceled
      return;

    MultipartFile toUpload = await MultipartFile.fromFile(imgFilePath, filename: "${widget.match.id}.jpg");

    if (!mounted) return;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        dialogContext = context;
        return const Center(child: CircularProgressIndicator());
      });

    const String url = useRemoteAPI ? "$remoteAPIURL/matches/photos/upload/" : "$defaultEndpointURL/uploadMatchImage.php";

    final Map<String, dynamic> data = useRemoteAPI ? {
      "type" : "mr",
      "match" : widget.match.id.toString(),
      "image" : toUpload
    } : {
      "username" : DjangoAuth.instance.user!,
      "match_id" : widget.match.id.toString(),
      "img" : toUpload
    };

    final String? uploadResponse = await DjangoAuth.instance.performRequest(HTTPRequestMethod.post, url, data);
    bool uploadOk;
    int? uploadedImageID;
    try {
      Map<String, dynamic> json = jsonDecode(uploadResponse!);
      uploadOk = json["status"] == "success";
      //{"status":"success","data":{"id":6,"image":"/media/i/matches/photos/3394518.jpg"}}
      Map<String, dynamic> jsonData = json["data"];
      uploadedImageID = jsonData["id"];
      uploadOk = true;
    }
    catch (e,f)
    {
      debugPrint("Error: $e, $f");
      uploadOk = false;
    }

    if (dialogContext != null && Navigator.of(dialogContext!).canPop())
      Navigator.of(dialogContext!).pop();

    if (uploadOk) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Immagine caricata con successo.")));

      setState(() { //Reload the images list to display the newly uploaded photo
        _imagesIDFuture = _loadUploadedImages();
      });
    }
    else { //Upload failed
      if (!mounted) return;
      showDialog(context: context, builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * .5,
          child: AlertDialog(
            backgroundColor: Theme.of(context).canvasColor,
            shape: RoundedRectangleBorder( //Dialog shape
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text("Errore",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.lightBlueAccent, fontSize: 22),
            ),
            content: const SingleChildScrollView(
              child: Align(alignment: Alignment.topCenter,
                  child: Text("Impossibile caricare l'immagine, riprova.", textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.red))),
            ),
            actions: [
              TextButton(onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                  "Chiudi", style: TextStyle(fontSize: 18, color: Colors.black)),
            )
            ],
          ),
        );
      });
    }
  }

  void _deletePhotoPressed(final int distintaID) async
  {
    bool delete = false;
    AlertDialog alert = AlertDialog(
      backgroundColor: Theme.of(context).canvasColor,
      title: const Text("Conferma"),
      content: const Text("Vuoi davvero eliminare questa distinta?",  style: TextStyle(fontSize: 18)),
      actions: [
        TextButton(
          child: const Text("Annulla", style: TextStyle(fontSize: 16)),
          onPressed:  () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text("Elimina",  style: TextStyle(fontSize: 16)),
          onPressed:  () {
            delete = true;
            Navigator.of(context).pop();
          },
        ),
      ],
    );

    await showDialog(context: context, builder: (context) => alert);

    if (!mounted || !delete)
      return;

    //Actually delete the photo
    showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) {
        return const PopScope(canPop: false,
        child: Center(child: CircularProgressIndicator()));
    });

    final String url = "$remoteAPIURL/matches/photos/$distintaID/";
    String? response = await DjangoAuth.instance.performRequest(HTTPRequestMethod.delete, url, {});
    debugPrint("Delete response for url $url: $response");

    if (!mounted)
      return;
    Navigator.of(context).pop(); //Dismiss circular progress
    Navigator.of(context).pop(); //Dismiss photo

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Immagine cancellata con successo.")));
    setState(() {
      _imagesIDFuture = _loadUploadedImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: const MyAppBar(title: Text("Aggiungi foto di distinta"), centerTitle: true),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Text("Aggiungi foto di distinta alla partita\n${widget.match.team1.name} - ${widget.match.team2.name}",
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20), textAlign: TextAlign.center),
                ),
                const Padding(padding: EdgeInsets.only(top: 8.0)),
                ElevatedButton( //Camera
                  onPressed: () async {
                    await uploadImageWithDialogs(true);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined),
                      Padding(padding: EdgeInsets.only(left: 4.0)),
                      AutoSizeText("Scatta una distinta",  maxFontSize: 18, minFontSize: 10, softWrap: true)
                    ],
                  ),
                ),
                ElevatedButton( //Gallery
                  onPressed: () async {
                    await uploadImageWithDialogs(false);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo),
                      Padding(padding: EdgeInsets.only(left: 4.0)),
                      AutoSizeText("Scegli una distinta dalla galleria", maxFontSize: 18, minFontSize: 10, softWrap: true)
                    ],
                  )
                ),
                const Padding(padding: EdgeInsets.only(top: 8.0)),
                FutureBuilder(
                  future: _imagesIDFuture,
                  builder: (context, AsyncSnapshot<void> snapshot) {
                    if (snapshot.hasError)
                      return const Center(child: Text("Errore di connessione.", style: TextStyle(color: Colors.red, fontSize: 20)));
                    else if (!snapshot.hasData) //Loading
                      return const Center(child: CircularProgressIndicator());

                    if (_imagesFuture.isEmpty)
                      return const Text("Non hai ancora caricato alcuna distinta per questa partita.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500));

                    final double screenWidth = MediaQuery.of(context).size.width;

                    return Column(
                      children: [
                        const Divider(thickness: 5),
                        Text("Ci sono ${_imagesFuture.length} distinte caricate:", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: screenWidth * .3),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            children: _imagesFuture.map((e) => _getSmallImageWidget(e)
                            ).toList(),
                          ),
                        ),
                        const Divider(thickness: 5)
                      ],
                    );
                  }
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  FutureBuilder _getSmallImageWidget(Future<Pair<int, Image?>> f) //Small image in the list of the distinte
  {
    return FutureBuilder<Pair<int, Image?>>(
        future: f,
        builder: (BuildContext context, AsyncSnapshot<Pair<int, Image?>> snapshot) {
          if (snapshot.hasData && snapshot.data!.second != null) {
            return Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                    onTap: () {
                      showDialog(barrierDismissible: true, context: context, builder: (context) =>
                          Stack(
                            children: [Center(child: snapshot.data!.second),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(onPressed: () => _deletePhotoPressed(snapshot.data!.first),
                                          style: const ButtonStyle(
                                              backgroundColor: MaterialStatePropertyAll(Colors.red)
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.only(top: 16.0, bottom: 16.0, left: 4.0, right: 4.0),
                                            child: Text("Elimina foto", style: TextStyle(fontSize: 18, color: Colors.white)),
                                          )),
                                      ElevatedButton(onPressed: () => Navigator.of(context).pop(),
                                          child: const Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: Text("Chiudi", style: TextStyle(fontSize: 22)),
                                          )),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          )
                      );
                    },
                    child: snapshot.data!.second
                )
            );
          }
          else {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell( //Tap on the image with error: reload
                onTap: () {
                  if (!snapshot.hasData)
                    return;
                  setState(() {
                    _imagesFuture.remove(f);
                    _imagesFuture.add(_downloadImage(snapshot.data!.first));
                  });
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: MediaQuery.of(context).size.height * 0.3,
                  color: Colors.grey,
                  child: (snapshot.hasError || snapshot.hasData && snapshot.data!.second == null) ? const Text("Errore", style: TextStyle(color: Colors.red))
                              : Center(child: SizedBox(width: MediaQuery.of(context).size.width * 0.1,
                                  height: MediaQuery.of(context).size.width * 0.1,
                                  child: const CircularProgressIndicator()))),
              ),
            );
          }
        }
    );
  }
}
