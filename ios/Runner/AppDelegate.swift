import Flutter
import UIKit
import VisionKit

@main
@objc class AppDelegate: FlutterAppDelegate, VNDocumentCameraViewControllerDelegate {
    private var pendingResult: FlutterResult?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Now that SceneDelegate is removed, window is reliably available here.
        if let controller = window?.rootViewController as? FlutterViewController {
            setupScannerChannel(controller: controller)
        }
        
        return result
    }

    private func setupScannerChannel(controller: FlutterViewController) {
        let channel = FlutterMethodChannel(name: "com.example.pdf_scanner_app/scanner",
                                          binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "scanDocument" {
                self?.pendingResult = result
                self?.startScan(controller: controller)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
    }

    private func startScan(controller: UIViewController) {
        if VNDocumentCameraViewController.isSupported {
            let scannerViewController = VNDocumentCameraViewController()
            scannerViewController.delegate = self
            controller.present(scannerViewController, animated: true)
        } else {
            pendingResult?(FlutterError(code: "UNSUPPORTED", message: "Document scanning is not supported on this device", details: nil))
            pendingResult = nil
        }
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var paths = [String]()
        for i in 0 ..< scan.pageCount {
            let image = scan.imageOfPage(at: i)
            if let path = saveImage(image: image, index: i) {
                paths.append(path)
            }
        }
        controller.dismiss(animated: true) {
            self.pendingResult?(paths)
            self.pendingResult = nil
        }
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) {
            self.pendingResult?(nil)
            self.pendingResult = nil
        }
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true) {
            self.pendingResult?(FlutterError(code: "SCAN_FAILED", message: error.localizedDescription, details: nil))
            self.pendingResult = nil
        }
    }

    private func saveImage(image: UIImage, index: Int) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = "scan_\(Int(Date().timeIntervalSince1970))_\(index).jpg"
        let path = NSTemporaryDirectory().appending(fileName)
        let url = URL(fileURLWithPath: path)
        do {
            try data.write(to: url)
            return path
        } catch {
            return nil
        }
    }
}
