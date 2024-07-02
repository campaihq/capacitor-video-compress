import Foundation
import Capacitor
import AVFoundation

private let MIN_BITRATE = Float(1400000)
private let MIN_HEIGHT = 640.0
private let MIN_WIDTH = 360.0

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
    
    var isFirstBuffer = true
    
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
        
        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            call.reject("No tracks found")
            return
        }
        
        let videoWriter: AVAssetWriter
        do {
            videoWriter = try AVAssetWriter(outputURL: compressedVideoURL, fileType: AVFileType.mov)
        } catch {
            call.reject("AVAssetWriter error: \(error.localizedDescription)")
            return
        }
        
        let videoReader: AVAssetReader
        do {
            videoReader = try AVAssetReader(asset: asset)
        } catch {
            call.reject("AVAssetReader error: \(error.localizedDescription)")
            return
        }
        
        let bitrate = calculateNewBitrate(videoTrack)
        let size: (width: Int, height: Int) = calculateNewResolution(videoTrack)
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: getWriteSettings(Int(bitrate), size.width, size.height))
        videoWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.transform = videoTrack.preferredTransform
        videoWriter.add(videoWriterInput)
        
        let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: getReaderSettings())
        videoReader.add(videoReaderOutput)
        
        let audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
        audioWriterInput.expectsMediaDataInRealTime = false
        videoWriter.add(audioWriterInput)
        
        let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first
        var audioReader: AVAssetReader?
        var audioReaderTrackOutput: AVAssetReaderTrackOutput?
        if (audioTrack != nil) {
            audioReaderTrackOutput = AVAssetReaderTrackOutput(track: audioTrack!, outputSettings: nil)
            audioReader = try? AVAssetReader(asset: asset)
            audioReader?.add(audioReaderTrackOutput!)
        }
        
        if FileManager.default.fileExists(atPath: compressedVideoURL.path) {
            try? FileManager.default.removeItem(at: compressedVideoURL)
        }
        
        videoWriter.startWriting()
        videoReader.startReading()
        videoWriter.startSession(atSourceTime: .zero)
        
        let processingQueue = DispatchQueue(label: "queue.video", qos: .background)
        
        isFirstBuffer = true
        
        videoWriterInput.requestMediaDataWhenReady(on: processingQueue) {
            self.processVideoFrame(videoWriter, videoWriterInput, videoReader, videoReaderOutput, audioWriterInput, audioReader, audioReaderTrackOutput) {
                self.handleCompletion(call, compressedVideoURL, videoWriter, videoReader, audioReader)
            }
        }
    }
    
    private func handleCompletion(
        _ call: CAPPluginCall,
        _ compressedVideoURL: URL,
        _ videoWriter: AVAssetWriter,
        _ videoReader: AVAssetReader,
        _ audioReader: AVAssetReader?
    ) {
        switch videoWriter.status {
            case .completed:
                call.resolve(["compressedUri": compressedVideoURL.absoluteString])
            
            case .failed, .cancelled:
                if let error = videoWriter.error {
                    call.reject("Video compression failed: \(error.localizedDescription)")
                } else {
                    call.reject("Video compression failed")
                }
            
            default:
                if videoReader.status == .failed {
                    if let error = videoReader.error {
                        call.reject("Video reader failed: \(error.localizedDescription)")
                    } else {
                        call.reject("Video reader failed")
                    }
                } else if audioReader?.status == .failed {
                    if let error = audioReader?.error {
                        call.reject("Audio reader failed: \(error.localizedDescription)")
                    } else {
                        call.reject("Audio reader failed")
                    }
                } else {
                    call.reject("Video compression failed")
                }
        }
    }
    
    private func processVideoFrame(
        _ videoWriter: AVAssetWriter,
        _ videoWriterInput: AVAssetWriterInput,
        _ videoReader: AVAssetReader,
        _ videoReaderTrackOutput: AVAssetReaderTrackOutput,
        _ audioWriterInput: AVAssetWriterInput,
        _ audioReader: AVAssetReader?,
        _ audioReaderTrackOutput: AVAssetReaderTrackOutput?,
        _ completion: @escaping () -> Void
    ) {
        while videoWriterInput.isReadyForMoreMediaData {
            if videoReader.status == .cancelled {
                completion()
                break
            }
            if videoReader.status == .failed {
                completion()
                break
            }
            
            let sampleBuffer = videoReaderTrackOutput.copyNextSampleBuffer()
            
            if videoReader.status == .reading && sampleBuffer != nil {
                videoWriterInput.append(sampleBuffer!)
            } else {
                if videoReader.status == .completed {
                    videoWriterInput.markAsFinished()
                    
                    if let audioReader, let audioReaderTrackOutput {
                        if audioReader.status != .reading || audioReader.status != .completed {
                            audioReader.startReading()
                            videoWriter.startSession(atSourceTime: .zero)
                            
                            let processingQueue = DispatchQueue(label: "queue.audio", qos: .background)
                            
                            audioWriterInput.requestMediaDataWhenReady(on: processingQueue) {
                                self.processAudioFrame(videoWriter, audioWriterInput, audioReader, audioReaderTrackOutput, completion)
                            }
                        }
                    } else {
                        videoWriter.finishWriting {
                            completion()
                        }
                    }
                    
                    break
                }
            }
        }
    }
    
    private func processAudioFrame(
        _ videoWriter: AVAssetWriter,
        _ audioWriterInput: AVAssetWriterInput,
        _ audioReader: AVAssetReader,
        _ audioReaderTrackOutput: AVAssetReaderTrackOutput,
        _ completion: @escaping () -> Void
    ) {
        while audioWriterInput.isReadyForMoreMediaData {
            if audioReader.status == .cancelled {
                completion()
                break
            }
            if audioReader.status == .failed {
                completion()
                break
            }
            
            let sampleBuffer = audioReaderTrackOutput.copyNextSampleBuffer()
            
            if audioReader.status == .reading && sampleBuffer != nil {
                if self.isFirstBuffer {
                    let dict = CMTimeCopyAsDictionary(CMTimeMake(value: 1024, timescale: 44100), allocator: kCFAllocatorDefault);
                    CMSetAttachment(sampleBuffer as CMAttachmentBearer, key: kCMSampleBufferAttachmentKey_TrimDurationAtStart, value: dict, attachmentMode: kCMAttachmentMode_ShouldNotPropagate);
                    self.isFirstBuffer = false
                }
                audioWriterInput.append(sampleBuffer!)
            } else {
                audioWriterInput.markAsFinished()
                
                videoWriter.finishWriting {
                    completion()
                }
                
                break
            }
        }
    }
    
    /**
     * Calculates a new bitrate based on the estimated data rate of a given video track.
     *
     * - Parameter videoTrack: The `AVAssetTrack` representing the video track for which to calculate the new bitrate.
     * - Returns: A `Float` value representing the calculated new bitrate.
     */
    private func calculateNewBitrate(_ videoTrack: AVAssetTrack) -> Float {
        let bitrate = videoTrack.estimatedDataRate
        var newBitrate = bitrate * 0.125
        if (newBitrate < MIN_BITRATE){
            newBitrate = min(MIN_BITRATE, bitrate)
        }
        return newBitrate
    }
    
    /**
     * Calculates new video dimensions based on resolution categories:
     * - For very high resolutions (width or height >= 1920), it reduces dimensions to 50%.
     * - For high resolutions (width or height >= 1280), it reduces dimensions to 75%.
     * - For medium resolutions (width or height >= 960), it adjusts dimensions to 95% of minimum height and width, maintaining aspect ratio.
     * - For lower resolutions, preserves the original size.
     *
     * The new dimensions are adjusted to be multiples of 16 for optimal compression efficiency when using the H.264 codec.
     */

    private func calculateNewResolution(_ videoTrack: AVAssetTrack) -> (width: Int, height: Int) {
        let size = videoTrack.naturalSize
        let width = size.width
        let height = size.height
        
        var newWidth = Int(width)
        var newHeight = Int(height)
        
        switch (width, height) {
            case let (w, h) where w >= 1920 || h >= 1920:
                newWidth = Int(width * 0.5 / 16) * 16
                newHeight = Int(height * 0.5 / 16) * 16
                
            case let (w, h) where w >= 1280 || h >= 1280:
                newWidth = Int(width * 0.75 / 16) * 16
                newHeight = Int(height * 0.75 / 16) * 16
                
            case let (w, h) where w >= 960 || h >= 960:
                if w > h {
                    newWidth = Int(MIN_HEIGHT * 0.95 / 16) * 16
                    newHeight = Int(MIN_WIDTH * 0.95 / 16) * 16
                } else {
                    newWidth = Int(MIN_WIDTH * 0.95 / 16) * 16
                    newHeight = Int(MIN_HEIGHT * 0.95 / 16) * 16
                }
                
            default: break
        }
        
        return (newWidth, newHeight)
    }
    
    private func getWriteSettings(_ bitrate: Int, _ width: Int, _ height: Int) -> [String : AnyObject] {
        let videoWriterCompressionSettings = [
            AVVideoAverageBitRateKey : bitrate
        ]
        
        let videoWriterSettings: [String : AnyObject] = [
            AVVideoCodecKey : AVVideoCodecType.h264 as AnyObject,
            AVVideoCompressionPropertiesKey : videoWriterCompressionSettings as AnyObject,
            AVVideoWidthKey : width as AnyObject,
            AVVideoHeightKey : height as AnyObject
        ]
        
        return videoWriterSettings
    }
    
    private func getReaderSettings() ->  [String : AnyObject] {
        let videoReaderSettings:[String : AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) as AnyObject
        ]
        
        return videoReaderSettings
    }
}
