//
//  VibrationManager.swift

import UIKit
import GameplayKit
import AudioToolbox.AudioServices

enum NoiseType: Int{
	case Peek = 0
	case Pop
	case Cancel
	case TryAgain
	case Failed
	case Impact
}


class VibrationManager: NSObject {

	static let shared = VibrationManager()
	
	func randNoiser() {
		let value = 1000 + GKRandomSource.sharedRandom().nextInt(upperBound: 11)
		AudioServicesPlayAlertSound(UInt32(value))
	}
	
	func lightImpact() {
		guard !SettingsStorage.shared.vibration else {
			return
		}
		
		let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
		impactFeedbackGenerator.prepare()
		impactFeedbackGenerator.impactOccurred()
	}
	
	func heavyImpact() {
		guard !SettingsStorage.shared.vibration else {
			return
		}
		
		let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
		impactFeedbackGenerator.prepare()
		impactFeedbackGenerator.impactOccurred()
	}
	
	func cancelVibration() {
		guard !SettingsStorage.shared.vibration else {
			return
		}
		
		AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
	}
	
	func randVibaration() {
		guard !SettingsStorage.shared.vibration else {
			return
		}
		
		let value = GKRandomSource.sharedRandom().nextInt(upperBound: 6)
		let vibrationType = NoiseType(rawValue: value)!
		switch vibrationType {
		case .Peek:
			let peek = SystemSoundID(1519)
			AudioServicesPlaySystemSound(peek)
			break;
		case .Pop:
			let pop = SystemSoundID(1520)
			AudioServicesPlaySystemSound(pop)
			break;
		case .Cancel:
			let cancelled = SystemSoundID(1521)
			AudioServicesPlaySystemSound(cancelled)
			break;
		case .TryAgain:
			let tryAgain = SystemSoundID(1102)
			AudioServicesPlaySystemSound(tryAgain)
			break;
		case .Failed:
			let failed = SystemSoundID(1107)
			AudioServicesPlaySystemSound(failed)
			break;
			
		case .Impact:
			let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
			lightImpactFeedbackGenerator.prepare()
			lightImpactFeedbackGenerator.impactOccurred()
			break;
		}
	}
}
