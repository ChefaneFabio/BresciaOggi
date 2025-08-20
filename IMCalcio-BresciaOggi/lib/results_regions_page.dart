import "package:flutter/material.dart";
import "package:imcalcio/classes/background_container.dart";
import "package:imcalcio/classes/region.dart";
import "package:imcalcio/results_committee_page.dart";

//TEMPLATE 2

class ResultsRegionsPage extends StatefulWidget {
  const ResultsRegionsPage({super.key, required this.categoryName, required this.selectedSeason});

  final String categoryName;
  final String selectedSeason;

  @override
  State<ResultsRegionsPage> createState() => _ResultsRegionsPageState();
}

class _ResultsRegionsPageState extends State<ResultsRegionsPage> {

  Widget buildRegionButton(String region)
  {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
          ResultsCommitteePage(selectedRegion: region, selectedSeason: widget.selectedSeason, selectedCategoryName: widget.categoryName))),
      child: Card(
        elevation: 5,
        color: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 30,
                  width: 30,
                  child: Region.instance().getImage(region),
                ),
                Expanded(
                  child: Text(region,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          )
      ),
    );
  }
  
  Widget getGridView()
  {
    List<Widget> regions = Region.instance().getSortedList().map((String r) => buildRegionButton(r)).toList();

    return GridView.count(
      primary: false,
      crossAxisCount: 2,
      crossAxisSpacing: 5,
      mainAxisSpacing: 5,
      padding: const EdgeInsets.all(10),
      childAspectRatio: (1 / .4),
      children: regions
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: MyAppBar(
          centerTitle: true,
          title: Text(widget.categoryName)
        ),
        body: getGridView()
      ),
    );
  }



}
