import 'package:flutter/material.dart';
import 'package:music_player/logger.dart' show gLogger;
import 'package:provider/provider.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/PageDescr.dart';

import 'package:music_player/states/AppearanceState.dart';

import 'package:music_player/view/components/parts.dart';

const double titleHeight = 36;
const double subtitleHeight = 23;
const double actionBtnHeight = 32;

double calcPageHeaderHeight(PageHeaderDescr header) {
  if (header.picture != null) {
    return CONFIG.pageHeaderHeight;
  }
  double h = titleHeight;
  if (header.subtitle != null) {
    h += subtitleHeight + 4.0; // subtitle padding
  }
  if (header.actionBtn != null) {
    h += actionBtnHeight + 8.0; // btn padding
  }
  h += 4.0; // bottom padding
  return h;
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.header,
    Key? key,
  }) : super(key: key);

  final PageHeaderDescr header;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    // double vw = MediaQuery.of(context).size.width;
    double titleFontSize = 25.0;
    double subtitleFontSize = 16.0;
    var height = calcPageHeaderHeight(header);
    // gLogger.blue('height: $height');
    // if (CONFIG.pageHeaderHeight > vw * 0.3) {
    //   titleFontSize = 20.0;
    //   subtitleFontSize = 14.0;
    //   height = 130;
    // }

    return Padding(
      padding: EdgeInsets.only(
          bottom: header.picture != null ? 18.0 : 0.0,
          top: 12.0,
          left: 12.0,
          right: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.picture != null)
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: Thumbnail(picture: header.picture, size: height),
            ),
          Flexible(
            child: Container(
              // color: Colors.red,
              height: height,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          header.title == CONFIG.favouritesPlaylist
                              ? lang.Favourites
                              : header.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: titleFontSize),
                          // softWrap:
                        ),
                        if (header.subtitle != null) ...[
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            header.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: subtitleFontSize,
                                color:
                                    appearanceState.colors[ColorType.subtitle]),
                          ),
                        ],
                      ],
                    ),
                    if (header.actionBtn != null) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: TextButton(
                          onPressed: header.actionBtn!.onTap,
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 14.0)),
                            foregroundColor: WidgetStateProperty.all(
                                ColorScheme.of(context).onSurface),
                            side: WidgetStateProperty.all(
                              BorderSide(
                                width: 1.0,
                                color: appearanceState.lerpBgColor(0.05),
                              ),
                            ),
                            shape:
                                WidgetStateProperty.all(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            )),
                          ),
                          child: Text(header.actionBtn!.text,
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
