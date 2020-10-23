//
//  MenuScene.swift
//  Robo2
//
//  Created by Cade Corontzos on 4/30/20.
//  Copyright © 2020 Cade Corontzos. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {

    var newGameButton = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        newGameButton = self.childNode(withName: "newGameButton") as! SKSpriteNode
        
    }
}
