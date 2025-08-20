// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:flutter/Material.dart';
import 'package:flutter/services.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/championship.dart';
import 'package:imcalcio/classes/coach.dart';
import 'package:imcalcio/classes/player.dart';
import 'package:imcalcio/staffer_page.dart';
import 'package:imcalcio/details_dispatcher_page.dart';
import 'package:imcalcio/player_page.dart';
import 'package:imcalcio/team_page.dart';
import 'package:imcalcio/classes/page_downloader_mixin.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/season_selector_dialog.dart';

enum SearchTabs {
  teams(name: "Squadre", tabIcon: Icons.groups, constructor: teamsConstructor),
  players(name: "Giocatori", tabIcon: Icons.person, constructor: playersConstructor),
  championships(name: "Competizioni", tabIcon: Icons.emoji_events, constructor: championshipsConstructor),
  coaches(name: "Allenatori", tabIcon: Icons.fitness_center, constructor: coachConstructor),
  managers(name: "Dirigenti", tabIcon: Icons.business_center, constructor: managerConstructor);

  static SearchTab teamsConstructor(final SearchPageState page, final String season) => TeamsSearchTab(searchPageState: page, startingSeason: season);
  static SearchTab playersConstructor(final SearchPageState page, final String season) => PlayersSearchTab(searchPageState: page, startingSeason: season);
  static SearchTab championshipsConstructor(final SearchPageState page, final String season) => ChampionshipsSearchTab(searchPageState: page, startingSeason: season);
  static SearchTab coachConstructor(final SearchPageState page, final String season) => CoachesSearchTab(searchPageState: page, startingSeason: season);
  static SearchTab managerConstructor(final SearchPageState page, final String season) => ManagersSearchTab(searchPageState: page, startingSeason: season);

  final String name;
  final IconData tabIcon;

  final SearchTab Function(SearchPageState, String) constructor;

  const SearchTabs({required this.name, required this.tabIcon, required this.constructor});
}

//#region SearchPage

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.startingSeason, this.startingSelectedPage = 0});

  final String startingSeason;
  final int startingSelectedPage;

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> with TickerProviderStateMixin {

  static const Widget emptySearchWidget = Padding(
    padding: EdgeInsets.only(top: 20.0),
    child: Text("La ricerca non ha prodotto risultati.", textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
  );

  static const TextStyle searchTitleStyle = TextStyle(fontWeight: FontWeight.w500, fontSize: 16.0);
  static const TextStyle searchSubtitleStyle = TextStyle(fontSize: 14.0);

  late TabController _tabController;

  PreferredSizeWidget _getTabs()
  {
    return TabBar(
        isScrollable: true,
        controller: _tabController,
        tabs: SearchTabs.values.map((e) {
          return Tab(
            child: Row(
              children: [
                Icon(e.tabIcon),
                const Padding(padding: EdgeInsets.only(left: 6.0)),
                Text(e.name)
              ],
            ),
          );
        }).toList()
    );
  }

  @override
  void initState()
  {
    super.initState();
    _tabController = TabController(length: SearchTabs.values.length, vsync: this);
    _tabController.index = widget.startingSelectedPage;
  }

  Widget _getTabsBody()
  {
    return TabBarView(
        controller: _tabController,
        children: SearchTabs.values.map((e) => e.constructor(this, widget.startingSeason)).toList()
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: MyAppBar(
          title: const Text("Cerca"),
          centerTitle: true,
          bottom: _getTabs(),
        ),
        body: _getTabsBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => buttonPressedCallbacks[SearchTabs.values[_tabController.index]]!(), //Call callback of tab
          label: const Text("Cerca"),
          icon: const Icon(Icons.search),
        ),
      ),
    );
  }

  final Map<SearchTabs, void Function()> buttonPressedCallbacks = {};
  void registerTab(final SearchTabs type, void Function() buttonPressed) //Register a callback for when the button is pressed
  {
    buttonPressedCallbacks[type] = buttonPressed;
  }
}

//#endregion SearchPage

//#region SearchTabs

abstract class SearchTab extends StatefulWidget {
  const SearchTab({super.key, required this.searchPageState, required this.startingSeason});

  final SearchPageState searchPageState;
  final String startingSeason;

  @override
  State<SearchTab> createState();
}

