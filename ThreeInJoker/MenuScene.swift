//
//  MenuScene.swift
//  BiscuitCrunch
//
//  Created by Leonardo Almeida silva ferreira on 26/09/16.
//  Copyright © 2016 kkwFwk. All rights reserved.
//

import SpriteKit


class MenuScene: SKScene {

    var playButton = SKSpriteNode()
    let playButtonTex = SKTexture(imageNamed: "play")
    var startNewGame: (() -> ())?
    let cancelSound = SKAction.playSoundFileNamed("MenuDecline.wav", waitForCompletion: false)
    let selectSound = SKAction.playSoundFileNamed("MenuAccept.mp3", waitForCompletion: false)
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let background = SKSpriteNode(imageNamed: "Background")
        background.size = size
        addChild(background)
       
        let _ = SKLabelNode(fontNamed: "GillSans-BoldItalic")
    }

    
    override func didMoveToView(view: SKView) {

        playButton = SKSpriteNode(texture: playButtonTex)
        playButton.position = CGPointMake(frame.midX, frame.midY)
        self.addChild(playButton)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        
        guard let touch = touches.first else { return }
        
        let pos = touch.locationInNode(self)
        let node = self.nodeAtPoint(pos)
            
        if node == playButton {
            runAction(selectSound)
            if let start = startNewGame {
                start()
            }
        }
    }
}