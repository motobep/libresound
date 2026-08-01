// ignore_for_file: prefer_initializing_formals

import 'dart:io' show File;

import 'package:m4a_tags_handler/Tags.dart';
import 'package:mp3_info/mp3_info.dart';

import 'package:music_player/logger.dart';
import 'package:music_player/logic/Item.dart';
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/fs/files.dart' as fs;
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/utils.dart' show formatDuration;

/* Proposal: Tile type to represent gui for MusicItem and GroupItem.
It will have link to the original object */

class MusicItem implements Item {
  MusicItem.fromFile(
    String filepath,
    this.tags, {
    required this.sourceId,
  })  : id = filepath,
        filepath = filepath,
        artistId = tags.artist,
        albumId = tags.album,
        extension = fs.getExtension(filepath);

  MusicItem.directly(
    this.id,
    this.tags, {
    String? subtitle,
    required this.sourceId,
    this.extension = '',
    this.duration = const Duration(seconds: 0),
    this.artistId,
    this.albumId,
    this.thumbnailUrl,
    this.props,
  }) : _subtitle = subtitle;

  // Create shallow copy. But property itemDialogDescr cloned as well
  MusicItem clone() {
    MusicItem mi = MusicItem.directly(
      id,
      tags,
      subtitle: _subtitle,
      thumbnailUrl: thumbnailUrl,
      sourceId: sourceId,
      extension: extension,
      duration: duration,
      artistId: artistId,
      albumId: albumId,
      props: props,
    );
    mi.filepath = filepath;
    mi.url = url;
    return mi;
  }

  void set(MusicItem mi) {
    id = mi.id;
    tags = mi.tags;
    _subtitle = mi._subtitle;
    sourceId = mi.sourceId;
    extension = mi.extension;
    duration = mi.duration;
    artistId = mi.artistId;
    albumId = mi.albumId;
    filepath = mi.filepath;
    url = mi.url;
    thumbnailUrl = mi.thumbnailUrl;
    props = mi.props;
  }

  // Attributes
  @override
  String id;
  String extension;

  @override
  String get subtitle {
    return _subtitle ?? artistName;
  }

  String? _subtitle;

  @override
  PictureTag? get picture {
    return tags.picture;
  }

  @override
  set picture(PictureTag? picture) {
    tags.picture = picture;
  }

  String? filepath;
  String? url;
  @override
  String? thumbnailUrl;
  @override
  KeyValue? props;

  Duration duration = const Duration(seconds: 0);
  Tags tags;

  @override
  String sourceId;
  // End Attributes

  //Tag getters
  @override
  String get title {
    return tags.title ?? lang.Unknown_Title;
  }

  // Proposal: make multiple artists, albums

  String? artistId;
  String? albumId;
  String get artistName {
    return tags.artist ?? lang.Unknown_Artist;
  }

  String get album {
    return tags.album ?? lang.Unknown_Album;
  }

  String get year {
    return tags.year ?? lang.Unknown_Year;
  }

  String get track {
    return tags.track ?? lang.Unknown_Track;
  }

  String get genre {
    return tags.genre ?? lang.Unknown_Genre;
  }

  String get time {
    return formatDuration(duration);
  }

  int get durationInSeconds {
    return duration.inSeconds;
  }

  void fetchDuration() {
    if (extension != '.mp3') {
      logger.warn('Not mp3 fetchDuration');
      return;
    }
    logger.trace('mp3 fetchDuration');
    try {
      final mp3 = MP3Processor.fromFile(File(filepath!));
      duration = mp3.duration;
      logger.log('mp3 "$id" duration: $duration');
    } catch (e) {
      logger.error('Exception while fetching mp3 "$id" duration: $e');
    }
  }

  Map<String, dynamic> toFilepathKeyMap() {
    return {
      filepath!.split('/').last: {
        'title': tags.title,
        'artist': tags.artist,
        'album': tags.album,
        'year': tags.year,
        'track': tags.track,
        'genre': tags.genre,
        'duration': durationInSeconds,
        'hasPicture': tags.picture != null,
        'extension': extension,
      }
    };
  }

  /// From json map
  static MusicItem fromJson(dynamic miJs, {required String sourceId}) {
    String id = miJs['id'];
    var artist = miJs['artist'];
    var album = miJs['album'];
    Tags tags = Tags(
      title: miJs['title'],
      artist: artist != null ? artist['title'] : null,
      album: album != null ? album['title'] : null,
    );

    String ext = miJs.containsKey('extension')
        ? miJs['extension']
        : '.mp3'; // defaults to '.mp3'

    MusicItem mi = MusicItem.directly(
      id,
      tags,
      subtitle: miJs['subtitle'],
      artistId: artist != null ? artist['id'] : null,
      albumId: album != null ? album['id'] : null,
      sourceId: sourceId,
      duration: Duration(seconds: miJs['duration'] ?? 0),
      extension: ext,
      thumbnailUrl: miJs['thumbnailUrl'],
      props: miJs['props'],
    );
    mi.filepath = miJs['filepath'];
    mi.url = miJs['url'];
    return mi;
  }

  @override
  Map toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'title': title,
      'subtitle': _subtitle,
      'artist': {
        'id': artistId,
        'title': artistName,
      },
      'album': {
        'id': albumId,
        'title': album,
      },
      'year': year,
      'track': track,
      'genre': genre,
      'duration': durationInSeconds,
      'hasPicture': tags.picture != null,
      'filepath': filepath,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'extension': extension,
      'props': props,
    };
  }

  static MusicItem dummy() {
    return MusicItem.directly(
      'dummy.mp3',
      Tags(),
      sourceId: 'null',
    );
  }

  static final Logger logger = Logger(prefix: 'MusicItem: ');
}
