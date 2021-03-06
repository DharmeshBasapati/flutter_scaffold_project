import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_base_project/app_constants.dart';
import 'package:flutter_base_project/src/app_update/app_update_key_provider.dart';
import 'package:flutter_base_project/src/remote_config/remote_config_repository.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateMode { noUpdate, flexibleUpdate, immediateUpdate }

class AppUpdateWidget extends StatefulWidget {
  @override
  _AppUpdateWidgetState createState() => _AppUpdateWidgetState();
}

class _AppUpdateWidgetState extends State<AppUpdateWidget> {
  @override
  void initState() {
    super.initState();
    promptAppUpdate(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

Future<void> promptAppUpdate(BuildContext context) async {
  final update = await checkAppUpdate(
    remoteConfigRepository: RemoteConfigRepository(),
  );

  if (update == UpdateMode.noUpdate) {
    return;
  }

  if (update == UpdateMode.flexibleUpdate) {
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text('flexible_update_msg'.tr()),
        action: SnackBarAction(
          label: 'btn_update'.tr(),
          onPressed: () => openStore(),
        ),
      ),
    );
  }

  if (update == UpdateMode.immediateUpdate) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('title_immediate_update'.tr()),
          content: Text('content_immediate_update'.tr()),
          actions: <Widget>[
            FlatButton(
              onPressed: () => openStore(),
              child: Text('btn_update'.tr()),
            )
          ],
        );
      },
    );
  }
}

Future<UpdateMode> checkAppUpdate({
  @required RemoteConfigRepository remoteConfigRepository,
}) async {
  final keyProvider = platformKeyProvider();

  final currentVersion = int.parse(await getCurrentAppVersion());
  final latestStableVersion = int.parse(
    remoteConfigRepository.getString(
      keyProvider.keyLatestStableVersion,
    ),
  );
  final latestVersion = int.parse(
    remoteConfigRepository.getString(
      keyProvider.keyLatestVersion,
    ),
  );

  if (currentVersion >= latestVersion) {
    return UpdateMode.noUpdate;
  }

  if (currentVersion < latestStableVersion) {
    return UpdateMode.immediateUpdate;
  }

  return UpdateMode.flexibleUpdate;
}

Future<String> getCurrentAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.buildNumber;
}

Future<void> openStore() async {
  String url;
  if (Platform.isAndroid) {
    url = androidPlayStoreUrl;
  } else if (Platform.isIOS) {
    url = iosAppStoreUrl;
  }
  if (await canLaunch(url)) {
    await launch(url);
  }
}
