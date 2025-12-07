import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    configureAudioSession()
    _ = faustEngine.start()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    faustEngine.stop()
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    _ = faustEngine.start()
  }

  deinit {
    faustEngine.teardown()
  }

  private lazy var faustEngine: FaustAudioEngine = {
    // Default to a 44.1 kHz render format and a modest buffer size that align with the
    // generated Faust driver defaults. This can be revisited once a concrete hardware
    // configuration is known.
    FaustAudioEngine(sampleRate: 44_100, bufferSize: 512)
  }()

  private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, options: [.mixWithOthers])
      try session.setPreferredSampleRate(44_100)
      try session.setPreferredIOBufferDuration(512.0 / 44_100.0)
      try session.setActive(true, options: [])
    } catch {
      NSLog("FaustAudioEngine: Failed to prime AVAudioSession: \(error)")
    }
  }
}
