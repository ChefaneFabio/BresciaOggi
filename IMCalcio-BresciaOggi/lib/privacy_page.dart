import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/background_container.dart';

const String _privacyText = "Questa Privacy Policy è resa ai sensi dell’art. 13 del Regolamento Europeo n. 679/2016 e si applica esclusivamente a tutti i Dati raccolti attraverso il Sito web https://calcioevai.it/\n"
"La presente Privacy Policy è soggetta ad aggiornamenti che verranno pubblicati puntualmente sul Sito web. La presente Privacy Policy stabilisce le basi sulle quali verranno elaborati i Dati personali dell’Interessato. Se l’Interessato utilizza o utilizzerà l’Applicazione Calcioevai deve prendere visione anche della Applicazione Mobile. Ai sensi dell’art. 13 del Regolamento UE 2016/679 ed in relazione alle informazioni di cui si entrerà in possesso, ai fini della tutela delle persone e altri soggetti in materia di trattamento di dati personali, si informa quanto segue:\n"
"1. Finalità del Trattamento I dati forniti da siti di terze parti (https://www.legaseriea.it/it) quali verranno utilizzati allo scopo e per il fine di informare il consumatore e per un miglior riconoscimento delle squadre delle serie maggiori calcistiche. Come dati si intendono loghi delle squadre e loghi delle principali competizioni italiane. Tali dati hanno puramente finalità editoriale e non commerciale\n"
"2. Modalità del Trattamento. Le modalità con la quale verranno trattati i dati personali contemplano la sola diffusione nell’App Calcioevai e il sito web https://calcioevai.it/. La diffusione viene espressa solo tramite immagini di squadre e competizioni nazionali, cui diritti appartengono a https://www.legaseriea.it/\n"
"3. Conferimento dei dati. Il conferimento dei dati per le finalità di cui al punto 1 sono facoltativi\n"
"4. Comunicazione e diffusione dei dati I dati forniti saranno comunicati agli utenti dell’applicazione Calcioevai. I dati forniti non saranno soggetti a comunicazione né a diffusione)\n"
"5. Titolare del Trattamento. Il titolare del trattamento dei dati personali \n"
"Contenuti Digitali S.r.l. –\n"
"Sede Legale: Via Verdi, 3 – 81051 Pietramelara (CE)  – C.F e P.I.V.A 04012790616 – Reg. Imprese CE 291553\n"
"6. Diritti dell’interessato In ogni momento, le Terze parti potranno esercitare, ai sensi degli articoli dal 15 al 22 del Regolamento UE n. 2016/679, il diritto di:\n"
"a) chiedere la conferma dell’esistenza o meno di propri dati personali;\n"
"b) ottenere le indicazioni circa le finalità del trattamento, le categorie dei dati personali, i destinatari o le categorie di destinatari a cui i dati personali sono stati o saranno comunicati e, quando possibile, il periodo di conservazione;\n"
"c) ottenere la rettifica e la cancellazione dei dati;\n"
"d) ottenere la limitazione del trattamento;\n"
"e) ottenere la portabilità dei dati, ossia riceverli da un titolare del trattamento, in un formato strutturato, di uso comune e leggibile da dispositivo automatico, e trasmetterli ad un altro titolare del trattamento senza impedimenti;\n"
"f) opporsi al trattamento in qualsiasi momento ed anche nel caso di trattamento per finalità di marketing diretto;\n"
"g) opporsi ad un processo decisionale automatizzato relativo alle persone fisiche, compresa la profilazione.\n"
"h) chiedere al titolare del trattamento l’accesso ai dati personali e la rettifica o la cancellazione degli stessi o la limitazione del trattamento che lo riguardano o di opporsi al loro trattamento, oltre al diritto alla portabilità dei dati;\n"
"i) revocare il consenso in qualsiasi momento senza pregiudicare la liceità del trattamento basata sul consenso prestato prima della revoca;\n"
"j) proporre reclamo a un’autorità di controllo. Può esercitare i Suoi diritti con richiesta scritta inviata a Cernusco sul Naviglio, via Carlo Mariani, 8 all'indirizzo postale della sede legale o all’indirizzo mail  contenutidigitali@legalmail.it Io sottoscritto dichiaro di aver ricevuto l’informativa che precede.\n"
"Cernusco sul Naviglio, lì 01/02/2024";

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BackgroundContainer(
      child: Scaffold(
        appBar: MyAppBar(
          title: Text("Privacy"),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(8.0),
          child: Text(_privacyText),
        ),
      ),
    );
  }
}