class TeamsSearchTab extends SearchTab {
  const TeamsSearchTab({super.key, required super.searchPageState, required super.startingSeason});

  @override
  State<SearchTab> createState() => TeamsSearchTabState();
}

class PlayersSearchTab extends SearchTab {
  const PlayersSearchTab({super.key, required super.searchPageState, required super.startingSeason});

  @override
  State<SearchTab> createState() => PlayersSearchTabState();
}

class ChampionshipsSearchTab extends SearchTab {
  const ChampionshipsSearchTab({super.key, required super.searchPageState, required super.startingSeason});

  @override
  State<SearchTab> createState() => ChampionshipSearchTabState();
}

class CoachesSearchTab extends SearchTab {
  const CoachesSearchTab({super.key, required super.searchPageState, required super.startingSeason});

  @override
  State<SearchTab> createState() => CoachesSearchTabState();
}

class ManagersSearchTab extends SearchTab {
  const ManagersSearchTab({super.key, required super.searchPageState, required super.startingSeason});

  @override
  State<SearchTab> createState() => ManagersSearchTabState();
}

//#endregion SearchTabs

String getFullString(final String? s1, final String? s2, final String? s3)
{
  String ret = "";
  ret = (s1 == null) ? ret : "$ret - $s1";
  ret = (s2 == null) ? ret : "$ret - $s2";
  ret = (s3 == null) ? ret : "$ret - $s3";

  return ret.length > 3 ? ret.substring(3) : "";
}

//#region SearchTabStates
abstract class SearchTabState extends State<SearchTab> with AutomaticKeepAliveClientMixin, PageDownloaderMixin {

  late TextEditingController textController;
  SearchTabs? getTab();
  String getObjName();

  bool buttonHasBeenPressed = false;

  bool get hasSeasonSelector => false;

  late String selectedSeason;

  @override
  void initState()
  {
    super.initState();
    selectedSeason = widget.startingSeason;
    widget.searchPageState.registerTab(getTab()!, searchButtonPressed);
    textController = TextEditingController();
  }

  void searchButtonPressed()
  {
    FocusManager.instance.primaryFocus?.unfocus(); //Close keyboard
    debugPrint("SearchButtonPressed of ${getTab()}. Url = $downloadUrl");

    if (textController.text.replaceFirst(" ", "").length < 3)
    {
      AlertDialog dialog = AlertDialog(
        backgroundColor: Theme.of(context).canvasColor,
        title: const Text("Errore"),
        content: const Text("Inserisci almeno 3 caratteri."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Ok"),
          )
        ],
      );
      showDialog(context: context, builder: (context) => dialog);
      return;
    }

