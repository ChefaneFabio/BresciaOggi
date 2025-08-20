 // ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:imcalcio/classes/api_auth.dart';

//Singleton
class ImageLoader
{
  static bool removeLogos() //Whether the proprietary logos must not be shown (placeholder instead)
  {
    //return Platform.isIOS;
    return false; //Allow proprietary logos on any platform
  }

  static late ImageLoader _instance;
  static bool init = false;

  static ImageLoader instance() {
    if (!init) {
        init = true;
        _instance = ImageLoader._();
    }
    return _instance;
  }

  Image getImage(String key, {String? placeholder})
  {
    if (!_images.containsKey(key.toLowerCase()))
      return placeholder == null ? this.placeholder : _images[placeholder.toLowerCase()]!;
    return _images[key.toLowerCase()]!;
  }

  final Map<String, String> _image2FileNames = { //NOTE: the comitati are removed if removeLogos() in loadImages().
    "comitati/Divisione Nazionale Calcio A 5" : "images/categories/Divisione Nazionale Calcio a 5 Modificato.png" ,
    "comitati/Calcio a 5" : "images/categories/Divisione Nazionale Calcio a 5 Modificato.png" ,
    "comitati/Dipartimento Calcio Femminile" : "images/categories/Dipartimento Calcio Femminile.png" ,
    "comitati/Calcio Femminile" : "images/categories/Dipartimento Calcio Femminile.png" ,
    "comitati/Lega Nazionale Dilettanti" : "images/categories/Lega Nazionale Dilettanti.png" ,
    "comitati/Lega Nazionale Professionisti" : "images/categories/Lega Nazionale Professionisti.png" ,
    "comitati/Lega Pro" : "images/categories/Lega Pro.png" ,
    "comitati/Settore Giovanile Scolastico" : "images/categories/Settore Giovanile Scolastico.png" ,
    "comitati/Estero" : "images/categories/Logo Uefa.png" ,
    "ItaliaMediaLogo" : "images/Logo.png",
    "CalcioEVaiLogo" : "images/Logo.png",
    "background" : "images/background.png",
    "background2" : "images/background2.png",
    "committeeGeneric" : "images/placeholderComitato.png",
    "championshipGeneric" : "images/placeholderCampionato.png",
    "teamGeneric" : "images/placeholderTeam.png"
    //TODO INSERT IMAGES HERE
  };

  final Image placeholder;
  final Map<String, Image> _images = {};

  ImageLoader._()
  : placeholder = Image.asset("images/placeholder.png")
  {
    for (MapEntry<String,String> image2File in _image2FileNames.entries)
    {
        if (_images.containsKey(image2File.key.toLowerCase()))
        {
          debugPrint("[ImageLoader] WARNING: key ${image2File.key.toLowerCase()} is duplicate!");
          continue;
        }

        Image i = Image.asset(image2File.value);
        _images.putIfAbsent(image2File.key.toLowerCase(), () => i);
    }
    debugPrint("Loaded ${_images.length} images.");
  }

  static void loadImages()
  {
    instance(); //Load images

    if (removeLogos()) //Due to copyright reasons e.g. first iOS version
    {
        instance()._images.removeWhere((String key, Image value) => key.startsWith("comitati"));
        instance()._image2FileNames.removeWhere((String key, String value) => key.startsWith("comitati"));
    }
  }
}

class LazyIconDownloader {
  final String imagesFolderName;
  final Duration imageRefreshPeriod;
  final String Function(String) getImageURL;
  final String debugName;
  late final String imagesFolderCompleteDirectory;

  Widget placeholder;

  LazyIconDownloader({required this.imagesFolderName, required this.imageRefreshPeriod,
    required this.debugName, required Directory appDocDirectory, required this.getImageURL, Widget? placeholder})
    : placeholder = placeholder ?? ImageLoader.instance().placeholder
  {
    imagesFolderCompleteDirectory = "${appDocDirectory.path}/$imagesFolderName";
    Directory directory = Directory(imagesFolderCompleteDirectory);
    if (!directory.existsSync())
      directory.createSync();

    //debugPrint("Champs imgs dir: ${directory}");
  }

  static final Map<String, Image> _loadedIcons = {}; //ID -> Image

  static final Map<String, Future<http.Response>> _downloads = {}; //ID -> Currently downloading

  Future<bool> _loadImage(final String id) async
  {
    if (_loadedIcons.containsKey(id))
      return true; //Image has already been loaded

    //Check if exists the file
    File imageFile = File("$imagesFolderCompleteDirectory/$id.png");
    if (imageFile.existsSync())
    {
      DateTime lastModified = imageFile.lastModifiedSync();
      if (DateTime.now().difference(lastModified) < imageRefreshPeriod) { //If the file is relatively new
        Image image = Image.file(imageFile);
        _loadedIcons[id] = image;
        return true;
      }
      else
        imageFile.deleteSync(); //The file is too old. Re download it from the internet.
    }

    //Download it from the web.
    try {
      Future<http.Response> imageResFuture;
      bool originalDownloader;//Whether this function is downloading the image or it's waiting another image to be downloaded (if there are two same images in the same page)
      if (_downloads.containsKey(id)) {
        //debugPrint("Key of $id present.");
        imageResFuture = _downloads[id]!;
        originalDownloader = false;
      }
      else {
        //debugPrint("Downloading ${getImageURL(id)}");
        imageResFuture = http.get(Uri.parse(getImageURL(id)), headers: {
          "Connection": "keep-alive",
          "Authorization": "Bearer ${ApiAuth.getInstance().getToken()}",
          "FromMobileApp": "1"
        });
        _downloads[id] = imageResFuture;
        originalDownloader = true;
      }


      http.Response imageRes = await imageResFuture;

      if (imageRes.statusCode != 200) {
        //debugPrint("Response of ${getImageURL(id)}: ${imageRes.statusCode}");
        return false;
      }
      if (originalDownloader) //To not repeat the image saving two times.
      {
        imageFile.writeAsBytesSync(imageRes.bodyBytes, mode: FileMode.write);
        debugPrint("Downloaded $debugName image $id.png. Length = ${imageRes.bodyBytes.length}");
        Image image = Image.file(imageFile);
        _loadedIcons[id] = image;
      }
      return true;
    } catch (e)
    {
      debugPrint("Error while downloading image of $debugName $id: $e");
      return false;
    }
    finally
    {
      _downloads.remove(id);
    }
  }

  Widget getIcon(final String id, {bool placeholderOnFail = true}) {
    //PlaceholderOnFail true means that if there is no icon for the object, it will be returned a placeholder Image, otherwise a Container.
    if (_loadedIcons.containsKey(id))
      return _loadedIcons[id]!;

    //Return the FutureBuilder
    return FutureBuilder<bool>(
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData || snapshot.hasError)
          return placeholderOnFail ? placeholder : const SizedBox(width: 0, height: 0);

        bool imageRetrieved = snapshot.data!;
        return imageRetrieved ? _loadedIcons[id]! : (placeholderOnFail ? placeholder : const SizedBox(width: 0, height: 0));
      },
      future: _loadImage(id),
    );
  }
}
