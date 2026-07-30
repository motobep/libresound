import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/states/FocusState.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:provider/provider.dart';

import 'package:music_player/states/AppearanceState.dart';

import 'package:music_player/view/App.dart' show bindingsHandler;

typedef SuggestionsType = List<(IconData, String)>;
const double borderRadius = 20;

class SearchAutocomplete extends StatefulWidget {
  SearchAutocomplete({
    super.key,
    required this.hintText,
    required this.onSubmitted,
    required this.getSuggestions,
    this.debounceDelay = const Duration(milliseconds: 300),
    required this.focusNode,
    required this.isWideSuggestions,
    this.initial = '',
    this.prefixIcon,
    this.boxBg,
    this.contentPadding,
  }) {
    _getSuggestionsDebounced =
        _debounce<SuggestionsType?, String>(getSuggestions, debounceDelay);
  }

  final String hintText;
  final void Function(String s) onSubmitted;
  final Future<List<(IconData, String)>?> Function(String s) getSuggestions;
  final Duration debounceDelay;
  final FocusNode focusNode;
  final bool isWideSuggestions;
  final String initial;
  final Widget? prefixIcon;
  final Color? boxBg;
  final EdgeInsets? contentPadding;

  late final _Debounceable<SuggestionsType?, String> _getSuggestionsDebounced;

  @override
  State<SearchAutocomplete> createState() => _SearchAutocomplete();
}

class _SearchAutocomplete extends State<SearchAutocomplete> {
  late final TextEditingController _textEditingController =
      TextEditingController(text: widget.initial);
  final OverlayPortalController _tooltipController = OverlayPortalController();

  RenderBox? _targetRenderBox;

  List<(IconData, String)> suggestions = [];
  int sugIndex = -1;

  void Function()? _focusListener;

