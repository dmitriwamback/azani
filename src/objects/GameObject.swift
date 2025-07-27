//
//  GameObject.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

import Foundation
import Metal
import MetalKit

class GameObject {
    var vertices: [inVertex]!
    var vertexBuffer: MTLBuffer!
}

func createModelMatrix(position: SIMD3<Float>, scale: SIMD3<Float>, rotation: SIMD3<Float>) -> simd_float4x4 {
        
    let translationMatrix: simd_float4x4 = simd_float4x4(
        SIMD4<Float>(1, 0, 0, 0),
        SIMD4<Float>(0, 1, 0, 0),
        SIMD4<Float>(0, 0, 1, 0),
        SIMD4<Float>(position.x, position.y, position.z, 1)
    )
    
    let scaleMatrix: simd_float4x4 = simd_float4x4(
        SIMD4<Float>(scale.x, 0, 0, 0),
        SIMD4<Float>(0, scale.y, 0, 0),
        SIMD4<Float>(0, 0, scale.z, 0),
        SIMD4<Float>(0, 0, 0, 1)
    )
    
    let xRotation: simd_float4x4 = simd_float4x4(
        SIMD4<Float>(1, 0, 0, 0),
        SIMD4<Float>(0, cos(rotation.x), sin(rotation.x), 0),
        SIMD4<Float>(0, -sin(rotation.x), cos(rotation.x), 0),
        SIMD4<Float>(0, 0, 0, 1)
    )
    let yRotation: simd_float4x4 = simd_float4x4(
        SIMD4<Float>(cos(rotation.y), 0, -sin(rotation.y), 0),
        SIMD4<Float>(0, 1, 0, 0),
        SIMD4<Float>(sin(rotation.y), 0, cos(rotation.y), 0),
        SIMD4<Float>(0, 0, 0, 1)
    )
    let zRotation: simd_float4x4 = simd_float4x4(
        SIMD4<Float>(cos(rotation.z), sin(rotation.z), 0, 0),
        SIMD4<Float>(-sin(rotation.z), cos(rotation.z), 0, 0),
        SIMD4<Float>(0, 0, 1, 0),
        SIMD4<Float>(0, 0, 0, 1)
    )
    
    let rotationMatrix: simd_float4x4 = xRotation * yRotation * zRotation
    
    return translationMatrix * rotationMatrix * scaleMatrix
}

func createColliderVertices(vertices: [inVertex], model: simd_float4x4) -> [inVertex] {
    
    var transformedVertices: [inVertex] = []
    
    for vertex in vertices {
        let v0 = vertex.position
        let t0 = model * SIMD4<Float>(v0, 1.0)
        
        var inV = inVertex(position: SIMD3<Float>(t0.x, t0.y, t0.z), normal: SIMD3<Float>(0.0, 0.0, 0.0), uv: SIMD2<Float>(0.0, 0.0))
        
        transformedVertices.append(inV)
    }
    
    return transformedVertices
}
