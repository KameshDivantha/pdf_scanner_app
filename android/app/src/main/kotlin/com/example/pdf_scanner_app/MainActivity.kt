package com.example.pdf_scanner_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.RESULT_FORMAT_JPEG
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_FULL
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import java.io.File
import java.io.FileOutputStream
import androidx.core.content.FileProvider

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.pdf_scanner_app/scanner"
    private var pendingResult: MethodChannel.Result? = null
    
    private lateinit var pickImageLauncher: ActivityResultLauncher<PickVisualMediaRequest>
    private lateinit var pickMultiImageLauncher: ActivityResultLauncher<PickVisualMediaRequest>
    private lateinit var takeImageLauncher: ActivityResultLauncher<Uri>
    private lateinit var pickFileLauncher: ActivityResultLauncher<Array<String>>
    
    private var tempPhotoUri: Uri? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        pickImageLauncher = registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
            pendingResult?.success(uri?.let { copyToTempFile(it) })
            pendingResult = null
        }

        pickMultiImageLauncher = registerForActivityResult(ActivityResultContracts.PickMultipleVisualMedia()) { uris ->
            pendingResult?.success(uris.mapNotNull { copyToTempFile(it) })
            pendingResult = null
        }

        takeImageLauncher = registerForActivityResult(ActivityResultContracts.TakePicture()) { success ->
            if (success) {
                pendingResult?.success(tempPhotoUri?.let { uri -> getFilePathFromUri(uri) })
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }

        pickFileLauncher = registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            pendingResult?.success(uri?.let { copyToTempFile(it) })
            pendingResult = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanDocument" -> {
                    pendingResult = result
                    startScan()
                }
                "pickImage" -> {
                    pendingResult = result
                    pickImageLauncher.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }
                "pickMultiImage" -> {
                    pendingResult = result
                    pickMultiImageLauncher.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }
                "takeImage" -> {
                    pendingResult = result
                    val photoFile = File.createTempFile("IMG_", ".jpg", getExternalFilesDir("Pictures"))
                    tempPhotoUri = FileProvider.getUriForFile(this, "${packageName}.fileprovider", photoFile)
                    takeImageLauncher.launch(tempPhotoUri)
                }
                "pickFile" -> {
                    pendingResult = result
                    pickFileLauncher.launch(arrayOf("*/*"))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun copyToTempFile(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val fileName = "picked_${System.currentTimeMillis()}"
            val tempFile = File.createTempFile(fileName, null, cacheDir)
            val outputStream = FileOutputStream(tempFile)
            inputStream.copyTo(outputStream)
            inputStream.close()
            outputStream.close()
            tempFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }
    
    private fun getFilePathFromUri(uri: Uri): String? {
        // This is mainly for the FileProvider URI which already points to a file we created
        return if (uri.scheme == "content") {
            // For camera, we know where it is
            val fileName = uri.pathSegments.lastOrNull() ?: return null
            val file = File(getExternalFilesDir("Pictures"), fileName)
            file.absolutePath
        } else {
            uri.path
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
                    val paths = pages.mapNotNull { copyToTempFile(it.imageUri) }
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
