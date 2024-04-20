//
//  Renderer.swift
//  Waves
//
//  Created by Kuutti Taavitsainen on 20.4.2024.
//

import Foundation
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    
    var vertices: [Vertex] = [
        Vertex(position: simd_float2(-1.0,  1.0), textureCoordinate: simd_float2(0.0, 0.0)),
        Vertex(position: simd_float2( 1.0, -1.0), textureCoordinate: simd_float2(1.0, 1.0)),
        Vertex(position: simd_float2(-1.0, -1.0), textureCoordinate: simd_float2(0.0, 1.0)),
        Vertex(position: simd_float2(-1.0,  1.0), textureCoordinate: simd_float2(0.0, 0.0)),
        Vertex(position: simd_float2( 1.0,  1.0), textureCoordinate: simd_float2(1.0, 0.0)),
        Vertex(position: simd_float2( 1.0, -1.0), textureCoordinate: simd_float2(1.0, 1.0))
    ]
    
    var shader: ShaderType = .Underwater
    
    var fragConsts: FragmentConstants = FragmentConstants()
    var output: Output!
    static var bgTexture: MTLTexture!
    
    override init() {
        super.init()
        output = Output()
        Task(operation: output.start)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        fragConsts.resX = Int(view.bounds.width)
        fragConsts.resY = Int(view.bounds.height)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable, let rpDescriptor = view.currentRenderPassDescriptor else { return }
        
        fragConsts.time += 1.0 / Float(view.preferredFramesPerSecond)
        
        drawable.layer.isOpaque = false
        
        let commandBuffer = EffectView.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rpDescriptor)
        commandEncoder?.setRenderPipelineState(RPStateLibrary.getPipeline(shader: shader))
        commandEncoder?.setVertexBytes(&vertices, length: MemoryLayout<Vertex>.stride * 6, index: 0)
        commandEncoder?.setFragmentBytes(&fragConsts, length: MemoryLayout<FragmentConstants>.stride, index: 1)
        commandEncoder?.setFragmentTexture(Renderer.bgTexture, index: 0)
        commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        commandEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}

