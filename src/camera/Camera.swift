//
//  Camera.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

import simd
import CoreFoundation
import Foundation

class Camera {
    
    var projectionMatrix: simd_float4x4!
    var lookAtMatrix: simd_float4x4!
    
    var position: SIMD3<Float>!
    var lookDirection: SIMD3<Float>!
    var velocity: SIMD3<Float>!
    
    var lastMousePositionX: Float!
    var lastMousePositionY: Float!
    
    var pitch: Float!
    var yaw: Float!
    
    var movement: SIMD4<Float>!
    var isRightMouseDown: Bool!
    
    var vertices: [inVertex]!
    
    init() {
        position = SIMD3<Float>(0, 0, 1)
        velocity = SIMD3<Float>(0, 0, 0)
        lookDirection = SIMD3<Float>(0, 0, -1)
        
        movement = SIMD4<Float>(0, 0, 0, 0)
        
        lastMousePositionX = 0
        lastMousePositionY = 0
        
        projectionMatrix = createProjectionMatrix(fov: 3.14159265358979/2.0, aspect: 1200/800, far: 1000.0, near: 0.1)
        lookAtMatrix = createLookAtMatrix(eye: position, target: position + lookDirection, up: SIMD3<Float>(0, 1, 0))
        
        pitch = 0
        yaw = 3.0 * 3.14159265358/2.0
        
        isRightMouseDown = false
        
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
    }
    
    func update() {
        
        let forward = movement.x
        let backward = movement.y
        let left = movement.z
        let right = movement.w
        
        let motion: SIMD3<Float> = lookDirection
        
        let rightDirection = normalize(cross(motion, SIMD3<Float>(0, 1, 0)))
        velocity = (motion * (forward + backward)) + (rightDirection * (right + left))
        
        lookDirection = normalize(SIMD3<Float>(
            cos(yaw) * cos(pitch),
            sin(pitch),
            sin(yaw) * cos(pitch)
        ))
                
        let width: CGFloat = Renderer.width
        let height: CGFloat = Renderer.height
        
        projectionMatrix = createProjectionMatrix(
            fov: .pi / 2.0,
            aspect: Float(width / height),
            far: 1000.0,
            near: 0.01
        )
    }
    
    func updateLookAt() {
        lookAtMatrix = createLookAtMatrix(eye: position, target: position + lookDirection, up: SIMD3<Float>(0, 1, 0))
    }
    
    func updateRotation(mousePosition: NSPoint) {
        
        if (isRightMouseDown) {
            let deltaX = Float(mousePosition.x) - lastMousePositionX
            let deltaY = Float(mousePosition.y) - lastMousePositionY
            
            pitch += deltaY * 0.0055
            yaw += deltaX * 0.0055
            
            if (pitch >  1.55) { pitch =  1.55 }
            if (pitch < -1.55) { pitch = -1.55 }
            
            lookDirection = normalize(SIMD3<Float>(cos(yaw) * cos(pitch),
                                                   sin(pitch),
                                                   sin(yaw) * cos(pitch)))
        }
        
        lastMousePositionX = Float(mousePosition.x)
        lastMousePositionY = Float(mousePosition.y)
    }
}
