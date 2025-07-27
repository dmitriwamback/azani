//
//  ViewController.swift
//  azani
//
//  Created by Dmitri Wamback on 2025-07-27.
//

import Cocoa
import Metal
import MetalKit

class ViewController: NSViewController {

    var renderer: Renderer?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view = ScreenView(frame: CGRect(x: 0, y: 0, width: 1200, height: 800))
        
        guard let metal = view as? MTKView else {
            fatalError("Metal view not set up")
        }
        
        renderer = Renderer(metal: metal)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

