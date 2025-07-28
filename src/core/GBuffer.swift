//
//  GBuffer.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-28.
//

import Foundation
import MetalKit
import Metal

class GBufferQuad {
    var vertices: [inVertex]!
    var vertexBuffer: MTLBuffer!
    var cloudNoiseTexture: MTLTexture!
    
    init() {
        vertices = [
            inVertex(position: SIMD3(-1.0,  1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3( 1.0,  1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-1.0, -1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3( 1.0,  1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 1.0, -1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3(-1.0, -1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 0)),
        ]
        
        vertexBuffer = Renderer.device.makeBuffer(bytes: vertices, length: MemoryLayout<inVertex>.stride * vertices.count, options: [])
    }
}

class GBuffer {
    var gPosition:              MTLTexture!
    var gNormal:                MTLTexture!
    var gAlbedo:                MTLTexture!
    var depthTexture:           MTLTexture!
    var brightness:             MTLTexture!
    var gBufferPipelineState:   MTLRenderPipelineState!
        
    init(vertexDescriptor: MTLVertexDescriptor, library: MTLLibrary?) {
        
        let gBufferVertexFunction   = library?.makeFunction(name: "vgBuffer")
        let gBufferFragmentFunction = library?.makeFunction(name: "fgBuffer")
        
        let gBufferDescriptor = MTLRenderPipelineDescriptor()
        gBufferDescriptor.vertexFunction                    = gBufferVertexFunction
        gBufferDescriptor.fragmentFunction                  = gBufferFragmentFunction
        gBufferDescriptor.colorAttachments[0].pixelFormat   = .rgba16Float
        gBufferDescriptor.colorAttachments[1].pixelFormat   = .rgba16Float
        gBufferDescriptor.colorAttachments[2].pixelFormat   = .rgba16Float
        gBufferDescriptor.vertexDescriptor                  = vertexDescriptor
        gBufferDescriptor.depthAttachmentPixelFormat        = .depth32Float
        
        do {
            gBufferPipelineState = try Renderer.device.makeRenderPipelineState(descriptor: gBufferDescriptor)
        }
        catch let error {
            fatalError(error.localizedDescription)
        }
        
        createGBufferTextures()
    }
    
    func update(cube: Cube, commandBuffer: MTLCommandBuffer, depthStencilState: MTLDepthStencilState) {
        
        createGBufferTextures()
        
        let descriptor = createGBufferRenderPassDescriptor()
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        var uniforms: UniformBuffer = UniformBuffer()
        
        let cameraTransform = createModelMatrix(position: Renderer.camera.position, scale: SIMD3<Float>(0.5, 0.5, 0.5), rotation: SIMD3<Float>(0.0, 0.0, 0.0))
        let cubeTransform = createModelMatrix(position: cube.position, scale: cube.scale, rotation: cube.rotation)
        let collision = GJK(colliderA: createColliderVertices(vertices: Renderer.camera.vertices, model: cameraTransform), colliderB: createColliderVertices(vertices: cube.vertices, model: cubeTransform))
        
        Renderer.camera.update()
        Renderer.camera.position += Renderer.camera.velocity
        
        if collision.collided {
            uniforms.color = SIMD3<Float>(0.8, 0.0, 0.0)
            var correctedNormal = collision.normal
            if simd_dot(correctedNormal, cube.position - Renderer.camera.position) > 0 {
                correctedNormal = -correctedNormal
            }
            Renderer.camera.position += correctedNormal * collision.depth
        }
        else {
            uniforms.color = cube.color
        }
        Renderer.camera.updateLookAt()
        
        uniforms.model = cubeTransform
        uniforms.lookAt = Renderer.camera.lookAtMatrix
        uniforms.projection = Renderer.camera.projectionMatrix
        
        let uniformBuffer: MTLBuffer = Renderer.device.makeBuffer(bytes: &uniforms, length: MemoryLayout<UniformBuffer>.stride, options: [])!

        encoder.setRenderPipelineState(gBufferPipelineState)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setVertexBuffer(cube.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)

        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<UniformBuffer>.stride)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 36)

        encoder.endEncoding()
    }
    
    func createGBufferRenderPassDescriptor() -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()
                    
        descriptor.colorAttachments[0].texture = gPosition
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)

        descriptor.colorAttachments[1].texture = gNormal
        descriptor.colorAttachments[1].loadAction = .clear
        descriptor.colorAttachments[1].storeAction = .store
        descriptor.colorAttachments[1].clearColor = MTLClearColorMake(0, 0, 0, 1)

        descriptor.colorAttachments[2].texture = gAlbedo
        descriptor.colorAttachments[2].loadAction = .clear
        descriptor.colorAttachments[2].storeAction = .store
        descriptor.colorAttachments[2].clearColor = MTLClearColorMake(0, 0, 0, 1)

        descriptor.depthAttachment.texture = depthTexture
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .dontCare
        descriptor.depthAttachment.clearDepth = 1.0

        return descriptor
    }
    
    func createGBufferTextures() {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: Int(Renderer.width),
            height: Int(Renderer.height),
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]

        gPosition = Renderer.device.makeTexture(descriptor: descriptor)
        gNormal = Renderer.device.makeTexture(descriptor: descriptor)
        gAlbedo = Renderer.device.makeTexture(descriptor: descriptor)

        let depthDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: Int(Renderer.width),
            height: Int(Renderer.height),
            mipmapped: false
        )
        depthDesc.usage = [.renderTarget]
        depthTexture = Renderer.device.makeTexture(descriptor: depthDesc)
    }
}
