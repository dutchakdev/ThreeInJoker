import SpriteKit
import GameplayKit

class GamePauseState: GameOverlayState {
  
  override var overlaySceneFileName: String {
    return "PauseScene"
  }
  
  override func didEnter(from previousState: GKState?) {
    super.didEnter(from: previousState)
    
    gameScene.isPaused = true
  }
  
  override func isValidNextState(_ stateClass: AnyClass) -> Bool {
    return stateClass is GameActiveState.Type
  }
  
  override func willExit(to nextState: GKState) {
    super.willExit(to: nextState)
    
    gameScene.isPaused = false
  }
}
