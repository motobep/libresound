import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as pathPkg;
import 'package:crypto/crypto.dart' as crypto;
import 'package:collection/collection.dart';

import 'package:music_player/logger.dart';
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/fs/m3u.dart' as m3u;
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/ws/FileDTO.dart';
import 'package:music_player/logic/ws/FileListInfoDTO.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/config.dart' show fileSystem;
import 'package:music_player/logic/UiNotification.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/fs/files.dart' as fs;
import 'package:music_player/logic/fs/filesHighLevel.dart' as fsHighLevel;
import 'package:music_player/logic/network.dart' as network;
import 'package:music_player/logic/ws/Message.dart';
import 'package:music_player/logic/ws/WsChannel.dart';

const bool _isTest = false;

final Map<String, String> _exceptionToText = {
  'PathAccessException': lang.Unable_to_access_path,
  'PathNotFoundException': lang.Path_not_found,
  'FileSystemException': lang.File_system_error,
  'FetchDirectoryFilesException': lang.Unable_to_read_directory,
  'UndefindException': lang.Undefind_error,
};

class WsHandler {
  WsHandler(
    this.ip,
    this.getMusicSourceDir, {
    required this.getPlaylistsDir,
    required this.notifyUiCallback,
    required this.interruptCallback,
    required this.connectHandler,
    required this.closeHandler,
  });

  WsHandler.test(
    this.ip,
    this.getMusicSourceDir, {
    required this.getPlaylistsDir,
    required this.notifyUiCallback,
    required this.interruptCallback,
  }) {
    connectHandler = () {
      logger.trace('test - connectHandler');
    };
    closeHandler = () {
      logger.trace('test - closeHandler');
    };
  }

  String ip;
  int get serverPort {
    if (socketsServer == null) return -1;
    return socketsServer!.port;
  }

  String Function() getMusicSourceDir;
  String Function() getPlaylistsDir;

  final void Function(UiNotification) notifyUiCallback;
  final Future<String> Function(String) interruptCallback;
  late void Function() connectHandler;
  late void Function() closeHandler;

  WsChannel? currChannel;
  ServerSocket? socketsServer;

  bool isSyncing = false;
  String _syncPriority = SyncPriority.none;

  Queue<Message> _transactionQueue = Queue<Message>();

  String _loggingName = '';

  bool isConnectionOpenOrConnecting() {
    return currChannel != null && currChannel!.isOpenOrConnecting();
  }

  // SERVER start
  /// Throws
  Future<void> startServer() async {
    assert(socketsServer == null, 'Server must be null');
    _loggingName = 'Server';
    logger = Logger(prefix: ' 🎯 WS [$_loggingName]:');

    var port = await network.getUnusedPort(ip);
    socketsServer = await ServerSocket.bind(ip, port);

    socketsServer!.listen((Socket serverSock) {
      // NOTICE: only one server Channel at a time must exist
      try {
        currChannel = WsChannel(
            WebSocket.fromUpgradedSocket(
              serverSock,
              serverSide: true,
            ),
            WsChannel.serverType);
        _listen(_listenHandler);
      } on SocketException catch (e) {
        logger.error(e.message);
        assert(false, 'shouldn\'t be here');
        rethrow;
      } catch (e) {
        logger.error(e);
        assert(false, 'shouldn\'t be here');
        rethrow;
      }
      _onServerConnectHandler();
    }, onDone: () {
      logger.log('socketsServer done');
    }, onError: (e) {
      logger.error('socketsServer error: $e');
    });

    logger.trace(
        'Serving at tcp server://${socketsServer!.address.host}:${socketsServer!.port}');
  }

  Future<void> stopServer() async {
    assert(socketsServer != null);
    logger.log('Stopping server');
    await socketsServer!.close();
    socketsServer = null;
  }

  Future<void> _onServerConnectHandler() async {
    logger.trace('Connection established');
    connectHandler();
  }
  // SERVER end

