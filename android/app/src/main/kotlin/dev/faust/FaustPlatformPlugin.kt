package dev.faust

import android.os.Handler
import android.os.Looper
import com.DspFaust.DspFaust
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Android counterpart to the iOS FaustPlatformPlugin. Exposes the generated
 * [DspFaust] engine over the same platform channels so the Dart API is identical
 * across platforms.
 *
 * Engine calls run on a single-threaded executor (mirroring the iOS serial
 * control queue); method results and event payloads are posted back to the main
 * thread, which Flutter requires.
 */
class FaustPlatformPlugin :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private companion object {
        const val CONTROL_CHANNEL = "dev.faust/engine"
        const val METERS_CHANNEL = "dev.faust/engine/meters"
        const val METER_INTERVAL_MS = 1000L / 30L
    }

    private val control = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var engine: DspFaust? = null
    private var eventSink: EventChannel.EventSink? = null
    private var meterAddresses: List<String> = emptyList()
    private var meterRunnable: Runnable? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CONTROL_CHANNEL).setMethodCallHandler(this)
        EventChannel(messenger, METERS_CHANNEL).setStreamHandler(this)
    }

    // MARK: - Method channel

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val sampleRate = call.argument<Int>("sampleRate")
                val bufferSize = call.argument<Int>("bufferSize")
                if (sampleRate == null || bufferSize == null) {
                    reply(result, false)
                    return
                }
                control.execute {
                    if (engine == null) {
                        engine = DspFaust(sampleRate, bufferSize)
                        meterAddresses = currentAddresses()
                    }
                    reply(result, engine != null)
                }
            }

            "start" -> control.execute { reply(result, engine?.start() ?: false) }

            "stop" -> control.execute {
                engine?.stop()
                reply(result, null)
            }

            "teardown" -> {
                stopMetering()
                control.execute {
                    engine?.let {
                        it.stop()
                        it.delete()
                    }
                    engine = null
                    meterAddresses = emptyList()
                    reply(result, null)
                }
            }

            "isRunning" -> control.execute { reply(result, engine?.isRunning ?: false) }

            "setParameter" -> {
                val address = call.argument<String>("address")
                val value = call.argument<Double>("value")
                if (address == null || value == null) {
                    result.error("bad_args", "setParameter expects { address: string, value: double }", null)
                    return
                }
                control.execute {
                    engine?.setParamValue(address, value.toFloat())
                    reply(result, null)
                }
            }

            "getParameter" -> {
                val address = call.argument<String>("address")
                if (address == null) {
                    result.error("bad_args", "getParameter expects { address: string }", null)
                    return
                }
                control.execute {
                    reply(result, (engine?.getParamValue(address) ?: 0.0f).toDouble())
                }
            }

            "listParameters" -> control.execute {
                val addresses = currentAddresses()
                meterAddresses = addresses
                reply(result, addresses)
            }

            else -> result.notImplemented()
        }
    }

    private fun currentAddresses(): List<String> {
        val dsp = engine ?: return emptyList()
        val count = dsp.paramsCount
        return (0 until count).mapNotNull { dsp.getParamAddress(it) }
    }

    private fun reply(result: MethodChannel.Result, value: Any?) {
        mainHandler.post { result.success(value) }
    }

    // MARK: - Meter streaming

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
        startMetering()
    }

    override fun onCancel(arguments: Any?) {
        stopMetering()
        eventSink = null
    }

    private fun startMetering() {
        if (meterRunnable != null) return
        val runnable = object : Runnable {
            override fun run() {
                control.execute { emitMeters() }
                mainHandler.postDelayed(this, METER_INTERVAL_MS)
            }
        }
        meterRunnable = runnable
        mainHandler.post(runnable)
    }

    private fun stopMetering() {
        meterRunnable?.let { mainHandler.removeCallbacks(it) }
        meterRunnable = null
    }

    private fun emitMeters() {
        val dsp = engine ?: return
        if (eventSink == null) return
        if (meterAddresses.isEmpty()) meterAddresses = currentAddresses()

        val values = HashMap<String, Double>()
        for (address in meterAddresses) {
            values[address] = dsp.getParamValue(address).toDouble()
        }
        val payload = hashMapOf(
            "timestampMs" to System.currentTimeMillis(),
            "meters" to values,
        )
        mainHandler.post { eventSink?.success(payload) }
    }
}
