import 'dart:async';

import 'package:grinta/model/apple_health_sync_config.dart';
import 'package:grinta/model/fitbit_sync_config.dart';
import 'package:grinta/model/google_health_sync_config.dart';
import 'package:grinta/model/polar_sync_config.dart';
import 'package:grinta/model/strava_sync_config.dart';
import 'package:grinta/model/wearable_device_type.dart';
import 'package:grinta/model/whoop_sync_config.dart';
import 'package:grinta/services/apple_health_sync_repository.dart';
import 'package:grinta/services/fitbit_sync_repository.dart';
import 'package:grinta/services/google_health_sync_repository.dart';
import 'package:grinta/services/polar_sync_repository.dart';
import 'package:grinta/services/strava_sync_repository.dart';
import 'package:grinta/services/whoop_sync_repository.dart';

/// Aggregates connected wearable devices across integrations.
class WearableDevicesRepository {
  WearableDevicesRepository({
    WhoopSyncRepository? whoopRepository,
    StravaSyncRepository? stravaRepository,
    PolarSyncRepository? polarRepository,
    FitbitSyncRepository? fitbitRepository,
    AppleHealthSyncRepository? appleHealthRepository,
    GoogleHealthSyncRepository? googleHealthRepository,
  })  : _whoopRepository = whoopRepository ?? WhoopSyncRepository(),
        _stravaRepository = stravaRepository ?? StravaSyncRepository(),
        _polarRepository = polarRepository ?? PolarSyncRepository(),
        _fitbitRepository = fitbitRepository ?? FitbitSyncRepository(),
        _appleHealthRepository =
            appleHealthRepository ?? AppleHealthSyncRepository(),
        _googleHealthRepository =
            googleHealthRepository ?? GoogleHealthSyncRepository();

  final WhoopSyncRepository _whoopRepository;
  final StravaSyncRepository _stravaRepository;
  final PolarSyncRepository _polarRepository;
  final FitbitSyncRepository _fitbitRepository;
  final AppleHealthSyncRepository _appleHealthRepository;
  final GoogleHealthSyncRepository _googleHealthRepository;

  /// Live count of connected wearable devices for a player profile.
  Stream<int> watchConnectedCount(String uid, String playerId) {
    return _combineSix(
      _whoopRepository.watchConfig(uid, playerId),
      _stravaRepository.watchConfig(uid, playerId),
      _polarRepository.watchConfig(uid, playerId),
      _fitbitRepository.watchConfig(uid, playerId),
      _appleHealthRepository.watchConfig(uid, playerId),
      _googleHealthRepository.watchConfig(uid, playerId),
      (
        WhoopSyncConfig? whoop,
        StravaSyncConfig? strava,
        PolarSyncConfig? polar,
        FitbitSyncConfig? fitbit,
        AppleHealthSyncConfig? appleHealth,
        GoogleHealthSyncConfig? googleHealth,
      ) {
        var count = 0;
        if (whoop?.connected == true) count++;
        if (strava?.connected == true) count++;
        if (polar?.connected == true) count++;
        if (fitbit?.connected == true) count++;
        if (appleHealth?.connected == true) count++;
        if (googleHealth?.connected == true) count++;
        return count;
      },
    );
  }

  bool isTypeConnected({
    required WearableDeviceType type,
    WhoopSyncConfig? whoopConfig,
    StravaSyncConfig? stravaConfig,
    PolarSyncConfig? polarConfig,
    FitbitSyncConfig? fitbitConfig,
    AppleHealthSyncConfig? appleHealthConfig,
    GoogleHealthSyncConfig? googleHealthConfig,
  }) {
    switch (type) {
      case WearableDeviceType.whoop:
        return whoopConfig?.connected == true;
      case WearableDeviceType.strava:
        return stravaConfig?.connected == true;
      case WearableDeviceType.polar:
        return polarConfig?.connected == true;
      case WearableDeviceType.fitbit:
        return fitbitConfig?.connected == true;
      case WearableDeviceType.appleHealth:
        return appleHealthConfig?.connected == true;
      case WearableDeviceType.googleHealthConnect:
        return googleHealthConfig?.connected == true;
    }
  }

  Stream<T> _combineSix<T, A, B, C, D, E, F>(
    Stream<A> first,
    Stream<B> second,
    Stream<C> third,
    Stream<D> fourth,
    Stream<E> fifth,
    Stream<F> sixth,
    T Function(A, B, C, D, E, F) combiner,
  ) {
    final controller = StreamController<T>();
    A? latestA;
    B? latestB;
    C? latestC;
    D? latestD;
    E? latestE;
    F? latestF;
    var hasA = false;
    var hasB = false;
    var hasC = false;
    var hasD = false;
    var hasE = false;
    var hasF = false;

    void emit() {
      if (!hasA ||
          !hasB ||
          !hasC ||
          !hasD ||
          !hasE ||
          !hasF ||
          controller.isClosed) {
        return;
      }
      controller.add(
        combiner(
          latestA as A,
          latestB as B,
          latestC as C,
          latestD as D,
          latestE as E,
          latestF as F,
        ),
      );
    }

    final firstSub = first.listen((value) {
      latestA = value;
      hasA = true;
      emit();
    });
    final secondSub = second.listen((value) {
      latestB = value;
      hasB = true;
      emit();
    });
    final thirdSub = third.listen((value) {
      latestC = value;
      hasC = true;
      emit();
    });
    final fourthSub = fourth.listen((value) {
      latestD = value;
      hasD = true;
      emit();
    });
    final fifthSub = fifth.listen((value) {
      latestE = value;
      hasE = true;
      emit();
    });
    final sixthSub = sixth.listen((value) {
      latestF = value;
      hasF = true;
      emit();
    });

    controller.onCancel = () async {
      await firstSub.cancel();
      await secondSub.cancel();
      await thirdSub.cancel();
      await fourthSub.cancel();
      await fifthSub.cancel();
      await sixthSub.cancel();
    };

    return controller.stream;
  }
}
