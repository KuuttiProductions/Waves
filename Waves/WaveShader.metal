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

constexpr sampler sampler2d = sampler(address::clamp_to_zero,
                                      min_filter::linear,
                                      mag_filter::linear);

fragment half4 wave_fragment(VertexOut verIn [[ stage_in]],
                             constant float &time [[ buffer(1) ]],
                             texture2d<float> source [[ texture(0) ]]) {
    
    half4 color = half4();
    
    float wave = sin(verIn.textureCoordinate.x * 30 + time * 2) * 0.5 + 0.5;
    float4 sample = float4(float3(source.sample(sampler2d, verIn.textureCoordinate + float2(wave * 0.01, wave * 0.01))), 1.0);
    color = half4(sample.r, sample.g, sample.b, sample.a);
    
    return color;
}
