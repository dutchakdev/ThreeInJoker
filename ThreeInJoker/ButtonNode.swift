import SpriteKit

protocol ButtonNodeResponder {
  func buttonPressed(button: ButtonNode)
}

enum ButtonIdentifier: String {
  case Resume = "resume"
  case Cancel = "cancel"
  case NextLevel = "nextlevel"
  case Pause  = "pause"
  
  static let allIdentifiers: [ButtonIdentifier] = [.Resume, .Cancel, .NextLevel, .Pause]
  
  var selectedTextureName: String? {
    switch self {
      default:
        return nil
    }
  }
  
  var focusedTextureName: String? {
    switch self {
      case .NextLevel:
        return "button_green_focussed"
      case .Cancel:
        return "button_red_focussed"
      default:
        return nil
    }
  }
}

class ButtonNode: SKSpriteNode {
  
  var defaultTexture: SKTexture?
  var selectedTexture: SKTexture?
  var focusedTexture: SKTexture?
  
  var buttonIdentifier: ButtonIdentifier!
  
  var responder: ButtonNodeResponder {
    guard let responder = scene as? ButtonNodeResponder else {
      fatalError("ButtonNode may only be used within a 'ButtonNodeResponder' scene")
    }
    return responder
  }
  
  var isHighlighted = false {
    didSet {
      colorBlendFactor = isHighlighted ? 1.0 : 0.0
    }
  }
  
  var isSelected = false {
    didSet {
      texture = isSelected ? selectedTexture : defaultTexture
    }
  }
  
  var isFocused = false {
    didSet {
      if isFocused {
        setScale(CGFloat(1.08))
      } else {
        setScale(CGFloat(1))
      }
      texture = isFocused ? focusedTexture : defaultTexture
      
      if let label = childNode(withName: "label") as? SKLabelNode {
        label.fontColor = isFocused ? SKColor.black : SKColor.white
      }
    }
  }
  
  init(templateNode: SKSpriteNode) {
    super.init(texture: templateNode.texture, color: SKColor.clear, size: templateNode.size)
    
    guard let nodeName = templateNode.name, let buttonIdentifier = ButtonIdentifier(rawValue: nodeName) else {
      fatalError("Unsupported button name found")
    }
    
    self.buttonIdentifier = buttonIdentifier
    
    name = templateNode.name
    position = templateNode.position
    
    //zPosition
    
    color = SKColor(white: 0.8, alpha: 1.0)
    
    defaultTexture = texture
    
    if let textureName = buttonIdentifier.selectedTextureName {
      selectedTexture = SKTexture(imageNamed: textureName)
    } else {
      selectedTexture = texture
    }
    
    if let focusedTextureName = buttonIdentifier.focusedTextureName {
      focusedTexture = SKTexture(imageNamed: focusedTextureName)
    } else {
      focusedTexture = texture
    }
    
    for child in templateNode.children {
      addChild(child.copy() as! SKNode)
    }
    
    isUserInteractionEnabled = true
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  func buttonTriggered() {
    if isUserInteractionEnabled {
      responder.buttonPressed(button: self)
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
    super.touchesBegan(touches, with: event)
    
    if hasTouchWithinButton(touches: touches) {
      isHighlighted = true
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    
    isHighlighted = false
    
    if hasTouchWithinButton(touches: touches) {
      responder.buttonPressed(button: self)
    }
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
    super.touchesCancelled(touches!, with: event)
    
    isHighlighted = false
  }
  
  func hasTouchWithinButton(touches: Set<UITouch>) -> Bool {
    guard let scene = scene else {fatalError("Button must be used within a scene")}
    
    let touchesInButton = touches.filter { touch in
      let touchPoint = touch.location(in: scene)
      let touchedNode = scene.atPoint(touchPoint)
      return touchedNode === self || touchedNode.inParentHierarchy(self)
    }
    return !touchesInButton.isEmpty
  }
  
  // MARK: Convenience
  static func parseButtonInNode(containerNode: SKNode) {
    for identifier in ButtonIdentifier.allIdentifiers {
      
      guard let templateNode = containerNode.childNode(withName: identifier.rawValue) as? SKSpriteNode else { continue}
      
      let buttonNode = ButtonNode(templateNode: templateNode)
      buttonNode.zPosition = templateNode.zPosition
      
      containerNode.addChild(buttonNode)
      templateNode.removeFromParent()
    }
  }
}
