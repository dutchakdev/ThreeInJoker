//
//  Button.swift
//  ChampionsF1Game
//
//  Created by Leonardo Almeida silva ferreira on 16/09/16.
//  Copyright © 2016 kkwFwk. All rights reserved.
//

import UIKit

class Button: UIButton {

  override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
    super.didUpdateFocus(in: context, with: coordinator)
    
    if self == context.nextFocusedView {
      coordinator.addCoordinatedAnimations({self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)}, completion: nil)
    } else if self == context.previouslyFocusedView {
      coordinator.addCoordinatedAnimations({self.transform = CGAffineTransform(scaleX: 1, y: 1)}, completion: nil)
    }
  }
}
