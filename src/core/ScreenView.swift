//
//  ScreenView.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

import MetalKit
import simd

class ScreenView: MTKView {
    
    override var acceptsFirstResponder: Bool { true }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
    }
    
    var keysPressed = Set<UInt16>()
    var mousePosition: NSPoint!
    
    override func keyDown(with event: NSEvent) {
        keysPressed.insert(event.keyCode)
        updateCameraMovement()
    }
    
    override func keyUp(with event: NSEvent) {
        keysPressed.remove(event.keyCode)
        updateCameraMovement()
    }
    
    override func mouseMoved(with event: NSEvent) {
        mousePosition = event.locationInWindow
        Renderer.camera.isRightMouseDown = false
        Renderer.camera.updateRotation(mousePosition: mousePosition)
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        mousePosition = event.locationInWindow
        Renderer.camera.isRightMouseDown = true
        Renderer.camera.updateRotation(mousePosition: mousePosition)
    }
    
    
    func updateCameraMovement() {
        
        let W: UInt16 = 13
        let A: UInt16 = 0
        let S: UInt16 = 1
        let D: UInt16 = 2
        
        Renderer.camera.movement = SIMD4<Float>(
                keysPressed.contains(W) ?  0.1 : 0,
                keysPressed.contains(S) ? -0.1 : 0,
                keysPressed.contains(A) ? -0.1 : 0,
                keysPressed.contains(D) ?  0.1 : 0)
    }
}