  // CLIENT start
  Future<bool> connect(String ip, int port) async {
    _loggingName = 'Client';
    logger = Logger(prefix: ' 🔎 WS [$_loggingName]:');

    logger.trace('Connecting to $ip:$port');
    try {
      currChannel = WsChannel(
          WebSocket.fromUpgradedSocket((await Socket.connect(ip, port)),
              serverSide: false),
          WsChannel.clientType);
    } on SocketException {
      logger.error('Exception connecting to server: SocketException');
      return false;
    } catch (e) {
      logger.error('Unexpected exception in connect(): $e');
      return false;
    }

    _listen(_listenHandler);
    logger.trace('Connection established');

    connectHandler();
    return true;
  }
  // CLIENT part end

  Future<void> closeCurrChannel() async {
    assert(currChannel != null, 'Currrent channel is null');
    await currChannel!.close();
    logger.trace('Currrent channel closed');
  }

  StreamSubscription<dynamic>? _listen(void Function(dynamic)? listenHandler) {
    assert(currChannel != null, 'Currrent channel is null');
    _transactionQueue = Queue.from([]);
    return currChannel!.socket.listen(listenHandler,
        onDone: _onDoneHandler, onError: _onErrorHandler, cancelOnError: true);
  }

  Future<void> _onDoneHandler() async {
    logger.trace('Stream done');
    assert(currChannel != null, 'Currrent channel is null');

    var readyState = currChannel!.socket.readyState;
    var closeCode = currChannel!.socket.closeCode;

    logger.log('readyState=$readyState, closeCode=$closeCode');

    if (isConnectionOpenOrConnecting()) {
      currChannel!.close();
    }

    isSyncing = false;
    closeHandler();
  }

  Future<void> _onErrorHandler(e) async {
    logger.error('Error in stream: $e');
    await closeCurrChannel();
    isSyncing = false;
    logger.log('use closeHandler() in _onErrorHandler()?');
    // QUESTION: Should here be closeHandler() ?
  }

