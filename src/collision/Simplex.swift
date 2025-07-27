//
//  Simplex.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

import Foundation
import simd

struct Simplex {
    private var points: [SIMD3<Float>] = Array(repeating: SIMD3<Float>(0, 0, 0), count: 4)
    private(set) var simplexSize: Int = 0
    
    mutating func set(_ list: [SIMD3<Float>]) {
        for (i, v) in list.enumerated() where i < 4 {
            points[i] = v
        }
        simplexSize = min(list.count, 4)
    }
    
    subscript(index: Int) -> SIMD3<Float> {
        get { points[index] }
        set { points[index] = newValue }
    }
    
    mutating func pushFront(_ point: SIMD3<Float>) {
        points.insert(point, at: 0)
        if points.count > 4 {
            points.removeLast()
        }
        simplexSize = min(simplexSize + 1, 4)
    }
    
    func size() -> Int {
        return simplexSize
    }
    
    func validPoints() -> ArraySlice<SIMD3<Float>> {
        return points.prefix(simplexSize)
    }
}
