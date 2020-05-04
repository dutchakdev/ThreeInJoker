//
//  GameScene.swift
//  BiscuitCrunch
//
//  Created by Leonardo Almeida silva ferreira on 24/09/16.
//  Copyright (c) 2016 kkwFwk. All rights reserved.
//

import SpriteKit
import GameplayKit

struct Emitter {
	static let flame: String = "Fire"
}

struct Layer {
	static let background: CGFloat = 1
	static let circle: CGFloat = 2
	static let flame: CGFloat = 6
}

protocol GameSceneProtocol {
    func didSelectCancelButton(gameScene: GameScene)
    func didShowOverlay(gameScene: GameScene)
    func didDismissOverlay(gameScene: GameScene)
    func updateLabels(targetScore: Int, movesLeft: Int, score: Int)
	
	func showGameOver(gameScene: GameScene)
}


class GameScene: SKScene {
    
    var gameSceneDelegate: GameSceneProtocol?
    
    fileprivate var swipeFromColumn: Int?
    fileprivate var swipeFromRow: Int?
    var selectionSprite = SKSpriteNode()
    
    var level: Level!
    var movesLeft = 0
    var score = 0
    var swipeHandler: ((Swap) -> ())?
	var shuffleHandler: (() -> ())?
    
    let TileWidth: CGFloat = 32.0
    let TileHeight: CGFloat = 36.0
    
    let gameLayer = SKNode()
    let cookiesLayer = SKNode()
    let tilesLayer = SKNode()
    let cropLayer = SKCropNode()
    let maskLayer = SKNode()
	
	private var jokerNode: SKSpriteNode!
    
    var swapSound: SKAction!, invalidSwapSound: SKAction!,
        matchSound: SKAction!, fallingCookieSound: SKAction!,
        addCookieSound: SKAction!
    
    var buttons = [ButtonNode]()
    var priorTouch: CGPoint = .zero
    var focusChangesEnabled = false
    
    var overlay: SceneOverlay?  {
        didSet {
            
            buttons = []
            oldValue?.backgroundNode.removeFromParent()
            
            if overlay != nil, camera != nil {
                
                camera?.addChild((overlay?.backgroundNode)!)
                buttons = findAllButtonsInScene()
                
                #if os(tvOS)
                    resetFocus()
                #endif
                
                focusChangesEnabled = true
                
                gameSceneDelegate?.didShowOverlay(gameScene: self)
            } else {
                focusChangesEnabled = false
                gameSceneDelegate?.didDismissOverlay(gameScene: self)
            }
        }
    }
    
    func decrementMoves() {
        movesLeft -= 1
        gameSceneDelegate?.updateLabels(targetScore: level.targetScore, movesLeft: movesLeft, score: score)
    }
    
    lazy var stateMachine: GKStateMachine = GKStateMachine(states: [
        GameActiveState(gameScene: self),
        GamePauseState(gameScene: self),
        GameFailureState(gameScene: self),
        GameSuccessState(gameScene: self)
        ])
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
		setupBackground()
		setupJokerNode()
		
        anchorPoint = CGPoint(x: 0, y: 0)
        
        swipeFromColumn = nil
        swipeFromRow = nil
        
//        ButtonNode.parseButtonInNode(containerNode: self)
//        
//        let pauseButton = childNode(withName: "pause") as! SKSpriteNode
//        pauseButton.anchorPoint = .zero
//        pauseButton.position = CGPoint(x: size.width - pauseButton.size.width, y: size.height - pauseButton.size.height - overlapAmount()/2)
//        
        swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
        invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
        matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
        fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
        addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
        
//        #if os(tvOS)
//            pauseButton.removeFromParent()
//        #endif
    
        let gameLayer = SKNode() //childNode(withName: "gameLayer")! as SKNode

		
        let layerPosition = CGPoint(
            x: TileWidth * CGFloat(NumColumns) / 2,
            y: TileHeight * CGFloat(NumRows) / 2
        )

		print(size.width)
		print(TileWidth)
		gameLayer.position = CGPoint(x: -layerPosition.x + (size.width/2 - layerPosition.x), y: 0)
		gameLayer.zPosition = 1
        addChild(gameLayer)
		
        let camera = SKCameraNode()
        scene?.camera = camera
        scene?.addChild(camera)
        setCameraPosition(position: CGPoint(x: size.width/2, y: size.height/2))
        
