import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faust_test_app/faust_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('dev.faust/engine');
  const meterChannel = EventChannel('dev.faust/engine/meters');
  const codec = StandardMethodCodec();

  final binaryMessenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final recordedCalls = <MethodCall>[];

  setUp(() {
    recordedCalls.clear();
    binaryMessenger.setMockMethodCallHandler(
      methodChannel,
      (call) async {
        recordedCalls.add(call);
        switch (call.method) {
          case 'initialize':
            return true;
          case 'start':
            return true;
          case 'getParameter':
            return 0.42;
          case 'listParameters':
            return <dynamic>["/gain", "/frequency", 123];
        }
        return null;
      },
    );

    binaryMessenger.setMockMessageHandler(
      meterChannel.name,
      (message) async {
        final methodCall = codec.decodeMethodCall(message);
        if (methodCall.method == 'listen') {
          scheduleMicrotask(() {
            binaryMessenger.handlePlatformMessage(
              meterChannel.name,
              codec.encodeSuccessEnvelope({
                'timestampMs': DateTime.fromMillisecondsSinceEpoch(0)
                    .add(const Duration(seconds: 1))
                    .millisecondsSinceEpoch,
                'meters': {'left': 0.12, 'right': 0.34},
              }),
              (_) {},
            );
          });
        }
        return null;
      },
    );
  });

  tearDown(() {
    binaryMessenger.setMockMethodCallHandler(methodChannel, null);
    binaryMessenger.setMockMessageHandler(meterChannel.name, null);
  });

  group('FaustEngineService', () {
    final service = FaustEngineService();

    test('initializes with provided configuration', () async {
      final initialized =
          await service.initialize(sampleRate: 48000, bufferSize: 256);

      expect(initialized, isTrue);
      expect(recordedCalls.single.method, 'initialize');
      expect(
        recordedCalls.single.arguments,
        equals({'sampleRate': 48000, 'bufferSize': 256}),
      );
    });

    test('sets and reads parameters through the method channel', () async {
      await service.setParameter('/gain', 0.9);
      final value = await service.getParameter('/gain');

      expect(recordedCalls[0].method, 'setParameter');
      expect(
        recordedCalls[0].arguments,
        equals({'address': '/gain', 'value': 0.9}),
      );
      expect(recordedCalls[1].method, 'getParameter');
      expect(
        recordedCalls[1].arguments,
        equals({'address': '/gain'}),
      );
      expect(value, closeTo(0.42, 1e-6));
    });

    test('returns sanitized parameter list', () async {
      final parameters = await service.listParameters();

      expect(parameters, equals(['/gain', '/frequency']));
    });

    test('streams parsed meter events', () async {
      final event = await service.meterStream().first;

      expect(event.meters, equals({'left': 0.12, 'right': 0.34}));
      expect(event.timestamp, DateTime.fromMillisecondsSinceEpoch(1000));
    });
  });
}
