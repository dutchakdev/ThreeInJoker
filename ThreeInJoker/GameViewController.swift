//
//  GameViewController.swift
//  BiscuitCrunch
//
//  Created by Leonardo Almeida silva ferreira on 24/09/16.
//  Copyright (c) 2016 kkwFwk. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation
import GoogleMobileAds

class GameViewController: UIViewController {
	
	let kGameOverSegue = "kGameOverSegue"
	
    var gameScene: GameScene!
    var level: Level!
    var tapGestureRecognizer: UITapGestureRecognizer!
	
    
    lazy var gameBackgroundMusic: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "", withExtension: "mp3") else {
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            return player
        } catch {
            return nil
        }
    }()
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var levelStackView: UIStackView!
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var shuffleButton: UIButton!
	@IBOutlet var levelController: LevelController!
	var bannerView: GADBannerView!
	
    @IBAction func shuffleButtonPressed(btn: AnyObject) {
		shuffleButton.isEnabled = gameScene.movesLeft > 1
		
		gameScene.shuffle()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
		level = Level(level: SettingsStorage.shared.level)
        

		
        if let scene = GameScene(fileNamed: "GameScene") {
            // Create and configure the scene.
            //scene = GameScene(size: skView.bounds.size)

			gameScene = scene
            gameScene.gameSceneDelegate = self

            // Configure the view.
            let skView = self.view as! SKView
//            skView.showsFPS = true
//            skView.showsNodeCount = true
            skView.isMultipleTouchEnabled = false

            /* Sprite Kit applies additional optimizations to improve rendering performance */
            // skView.ignoresSiblingOrder = true

			gameScene.size = view.bounds.size
            gameScene.scaleMode = .resizeFill
            gameScene.level = level

            // Present the scene.
            skView.presentScene(scene)


            // Start menu background music.
            SKTAudio.sharedInstance().playBackgroundMusic(filename: "Karibu Watu Wangu.mp3")
        }
		
		setupBanner()
    }
    
	@IBAction func menuDidTapAction(_ sender: UIButton) {
		SKTAudio.sharedInstance().playSoundEffect(filename: "button_press.wav")
		SKTAudio.sharedInstance().pauseBackgroundMusic()
		self.navigationController?.popViewController(animated: true)
	}
	
	func setupBanner() {
		
		GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["2bd7b2576970aeb9b6f37ef76b36246a", (kGADSimulatorID as! String)]
		
		bannerView = GADBannerView(adSize: kGADAdSizeBanner)
//		#if DEBUG
//		bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
//		#else
		bannerView.adUnitID = "ca-app-pub-4053997895468335/3635626908"
//		#endif
		
		bannerView.rootViewController = self
		
		bannerView.load(GADRequest())
		addBannerViewToView(bannerView)
	}
		
	func addBannerViewToView(_ bannerView: GADBannerView) {
		bannerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(bannerView)
		view.addConstraints(
			[
				NSLayoutConstraint(item: bannerView,
								attribute: .bottom,
								relatedBy: .equal,
								toItem: view,
								attribute: .bottom,
								multiplier: 1,
								constant: 0),
			 NSLayoutConstraint(item: bannerView,
								attribute: .centerX,
								relatedBy: .equal,
								toItem: view,
								attribute: .centerX,
								multiplier: 1,
								constant: 0)

		])
	}
	
    override var shouldAutorotate : Bool {
        return true
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.portrait, UIInterfaceOrientationMask.portraitUpsideDown]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == kGameOverSegue {
			let vc = segue.destination as! GameOverViewController
			vc.delegate = self
			
		}
	}
    
}

extension GameViewController: GameSceneProtocol {
    func didSelectCancelButton(gameScene: GameScene) {
        navigationController?.popToRootViewController(animated: false)
    }
    
    func didShowOverlay(gameScene: GameScene) {
        self.shuffleButton.isHidden = true
        self.stackView.isHidden = true
        self.levelStackView.isHidden = true
    }
    
    func didDismissOverlay(gameScene: GameScene) {
        self.shuffleButton.isHidden = false
        self.stackView.isHidden = false
        self.levelStackView.isHidden = false
    }
    
    func updateLabels(targetScore: Int, movesLeft: Int, score: Int) {
		shuffleButton.isEnabled = gameScene.movesLeft > 1
		
        targetLabel.text = String(format: "%ld", targetScore)
        movesLabel.text = String(format: "%ld", movesLeft)
        scoreLabel.text = String(format: "%ld", score)

		
		levelController.leftLabel.text = "\(gameScene.level.currentLevel())"
		levelController.rightLabel.text = "\(gameScene.level.currentLevel() + 1)"
		levelController.progress = Double(score) / Double(targetScore)
    }
	
	func showGameOver(gameScene: GameScene) {
		self.performSegue(withIdentifier: kGameOverSegue, sender: nil)
	}
	
    
    #if os (tvOS)
    override func pressesBegan(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        scene.pressesBegan(presses, withEvent: event)
    }
    #endif
}

extension GameViewController: GameOverViewControllerDelegate {
	func gameOverViewControllerDidTapRestart() {
		gameScene.restart()
	}
	
	func gameOverViewControllerDidTapMenu() {
		navigationController?.popViewController(animated: false)
	}
}