  void _listenHandler(dynamic payload) async {
    Message message = Message.fromBytes(payload as Uint8List);
    var header = message.header;

    switch (header['type']) {
      case 'START_SYNCING':
        logger.log('START_SYNCING.version=${header['version']}');
        isSyncing = true;
        _syncPriority = SyncPriority.none;
        _notify(SyncNotify.start);
        _send(ackStartSyncMsg);
        break;
      case 'END_SYNCING':
        isSyncing = false;
        _sendType('ACK');
        _notify(SyncNotify.finish);
        break;
      case 'PASS_TRANSACTIONS':
        String json = utf8.decode(message.body);
        List<KeyValue> list = jsonDecode(json).cast<KeyValue>();
        assert(_transactionQueue.isEmpty, 'Queue must be empty');
        for (var el in list) {
          _transactionQueue.add(Message.header(el));
        }
        _syncPriority = message.header['priority'];
        await _executeNextTransaction();
        break;
      case 'ACK_START_SYNCING':
        logger.log('ACK_START_SYNCING.version=${header['version']}');

        // If it's END_SYNCING ACK we don't have transactions
        if (_transactionQueue.isNotEmpty) {
          await _executeNextTransaction();
        }
        break;
      case 'ACK':
        // If it's END_SYNCING ACK we don't have transactions
        if (_transactionQueue.isNotEmpty) {
          await _executeNextTransaction();
        }
        break;
      // Download usage starts, when reciever asks for list info
      case 'GET_FILE_LIST':
        final target = header['target'];
        try {
          FileInfoList dto = _fetchFileInfoList(target);
          // TODO: test check
          var resp =
              Message({'type': 'FILE_LIST', 'target': target}, dto.toBytes());
          _send(resp);

          logger.log('Uploading file list $target');
        } catch (e) {
          logger.error('Error during GET_FILE_LIST: $e');

          Message msg;
          switch (e.runtimeType) {
            case fs.FetchDirectoryFilesException:
              String errName = e.runtimeType.toString();
              String errNameForUser = _exceptionToText[errName]!;
              _notify(SyncNotify.addError, '$errNameForUser: $target');
              msg = Message.header({
                'type': 'ERROR',
                'err': {'name': errName, 'message': target}
              });
              break;
            default:
              String errName = 'UndefindException';
              String errNameForUser = _exceptionToText[errName]!;
              _notify(SyncNotify.addError, errNameForUser);
              msg = Message.header({
                'type': 'ERROR',
                'err': {'name': errName}
              });
          }
          _send(msg);
        }
        break;
      case 'FILE_LIST':
        final String target = header['target'];
        logger.trace('FILE_LIST: $target');
        _fileInfoListMap[target] = FileInfoList.fromBytes(message.body);

        logger.log('Downloading file list $target');
        await _executeNextTransaction();
        break;
      case 'REQUEST_FILE':
        _notify(SyncNotify.setText, lang.Sending_files);
        String filename = header['filename'] as String;

        // Update progress
        String progress = header['progress'];
        _updateProgress(filename, progress, 'Sending');

        if (_isTest &&
            CONFIG.isDev() &&
            filename == 'Server-non_existent.mp3') {
          String dirpath = _getDirpathForFilename(filename);
          String path = '$dirpath/$filename';
          await fsHighLevel.deleteFilesAsync([path]);
        }

        // Send file
        logger.trace('Sending file: "$filename"');
        try {
          final dirpath = _getDirpathForFilename(filename);

          final originalFile = fileSystem.file('$dirpath/$filename');
          FileDTO dto;
          if (filename.endsWith('.m3u')) {
            // Unprefix m3u records
            gLogger.debug('send m3u ${filename}');
            // TODO: handle possible exception
            String contents = originalFile.readAsStringSync();

            String musicDirRelativeToPlaylistsDir =
                pathPkg.relative(getMusicSourceDir(), from: getPlaylistsDir());
            gLogger.debug('send relative: $musicDirRelativeToPlaylistsDir');
            var (newContents, err) = m3u.unPrefixM3uPaths(
                contents, '$musicDirRelativeToPlaylistsDir/');
            if (err != null) {
              gLogger.exception('Failed prefixing', err);
              dto = FileDTO.fromFile(originalFile);
            } else {
              // gLogger.warn('contents: $contents');
              // gLogger.blue('newContents: $newContents');
              Uint8List bContents = utf8.encode(newContents);

              dto = FileDTO(filename, bContents);
            }
          } else {
            dto = FileDTO.fromFile(originalFile);
          }
          // TODO: test check
          var msg = Message({'type': 'FILE'}, dto.toBytes());
          _send(msg);
        } catch (e) {
          logger.error('Error during REQUEST_FILE: $e');
          logger.error('  runtimeType: ${e.runtimeType}');

          Message msg;
          switch (e.runtimeType) {
            case PathAccessException:
            case PathNotFoundException:
              String errName = e.runtimeType.toString();
              String errNameForUser = _exceptionToText[errName]!;
              _notify(SyncNotify.addError, '$errNameForUser: $filename');
              msg = Message.header({
                'type': 'ERROR',
                'err': {'name': errName, 'message': filename}
              });
              break;
            case FileSystemException:
              String errName = e.runtimeType.toString();
              String errNameForUser = _exceptionToText[errName]!;
              _notify(SyncNotify.addError, errNameForUser);
              msg = Message.header({
                'type': 'ERROR',
                'err': {'name': errName}
              });
              break;
            default:
              String errName = 'UndefindException';
              String errNameForUser = _exceptionToText[errName]!;
              _notify(SyncNotify.addError, errNameForUser);
              msg = Message.header({
                'type': 'ERROR',
                'err': {'name': errName}
              });
          }
          _send(msg);
        }

        break;
      case 'FILE':
        // Saving
        FileDTO dto = FileDTO.fromBytes(message.body);
        logger.trace('Saving file: "${dto.filename}"');
        final dirpath = _getDirpathForFilename(dto.filename);
        var f = fileSystem.file('$dirpath/${dto.filename}');
        // TODO: test check

        if (dto.filename.endsWith('.m3u')) {
          // Prefix m3u records
          gLogger.debug('file m3u ${dto.filename}');
          String contents = utf8.decode(dto.bContents);

          String musicDirRelativeToPlaylistsDir =
              pathPkg.relative(getMusicSourceDir(), from: getPlaylistsDir());
          gLogger.debug('file relative: $musicDirRelativeToPlaylistsDir');
          var (newContents, err) =
              m3u.prefixM3uPaths(contents, musicDirRelativeToPlaylistsDir);
          if (err != null) {
            gLogger.exception('Failed prefixing', err);
          } else {
            // gLogger.warn('contents: $contents');
            // gLogger.blue('newContents: $newContents');
            fs.writeToFile(f.path, newContents);
          }
        } else {
          fs.writeToFileAsBytes(f, dto.bContents);
        }

        await _executeNextTransaction();
        break;
      case 'ERROR':
        var err = message.header['err'];
        // Handling error
        String prefix = '(${lang.Error_from_partner})';
        String errName = err['name'];
        String errNameForUser = _exceptionToText[errName] ?? errName;
        logger.error('Error from partner: $errName');
        if (errName == 'PathAccessException' ||
            errName == 'PathNotFoundException' ||
            errName == 'FetchDirectoryFilesException') {
          String errMessage = err['message'];
          _notify(SyncNotify.addError, '$prefix $errNameForUser: $errMessage');
        } else {
          _notify(SyncNotify.addError, '$prefix $errNameForUser');
        }

        await _executeNextTransaction();
        break;
      case 'PING':
        sendPing();
        break;
      default:
        assert(true, 'WRONG BRANCH');
        break;
    }
  }

