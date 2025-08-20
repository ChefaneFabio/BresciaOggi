import 'dart:developer';

import 'package:flutter/Material.dart';
import 'package:imcalcio/classes/image_loader.dart';

class BackgroundContainer extends StatelessWidget {
  const BackgroundContainer({super.key, required this.child, this.displayBannerAd = true});

  final Widget child;
  final bool displayBannerAd;

  @override
  Widget build(BuildContext context) {
    final Container cont = Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        image: DecorationImage(
          colorFilter: ColorFilter.mode(Theme.of(context).canvasColor.withOpacity(.15), BlendMode.dstATop),
          image: ImageLoader.instance().getImage("background2").image,
          fit: BoxFit.cover
        )
      ),
      child: child
    );

    return cont;
  }
}

class MyAppBar extends StatelessWidget implements PreferredSizeWidget
{
 
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;
  
  const MyAppBar({super.key, this.title, this.leading, this.actions, this.centerTitle, this.bottom});
  
  @override
  Size get preferredSize {
    double height = kToolbarHeight;
    if (bottom != null)
      height += bottom!.preferredSize.height;
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      key: key,
      title: title,
      actions: actions,
      centerTitle: centerTitle,
      bottom: bottom,
      leading: leading ?? GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        onLongPress: () => Navigator.of(context).popUntil((route) => route.isFirst),
        child: const Icon(Icons.arrow_back)
      ),
    );
  }


}