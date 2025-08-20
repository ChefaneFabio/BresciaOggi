import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/background_container.dart';
import 'package:imcalcio/classes/formation.dart';
import 'package:imcalcio/classes/team.dart';
import 'package:imcalcio/formations_page.dart';

class FormationsInfoPage extends StatelessWidget {
   const FormationsInfoPage({super.key})
     : examplePlayer = const FormationPlayer("Mario","Rossi", 3, 1, examplePlayerTeamID, 20, 0, 40, 1, -1, -1, -1, -1, -1, true, 40, 1,
         "", "", "", [FormationGoal(10, 0, false, 100), FormationGoal(35, 0, false, 100), FormationGoal(15, 1, true, 100),
         FormationGoal(35, 1, false, 99)]);

   final FormationPlayer examplePlayer;
   static const int examplePlayerTeamID = 100;

 //#region footballPitch
   Widget getPlayerPitchWidget(BuildContext context)
   {
     return Center(
       child: Padding(
         padding: const EdgeInsets.only(top: 50.0, right: 30.0, bottom: 30.0, left: 30.0),
         child: Transform.scale(
          scale: 2,
          child: FormationsPageState.buildPlayerMarker(context, examplePlayer, Team.getTeam("Example", id: examplePlayerTeamID))
         ),
       )
     );
   }

   TableRow getLegendPitchWidget(final Widget left, final String text, {final double scale = 2})
   {
     return TableRow(
       children: [
           Transform.scale(
             scale: scale,
             child: Container(
               alignment: Alignment.center,
              padding: const EdgeInsets.all(28),
               child: left
             ),
           ),
         Padding(
           padding: const EdgeInsets.all(8.0),
           child: Text(text, style: const TextStyle(fontSize: 16)),
         )]
     );
   }

   Widget getLegendPitch(BuildContext context)
   {
     return Padding(
       padding: const EdgeInsets.all(8.0),
       child: Table(
         border: TableBorder.all(width: 1.5),
         columnWidths: const {
           0: FlexColumnWidth(.3),
           1: FlexColumnWidth()
         },
         children: [
           getLegendPitchWidget(FormationsPageState.buildPlayerFlag(examplePlayer, const Color.fromARGB(255, 255, 90, 90), "40 ST"),
               "Espulsione del giocatore: Il giocatore è stato espulso al minuto 40 del secondo tempo."),
           //getLegendPitchWidget(FormationsPageState.buildPlayerFlag(examplePlayer, const Color.fromARGB(255, 255, 255, 90), "30 PT"),
           //    "Ammonizione del giocatore: Il giocatore è stato ammonito al minuto 30 del primo tempo."),
           getLegendPitchWidget(FormationsPageState.getMonitionFlag(), "Ammonizione del giocatore: Il giocatore è stato ammonito"),
           getLegendPitchWidget(FormationsPageState.getGoalsWidget(2),
               "Gol del giocatore: il giocatore ha segnato due gol."),
           getLegendPitchWidget(FormationsPageState.getGoalsWidget(1, rightText: "R"),
               "Rigori del giocatore: il giocatore ha segnato un rigore."),
           getLegendPitchWidget(FormationsPageState.getGoalsWidget(1, rightText: "A"),
               "Autogol del giocatore: il giocatore ha fatto un autogol."),
           getLegendPitchWidget(FormationsPageState.getExitWidget("40ST"),
               "Sostituzione: il giocatore è uscito al 40esimo minuto del secondo tempo."),
         ],
       ),
     );
   }
   
   Widget getPitchBody(BuildContext context)
   {
     return Column(
       mainAxisSize: MainAxisSize.max,
       mainAxisAlignment: MainAxisAlignment.center,
       crossAxisAlignment: CrossAxisAlignment.center,
       children: [
         const Padding(padding: EdgeInsets.only(top: 10)),
         const Text("Titolari", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500)),
         getPlayerPitchWidget(context),
         const Padding(padding: EdgeInsets.all(8)),
         getLegendPitch(context)
       ],
     );
   }
//#endregion
  
//#region reserves

  Widget getLegendReserves(BuildContext context)
  {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        border: TableBorder.all(width: 1.5),
        columnWidths: const {
          0: FlexColumnWidth(.3),
          1: FlexColumnWidth()
        },
        children: [
          getLegendPitchWidget(FormationsPageState.getReserveCellIcon(FormationsPageState.substitutionEnterImage, minute: 10, setNo: 0),
              "Sostituzione: il giocatore è entrato al decimo minuto del primo tempo.", scale: 1.5),
          getLegendPitchWidget(FormationsPageState.getReserveCellIcon(FormationsPageState.ballImage, minute: 20, setNo: 0),
              "Gol del giocatore: il giocatore ha segnato al minuto 20 del primo tempo.", scale: 1.5),
          //getLegendPitchWidget(FormationsPageState.getReserveCellIcon(FormationsPageState.yellowFlagImage, minute: 30, setNo: 0),
          //   "Ammonizione del giocatore: Il giocatore è stato ammonito al minuto 30 del primo tempo.", scale: 1.5),
          getLegendPitchWidget(FormationsPageState.getReserveCellIcon(FormationsPageState.yellowFlagImage),
             "Ammonizione del giocatore: Il giocatore è stato ammonito", scale: 1.5),
          getLegendPitchWidget(FormationsPageState.getGoalReserveCellIcon(15, 1, "R"),
              "Rigori del giocatore: il giocatore ha segnato un rigore al minuto 15 del secondo tempo.", scale: 1.5),
          getLegendPitchWidget(FormationsPageState.getGoalReserveCellIcon(35, 1, "A"),
              "Autogol del giocatore: il giocatore ha fatto un autogol al 35esimo minuto del secondo tempo.", scale: 1.5),
          getLegendPitchWidget(FormationsPageState.getReserveCellIcon(FormationsPageState.redFlagImage, minute: 40, setNo: 1),
              "Espulsione del giocatore: Il giocatore è stato espulso al minuto 40 del secondo tempo.", scale: 1.5),
          getLegendPitchWidget(FormationsPageState.getReserveCellIcon(FormationsPageState.substitutionExitImage, minute: 40, setNo: 1),
              "Sostituzione: il giocatore è uscito al 40esimo minuto del secondo tempo.", scale: 1.5),
        ],
      ),
    );
  }

  Widget getReservesBody(BuildContext context)
  {
    return Column(
      children: [
        const Text("Riserve", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500)),
        getReservesSample(context),
        getLegendReserves(context),
        const Padding(
          padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
          child: Text("Le icone delle riserve sono mostrate in base all'ordine degli eventi.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        )
      ],
    );
  }

  Widget getReservesSample(BuildContext context)
  {
    return Padding(
      padding: const EdgeInsets.only(top: 28.0, bottom: 28.0, left: 8.0, right: 8.0),
      child: Transform.scale(
        scale: 1.3,
        child: Container(
          width: MediaQuery.of(context).size.width / 2,
          decoration:  BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.0),
          ),
          child: FormationsPageState.getReserveCell(context, examplePlayer, Team.getTeam("example", id: examplePlayerTeamID)),
        ),
      ),
    );
  }
//#endregion
  
  
  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: const MyAppBar(title: Text("Dettaglio giocatore"), centerTitle: true),
        body: SingleChildScrollView(
          child: Column(
            children: [
              getPitchBody(context),
              const Divider(height: 10, thickness: 3.0, indent: 10.0, endIndent: 10.0, color: Colors.black),
              getReservesBody(context)
            ],
          )
        ),
      ),
    );
  }
}
