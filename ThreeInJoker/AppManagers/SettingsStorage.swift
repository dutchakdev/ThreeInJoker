//
//  GameStorage.swift


import UIKit

class SettingsStorage: NSObject {
	let kGameVibration = "kGameVibaration"
	let kGameSound = "kGameSound"
	let kLevel = "kLevel"
	
	static let shared = SettingsStorage()
	
	override init() {
		super.init()
		if UserDefaults.standard.integer(forKey: kLevel) == 0 {
			level = 1
		}
	}
	
	var vibration: Bool {
		set {
			UserDefaults.standard.set(!newValue, forKey: kGameVibration)
			UserDefaults.standard.synchronize()
		}
		get {
			return !UserDefaults.standard.bool(forKey: kGameVibration)
		}
	}
	
	var sound: Bool {
		set {
			UserDefaults.standard.set(!newValue, forKey: kGameSound)
			UserDefaults.standard.synchronize()
		}
		get {
			return !UserDefaults.standard.bool(forKey: kGameSound)
		}
	}
	
	var level: NSInteger {
		set {
			UserDefaults.standard.set(newValue, forKey: kLevel)
			UserDefaults.standard.synchronize()
		}
		get {
			return UserDefaults.standard.integer(forKey: kLevel)
		}
	}
}
