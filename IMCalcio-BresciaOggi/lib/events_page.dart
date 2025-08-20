// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/event.dart';
import 'package:imcalcio/classes/formation.dart';
import 'package:imcalcio/classes/match.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/results_match_page.dart';

class EventsGoalsPage extends StatefulWidget {
  const EventsGoalsPage(this.tabIndex, {super.key, required Widget resultsMatchPage, required State matchListener, required this.refreshCondition})
      : resultsMatchPage = resultsMatchPage as ResultsMatchPage
      , matchListener = matchListener as ResultsMatchPageState;

  final ResultsMatchPage resultsMatchPage;
  final bool Function() refreshCondition;
  final ResultsMatchPageState matchListener;
  final int tabIndex;

  @override
  State<EventsGoalsPage> createState() => _EventsGoalsPageState();
}

class _EventsGoalsPageState extends State<EventsGoalsPage>
    with AutomaticKeepAliveClientMixin, PageDownloaderMixin {

  late final Match match; //widget match

  bool _chronologicalOrder = false;

  Formation? formation;

  @override
  void initState() {
    super.initState();
    match = widget.resultsMatchPage.beginMatch;
    pageDownloaderInit();
    widget.matchListener.addTabRefreshCallback(this, widget.tabIndex);
  }

  @override
  bool refreshCondition()
  {
    return widget.refreshCondition();
  }

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/matches/${widget.resultsMatchPage.beginMatch.id}/formation/"
                                         : "$defaultEndpointURL/getFormation.php?matchID=${widget.resultsMatchPage.beginMatch.id}";

  @override
  int get downloadTries => 3;

  @override
  Future<bool> parseDownloadedData(final String body) async {
    debugPrint(
        "Downloading formation of match ${widget.resultsMatchPage.beginMatch.id}");

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
      if (!json.containsKey("formations")) {
        throw Exception("Key formations does not exist.");
      }
    } on Exception catch (_, e) {
      debugPrint("Json error: $e");
      return false;
    }

    try {
      if (!json.containsKey("formations")) {
        debugPrint("Error: response does not contain formations key.");
        return false;
      }
      if (!json.containsKey("goals")) {
        debugPrint("Error: response does not contain goals key.");
        return false;
      }
      if (!json.containsKey("referees")) {
        debugPrint("Error: response does not contain referees key.");
        return false;
      }
      formation = Formation.fromJson(match, json);
    } on Exception catch (d, e) {
      debugPrint("Decode error: $d\n$e");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return getEntireRefreshablePage();
  }

  @override
  bool get wantKeepAlive => true;

  List<GoalEvent> _getGoalEvents() //List of goal events that will be displayed in the "Gol" section
  {

    //The goal should be displayed on the part of the advantaged team -> move the autogoals on the other side w.r.t. the player who did the event.
    Iterable<GoalEvent> events1 = formation!.playersTeam1.expand((p) => p.goals.map(
        (g) => GoalEvent(goal: g, minute: g.minute, set: g.set, mainPlayer: p, team: g.advantagedTeamID == match.team1.id ? EventTeamType.first : EventTeamType.second)));

    Iterable<GoalEvent> events2 = formation!.playersTeam2.expand((p) => p.goals.map(
            (g) => GoalEvent(goal: g, minute: g.minute, set: g.set, mainPlayer: p, team: g.advantagedTeamID == match.team2.id ? EventTeamType.second : EventTeamType.first)));



    List<GoalEvent> ret = [...events1, ...events2];
    Event.sortEvents(ret);
    return ret;
  }

  Iterable<SubstitutionEvent> _getTeamSubstitutionEvents(final List<FormationPlayer> players, final EventTeamType team)
  {
    return players.expand((p) {
      if (p.exitMinute > 0 && p.evictionSet <= 0 //Check if the player has been substituted and not evicted
          && p.substitutedNumber > 0 && players.length > p.substitutedNumber - 1) //Check if exists the substitute-r player
      {
        FormationPlayer enteringPlayer;
        enteringPlayer = players[p.substitutedNumber - 1];
        return [SubstitutionEvent(minute: p.exitMinute, set: p.exitSet, team: team,
            mainPlayer: enteringPlayer, subtitle: "${p.lastName} ${p.firstName}")];
      }
      return [];
    });
  }

  List<SubstitutionEvent> _getSubstitutionEvents()
  {
    List<SubstitutionEvent> ret = [..._getTeamSubstitutionEvents(formation!.playersTeam1, EventTeamType.first),
      ..._getTeamSubstitutionEvents(formation!.playersTeam2, EventTeamType.second)];
    Event.sortEvents(ret);
    return ret;
  }

  Iterable<FlagEvent> _getTeamFlagEvents(final List<FormationPlayer> players, final EventTeamType team)
  {
    Iterable<FlagEvent> flagEvents = players.expand((p) => [
        if (p.evictionSet > 0)
          RedFlagEvent(minute: p.evictionMinute, set: p.evictionSet, mainPlayer: p, team: team),
        if (p.monitionSet > 0)
          YellowFlagEvent(minute: p.monitionMinute, set: p.monitionSet, mainPlayer: p, team: team)
        else if (p.monitionX)
          YellowFlagEvent(minute: -1, set: -1, team: team, mainPlayer: p)
      ]);
    return flagEvents;
  }

  List<FlagEvent> _getFlagEvents()
  {
    List<FlagEvent> ret = [..._getTeamFlagEvents(formation!.playersTeam1, EventTeamType.first),
      ..._getTeamFlagEvents(formation!.playersTeam2, EventTeamType.second)];
    Event.sortEvents(ret);
    return ret;
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
              label: Text("Vista categorie"),
              icon: Icon(Icons.category)
            ),
            ButtonSegment<bool>(
                value: true,
                label: Text("Vista cronologica"),
                icon: Icon(Icons.calendar_today)
            )
          ],
          selected: {_chronologicalOrder},
          onSelectionChanged: (Set<bool> newValue) {
            setState(() {
              _chronologicalOrder = newValue.first;
            });
          }),
      ),
    );
  }

  @override
  Widget downloadOK() {

    List<Widget> displayed;

    if (_chronologicalOrder) {
      List<Event> chronologicalEvents = [..._getFlagEvents(), ..._getSubstitutionEvents(), ..._getGoalEvents()];
      Event.sortEvents(chronologicalEvents);
      displayed = [EventSection(name: "Eventi", events: chronologicalEvents, collapsible: false)];
    } else {
      displayed = [EventSection(name: "Gol", events: _getGoalEvents()),
      const Padding(padding: EdgeInsets.all(10)),
      const EventSection(name: "Occasioni", events: []),
      const Padding(padding: EdgeInsets.all(10)),
      EventSection(name: "Sostituzioni", events: _getSubstitutionEvents()),
      const Padding(padding: EdgeInsets.all(10)),
      EventSection(name: "Cartellini", events: _getFlagEvents()),
      const Padding(padding: EdgeInsets.all(10)),
      const EventSection(name: "Infortuni", events: [])];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_getModeSelector(), ...displayed, const Padding(padding: EdgeInsets.all(5))]
      ),
    );
  }
}