    setState(() {
      buttonHasBeenPressed = true;
      pageDownloaderInit();
    });
  }

  Widget _getSearchTextField()
  {
    return TextField(
      controller: textController,
      keyboardType: TextInputType.text,
      onSubmitted: (final String season) {
        searchButtonPressed();
      },
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZàòèÀÒÈéÉúÚíÍóÓáÁűŰőŐüÜöÖäÄß\s]", unicode: true))
      ],
      decoration: InputDecoration(
        prefixIcon: Icon(getTab()!.tabIcon),
        isDense: true,
        fillColor: Colors.white,
        filled: true,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.greenAccent),
        ),
      ),
    );
  }

  Widget _getSearchFieldSeasonSelector() //Search field + season selector
  {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Flexible(flex: 2, child: _getSearchTextField()),
        Flexible(flex: 1, child: GestureDetector(
          onTap: () async {
            String? newSeason = await Navigator.of(context)
                .push(MaterialPageRoute<String>(builder: (context) => SeasonSelectorDialog(initialCurrentSeason: selectedSeason)));
            if (newSeason != null)
              setState(() {
                selectedSeason = newSeason;
              });
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Stagione:", textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
                Text(selectedSeason, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
              ],
            ),
          ),
        ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          hasSeasonSelector ? _getSearchFieldSeasonSelector() : _getSearchTextField(),
          const Padding(padding: EdgeInsets.only(top: 20)),
          Expanded(child: getSearchWidget())
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget getDefaultWidget() //When the user has NOT pressed the button. Default text
  {
    return Text("Inserisci ${getObjName()} che vuoi cercare e premi il tasto in fondo alla pagina.",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.center);
  }

  Widget getSearchWidget()
  {
    if (buttonHasBeenPressed)
      return getEntirePage();

    return getDefaultWidget();
  }
}

class TeamsSearchTabState extends SearchTabState
{
  List<Team> downloadedTeams = [];

  @override
  bool get hasSeasonSelector => true;

  @override
  SearchTabs getTab() => SearchTabs.teams;

  @override
  String getObjName() => "la squadra";

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/teams/search/brescia/?name=${textController.text}&season=$selectedSeason"
                                         : "$defaultEndpointURL/searchTeams.php?team=${textController.text}&season=$selectedSeason";

  @override
  Future<bool> parseDownloadedData(String body) async {
    debugPrint("Downloading search of team ${textController.text}");

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
    } on Exception catch (_, e) {
      debugPrint("Json error: $e");
      return false;
    }

    List<Team> newDownloadedTeams = [];

    try {
      for (int i = 0; true; i++)
      {
        if (json[i.toString()] == null)
          break;

        Map<String, dynamic> teamJson = json[i.toString()];
        Team team = Team.getTeam(teamJson["teamName"],
                                id: int.parse(teamJson["teamID"].toString()),
                                championship: teamJson["championship"],
                                locality: teamJson["locality"],
                                group: teamJson["group"],
                                groupID: int.parse(teamJson["groupID"].toString()),
                                championshipID: int.parse(teamJson["championshipID"].toString()),
                                season: selectedSeason
                                );
        newDownloadedTeams.add(team);
      }
    } on Exception catch (d, e) {
      debugPrint("Decode error: $d\n$e");
      return false;
    }
    downloadedTeams = newDownloadedTeams;
    return true;
  }

  @override
  Widget downloadOK()
  {
    if (downloadedTeams.isNotEmpty)
      return ListView(
        shrinkWrap: true,
        children: downloadedTeams.expand((e) => [ListTile(
            dense: true,
            leading: SizedBox(width: 30, height: 30, child: e.icon),
            title: Text(e.name, style: SearchPageState.searchTitleStyle),
            subtitle: Text(getFullString(e.locality, e.championship, e.group), style: SearchPageState.searchSubtitleStyle),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => TeamPage(team: e)));
            },
          ),
          const Divider()
      ]).toList());
    return SearchPageState.emptySearchWidget;
  }
}

class PlayersSearchTabState extends SearchTabState
{
  List<SearchPlayer> downloadedPlayers = [];
  
  @override
  bool get hasSeasonSelector => true;

  @override
  SearchTabs getTab() => SearchTabs.players;

  @override
  String getObjName() => "il giocatore";

  @override
  //String get downloadUrl => "$defaultEndpointURL/searchPlayers.php?name=${textController.text}&season=$selectedSeason";
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/players/search/brescia/?name=${textController.text}&season=$selectedSeason"
                                         : "$defaultEndpointURL/searchPlayers.php?name=${textController.text}&season=$selectedSeason";

  @override
  Future<bool> parseDownloadedData(String body) async {
    debugPrint("Downloading search of player ${textController.text} - season $selectedSeason");

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
    } on Exception catch (_, e) {
      debugPrint("Json error: $e");
      return false;
    }
    List<SearchPlayer> newDownloadedPlayers = [];

    try {
      for (int i = 0; true; i++)
      {
        if (json[i.toString()] == null)
          break;

        Map<String, dynamic> playerJson = json[i.toString()];
        SearchPlayer player = SearchPlayer(int.parse(playerJson["playerID"].toString()), playerJson["firstName"], playerJson["lastName"],
          teamID: int.parse(playerJson["teamID"].toString()), teamName: playerJson["teamName"] ?? "", champID: int.parse(playerJson["champID"].toString()),
            champName: playerJson["champName"]);
        newDownloadedPlayers.add(player);
      }
    } on Exception catch (d, e) {
      debugPrint("Decode error: $d\n$e");
      return false;
    }
    downloadedPlayers = newDownloadedPlayers;
    return true;
  }

  @override
  Widget downloadOK() {
    if (downloadedPlayers.isNotEmpty)
      return ListView(
          shrinkWrap: true,
          children: downloadedPlayers.expand((e) {
            final Team team = Team.getTeam(e.teamName, id: e.teamID);
            return [ListTile(
                dense: true,
                leading: SizedBox(width: 30, height: 30, child: team.icon),
                title: Text("${e.firstName} ${e.lastName}", style: SearchPageState.searchTitleStyle),
                subtitle: Text(getFullString(e.teamName, e.champName, e.matricola != null ? "Matricola ${e.matricola}" : null), style: SearchPageState.searchSubtitleStyle),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlayerPage(searchPlayer: e, season: selectedSeason)));
                },
              ),
              const Divider()
            ];
          }).toList()
      );
    return SearchPageState.emptySearchWidget;
  }
}

