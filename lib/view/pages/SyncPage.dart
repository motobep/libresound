import 'dart:io';

import 'package:music_player/logger.dart';
import 'package:music_player/main.dart' show config;
import 'package:music_player/states/AppState.dart' show AppState;
import 'package:music_player/view/addGuardsFuncs.dart';
import 'package:music_player/view/components/dialogs.dart';
import 'package:music_player/view/components/inputs.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/ws/helpers.dart' as ws_helpers;
import 'package:music_player/logic/PairCandidate.dart';

import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/NetworkState.dart';

import 'package:music_player/view/components/buttons.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syncing music'),
        leading: getBackBtn(context),
      ),
      body: const SyncBody(),
    );
  }
}

class SyncBody extends StatelessWidget {
  const SyncBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget body = _addGuardsToSyncBody(const _PairListBody(), context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CONFIG.pagePaddingHor,
        vertical: CONFIG.pagePaddingVert,
      ),
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [body],
      ),
    );
  }
}

class _PairListBody extends StatelessWidget {
  const _PairListBody();

  @override
  Widget build(BuildContext context) {
    NetworkState networkState =
        Provider.of<NetworkState>(context, listen: false);
    PairCandidate? chosenCandidate = context
        .select<NetworkState, PairCandidate?>((app) => app.chosenCandidate);
    bool isNetworkActivated =
        context.select<NetworkState, bool>((app) => app.isNetworkActivated);
    String currIp = context.select<NetworkState, String>((s) => s.currIp!);

    Widget actDeactBtn = isNetworkActivated
        ? StandardButton(
            lang.Deactivate,
            onTap: () {
              networkState.deactivateNetwork();
            },
          )
        : StandardButton(
            lang.Activate,
            onTap: () {
              gLogger.view('Activate btn clicked');
              networkState.activateNetwork();
            },
          );

    // Choosing candidate page
    if (chosenCandidate == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isNetworkActivated) ...[
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 5.0, right: 12.0),
                  child: Text('IP :'),
                ),
                (config.allIps.length == 1)
                    ? Text(config.allIps[0])
                    : SelectInput(
                        elements: config.allIps.map((ip) => (ip, ip)).toList(),
                        initial: currIp,
                        onSelect: (ip) {
                          gLogger.view('selected');
                          networkState.changeIp(ip!);
                        })
              ],
            ),
            const SizedBox(height: 18),
          ],
          actDeactBtn,
          const SizedBox(height: 10),
          isNetworkActivated
              ? const _SyncCandidates()
              : const SizedBox.shrink(),
        ],
      );
    }

    // Connecting page
    bool isShowSyncing =
        context.select<NetworkState, bool>((app) => app.isShowSyncPage());
    if (!isShowSyncing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chosenCandidate.deviceName),
          LinkButton(
            onTap: () {
              networkState.cancel();
            },
            child: Text(lang.Cancel),
          ),
          const SizedBox(height: 8),
          Text(lang.Connecting),
        ],
      );
    }

    List<String> errorsDuringSync =
        context.select<NetworkState, List<String>>((s) => s.errorsDuringSync);

    // Sync buttons page
    bool isSyncing = context.select<NetworkState, bool>((s) => s.isSyncing);
    if (!isSyncing) {
      return _SyncButtonsBody(
        deviceName: chosenCandidate.deviceName,
        errorsDuringSync: errorsDuringSync,
      );
    }

    String syncingHeader =
        context.select<NetworkState, String>((s) => s.syncingHeader);
    int gotItems = context.select<NetworkState, int>((s) => s.gotItems);
    int allItems = context.select<NetworkState, int>((s) => s.allItems);

    return SyncProgressBody(
      syncingHeader: syncingHeader,
      gotItems: gotItems,
      allItems: allItems,
      errorsDuringSync: errorsDuringSync,
      deviceName: chosenCandidate.deviceName,
    );
  }
}

class _SyncCandidates extends StatelessWidget {
  const _SyncCandidates();

