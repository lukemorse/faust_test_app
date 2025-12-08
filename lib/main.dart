import 'dart:async';

import 'package:flutter/material.dart';

import 'faust_engine.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faust Test App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const FaustDemoPage(),
    );
  }
}

class FaustDemoPage extends StatefulWidget {
  const FaustDemoPage({super.key});

  @override
  State<FaustDemoPage> createState() => _FaustDemoPageState();
}

class _FaustDemoPageState extends State<FaustDemoPage> {
  final FaustEngineService _engine = FaustEngineService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _valueController = TextEditingController(
    text: '0.5',
  );

  bool _initialized = false;
  bool _running = false;
  bool _busy = false;
  List<String> _parameterAddresses = const [];
  MeterEvent? _latestMeters;
  StreamSubscription<MeterEvent>? _meterSubscription;

  @override
  void dispose() {
    _meterSubscription?.cancel();
    _addressController.dispose();
    _valueController.dispose();
    _engine.teardown();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _runAction(() async {
      final initialized = await _engine.initialize(
        sampleRate: 44100,
        bufferSize: 512,
      );
      if (!initialized) {
        throw const FaustEngineException(
          'Engine reported initialization failure',
        );
      }

      _parameterAddresses = await _engine.listParameters();
      if (_parameterAddresses.isNotEmpty && _addressController.text.isEmpty) {
        _addressController.text = _parameterAddresses.first;
      }
      _subscribeToMeters();
      _initialized = initialized;
      _running = await _engine.isRunning();
    });
  }

  Future<void> _start() async {
    await _runAction(() async {
      _running = await _engine.start();
    });
  }

  Future<void> _stop() async {
    await _runAction(() async {
      await _engine.stop();
      _running = await _engine.isRunning();
    });
  }

  Future<void> _teardown() async {
    await _runAction(() async {
      await _engine.teardown();
      _running = false;
      _initialized = false;
      _parameterAddresses = const [];
      _latestMeters = null;
      await _meterSubscription?.cancel();
      _meterSubscription = null;
    });
  }

  Future<void> _setParameter() async {
    await _runAction(() async {
      final address = _addressController.text.trim();
      final value = double.tryParse(_valueController.text);
      if (address.isEmpty || value == null) {
        throw const FaustEngineException(
          'Enter a valid parameter address and numeric value.',
        );
      }
      await _engine.setParameter(address, value);
    });
  }

  Future<void> _getParameter() async {
    await _runAction(() async {
      final address = _addressController.text.trim();
      if (address.isEmpty) {
        throw const FaustEngineException('Enter a parameter address to read');
      }
      final value = await _engine.getParameter(address);
      _valueController.text = value.toStringAsFixed(3);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on FaustEngineException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _subscribeToMeters() {
    _meterSubscription ??= _engine.meterStream().listen(
      (event) {
        setState(() {
          _latestMeters = event;
        });
      },
      onError: (error) {
        _showSnack('Meter stream error: $error');
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Faust Engine Demo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _busy ? null : _initialize,
                    child: const Text('Initialize'),
                  ),
                  FilledButton(
                    onPressed: _busy || !_initialized ? null : _start,
                    child: const Text('Start'),
                  ),
                  FilledButton(
                    onPressed: _busy || !_initialized ? null : _stop,
                    child: const Text('Stop'),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy || !_initialized ? null : _teardown,
                    child: const Text('Teardown'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatusChip(label: 'Initialized', active: _initialized),
                  const SizedBox(width: 8),
                  _StatusChip(label: 'Running', active: _running),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Parameter controls',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'Select a parameter to control',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Value'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: _busy || !_initialized ? null : _setParameter,
                    child: const Text('Set parameter'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(enableFeedback: false),
                    onPressed: _busy || !_initialized ? null : _getParameter,
                    child: const Text('Read parameter'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_parameterAddresses.isNotEmpty) ...[
                Text('Published parameters (${_parameterAddresses.length})'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _parameterAddresses
                      .map(
                        (address) => Chip(
                          label: Text(address),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ] else
                const Text('Initialize to load Faust parameter addresses.'),
              const Divider(height: 32),
              Text('Meters', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_latestMeters == null)
                const Text('No meter data received yet.')
              else
                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        'Timestamp: ${_latestMeters!.timestamp.toIso8601String()}',
                      ),
                      const SizedBox(height: 8),
                      ..._latestMeters!.meters.entries.map(
                        (entry) => ListTile(
                          dense: true,
                          title: Text(entry.key),
                          trailing: Text(entry.value.toStringAsFixed(3)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      backgroundColor: active
          ? colorScheme.primaryContainer
          : colorScheme.surfaceVariant,
      avatar: Icon(
        active ? Icons.check_circle : Icons.cancel,
        color: active ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }
}
