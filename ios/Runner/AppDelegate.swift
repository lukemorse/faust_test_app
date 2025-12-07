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
    registerFaustPlugin()
    configureAudioSession()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerFaustPlugin() {
    guard let registrar = self.registrar(forPlugin: "FaustPlatformPlugin") else { return }
    FaustPlatformPlugin.register(with: registrar)
  }

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
