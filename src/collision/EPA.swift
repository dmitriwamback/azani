//
//  EPA.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

import simd

struct Collision {
    var A: SIMD3<Float> = .zero
    var B: SIMD3<Float> = .zero
    var normal: SIMD3<Float> = .zero
    var depth: Float = 0
    var collided: Bool = false
}

func getNormal(polytope: [SIMD3<Float>], indices: [Int]) -> ([SIMD4<Float>], Int) {
    var normals: [SIMD4<Float>] = []
    var minIndex = 0
    var minDistance = Float.greatestFiniteMagnitude
    
    for i in 0..<(indices.count / 3) {
        let A = polytope[indices[i*3]]
        let B = polytope[indices[i*3 + 1]]
        let C = polytope[indices[i*3 + 2]]
        
        var normal = simd_normalize(simd_cross(B - A, C - A))
        var distance = simd_dot(normal, A)
        
        if distance < 0 {
            normal = -normal
            distance = -distance
        }
        
        normals.append(SIMD4<Float>(normal.x, normal.y, normal.z, distance))
        
        if distance < minDistance {
            minIndex = i
            minDistance = distance
        }
    }
    return (normals, minIndex)
}

func addUnique(edges: inout [(Int, Int)], faces: [Int], a: Int, b: Int) {
    if let idx = edges.firstIndex(where: { $0.0 == faces[b] && $0.1 == faces[a] }) {
        edges.remove(at: idx)
    } else {
        edges.append((faces[a], faces[b]))
    }
}

func EPA(simplex: Simplex, colliderA: [inVertex], colliderB: [inVertex]) -> Collision {
    var result = Collision()
    if simplex.size() < 4 { return result }
    
    var polytope = Array(simplex.validPoints())
    var indices: [Int] = [
        0,1,2, 0,3,1,
        0,2,3, 1,3,2
    ]
    
    var (normals, minTriangle) = getNormal(polytope: polytope, indices: indices)
    
    var minVec = SIMD3<Float>()
    var minDistance: Float = .greatestFiniteMagnitude
    
    for _ in 0..<100 {
        minVec = SIMD3<Float>(normals[minTriangle].x, normals[minTriangle].y, normals[minTriangle].z)
        minDistance = normals[minTriangle].w
        
        let supportPoint = support(collider: colliderA, direction: minVec) -
                           support(collider: colliderB, direction: -minVec)
        
        if simd_length(supportPoint) < 1e-6 { break }
        let sdist = simd_dot(minVec, supportPoint)
        
        if abs(sdist - minDistance) > 0.001 && sdist < 1e6 {
            var uniqueEdges: [(Int, Int)] = []
            
            var i = 0
            while i < normals.count {
                if simd_dot(SIMD3<Float>(normals[i].x, normals[i].y, normals[i].z), supportPoint) > normals[i].w {
                    let idx = i*3
                    addUnique(edges: &uniqueEdges, faces: indices, a: idx, b: idx+1)
                    addUnique(edges: &uniqueEdges, faces: indices, a: idx+1, b: idx+2)
                    addUnique(edges: &uniqueEdges, faces: indices, a: idx+2, b: idx)
                    
                    indices.removeSubrange(idx..<idx+3)
                    normals.remove(at: i)
                }
                else {
                    i += 1
                }
            }
            
            var newFaces: [Int] = []
            for (a,b) in uniqueEdges {
                newFaces.append(a)
                newFaces.append(b)
                newFaces.append(polytope.count)
            }
            
            polytope.append(supportPoint)
            
            let (newNormals, newMinFace) = getNormal(polytope: polytope, indices: newFaces)
            
            var oldMinDist = Float.greatestFiniteMagnitude
            for (j, n) in normals.enumerated() {
                if n.w < oldMinDist {
                    oldMinDist = n.w
                    minTriangle = j
                }
            }
            
            if newNormals[newMinFace].w < oldMinDist {
                minTriangle = newMinFace + normals.count
            }
            
            indices.append(contentsOf: newFaces)
            normals.append(contentsOf: newNormals)
        }
    }
    
    result.normal = minVec
    result.depth = min(minDistance + 0.001, 100.0)
    result.collided = true
    return result
}
