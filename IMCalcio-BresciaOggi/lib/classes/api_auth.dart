import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/Material.dart';

class ApiAuth
{
  static late ApiAuth _instance;
  static bool _hasInstance = false;

  ApiAuth._() :_dio = Dio();

  static ApiAuth getInstance()
  {
    if (!_hasInstance)
    {
      _hasInstance = true;
      _instance = ApiAuth._();
    }

    return _instance;
  }

  String _token = "";
  String getToken() => _token;
  bool _authStatus = false;

  bool getAuthStatus() => _authStatus;

  final Dio _dio;
  static const String _name = "MobileApp";//"calcio";
  static const String _key = "MobileApp"; //"ZBPfMVYpJgJb464";

  Future<void> auth() async
  {
    final Map<String, String> data = {"username":_name, "password": _key};
    final Response r = await _dio.post("https://calcioevai.it/api-token-auth/", data: data, options: Options(
      responseType: ResponseType.plain
    ));

    debugPrint("Status: ${r.statusCode}");

    try {
      final String body = r.data.toString();
      debugPrint("Data: $body");

      Map<String, dynamic> json = jsonDecode(body);
      _token = json["token"];
      debugPrint("Token obtained: $_token");
      _authStatus = true;
    } on Exception catch(e, s)
    {
      _authStatus = false;
      debugPrint("Error API authentication: $e\n$s");
      return;
    }
  }

  void resetAuthentication() => _authStatus = false;
}