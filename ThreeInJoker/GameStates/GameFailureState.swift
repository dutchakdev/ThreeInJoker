import GameplayKit
import SpriteKit

class GameFailureState: GameOverlayState {
  
  override var overlaySceneFileName: String {
    return "FailureScene"
  }
  
  override func didEnter(from previousState: GKState?) {
    super.didEnter(from: previousState)
  }

  override func isValidNextState(_ stateClass: AnyClass) -> Bool {
    return true
  }

}
