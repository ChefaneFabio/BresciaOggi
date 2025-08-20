// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/Material.dart';
import 'package:imcalcio/formations_page.dart';

import 'formation.dart';

enum EventTeamType {first, second}

abstract class Event //GoalEvent, ...
{
  static const Color evenRowColor = Color.fromARGB(255, 220, 220, 220);
  static const Color oddRowColor = Colors.transparent;
  static const double iconWidth = 20;
  static const double iconHeight = 50;
  static const double mainPlayerTextSize = 13;
  static const double secondaryPlayerTextSize = 12.5;
  static const double minuteTextSize = 11.5;

  final int set;
  final int minute;

  final FormationPlayer mainPlayer;
  final String? subtitle;

  final EventTeamType team;

  Widget get icon;

  const Event({required this.minute, required this.set, required this.team, required this.mainPlayer, this.subtitle});

  static void sortEvents(List<Event> events)
  {
    events.sort((e1, e2) => (e1.set * 1000 + e1.minute).compareTo(e2.set * 1000 + e2.minute));
  }

  Widget getEventCell(final EventTeamType team, final Widget icon)
  {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      visualDensity: VisualDensity.compact,
      minLeadingWidth: 10,
      dense: true,
      title: Text("${mainPlayer.firstName} ${mainPlayer.lastName}", style: const TextStyle(fontSize: mainPlayerTextSize, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      subtitle: (subtitle != null) ? Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(fontSize: secondaryPlayerTextSize)) : null,
      leading: team == EventTeamType.first ?  icon : null,
      trailing: team == EventTeamType.second ? icon : null,
    );
  }

  Widget getEventRow({bool isEven = true})
  {
    final Color rowColor = isEven ? evenRowColor : oddRowColor;
    return Container(
      color: rowColor,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 40, //MinHeight
          ),
          Expanded( //Left widget
            flex: 1,
            child: (team == EventTeamType.first) ? getEventCell(team, icon) : Container(),
          ),
          Container( //Minute + set
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: (set > 0) ? Colors.blueAccent : Colors.transparent
            ),
            child: Text("$minute${getSetString(set)}", style: TextStyle(fontWeight: FontWeight.w700,
                fontSize: minuteTextSize, color: (set > 0) ? Colors.black : Colors.transparent)),
          ),
          Expanded(
              flex: 1,
              child: (team == EventTeamType.second) ? getEventCell(team, icon) : Container()
          )
        ],
      ),
    );
  }
}

//Goals
class GoalEvent extends Event
{
  final FormationGoal goal;

  GoalEvent({required super.minute, required super.set, required super.team,
    required super.mainPlayer, super.subtitle, required this.goal});

  Widget _getGoalIcon()
  {
    return SizedBox(
      width: Event.iconWidth,
      height: Event.iconHeight,
      child: FormationsPageState.ballImage,
    );
  }

  Widget _getSpecialGoalIcon(final String type)
  {
    return SizedBox(
      width: Event.iconWidth,
      height: Event.iconWidth, //Width, not a typo, otherwise the R of penalties goes out of the ball.
      child: Stack(
        children: [
          _getGoalIcon(),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(5)
              ),
              child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: Event.minuteTextSize),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget get icon {
    if (goal.penalty)
      return _getSpecialGoalIcon("R");
    else if (goal.advantagedTeamID != mainPlayer.teamID)
      return _getSpecialGoalIcon("A");
    return _getGoalIcon();
  }
}

//Occasions like goals but with different icons

//Substitutions
class SubstitutionEvent extends Event
{
  SubstitutionEvent({required super.minute, required super.set, required super.team,
    required super.mainPlayer, required super.subtitle});

  @override
  Widget get icon {
    return SizedBox(
      width: Event.iconWidth,
      height: Event.iconHeight,
      child: FormationsPageState.substitutionImage
    );
  }
}

//Bookings
abstract class FlagEvent extends Event
{
  FlagEvent({required super.minute, required super.set, required super.team,
    required super.mainPlayer, super.subtitle});

  Image get _image;

  @override
  Widget get icon => SizedBox(
    width: Event.iconWidth-2,
    height: Event.iconHeight-2,
    child: ColorFiltered(
      colorFilter: const ColorFilter.matrix([ //Darken the flags (especially useful for the yellow one)
        0.9, 0, 0, 0, 0, // Red channel
        0, 0.9, 0, 0, 0, // Green channel
        0, 0, 0.9, 0, 0, // Blue channel
        0, 0, 0, 1, 0, // Alpha channel
      ]),
      child: _image
    ),
  );
}

class RedFlagEvent extends FlagEvent
{
  RedFlagEvent({required super.minute, required super.set, required super.team,
    required super.mainPlayer, super.subtitle});

  @override
  Image get _image => FormationsPageState.redFlagImage;
}

class YellowFlagEvent extends FlagEvent
{
  YellowFlagEvent({required super.minute, required super.set, required super.team,
    required super.mainPlayer, super.subtitle});

  @override
  Image get _image => FormationsPageState.yellowFlagImage;
}