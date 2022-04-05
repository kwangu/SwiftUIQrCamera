//
//  CodeData.swift
//  QrCodeExample
//
//  Created by 강관구 on 2021/12/07.
//

import AVFoundation
import UIKit


/// Barcode, Qrcode Entity
public struct CodeData {
    
    public let value: String
    // barcode, qrcode ...
    public let type: AVMetadataObject.ObjectType
    
    public init(value: String, type: AVMetadataObject.ObjectType) {
        self.value = value
        self.type = type
    }
}
