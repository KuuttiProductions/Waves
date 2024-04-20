//
//  rpStateLibrary.swift
//  Waves
//
//  Created by Kuutti Taavitsainen on 20.4.2024.
//

import Foundation
import MetalKit

class VertexDescriptor {
    let vertexDescriptor: MTLVertexDescriptor!
    init() {
        vertexDescriptor = MTLVertexDescriptor()
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
    }
}

enum ShaderType {
    case Underwater
    case CosmicSwirl
}

class RPStateLibrary {
    var shaderLib = EffectView.device?.makeDefaultLibrary()
    var vertexShader: MTLFunction!
    var descriptor: MTLVertexDescriptor = VertexDescriptor().vertexDescriptor
    
    static private var _library: [ShaderType : RPState] = [:]
    
    init() {
        vertexShader = shaderLib!.makeFunction(name: "wave_vertex")
        RPStateLibrary._library.updateValue(RPState(shaderName: "wave_fragment", lib: self), forKey: .Underwater)
        RPStateLibrary._library.updateValue(RPState(shaderName: "cosmic_swirl_fragment", lib: self), forKey: .CosmicSwirl)
    }
    
    static func getPipeline(shader: ShaderType)-> MTLRenderPipelineState {
        return RPStateLibrary._library[shader]!.rpState
    }
}

class RPState {
    var rpState: MTLRenderPipelineState!
    init(shaderName: String, lib: RPStateLibrary) {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.vertexDescriptor = lib.descriptor
        descriptor.vertexFunction = lib.vertexShader
        descriptor.fragmentFunction = lib.shaderLib?.makeFunction(name: shaderName)
        
        do {
            rpState = try EffectView.device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error as NSError { print(error) }
    }
}
