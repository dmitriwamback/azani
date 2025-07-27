//
//  Matrix.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

import simd

func createProjectionMatrix(fov: Float, aspect: Float, far: Float, near: Float) -> simd_float4x4 {
    
    let y = 1 / tan(fov * 0.5)
    let x = y / aspect
    let zRange = far - near
    let z = -(far + near) / zRange
    let w = -2 * far * near / zRange
    
    return simd_float4x4(SIMD4<Float>(x, 0, 0, 0),
                         SIMD4<Float>(0, y, 0, 0),
                         SIMD4<Float>(0, 0, z, -1),
                         SIMD4<Float>(0, 0, w, 0))
}

func createLookAtMatrix(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
    let forward = normalize(target - eye)
    let right = normalize(cross(forward, up))
    let camUp = cross(right, forward)
    
    let translation = SIMD3<Float>(
        -dot(right, eye),
        -dot(camUp, eye),
        -dot(-forward, eye)
    )
    
    return simd_float4x4(columns: (
        SIMD4<Float>(right.x, camUp.x, -forward.x, 0),
        SIMD4<Float>(right.y, camUp.y, -forward.y, 0),
        SIMD4<Float>(right.z, camUp.z, -forward.z, 0),
        SIMD4<Float>(translation.x, translation.y, translation.z, 1)
    ))
}

func createModelMatrix() {
    
}
