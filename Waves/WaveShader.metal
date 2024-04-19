//
//  WaveShader.metal
//  Waves
//
//  Created by Kuutti Taavitsainen on 19.4.2024.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[ attribute(0) ]];
    float2 textureCoordinate [[ attribute(1) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

vertex VertexOut wave_vertex(VertexIn verIn [[ stage_in ]]) {
    VertexOut verOut;
    
    verOut.position = float4(verIn.position, 1, 1);
    verOut.textureCoordinate = verIn.textureCoordinate;
    
    return verOut;
}

constexpr sampler sampler2d = sampler();

fragment half4 wave_fragment(VertexOut verIn [[ stage_in]],
                             constant float &time [[ buffer(1) ]],
                             texture2d<float> source [[ texture(0) ]]) {
    
    half4 color = half4();
    
    //float wave = sin(verIn.textureCoordinate.x * 100 + time * 10) * 0.5 + 0.5;
    color = half4(source.sample(sampler2d, verIn.textureCoordinate + float2(0.1, 0.1)));
    
    return color;
}
