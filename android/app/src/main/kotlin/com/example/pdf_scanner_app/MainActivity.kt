package com.example.pdf_scanner_app

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.RESULT_FORMAT_JPEG
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_FULL
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.pdf_scanner_app/scanner"
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scanDocument") {
                pendingResult = result
                startScan()
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startScan() {
        val options = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(true)
            .setResultFormats(RESULT_FORMAT_JPEG)
            .setScannerMode(SCANNER_MODE_FULL)
            .build()

        val scanner = GmsDocumentScanning.getClient(options)
        
        scanner.getStartScanIntent(this)
            .addOnSuccessListener { intentSender ->
                startIntentSenderForResult(intentSender, 1001, null, 0, 0, 0)
            }
            .addOnFailureListener { e ->
                pendingResult?.error("SCAN_FAILED", e.message, null)
                pendingResult = null
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1001) {
            if (resultCode == Activity.RESULT_OK) {
                val result = GmsDocumentScanningResult.fromActivityResultIntent(data)
                result?.pages?.let { pages ->
                    val paths = pages.map { it.imageUri.toString() }
                    pendingResult?.success(paths)
                } ?: run {
                    pendingResult?.success(emptyList<String>())
                }
            } else if (resultCode == Activity.RESULT_CANCELED) {
                pendingResult?.success(null)
            } else {
                pendingResult?.error("SCAN_ERROR", "Scanner failed with code $resultCode", null)
            }
            pendingResult = null
        }
    }
}
