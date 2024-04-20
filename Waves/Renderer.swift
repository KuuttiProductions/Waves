//
//  Renderer.swift
//  Waves
//
//  Created by Kuutti Taavitsainen on 20.4.2024.
//

import Foundation
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    
    var vertices: [Vertex] = [
        Vertex(position: simd_float2(-1.0,  1.0), textureCoordinate: simd_float2(0.0, 0.0)),
        Vertex(position: simd_float2( 1.0, -1.0), textureCoordinate: simd_float2(1.0, 1.0)),
        Vertex(position: simd_float2(-1.0, -1.0), textureCoordinate: simd_float2(0.0, 1.0)),
        Vertex(position: simd_float2(-1.0,  1.0), textureCoordinate: simd_float2(0.0, 0.0)),
        Vertex(position: simd_float2( 1.0,  1.0), textureCoordinate: simd_float2(1.0, 0.0)),
        Vertex(position: simd_float2( 1.0, -1.0), textureCoordinate: simd_float2(1.0, 1.0))
    ]
    
    static var shader: ShaderType = .Underwater
    
    var deltaTime: Float = 0.0
    var fragConsts: FragmentConstants = FragmentConstants()
    var output: Output!
    static var bgTexture: MTLTexture!
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        output = Output()
        Task(operation: output.start)
        fragConsts.resX = Float(view.bounds.width)
        fragConsts.resY = Float(view.bounds.height)
        view.preferredFramesPerSecond = 60
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable, let rpDescriptor = view.currentRenderPassDescriptor else { return }
    
        fragConsts.time += 1.0 / Float(view.preferredFramesPerSecond)
        
        drawable.layer.isOpaque = false
        
        let commandBuffer = Renderer.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rpDescriptor)
        commandEncoder?.setRenderPipelineState(RPStateLibrary.getPipeline(shader: Renderer.shader))
        commandEncoder?.setVertexBytes(&vertices, length: MemoryLayout<Vertex>.stride * 6, index: 0)
        commandEncoder?.setFragmentBytes(&fragConsts, length: MemoryLayout<FragmentConstants>.stride, index: 0)
        commandEncoder?.setFragmentTexture(Renderer.bgTexture, index: 0)
        commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        commandEncoder?.endEncoding()
        
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}

