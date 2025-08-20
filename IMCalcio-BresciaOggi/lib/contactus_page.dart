// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/api_auth.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:http/http.dart' as http;
import 'package:imcalcio/classes/sidebar_stuff.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

enum UserFeedbackType {
  hint("Suggerimento"),
  problem("Problema");

  const UserFeedbackType(this.italianName);

  final String italianName;
}

class _ContactUsPageState extends State<ContactUsPage> {

  late TextEditingController mailController;
  late TextEditingController messageController;
  UserFeedbackType _messageTypeSelected = UserFeedbackType.hint;
  final GlobalKey<FormState> _formKey = GlobalKey();
  String feedbackSendStatus = ""; //String representing the status of the send.

  @override
  void initState()
  {
    super.initState();
    mailController = TextEditingController();
    messageController = TextEditingController();
  }

  @override
  void dispose()
  {
    super.dispose();
    mailController.dispose();
    messageController.dispose();
  }

  void _setMessageTypeSelected(final UserFeedbackType? value)
  {
    setState(() {
      if (value != null)
        _messageTypeSelected = value;
    });
  }

  Widget _getFeedbackWidget()
  {
    return Card(
      elevation: 4.0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text("Invia un messaggio alla redazione", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500), textAlign: TextAlign.center,),
            const Padding(padding: EdgeInsets.only(top: 4.0)),
            Container(
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2.0
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(6.0))
              ),
              child: Column(
                children: [
                  const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text("Tipo di messaggio:", style: TextStyle(fontWeight: FontWeight.w600))),
                  ...UserFeedbackType.values.map((e) =>
                      RadioListTile<UserFeedbackType>(value: e, groupValue: _messageTypeSelected,
                        title: Text(e.italianName, style: const TextStyle(fontSize: 17)),
                        onChanged: _setMessageTypeSelected,
                        dense: true,
                      ))
                ],
              ),
            ),
            Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                      child: TextFormField(
                        decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(left: 8.0, right: 8.0),
                            labelText: "Mail",
                            hintText: "La mail per ricevere una risposta.",
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    width: 2
                                )
                            )
                        ),
                        maxLines: 1,
                        keyboardType: TextInputType.emailAddress,
                        controller: mailController,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Inserisci un indirizzo mail valido";
                          //Regular expression for email validation
                          const String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                          RegExp regex = RegExp(pattern);
                          if (!regex.hasMatch(value))
                            return "Inserisci un indirizzo mail valido";
                          return null; // Return null if the input is valid
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0, left: 12.0, right: 12.0),
                      child: TextFormField(
                        decoration: const InputDecoration(
                            labelText: "Messaggio",
                            hintText: "Il messaggio da inviare alla redazione.",
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    width: 2
                                )
                            )
                        ),
                        controller: messageController,
                        validator: (value) {
                          if (value == null || value.length < 10)
                            return "Inserisci un messaggio lungo almeno 10 caratteri.";
                          return null; // Return null if the input is valid
                        },
                        minLines: 2,
                        maxLines: 4,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * .4,
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            feedbackSendStatus = "";
                          });
                          if (_formKey.currentState?.validate() ?? false)
                            _sendFeedbackMessage(_messageTypeSelected, mailController.text, messageController.text);
                        },
                        child: const Text("Invia", style: TextStyle(fontSize: 18)),
                      ),
                    )
                  ],
                )
            ),
            if (feedbackSendStatus != "") Text(feedbackSendStatus, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blue, fontSize: 17))
          ],
        ),
      ),
    );
  }

  void _sendFeedbackMessage(final UserFeedbackType hintType, final String mail, final String message) async
  {
    const String url = useRemoteAPI ? "$remoteAPIURL/feedback/" : "$defaultEndpointURL/sendFeedback.php";

    final Map<String, String> data = {
      "type" : hintType.italianName,
      "email" : mail,
      "mail" : mail,
      "message" : message
    };

    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    NavigatorState navigator = Navigator.of(context);
    ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);

    String snackBarText;
    try {
      http.Response r = await http.post(Uri.parse(url), body: data,
          headers: {
            "Connection": "keep-alive",
            "Authorization": "Bearer ${ApiAuth.getInstance().getToken()}",
            "FromMobileApp" : "1"
          }).timeout(const Duration(seconds: 5),
          onTimeout: () => http.Response("Timeout", 408));

      if (r.statusCode != 201)
        throw Exception("Error: statusCode = ${r.statusCode}\nBody:${r.body}");

      if (r.body.contains("success"))
        snackBarText = "Messaggio inviato con successo.";
      else
        snackBarText = "Errore: riprova più tardi.";

    } catch (e, f)
    {

      debugPrint("$e\n$f");
      snackBarText = "Errore. Riprova più tardi.";
    }

    navigator.pop();
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(snackBarText)));
    setState(() {
      feedbackSendStatus = snackBarText;
    });
  }

  Widget _getBody()
  {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _getFeedbackWidget(),
            const Padding(padding: EdgeInsets.only(top: 8.0)),
            _sendMailWidget()
          ],
        ),
      ),
    );
  }

  Widget _sendMailWidget()
  {
    const String emailAddress = "calcioevai@gmail.com";
    return Column(
      children: [
        const Text("Oppure manda una mail a:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        GestureDetector(
          onTap: (){
            final Uri url = Uri(
              scheme: "mailto",
              path: emailAddress,
              query: "subject=Segnalazione Calcioevai&body=",
            );
            ScaffoldWithSidebar.openURL(url.toString());
          },
          child: const Text(emailAddress,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color.fromARGB(255, 0, 0, 200)))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      displayBannerAd: false,
      child: Scaffold(
        appBar: const MyAppBar(title: Text("Contattaci"), centerTitle: true),
        body: _getBody(),
      ),
    );
  }
}
