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
    
    init(projection: simd_float4x4, lookAt: simd_float4x4, model: simd_float4x4, inverseProjection: simd_float4x4, inverseLookAt: simd_float4x4, cameraPosition: SIMD3<Float>, color: SIMD3<Float>, time: Float) {
        self.projection             = projection
        self.lookAt                 = lookAt
        self.model                  = model
        self.inverseProjection      = inverseProjection
        self.inverseLookAt          = inverseLookAt
        self.cameraPosition         = cameraPosition
        self.color                  = color
        self.time                   = time
    }
    
    init() {
        self.projection             = simd_float4x4()
        self.lookAt                 = simd_float4x4()
        self.model                  = simd_float4x4()
        self.inverseProjection      = simd_float4x4()
        self.inverseLookAt          = simd_float4x4()
        self.cameraPosition         = SIMD3<Float>(0, 0, 0)
        self.color                  = SIMD3<Float>(0, 0, 0)
        self.time                   = 0
    }
}
