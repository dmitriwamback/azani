//
//  Shaders.metal
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

#include <metal_stdlib>
using namespace metal;

struct inVertex {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

struct outVertex {
    float4 position [[position]];
    float3 normal;
    float3 color;
    float3 fragp;
    float2 uv;
};

struct Uniforms {
    float4x4 projection;
    float4x4 lookAt;
    float4x4 model;
    float4x4 inverseProjection;
    float4x4 inverseLookAt;
    float3 cameraPosition;
    float3 color;
    float time;
};

struct GBufferOut {
    float4 position [[position]];
    float3 fragp;
    float3 normal;
    float3 color;
    float2 uv;
};

struct GBufferOutFragment {
    float4 fragp [[color(0)]];
    float4 normal [[color(1)]];
    float4 albedo [[color(2)]];
};

vertex outVertex vmain(uint vertexID [[vertex_id]], constant inVertex *vertexArray [[buffer(0)]], constant Uniforms& uniforms [[buffer(1)]]) {
    
    outVertex out;
    
    inVertex vert = vertexArray[vertexID];

    out.position    = float4(vert.position.xy, 0.0, 1.0);
    out.normal      = vert.normal.xyz;
    out.uv          = vert.uv;
    out.color       = uniforms.color;
    out.fragp       = float3(uniforms.model * float4(vert.position, 1.0));
    
    return out;
}

fragment float4 fmain(outVertex in [[stage_in]], texture2d<float> albedo [[texture(0)]], texture2d<float> normal [[texture(1)]], texture2d<float> fragp [[texture(2)]], sampler inSampler [[sampler(0)]]) {
    
    float4 _albedo = albedo.sample(inSampler, float2(in.uv.x, 1 - in.uv.y));
    float4 _normal = normal.sample(inSampler, float2(in.uv.x, 1 - in.uv.y));
    float4 _fragp  = fragp.sample(inSampler, float2(in.uv.x, 1 - in.uv.y));
    
    float3 lightPosition = float3(100.0);
    float3 ambient = _albedo.rgb * 0.4;
    
    float3  lightDirection  = normalize(lightPosition - _fragp.rgb);
    float   diff            = max(dot(_normal.rgb, lightDirection), 0.0);
    float3  diffuse         = diff * float3(1.0);
    
    return float4(_albedo.rgb * (ambient + diffuse), 1.0);
}

vertex GBufferOut vgBuffer(uint vertexID [[vertex_id]], constant inVertex *vertexArray [[buffer(0)]], constant Uniforms& uniforms [[buffer(1)]]) {
    inVertex vert = vertexArray[vertexID];
    GBufferOut out;
    
    float4 fragp    = uniforms.lookAt * uniforms.model * float4(vert.position, 1.0);
    out.position    = uniforms.projection * fragp;
    out.fragp       = fragp.xyz;
    out.normal      = vert.normal;
    out.uv          = vert.uv;
    out.color       = uniforms.color;
    
    return out;
}

fragment GBufferOutFragment fgBuffer(GBufferOut in [[stage_in]]) {
    GBufferOutFragment out;
    out.fragp   = float4(in.fragp, 1.0);
    out.normal  = float4(normalize(in.normal), 1.0);
    out.albedo  = float4(in.color, 1.0);
    return out;
}
