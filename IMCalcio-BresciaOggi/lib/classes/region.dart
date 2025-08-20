import 'package:flutter/material.dart';

class Region //Singleton
{
  
  static final List<String> _regionNames = ["Valle d'Aosta",
  "Lombardia", "Trentino-Alto Adige/Südtirol", "Piemonte",
  "Friuli-Venezia Giulia", "Veneto", "Emilia Romagna",
  "Liguria", "Toscana", "Marche",
  "Umbria", "Lazio", "Abruzzo",
  "Molise", "Campania", "Puglia",
  "Basilicata", "Calabria", "Sicilia",
  "Sardegna"];

  final Map<String, Image> _images;
  Region._() : _images = {};

  static Region instance() {
    if (!_instantiated)
    {
      _instance = Region._();
      _instantiated = true;
    }
    return _instance;
  }
  static bool _instantiated = false;
  static late Region _instance;

  Image getImage(final String r)
  {
    //debugPrint("$r: ${_images.containsKey(r)}");
    return _images[r]!;
  }

  void addRegion_(final String r)
  {
    Image i = Image(image: AssetImage("images/regions/${r.replaceAll("/","-")}.png"));
    _images.putIfAbsent(r, () => i);
  }

  static void initRegions()
  {
    for (String r in _regionNames)
    {
      instance().addRegion_(r); 
    }
    debugPrint("Loaded ${instance()._images.length} regions.");
  }

  List<String> getList()
  {
    return List.from(_regionNames);
  }

  List<String> getSortedList()
  {
    List<String> ret = getList();
    ret.sort();
    return ret;
  }

}