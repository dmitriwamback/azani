//
//  Model.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-08-01.
//

import Foundation
import Metal
import MetalKit

class Model {
    
    var meshes: [Mesh] = [Mesh]()
    var position = simd_float3(repeating: 0.0)
    var rotation = simd_float3(repeating: 0.0)
    var scale = simd_float3(repeating: 1.0)
    
    init(url: URL, vertexDescriptor: MTLVertexDescriptor) {
        
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        
        let modelVD = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
        
        let attribPosition  = modelVD.attributes[0] as! MDLVertexAttribute
        let attribNormal    = modelVD.attributes[1] as! MDLVertexAttribute
        let attribUV        = modelVD.attributes[2] as! MDLVertexAttribute
        
        attribPosition.name = MDLVertexAttributePosition
        attribNormal.name   = MDLVertexAttributeNormal
        attribUV.name       = MDLVertexAttributeTextureCoordinate
        
        modelVD.attributes[0] = attribPosition
        modelVD.attributes[1] = attribNormal
        modelVD.attributes[2] = attribUV
        
        let bufferAllocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(url: url, vertexDescriptor: modelVD, bufferAllocator: bufferAllocator)
        asset.loadTextures()
        
        guard let (mdlMeshes, mtkMeshes) = try? MTKMesh.newMeshes(asset: asset, device: Renderer.device) else {
            print("failed to load meshes")
            return
        }
        
        self.meshes.reserveCapacity(mdlMeshes.count)
        
        for (mdlMesh, mtkMesh) in zip(mdlMeshes, mtkMeshes) {
            var materials = [Material]()
            
            for mdlSubmesh in mdlMesh.submeshes as! [MDLSubmesh] {
                let material = Material(mdlMaterial: mdlSubmesh.material, textureLoader: textureLoader)
                materials.append(material)
            }
            let mesh = Mesh(mesh: mtkMesh, materials: materials)
            self.meshes.append(mesh)
        }
    }
}

class Mesh {
    var mesh: MTKMesh
    var materials: [Material]
    
    init(mesh: MTKMesh, materials: [Material]) {
        self.mesh = mesh
        self.materials = materials
    }
}

class Material {
    var albedoTexture: MTLTexture?
    
    init(mdlMaterial: MDLMaterial?, textureLoader: MTKTextureLoader) {
        
        guard let materialProperty = mdlMaterial?.property(with: .baseColor) else { return }
        guard let source = materialProperty.textureSamplerValue?.texture else { return }
        
        albedoTexture = try? textureLoader.newTexture(texture: source, options: nil)
    }
}
