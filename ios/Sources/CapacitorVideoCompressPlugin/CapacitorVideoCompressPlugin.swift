import Foundation
import Capacitor
import AVFoundation

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(CapacitorVideoCompressPlugin)
public class CapacitorVideoCompressPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "CapacitorVideoCompressPlugin"
    public let jsName = "CapacitorVideoCompress"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "echo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "compressVideo", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = CapacitorVideoCompress()

    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.resolve([
            "value": implementation.echo(value)
        ])
    }

    @objc func compressVideo(_ call: CAPPluginCall) {
        guard let fileUri = call.getString("fileUri"),
              let inputFileUrl = URL(string: fileUri) else {
            call.reject("Invalid fileUri")
            return
        }
        
        print("compressVideo \(fileUri)")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let compressedVideoURL = documentsPath.appendingPathComponent("compressedVideo.mp4")

        let asset = AVAsset(url: inputFileUrl)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            call.reject("Failed to create AVAssetExportSession")
            return
        }
        
        if FileManager.default.fileExists(atPath: compressedVideoURL.path) {
            try? FileManager.default.removeItem(at: compressedVideoURL)
        }
        
        exportSession.outputURL = compressedVideoURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            switch exportSession.status {
                case .completed:
                    call.success(["compressedUri": compressedVideoURL.absoluteString])
                case .failed, .cancelled:
                    if let error = exportSession.error {
                        call.error("Video compression failed: \(error.localizedDescription)")
                    } else {
                        call.error("Video compression failed")
                    }
                case .exporting:
                    print("exporing")
                case .waiting:
                    print("waiting")
                case .unknown:
                    print("unknown")
                default:
                    call.error("Video compression failed")
            }
        }
    }
}
