//
//  Camera.swift
//  camera prova
//
//  Created by Hitrost on 03/05/18.
//  Copyright © 2018 Hitrost. All rights reserved.
//


import Foundation
import AVFoundation

class Camera {
    var timeCounter: Int = 0
    var hasFound: Bool = false
    
    var leftPosition: CGPoint?
    var rightPosition: CGPoint?
    
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    var photoOutput: AVCapturePhotoOutput?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
}

