//
//  ViewController.swift


import UIKit
import GameKit
import FacebookCore

class MenuViewController: UIViewController {
    
	@IBOutlet var vibrationBtn: UIButton!
	@IBOutlet var soundBtn: UIButton!
	
	var isAuthenticated: Bool? {
        didSet {
            if isAuthenticated != oldValue, isAuthenticated == true {
                UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated")
                UserDefaults.standard.synchronize()
            }
        }
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		update()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

        isAuthenticated = UserDefaults.standard.object(forKey: "isAuthenticated") as? Bool
    }
    
    var firstLoad = true
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if firstLoad {
            firstLoad = false
            authPlayerOnStart(true) { (success) in }
        }
    }
	
	func update() {
		vibrationBtn.isSelected = !SettingsStorage.shared.vibration
		soundBtn.isSelected = !SettingsStorage.shared.sound
	}
    
    private func reportScore() {
        authPlayerOnStart(false) { (success) in
            if success {
                self.reportScoreAndShowLeaderboard()
            }
        }
    }
    
    private func authPlayerOnStart(_ onStart: Bool, block: @escaping (_ success: Bool) -> ()) {
        if onStart, isAuthenticated != true {
            block(false)
            return
        }
        if !onStart, isAuthenticated == true {
            block(true)
            return
        }
        
		let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { (controller, error) in
            if let currentController = controller {
                self.present(currentController, animated: true, completion: nil)
            } else {
                self.isAuthenticated = error == nil ? localPlayer.isAuthenticated : false
                block(localPlayer.isAuthenticated)
            }
        }
    }
    
    func reportScoreAndShowLeaderboard() {
		
		let scoreReporter = GKScore(leaderboardIdentifier: kLeaderBoardId)
		scoreReporter.value = Int64(SettingsStorage.shared.level)

        GKScore.report([scoreReporter], withCompletionHandler: nil)
        
        showGameCenterVC()
    }
	
	@IBAction func soundDidTapAction(_ sender: UIButton) {
		soundBtn.isSelected = !sender.isSelected //paste button action from here
		SettingsStorage.shared.sound = !soundBtn.isSelected
	}
	
	@IBAction func vibraDidTapAction(_ sender: UIButton) {
		vibrationBtn.isSelected = !sender.isSelected
		SettingsStorage.shared.vibration = !vibrationBtn.isSelected
	}
	
	@IBAction func shareDidTapAction(_ sender: UIButton) {
		let text = "Let's play in this cool game....."
		let activityViewController =
		UIActivityViewController(activityItems: [text],
								 applicationActivities: nil)
		present(activityViewController, animated: true, completion: nil)
	}

    private func showGameCenterVC() {
        let gameCenterVC = GKGameCenterViewController()
        gameCenterVC.gameCenterDelegate = self
        
        present(gameCenterVC, animated: true, completion: nil)
    }
    
    @IBAction func statisticButtonPressed(_ sender: UIButton) {
        reportScore()
    }
}

extension MenuViewController: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
