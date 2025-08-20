// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:flutter/Material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' hide Options;
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:url_launcher/url_launcher.dart';

enum HTTPRequestMethod {
  get(getRequest),
  post(postRequest),
  delete(deleteRequest),
  patch(patchRequest);

  final Future<Response<T>> Function<T>(String, FormData, Options) req;

  const HTTPRequestMethod(this.req);

  static Future<Response<T>> postRequest<T>(String url, FormData f, Options o) async => await DjangoAuth.instance.dio.post(url, data: f, options: o);
  static Future<Response<T>> getRequest<T>(String url, FormData f, Options o) async => await DjangoAuth.instance.dio.get(url, data: f, options: o);
  static Future<Response<T>> deleteRequest<T>(String url, FormData f, Options o) async => await DjangoAuth.instance.dio.delete(url, data: f, options: o);
  static Future<Response<T>> patchRequest<T>(String url, FormData f, Options o) async => await DjangoAuth.instance.dio.patch(url, data: f, options: o);
}

class DjangoAuth { //Singleton

  final Dio dio = Dio();
  static DjangoAuth? _instance;

  static DjangoAuth get instance {
    _instance ??= DjangoAuth._();

    return _instance!;
  }

  DjangoAuth._() : _secureStorage = const FlutterSecureStorage();

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  String? _user;
  String? get user => _user;

  String? _token;

  List<int> _champsCanEdit = []; //Champs where the user is allowed to edit (upload distinte, edit result)
  List<int> get champsCanEdit => List.from(_champsCanEdit);
  bool _userIsAdmin = false; //If true, the user is allowed to edit every champ
  bool get userIsAdmin => _userIsAdmin;

  FlutterSecureStorage _secureStorage; //Initialized in the startupAuthentication method

  static const String userKey = "calcioevai_username";
  static const String passwordKey = "calcioevai_password";

  Future<bool?> displayAuthenticationDialog(final BuildContext context, {bool closeOnAuthentication = false})
  {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return DjangoAuthPage(closeOnAuthentication: closeOnAuthentication);
      },
    );
  }

  Future<bool> performAuthentication(final String name, final String password) async
  {
    //ZBPfMVYpJgJb464

    try {
      //Send name, password and csrf token
      const String loginUrl = "https://calcioevai.it/api-token-auth/";
      final Response loginResponse = await dio.post(loginUrl,
        options: Options(
            followRedirects: false,
            validateStatus: (status) => status == 200 || status == 302,
            responseType: ResponseType.plain
        ),
        data: FormData.fromMap({"username": name, "password": password})
      );

      debugPrint("Logged in: ${loginResponse.data.toString()}");
      //{token: "558665a865669343dd56836fdd65afba9a765601"}

      final Map<String, dynamic> tokenJson = jsonDecode(loginResponse.data.toString());
      if (!tokenJson.containsKey("token"))
        throw Exception("Error: response does not contain token.");

      _token = tokenJson["token"];

      _user = name;

      bool permissions = await fetchUserPermissions();

      _authenticated = permissions;
      if (_authenticated)
      {
        _secureStorage.write(key: userKey, value: name);
        _secureStorage.write(key: passwordKey, value: password);
      }
      return permissions;
    } catch (e,f)
    {
      debugPrint("Django auth error $e\n$f");
      _authenticated = false;
      return false;
    }
  }

  Future<bool> fetchUserPermissions() async //Returns the status of the http request
  {
    const String url = "$remoteAPIURL/matches/photos/permissions";
    String? data = await performRequest(HTTPRequestMethod.get, url, {});
    if (data == null)
      return false;

    debugPrint(data);

    //{"userType":"admin","allowedChamps":["*"]}
    try {
      Map<String, dynamic> json = jsonDecode(data);
      bool userIsAdmin = json["userType"] == "admin";
      if (!userIsAdmin)
      {
        List<int> allowedChamps = List.from(json["allowedChamps"]);
        _champsCanEdit = allowedChamps;
      }
      _userIsAdmin = userIsAdmin;
      return true;
    }
    on Exception catch (f, e)
    {
      debugPrint("FetchUserPermissions error: $data - $f - $e");
      return false;
    }
  }

  void logout()
  {
    _authenticated = false;
    _token = null;
    _secureStorage.delete(key: userKey);
    _secureStorage.delete(key: passwordKey);
  }

  //Perform a POST request to the url with the provided data. Uses also the cookies of authentication
  Future<bool> performRequestValidator(final HTTPRequestMethod method, final String url, final Map<String, dynamic> data, bool Function(String) dataValidator, {Map<String, String>? additionalHeaders}) async
  {
    String? resp = await performRequest(method, url, data, additionalHeaders: additionalHeaders);

    if (resp == null)
      return false;

    return dataValidator(resp);
  }

  Future<String?> performRequest(final HTTPRequestMethod method, final String url, final Map<String, dynamic> data, {Map<String, String>? additionalHeaders}) async
  {
    return performGenericRequest<String>(method, url, data, additionalHeaders: additionalHeaders);
  }

  Future<T?> performGenericRequest<T>(final HTTPRequestMethod method, final String url, final Map<String, dynamic> data, {Map<String, String>? additionalHeaders, ResponseType? responseType}) async
  {
    Map<String, String> headers = {
      "Connection": "keep-alive",
      "Authorization": "Bearer $_token",
    };

    if (additionalHeaders != null)
      headers.addAll(additionalHeaders);

    debugPrint(_token);
    Response<T>? r;
    try {
      r = await method.req(url, FormData.fromMap(data), Options(
          headers: headers, validateStatus: (s) => true, responseType: responseType));
      //debugPrint(r.data.toString());
    } catch (e,f)
    {
      debugPrint("Error: $e, $f");

      return null;
    }

    return r.data;
  }

  Future<bool> ensureDjangoAuthentication(final BuildContext context) async //Authenticate and ensure authentication
  {
    if (!DjangoAuth.instance.authenticated)
      await DjangoAuth.instance.displayAuthenticationDialog(context, closeOnAuthentication: true);

    if (!DjangoAuth.instance.authenticated)
      return false;

    return true;
  }

  Future<void> startupAuthentication() async //Authenticate at startup
  {
    //Two keys, calcioevai_username and calcioevai_password
    String? username = await _secureStorage.read(key: userKey);
    String? password = await _secureStorage.read(key: passwordKey);

    if (username == null || password == null) {
      debugPrint("Cannot perform automatic authentication, missing username or password");
      return;
    }

    await performAuthentication(username, password);
  }
}

