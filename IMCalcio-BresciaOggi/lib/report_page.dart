// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/match.dart';
import 'package:imcalcio/django_auth.dart';
import 'package:imcalcio/formations_page.dart';
import 'package:imcalcio/results_match_page.dart';

class MinuteEvent {
  final int set;
  final int minute;
  final String content;

  const MinuteEvent(this.set, this.minute, this.content);
}

class ReportPage extends StatefulWidget {
  const ReportPage(this.tabIndex, {super.key, required Widget resultsMatchPage, required State matchListener, required this.refreshCondition})
      : resultsMatchPage = resultsMatchPage as ResultsMatchPage
      , matchListener = matchListener as ResultsMatchPageState;

  final ResultsMatchPage resultsMatchPage;
  final bool Function() refreshCondition;
  final ResultsMatchPageState matchListener;
  final int tabIndex;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with AutomaticKeepAliveClientMixin, PageDownloaderMixin {

  late Match match;
  String officialReport = "";

  bool _generalReport = true; //General, not day-by-day

  String? eventCommentToAdd;
  int? eventSetToAdd;
  int? eventMinuteToAdd;

  List<MinuteEvent> minuteEvents = [];

  @override
  /*String get downloadUrl => "$defaultEndpointURL/getMatchReport.php"
      "?matchID=${widget.resultsMatchPage.beginMatch.id}";*/
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/matches/${widget.resultsMatchPage.beginMatch.id}/reports"
                                         : "$defaultEndpointURL/getMatchReport.php?matchID=${widget.resultsMatchPage.beginMatch.id}";

  @override
  bool refreshCondition()
  {
    return widget.refreshCondition();
  }

  @override
  void initState() {
    super.initState();
    match = widget.resultsMatchPage.beginMatch;

   /* eventRows.add(_getMinuteReportRow(0, 20, "Cronaca minuto per minuto Cronaca minuto per minuto Cronaca minuto per minuto Cronaca minuto per minuto Cronaca minuto per minuto Cronaca minuto per minuto"));
    eventRows.add(_getMinuteReportRow(0, 25, "Ciao"));*/

    pageDownloaderInit();
    widget.matchListener.addTabRefreshCallback(this, widget.tabIndex);
  }

  @override
  Future<bool> parseDownloadedData(String body) async {
    debugPrint(
        "Downloading report of match ${widget.resultsMatchPage.beginMatch.id}");

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
      if (!json.containsKey("reports")) {
        throw Exception("Key reports does not exist.");
      }
      Map<String, dynamic> reportsJson = json["reports"];
      for (dynamic d in reportsJson.values)
      {
        officialReport = d as String;
        break;
      }

      debugPrint(json.toString());
      if (json.containsKey("minute_events"))
      {
        List<Map<String, dynamic>> minuteEventsJson = List.from(json["minute_events"]);
        minuteEvents = minuteEventsJson.map((e) => MinuteEvent(int.parse(e["set"].toString()), int.parse(e["minute"].toString()), e["content"])).toList();
      }
    } on Exception catch (d, e) {
      debugPrint("Json error: $e");
      debugPrint(d.toString());
      return false;
    }

    debugPrint(officialReport);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return getEntireRefreshablePage();
  }

