//
//  HomeViewController.swift
//  GuideMe
//
//  Created by Courtney Osborn on 02/02/2017.
//  Copyright © 2017 Leke Abolade. All rights reserved.
//

import UIKit
import Speech
import AudioToolbox

class HomeViewController: UIViewController, SFSpeechRecognizerDelegate{
    
    
    @IBAction func switchTextToSpeech(_ sender: UISwitch) {
        
    }
    @IBOutlet weak var dictatebutton: UIButton!
    
//    @IBOutlet weak var textview: UITextView!
//    
//    
    
    
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let audioEngine = AVAudioEngine()
    
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    
 
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
    textFieldShouldReturn(textField: textField)
        print("HELLO")
    }

    
    @IBOutlet weak var textField: UITextField!
    
       override func viewDidLoad() {
        super.viewDidLoad()
         dictatebutton.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! ViewController
        viewController.receivedDestination = textField.text!
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

    
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true;
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            OperationQueue.main.addOperation {
                
                switch authStatus {
                case .authorized:
                    
                    self.dictatebutton.isEnabled = true
                    
                case .denied:
                    self.dictatebutton.isEnabled = false
                    self.dictatebutton.setTitle("User denied access to speech recognition.", for: .disabled)
                    
                    
                case .restricted:
                    self.dictatebutton.isEnabled = false
                    self.dictatebutton.setTitle("Speech recognition restricted on device.", for: .disabled)
                    
                    
                case .notDetermined:
                    self.dictatebutton.isEnabled = false
                    self.dictatebutton.setTitle("Speech recognition not yet authorized.", for: .disabled)
                    
                }
            }
            
        }
        
    }
    
    
    func StartRecording() throws {
        
        
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
            
            
        }
        
        let audioSession = AVAudioSession.sharedInstance()
      
        try audioSession.setCategory(AVAudioSessionCategoryMultiRoute)

        
        
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SfSpeechAudioBufferRecognitionRequest object")}
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in var isFinal = false
            
            if let result = result {
                self.textField.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.dictatebutton.isEnabled = true
                self.dictatebutton.setTitle("Start Speaking", for: [])
            }
            
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
        
        textField.text = "I'm listening."
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            
            dictatebutton.isEnabled = true
            dictatebutton.setTitle("Start Recording", for: [])
        } else {
            dictatebutton.isEnabled = false
            dictatebutton.setTitle("Recognition not available.", for: .disabled)
        }
        
    }
    
    @IBAction func dictateaction(_ sender: UIButton) {
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            dictatebutton.isEnabled = false
            dictatebutton.setTitle("Ending...", for: .disabled)
            
        } else {
            
            try! StartRecording()
            dictatebutton.setTitle("Stop Recording", for: [])
            
        }
    }



}