  @override
  void initState() {
    super.initState();

    final f = Provider.of<FocusManagerState>(context, listen: false);

    if (f.isEnabled) {
      // WARNING: bindings work for all SearchAutocompletes on the page at the same time
      // Proposal: use state.
      final map = bindingsHandler.keyBindingsMap;
      // TODO later: Free handlers on dispose
      final prevKb = map['Input.${KeyboardAction.prev_suggestion.name}'];
      prevKb!.handler = () {
        gLogger.view('prev');
        if (suggestions.isEmpty) return;

        if (sugIndex == 0 || sugIndex == -1) {
          var sugTail = suggestions.length - 1;
          sugIndex = sugTail;
        } else {
          sugIndex--;
        }
        var s = suggestions[sugIndex];
        _textEditingController.text = s.$2;
        setState(() {});
        return null;
      };
      final nextKb = map['Input.${KeyboardAction.next_suggestion.name}'];
      nextKb!.handler = () {
        gLogger.view('next');
        if (suggestions.isEmpty) return;

        var sugTail = suggestions.length - 1;
        if (sugIndex == sugTail || sugIndex == -1) {
          sugIndex = 0;
        } else {
          sugIndex++;
        }
        var s = suggestions[sugIndex];
        _textEditingController.text = s.$2;
        setState(() {});
        return null;
      };
      prevKb.activate();
      nextKb.activate();

      _focusListener = f.getInputFocusListener(widget.focusNode);
      widget.focusNode.addListener(_focusListener!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _targetRenderBox = context.findRenderObject() as RenderBox?;
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (_focusListener != null) {
      widget.focusNode.removeListener(_focusListener!);
    }
    super.dispose();
  }

  Future<void> setSuggestions(String s) async {
    SuggestionsType? sugs = await widget._getSuggestionsDebounced(s);
    if (sugs == null) return;
    setState(() {
      if (sugs.length >= 8) {
        suggestions = sugs.sublist(0, 8);
      } else {
        suggestions = sugs.sublist(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    if (_targetRenderBox == null) return Container();
    _targetRenderBox = context.findRenderObject() as RenderBox;
    if (_targetRenderBox == null) return Container();
    final position = _targetRenderBox!.localToGlobal(Offset.zero);
    var boxWidth = _targetRenderBox!.size.width;

    final textBtnStyle = TextButton.styleFrom(
      foregroundColor: ColorScheme.of(context).onSurface,
      overlayColor: appearanceState.lerpBgColor(0.45),
      padding: const EdgeInsets.all(0),
    );

    bool isShowSuggestions =
        suggestions.isNotEmpty && widget.focusNode.hasFocus;
    bool isRoundCorners = !isShowSuggestions || widget.isWideSuggestions;

    return OverlayPortal(
      controller: _tooltipController,
      overlayChildBuilder: (BuildContext context) {
        return isShowSuggestions
            ? Suggestions(
                isWide: widget.isWideSuggestions,
                suggestions: suggestions,
                sugIndex: sugIndex,
                position: position,
                boxWidth: boxWidth,
                boxBg: widget.boxBg,
                onTap: (String s) {
                  gLogger.view('selected: ${s}');
                  _textEditingController.text = s;
                  setState(() {
                    suggestions = [];
                  });

                  widget.focusNode.unfocus();

                  widget.onSubmitted(s);
                },
                onFill: (String s) {
                  // On fill search text
                  gLogger.view('fill clicked');
                  _textEditingController.value =
                      _textEditingController.value.copyWith(
                    text: s,
                    selection: TextSelection.collapsed(offset: s.length),
                  );
                  sugIndex = -1;
                  setSuggestions(s);
                },
              )
            : const SizedBox.shrink();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(borderRadius),
            topRight: const Radius.circular(borderRadius),
            bottomLeft: Radius.circular(isRoundCorners ? borderRadius : 0),
            bottomRight: Radius.circular(isRoundCorners ? borderRadius : 0),
          ),
          color: widget.boxBg,
        ),
        child: Focus(
          onFocusChange: (f) async {
            if (f == true) {
              gLogger.view('onFocus');
              sugIndex = -1;
              _tooltipController.show();

              var s = _textEditingController.value.text;
              setSuggestions(s);
            } else {
              gLogger.view('onFocusLost');
              _tooltipController.hide();

              setState(() {});
            }
          },
          child: TextField(
            controller: _textEditingController,
            focusNode: widget.focusNode,
            style: const TextStyle(fontSize: 14),
            cursorColor: Colors.grey,
            selectAllOnFocus: false,
            decoration: InputDecoration(
              constraints: const BoxConstraints(maxHeight: 42),
              contentPadding: widget.contentPadding,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide.none),
              hintText: widget.hintText,
              hintStyle:
                  const TextStyle(color: Colors.grey, fontSize: 14, height: 1),
              prefixIcon: widget.prefixIcon,
              suffixIcon: TextButton(
                style: textBtnStyle,
                onPressed: () {
                  // On clear search text
                  _textEditingController.text = '';
                  setSuggestions(_textEditingController.text);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: const Icon(
                    PhosphorIconsThin.x,
                    size: 24,
                  ),
                ),
              ),
            ),
            onSubmitted: (s) async {
              // On submitted search text
              widget.onSubmitted(s);
            },
            onChanged: (s) async {
              // On change user search text
              gLogger.view('change: $s');
              sugIndex = -1;
              setSuggestions(s);
            },
            onTapOutside: (event) {
              gLogger.view('onTapOutside');
              widget.focusNode.unfocus();
            },
          ),
        ),
      ),
    );
  }
}

class Suggestions extends StatelessWidget {
  const Suggestions({
    super.key,
    required this.suggestions,
    required this.sugIndex,
    required this.position,
    required this.boxWidth,
    required this.onTap,
    required this.onFill,
    required this.isWide,
    this.boxBg,
  });

  final List<(IconData, String)> suggestions;
  final int sugIndex;

  final Offset position;
  final double boxWidth;

  final void Function(String) onTap;
  final void Function(String) onFill;

  final bool isWide;

  final Color? boxBg;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    Color dividerColor = appearanceState.lerpBgColor(0.15);

    double vw = MediaQuery.of(context).size.width;
    double vh = MediaQuery.of(context).size.height;

    double suggestionsHeight = min(
        min(CONFIG.suggestionExtent * 8,
            CONFIG.suggestionExtent * suggestions.length),
        vh * 0.8);

    double top = position.dy + 42;
    double left = position.dx;
    double width = boxWidth;
    var borderRadiusObj = const BorderRadius.only(
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    if (isWide) {
      top += 5;
      left = 0;
      width = vw;
      borderRadiusObj = const BorderRadius.only();
    }

    final textBtnStyle = TextButton.styleFrom(
      foregroundColor: ColorScheme.of(context).onSurface,
      overlayColor: appearanceState.lerpBgColor(0.45),
      padding: const EdgeInsets.all(0),
    );

    return Positioned(
      top: top,
      left: left,
      child: Column(
        children: [
          Container(
              width: boxWidth, height: isWide ? 0 : 1, color: dividerColor),
          TextFieldTapRegion(
            child: Container(
              width: width,
              height: suggestionsHeight,
              decoration: BoxDecoration(
                borderRadius: borderRadiusObj,
                color: boxBg,
              ),
              clipBehavior: Clip.hardEdge,
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  itemExtent: CONFIG.suggestionExtent,
                  itemBuilder: (context, index) {
                    var (icon, s) = suggestions[index];
                    return TextButton(
                      style: textBtnStyle.copyWith(
                        backgroundColor: index == sugIndex
                            ? WidgetStatePropertyAll(
                                appearanceState.focusSuggestionColor())
                            : null,
                        shape: const WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.zero))),
                      ),
                      onPressed: () {
                        onTap(s);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 12, top: 10.0, bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(icon, size: 20.0),
                                const SizedBox(width: 14),
                                SizedBox(
                                  width: boxWidth - 120,
                                  child: Text(s,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1),
                                ),
                              ],
                            ),
                            TextButton(
                              style: textBtnStyle,
                              onPressed: () {
                                onFill(s);
                              },
                              child: const Icon(PhosphorIconsLight.arrowUpLeft,
                                  size: borderRadius),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

/// Wraps a function making it debounced (Called with a delay).
_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> func, Duration delay) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.completer.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer(delay);
    try {
      await debounceTimer!.completer.future;
    } catch (error) {
      gLogger.view('new call');
      if (error is _CancelException) return null;
      rethrow;
    }
    return func(parameter);
  };
}

// A wrapper around Timer used for debouncing.
class _DebounceTimer {
  _DebounceTimer(Duration delay) {
    _timer = Timer(delay, _onComplete);
  }

  final Completer<void> completer = Completer<void>();
  late final Timer _timer;

  void cancel() {
    _timer.cancel();
    completer.completeError(const _CancelException());
  }

  void _onComplete() {
    completer.complete();
  }
}

class _CancelException implements Exception {
  const _CancelException();
}

Future<T?> Function(String) makeRelevantCall<T>(
    Future<T> Function(String) func) {
  String? currStr;

  return (String str) async {
    currStr = str;
    T val = await func(str);

    // If another search happened after this one, throw away these options.
    if (currStr != str) {
      gLogger.view('throwed away');
      return null;
    }
    currStr = null;
    return val;
  };
}