class EventSection extends StatefulWidget {
  const EventSection({super.key, required this.name, required this.events, this.collapsible = true});

  final String name;
  final List<Event> events;
  final bool collapsible;

  @override
  State<EventSection> createState() => _EventSectionState();
}

class _EventSectionState extends State<EventSection> {

  bool _open = true;

  @override
  Widget build(BuildContext context) {
    bool even = true;
    List<Widget> eventRows = [];
    for (Event e in widget.events)
    {
      eventRows.add(e.getEventRow(isEven: even));
      even = !even;
    }

    return Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)
        ),
        elevation: 10,
        color: const Color.fromARGB(255, 240, 240, 240),
        child: Column(
            children: [
              const Padding(padding: EdgeInsets.only(top: 8)),
              Row(
                mainAxisAlignment: widget.collapsible ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                children: [
                  if (widget.collapsible) const Padding(
                    padding: EdgeInsets.only(left: 15.0),
                    child: Icon(Icons.keyboard_arrow_down, color: Colors.transparent),
                  ),
                  Text(widget.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
                  if (widget.collapsible) IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(right: 15),
                    icon: Icon((_open || !widget.collapsible) ? Icons.keyboard_arrow_down_outlined : Icons.keyboard_arrow_right),
                    onPressed: () {
                      setState(() {
                        _open = !_open;
                      });
                    },
                  ),
              ]),
              const Padding(padding: EdgeInsets.only(top: 8)),
              AnimatedSize(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: SizedBox(
                  height: (_open || !widget.collapsible) ? null : 0,
                  child: Column(
                    children: [
                      if (widget.events.isNotEmpty)
                        ...eventRows
                      else Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text("Non ci sono ${widget.name.toLowerCase()}.", style: const TextStyle(fontSize: 17)),
                        )
                      ]),
                    ],
                  ),
                ),
              ),
            ]
        )
    );
  }
}