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
      guard let engine = engine else {
        result(false)
        return
      }
      result(engine.start())

    case "stop":
      engine?.stop()
      result(nil)

    case "teardown":
      stopMetering()
      engine?.teardown()
      engine = nil
      result(nil)

    case "isRunning":
      result(engine?.isRunning() ?? false)

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
      engine?.setParameter(address, value: value.floatValue)
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
      let value = engine?.getParameter(address) ?? 0.0
      result(Double(value))

    case "listParameters":
      result(engine?.parameterAddresses() ?? [])

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

    if engine == nil {
      engine = FaustAudioEngine(sampleRate: sampleRate.intValue, bufferSize: bufferSize.intValue)
      meterAddresses = engine?.parameterAddresses() as? [String] ?? []
    }
    return engine != nil
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
    guard let sink = metersEventSink, let engine else { return }

    if meterAddresses.isEmpty {
      meterAddresses = engine.parameterAddresses() as? [String] ?? []
    }

    var values: [String: Double] = [:]
    for address in meterAddresses {
      values[address] = Double(engine.getParameter(address))
    }

    sink([
      "timestampMs": Int(Date().timeIntervalSince1970 * 1000),
      "meters": values,
    ])
  }
}
