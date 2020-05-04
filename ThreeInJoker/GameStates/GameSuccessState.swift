import SpriteKit
import GameplayKit

class GameSuccessState: GameOverlayState {

  override var overlaySceneFileName: String {
    return "SuccessScene"
  }
    
  override func didEnter(from previousState: GKState?) {
      super.didEnter(from: previousState)
    
      gameScene.isPaused = true
  }
    
  
  override func isValidNextState(_ stateClass: AnyClass) -> Bool {
    return stateClass is GameActiveState.Type
  }
}
