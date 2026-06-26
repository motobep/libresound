enum PlayState {
  playing,
  pause,

  // stopped
  idle,
  notReady,
  loading,
  endOfQueue;

  static PlayState fromString(String s) {
    return PlayState.values.firstWhere((e) => e.name == s, orElse: () {
      assert(false, 'Wrong name "$s"');
      throw 'Wrong name "$s"';
    });
  }
}

enum RepeatState {
  norepeat,
  repeatOne,
  repeatAll,
}

class FsStacks {
  static const all = 'All';
  static const playlists = 'Playlists';
  static const artists = 'Artists';
  static const albums = 'Albums';
  // static const genres = 'Genres';
  static const search = 'Search';
  static const list = [all, playlists, artists, albums, search];
}

class FsTabsNames {
  static const all = FsStacks.all;
  static const playlists = FsStacks.playlists;
  static const artists = FsStacks.artists;
  static const albums = FsStacks.albums;
  static const list = [all, playlists, artists, albums];
}

class PaneType {
  static const sidebar = 'sidebar';
  static const items = 'items';
  static const queue = 'queue';
}

enum LogLevel {
  none,
  dev,
  trace,
}

class SyncPriority {
  static const none = 'none';
  static const self = 'self';
  static const partner = 'partner';
  static const asIs = 'asIs';

  static String getPartnersPriority(String syncPriority) {
    switch (syncPriority) {
      case SyncPriority.self:
        return SyncPriority.partner;
      case SyncPriority.partner:
        return SyncPriority.self;
      case SyncPriority.asIs:
        return SyncPriority.asIs;
      case SyncPriority.none:
        return SyncPriority.none;
      default:
        assert(false, 'Wrong branch');
        return SyncPriority.none; // to shut up compiler
    }
  }
}

enum SyncNotify {
  start,
  finish,
  setText,
  setProgress,
  addError,
}

enum NetworkError {
  none,
  noIp,
  networkUnreachable,
  badActivation,
}

enum ListType {
  tracklist,
  grouplist,
}

enum BodyType {
  items,
  sections,
}

enum WrapperType {
  playlist,
  none,
}

enum NavType {
  tabs,
  searchTabs,
  none,
}

NavType toNavType(String s) {
  return switch (s) {
    'tabs' => NavType.tabs,
    'searchTabs' => NavType.searchTabs,
    _ => NavType.none,
  };
}

WrapperType toWrapperType(String s) {
  return switch (s) {
    'playlist' => WrapperType.playlist,
    _ => WrapperType.none,
  };
}

ListType toListType(String s) {
  return ListType.values.firstWhere((e) => e.toString() == 'ListType.$s',
      orElse: () {
    assert(false, 'Wrong type name "$s"');
    throw 'Wrong type name "$s"';
  });
}

T strToEnum<T extends Enum>(String s, List<T> values) {
  return values.firstWhere((e) => e.name == s, orElse: () {
    assert(false, 'Wrong type name "$s"');
    throw 'Wrong type name "$s"';
  });
}

BodyType toBodyType(String s) {
  return switch (s) {
    'items' => BodyType.items,
    'sections' => BodyType.sections,
    _ => throw Exception('Wrong body type'),
  };
}

enum IconName {
  plus,
  chevron_right,
  clear,
  playlist,
  trash_can,
  artist,
  minus,
  remove,
  download,
  shuffle,
  house,
  vinyl_record,
  pencil,
  music_note,
  music_notes,
  heart,
  thumbs_up,
  thumbs_down,
}

IconName? toIconNameOrNull(String? s) {
  return s == null ? null : toIconName(s);
}

IconName toIconName(String s) {
  return IconName.values.firstWhere((e) => e.toString() == 'IconName.$s',
      orElse: () {
    assert(false, 'Wrong icon name "$s"');
    throw 'Wrong icon name "$s"';
  });
}

// TODO: use queue by default. Move settings to plugins ('settings' controls stays as optional)
List<String> allowedRightControls = ['search', 'settings', 'queue'];

enum Pages {
  settings,
  appearance,
  sync,
  plugins,
  source,
}

enum KeyEventType {
  down,
  up,
  repeat,
}

typedef Bindings = Map<String, void Function()>;

enum KeyboardAction {
  toggle_playback,
  play_prev,
  play_next,
  shuffle,
  toggle_repeat,
  show_current_item_dialog,
  choose,
  focus_up,
  focus_down,
  to_bottom,
  to_top,
  focus_left_pane,
  focus_right_pane,
  to_prev_tab,
  to_next_tab,
  back,
  show_item_dialog,
  focus_search,
  unfocus,
  prev_suggestion,
  next_suggestion,
}

enum DownloadType {
  play,
  download;

  static DownloadType fromString(String s) {
    return DownloadType.values.firstWhere((e) => e.name == s, orElse: () {
      assert(false, 'Wrong name "$s"');
      throw 'Wrong name "$s"';
    });
  }
}

enum AmbientMode {
  off,
  playback,
  all;

  String toJson() {
    return name;
  }

  static AmbientMode fromJson(String s) {
    return AmbientMode.values.firstWhere((e) => e.name == s, orElse: () {
      assert(false, 'Wrong name "$s"');
      throw 'Wrong name "$s"';
    });
  }
}

enum OpenDegree {
  closed,
  middle,
  opened,
}

enum PageDescrType {
  music,
  controls,
  webView,
}
