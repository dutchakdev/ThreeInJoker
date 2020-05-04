import UIKit

class SelectLevelViewController: UIViewController {

  @IBAction func backButtonPressed(_ sender: UIButton) {
    navigationController!.popViewController(animated: true)
    SKTAudio.sharedInstance().playSoundEffect(filename: "button_press.wav")
  }
  
  @IBAction func levelButtonPressed(_ sender: UIButton) {
    
    if let gameViewController = storyboard?.instantiateViewController(withIdentifier: "GameViewController") as? GameViewController {
      
      SKTAudio.sharedInstance().playSoundEffect(filename: "button_press.wav")
      
      gameViewController.level = Level(level: sender.tag)
//		gameView Controller.level = Level(level: 6)
      
      navigationController?.pushViewController(gameViewController, animated: false)
    }
  }
}
