//
//  Renderer.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

import Foundation
import MetalKit
import simd

class Renderer: NSObject {
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    
    static var camera: Camera!
    static var movement: SIMD4<Float>!
    
    static var width: CGFloat!
    static var height: CGFloat!
    var uniforms: UniformBuffer!
    var uniformBuffer: MTLBuffer!
    var debugTime: Float!
    
    var pipelineState: MTLRenderPipelineState!
    var depthStencilState: MTLDepthStencilState!
    var cube: Cube!
    var gBufferQuad: GBufferQuad!
    var gBufferPipeline: GBuffer!
    
    init (metal: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Couldn't create MTLDevice")
        }
        metal.device = device
        Renderer.device = device
        Renderer.commandQueue = device.makeCommandQueue()
        Renderer.width = metal.frame.width
        Renderer.height = metal.frame.height
        cube = Cube()
                
        super.init()
        
        metal.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        metal.delegate = self
        metal.depthStencilPixelFormat = .depth32Float
        
        let vertexDescriptor = MTLVertexDescriptor()

        vertexDescriptor.attributes[0].format = .float4 // position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float3 // normal
        vertexDescriptor.attributes[1].offset = MemoryLayout<float4>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.attributes[2].format = .float2 // uv
        vertexDescriptor.attributes[2].offset = MemoryLayout<float4>.stride + MemoryLayout<float3>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<inVertex>.stride
        
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vmain")
        let fragmentFunction = library?.makeFunction(name: "fmain")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metal.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        Renderer.camera = Camera()
        
        uniforms = UniformBuffer(projection: Renderer.camera.projectionMatrix,
                                 lookAt: Renderer.camera.lookAtMatrix,
                                 model: simd_float4x4(),
                                 inverseProjection: Renderer.camera.projectionMatrix.inverse,
                                 inverseLookAt: Renderer.camera.lookAtMatrix.inverse,
                                 cameraPosition: Renderer.camera.position,
                                 color: SIMD3<Float>(1.0, 1.0, 1.0),
                                 time: 0)
        uniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<UniformBuffer>.stride, options: [])
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<UniformBuffer>.stride)
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        catch let error {
            fatalError("\(error.localizedDescription)")
        }
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        depthStencilState = Renderer.device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        gBufferPipeline = GBuffer(vertexDescriptor: vertexDescriptor, library: library)
        
        gBufferQuad = GBufferQuad()
    }
}


extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge

        let samplerState = Renderer.device.makeSamplerState(descriptor: samplerDescriptor)
        
        Renderer.width = view.drawableSize.width
        Renderer.height = view.drawableSize.height
        
        guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer() else { return }
        
        gBufferPipeline.update(cube: cube, commandBuffer: commandBuffer, depthStencilState: depthStencilState)
        
        guard let descriptor = view.currentRenderPassDescriptor else { return }
                
        descriptor.depthAttachment.texture = view.depthStencilTexture
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .store
        descriptor.depthAttachment.clearDepth = 1.0
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(gBufferQuad.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(gBufferPipeline.gAlbedo, index: 0)
        renderEncoder.setFragmentTexture(gBufferPipeline.gNormal, index: 1)
        renderEncoder.setFragmentTexture(gBufferPipeline.gPosition, index: 2)
        
        //uniforms.model              = createModelMatrix(position: cube.position, scale: cube.scale, rotation: cube.rotation)
        uniforms.lookAt             = Renderer.camera.lookAtMatrix
        uniforms.projection         = Renderer.camera.projectionMatrix
        uniforms.inverseLookAt      = Renderer.camera.lookAtMatrix.inverse
        uniforms.inverseProjection  = Renderer.camera.projectionMatrix.inverse
        uniforms.cameraPosition     = Renderer.camera.position
        
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<UniformBuffer>.stride)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        renderEncoder.endEncoding()
        
        guard let drawable = view.currentDrawable else { return }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        Renderer.camera.velocity = .zero
    }
}
