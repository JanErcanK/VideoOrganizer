import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        let channel = FlutterMethodChannel(name: "clipfolio/share",
            binaryMessenger: engineBridge.applicationRegistrar.messenger())
        channel.setMethodCallHandler { call, result in
            do {
                switch call.method {
                case "pending":
                    result(try SharedInbox.files().map { try String(contentsOf: $0, encoding: .utf8) })
                case "ack":
                    guard let id = call.arguments as? String, UUID(uuidString: id) != nil else {
                        throw CocoaError(.fileReadInvalidFileName)
                    }
                    let file = try SharedInbox.folder.appendingPathComponent(id + ".json")
                    if FileManager.default.fileExists(atPath: file.path) {
                        try FileManager.default.removeItem(at: file)
                    }
                    result(nil)
                case "tags":
                    SharedInbox.defaults?.set(call.arguments as? [String], forKey: "tags")
                    result(nil)
                default: result(FlutterMethodNotImplemented)
                }
            } catch {
                result(FlutterError(code: "share_inbox", message: error.localizedDescription, details: nil))
            }
        }
    }
}