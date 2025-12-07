import Foundation
import Flutter

/// Flutter-facing bridge that exposes the Faust audio engine over platform channels.
///
/// Methods are handled on the main thread and forward to the lightweight Swift/ObjC++
/// wrapper, keeping the audio thread untouched.
final class FaustPlatformPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private enum ChannelName {
    static let control = "dev.faust/engine"
    static let meters = "dev.faust/engine/meters"
  }

  private let meterInterval: TimeInterval = 1.0 / 30.0
  private let controlQueue = DispatchQueue(
    label: "dev.faust.engine.control",
    qos: .userInitiated
  )
  private var engine: FaustAudioEngine?
  private var metersEventSink: FlutterEventSink?
  private var meterTimer: Timer?
  private var meterAddresses: [String] = []

  // MARK: - Registration

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FaustPlatformPlugin()
    let controlChannel = FlutterMethodChannel(
      name: ChannelName.control,
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: controlChannel)

    let metersChannel = FlutterEventChannel(
      name: ChannelName.meters,
      binaryMessenger: registrar.messenger()
    )
    metersChannel.setStreamHandler(instance)
  }

  // MARK: - Method channel

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      result(handleInitialize(arguments: call.arguments))

    case "start":
      let didStart = controlQueue.sync { [weak self] in
        guard let self, let engine = self.engine else { return false }
        return engine.start()
      }
      result(didStart)

    case "stop":
      controlQueue.sync { [weak self] in
        self?.engine?.stop()
      }
      result(nil)

    case "teardown":
      stopMetering()
      controlQueue.sync { [weak self] in
        guard let self else { return }
        self.engine?.teardown()
        self.engine = nil
        self.meterAddresses.removeAll()
      }
      result(nil)

    case "isRunning":
      let running = controlQueue.sync { [weak self] in
        self?.engine?.isRunning() ?? false
      }
      result(running)

    case "setParameter":
      guard let args = call.arguments as? [String: Any],
            let address = args["address"] as? String,
            let value = args["value"] as? NSNumber else {
        result(FlutterError(
          code: "bad_args",
          message: "setParameter expects { address: string, value: double }",
          details: nil
        ))
        return
      }
      controlQueue.sync { [weak self] in
        self?.engine?.setParameter(address, value: value.floatValue)
      }
      result(nil)

    case "getParameter":
      guard let args = call.arguments as? [String: Any],
            let address = args["address"] as? String else {
        result(FlutterError(
          code: "bad_args",
          message: "getParameter expects { address: string }",
          details: nil
        ))
        return
      }
      let value = controlQueue.sync { [weak self] in
        self?.engine?.getParameter(address) ?? 0.0
      }
      result(Double(value))

    case "listParameters":
      let parameters = controlQueue.sync { [weak self] in
        guard let self, let engine = self.engine else { return [] }
        let addresses = engine.parameterAddresses() as? [String] ?? []
        self.meterAddresses = addresses
        return addresses
      }
      result(parameters)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleInitialize(arguments: Any?) -> Bool {
    guard let args = arguments as? [String: Any],
          let sampleRate = args["sampleRate"] as? NSNumber,
          let bufferSize = args["bufferSize"] as? NSNumber else {
      return false
    }

    return controlQueue.sync { [weak self] in
      guard let self else { return false }

      if engine == nil {
        engine = FaustAudioEngine(
          sampleRate: Int32(sampleRate.intValue),
          bufferSize: Int32(bufferSize.intValue)
        )
        meterAddresses = engine?.parameterAddresses() as? [String] ?? []
      }
      return engine != nil
    }
  }

  // MARK: - Meter streaming

  func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
    metersEventSink = eventSink
    startMetering()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stopMetering()
    metersEventSink = nil
    return nil
  }

  private func startMetering() {
    guard meterTimer == nil else { return }

    let timer = Timer(timeInterval: meterInterval, repeats: true) { [weak self] _ in
      self?.emitMeters()
    }
    meterTimer = timer
    RunLoop.main.add(timer, forMode: .common)
  }

  private func stopMetering() {
    meterTimer?.invalidate()
    meterTimer = nil
  }

  private func emitMeters() {
    controlQueue.async { [weak self] in
      guard let self else { return }
      guard let sink = self.metersEventSink, let engine = self.engine else { return }

      if self.meterAddresses.isEmpty {
        self.meterAddresses = engine.parameterAddresses() as? [String] ?? []
      }

      var values: [String: Double] = [:]
      for address in self.meterAddresses {
        values[address] = Double(engine.getParameter(address))
      }

      let payload: [String: Any] = [
        "timestampMs": Int(Date().timeIntervalSince1970 * 1000),
        "meters": values,
      ]

      DispatchQueue.main.async {
        sink(payload)
      }
    }
  }
}