  bool _checkPlaylistsConfilcts(FileInfoList got, FileInfoList my) {
    const eq = ListEquality();
    for (var g in got.list) {
      for (var m in my.list) {
        if (g.filename == m.filename) {
          if (g.size != m.size) {
            logger.blue('size diff - gotDto: $g; myDto $m');
            return true;
          }
          if (!eq.equals(g.hash, m.hash)) {
            logger.blue('hash diff - gotDto: $g; myDto $m');
            return true;
          }
          break;
        }
      }
    }
    return false;
  }

  void _updateProgress(String filename, String progress, String action) {
    _notify(SyncNotify.setProgress, progress);
  }

  void sync() {
    _transactionQueue = Queue.from([
      startSyncMsg,
      getMp3Msg,
      getM4aMsg,
      getM3uMsg,
      Message.header({'type': '_DIFF'}),
      Message.header({
        'type': '_DOWNLOAD_FILES'
      }), // it's a fake message only used in _executeNextTransaction()
      Message(
        {'type': 'PASS_TRANSACTIONS'},
        _messagesAsBytes([
          getMp3Msg,
          getM4aMsg,
          getM3uMsg,
          Message.header({'type': '_DIFF'}),
          Message.header({'type': '_DOWNLOAD_FILES'}),
          endSyncMsg,
        ]),
      ),
    ]);
    _executeNextTransaction();
  }

  void download() {
    _transactionQueue = Queue.from([
      startSyncMsg,
      getMp3Msg,
      getM4aMsg,
      getM3uMsg,
      Message.header({'type': '_DIFF'}),
      Message.header({'type': '_DOWNLOAD_FILES'}),
      endSyncMsg,
    ]);
    _executeNextTransaction();
  }

  void clean() {
    _transactionQueue = Queue.from([
      startSyncMsg,
      Message.header({
        'type': '_SET_PRIORITY',
        'priority': SyncPriority.self
      }), // fake messsage
      getMp3Msg,
      getM4aMsg,
      getM3uMsg,
      Message.header({'type': '_CLEAN_DIFF'}),
      Message.header({'type': '_CLEAN_FILES'}), // fake messsage
      endSyncMsg,
    ]);
    _executeNextTransaction();
  }

  static Message startSyncMsg =
      Message.header({'type': 'START_SYNCING', 'version': CONFIG.syncVersion});
  static Message ackStartSyncMsg = Message.header(
      {'type': 'ACK_START_SYNCING', 'version': CONFIG.syncVersion});
  static Message endSyncMsg = Message.header({'type': 'END_SYNCING'});

  final Map<String, FileInfoList> _fileInfoListMap = {
    '.mp3': FileInfoList(),
    '.m4a': FileInfoList(),
    '.m3u': FileInfoList(),
  };

  static Message getMp3Msg =
      Message.header({'type': 'GET_FILE_LIST', 'target': '.mp3'});
  static Message getM4aMsg =
      Message.header({'type': 'GET_FILE_LIST', 'target': '.m4a'});
  static Message getM3uMsg =
      Message.header({'type': 'GET_FILE_LIST', 'target': '.m3u'});

  Uint8List _messagesAsBytes(List<Message> list) {
    List<KeyValue> headers = [];
    for (var el in list) {
      headers.add(el.header);
    }
    String json = jsonEncode(headers);
    return utf8.encode(json);
  }