class DjangoAuthPage extends StatefulWidget {
  const DjangoAuthPage({super.key, required this.closeOnAuthentication});

  final bool closeOnAuthentication;

  @override
  State<DjangoAuthPage> createState() => _DjangoAuthPageState();
}

class _DjangoAuthPageState extends State<DjangoAuthPage> {

  static const double titleSize = 20.0;
  static const double optionsSize = 18.0;
  TextEditingController userController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  //TextEditingController OTPController = TextEditingController(); Deprecated: OTP is no longer required

  bool performingAuthentication = false; //For circularProgressIndicator
  bool showError = false;

  Future<bool> performAuthentication()
  {
    return Future.delayed(const Duration(seconds: 4), () => true);
  }

  Widget getAuthenticationPage() //Not authenticated
  {
    final double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth,
      child: AlertDialog(
        backgroundColor: Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Rounded corners for the dialog
        ),
        title: const Text(
          "Autenticazione membri riservati SportBrescia",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueAccent, fontSize: titleSize),
        ),
        content: SingleChildScrollView( // Ensures the dialog is scrollable
          child: ListBody(
            children: [
              TextField(
                readOnly: performingAuthentication,
                controller: userController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16), // Space between text fields
              TextField(
                readOnly: performingAuthentication,
                controller: passwordController,
                obscureText: true, // Hides password text
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
             /* const SizedBox(height: 16), // Space between text fields
              TextField(
                readOnly: performingAuthentication,
                controller: OTPController,
                decoration: const InputDecoration(
                  labelText: "OTP Token",
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
              ),*/ //Deprecated: OTP is no longer required
              if (showError) const Padding(
                padding: EdgeInsets.all(4.0),
                child: Text("Autenticazione fallita.", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
              ),
              const Padding(padding: EdgeInsets.only(top: 8.0)),
              RichText(textAlign: TextAlign.center,
                text: TextSpan(text: "Clicca qui ", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color.fromARGB(255, 0, 0, 200), fontFamily: "Comfortaa"),
                    recognizer: TapGestureRecognizer()..onTap = () {
                      launchUrl(Uri.parse("mailto:calcioevai@gmail.com"));
                    },
                    children: const [
                    TextSpan(text: "e richiedi l'accesso per aggiungere croncaca e foto delle partite!",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                ]
              ))
            ]
          ),
        ),
        actions: <Widget>[
          if (performingAuthentication) const CircularProgressIndicator(),
          TextButton(
            onPressed: performingAuthentication ? null : () {
              Navigator.of(context).pop(false); // Dismisses the dialog and returns false
            },
            child: const Text("Annulla", style: TextStyle(fontSize: optionsSize, color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: performingAuthentication ? null : () async {
              setState(() {
                performingAuthentication = true;
              });
              bool ok = await DjangoAuth.instance.performAuthentication(userController.text, passwordController.text);
              setState(() {
                showError = !ok;
                performingAuthentication = false;
                if (ok && widget.closeOnAuthentication)
                  Navigator.of(context).pop();
              });
            },
            child: const Text("Accedi", style: TextStyle(fontSize: optionsSize)),
          ),
        ],
      ),
    );
  }

  Widget getAuthenticatedPage() //Authenticated
  {
    final double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth,
      child: AlertDialog(
        backgroundColor: Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Rounded corners for the dialog
        ),
        title: const Text(
          "Autenticazione membri riservati SportBrescia",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueAccent, fontSize: titleSize),
        ),
        content: SingleChildScrollView( // Ensures the dialog is scrollable
          child: ListBody(
            children: [
              RichText(textAlign: TextAlign.center,
                  text: TextSpan(text: "Autenticato come: ", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black),
                    children: [TextSpan(text: DjangoAuth.instance.user!, style: const TextStyle(fontSize: 22, color: Colors.black))]
              ))
            ],
          ),
        ),
        actions: <Widget>[
          if (performingAuthentication) const CircularProgressIndicator(),
          TextButton(
            onPressed: performingAuthentication ? null : () {
              setState(() {
                DjangoAuth.instance.logout();
              }); // Dismisses the dialog and returns false
            },
            child: const Text("Logout", style: TextStyle(fontSize: optionsSize, color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: performingAuthentication ? null : () {
              Navigator.of(context).pop();
            },
            child: const Text("Chiudi", style: TextStyle(fontSize: optionsSize)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!DjangoAuth.instance.authenticated)
      return getAuthenticationPage();

    return getAuthenticatedPage();
  }
}
