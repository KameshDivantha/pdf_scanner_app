import Flutter
import UIKit
import VisionKit
import PhotosUI
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, VNDocumentCameraViewControllerDelegate, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    private var pendingResult: FlutterResult?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
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
            self?.pendingResult = result
            switch call.method {
            case "scanDocument":
                self?.startScan(controller: controller)
            case "pickImage":
                self?.startPHPicker(controller: controller, multiSelect: false)
            case "pickMultiImage":
                self?.startPHPicker(controller: controller, multiSelect: true)
            case "takeImage":
                self?.startCameraPicker(controller: controller)
            case "pickFile":
                self?.startFilePicker(controller: controller)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }

    // MARK: - Document Scanner
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
            if let path = saveImage(image: image, fileName: "scan_\(Int(Date().timeIntervalSince1970))_\(i).jpg") {
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

    // MARK: - PHPicker (Gallery)
    private func startPHPicker(controller: UIViewController, multiSelect: Bool) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = multiSelect ? 0 : 1 // 0 means no limit
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        controller.present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        let group = DispatchGroup()
        var paths = [String]()
        
        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                defer { group.leave() }
                if let image = object as? UIImage {
                    if let path = self?.saveImage(image: image, fileName: "picked_\(UUID().uuidString).jpg") {
                        paths.append(path)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if results.isEmpty {
                self.pendingResult?(nil)
            } else if results.count == 1 {
                self.pendingResult?(paths.first)
            } else {
                self.pendingResult?(paths)
            }
            self.pendingResult = nil
        }
    }

    // MARK: - Camera Picker
    private func startCameraPicker(controller: UIViewController) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            controller.present(picker, animated: true)
        } else {
            pendingResult?(FlutterError(code: "UNAVAILABLE", message: "Camera not available", details: nil))
            pendingResult = nil
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            if let path = saveImage(image: image, fileName: "captured_\(Int(Date().timeIntervalSince1970)).jpg") {
                pendingResult?(path)
            } else {
                pendingResult?(nil)
            }
        } else {
            pendingResult?(nil)
        }
        pendingResult = nil
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        pendingResult?(nil)
        pendingResult = nil
    }

    // MARK: - File Picker
    private func startFilePicker(controller: UIViewController) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        picker.delegate = self
        controller.present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            pendingResult?(url.path)
        } else {
            pendingResult?(nil)
        }
        pendingResult = nil
    }

    func documentPickerDidCancel(_ controller: UIDocumentPickerViewController) {
        pendingResult?(nil)
        pendingResult = nil
    }

    // MARK: - Helper
    private func saveImage(image: UIImage, fileName: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
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
