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

struct fragmentConstants {
    float time;
    int resX;
    int resY;
};

float3 palette(float t) {
    float3 a = float3(0.4, 0.4, 0.5);
    float3 b = float3(0.5, 0.5, 0.5);
    float3 c = float3(1.9, 1.7, 0.4);
    float3 d = float3(0.25, 0.6, 0.30);

    return a + b * cos(6.28318 * (c + t * d));
}

fragment half4 wave_fragment(VertexOut verIn [[ stage_in]],
                             constant fragmentConstants &frConst [[ buffer(1) ]],
                             texture2d<float> source [[ texture(0) ]]) {
    
    float4 finalColor = float4(0.0, 0.0, 0.0, 1.0);
    float2 tCoord = verIn.textureCoordinate;
    
    float wave = sin(verIn.textureCoordinate.x * 30 + frConst.time * 2) * 0.5 + 0.5;
    float2 offset = float2(wave * 0.01, wave * 0.01);
    float4 sample = float4(float3(source.sample(sampler2d, verIn.textureCoordinate + offset)), 1.0);
    finalColor = float4(sample.r * 0.1, sample.g, sample.b, sample.a);
    
    return half4(finalColor);
}

fragment half4 cosmic_swirl_fragment(VertexOut verIn [[ stage_in]],
                             constant fragmentConstants &frConst [[ buffer(1) ]],
                             texture2d<float> source [[ texture(0) ]]) {
    
    float4 finalColor = float4(0.0, 0.0, 0.0, 1.0);
    float2 tCoord = verIn.textureCoordinate;
    
    float2 uv = (tCoord - 0.5 * float2(frConst.resX, frConst.resY)) / frConst.resY;
    float2 uv0 = uv;

    for (float i = 0.6; i < 5.0; i++) {
        uv = fract(uv * 1.5) - 0.5;
        float d = length(uv) * exp(-length(uv0));

        float3 col = palette(float(length(uv0) + i * 0.09 + frConst.time * 0.07));

        d = sin(d * 7.0 + frConst.time) / 7.0;
        d = abs(d);
        d = pow(0.02 / d, 1.5);

        finalColor.rgb += col * d;
    }
    
    return half4(finalColor);
}

