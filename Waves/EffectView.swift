//
//  EffectView.swift
//  Waves
//
//  Created by Kuutti Taavitsainen on 19.4.2024.
//

import Foundation
import MetalKit

struct Vertex {
    var position: simd_float2
    var textureCoordinate: simd_float2
}

struct FragmentConstants {
    var time: Float
    var resX: Int
    var resY: Int
    
    init() {
        time = 0
        resX = 1920
        resY = 1080
    }
}

class EffectView: MTKView {
    var renderer: Renderer!
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice()
        EffectView.device = device
        EffectView.commandQueue = device!.makeCommandQueue()
        
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        self.preferredFramesPerSecond = 120
        
        renderer = Renderer()
        self.delegate = renderer
        
        let lib = RPStateLibrary.init()
    }
}
