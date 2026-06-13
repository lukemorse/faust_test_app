package com.example.faust_test_app

import dev.faust.FaustPlatformPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val faustPlugin = FaustPlatformPlugin()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        faustPlugin.register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