class ChampionshipSearchTabState extends SearchTabState
{
  @override
  bool get hasSeasonSelector => true;

  @override
  SearchTabs getTab() => SearchTabs.championships;

  @override
  String getObjName() => "il campionato";

  List<Group> downloadedChampionships = [];

  @override
  //String get downloadUrl => "$defaultEndpointURL/searchChampionships.php?champ=${textController.text}&season=$selectedSeason";
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/champs/search?champ_name=${textController.text}&season_name=$selectedSeason"
                                         : "$defaultEndpointURL/searchChampionships.php?champ=${textController.text}&season=$selectedSeason";

  @override
  Future<bool> parseDownloadedData(String body) async {
    debugPrint("Downloading search of championship ${textController.text}");

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
    } on Exception catch (_, e) {
      debugPrint("Json error: $e");
      return false;
    }

    List<Group> newDownloadedChampionships = [];

    try {
      for (int i = 0; true; i++)
      {
        if (json[i.toString()] == null)
          break;

        Map<String, dynamic> champJson = json[i.toString()];
        Group champ = Group(champName: champJson["champName"], champID: int.parse(champJson["champID"].toString()),
          committee: champJson["committeeName"], id: int.parse(champJson["groupID"].toString()), name: champJson["groupName"], season: selectedSeason,
        category: champJson["category"] ?? champJson["area"], committeeID: int.parse(champJson["committeeID"].toString()));
        newDownloadedChampionships.add(champ);
      }
    } on Exception catch (d, e) {
      debugPrint("Decode error: $d\n$e");
      return false;
    }
    downloadedChampionships = newDownloadedChampionships;
    return true;
  }

  @override
  Widget downloadOK() {
    NavigatorState currentNavigator = Navigator.of(context);
    if (downloadedChampionships.isNotEmpty)
      return ListView(
          shrinkWrap: true,
          children: downloadedChampionships.expand((e) {
            Championship championship = Championship(e.champName, e.champID);
            return [ListTile(
              dense: true,
              leading: SizedBox(width: 30, height: 30, child: championship.getIcon(selectedSeason)),
              title: Text(getFullString(e.champName, "Girone ${e.name}", null), style: SearchPageState.searchTitleStyle),
              subtitle: Text(getFullString(e.category, e.committee, null), style: SearchPageState.searchSubtitleStyle),
              onTap: () async {
                ChampionshipDetailsPage? chosen = await openChooseDetailsPageDialog(e.name, e.champName, context);
                if (chosen == null)
                  return;

                currentNavigator.push(MaterialPageRoute(builder: (context) =>
                    ChampionshipDetailsDispatcherPage(initialPage: chosen,
                        selectedSeason: selectedSeason, selectedCommittee: e.committee, selectedCategory: e.category,
                        selectedChampionship: e.champName, selectedChampionshipID: e.champID,
                        selectedGroup: e.name, selectedGroupID: e.id, selectedCommitteeID: e.committeeID)));
              },
            ),
            const Divider()
          ];}).toList());
    return SearchPageState.emptySearchWidget;
  }
}

class CoachesSearchTabState extends SearchTabState
{
  List<SearchCoach> downloadedCoaches = [];

  @override
  SearchTabs getTab() => SearchTabs.coaches;

  @override
  String getObjName() => "l'allenatore";

  @override
  Future<bool> parseDownloadedData(String body) async {
    debugPrint("Downloading search of coach ${textController.text}");

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
    } on Exception catch (_, e) {
      debugPrint("Json error: $e");
      return false;
    }

    List<SearchCoach> newCoaches = [];

