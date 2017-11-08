//
//  RecordSoundsViewController.swift
//  PitchPerfect
//
//  Created by Al Manigsaca on 11/2/17.
//  Copyright © 2017 axillon. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {

    let recordString = "RECORDING IN PROGRESS"
    let stopString   = "TAP TO RECORD"
    
    var audioRecorder : AVAudioRecorder!
    
    @IBOutlet weak var recordingLabel      : UILabel!
    @IBOutlet weak var recordButton        : UIButton!
    @IBOutlet weak var stopRecordingButton : UIButton!
    
    // For record level meter indicator using borderWidth and opacity (ring around the button)
    @IBOutlet weak var audioLevelView: UIView!
    
    var levelTimer    : Timer!
    var meterMaxWidth : CGFloat = 0
    let meterMaxPower : Float = 50.0
    let meterBorderColor = UIColor.lightGray.cgColor
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure meter indicator view (rounded)
        audioLevelView.layer.cornerRadius = audioLevelView.bounds.height/2
        audioLevelView.layer.borderColor  = meterBorderColor
        meterMaxWidth = (audioLevelView.bounds.width - recordButton.bounds.width)/2
        
        // Initially enable record button
        recordingAudio(status: false)
    }
    
    // Update UI elements when recording and when stop button is pressed
    func recordingAudio( status: Bool = true ) {
        
        // Reset meter indicator
        audioLevelView.layer.opacity = 0
        audioLevelView.layer.borderWidth = meterMaxWidth
        
        // When buttons are hidden, does not receive user interaction
        recordButton.isHidden = status
        stopRecordingButton.isHidden = !status
        
        recordingLabel.text = status ? recordString : stopString
    }

    // MARK: - Record Audio
    @IBAction func recordAudio(_ sender: Any) {

        // Update UI
        recordingAudio(status: true)
        
        // Setup file path where to store audio file
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let recordingName = "recordedVoice.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = URL(string: pathArray.joined(separator: "/"))
        
        // Activate audio session and request user permssion to record audio
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord, with:AVAudioSessionCategoryOptions.defaultToSpeaker)
        
        // Record audio
        try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
        
        // Start timer for record time and meter visual update
        levelTimer = Timer.scheduledTimer(timeInterval: 0.05,
                                                target: self,
                                              selector: #selector(self.updateMeter(_:)),
                                              userInfo: nil,
                                               repeats: true)
        
    }
    
    // MARK: - Update Record Time String and Meter
    // Update meter and Record time based on ave power and audio recorder current time
    @objc func updateMeter(_ timer:Timer) {
        
        let minutes     = Int(audioRecorder.currentTime / 60)
        let seconds     = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
        let timerString = String(format: "%02d:%02d", minutes, seconds)

        recordingLabel.text = "\(timerString) \(recordString)"

        audioRecorder.updateMeters()

        // Update meter indicator using UIView border width
        let averagePowerChannel0 = audioRecorder.averagePower(forChannel: 0)

        // Convert power to percentage
        let level : Float = -averagePowerChannel0/meterMaxPower
        
        // Only accept values between 0 and 1 to update opacity and border width
        if level < 1 && level >= 0 {
            audioLevelView.layer.opacity = (1 - level)
            audioLevelView.layer.borderWidth = CGFloat(level) * meterMaxWidth
        }
    }
    
    // MARK: - Stop Recording
    @IBAction func stopRecording(_ sender: Any) {

        // Update UI
        recordingAudio(status: false)
        
        levelTimer.invalidate()
        
        // Stop recording
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            performSegue(withIdentifier: "stopRecording", sender: audioRecorder.url)
        } else {
            print("Recording unsuccessful")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "stopRecording" {
            
            // Pass file path of the audio file to the destination VC
            let playSoundsVC = segue.destination as! PlaySoundsViewController
            let recordedAudioURL = sender as! URL
            playSoundsVC.recordedAudioURL = recordedAudioURL
        }
    }
}

