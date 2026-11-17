package de.clipfolio.clipfolio

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.UUID

class MainActivity : FlutterActivity() {
    private var bridge: MethodChannel? = null
    private val inbox by lazy { getSharedPreferences("share_inbox", MODE_PRIVATE) }

    override fun onCreate(savedInstanceState: Bundle?) {
        if (savedInstanceState == null) receive(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        receive(intent)
    }

    private fun receive(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
            ?: intent.clipData?.takeIf { it.itemCount > 0 }?.getItemAt(0)?.text?.toString()
            ?: return
        val id = UUID.randomUUID().toString()
        inbox.edit().putString(id, JSONObject().put("id", id).put("text", text)
            .put("created", System.currentTimeMillis()).toString()).apply()
        bridge?.invokeMethod("incoming", null)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "clipfolio/share")
        bridge?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pending" -> result.success(inbox.all.values.filterIsInstance<String>())
                "ack" -> {
                    inbox.edit().remove(call.arguments as String).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}