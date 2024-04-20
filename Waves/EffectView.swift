//
//  EffectView.swift
//  Waves
//
//  Created by Kuutti Taavitsainen on 19.4.2024.
//

import Foundation
import SwiftUI
import MetalKit

struct Vertex {
    var position: simd_float2
    var textureCoordinate: simd_float2
}

struct FragmentConstants {
    var time: Float
    var resX: Float
    var resY: Float
    
    init() {
        time = 0
        resX = 1920
        resY = 1080
    }
}

class EffectView: MTKView {
    var renderer: Renderer = Renderer()
    required init(coder: NSCoder) {
        super.init(coder: coder)
        if let device = MTLCreateSystemDefaultDevice() {
            self.device = device
        }
        
        self.delegate = renderer
        Renderer.device = self.device
        Renderer.commandQueue = Renderer.device.makeCommandQueue()
        
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        self.preferredFramesPerSecond = 60
        
        let lib = RPStateLibrary()
        lib.initialize()
    }
}
