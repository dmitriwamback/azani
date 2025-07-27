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

vertex outVertex vmain(uint vertexID [[vertex_id]], constant inVertex *vertexArray [[buffer(0)]], constant Uniforms& uniforms [[buffer(1)]]) {
    
    outVertex out;
    
    inVertex vert = vertexArray[vertexID];

    out.position    = uniforms.projection * uniforms.lookAt * uniforms.model * float4(vert.position, 1.0);
    out.normal      = vert.normal.xyz;
    out.uv          = vert.uv;
    out.color       = uniforms.color;
    out.fragp       = float3(uniforms.model * float4(vert.position, 1.0));
    
    return out;
}

fragment float4 fmain(outVertex in [[stage_in]]) {
    
    float3 lightPosition = float3(100.0);
    float3 ambient = in.color * 0.4;
    
    float3  lightDirection  = normalize(lightPosition - in.fragp);
    float   diff            = max(dot(in.normal, lightDirection), 0.0);
    float3  diffuse         = diff * float3(1.0);
    
    return float4(in.color * (ambient + diffuse), 1.0);
}
