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
    var gPosition:                  MTLTexture!
    var gNormal:                    MTLTexture!
    var gAlbedo:                    MTLTexture!
    var gDepth:                     MTLTexture!
    var gBrightness:                MTLTexture!
    var foregroundTexture:          MTLTexture!
    
    var depthTexture:               MTLTexture!
    
    var gBufferPipelineState:       MTLRenderPipelineState!
    var backgroundPipelineState:    MTLComputePipelineState!
        
    init(vertexDescriptor: MTLVertexDescriptor, library: MTLLibrary?) {
        
        let gBufferVertexFunction       = library?.makeFunction(name: "vgBuffer")
        let gBufferFragmentFunction     = library?.makeFunction(name: "fgBuffer")
        let backgroundKernelFunction    = library?.makeFunction(name: "background")
        
        let gBufferDescriptor = MTLRenderPipelineDescriptor()
        gBufferDescriptor.vertexFunction                    = gBufferVertexFunction
        gBufferDescriptor.fragmentFunction                  = gBufferFragmentFunction
        gBufferDescriptor.colorAttachments[0].pixelFormat   = .rgba16Float
        gBufferDescriptor.colorAttachments[1].pixelFormat   = .rgba16Float
        gBufferDescriptor.colorAttachments[2].pixelFormat   = .rgba16Float
        gBufferDescriptor.colorAttachments[3].pixelFormat   = .r32Float
        gBufferDescriptor.vertexDescriptor                  = vertexDescriptor
        gBufferDescriptor.depthAttachmentPixelFormat        = .depth32Float
        
        do {
            gBufferPipelineState = try Renderer.device.makeRenderPipelineState(descriptor: gBufferDescriptor)
            backgroundPipelineState = try Renderer.device.makeComputePipelineState(function: backgroundKernelFunction!)
        }
        catch let error {
            fatalError(error.localizedDescription)
        }
        
        createGBufferTextures()
        
        let backgroundTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: Int(Renderer.width),
            height: Int(Renderer.height),
            mipmapped: false
        )
        backgroundTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        // -------------------------------------------------------------------------------- //
        
        foregroundTexture = Renderer.device.makeTexture(descriptor: backgroundTextureDescriptor)
    }
    
    func update(cube: Cube, commandBuffer: MTLCommandBuffer, depthStencilState: MTLDepthStencilState) {
        
        createGBufferTextures()
        
        
        
        var uniforms: UniformBuffer = UniformBuffer()
        
        let cameraTransform = createModelMatrix(position: Renderer.camera.position, scale: SIMD3<Float>(0.5, 0.5, 0.5), rotation: SIMD3<Float>(0.0, 0.0, 0.0))
        let cubeTransform = createModelMatrix(position: cube.position, scale: cube.scale, rotation: cube.rotation)
        let collision = GJK(colliderA: createColliderVertices(vertices: Renderer.camera.vertices, model: cameraTransform), colliderB: createColliderVertices(vertices: cube.vertices, model: cubeTransform))
        
        Renderer.camera.update()
        
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
        
        uniforms.model                  = cubeTransform
        uniforms.inverseModel           = cubeTransform.inverse
        uniforms.lookAt                 = Renderer.camera.lookAtMatrix
        uniforms.projection             = Renderer.camera.projectionMatrix
        uniforms.inverseLookAt          = Renderer.camera.lookAtMatrix.inverse
        uniforms.inverseProjection      = Renderer.camera.projectionMatrix.inverse
        uniforms.cameraPosition         = Renderer.camera.position
        
        let uniformBuffer: MTLBuffer = Renderer.device.makeBuffer(bytes: &uniforms, length: MemoryLayout<UniformBuffer>.stride, options: [])!
        
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<UniformBuffer>.stride)
        
        let descriptor = createGBufferRenderPassDescriptor()
        
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge

        let samplerState = Renderer.device.makeSamplerState(descriptor: samplerDescriptor)
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        encoder.setRenderPipelineState(gBufferPipelineState)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setVertexBuffer(cube.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 36)

        encoder.endEncoding()
        
        if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
                    
            computeEncoder.setSamplerState(samplerState, index: 0)
            
            let threads = 16
            
            let threadsPerThreadgroup = MTLSizeMake(threads, threads, 1)
            let threadgroups = MTLSizeMake(
                (Int(foregroundTexture.width) + threads-1) / threads,
                (Int(foregroundTexture.height) + threads-1) / threads,
                1)
            
            computeEncoder.setComputePipelineState(backgroundPipelineState)
            
            computeEncoder.setTexture(foregroundTexture, index: 0)
            computeEncoder.setTexture(gAlbedo,      index: 1)
            computeEncoder.setTexture(gNormal,      index: 2)
            computeEncoder.setTexture(gPosition,    index: 3)
            computeEncoder.setTexture(gDepth,       index: 4)
            computeEncoder.setBuffer(uniformBuffer, offset: 0, index: 0)
            
            computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
            computeEncoder.endEncoding()
        }
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
        
        descriptor.colorAttachments[3].texture = gDepth
        descriptor.colorAttachments[3].loadAction = .clear
        descriptor.colorAttachments[3].storeAction = .store
        descriptor.colorAttachments[3].clearColor = MTLClearColorMake(0, 0, 0, 1)

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

        gPosition   = Renderer.device.makeTexture(descriptor: descriptor)
        gNormal     = Renderer.device.makeTexture(descriptor: descriptor)
        gAlbedo     = Renderer.device.makeTexture(descriptor: descriptor)

        let depthDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: Int(Renderer.width),
            height: Int(Renderer.height),
            mipmapped: false
        )
        depthDesc.usage = [.renderTarget, .shaderRead]
        depthTexture = Renderer.device.makeTexture(descriptor: depthDesc)
        
        let gDepthDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r32Float,
            width: Int(Renderer.width),
            height: Int(Renderer.height),
            mipmapped: false
        )
        gDepthDesc.usage = [.renderTarget, .shaderRead]
        gDepth = Renderer.device.makeTexture(descriptor: gDepthDesc)
    }
}