    int i = 0;
    while (true)
    {
      if (!json.containsKey(i.toString())) break;

      Map<String,dynamic> coachJson = json[i.toString()];

      try {
        SearchCoach c = SearchCoach(
          int.parse(coachJson["id"].toString()),
          firstName: coachJson["firstName"],
          lastName: coachJson["lastName"],
          championship: coachJson["championship"],
          committee: coachJson["committee"],
          teamID: int.tryParse((coachJson["teamID"] ?? "").toString()),
          teamName: coachJson["teamName"],
          birthday: coachJson["birthday"],
          season: coachJson["season"]
        );
        newCoaches.add(c);
      } catch (e) {
        debugPrint(e.toString());
      }
      i++;
    }

    downloadedCoaches = newCoaches;
    return true;
  }

  @override
  Widget downloadOK() {
    if (downloadedCoaches.isNotEmpty)
      return ListView(
          shrinkWrap: true,
          children: downloadedCoaches.expand((e) {
            Team? team = e.teamName != null ? Team.getTeam(e.teamName!, id: e.teamID!) : null;
            return [ListTile(
              dense: true,
              leading: SizedBox(width: 30, height: 30, child: team != null ? team.icon : const Icon(Icons.person)),
              title: Text("${e.firstName} ${e.lastName}", style: SearchPageState.searchTitleStyle),
              subtitle: Text(getFullString(e.teamName, e.championship, e.season), style: SearchPageState.searchSubtitleStyle),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                    StafferPage(StafferType.coach, stafferID: e.id, stafferFullName: "${e.firstName} ${e.lastName}")));
              },
            ),
              const Divider()
            ];}).toList());
    return SearchPageState.emptySearchWidget;
  }

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/staff/coaches/search/?name=${textController.text}"
                                         : "$defaultEndpointURL/searchCoaches.php?name=${textController.text}";
}

class ManagersSearchTabState extends SearchTabState
{
  List<SearchCoach> downloadedManagers = [];

  @override
  SearchTabs getTab() => SearchTabs.managers;

  @override
  String getObjName() => "il dirigente";

  @override
  Future<bool> parseDownloadedData(String body) async {
    debugPrint("Downloading search of coach ${textController.text}");

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
    } on Exception catch (_, e) {
      debugPrint("Json error: $e");
      return false;
    }

    List<SearchCoach> newCoaches = [];

    int i = 0;
    while (true)
    {
      if (!json.containsKey(i.toString())) break;

      Map<String,dynamic> coachJson = json[i.toString()];

      try {
        SearchCoach c = SearchCoach(
            int.parse(coachJson["id"].toString()),
            firstName: coachJson["firstName"],
            lastName: coachJson["lastName"],
            championship: coachJson["championship"],
            committee: coachJson["committee"],
            teamID: int.tryParse((coachJson["teamID"] ?? "").toString()),
            teamName: coachJson["teamName"],
            birthday: coachJson["birthday"],
            season: coachJson["season"]
        );
        newCoaches.add(c);
      } catch (e) {
        debugPrint(e.toString());
      }
      i++;
    }

    downloadedManagers = newCoaches;
    return true;
  }

  @override
  Widget downloadOK() {

    if (downloadedManagers.isNotEmpty)
      return ListView(
          shrinkWrap: true,
          children: downloadedManagers.expand((e) {
            Team? team = e.teamName != null ? Team.getTeam(e.teamName!, id: e.teamID!) : null;
            return [ListTile(
              dense: true,
              leading: SizedBox(width: 30, height: 30, child: team != null ? team.icon : const Icon(Icons.person)),
              title: Text("${e.firstName} ${e.lastName}", style: SearchPageState.searchTitleStyle),
              subtitle: Text(getFullString(e.teamName, e.championship, e.season), style: SearchPageState.searchSubtitleStyle),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                  StafferPage(StafferType.manager, stafferID: e.id, stafferFullName: "${e.firstName} ${e.lastName}")));
              },
            ),
              const Divider()
            ];
          }).toList());
    return SearchPageState.emptySearchWidget;
  }

  @override
  String get downloadUrl => useRemoteAPI ? "$remoteAPIURL/staff/managers/search/?name=${textController.text}"
                                         : "$defaultEndpointURL/searchManagers.php?name=${textController.text}";
}

//#endregion SearchTabStates