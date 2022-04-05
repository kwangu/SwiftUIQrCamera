//
//  CodeFrame.swift
//  QrCodeExample
//
//  Created by 강관구 on 2021/12/07.
//

import UIKit

public struct CodeFrame {
    public let corners: [CGPoint]
    public let cameraPreviewView: UIView
    
    public func draw(lineWidth: CGFloat = 1, lineColor: UIColor = UIColor.red, fillColor: UIColor = UIColor.clear) {
        
        let view = cameraPreviewView as! CameraPreview
        
        view.drawFrame(corners: corners,
            lineWidth: lineWidth,
            lineColor: lineColor,
            fillColor: fillColor)
    }
}
