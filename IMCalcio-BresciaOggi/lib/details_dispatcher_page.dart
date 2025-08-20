// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/Material.dart';
import 'package:imcalcio/results_match_list_page.dart';
import 'package:imcalcio/scoreboard_page.dart';

enum ChampionshipDetailsPage {
  results(icon: Icons.scoreboard, shortTitle: "Risultati"),
  scoreboard(icon: Icons.format_list_numbered, shortTitle: "Classifica");
 // calendar(icon: Icons.calendar_month, shortTitle: "Calendario")

  const ChampionshipDetailsPage({required this.icon, required this.shortTitle});

  static String completeTitle(final ChampionshipDetailsPage page, final String championship) //"Risultati" o "Classifica"
  {
    switch (page) {
      case ChampionshipDetailsPage.scoreboard:
      //case ChampionshipDetailsPage.calendar:
        return page.shortTitle;
      case ChampionshipDetailsPage.results:
        return page.shortTitle;
    }
  }

  final IconData icon;
  final String shortTitle;
}

//Opens a dialog with the buttons "Classifica" and "Risultati" (and "Calendar", later).
Future<ChampionshipDetailsPage?> openChooseDetailsPageDialog(String groupName,
    final String championshipName, final BuildContext context, {final ChampionshipDetailsPage? selectedPage}) {
  const double titleSize = 20.0;
  const double optionsSize = 18.0;

  if (!groupName.toLowerCase().startsWith("girone"))
    groupName = "Girone $groupName";

  return showDialog<ChampionshipDetailsPage?>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Rounded corners for the dialog
        ),
        title: Text(
          "Seleziona un'opzione per il campionato $championshipName",//$championshipName, $groupName",
          style: const TextStyle(color: Colors.blueAccent, fontSize: titleSize), // Custom text style for the title
        ),
        content:
        Column(
            mainAxisSize: MainAxisSize.min,
            children: ChampionshipDetailsPage.values.expand((page) {
              return [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  splashColor: Colors.blueAccent[300], // Ripple color
                  onTap: () {
                    Navigator.pop(context, page);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(page.icon, color: Colors.blueAccent),
                            const Padding(padding: EdgeInsets.only(left: 10)),
                            Text(page.shortTitle, style: const TextStyle(color: Colors.blueAccent, fontSize: optionsSize)),
                          ],
                        ),
                        if (selectedPage == page) const Icon(Icons.check_circle, color: Colors.blueAccent),
                      ],
                    ),
                  ),
                ),
                if (page != ChampionshipDetailsPage.values.last) const Divider(color: Colors.blueAccent)
              ];}
            ).toList()
        ),
      );
    },
  );
}


class ChampionshipDetailsDispatcherPage extends StatefulWidget {
  final ChampionshipDetailsPage initialPage;

  final String selectedSeason; //
  final String selectedCommittee; //
  final int selectedCommitteeID;
  final String selectedCategory;
  final int selectedChampionshipID; //
  final String selectedChampionship; //
  final int selectedGroupID; //
  final String selectedGroup; //

  const ChampionshipDetailsDispatcherPage({super.key, required this.initialPage, required this.selectedSeason,
    required this.selectedChampionship, required this.selectedChampionshipID,
    required this.selectedCommittee, required this.selectedCommitteeID,
    required this.selectedGroup, required this.selectedGroupID, required this.selectedCategory});

  @override
  State<ChampionshipDetailsDispatcherPage> createState() => _ChampionshipDetailsDispatcherPageState();
}

class _ChampionshipDetailsDispatcherPageState extends State<ChampionshipDetailsDispatcherPage> {
  late ChampionshipDetailsPage selectedPage;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    debugPrint("InitialPage: ${widget.initialPage}, selectedCategory: ${widget.selectedCategory}");
    selectedPage = widget.initialPage;
    _pageController = PageController(initialPage: selectedPage.index);
  }

  Widget _getPagesAppBarTitle() //Dropdown with Risultati and Classifica
  {
    return GestureDetector(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(ChampionshipDetailsPage.completeTitle(selectedPage, widget.selectedChampionship), softWrap: true, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.arrow_drop_down)
            ]
          ),
          AutoSizeText("${widget.selectedChampionship} - ${widget.selectedGroup}", textAlign: TextAlign.center, maxLines: 1, maxFontSize: 18, minFontSize: 8, softWrap: true)
        ]
      ),
      onTap: () async {
        ChampionshipDetailsPage? newPage = await openChooseDetailsPageDialog(widget.selectedGroup,
            widget.selectedChampionship, context, selectedPage: selectedPage);
        if (newPage != null && newPage != selectedPage)
        {
          setState(() {
            selectedPage = newPage;
            _pageController.jumpToPage(selectedPage.index);
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            selectedPage = ChampionshipDetailsPage.values[index];
          });
        },
        children: [
          ResultsMatchListPage(appBarTitle: _getPagesAppBarTitle, selectedSeason: widget.selectedSeason, selectedCommittee: widget.selectedCommittee, selectedCategoryName: widget.selectedCategory,
              selectedChampionship: widget.selectedChampionship, selectedChampionshipID: widget.selectedChampionshipID, selectedGroup: widget.selectedGroup, selectedGroupID: widget.selectedGroupID),  // Placeholder for your results page widget
          ScoreboardPage(standaloneTitle: _getPagesAppBarTitle, selectedSeason: widget.selectedSeason, selectedGroupID: widget.selectedGroupID,
              selectedChampionship: widget.selectedChampionship, selectedChampionshipID: widget.selectedChampionshipID, selectedGroup: widget.selectedGroup, standalone: true),  // Placeholder for your scoreboard page widget
          //TODO CALENDAR
        ],
    );
  }
}