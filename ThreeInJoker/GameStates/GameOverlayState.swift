import SpriteKit
import GameplayKit

class GameOverlayState: GKState {
  
  unowned let gameScene: GameScene
  
  var overlay: SceneOverlay!
  var overlaySceneFileName: String { fatalError("Unimplemented overlaySceneName") }
  
  init(gameScene: GameScene) {
    self.gameScene = gameScene
    super.init()
    
    overlay = SceneOverlay(overlaySceneFileName: overlaySceneFileName, zPosition: 2)
    
    ButtonNode.parseButtonInNode(containerNode: overlay.contentNode)
  }
  
  override func didEnter(from previousState: GKState?) {
    super.didEnter(from: previousState)
    gameScene.isPaused = true
    gameScene.overlay = overlay
  }
  
  override func willExit(to nextState: GKState) {
    super.willExit(to: nextState)
    gameScene.isPaused = false
    gameScene.overlay = nil
  }
}
