//
//  LevelController.swift
//  JokerStrike
//
//  Created by Artyom Lihach on 28/10/2019.
//  Copyright © 2019 JokerStrike. All rights reserved.
//

import UIKit

class LevelController: UIView {

	@IBOutlet var contentView: UIView!
	@IBOutlet var leftView: UIView!
	@IBOutlet var rightView: UIView!
	
	@IBOutlet var leftLabel: UILabel!
	@IBOutlet var rightLabel: UILabel!
	
	@IBOutlet var lineContentView: UIView!
	@IBOutlet var lineWidthConstraint: NSLayoutConstraint!
	
	var progress: Double = 0 { //0...1

		didSet {
			if (progress > 1) {
				progress = 1
			}
			let width = lineContentView.frame.size.width * CGFloat (progress)
			lineWidthConstraint.constant
			= width
			layoutSubviews()
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
	
	func commonInit() {
		let xibName = String(describing: LevelController.self)
		Bundle.main.loadNibNamed(xibName, owner: self, options: nil)
		contentView.fixInView(self)
	}
	
	override func awakeFromNib() {
		progress = 0
	}
	
	func setup() {
		leftView.setRounded()
		rightView.setRounded()
	}
	
	override func layoutSubviews() {
		setup()
	}
}


extension UIView
{
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}

extension UIView {

   func setRounded() {
	let radius = self.frame.width / 2
      self.layer.cornerRadius = radius
      self.layer.masksToBounds = true
   }
}


