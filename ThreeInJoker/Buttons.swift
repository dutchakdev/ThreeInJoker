import Foundation

extension GameScene: ButtonNodeResponder {
  
  func findAllButtonsInScene() -> [ButtonNode] {
    return ButtonIdentifier.allIdentifiers.flatMap { buttonIdentifier in
      return childNode(withName: "//\(buttonIdentifier.rawValue)") as? ButtonNode
    }
  }
  
  func buttonPressed(button: ButtonNode) {
    switch button.buttonIdentifier! {
      case .Resume:
        stateMachine.enter(GameActiveState.self)
      case .Cancel:
        gameSceneDelegate?.didSelectCancelButton(gameScene: self)
      case .NextLevel:
        stateMachine.enter(GameActiveState.self)
      case .Pause:
        stateMachine.enter(GamePauseState.self)
    }
  }
}