        tilesLayer.position = layerPosition
        gameLayer.addChild(tilesLayer)
        gameLayer.addChild(cropLayer)
        
        maskLayer.position = layerPosition
        cropLayer.maskNode = maskLayer
        
        cookiesLayer.position = layerPosition
        cropLayer.addChild(cookiesLayer)
        
        addTiles()
        
        stateMachine.enter(GameActiveState.self)
    }
	
	func restart() {
		stateMachine.enter(GameActiveState.self)
		gameSceneDelegate?.updateLabels(targetScore: level.targetScore, movesLeft: movesLeft, score: score)
	}
	
	func setupBackground() {
		let backgroundTexture = SKTexture(imageNamed: "background")
		let background = SKSpriteNode(texture: backgroundTexture)
		background.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
		background.size = size
		addChild(background)
	}
    
	func setupJokerNode() {
		let image = UIImage(named: "joker_ring_img")!
		let texture = SKTexture(image: image)
		jokerNode = SKSpriteNode(texture: texture)
		jokerNode.zPosition = 5
		jokerNode.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
		jokerNode.alpha = 0
		addChild(jokerNode)
	}
	
	func showJokerNodeCompletion(block: @escaping () -> Void) {
		let fadeIn = SKAction.fadeIn(withDuration: 0.5)
		let wait = SKAction.wait(forDuration: 1)
		let fadeOut = SKAction.fadeOut(withDuration: 0.5)
		let action = SKAction.sequence([fadeIn, wait, fadeOut])
		jokerNode.run(action) {
			block()
		}
	}
	
    func setCameraPosition(position: CGPoint) {
        scene?.camera?.position = CGPoint(x: position.x, y: position.y - overlapAmount()/2)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        guard let touch = touches.first else { return }
        let location = touch.location(in: cookiesLayer)
        
        let (success, column, row) = convertPoint(location)
        if success {
            if let cookie = level.cookieAtColumn(column, row: row) {
                showSelectionIndicatorForCookie(cookie)
                swipeFromColumn = column
                swipeFromRow = row
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard swipeFromColumn != nil else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: cookiesLayer)
        
        let (success, column, row) = convertPoint(location)
        if success {
            
            var horzDelta = 0, vertDelta = 0
            if column < swipeFromColumn! {          // swipe left
                horzDelta = -1
            } else if column > swipeFromColumn! {   // swipe right
                horzDelta = 1
            } else if row < swipeFromRow! {         // swipe down
                vertDelta = -1
            } else if row > swipeFromRow! {         // swipe up
                vertDelta = 1
            }
            
            if horzDelta != 0 || vertDelta != 0 {
                trySwapHorizontal(horzDelta, vertical: vertDelta)
                
                hideSelectionIndicator()
                swipeFromColumn = nil
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if selectionSprite.parent != nil && swipeFromColumn != nil {
            hideSelectionIndicator()
        }
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touches = touches
        if #available(iOS 8.0, *) {
            touchesEnded(touches, with: event)
        }
    }
    
    func trySwapHorizontal(_ horzDelta: Int, vertical vertDelta: Int) {
        
        let toColumn = swipeFromColumn! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        
        guard toColumn >= 0 && toColumn < NumColumns else { return }
        guard toRow >= 0 && toRow < NumRows else { return }
        
        if let toCookie = level.cookieAtColumn(toColumn, row: toRow),
            let fromCookie = level.cookieAtColumn(swipeFromColumn!, row: swipeFromRow!) {
            if let handler = swipeHandler {
                let swap = Swap(cookieA: fromCookie, cookieB: toCookie)
                handler(swap)
				VibrationManager.shared.heavyImpact()
            }
        }
		
		VibrationManager.shared.lightImpact()
    }
    
    func addTiles(){
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if level.tileAtColumn(column, row: row) != nil {
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                    tileNode.size = CGSize(width: TileWidth, height: TileHeight)
                    tileNode.position = pointForColumn(column, row: row)
                    maskLayer.addChild(tileNode)
                }
            }
        }
        
        for row in 0...NumRows {
            for column in 0...NumColumns {
                let topLeft     = (column > 0) && (row < NumRows)
                    && level.tileAtColumn(column - 1, row: row) != nil
                let bottomLeft  = (column > 0) && (row > 0)
                    && level.tileAtColumn(column - 1, row: row - 1) != nil
                let topRight    = (column < NumColumns) && (row < NumRows)
                    && level.tileAtColumn(column, row: row) != nil
                let bottomRight = (column < NumColumns) && (row > 0)
                    && level.tileAtColumn(column, row: row - 1) != nil
                
                // The tiles are named from 0 to 15, according to the bitmask that is
                // made by combining these four values.
                let value = (topLeft ? 1 : 0) |
                     (topRight ? 1 : 0) << 1 |
                     (bottomLeft ? 1 : 0) << 2 |
                     (bottomRight ? 1 : 0) << 3
                
                // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
                if value != 0 && value != 6 && value != 9 {
                    let name = String(format: "Tile_%ld", value)
                    let tileNode = SKSpriteNode(imageNamed: name)
                    tileNode.size = CGSize(width: TileWidth, height: TileHeight)
                    var point = pointForColumn(column, row: row)
                    point.x -= TileWidth/2
                    point.y -= TileHeight/2 
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }
            }
        }
    }
    
    func addSpritesForCookies(_ cookies: Set<Cookie>){
        
        for cookie in cookies {
            let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
            sprite.size = CGSize(width: TileWidth, height: TileHeight)
            sprite.position = pointForColumn(cookie.column, row: cookie.row)
            cookiesLayer.addChild(sprite)
            cookie.sprite = sprite
            
            // Give each cookie sprite a small, random delay. Then fade them in.
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.run(
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.25, withRange: 0.5),
                    SKAction.group([
                        SKAction.fadeIn(withDuration: 0.25),
                        SKAction.scale(to: 1.0, duration: 0.25)
                        ])
                    ]))
        }
    }
    
    func pointForColumn(_ column: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column)*TileWidth + TileWidth/2,
            y: CGFloat(row)*TileHeight + TileHeight/2
        )
    }
    
    func convertPoint(_ point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(NumColumns)*TileWidth &&
            point.y >= 0 && point.y < CGFloat(NumRows)*TileHeight {
            return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
        } else {
            return (false, 0, 0)  // invalid location
        }
    }
    
    func showSelectionIndicatorForCookie(_ cookie: Cookie) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        
        if let sprite = cookie.sprite {
            let texture = SKTexture(imageNamed: cookie.cookieType.highlightedSpriteName)
            selectionSprite.size = CGSize(width: TileWidth, height: TileHeight)
            selectionSprite.run(SKAction.setTexture(texture))
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    
    func removeAllCookieSprites() {
        cookiesLayer.removeAllChildren()
    }
    
    func hideSelectionIndicator() {
        selectionSprite.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()]))
    }

    
    func animateSwap(_ swap: Swap, completion: @escaping () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: TimeInterval = 0.3
        
        let moveA = SKAction.move(to: spriteB.position, duration: Duration)
        moveA.timingMode = .easeOut
        spriteA.run(moveA, completion: completion)
        
        let moveB = SKAction.move(to: spriteA.position, duration: Duration)
        moveB.timingMode = .easeOut
        spriteB.run(moveB)
        play(sound: swapSound)
    }
    
    func animateInvalidSwap(_ swap: Swap, completion: @escaping () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: TimeInterval = 0.2
        
        let moveA = SKAction.move(to: spriteB.position, duration: Duration)
        moveA.timingMode = .easeOut
        
        let moveB = SKAction.move(to: spriteA.position, duration: Duration)
        moveB.timingMode = .easeOut
        
        spriteA.run(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.run(SKAction.sequence([moveB, moveA]))
        play(sound: invalidSwapSound)
    }
    
    func animateMatchedCookies(_ chains: Set<Chain>, completion: @escaping () -> ()) {
        for chain in chains {
            animateScoreForChain(chain)
            for cookie in chain.cookies {
                if let sprite = cookie.sprite {
                    if sprite.action(forKey: "removing") == nil {
                        let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
                        scaleAction.timingMode = .easeOut
                        sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                                         withKey:"removing")
                    }
                }
            }
        }
        play(sound: matchSound)
        run(SKAction.wait(forDuration: 0.3), completion: completion)
    }
    
    func animateFallingCookies(_ columns: [[Cookie]], completion: @escaping () -> ()) {
        var longestDuration: TimeInterval = 0
        for array in columns {
            for (idx, cookie) in array.enumerated() {
                let newPosition = pointForColumn(cookie.column, row: cookie.row)
                // 2
                let delay = 0.05 + 0.15*TimeInterval(idx)
                // 3
                let sprite = cookie.sprite!
                let duration = TimeInterval(((sprite.position.y - newPosition.y) / TileHeight) * 0.1)
                // 4
                longestDuration = max(longestDuration, duration + delay)
                // 5
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
				let fallingCookieAction = SKAction.run {
					self.play(sound: self.fallingCookieSound)
				}
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([moveAction, fallingCookieAction])]))
            }
        }
        // 6
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateNewCookies(_ columns: [[Cookie]], completion: @escaping () -> ()) {
        // 1
        var longestDuration: TimeInterval = 0
        
        for array in columns {
            // 2
            let startRow = array[0].row + 1
            
            for (idx, cookie) in array.enumerated() {
                // 3
                let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
                sprite.size = CGSize(width: TileWidth, height: TileHeight)
                sprite.position = pointForColumn(cookie.column, row: startRow)
                cookiesLayer.addChild(sprite)
                cookie.sprite = sprite
                // 4
                let delay = 0.1 + 0.2 * TimeInterval(array.count - idx - 1)
                // 5
                let duration = TimeInterval(startRow - cookie.row) * 0.1
                longestDuration = max(longestDuration, duration + delay)
                // 6
                let newPosition = pointForColumn(cookie.column, row: cookie.row)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.alpha = 0
				let addCookieAction = SKAction.run {
					self.play(sound: self.addCookieSound)
							}
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([
                            SKAction.fadeIn(withDuration: 0.05),
                            moveAction,
                            addCookieAction])
                        ]))
            }
        }
        // 7
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateScoreForChain(_ chain: Chain) {
        let firstSprite = chain.firstCookie().sprite!
        let lastSprite = chain.lastCookie().sprite!
        let centerPosition = CGPoint(
            x: (firstSprite.position.x + lastSprite.position.x)/2,
            y: (firstSprite.position.y + lastSprite.position.y)/2 - 8)
        
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
        scoreLabel.fontSize = 16
        scoreLabel.text = String(format: "%ld", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        cookiesLayer.addChild(scoreLabel)
        
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 3), duration: 0.7)
        moveAction.timingMode = .easeOut
        scoreLabel.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
    }
    
    func animateGameOver(_ completion: @escaping () -> ()) {
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeIn
        gameLayer.run(action, completion: completion)
    }
    
    func animateMainMenu(_ completion: @escaping () -> ()) {
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeIn
        gameLayer.run(action, completion: completion)
    }
    
    func animateBeginGame(_ completion: @escaping () -> ()) {
        gameLayer.isHidden = false
		gameLayer.position = CGPoint(x: 0, y: size.height)
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeOut
        gameLayer.run(action, completion: completion)
    }
    
    func overlapAmount() -> CGFloat {
        guard let view = self.view else {
            return 0
        }
        let scale = view.bounds.size.width / self.size.width
        let scaledHeight = self.size.height * scale
        let scaledOverlap = scaledHeight - view.bounds.size.height
        return scaledOverlap / scale
    }
	
	func showFireFlame() {
		SKTAudio.sharedInstance().playSoundEffect(filename: "fire.mp3")
		showJokerNodeCompletion {
		}
		
		let position = CGPoint(x: size.width/2, y: size.height/2)
		let fire = showFire(position: position)
		addChild(fire)
	}
	
	func showFire(position: CGPoint) -> SKEmitterNode {
		let emitter = SKEmitterNode(fileNamed: Emitter.flame)!
		emitter.zPosition = Layer.flame
		emitter.position = position
		return emitter
	}
    
    func shuffle(){
		if let handler = shuffleHandler {
			handler()
		}
		showFireFlame()
        removeAllCookieSprites()
        let newCookies = level.shuffle()
        addSpritesForCookies(newCookies)
        gameSceneDelegate?.didDismissOverlay(gameScene: self)
    }
    
    override func update(_ currentTime: TimeInterval) {
        stateMachine.update(deltaTime: currentTime)
    }
    
    func updateLabels() {
        gameSceneDelegate?.updateLabels(targetScore: level.targetScore, movesLeft: movesLeft, score: score)
    }
    
}

extension GameScene {

	func play(sound: SKAction) {
		guard SettingsStorage.shared.sound else {
			return
		}
		run(sound, withKey: "sound")
	}
	
}
