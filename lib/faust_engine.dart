import 'dart:async';

import 'package:flutter/services.dart';

class FaustEngineException implements Exception {
  const FaustEngineException(this.message);

  final String message;

  @override
  String toString() => 'FaustEngineException: $message';
}

class MeterEvent {
  const MeterEvent({required this.timestamp, required this.meters});

  factory MeterEvent.fromChannelPayload(dynamic payload) {
    if (payload is! Map) {
      throw const FaustEngineException('Meter payload was not a map');
    }

    final timestampMs = payload['timestampMs'];
    final meters = payload['meters'];

    if (timestampMs is! int || meters is! Map) {
      throw FaustEngineException(
        'Unexpected meter payload shape: $payload',
      );
    }

    final parsedMeters = <String, double>{};
    meters.forEach((key, value) {
      if (key is! String) {
        return;
      }
      final parsedValue = _parseDouble(value);
      if (parsedValue != null) {
        parsedMeters[key] = parsedValue;
      }
    });

    return MeterEvent(
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      meters: parsedMeters,
    );
  }

  final DateTime timestamp;
  final Map<String, double> meters;

  static double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}

class FaustEngineService {
  static const MethodChannel _methodChannel = MethodChannel('dev.faust/engine');
  static const EventChannel _meterChannel =
      EventChannel('dev.faust/engine/meters');

  Stream<MeterEvent>? _meterStream;

  Future<bool> initialize({required int sampleRate, required int bufferSize}) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('initialize', {
        'sampleRate': sampleRate,
        'bufferSize': bufferSize,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw FaustEngineException(
        'initialize failed: ${e.message ?? e.code}',
      );
    }
  }

  Future<bool> start() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('start');
      return result ?? false;
    } on PlatformException catch (e) {
      throw FaustEngineException('start failed: ${e.message ?? e.code}');
    }
  }

  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod<void>('stop');
    } on PlatformException catch (e) {
      throw FaustEngineException('stop failed: ${e.message ?? e.code}');
    }
  }

  Future<void> teardown() async {
    try {
      await _methodChannel.invokeMethod<void>('teardown');
    } on PlatformException catch (e) {
      throw FaustEngineException('teardown failed: ${e.message ?? e.code}');
    }
  }

  Future<bool> isRunning() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isRunning');
      return result ?? false;
    } on PlatformException catch (e) {
      throw FaustEngineException('isRunning failed: ${e.message ?? e.code}');
    }
  }

  Future<void> setParameter(String address, double value) async {
    try {
      await _methodChannel.invokeMethod<void>('setParameter', {
        'address': address,
        'value': value,
      });
    } on PlatformException catch (e) {
      throw FaustEngineException('setParameter failed: ${e.message ?? e.code}');
    }
  }

  Future<double> getParameter(String address) async {
    try {
      final result = await _methodChannel.invokeMethod<double>('getParameter', {
        'address': address,
      });
      return result ?? 0.0;
    } on PlatformException catch (e) {
      throw FaustEngineException('getParameter failed: ${e.message ?? e.code}');
    }
  }

  Future<List<String>> listParameters() async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'listParameters',
      );
      return result
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[];
    } on PlatformException catch (e) {
      throw FaustEngineException('listParameters failed: ${e.message ?? e.code}');
    }
  }

  Stream<MeterEvent> meterStream() {
    _meterStream ??= _meterChannel
        .receiveBroadcastStream()
        .map(MeterEvent.fromChannelPayload)
        .asBroadcastStream();
    return _meterStream!;
  }
}
