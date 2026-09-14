import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taply/core/services/native_bridge.dart';
import 'package:taply/core/services/app_service.dart';
import 'package:taply/core/services/permission_service.dart';
import 'package:taply/core/services/system_action_service.dart';
import 'package:taply/core/services/storage_service.dart';
import 'package:taply/shared/models/installed_app.dart';

class TestStorageService implements IStorageService {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> init() async {}

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  @override
  double? getDouble(String key) => _data[key] as double?;

  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  @override
  List<String>? getStringList(String key) =>
      (_data[key] as List?)?.cast<String>();

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = List<String>.from(value);
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _data.clear;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeBridge Utility & Decoding Tests', () {
    test('decodeBase64Icon decodes valid base64 bytes correctly', () {
      final sampleBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
      ]); // PNG magic bytes
      final base64String = base64Encode(sampleBytes);

      final decoded = NativeBridge.decodeBase64Icon(base64String);
      expect(decoded, isNotNull);
      expect(decoded, equals(sampleBytes));
    });

    test('decodeBase64Icon returns null for null, empty, or corrupt input', () {
      expect(NativeBridge.decodeBase64Icon(null), isNull);
      expect(NativeBridge.decodeBase64Icon(''), isNull);
      expect(NativeBridge.decodeBase64Icon('!!!NotBase64@@@'), isNull);
    });

    test(
      'NativeBridge returns safe fallback values in test environment',
      () async {
        final bridge = NativeBridge.instance;
        expect(bridge.isNativeAvailable, isFalse);

        final perms = await bridge.checkAllPermissions();
        expect(perms['overlay'], isTrue);
        expect(perms['accessibility'], isTrue);

        final deviceInfo = await bridge.getDeviceInfo();
        expect(deviceInfo['batteryLevel'], equals(85));
        expect(deviceInfo['osVersion'], contains('Android'));

        final volLevels = await bridge.getVolumeLevels();
        expect(volLevels['ringerMode'], equals('Normal'));

        final brightness = await bridge.getBrightness();
        expect(brightness, inInclusiveRange(0.0, 1.0));
      },
    );
  });

  group('NativeAppService Architecture & Operations', () {
    late TestStorageService storage;
    late NativeAppService appService;

    setUp(() {
      storage = TestStorageService();
      appService = NativeAppService(storage: storage);
    });

    test(
      'getInstalledApps loads and caches fallback apps in test environment',
      () async {
        final apps1 = await appService.getInstalledApps();
        expect(apps1, isNotEmpty);
        expect(
          apps1.any((a) => a.packageName == 'com.google.android.dialer'),
          isTrue,
        );

        final apps2 = await appService.getInstalledApps();
        expect(identical(apps1, apps2), isTrue); // verifies memory caching
      },
    );

    test(
      'toggleFavorite toggles state and persists list in IStorageService',
      () async {
        final targetPkg = 'com.android.chrome';
        await appService.getInstalledApps(); // initialize cache

        // Initially Chrome is not favorite
        var chrome = (await appService.getInstalledApps()).firstWhere(
          (a) => a.packageName == targetPkg,
        );
        expect(chrome.isFavorite, isFalse);

        // Toggle ON
        await appService.toggleFavorite(targetPkg);
        chrome = (await appService.getInstalledApps()).firstWhere(
          (a) => a.packageName == targetPkg,
        );
        expect(chrome.isFavorite, isTrue);

        // Storage has updated
        final storedList = storage.getStringList('taply_favorites');
        expect(storedList, contains(targetPkg));

        // Toggle OFF
        await appService.toggleFavorite(targetPkg);
        chrome = (await appService.getInstalledApps()).firstWhere(
          (a) => a.packageName == targetPkg,
        );
        expect(chrome.isFavorite, isFalse);
        expect(
          storage.getStringList('taply_favorites'),
          isNot(contains(targetPkg)),
        );
      },
    );

    test(
      'toggleHidden toggles visibility and persists list in IStorageService',
      () async {
        final targetPkg = 'com.google.android.deskclock';
        await appService.getInstalledApps();

        await appService.toggleHidden(targetPkg);
        var app = (await appService.getInstalledApps()).firstWhere(
          (a) => a.packageName == targetPkg,
        );
        expect(app.isHidden, isTrue);
        expect(storage.getStringList('taply_hidden'), contains(targetPkg));

        await appService.toggleHidden(targetPkg);
        app = (await appService.getInstalledApps()).firstWhere(
          (a) => a.packageName == targetPkg,
        );
        expect(app.isHidden, isFalse);
        expect(
          storage.getStringList('taply_hidden'),
          isNot(contains(targetPkg)),
        );
      },
    );

    test('recordLaunch increments usage count and sets timestamp', () async {
      final targetPkg = 'com.google.android.calculator';
      await appService.getInstalledApps();

      var app = (await appService.getInstalledApps()).firstWhere(
        (a) => a.packageName == targetPkg,
      );
      final initialUsage = app.usageCount;
      expect(app.lastUsedAt, isNull);

      await appService.recordLaunch(targetPkg);
      app = (await appService.getInstalledApps()).firstWhere(
        (a) => a.packageName == targetPkg,
      );
      expect(app.usageCount, equals(initialUsage + 1));
      expect(app.lastUsedAt, isNotNull);
    });

    test('updateLaunchMode updates launch mode on installed app', () async {
      final targetPkg = 'com.google.android.calendar';
      await appService.getInstalledApps();

      await appService.updateLaunchMode(targetPkg, AppLaunchMode.floating);
      final app = (await appService.getInstalledApps()).firstWhere(
        (a) => a.packageName == targetPkg,
      );
      expect(app.launchMode, equals(AppLaunchMode.floating));
    });
  });

  group('NativePermissionService Tests', () {
    test(
      'checkAllPermissions maps native map correctly to PermissionStatus enum',
      () async {
        final permService = NativePermissionService();
        final statuses = await permService.checkAllPermissions();

        expect(statuses.containsKey(PermissionType.overlay), isTrue);
        expect(statuses.containsKey(PermissionType.accessibility), isTrue);
        expect(statuses.containsKey(PermissionType.notifications), isTrue);
        expect(
          statuses.containsKey(PermissionType.batteryOptimization),
          isTrue,
        );
      },
    );
  });

  group('NativeSystemActionService Tests', () {
    test(
      'executeAction dispatches navigation and system controls gracefully',
      () async {
        final actionService = NativeSystemActionService();

        expect(
          await actionService.executeAction(SystemActionType.home),
          isTrue,
        );
        expect(
          await actionService.executeAction(SystemActionType.back),
          isTrue,
        );
        expect(
          await actionService.executeAction(SystemActionType.recentApps),
          isTrue,
        );
        expect(
          await actionService.executeAction(SystemActionType.lockScreen),
          isTrue,
        );
        expect(
          await actionService.executeAction(SystemActionType.screenshot),
          isTrue,
        );

        expect(
          await actionService.executeAction(
            SystemActionType.mediaVolume,
            parameter: 0.75,
          ),
          isTrue,
        );
        expect(
          await actionService.executeAction(
            SystemActionType.brightness,
            parameter: 0.8,
          ),
          isTrue,
        );
        expect(
          await actionService.executeAction(SystemActionType.wifi),
          isTrue,
        );
        expect(
          await actionService.executeAction(SystemActionType.bluetooth),
          isTrue,
        );

        expect(actionService.isSupported(SystemActionType.home), isTrue);
      },
    );
  });
}
