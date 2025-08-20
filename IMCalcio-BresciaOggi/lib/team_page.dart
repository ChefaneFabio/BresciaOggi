// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/team_society_page.dart';
import 'package:imcalcio/team_stats_page.dart';
import 'package:imcalcio/team_results_page.dart';
import 'package:imcalcio/team_roster_page.dart';
import 'package:imcalcio/team_scorers_page.dart';
import 'package:imcalcio/scoreboard_page.dart';

enum TeamPageTabs {
  info(Icons.info, "Società"),
  stats(Icons.bar_chart, "Statistiche"),
  results(Icons.score, "Risultati"),
  roster(Icons.groups, "Rosa e staff"), //Rosa
  goals(Icons.sports_soccer, "Marcatori"), //Marcatori
  scoreboard(Icons.format_list_numbered, "Classifica"),
  news(Icons.newspaper, "Notizie");

  const TeamPageTabs(this.icon, this.name);

  final IconData icon;
  final String name;
}

class TeamPage extends StatefulWidget {
  const TeamPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> with TickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState()
  {
    super.initState();
    _tabController = TabController(length: TeamPageTabs.values.length, vsync: this);
  }

  PreferredSizeWidget _getTabs()
  {
    return TabBar(
      isScrollable: true,
      controller: _tabController,
      tabs: TeamPageTabs.values.map((e) => Tab(
        child: Row(
          children: [
            Icon(e.icon),
            const Padding(padding: EdgeInsets.only(left: 6.0)),
            Text(e.name)
          ],
        ),
      )).toList());
  }

  Widget _getTabsBody()
  {
    return TabBarView(
        controller: _tabController,
        children: TeamPageTabs.values.map((e) {
          switch (e)
          {
            case TeamPageTabs.info:
              return TeamSocietyPage(team: widget.team);
            case TeamPageTabs.stats:
              return TeamStatsPage(team: widget.team);
            case TeamPageTabs.results:
              return TeamResultsPage(team: widget.team);
            case TeamPageTabs.roster:
              return TeamRosterPage(team: widget.team);
            case TeamPageTabs.goals:
              return TeamScorersPage(team: widget.team);
            case TeamPageTabs.scoreboard:
              return ScoreboardPage(selectedChampionship: widget.team.championship!, selectedGroupID: widget.team.groupID!,
                  selectedGroup: widget.team.group!, selectedChampionshipID: widget.team.championshipID!, selectedSeason: widget.team.season!, standalone: false);
            case TeamPageTabs.news:
              return const Center(
                child: AutoSizeText("Le notizie saranno presto disponibili.", maxLines: 1, minFontSize: 15, maxFontSize: 25),
              );
          }
        }).toList()
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: MyAppBar(
          title: Text("${widget.team.name} - ${widget.team.championship!}"),
          bottom: _getTabs(),
          centerTitle: true,
        ),
        body: _getTabsBody(),
      ),
    );
  }
}

