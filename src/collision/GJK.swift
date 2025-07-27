//
//  GJK.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

import Foundation
import simd


func getFurthestPoint(vertices: [SIMD3<Float>], direction: SIMD3<Float>) -> SIMD3<Float> {
    
    var max = vertices[0]
    var dstMax = simd_dot(max, direction)
    
    for vertex in vertices {
        let dst = simd_dot(vertex, direction)
        if dst > dstMax {
            dstMax = dst
            max = vertex
        }
    }
    
    return max
}

func support(collider: [inVertex], direction: SIMD3<Float>) -> SIMD3<Float> {
    
    var transformedVertices: [SIMD3<Float>] = []
    for vertex in collider {
        transformedVertices.append(SIMD3<Float>(vertex.position))
    }
    return getFurthestPoint(vertices: transformedVertices, direction: direction)
}

func sameDirection(direction: SIMD3<Float>, AO: SIMD3<Float>) -> Bool {
    return simd_dot(direction, AO) > 0
}

func simplexLine(simplex: inout Simplex, direction: inout SIMD3<Float>) -> Bool {
    
    let A = simplex[0]
    let B = simplex[1]
    
    let AB = B - A
    let AO = -A
    
    if sameDirection(direction: AB, AO: AO) {
        direction = simd_cross(simd_cross(AB, AO), AB)
    }
    else {
        simplex.set([A])
        direction = AO
    }
    
    return false
}

func simplexTriangle(simplex: inout Simplex, direction: inout SIMD3<Float>) -> Bool {
    
    let A = simplex[0];
    let B = simplex[1];
    let C = simplex[2];
    
    let AB = B - A;
    let AC = C - A;
    let AO = -A;
    
    let ABC = simd_cross(AB, AC);
    
    if sameDirection(direction: simd_cross(ABC, AC), AO: AO) {
        if ( sameDirection(direction: AC, AO: AO)) {
            simplex.set([A, C])
            direction = simd_cross(simd_cross(AC, AO), AC);
        }
        else {
            simplex.set([A, B])
            return simplexLine(simplex: &simplex, direction: &direction);
        }
    }
    else {
        if (sameDirection(direction: simd_cross(AB, ABC), AO: AO)) {
            simplex.set([A, B])
            return simplexLine(simplex: &simplex, direction: &direction);
        }
        else {
            if (sameDirection(direction: ABC, AO: AO)) {
                direction = ABC;
            }
            else {
                simplex.set([A, C, B]);
                direction = -ABC;
            }
        }
    }

    return false;
}

func simplexTetrahedron(simplex: inout Simplex, direction: inout SIMD3<Float>) -> Bool {
    
    let A = simplex[0];
    let B = simplex[1];
    let C = simplex[2];
    let D = simplex[3];
    
    let AB = B - A;
    let AC = C - A;
    let AD = D - A;
    let AO = -A;
    
    let ABC = simd_cross(AB, AC);
    let ACD = simd_cross(AC, AD);
    let ADB = simd_cross(AD, AB);
    
    if (sameDirection(direction: ABC, AO: AO)) {
        simplex.set([A, B, C])
        return simplexTriangle(simplex: &simplex, direction: &direction);
    }
    if (sameDirection(direction: ACD, AO: AO)) {
        simplex.set([A, C, D])
        return simplexTriangle(simplex: &simplex, direction: &direction);
    }
    if (sameDirection(direction: ADB, AO: AO)) {
        simplex.set([A, D, B])
        return simplexTriangle(simplex: &simplex, direction: &direction);
    }
    
    
    return true;
}

func HandleSimplex(simplex: inout Simplex, direction: inout SIMD3<Float>) -> Bool {
    
    switch (simplex.size()) {
    case 2: return simplexLine(simplex: &simplex, direction: &direction);
        case 3: return simplexTriangle(simplex: &simplex, direction: &direction);
        case 4: return simplexTetrahedron(simplex: &simplex, direction: &direction);
        default: return false;
    }
}

func GJK(colliderA: [inVertex], colliderB: [inVertex]) -> Bool {
    
    let _support = support(collider: colliderA, direction: SIMD3<Float>(1.0, 0.0, 0.0)) - support(collider: colliderB, direction: SIMD3<Float>(1.0, 0.0, 0.0))
    
    var simplex: Simplex = Simplex()
    simplex.pushFront(_support)
    
    var direction = -_support
    
    for i in 0..<100 {
        let va = support(collider: colliderA, direction: direction)
        let vb = support(collider: colliderB, direction: -direction)
        let newSupport = va - vb
        
        if simd_dot(newSupport, direction) <= 0.0 {
            return false
        }
        simplex.pushFront(newSupport)
        
        if HandleSimplex(simplex: &simplex, direction: &direction) {
            return true
        }
    }
    
    return false
}
