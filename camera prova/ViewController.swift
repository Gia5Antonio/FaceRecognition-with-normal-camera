//
//  ViewController.swift
//  camera prova
//
//  Created by Hitrost on 03/05/18.
//  Copyright © 2018 Hitrost. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var previewView: UIView!
    
    var sensors = SensorsModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startCamera()
        
        //no sleep while is in execution
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func startCamera() {
        setupCaptureSession()
        setupDevice()
        
        //Only because we are used it on simulator
        if let camera = sensors.camera.currentCamera {
            setupInputOutput()
            saveBuffer()
            setupPreviewLayer()
            startRunningCaptureSession()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //restore sleep while is in execution
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func setupCaptureSession(){
        sensors.camera.captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                sensors.camera.backCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                sensors.camera.frontCamera = device
            }
        }
        sensors.camera.currentCamera = sensors.camera.frontCamera
    }
    
    //AVCaptureDeviceInput(device: AVCaptureDevice) è throws quindi prima di chiamare la funzione serve il try. Try deve essere all'interno di un blocco do {} catch {} che esegue l'azione a meno che non venga trovata un'eccezione
    func setupInputOutput(){
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: sensors.camera.currentCamera!)
            sensors.camera.captureSession.addInput(captureDeviceInput)
            
            //non necessario:
            sensors.camera.photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
        } catch {
            print(error)
        }
    }
    
    func setupPreviewLayer(){
        sensors.camera.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: sensors.camera.captureSession)
        sensors.camera.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        sensors.camera.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        //default
        sensors.camera.cameraPreviewLayer?.frame = CGRect(x: 0, y: 0, width: self.previewView.frame.width, height: self.previewView.frame.height)
        
        //se commentata non mostra l'anteprima
//        self.previewView.layer.insertSublayer(cameraPreviewLayer!, at: 0)
    }

    func startRunningCaptureSession() {
        sensors.camera.captureSession.startRunning()
    }
    
    func saveBuffer(){
        let sampleBufferQueue = DispatchQueue.global(qos: .userInteractive)
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        sensors.camera.captureSession.addOutput(output)
    }
    
    //func gestita dal delegate, non posso fare l'update della UI qui dentro
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let image = CIImage(cvImageBuffer: imageBuffer)
        
        sensors.camera.hasFound = hasDetected(image: image)
        
        update(hasToUpdate: sensors.camera.hasFound)
    }
    
    func update(hasToUpdate: Bool) {
        DispatchQueue.main.async {
            self.sensors.camera.timeCounter += 1
//            self.myLabel.text = "updated times: \(self.timeCounter)\nhas found: \(self.hasFound)"
            
            if(hasToUpdate == true){
                self.myLabel.backgroundColor = UIColor.red
                if let leftEye = self.sensors.camera.leftPosition, let rightEye = self.sensors.camera.rightPosition {
                    LabelValue.shared.eyesDetected = true
                    LabelValue.shared.leftEyePosition = leftEye
                    LabelValue.shared.rightEyePosition = rightEye
                    self.myLabel.text = "left position: \(leftEye)\nright position: \(rightEye)"
//                    debugPrint("\(LabelValue.shared.eyesDetected), \(LabelValue.shared.leftEyePosition), \(LabelValue.shared.rightEyePosition)")
                }
            } else {
                self.myLabel.backgroundColor = UIColor.blue
                LabelValue.shared.eyesDetected = false
                LabelValue.shared.leftEyePosition = CGPoint(x: -1, y: -1)
                LabelValue.shared.rightEyePosition = CGPoint(x: -1, y: -1)
                self.myLabel.text = "No eyes detected"
//                debugPrint("\(LabelValue.shared.eyesDetected), \(LabelValue.shared.leftEyePosition), \(LabelValue.shared.rightEyePosition)")
            }
        }
    }
    
    func hasDetected(image: CIImage) -> Bool{
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])
        
        let options: [String : Any] = [CIDetectorImageOrientation: exifOrientation(orientation: UIDevice.current.orientation),
                                       CIDetectorSmile: true,
                                       CIDetectorEyeBlink: true]
        
        let faces = faceDetector?.features(in: image, options: options)
        
        if let face = faces?.first as? CIFaceFeature {
//            print("Found face at \(face.bounds)")
            
            if face.hasLeftEyePosition {
//                print("Found left eye at \(face.leftEyePosition)")
            }
            
            if face.hasRightEyePosition {
//                print("Found right eye at \(face.rightEyePosition)")
            }
            
            if face.hasMouthPosition {
//                print("Found mouth at \(face.mouthPosition)")
            }
//            print("right closed: \(face.leftEyeClosed)")
//            print("left closed: \(face.rightEyeClosed)")
            
            sensors.camera.leftPosition = face.leftEyePosition
            sensors.camera.rightPosition = face.rightEyePosition
            
            return true
        } else {
            return false
        }
    }
    
    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
        switch orientation {
        case .portraitUpsideDown:
            return 8
        case .landscapeLeft:
            return 3
        case .landscapeRight:
            return 1
        default:
            return 6 //portrait
        }
    }
}