  Widget _getModeSelector()
  {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: SegmentedButton<bool>(
            style: ButtonStyle(
                elevation: MaterialStateProperty.all(4),
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected))
                    return const Color.fromARGB(255, 200, 200, 200);
                  return const Color.fromARGB(255, 240, 240, 240);
                }),
                foregroundColor: MaterialStateProperty.all(Colors.black),
                visualDensity: VisualDensity.compact
            ),
            segments: const [
              ButtonSegment<bool>(
                  value: false,
                  label: Text("Cronaca generale"),
                  icon: Icon(Icons.description)
              ),
              ButtonSegment<bool>(
                  value: true,
                  label: Text("Cronaca minuto per minuto"),
                  icon: Icon(Icons.timer)
              )
            ],
            selected: {!_generalReport},
            onSelectionChanged: (Set<bool> newValue) {
              setState(() {
                _generalReport = !newValue.first;
              });
            }),
      ),
    );
  }

  @override
  Widget downloadOK() {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _getModeSelector(),
                const Padding(padding: EdgeInsets.only(top: 10)),
                _generalReport ? _getGeneralReportPage() : _getMinuteByMinuteReportPage()
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _generalReport ? null : FloatingActionButton(
          onPressed: floatingButtonPressed, child: const Icon(Icons.add)
        )

    );
  }

  void floatingButtonPressed() async
  {
    final bool authOk = await DjangoAuth.instance.ensureDjangoAuthentication(context);
    if (!authOk) return;

    bool? added = await showDialog<bool?>(context: context, builder: (BuildContext context)
    {
      return _AddReportRowDialog(reportPage: this);
    });

    if (added == null || !added)
      return;

    //Add row
    const String reportURL = useRemoteAPI ? "$remoteAPIURL/matches/reports/" : "$defaultEndpointURL/addReportMinuteEvent.php";

    String errorReason = "Riprova più tardi.";
    validator(s) {
      debugPrint("Response: $s");
      try {
        Map<String, dynamic> json = jsonDecode(s);
        errorReason = json["detail"];
        return json["status"] == "success";
      }
      catch (e)
      {
        return false;
      }
    }

    BuildContext oldContext = context;

    bool ok = await DjangoAuth.instance.performRequestValidator(HTTPRequestMethod.post, reportURL, {
      "matchID" : match.id.toString(),
      "minute" : eventMinuteToAdd.toString(),
      "set" : eventSetToAdd.toString(),
      "content" : eventCommentToAdd.toString()
    }, validator);
    
    if (!ok)
    {
      AlertDialog dialog = AlertDialog(
        title: const Text("Errore"),
        content: Text("Impossibile aggiungere l'evento: $errorReason"),
        actions: [TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Chiudi"),
        )]
      );
      showDialog(context: oldContext, builder: (BuildContext context) => dialog);
    }

    setState(() {
      refresh();
    }); //Download new history with the new row
  }

  Widget _getGeneralReportPage()
  {
    if (officialReport.isNotEmpty)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Cronaca generale", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const Padding(padding: EdgeInsets.only(top: 5)),
          Flexible(child: Text(officialReport, style: const TextStyle(fontSize: 15.5)))
        ],
      );

    return const Text("La cronaca generale di questa partita non è ancora stata inserita.", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.red));
  }

  bool _minuteReportEven = false;
  Widget _getMinuteReportRow(final int set, final int minute, final String text)
  {
    _minuteReportEven = !_minuteReportEven;
    final int t = _minuteReportEven ? 220 : 240;
    return Container(
      padding: const EdgeInsets.all(10),
      color: Color.fromARGB(255, t, t, t),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
           Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.orangeAccent),
              child: Text("$minute${getSetString(set)}", style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500))
            ),
            const Padding(padding: EdgeInsets.only(left: 8)),
            Flexible(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400))),
        ],
      )
    );
  }

  Widget _getMinuteByMinuteReportPage()
  {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(padding: EdgeInsets.only(top: 5)),
        if (minuteEvents.isNotEmpty)
          ...[const Text("Cronaca minuto per minuto", textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)), ...minuteEvents.map((e) => _getMinuteReportRow(e.set, e.minute, e.content)),]
        else
          const Text("La cronaca minuto per minuto di questa partita non è ancora stata inserita.", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.red)),
        const Padding(padding: EdgeInsets.only(top: 50))
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _AddReportRowDialog extends StatefulWidget {
  const _AddReportRowDialog({required this.reportPage});

  final _ReportPageState reportPage;

  @override
  State<_AddReportRowDialog> createState() => _AddReportRowDialogState();
}

class _AddReportRowDialogState extends State<_AddReportRowDialog> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController minuteController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  int _setSelected = 1;

  Widget _getSetSelector()
  {
    const List<String> sets = ["PT", "ST", "PS", "SS"];

    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 0.0, right: 0.0),
      child: Center(
        child: SegmentedButton<int>(
            style: ButtonStyle(
                elevation: MaterialStateProperty.all(4),
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected))
                    return const Color.fromARGB(255, 200, 200, 200);
                  return const Color.fromARGB(255, 240, 240, 240);
                }),
                foregroundColor: MaterialStateProperty.all(Colors.black),
                visualDensity: VisualDensity.comfortable
            ),
            segments: sets.map((s) => ButtonSegment<int>(
              value: sets.indexOf(s) + 1,
              label: Text(s, style: const TextStyle(fontSize: 13)),
              icon: const Icon(Icons.sports_soccer, size: 12)
            )).toList(),
            selected: {_setSelected},
            onSelectionChanged: (Set<int> newValue) {
              setState(() {
                _setSelected = newValue.first;
              });
            }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).canvasColor,
      title: const Text("Nuovo evento"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              TextFormField(
                controller: minuteController,
                validator: (s) {
                  if (s == null || int.tryParse(s) == null)
                    return "Il campo deve essere un minuto valido";
                  final int n = int.parse(s);
                  if (n < 0 || n > 60)
                    return "Il numero inserito non è valido";
                  return null;
                },
                decoration: const InputDecoration(
                  icon: Icon(Icons.calendar_today),
                  labelText: "Minuto evento",
                ),
                keyboardType: TextInputType.number,
              ),
              const Padding(padding: EdgeInsets.only(top: 20)),
              _getSetSelector(),
              const Padding(padding: EdgeInsets.only(top: 20)),
              TextFormField(
                controller: commentController,
                validator: (s) {
                  if (s == null)
                    return "Inserisci un evento valido";
                  if (s.length < 4)
                    return "L'evento inserito è troppo corto";
                  return null;
                },
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(5.0)
                  ),
                  labelText: "Evento",
                ),
              )
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text("Annulla"),
          onPressed: () {
            Navigator.of(context).pop<bool?>(false); // Close the dialog
          },
        ),
        ElevatedButton(
          child: const Text("Aggiungi"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              int minute = int.parse(minuteController.text);
              int set = _setSelected;
              String comment = commentController.text;

              widget.reportPage.eventMinuteToAdd = minute;
              widget.reportPage.eventSetToAdd = set;
              widget.reportPage.eventCommentToAdd = comment;

              Navigator.of(context).pop<bool?>(true);
            }
          },
        ),
      ],
    );
  }
}
