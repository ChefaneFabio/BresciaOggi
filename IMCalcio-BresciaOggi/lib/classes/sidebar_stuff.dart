import 'package:flutter/Material.dart';
import 'package:imcalcio/contactus_page.dart';
import 'package:imcalcio/news_page.dart';
import 'package:imcalcio/privacy_page.dart';
import 'package:imcalcio/classes/image_loader.dart';
import 'package:imcalcio/django_auth.dart';
import 'package:imcalcio/live_page.dart';
import 'package:imcalcio/results_category_page.dart';
import 'package:imcalcio/search_page.dart';
import 'package:imcalcio/settings_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ScaffoldWithSidebar extends StatelessWidget
{
  const ScaffoldWithSidebar({super.key, required this.body, this.appBar,
    this.floatingActionButtonLocation, this.floatingActionButton, this.backgroundColor, this.primary = true});

  final Widget body;
  final PreferredSizeWidget? appBar;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: key,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor,
      primary: primary,
      drawer: _getDrawer(context),
    );
  }

  static Future<void> openURL(final String url) async {
    await launchUrl(Uri.parse(url));
  }

  Drawer _getDrawer(final BuildContext context)
  {
    const TextStyle optionStyle = TextStyle(fontSize: 16);
    const double optionIconSize = 30.0;
    return Drawer(
      backgroundColor: Theme.of(context).canvasColor,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children:[
             DrawerHeader(
              margin: const EdgeInsets.only(left: 4.0, right: 4.0),
              padding: EdgeInsets.zero,
              child: Align(alignment: Alignment.center,
                  child: ImageLoader.instance().getImage("CalcioEVaiLogo")),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.live_tv, size: optionIconSize),
              title: const Text("Live", style: optionStyle),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                    const LivePage()));
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.groups, size: optionIconSize),
              title: const Text("Squadre", style: optionStyle),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                    SearchPage(startingSeason: getCurrentSeason(), startingSelectedPage: 0)));
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.person, size: optionIconSize),
              title: const Text("Giocatori", style: optionStyle),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                    SearchPage(startingSeason: getCurrentSeason(), startingSelectedPage: 1)));
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.emoji_events, size: optionIconSize),
              title: const Text("Competizioni", style: optionStyle),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                    SearchPage(startingSeason: getCurrentSeason(), startingSelectedPage: 2)));
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.fitness_center, size: optionIconSize),
              title: const Text("Allenatori", style: optionStyle),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                    SearchPage(startingSeason: getCurrentSeason(), startingSelectedPage: 3)));
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.business_center, size: optionIconSize),
              title: const Text("Dirigenti", style: optionStyle),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                    SearchPage(startingSeason: getCurrentSeason(), startingSelectedPage: 4)));
              },
            ),
            const Divider(thickness: 4.0),
            /*ListTile(
                dense: true,
                leading: const Icon(Icons.newspaper, size: optionIconSize),
                title: const Text("Notizie", style: optionStyle),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                          const FullNewsPage()));
                }
            ),*/
            ListTile(
              dense: true,
              leading: const Icon(Icons.sports_soccer, size: optionIconSize),
              title: const Text("Calcio e vai", style: optionStyle),
              onTap: () => openURL("https://calcioevai.it")
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.sports, size: optionIconSize),
              title: const Text("Sport e vai", style: optionStyle),
              onTap: () => openURL("https://sportevai.it")
            ),
            const Divider(thickness: 4.0),
            ListTile(
              dense: true,
              leading: const Icon(Icons.settings, size: optionIconSize),
              title: const Text("Impostazioni", style: optionStyle),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()))
            ),
            /*ListTile(
              dense: true,
              leading: const Icon(Icons.privacy_tip, size: optionIconSize),
              title: const Text("Privacy", style: optionStyle),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                const PrivacyPage()));
              },
            ),*/
            ListTile(
              dense: true,
              leading: const Icon(Icons.contact_support, size: optionIconSize),
              title: const Text("Contattaci", style: optionStyle),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                const ContactUsPage()));
              },
            ),
            const Divider(thickness: 4.0),
            ListTile(
              dense: true,
              leading: const Icon(Icons.person_2, size: optionIconSize),
              title: const Text("Autenticazione SportBrescia", style: optionStyle),
              onTap: () {
                DjangoAuth.instance.displayAuthenticationDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}