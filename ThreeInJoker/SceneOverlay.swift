import SpriteKit

class SceneOverlay {
  
  let backgroundNode: SKSpriteNode
  let contentNode: SKSpriteNode
//  let levelLabelNode: SKLabelNode
  let nativeContentSize: CGSize
    
  var level: Int = 1
//{
//    didSet {
//      levelLabelNode.text = "\(level)"
//    }
//  }
  
  init(overlaySceneFileName fileName: String, zPosition: CGFloat) {
    
    let overlayScene = SKScene(fileNamed: fileName)
    let contentTemplateNode = overlayScene?.childNode(withName: "Overlay") as! SKSpriteNode
    
    backgroundNode = SKSpriteNode(color: contentTemplateNode.color, size: contentTemplateNode.size)
    backgroundNode.zPosition = zPosition
    
    contentNode = contentTemplateNode.copy() as! SKSpriteNode
    
//    levelLabelNode = SKLabelNode(fontNamed: "Trattatello")
//    if fileName == "SuccessScene" {
//        levelLabelNode.fontSize = 40
//        levelLabelNode.text = "0"
//        levelLabelNode.horizontalAlignmentMode = .center
//        levelLabelNode.position = CGPoint(x: 60, y: 80)
//        contentNode.addChild(levelLabelNode)
//    }
    
    contentNode.position = .zero
    backgroundNode.addChild(contentNode)
    
    contentNode.color = .clear
    
    nativeContentSize = contentNode.size
  }
  
  func updateScale() {
    guard let viewSize = backgroundNode.scene?.view?.frame.size else {
      return
    }
    
    backgroundNode.size = viewSize
    
    let scale = viewSize.height/nativeContentSize.height
    contentNode.setScale(scale)
  }
}
