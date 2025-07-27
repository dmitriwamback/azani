//
//  Uniforms.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

import simd

struct inVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var uv: SIMD2<Float>
}

struct UniformBuffer {
    var projection: simd_float4x4
    var lookAt: simd_float4x4
    var model: simd_float4x4
    var inverseProjection: simd_float4x4
    var inverseLookAt: simd_float4x4
    var cameraPosition: SIMD3<Float>
    var color: SIMD3<Float>
    var time: Float
}
