//
//  Textures.swift
//  Icarus
//
//  Created by Andrew Eeckman on 1/12/23.
//

import Foundation
import SpriteKit

class Textures {
    static let textures = Textures()
    let texturesAtlas = SKTextureAtlas(named: "textures")

    func preloadTextures() {
        texturesAtlas.preload(completionHandler: debugCheck)
    }
    
    func debugCheck() {
        print("Texture Atlas Preloaded")
    }
}
