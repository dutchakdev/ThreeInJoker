//
//  GameOverViewController.swift

import UIKit

protocol GameOverViewControllerDelegate: class {
    func gameOverViewControllerDidTapMenu()
    func gameOverViewControllerDidTapRestart()
}

class GameOverViewController: UIViewController {
    
    weak var delegate: GameOverViewControllerDelegate?
    
    override func viewWillAppear(_ animated: Bool) {

    }
	
    @IBAction func menuButtonTapped(_ sender: UIButton) {
        self.dismiss(animated:false) {
            self.delegate?.gameOverViewControllerDidTapMenu()
        }
    }
	
	@IBAction func shareDidTapAction(_ sender: UIButton) {
		let text = "Let's play in this cool game....."
		let activityViewController =
		UIActivityViewController(activityItems: [text],
								 applicationActivities: nil)
		present(activityViewController, animated: true, completion: nil)
	}
	
	@IBAction func restartButtonTapped(_ sender: UIButton) {
		self.dismiss(animated:true) {
			self.delegate?.gameOverViewControllerDidTapRestart()
		}
	}

	
	@IBAction func rateUsDidTapAction(_ sender: UIButton) {
		rateApp(appId: kAppId)
	}
	
	fileprivate func rateApp(appId: String) {
		openUrl("itms-apps://itunes.apple.com/app/" + appId)
	}
	fileprivate func openUrl(_ urlString:String) {
		let url = URL(string: urlString)!
		if #available(iOS 10.0, *) {
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
		} else {
			UIApplication.shared.openURL(url)
		}
	}
}
