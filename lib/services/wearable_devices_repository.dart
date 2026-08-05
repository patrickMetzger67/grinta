import 'dart:async';

import 'package:grinta/model/apple_health_sync_config.dart';
import 'package:grinta/model/fitbit_sync_config.dart';
import 'package:grinta/model/google_health_sync_config.dart';
import 'package:grinta/model/intense_gps_sync_config.dart';
import 'package:grinta/model/oura_sync_config.dart';
import 'package:grinta/model/polar_sync_config.dart';
import 'package:grinta/model/strava_sync_config.dart';
import 'package:grinta/model/wearable_device_type.dart';
import 'package:grinta/model/whoop_sync_config.dart';
import 'package:grinta/services/apple_health_sync_repository.dart';
import 'package:grinta/services/fitbit_sync_repository.dart';
import 'package:grinta/services/google_health_sync_repository.dart';
import 'package:grinta/services/intense_gps_sync_repository.dart';
import 'package:grinta/services/oura_sync_repository.dart';
import 'package:grinta/services/polar_sync_repository.dart';
import 'package:grinta/services/strava_sync_repository.dart';
import 'package:grinta/services/whoop_sync_repository.dart';

/// Aggregates connected wearable devices across integrations.
class WearableDevicesRepository {
  WearableDevicesRepository({
    WhoopSyncRepository? whoopRepository,
    StravaSyncRepository? stravaRepository,
    PolarSyncRepository? polarRepository,
    OuraSyncRepository? ouraRepository,
    FitbitSyncRepository? fitbitRepository,
    AppleHealthSyncRepository? appleHealthRepository,
    GoogleHealthSyncRepository? googleHealthRepository,
    IntenseGpsSyncRepository? intenseGpsRepository,
  })  : _whoopRepository = whoopRepository ?? WhoopSyncRepository(),
        _stravaRepository = stravaRepository ?? StravaSyncRepository(),
        _polarRepository = polarRepository ?? PolarSyncRepository(),
        _ouraRepository = ouraRepository ?? OuraSyncRepository(),
        _fitbitRepository = fitbitRepository ?? FitbitSyncRepository(),
        _appleHealthRepository =
            appleHealthRepository ?? AppleHealthSyncRepository(),
        _googleHealthRepository =
            googleHealthRepository ?? GoogleHealthSyncRepository(),
        _intenseGpsRepository =
            intenseGpsRepository ?? IntenseGpsSyncRepository();

  final WhoopSyncRepository _whoopRepository;
  final StravaSyncRepository _stravaRepository;
  final PolarSyncRepository _polarRepository;
  final OuraSyncRepository _ouraRepository;
  final FitbitSyncRepository _fitbitRepository;
  final AppleHealthSyncRepository _appleHealthRepository;
  final GoogleHealthSyncRepository _googleHealthRepository;
  final IntenseGpsSyncRepository _intenseGpsRepository;

  /// Live count of connected wearable devices for a player profile.
  Stream<int> watchConnectedCount(String uid, String playerId) {
    return _combineEight(
      _whoopRepository.watchConfig(uid, playerId),
      _stravaRepository.watchConfig(uid, playerId),
      _polarRepository.watchConfig(uid, playerId),
      _ouraRepository.watchConfig(uid, playerId),
      _fitbitRepository.watchConfig(uid, playerId),
      _appleHealthRepository.watchConfig(uid, playerId),
      _googleHealthRepository.watchConfig(uid, playerId),
      _intenseGpsRepository.watchConfig(uid, playerId),
      (
        WhoopSyncConfig? whoop,
        StravaSyncConfig? strava,
        PolarSyncConfig? polar,
        OuraSyncConfig? oura,
        FitbitSyncConfig? fitbit,
        AppleHealthSyncConfig? appleHealth,
        GoogleHealthSyncConfig? googleHealth,
        IntenseGpsSyncConfig? intenseGps,
      ) {
        var count = 0;
        if (whoop?.connected == true) count++;
        if (strava?.connected == true) count++;
        if (polar?.connected == true) count++;
        if (oura?.connected == true) count++;
        if (fitbit?.connected == true) count++;
        if (appleHealth?.connected == true) count++;
        if (googleHealth?.connected == true) count++;
        if (intenseGps?.connected == true) count++;
        return count;
      },
    );
  }

  bool isTypeConnected({
    required WearableDeviceType type,
    WhoopSyncConfig? whoopConfig,
    StravaSyncConfig? stravaConfig,
    PolarSyncConfig? polarConfig,
    OuraSyncConfig? ouraConfig,
    FitbitSyncConfig? fitbitConfig,
    AppleHealthSyncConfig? appleHealthConfig,
    GoogleHealthSyncConfig? googleHealthConfig,
    IntenseGpsSyncConfig? intenseGpsConfig,
  }) {
    switch (type) {
      case WearableDeviceType.whoop:
        return whoopConfig?.connected == true;
      case WearableDeviceType.strava:
        return stravaConfig?.connected == true;
      case WearableDeviceType.polar:
        return polarConfig?.connected == true;
      case WearableDeviceType.oura:
        return ouraConfig?.connected == true;
      case WearableDeviceType.fitbit:
        return fitbitConfig?.connected == true;
      case WearableDeviceType.appleHealth:
        return appleHealthConfig?.connected == true;
      case WearableDeviceType.googleHealthConnect:
        return googleHealthConfig?.connected == true;
      case WearableDeviceType.gpsInsidersIntense:
        return intenseGpsConfig?.connected == true;
    }
  }

  Stream<T> _combineEight<T, A, B, C, D, E, F, G, H>(
    Stream<A> first,
    Stream<B> second,
    Stream<C> third,
    Stream<D> fourth,
    Stream<E> fifth,
    Stream<F> sixth,
    Stream<G> seventh,
    Stream<H> eighth,
    T Function(A, B, C, D, E, F, G, H) combiner,
  ) {
    final controller = StreamController<T>();
    A? latestA;
    B? latestB;
    C? latestC;
    D? latestD;
    E? latestE;
    F? latestF;
    G? latestG;
    H? latestH;
    var hasA = false;
    var hasB = false;
    var hasC = false;
    var hasD = false;
    var hasE = false;
    var hasF = false;
    var hasG = false;
    var hasH = false;

    void emit() {
      if (!hasA ||
          !hasB ||
          !hasC ||
          !hasD ||
          !hasE ||
          !hasF ||
          !hasG ||
          !hasH ||
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
          latestG as G,
          latestH as H,
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
    final seventhSub = seventh.listen((value) {
      latestG = value;
      hasG = true;
      emit();
    });
    final eighthSub = eighth.listen((value) {
      latestH = value;
      hasH = true;
      emit();
    });

    controller.onCancel = () async {
      await firstSub.cancel();
      await secondSub.cancel();
      await thirdSub.cancel();
      await fourthSub.cancel();
      await fifthSub.cancel();
      await sixthSub.cancel();
      await seventhSub.cancel();
      await eighthSub.cancel();
    };

    return controller.stream;
  }
}
