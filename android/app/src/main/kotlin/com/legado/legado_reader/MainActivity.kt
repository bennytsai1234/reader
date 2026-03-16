package com.legado.legado_reader

import android.content.ComponentName
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.legado.reader/launcher_icon"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "changeIcon") {
                val iconName = call.argument<String>("iconName")
                changeIcon(iconName)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun changeIcon(iconName: String?) {
        val packageManager = context.packageManager
        val packageName = context.packageName
        
        // 所有可能的 Alias 名稱 (需與 AndroidManifest 一致)
        val aliases = listOf("Launcher1", "Launcher2")
        
        // 1. 處理預設 Activity
        if (iconName == null || iconName == "Default") {
            packageManager.setComponentEnabledSetting(
                ComponentName(context, "$packageName.MainActivity"),
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
        } else {
            packageManager.setComponentEnabledSetting(
                ComponentName(context, "$packageName.MainActivity"),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
        }

        // 2. 切換 Alias
        for (alias in aliases) {
            val state = if (alias == iconName) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }
            
            packageManager.setComponentEnabledSetting(
                ComponentName(context, "$packageName.$alias"),
                state,
                PackageManager.DONT_KILL_APP
            )
        }
    }
}
