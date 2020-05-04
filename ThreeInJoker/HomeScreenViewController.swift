import UIKit

class HomeScreenViewController: UIViewController {
    
    var isPlaying: Bool = false
    
    @IBAction func playGame(_ sender: UIButton){
        SKTAudio.sharedInstance().playSoundEffect(filename: "button_press.wav")
        if let levelViewController = storyboard?.instantiateViewController(withIdentifier: "SelectLevelViewController") as? SelectLevelViewController {
            navigationController?.pushViewController(levelViewController, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isPlaying {
            SKTAudio.sharedInstance().playBackgroundMusic(filename: "transport.mp3")
            isPlaying = true
        }
    }
}
