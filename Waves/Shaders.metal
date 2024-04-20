//
//  WaveShader.metal
//  Waves
//
//  Created by Kuutti Taavitsainen on 19.4.2024.
//

#include <metal_stdlib>
using namespace metal;

class Functions {
public:
    template <typename T>
    static T baryinterp(T c0, T c1, T c2, float3 bary) {
        return c0 * bary[0] + c1 * bary[1] + c2 * bary[2];
    }

    template <typename T>
    static T bilerp(T c00, T c01, T c10, T c11, float2 uv) {
        T c0 = mix(c00, c01, T(uv[0]));
        T c1 = mix(c10, c11, T(uv[0]));
        return mix(c0, c1, T(uv[1]));
    }

    static float interpolate(float a0, float a1, float w) {
        return (a1 - a0) * (3.0 - w * 2.0) * w * w + a0;
    }
};

class Noises {
public:
    static vector_float2 randomGradient(int ix, int iy) {
        const unsigned w = 8 * sizeof(unsigned);
        const unsigned s = w / 2;
        unsigned a = ix, b = iy;
        a *= 3284157443; b ^= a << s | a >> (w-s);
        b *= 1911520717; a ^= b << s | b >> (w-s);
        a *= 2048419325;
        float random = a * (3.14159265 / ~(~0u >> 1));
        vector_float2 v;
        v.x = cos(random); v.y = sin(random);
        return v;
    }

    static float dotGridGradient(int ix, int iy, float x, float y) {
        vector_float2 gradient = randomGradient(ix, iy);
        
        float dx = x - float(ix);
        float dy = y - float(iy);

        return (dx*gradient.x + dy*gradient.y);
    }

    static float perlin(float x, float y) {
        int x0 = (int)floor(x);
        int x1 = x0 + 1;
        int y0 = (int)floor(y);
        int y1 = y0 + 1;
        
        float sx = x - (float)x0;
        float sy = y - (float)y0;
        
        float n0, n1, ix0, ix1, value;
        
        n0 = dotGridGradient(x0, y0, x, y);
        n1 = dotGridGradient(x1, y0, x, y);
        ix0 = Functions::interpolate(n0, n1, sx);
        
        n0 = dotGridGradient(x0, y1, x, y);
        n1 = dotGridGradient(x1, y1, x, y);
        ix1 = Functions::interpolate(n0, n1, sx);
        
        value = Functions::interpolate(ix0, ix1, sy) * 0.5 + 0.5;
        return value;
    }
};


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
    float resX;
    float resY;
};

fragment half4 wave_fragment(VertexOut verIn [[ stage_in]],
                             constant fragmentConstants &frConst [[ buffer(0) ]],
                             texture2d<float> source [[ texture(0) ]]) {
    
    float4 finalColor = float4(0.0, 0.0, 0.0, 1.0);
    float2 tCoord = verIn.textureCoordinate;
    
    float wave = sin(verIn.textureCoordinate.x * 30 + frConst.time * 2) * 0.5 + 0.5;
    float2 offset = float2(wave * 0.01, wave * 0.01);
    float4 sample = float4(float3(source.sample(sampler2d, tCoord + offset)), 1.0);
    finalColor = float4(sample.r * 0.1, sample.g, sample.b, sample.a);
    
    float noise = 0.8f + Noises::perlin(tCoord.x * 3 + cos(frConst.time / 3) * 2, tCoord.y * 3 + sin(frConst.time / 3) * 2) * 0.5;

    return half4(finalColor * noise);
}

fragment half4 rage_fragment(VertexOut verIn [[ stage_in]],
                             constant fragmentConstants &frConst [[ buffer(0) ]],
                             texture2d<float> source [[ texture(0) ]]) {
    
    float4 finalColor = float4(0.0, 0.0, 0.0, 1.0);
    float2 tCoord = verIn.textureCoordinate;
    
    float2 offset = float2(sin(frConst.time * 100) * 0.005, cos(frConst.time * 100) * 0.005);
    float4 sample = source.sample(sampler2d, tCoord + offset);
    finalColor = float4(sample.r, sample.g, sample.b, 1.0);
    
    return half4(finalColor);
}

fragment half4 cosmic_swirl_fragment(VertexOut verIn [[ stage_in]],
                             constant fragmentConstants &frConst [[ buffer(0) ]],
                             texture2d<float> source [[ texture(0) ]]) {
    
    float4 finalColor = float4(0.0, 0.0, 0.0, 1.0);
    float2 tCoord = verIn.textureCoordinate;
    
    float xOffset = Noises::perlin(tCoord.x, (tCoord.y * frConst.resY / 10) + frConst.time * -5.0) * 0.01;
    
    float sampleR = source.sample(sampler2d, tCoord + float2(-0.003, 0.0) + float2(xOffset, 0.0)).r;
    float sampleG = source.sample(sampler2d, tCoord + float2( 0.00, 0.0) + float2(xOffset, 0.0)).g;
    float sampleB = source.sample(sampler2d, tCoord + float2( 0.003, 0.0) + float2(xOffset, 0.0)).b;
    
    finalColor.r = sampleR;
    finalColor.g = sampleG;
    finalColor.b = sampleB;
    
    float wave = 1 - sin(tCoord.y * 200 + frConst.time * 10) * 0.5 + 0.5;

    return half4(finalColor) * wave;
}