  @override
  Widget build(BuildContext context) {
    var pairCandidates = context.watch<NetworkState>().pairCandidates;
    if (pairCandidates.isEmpty) {
      return Text(lang.phrase__no_active_devices_to_pair_with);
    }

    return Column(
      children: [for (var el in pairCandidates) _SyncCard(el)],
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard(this.pairCandidate);

  final PairCandidate pairCandidate;

  @override
  Widget build(BuildContext context) {
    NetworkState networkState =
        Provider.of<NetworkState>(context, listen: false);

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
              '${pairCandidate.deviceName} ${pairCandidate.ip}:${pairCandidate.wsPort}'),
          pairCandidate.isAcceptState
              ? LinkButton(
                  onTap: () async {
                    await networkState.accept(pairCandidate);
                  },
                  child: Text(lang.Accept),
                )
              : LinkButton(
                  onTap: () {
                    networkState.pair(pairCandidate);
                  },
                  child: Text(lang.Pair),
                ),
        ],
      ),
    );
  }
}

class _SyncButtonsBody extends StatelessWidget {
  const _SyncButtonsBody({
    required this.deviceName,
    required this.errorsDuringSync,
  });

  final String deviceName;
  final List<String> errorsDuringSync;

  @override
  Widget build(BuildContext context) {
    NetworkState networkState =
        Provider.of<NetworkState>(context, listen: false);
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    double height = MediaQuery.of(context).size.height;

    const double actionsGap = 24;
    const double textGap = 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${lang.Partner}: $deviceName'),
        const SizedBox(height: 10),
        _UnpairButton(networkState: networkState),
        const SizedBox(height: actionsGap + 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StandardButton(
              lang.Synchronize,
              onTap: () {
                networkState.sync();
              },
            ),
            const SizedBox(height: textGap),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                lang.File_sharing_with_a_partner,
                style: TextStyle(color: ColorScheme.of(context).secondary),
              ),
            ),
            const SizedBox(height: actionsGap),
            StandardButton(
              lang.Download,
              onTap: () {
                networkState.download();
              },
            ),
            const SizedBox(height: textGap),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                lang.Downloading_file_from_partner,
                style: TextStyle(color: ColorScheme.of(context).secondary),
              ),
            ),
            const SizedBox(height: actionsGap),
            StandardButton(
              lang.Clean,
              onTap: () async {
                bool? isConfirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => ConfirmDialog(
                    heading: lang
                        .Remove_extra_files_that_the_partner_does_not_have__q,
                    content: Padding(
                        padding: const EdgeInsets.only(left: 2.0, bottom: 12),
                        child: Text('${lang.See} "${lang.About_modes}"')),
                    confirmText: lang.Ok,
                    cancelText: lang.Cancel,
                  ),
                );
                if (isConfirm != null && isConfirm == true) {
                  gLogger.view('Clean confirmed');
                  networkState.clean();
                } else {
                  gLogger.view('Clean canceled');
                }
              },
            ),
            const SizedBox(height: textGap),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                lang.Removing_extra_files_that_the_partner_does_not_have,
                style: TextStyle(color: ColorScheme.of(context).secondary),
              ),
            ),
            const SizedBox(height: actionsGap),
            if (CONFIG.isDev())
              StandardButton(
                'Prepare dirs',
                onTap: () async {
                  final testDirServer =
                      '${Directory.current.path}/test_targets/music_playlists/server';
                  final testDirClient =
                      '${Directory.current.path}/test_targets/music_playlists/client';
                  ws_helpers.prepare_directory(testDirServer);
                  ws_helpers.prepare_directory(testDirClient);

                  var playlistFile = File(
                      '${ws_helpers.pivotD(testDirServer)}/shared-example.m3u');
                  playlistFile.setLastModifiedSync(
                      DateTime.fromMillisecondsSinceEpoch(0));
                  var noReadPermFile =
                      '$testDirServer/pivot/Server-no_read_permission.mp3';
                  await Process.run('chmod', ['ugo-r', noReadPermFile]);
                  gLogger.view('Prepared');
                },
              ),
            const SizedBox(height: 20),
            TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateColor.resolveWith(
                    (states) => appearanceState.buttonColor()),
                minimumSize: WidgetStateProperty.all(Size.zero),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40.0),
                )),
                padding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: .0,
                )),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      lang.About_modes,
                      style:
                          TextStyle(color: ColorScheme.of(context).secondary),
                    ),
                  ),
                  SizedBox(
                    width: 18.0,
                    height: 34.0,
                    child: Icon(
                      PhosphorIconsThin.question,
                      color: ColorScheme.of(context).secondary,
                      size: 18,
                    ),
                  ),
                ],
              ),
              onPressed: () {
                gLogger.view('More about modes btn');
                // TODO: manage focus
                showDialog<String>(
                  context: context,
                  builder: (context) => const ModesInfoDialog(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
        errorsDuringSync.isNotEmpty
            ? ErrorsDuringSyncing(
                height: height, errorsDuringSync: errorsDuringSync)
            : const SizedBox.shrink(),
      ],
    );
  }
}