  Future<void> _executeNextTransaction() async {
    logger.trace('Transactions amount: ${_transactionQueue.length}');
    assert(_transactionQueue.isNotEmpty, 'Must have transactions');

    var msg = _transactionQueue.removeFirst();
    switch (msg.header['type']) {
      case 'START_SYNCING':
        isSyncing = true;
        _syncPriority = SyncPriority.none;
        _notify(SyncNotify.start);
        break;
      case '_SET_PRIORITY':
        _syncPriority = msg.header['priority'];
        await _executeNextTransaction();
        return;
      case '_DIFF':
        for (var target in fs.allowedExt) {
          if (_fileInfoListMap[target]!.list.isEmpty) {
            continue;
          }
          try {
            FileInfoList got = _fileInfoListMap[target]!;
            FileInfoList my = _fetchFileInfoList(target);
            // TODO: test check

            if (target != '.m3u') {
              _fileInfoListMap[target] =
                  FileInfoList.filenameDifference(got, my);
            } else {
              if (_syncPriority == SyncPriority.none &&
                  _checkPlaylistsConfilcts(got, my)) {
                _syncPriority = await interruptCallback('playlists_conflict');
                assert(_syncPriority != SyncPriority.none,
                    'Must be chosen SyncPriority');
              }
              logger.trace('SyncPriority: $_syncPriority');

              // Take difference
              if (_syncPriority == SyncPriority.partner) {
                // logger.log('partner');
                _fileInfoListMap['.m3u'] = FileInfoList.fullDifference(got, my);
              } else {
                // logger.log('else');
                _fileInfoListMap['.m3u'] =
                    FileInfoList.filenameDifference(got, my);
              }
            }
          } catch (e) {
            logger.exception('Diff', e);

            switch (e.runtimeType) {
              case fs.FetchDirectoryFilesException:
                String errNameForUser = lang.Unable_to_read_directory;
                _notify(SyncNotify.addError, '$errNameForUser: $target');
                break;
              default:
                _notify(SyncNotify.addError, lang.Undefind_error);
            }
          }
        }

        await _executeNextTransaction();
        return;
      case '_CLEAN_DIFF':
        for (var target in fs.allowedExt) {
          try {
            FileInfoList got = _fileInfoListMap[target]!;
            FileInfoList my = _fetchFileInfoList(target);
            // TODO: test check
            _fileInfoListMap[target] = FileInfoList.filenameDifference(my, got);
          } catch (e) {
            logger.exception('Clean diff', e);

            switch (e.runtimeType) {
              case fs.FetchDirectoryFilesException:
                String errNameForUser = lang.Unable_to_read_directory;
                _notify(SyncNotify.addError, '$errNameForUser: $target');
                break;
              default:
                _notify(SyncNotify.addError, lang.Undefind_error);
            }
          }
        }

        await _executeNextTransaction();
        return;
      case '_DOWNLOAD_FILES':
        logger.trace(_fileInfoListMap);

        _prependFileListsToTransacitonQueue(_fileInfoListMap, fs.allowedExt);
        await _executeNextTransaction();
        return;
      case '_CLEAN_FILES':
        _notify(SyncNotify.setText, lang.Cleaning_files);
        await _cleanFilesAsync(_fileInfoListMap['.m3u']);
        await _cleanFilesAsync(_fileInfoListMap['.m4a']);
        await _cleanFilesAsync(_fileInfoListMap['.mp3']);
        await _executeNextTransaction();
        return;
      case 'REQUEST_FILE':
        if (CONFIG.isDev() && CONFIG.isThrottle) {
          sleep(const Duration(milliseconds: 1000));
        }
        _notify(SyncNotify.setText, lang.Downloading_files);
        _updateProgress(
            msg.header['filename'], msg.header['progress'], 'Downloading');
        break;
      case 'PASS_TRANSACTIONS':
        msg.header['priority'] =
            SyncPriority.getPartnersPriority(_syncPriority);
        break;
      case 'END_SYNCING':
        isSyncing = false;
        _notify(SyncNotify.finish);
        break;
    }

    _send(msg);
  }

