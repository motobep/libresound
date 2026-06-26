import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:music_player/logger.dart';
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/ws/FileDTO.dart';
import 'package:music_player/logic/ws/FileListInfoDTO.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/config.dart' show fileSystem;
import 'package:music_player/logic/UiNotification.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/fs/files.dart' as fs;
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
    required this.notifyUiCallback,
    required this.interruptCallback,
    required this.connectHandler,
    required this.closeHandler,
  });

  WsHandler.test(
    this.ip,
    this.getMusicSourceDir, {
    required this.notifyUiCallback,
    required this.interruptCallback,
  }) {
    connectHandler = () {
      trace('test - connectHandler');
    };
    closeHandler = () {
      trace('test - closeHandler');
    };
  }

  String ip;
  int get serverPort {
    if (socketsServer == null) return -1;
    return socketsServer!.port;
  }

  String Function() getMusicSourceDir;

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
        error(e.message);
        assert(false, 'shouldn\'t be here');
        rethrow;
      } catch (e) {
        error(e);
        assert(false, 'shouldn\'t be here');
        rethrow;
      }
      _onServerConnectHandler();
    }, onDone: () {
      log('socketsServer done');
    }, onError: (e) {
      error('socketsServer error: $e');
    });

    trace(
        'Serving at tcp server://${socketsServer!.address.host}:${socketsServer!.port}',
        color: 'blue');
  }

  Future<void> stopServer() async {
    assert(socketsServer != null);
    log('Stopping server');
    await socketsServer!.close();
    socketsServer = null;
  }

  Future<void> _onServerConnectHandler() async {
    trace('Connection established', color: 'blue');
    connectHandler();
  }
  // SERVER end

  // CLIENT start
  Future<bool> connect(String ip, int port) async {
    _loggingName = 'Client';

    trace('Connecting to $ip:$port', color: 'blue');
    try {
      currChannel = WsChannel(
          WebSocket.fromUpgradedSocket((await Socket.connect(ip, port)),
              serverSide: false),
          WsChannel.clientType);
    } on SocketException {
      error('Exception connecting to server: SocketException');
      return false;
    } catch (e) {
      error('Unexpected exception in connect(): $e');
      return false;
    }

    _listen(_listenHandler);
    trace('Connection established', color: 'blue');

    connectHandler();
    return true;
  }
  // CLIENT part end

  Future<void> closeCurrChannel() async {
    assert(currChannel != null, 'Currrent channel is null');
    await currChannel!.close();
    trace('Currrent channel closed');
  }

  StreamSubscription<dynamic>? _listen(void Function(dynamic)? listenHandler) {
    assert(currChannel != null, 'Currrent channel is null');
    _transactionQueue = Queue.from([]);
    return currChannel!.socket.listen(listenHandler,
        onDone: _onDoneHandler, onError: _onErrorHandler, cancelOnError: true);
  }

  Future<void> _onDoneHandler() async {
    trace('Stream done');
    assert(currChannel != null, 'Currrent channel is null');

    var readyState = currChannel!.socket.readyState;
    var closeCode = currChannel!.socket.closeCode;

    log('readyState=$readyState, closeCode=$closeCode');

    if (isConnectionOpenOrConnecting()) {
      currChannel!.close();
    }

    isSyncing = false;
    closeHandler();
  }

  Future<void> _onErrorHandler(e) async {
    error('Error in stream: $e');
    await closeCurrChannel();
    isSyncing = false;
    log('use closeHandler() in _onErrorHandler()?');
    // QUESTION: Should here be closeHandler() ?
  }

  void _listenHandler(dynamic payload) async {
    Message message = Message.fromBytes(payload as Uint8List);
    var header = message.header;

    switch (header['type']) {
      case 'START_SYNCING':
        isSyncing = true;
        _syncPriority = SyncPriority.none;
        _notify(SyncNotify.start);
        _sendType('ACK');
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
          FileListInfoDTO dto =
              _fetchFileListInfoDtos(getMusicSourceDir(), target);
          var resp =
              Message({'type': 'FILE_LIST', 'target': target}, dto.toBytes());
          _send(resp);

          log('Uploading file list $target');
        } catch (e) {
          error('Error during GET_FILE_LIST: $e');

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
        trace('FILE_LIST: $target', color: 'yellow');
        _fileListInfoMap[target] =
            FileListInfoDTO.fromBytes(message.body).toFileDTOSet();

        log('Downloading file list $target');
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
          String path = '${getMusicSourceDir()}/$filename';
          fs.deleteFile(path);
        }

        // Send file
        trace('Sending file: "$filename"');
        try {
          FileDTO dto = FileDTO.fromFile(
              fileSystem.file('${getMusicSourceDir()}/$filename'));
          var msg = Message({'type': 'FILE'}, dto.toBytes());
          _send(msg);
        } catch (e) {
          error('Error during REQUEST_FILE: $e');
          error('  runtimeType: ${e.runtimeType}');

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
        trace('Saving file: "${dto.filename}"');
        var f = fileSystem.file('${getMusicSourceDir()}/${dto.filename}');
        fs.writeToFileAsBytes(f, dto.bContents);
        DateTime time = DateTime.fromMillisecondsSinceEpoch(dto.modified);
        f.setLastModifiedSync(time);

        await _executeNextTransaction();
        break;
      case 'ERROR':
        var err = message.header['err'];
        // Handling error
        String prefix = '(${lang.Error_from_partner})';
        String errName = err['name'];
        String errNameForUser = _exceptionToText[errName] ?? errName;
        error('Error from partner: $errName');
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

  bool _checkPlaylistsConfilcts(Set<FileDTO> gotSet, Set<FileDTO> mySet) {
    for (var gotDto in gotSet) {
      for (var myDto in mySet) {
        if (gotDto.filename == myDto.filename) {
          if (gotDto.modified != myDto.modified) {
            trace('gotDto: $gotDto; myDto $myDto');
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

  static Message startSyncMsg = Message.header({'type': 'START_SYNCING'});
  static Message endSyncMsg = Message.header({'type': 'END_SYNCING'});

  final Map<String, Set<FileDTO>> _fileListInfoMap = {
    '.mp3': {},
    '.m4a': {},
    '.m3u': {},
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
    trace('Transactions amount: ${_transactionQueue.length}');
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
          if (_fileListInfoMap[target]!.isEmpty) {
            continue;
          }
          try {
            Set<FileDTO> got = _fileListInfoMap[target]!;
            Set<FileDTO> my =
                _fetchFileListInfoDtos(getMusicSourceDir(), target)
                    .toFileDTOSet();

            if (target != '.m3u') {
              _fileListInfoMap[target] = FileDTO.filenameDifference(got, my);
            } else {
              if (_syncPriority == SyncPriority.none &&
                  _checkPlaylistsConfilcts(got, my)) {
                _syncPriority = await interruptCallback('playlists_conflict');
                assert(_syncPriority != SyncPriority.none,
                    'Must be chosen SyncPriority');
              }
              trace('SyncPriority: $_syncPriority');

              // Take difference
              if (_syncPriority == SyncPriority.partner) {
                // log('partner');
                _fileListInfoMap['.m3u'] = got.difference(my);
              } else {
                // log('else');
                _fileListInfoMap['.m3u'] = FileDTO.filenameDifference(got, my);
              }
            }
          } catch (e) {
            error(e);

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
            Set<FileDTO> got = _fileListInfoMap[target]!;
            Set<FileDTO> my =
                _fetchFileListInfoDtos(getMusicSourceDir(), target)
                    .toFileDTOSet();
            _fileListInfoMap[target] = FileDTO.filenameDifference(my, got);
          } catch (e) {
            error(e);

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
        trace(_fileListInfoMap);

        _prependFileListsToTransacitonQueue(_fileListInfoMap, fs.allowedExt);
        await _executeNextTransaction();
        return;
      case '_CLEAN_FILES':
        _notify(SyncNotify.setText, lang.Cleaning_files);
        _cleanFiles(_fileListInfoMap['.m3u']);
        _cleanFiles(_fileListInfoMap['.m4a']);
        _cleanFiles(_fileListInfoMap['.mp3']);
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
      Map<String, Set<FileDTO>> fileListInfoMap, List<String> targets) {
    int all = 0;
    for (var t in targets) {
      var fileListInfo = fileListInfoMap[t]!;
      all += fileListInfo.length;
    }
    int i = all;
    for (var t in targets) {
      var fileListInfo = fileListInfoMap[t]!;
      for (var el in fileListInfo) {
        var msg = Message.header({
          'type': 'REQUEST_FILE',
          'filename': el.filename,
          'progress': '$i/$all'
        });
        trace('Adding: $msg');
        _transactionQueue.addFirst(msg);
        i--;
      }
    }
  }

  void _cleanFiles(Set<FileDTO>? fileListInfo) {
    if (fileListInfo != null && fileListInfo.isNotEmpty) {
      for (var el in fileListInfo) {
        String filename = el.filename;
        trace('Deleting file: $filename');
        fs.deleteFile('${getMusicSourceDir()}/$filename');
      }
    }
  }

  void _sendType(String type) {
    Message msg = Message({'type': type}, Uint8List(0));
    _send(msg);
  }

  void _send(Message msg) {
    trace('_send() - msg: $msg');
    assert(currChannel != null, 'Currrent channel is null');
    try {
      currChannel!.sendAsBinary(msg.toBytes());
    } catch (e) {
      error('Exception in _send(): $e');
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

  void log(s, {String color = ''}) {
    if (_loggingName == 'Server') {
      gLogger.log(' 🎯 WS [$_loggingName]: $s', color);
    } else if (_loggingName == 'Client') {
      gLogger.log(' 🔎 WS [$_loggingName]: $s', color);
    } else {
      gLogger.log('WS [$_loggingName]: $s', color);
    }
  }

  void trace(s, {String color = ''}) {
    if (CONFIG.isLogTrace) {
      log(s, color: color);
    }
  }

  void error(s) => log(s, color: 'red');
}

/// Throws
FileListInfoDTO _fetchFileListInfoDtos(String sourceDir, String ext) {
  if (_isTest && CONFIG.isDev() && ext == '.m4a') {
    throw fs.FetchDirectoryFilesException('Dev Test exception');
  }
  List<File> files = fs.fetchFilesFromDirByExt(sourceDir, ext);
  return FileListInfoDTO.fromFiles(files);
}
