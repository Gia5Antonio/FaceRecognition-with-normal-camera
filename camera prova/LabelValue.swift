//
//  sing.swift
//  camera prova
//
//  Created by Hitrost on 03/05/18.
//  Copyright © 2018 Hitrost. All rights reserved.
//


import UIKit

class LabelValue {
    public static var shared = LabelValue()
    
    var eyesDetected = Bool()
    var leftEyePosition = CGPoint()
    var rightEyePosition = CGPoint()
}
