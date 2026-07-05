package com.androdartstudio.flutteride.androdart_studio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL_PROOT = "com.androdartstudio.flutteride.androdart_studio/proot"
    private val CHANNEL_PTY = "com.androdartstudio.flutteride.androdart_studio/pty"
    private val CHANNEL_SDK = "com.androdartstudio.flutteride.androdart_studio/sdk"
    private val CHANNEL_PTY_OUTPUT = "com.androdartstudio.flutteride.androdart_studio/pty_output"
    private val CHANNEL_PTY_EXIT = "com.androdartstudio.flutteride.androdart_studio/pty_exit"

    private var currentPtySession: Long = 0
    private var ptyOutputChannel: MethodChannel? = null
    private var ptyExitChannel: MethodChannel? = null

    interface PtyCallback {
        fun onOutput(sessionId: Long, data: String)
        fun onExit(sessionId: Long, code: Int)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        ptyOutputChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PTY_OUTPUT)
        ptyExitChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PTY_EXIT)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PROOT).setMethodCallHandler { call, result ->
            when (call.method) {
                "getNativeLibDir" -> result.success(nativeGetNativeLibDir())
                "getFilesDir" -> result.success(filesDir.absolutePath)
                "extractRootfs" -> result.success(filesDir.absolutePath)
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PTY).setMethodCallHandler { call, result ->
            when (call.method) {
                "create" -> {
                    val command = call.argument<String>("command") ?: "/bin/bash"
                    val args = call.argument<List<String>>("args") ?: emptyList()
                    val envVars = call.argument<List<String>>("envVars") ?: emptyList()
                    val workingDir = call.argument<String>("workingDir") ?: "/"

                    val sessionId = nativeCreatePty(
                        object : PtyCallback {
                            override fun onOutput(sessionId: Long, data: String) {
                                runOnUiThread {
                                    ptyOutputChannel?.invokeMethod("onOutput", mapOf(
                                        "sessionId" to sessionId,
                                        "data" to data
                                    ))
                                }
                            }
                            override fun onExit(sessionId: Long, code: Int) {
                                runOnUiThread {
                                    ptyExitChannel?.invokeMethod("onExit", mapOf(
                                        "sessionId" to sessionId,
                                        "code" to code
                                    ))
                                }
                            }
                        },
                        command,
                        args.toTypedArray(),
                        envVars.toTypedArray(),
                        workingDir
                    )
                    currentPtySession = sessionId
                    result.success(sessionId)
                }
                "write" -> {
                    val sessionId = call.argument<Long>("sessionId") ?: currentPtySession
                    val input = call.argument<String>("input") ?: ""
                    val written = nativeWritePty(sessionId, input)
                    result.success(written)
                }
                "resize" -> {
                    val sessionId = call.argument<Long>("sessionId") ?: currentPtySession
                    val cols = call.argument<Int>("cols") ?: 80
                    val rows = call.argument<Int>("rows") ?: 24
                    nativeResizePty(sessionId, cols, rows)
                    result.success(null)
                }
                "close" -> {
                    val sessionId = call.argument<Long>("sessionId") ?: currentPtySession
                    nativeClosePty(sessionId)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SDK).setMethodCallHandler { call, result ->
            when (call.method) {
                "isInstalled" -> result.success(false)
                else -> result.notImplemented()
            }
        }
    }

    private external fun nativeCreatePty(
        callback: PtyCallback,
        command: String,
        args: Array<String>,
        envVars: Array<String>,
        workingDir: String
    ): Long

    private external fun nativeWritePty(sessionPtr: Long, input: String): Int
    private external fun nativeResizePty(sessionPtr: Long, cols: Int, rows: Int): Int
    private external fun nativeClosePty(sessionPtr: Long): Int
    private external fun nativeGetNativeLibDir(): String

    companion object {
        init {
            System.loadLibrary("pty")
        }
    }
}
