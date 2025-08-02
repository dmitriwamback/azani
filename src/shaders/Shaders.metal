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
    float4x4 inverseModel;
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
    float  depth [[color(3)]];
    float4 brightness [[color(4)]];
};

constant float3 zenithColor  = float3(0.05, 0.15, 0.4);
constant float3 horizonColor = float3(0.6, 0.7, 0.9);
constant float3 groundColor  = float3(0.4, 0.35, 0.3);

float3 getSkyColor(float y) {
    
    float3 skyColor;
    
    if (y > 0.0) {
        float t = pow(y, 0.65);
        skyColor = mix(horizonColor, zenithColor, t);
    }
    else {
        float t = pow(-y, 0.7);
        skyColor = mix(horizonColor, groundColor, t);
    }
    
    return skyColor;
}



vertex outVertex vmain(uint vertexID [[vertex_id]], constant inVertex *vertexArray [[buffer(0)]], constant Uniforms& uniforms [[buffer(1)]]) {
    
    outVertex out;
    
    inVertex vert = vertexArray[vertexID];

    out.position    = float4(vert.position.xy, 0.0, 1.0);
    out.normal      = normalize(float3(transpose(uniforms.inverseModel) * float4(vert.normal.xyz, 1.0)));
    out.uv          = vert.uv;
    out.color       = uniforms.color;
    out.fragp       = float3(uniforms.model * float4(vert.position, 1.0));
    
    return out;
}

fragment float4 fmain(outVertex in [[stage_in]],
                      constant Uniforms& uniforms   [[buffer(1)]],
                      texture2d<float> albedo       [[texture(0)]],
                      texture2d<float> normal       [[texture(1)]],
                      texture2d<float> fragp        [[texture(2)]],
                      texture2d<float> depth        [[texture(3)]],
                      texture2d<float> brightness   [[texture(4)]],
                      texture2d<float> background   [[texture(5)]],
                      sampler inSampler             [[sampler(0)]]) {
    
    float2 gUV = float2(in.uv.x, 1 - in.uv.y);
    float _depth = depth.sample(inSampler, gUV).r;
    float4 _albedo = float4(0.0);
    
    if (_depth <= 0.0) {
        _albedo = background.sample(inSampler, gUV);
        return float4(_albedo.rgb, 1.0);
    }
    
    _albedo = albedo.sample(inSampler, gUV);
    float4 _normal = normal.sample(inSampler, gUV);
    float4 _fragp  = fragp.sample(inSampler, gUV);

    float3 lightPosition = float3(100.0);
    float3 ambient = _albedo.rgb * 0.4;
    
    float3  lightDirection  = normalize(lightPosition - _fragp.rgb);
    float   diff            = max(dot(_normal.rgb, lightDirection), 0.0);
    float3  diffuse         = diff * float3(1.0);
    
    _albedo.rgb *= ambient + diffuse;
    
    
    float3 viewDirection = normalize(uniforms.cameraPosition - _fragp.xyz);
    float3 normalDirection = normalize(_normal.xyz);
    float3 reflectDirection = normalize(reflect(-viewDirection, normalDirection));
    
    float3 skyColor = getSkyColor(reflectDirection.y);
    
    float reflectivity = 0.0;
    _albedo.rgb = mix(_albedo.rgb, skyColor, reflectivity);
    
    return float4(_albedo.rgb, 1.0);
}

vertex GBufferOut vgBuffer(uint vertexID [[vertex_id]], constant inVertex *vertexArray [[buffer(0)]], constant Uniforms& uniforms [[buffer(1)]]) {
    inVertex vert = vertexArray[vertexID];
    GBufferOut out;
    
    float4 fragp    = uniforms.model * float4(vert.position, 1.0);
    out.position    = uniforms.projection * uniforms.lookAt * uniforms.model * float4(vert.position, 1.0);
    out.fragp       = fragp.xyz;
    out.normal      = normalize(float3(transpose(uniforms.inverseModel) * float4(vert.normal, 1.0)));
    out.uv          = vert.uv;
    out.color       = uniforms.color;
    
    return out;
}

fragment GBufferOutFragment fgBuffer(GBufferOut in [[stage_in]], constant Uniforms& uniforms [[buffer(1)]], texture2d<float> albedo [[texture(0)]], sampler inSampler [[sampler(0)]]) {
    
    float near = 0.01;
    float far = 1000.0;
    
    float linearDepth = length(uniforms.cameraPosition - in.fragp);
    float depth01 = (linearDepth - near) / (far - near);
    
    float2 gUV = float2(in.uv.x, 1 - in.uv.y);
    
    GBufferOutFragment out;
    out.fragp   = float4(in.fragp, 1.0);
    out.normal  = float4(normalize(in.normal), 1.0);
    out.albedo  = albedo.sample(inSampler, gUV);
    out.depth   = clamp(depth01 - 1e-5, 0.0, 1.0);
    return out;
}



float3 computeRayDirection(float2 fragp, float4x4 inverseProjection, float4x4 inverseLookAt) {
    
    float2 uv = fragp * 2.0 - 1.0;
    float4 clip = float4(uv, -1.0, 1.0);
    float4 view = inverseProjection * clip;
    view.z = -1.0;
    view.w = 0;
    float4 world = inverseLookAt * view;
    return normalize(world.xyz);
}

kernel void background(constant Uniforms& uniforms [[buffer(0)]],
                       texture2d<float, access::write> output [[texture(0)]],
                       texture2d<float> albedo [[texture(1)]],
                       texture2d<float> normal [[texture(2)]],
                       texture2d<float> fragp [[texture(3)]],
                       texture2d<float> depth [[texture(4)]],
                       sampler inSampler [[sampler(0)]],
                       uint2 gid [[thread_position_in_grid]]) {
    
    uint2 size = uint2(output.get_width(), output.get_height());
            
    if (gid.x >= size.x || gid.y >= size.y) {
        return;
    }
    
    float2 uv = float2(gid) / float2(size);
    
    float3 ray = computeRayDirection(float2(uv.x, 1 - uv.y), uniforms.inverseProjection, uniforms.inverseLookAt);
    float y = ray.y;
    
    float4 _albedo = float4(getSkyColor(y), 1.0);
    
    output.write(_albedo, gid);
}