class _UnpairButton extends StatelessWidget {
  const _UnpairButton({
    required this.networkState,
  });

  final NetworkState networkState;

  @override
  Widget build(BuildContext context) {
    return StandardButton(
      lang.Unpair,
      fgColor: ColorScheme.of(context).onSurface,
      onTap: () {
        networkState.unpair();
      },
    );
  }
}

class SyncProgressBody extends StatelessWidget {
  const SyncProgressBody({
    required this.syncingHeader,
    required this.gotItems,
    required this.allItems,
    required this.errorsDuringSync,
    required this.deviceName,
    super.key,
  });

  final String syncingHeader;
  final int gotItems;
  final int allItems;
  final List<String> errorsDuringSync;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    NetworkState networkState =
        Provider.of<NetworkState>(context, listen: false);
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    double ratio = gotItems / allItems;

    double height = MediaQuery.of(context).size.height;

    var progressIndicator = allItems > 0
        ? Column(children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0, left: 2, right: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$gotItems'),
                  Text('$allItems'),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 3,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              semanticsLabel: 'File transfer progress',
              color: ColorScheme.of(context).primary,
              backgroundColor: appearanceState.inactiveTrackColor(),
            ),
          ])
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(deviceName),
        const SizedBox(height: 8),
        _UnpairButton(networkState: networkState),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              Text(syncingHeader, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              progressIndicator,
              const SizedBox(height: 30),
              errorsDuringSync.isNotEmpty
                  ? ErrorsDuringSyncing(
                      height: height, errorsDuringSync: errorsDuringSync)
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}

class ErrorsDuringSyncing extends StatelessWidget {
  const ErrorsDuringSyncing({
    super.key,
    required this.height,
    required this.errorsDuringSync,
  });

  final double height;
  final List<String> errorsDuringSync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.Errors,
            style: TextStyle(
                fontSize: 18, color: ColorScheme.of(context).tertiary)),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: SizedBox(
            height: height * 0.55,
            child: ListView(
              children: [
                for (var err in errorsDuringSync)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(err,
                        style: const TextStyle(fontSize: 14.5, height: 1.4)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _addGuardsToSyncBody(Widget body, BuildContext context) {
  bool isShowGrantStorageAccess =
      context.select<AppState, bool>((s) => s.isShowGrantStorageAccess);
  bool isShowChooseMusicDir =
      context.select<AppState, bool>((s) => s.isShowChooseMusicDir);
  NetworkError networkError =
      context.select<NetworkState, NetworkError>((n) => n.networkError);

  if (isShowGrantStorageAccess) {
    return const GrantStorageAccess();
  } else if (isShowChooseMusicDir) {
    return const SelectSourceDir();
  } else if (networkError != NetworkError.none) {
    return _ErrorBody(networkError: networkError);
  }
  return body;
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.networkError,
  });

  final NetworkError networkError;

  @override
  Widget build(BuildContext context) {
    NetworkState networkState =
        Provider.of<NetworkState>(context, listen: false);
    String msg;
    switch (networkError) {
      case NetworkError.noIp:
        msg =
            '${lang.No_network_connection} (${lang.IP_address_not_found}).\n${lang.Connect_to_the_network_and_press_Retry}';
        break;
      case NetworkError.networkUnreachable:
        msg =
            '${lang.No_network_connection} (${lang.Network_unreachable}).\n${lang.Connect_to_the_network_and_press_Retry}';
        break;
      case NetworkError.badActivation:
        msg =
            '${lang.phrase__bad_activation}.\n${lang.Connect_to_the_network_and_press_Retry}';
        break;
      default:
        assert(false, 'SHOULD NOT BE HERE');
        msg = lang.Unknown_error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(msg,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 15),
        StandardButton(lang.Retry, onTap: () {
          networkState.retry();
        }),
      ],
    );
  }
}
