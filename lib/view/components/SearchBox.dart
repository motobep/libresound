import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:provider/provider.dart';

import 'package:music_player/logic/Source.dart';

import 'package:music_player/states/AppState.dart';

import 'package:music_player/view/components/SearchAutocomplete.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.focusNode,
    this.prefixIcon,
    this.boxBg,
    this.contentPadding,
  });

  final FocusNode focusNode;
  final Widget? prefixIcon;
  final Color? boxBg;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    bool isShowSearch =
        context.select<AppState, bool>((s) => s.currentSource.isShowSearch);
    bool isWideSugs = !context.select<AppState, bool>((s) => s.isWide);

    AppState appState = Provider.of<AppState>(context, listen: false);
    Source source = context.select<AppState, Source>((s) => s.currentSource);

    final searchHelper = _SearchHelper(appState);

    List<String> suggestions = context.select<AppState, List<String>>(
        (s) => s.searchSuggestionsStorage.value);
    SuggestionsType suggestionsRecent = suggestions
        .map<(IconData, String)>(
            (el) => (PhosphorIconsThin.clockCounterClockwise, el))
        .toList();

    Future<SuggestionsType> getSuggestions(String s) async {
      var got = await source.getSuggestionsAsync(s);
      if (got == null) {
        return suggestionsRecent;
      }
      var suggestionsSearched = got
          .map<(IconData, String)>(
              (el) => (PhosphorIconsThin.magnifyingGlass, el))
          .toList();
      return suggestionsSearched + suggestionsRecent;
    }

    final lang = context.select<AppearanceState, Lang>((s) => s.lang);

    return isShowSearch
        ? SearchAutocomplete(
            focusNode: focusNode,
            isWideSuggestions: isWideSugs,
            hintText: lang.Search,
            onSubmitted: (s) {
              gLogger.view('search: $s');
              searchHelper.search(s);

              // Close search box after search
              appState.isSearchToggled = false;
              appState.update();
            },
            getSuggestions: (s) async {
              var getRelevantSuggestions =
                  makeRelevantCall<SuggestionsType>(getSuggestions);
              return await getRelevantSuggestions(s);
            },
            debounceDelay: source.debounceDelay,
            prefixIcon: prefixIcon,
            boxBg: boxBg,
            contentPadding: contentPadding,
          )
        : const SizedBox.shrink();
  }
}

class _SearchHelper {
  _SearchHelper(this.appState)
      : source = appState.currentSource;

  final AppState appState;
  final Source source;

  Future<void> search(String s, [String cat = '']) async {
    gLogger.view('Search Btn clicked');

    try {
      await source.searchAsync(s);
    } catch (e) {
      gLogger.error('Exception in searchAsync: $e');
    }

    // Save suggestion
    appState.searchSuggestionsStorage.addAndSave(s);

    appState.update();
  }
}
