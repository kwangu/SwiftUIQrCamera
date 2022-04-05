//
//  ScannerView.swift
//  QrCodeExample
//
//  Created by 강관구 on 2021/12/07.
//

import SwiftUI
import AVFoundation

public struct ScannerView: UIViewRepresentable {
    
    
    public typealias OnFound = (CodeData) -> Void
    public typealias OnDraw = (CodeFrame) -> Void
    
    public typealias UIViewType = CameraPreview
    
    @Binding
    public var supportBarcode: [AVMetadataObject.ObjectType]
    
    @Binding
    public var torchLightIsOn:Bool
    
    @Binding
    public var scanInterval: Double
    
    @Binding
    public var cameraPosition:AVCaptureDevice.Position
    
    public var onFound: OnFound?
    public var onDraw: OnDraw?
    
    public init(supportBarcode:Binding<[AVMetadataObject.ObjectType]> ,
         torchLightIsOn: Binding<Bool> = .constant(false),
         scanInterval: Binding<Double> = .constant(3.0),
         cameraPosition: Binding<AVCaptureDevice.Position> = .constant(.back),
         onFound: @escaping OnFound,
         onDraw: OnDraw? = nil
    ) {
        _torchLightIsOn = torchLightIsOn
        _supportBarcode = supportBarcode
        _scanInterval = scanInterval
        _cameraPosition = cameraPosition
        self.onFound = onFound
        self.onDraw = onDraw
    }
    
    public func makeUIView(context: UIViewRepresentableContext<ScannerView>) -> CameraPreview {
        let view = CameraPreview()
        view.scanInterval = scanInterval
        view.supportBarcode = supportBarcode
        view.setupScanner()
        view.onFound = onFound
        view.onDraw = onDraw
        return view
    }
    
    public static func dismantleUIView(_ uiView: CameraPreview, coordinator: ()) {
        uiView.session?.stopRunning()
    }
    
    public func updateUIView(_ uiView: CameraPreview, context: UIViewRepresentableContext<ScannerView>) {
        uiView.setTorchLight(isOn: torchLightIsOn)
        uiView.setCamera(position: cameraPosition)
        uiView.scanInterval = scanInterval
        uiView.setSupportedBarcode(supportBarcode: supportBarcode)
        
        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        if !(uiView.session?.isRunning ?? false) {
            uiView.session?.startRunning()
        }
        uiView.updateCameraView()
    }
}
