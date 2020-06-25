//
//  ViewController.swift
//  ReadMove
//
//  Created by Aneena on 25/06/20.
//  Copyright © 2020 Aneena. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var delayTextField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var readingData: UILabel!
    var timer: Timer!
    @IBOutlet weak var gyroSwitch: UISwitch!
    @IBOutlet weak var acceleroSwitch: UISwitch!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
   
    let motionManager = CMMotionManager()
    var accelerometerDataArray = [[String:Any]]()
    var accelerometerDataDic = [String:Any]()
    var accelerometerDataCollection = [String:[[String:Any]]]()

    var gyroDataArray = [[String:Any]]()
    var gyroDataDic = [String:Any]()
    var gyroDataDataCollection = [String:[[String:Any]]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.indicator.stopAnimating()

        // Do any additional setup after loading the view.
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        motionManager.startMagnetometerUpdates()
        motionManager.startDeviceMotionUpdates()
        self.startButton.setTitle("START", for: .normal)
        self.startButton.setTitleColor(UIColor.green, for: .normal)
        self.startButton.layer.borderColor = UIColor.green.cgColor
        self.startButton.layer.borderWidth = 1
        self.startButton.layer.cornerRadius = self.startButton.frame.height / 2
        self.delayTextField.delegate = self
       

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("n je cjecjr")
        
    }
   
  
    @IBAction func startAction(_ sender: Any) {
        if acceleroSwitch.isOn || gyroSwitch.isOn{
            if  self.startButton.titleLabel?.text == "STOP"{
                self.stopAction()
            }else{
                if self.motionManager.isAccelerometerAvailable {
                    timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
                    self.startButton.setTitle("STOP", for: .normal)
                    self.startButton.setTitleColor(UIColor.red, for: .normal)
                    self.delayTextField.isUserInteractionEnabled = false
                    self.startButton.layer.borderWidth = 1
                    self.startButton.layer.borderColor = UIColor.red.cgColor
                }
                else{
                    let alert = UIAlertController(title: "Accelerometer", message: "Accelerometer hardware is not available", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }else{
            let alert = UIAlertController(title: "", message: "Please switch on any of the options and start again", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
       
    }
    
    @objc func update(){
        
        
        if acceleroSwitch.isOn{
            self.getAcceleroData()
        }
        
        if gyroSwitch.isOn{
            self.getGyroData()
        }
       
    }
    
    func getAcceleroData(){
        if let accelerometerData = motionManager.accelerometerData {
            print("accelerometerData:",accelerometerData)
            let x = accelerometerData.acceleration.x
            let y = accelerometerData.acceleration.y
            let z = accelerometerData.acceleration.z
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .full
            let formattedString = formatter.string(from: TimeInterval(accelerometerData.timestamp))!
        
            self.accelerometerDataDic = ["x":x,"y":y,"z":z,"time":formattedString]
            self.accelerometerDataArray.append(accelerometerDataDic)
            self.accelerometerDataCollection = ["accelerometerData":self.accelerometerDataArray]
            print("accelerometerDataCollection:",self.accelerometerDataCollection)
        }
    }
    
    func getGyroData(){
        if let gyroData = motionManager.gyroData {
            print("gyroData:",gyroData)
            let x = gyroData.rotationRate.x
            let y = gyroData.rotationRate.y
            let z = gyroData.rotationRate.z
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .full
            let formattedString = formatter.string(from: TimeInterval(gyroData.timestamp))!
            
            self.gyroDataDic = ["x":x,"y":y,"z":z,"time":formattedString]
            self.gyroDataArray.append(gyroDataDic)
            self.gyroDataDataCollection = ["gyroData":self.gyroDataArray]
            print("gyroDataDataCollection:",self.gyroDataDataCollection)
        }
    }
   func stopAction(){
        self.startButton.setTitle("START", for: .normal)
        self.startButton.layer.borderColor = UIColor.green.cgColor
        self.startButton.layer.borderWidth = 1
        self.delayTextField.isUserInteractionEnabled = true

        self.startButton.setTitleColor(UIColor.green, for: .normal)

        timer?.invalidate()
        timer = nil
        // Prepare URL
        let url = URL(string: "https://us-central1-eldercare-6ef4f.cloudfunctions.net/saveiPhoneReadings")
        guard let requestUrl = url else { fatalError() }
        // Prepare URL Request Object
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
         
        // HTTP Request Parameters which will be sent in HTTP Request Body
        let postString = "accelerometerData=\( self.accelerometerDataArray)&gyroData=\(self.gyroDataArray)&isGyroEnabled=\(self.gyroSwitch.isOn)&isAccelEnabled=\(self.acceleroSwitch.isOn)&delay=200";
        // Set HTTP Request Body
        print("POSTDATA:",postString)
        request.httpBody = postString.data(using: String.Encoding.utf8);
        // Perform HTTP Request
        self.indicator.startAnimating()
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                // Check for Error
                if let error = error {
                    print("Error took place \(error)")
                    self.indicator.stopAnimating()
                    return
                }
         
                // Convert HTTP Response Data to a String
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("Response data string:\n \(dataString)")
                    DispatchQueue.main.async {
                        self.indicator.stopAnimating()
                        let alert = UIAlertController(title: "", message: "Added the readings", preferredStyle: UIAlertController.Style.alert)
                      alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                      self.present(alert, animated: true, completion: nil)
                    }

                }
        }
        task.resume()
        self.accelerometerDataArray.removeAll()
        self.accelerometerDataDic.removeAll()
        self.gyroDataArray.removeAll()
        self.gyroDataDic.removeAll()

    }
  
}

