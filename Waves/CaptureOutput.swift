//
//  CaptureOutput.swift
//  Waves
//
//  Created by Kuutti Taavitsainen on 20.4.2024.
//

import Foundation
import ScreenCaptureKit

class Output: NSObject, SCStreamOutput, SCStreamDelegate {
    var stream: SCStream!
    var textureCache: CVMetalTextureCache?
    var display: SCDisplay!
    var apps: [SCRunningApplication]!
    var excepted: [SCWindow]!
    
    override init() {
        super.init()
        setupTextureCache()
    }
    
    func start() async{
        await getAvailable()
    
        let filter = SCContentFilter(display: display, excludingApplications: apps, exceptingWindows: excepted)
        
        let config = SCStreamConfiguration()
        
        config.capturesAudio = false
        
        config.width = display.width * 2
        config.height = display.height * 2

        config.captureResolution = SCCaptureResolutionType.best
        
        config.minimumFrameInterval = CMTime(value: 1, timescale: 120)
        
        config.pixelFormat = kCVPixelFormatType_32BGRA
        
        config.showsCursor = false
        
        stream = SCStream(filter: filter, configuration: config, delegate: self)
        
        try! stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: DispatchQueue(label: "StreamPatchQueue"))
        try! await stream.startCapture()
    }
    
    func getAvailable() async {
        do {
            let available: SCShareableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            display = available.displays.first
            apps = available.applications.filter { app in
                Bundle.main.bundleIdentifier == app.bundleIdentifier
            }
            excepted = available.windows.filter { window in
                window.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier
            }
        } catch let error as NSError { print(error) }
    }
    
    func setupTextureCache() {
        var cache: CVMetalTextureCache?
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, Renderer.device, nil, &cache) == kCVReturnSuccess else { return }
        textureCache = cache
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard sampleBuffer.isValid else { return }
        
        switch type {
        case .screen:
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            var texture: CVMetalTexture?
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &texture)
            
            Renderer.bgTexture = CVMetalTextureGetTexture(texture!)
        case .audio:
            return
        default:
            return
        }
    }
}