  void _prependFileListsToTransacitonQueue(
      Map<String, FileInfoList> fileListInfoMap, List<String> targets) {
    int all = 0;
    for (var t in targets) {
      var fileInfoList = fileListInfoMap[t]!;
      all += fileInfoList.list.length;
    }
    int i = all;
    for (var t in targets) {
      var fileInfoList = fileListInfoMap[t]!;
      for (var el in fileInfoList.list) {
        var msg = Message.header({
          'type': 'REQUEST_FILE',
          'filename': el.filename,
          'progress': '$i/$all'
        });
        logger.trace('Adding: $msg');
        _transactionQueue.addFirst(msg);
        i--;
      }
    }
  }

  Future<void> _cleanFilesAsync(FileInfoList? fileInfoList) async {
    if (fileInfoList == null || fileInfoList.list.isEmpty) return;

    final arr = fileInfoList.list;
    // TODO: test check
    final fname = arr.first.filename;
    String dirpath = _getDirpathForFilename(fname);
    List<String> paths = arr.map((el) {
      String filename = el.filename;
      return '${dirpath}/$filename';
    }).toList();
    logger.trace('Deleting files: $paths');
    await fsHighLevel.deleteFilesAsync(paths);
  }

  void _sendType(String type) {
    Message msg = Message({'type': type}, Uint8List(0));
    _send(msg);
  }

  void _send(Message msg) {
    logger.trace('_send() - msg: $msg');
    assert(currChannel != null, 'Currrent channel is null');
    try {
      currChannel!.sendAsBinary(msg.toBytes());
    } catch (e) {
      logger.error('Exception in _send(): $e');
    }
  }

  // For test
  void sendPing() {
    var msg = Message.header({'type': 'PING'});
    _send(msg);
  }

  void sendPong() {
    var msg = Message.header({'type': 'PONG'});
    _send(msg);
  }

  void _notify(SyncNotify type, [String? body]) {
    notifyUiCallback(UiNotification(type, body: body));
  }

  late Logger logger = Logger(prefix: 'WS [$_loggingName]:');

  String _getDirpathForFilename(String filename) {
    if (filename.endsWith('.m3u')) {
      return getPlaylistsDir();
    } else if (filename.endsWith('.mp3') || filename.endsWith('.m4a')) {
      return getMusicSourceDir();
    } else {
      assert(true, 'Bad extension for filename: $filename');
      return getMusicSourceDir();
    }
  }

  String _getDirpathForExtension(String extension) {
    assert(fs.allowedExt.contains(extension), 'Bad extension: $extension');
    if (extension.endsWith('.m3u')) {
      return getPlaylistsDir();
    } else {
      return getMusicSourceDir();
    }
  }

  /// Throws
  FileInfoList _fetchFileInfoList(String ext) {
    if (_isTest && CONFIG.isDev() && ext == '.m4a') {
      throw fs.FetchDirectoryFilesException('Dev Test exception');
    }

    String dirpath = _getDirpathForExtension(ext);
    List<File> files = fs.fetchFilesFromDirByExt(dirpath, ext);
    if (ext == '.m3u') {
      List<FileInfo> list = [];
      for (var f in files) {
        String filename = pathPkg.basename(f.path);

        final bytes = f.readAsBytesSync();
        String contents = utf8.decode(bytes);

        String musicDirRelativeToPlaylistsDir =
            pathPkg.relative(getMusicSourceDir(), from: getPlaylistsDir());
        // gLogger.blue(
        //     '_fetchFileInfoList relative: $musicDirRelativeToPlaylistsDir');
        var (newContents, err) =
            m3u.unPrefixM3uPaths(contents, '$musicDirRelativeToPlaylistsDir/');
        Uint8List newBytes = utf8.encode(newContents);

        // gLogger.log('before:\n$contents\n\nafter:\n$newContents');

        List<int> hash = hashBytes(newBytes).bytes;
        var info = FileInfo(
          filename,
          newContents.length,
          hash,
        );
        list.add(info);
      }
      return FileInfoList(list);
    }
    return _infoForAudio(files);
  }

  static FileInfoList _infoForAudio(List<File> files) {
    List<FileInfo> list = [];
    for (var f in files) {
      String filename = pathPkg.basename(f.path);
      // Empty values for audio
      FileInfo l = FileInfo(filename, -1, []);
      list.add(l);
    }
    return FileInfoList(list);
  }
}

crypto.Digest hashBytes(List<int> bytes) {
  return crypto.sha256.convert(bytes);
}
