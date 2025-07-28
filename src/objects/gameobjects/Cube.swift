//
//  Cube.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

import simd
import Metal
import MetalKit

class Cube {
    
    var vertices: [inVertex]!
    var vertexBuffer: MTLBuffer!
    
    var position:   SIMD3<Float>!
    var scale:      SIMD3<Float>!
    var rotation:   SIMD3<Float>!
    var color:      SIMD3<Float>!
    
    init() {
        vertices = [
            inVertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 0)),
            
            // Back face
            inVertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(0, 0)),
            
            // Right face
            inVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(0, 0)),
            
            // Left face
            inVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(0, 0)),
            
            // Top face
            inVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(0, 0)),
            
            // Bottom face
            inVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(0, 0)),
        ]
        
        position = SIMD3<Float>(0.0, 0.0, -5.0)
        rotation = SIMD3<Float>(25.0, 45.0, 0.0)
        scale = SIMD3<Float>(5.5, 5.0, 5.0)
        color = SIMD3<Float>(0.8, 0.8, 0.8)
        
        vertexBuffer = Renderer.device.makeBuffer(bytes: vertices, length: MemoryLayout<inVertex>.stride * vertices.count, options: [])
    }
}
