import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/view/components/buttons.dart';
import 'package:music_player/view/components/inputs.dart' show SelectInput;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';

class PluginsList extends StatelessWidget {
  const PluginsList(
    this.data,
    this.curr, {
    super.key,
    required this.onDownloadTap,
    required this.onInfoTap,
    required this.onPageTap,
    required this.onSortChange,
    required this.selectInitial,
  });

  final dynamic data;
  final int curr;
  final void Function(String name) onDownloadTap;
  final void Function(String name) onInfoTap;
  final void Function(int) onPageTap;
  final void Function(String orderBy, String orderDirection) onSortChange;

  final (String, String)? selectInitial;

  @override
  Widget build(BuildContext context) {
    final List plugins = data['plugins'];
    final int count = data['count'];
    final int limit = data['limit'];
    final int last = (count / limit).ceil();
    final List? sortBy = data['sort_by'];

    Widget? selectInput;
    if (sortBy != null && sortBy.isNotEmpty) {
      if (sortBy[0] is Map &&
          !([
            sortBy[0]['order_by'],
            sortBy[0]['order_direction'],
            sortBy[0]['text']
          ].every((el) => el is String))) {
        gLogger.error('Bad sortBy structure');
      } else {
        final List<((String, String), String)> elements = sortBy.expand((el) {
          return [
            (
              (el['order_by'] as String, el['order_direction'] as String),
              (el['text'] as String)
            ),
          ];
        }).toList();
        final (String, String) initial = selectInitial ?? elements[0].$1;

        selectInput = SelectInput<(String, String)>(
          elements: elements,
          initial: initial,
          onSelect: (v) {
            gLogger.debug('value: $v');
            var (orderBy, orderDirection) = v!;
            onSortChange(orderBy, orderDirection);
          },
          isCompact: true,
        );
      }
    }

    final colorScheme = ColorScheme.of(context);

    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    final itemBgColor = appearanceState
        .lerpBgColor(0.03)
        .withAlpha(appearanceState.overBgAlpha);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (selectInput != null) ...[
              selectInput,
              const SizedBox(width: 14),
            ],
            Text('${count} ${lang.plugins__genetive}'),
          ],
        ),
        const SizedBox(height: 16),
        for (var el in plugins) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: appearanceState.lerpBgColor(0.07), width: 1.0),
              borderRadius: BorderRadius.circular(12.0),
              color: itemBgColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        "${el['name']}",
                        style: TextStyle(
                          fontSize: 16,
                          letterSpacing: 0.75,
                          color: colorScheme.secondary,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 2,
                        minLines: 1,
                      ),
                      const SizedBox(width: 12.0),
                      if (el['approved_by'] != null && el['approved_by'] != '')
                        Text(
                          "${lang.Approved_by} ${el['approved_by']}",
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              // letterSpacing: 0.75,
                              color: colorScheme.primary),
                        ),
                      SelectableText(
                          el['langs_longtitle'] ??
                              el['longtitle'] ??
                              el['title'],
                          style: const TextStyle(
                              fontSize: 18, letterSpacing: 0.75)),
                      const SizedBox(width: 8.0),
                      SelectableText(
                        el['langs_descr'] ?? el['descr'],
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 6.0),
                      SelectableText(
                        '${lang.Downloads__genetive}: ${el['downloads']}',
                      ),
                      const SizedBox(height: 4.0),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: ColorScheme.of(context).secondary,
                          ),
                          children: [
                            TextSpan(
                              text: '${lang.Author}: ',
                            ),
                            TextSpan(
                              text: "${el['author'] ?? lang.Deleted_User}",
                              style: TextStyle(
                                color: ColorScheme.of(context).secondary,
                                fontStyle: el['author'] == null
                                    ? FontStyle.italic
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AllOutlinedStandardButton(
                        Icon(PhosphorIconsLight.downloadSimple,
                            color: ColorScheme.of(context).onSurface),
                        onTap: () {
                          onDownloadTap(el['name']);
                        },
                      ),
                      const SizedBox(height: 48.0),
                      ToPageButton(
                        '',
                        onTap: () {
                          onInfoTap(el['name']);
                        },
                        padding: const EdgeInsets.only(
                            top: 10.0, bottom: 10.0, right: 10.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18.0),
        ],
        const SizedBox(height: 14.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            border: Border.all(
                color: appearanceState.lerpBgColor(0.07), width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: _Pagination(curr: curr, last: last, onTap: onPageTap),
        ),
      ],
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.curr,
    required this.last,
    required this.onTap,
  });

  final int curr;
  final int last;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    var t = onTap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (curr > 1) _Box('<', onTap: () => t(curr - 1)),
        if (curr > 1) _Box('1', onTap: () => t(1)),
        if (curr > 1 + 2) const _Box('...'),
        if (curr > 1 + 1) _Box('${curr - 1}', onTap: () => t(curr - 1)),
        _Box('$curr', isActive: true, onTap: () => t(curr)),
        if (curr < last - 1) _Box('${curr + 1}', onTap: () => t(curr + 1)),
        if (curr < last - 2) const _Box('...'),
        if (curr < last) _Box('$last', onTap: () => t(last)),
        if (curr < last) _Box('>', onTap: () => t(curr + 1)),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box(this.s, {this.isActive = false, this.onTap});

  final String s;
  final bool isActive;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = ColorScheme.of(context).primary;
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
        child: Text(
          s,
          style: TextStyle(
            fontSize: 16,
            color: isActive ? primary : null,
            fontWeight: isActive ? FontWeight.bold : null,
          ),
        ),
      ),
      onTap: () {
        gLogger.view('hey');
        onTap?.call();
      },
    );
  }
}
