//
//  EffectView.swift
//  Waves
//
//  Created by Kuutti Taavitsainen on 19.4.2024.
//

import Foundation
import MetalKit
import ScreenCaptureKit

struct Vertex {
    var position: simd_float2
    var textureCoordinate: simd_float2
}

class Output: NSObject, SCStreamOutput, SCStreamDelegate {
    var stream: SCStream!
    var textureCache: CVMetalTextureCache?
    var display: SCDisplay!
    
    override init() {
        super.init()
        setupTextureCache()
    }
    
    func start() async{
            await getAvailable()
        
            let filter = SCContentFilter(display: display, including: [])
            
            let config = SCStreamConfiguration()
            
            config.capturesAudio = false
            
            config.width = 3456
            config.height = 2234
            
            config.minimumFrameInterval = CMTime(value: 1, timescale: 120)
            
            stream = SCStream(filter: filter, configuration: config, delegate: self)
            
            try! await stream.startCapture()
            try! stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: DispatchQueue(label: "StreamPatchQueue"))
    }
    
    func getAvailable() async {
        do {
            let available: SCShareableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            display = available.displays.first
        } catch let error as NSError { print(error) }
    }
    
    func setupTextureCache() {
        var cache: CVMetalTextureCache?
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, EffectView.device, nil, &cache) == kCVReturnSuccess else { return }
        textureCache = cache
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        print("STREAM")
        guard sampleBuffer.isValid else { return }
        
        switch type {
        case .screen:
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            var texture: CVMetalTexture?
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &texture)
            
            EffectView.bgTexture = CVMetalTextureGetTexture(texture!)
        case .audio:
            return
        default:
            return
        }
    }
}

class EffectView: MTKView {
    
    var vertices: [Vertex] = [
        Vertex(position: simd_float2(-1.0,  1.0), textureCoordinate: simd_float2(0.0, 0.0)),
        Vertex(position: simd_float2( 1.0, -1.0), textureCoordinate: simd_float2(1.0, 1.0)),
        Vertex(position: simd_float2(-1.0, -1.0), textureCoordinate: simd_float2(0.0, 1.0)),
        Vertex(position: simd_float2(-1.0,  1.0), textureCoordinate: simd_float2(0.0, 0.0)),
        Vertex(position: simd_float2( 1.0,  1.0), textureCoordinate: simd_float2(1.0, 0.0)),
        Vertex(position: simd_float2( 1.0, -1.0), textureCoordinate: simd_float2(1.0, 1.0))
    ]
    
    static var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var rpState: MTLRenderPipelineState!
    var time: Float = 0.0
    
    var output: Output!
    static var bgTexture: MTLTexture!
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice()
        EffectView.device = device
        self.commandQueue = device!.makeCommandQueue()
        
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        self.preferredFramesPerSecond = 120
        
        createRenderPipelineState()
        
        output = Output()

        Task(operation: output.start)
    }
    
    func createRenderPipelineState() {
        let library = device?.makeDefaultLibrary()
        let vertexShader = library?.makeFunction(name: "wave_vertex")
        let fragmentShader = library?.makeFunction(name: "wave_fragment")
        
        let vertexDescriptor = MTLVertexDescriptor()
        var totalOffset: Int = 0
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = totalOffset
        totalOffset += MemoryLayout<simd_float2>.stride
        
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = totalOffset
        totalOffset += MemoryLayout<simd_float3>.stride
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        let rpDescriptor = MTLRenderPipelineDescriptor()
        rpDescriptor.vertexDescriptor = vertexDescriptor
        rpDescriptor.vertexFunction = vertexShader
        rpDescriptor.fragmentFunction = fragmentShader
        rpDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            rpState = try device?.makeRenderPipelineState(descriptor: rpDescriptor)
        } catch let error as NSError {
            print(error)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let drawable = currentDrawable, let rpDescriptor = currentRenderPassDescriptor else { return }
        
        time += 1.0 / Float(preferredFramesPerSecond)
        
        drawable.layer.isOpaque = false
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rpDescriptor)
        commandEncoder?.setRenderPipelineState(rpState)
        commandEncoder?.setVertexBytes(&vertices, length: MemoryLayout<Vertex>.stride * 6, index: 0)
        commandEncoder?.setFragmentBytes(&time, length: MemoryLayout<Float>.stride, index: 1)
        commandEncoder?.setFragmentTexture(EffectView.bgTexture, index: 0)
        commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        commandEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
