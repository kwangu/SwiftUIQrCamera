//
//  CameraPreview.swift
//  QrCodeExample
//
//  Created by 강관구 on 2021/12/07.
//

import UIKit
import AVFoundation

public class CameraPreview: UIView {
    
    // camera 셋팅
    var cameraInput: AVCaptureDeviceInput?
    var cameraPosition = AVCaptureDevice.Position.back
    var previewLayer: AVCaptureVideoPreviewLayer?
    var session: AVCaptureSession?
    var supportBarcode: [AVMetadataObject.ObjectType]?
    var selectedCamera: AVCaptureDevice?
    var onDraw: ScannerView.OnDraw?
    var onFound: ScannerView.OnFound?
    
    // flash 옵션
    var torchLightIsOn: Bool = false
    
    // 마지막 code 인식용
    var scanInterval: Double = 3.0
    var lastTime = Date(timeIntervalSince1970: 0)
    var lastScannedCode: CodeData?
    
    // code 인식 모양
    var removeFrameTimer: Timer?
    var shapeLayer: CAShapeLayer?
    
    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupScanner() {
        checkCameraAuthorizationStatus()
    }
    
    // 카메라 권한
    private func checkCameraAuthorizationStatus() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraAuthorizationStatus == .authorized {
            setupCamera()
        } else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.sync {
                    if granted {
                        self.setupCamera()
                    }
                }
            }
        }
    }
    
    // 현재는 qr code만 사용할 예정
    func setSupportedBarcode(supportBarcode: [AVMetadataObject.ObjectType]) {
        self.supportBarcode = supportBarcode

        guard let session = session else { return }

        session.beginConfiguration()

        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)

            metadataOutput.metadataObjectTypes = supportBarcode
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        }

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)

            metadataOutput.metadataObjectTypes = supportBarcode
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        }
        session.commitConfiguration()
    }
    
    // 카메라 셋팅
    func setupCamera() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: cameraPosition)

        if let selectedCamera = deviceDiscoverySession.devices.first {
            if let input = try? AVCaptureDeviceInput(device: selectedCamera) {

                let session = AVCaptureSession()
                session.sessionPreset = .hd1280x720

                if session.canAddInput(input) {
                    session.addInput(input)
                    cameraInput = input
                }

                let metadataOutput = AVCaptureMetadataOutput()

                if session.canAddOutput(metadataOutput) {
                    session.addOutput(metadataOutput)

                    metadataOutput.metadataObjectTypes = supportBarcode
                    metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                }

                previewLayer?.removeFromSuperlayer()
                self.session = session
                self.selectedCamera = selectedCamera
                self.backgroundColor = UIColor.gray
                
                DispatchQueue.global().async {
                    Thread.sleep(forTimeInterval: 0.2)
                    session.startRunning()
                    DispatchQueue.main.async {
                        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                        previewLayer.videoGravity = .resizeAspectFill
                        self.layer.addSublayer(previewLayer)
                        
                        self.previewLayer = previewLayer
                    }
                }
                
            }
        }
    }
    
    func setCamera(position: AVCaptureDevice.Position) {

        if cameraPosition == position { return }
        cameraPosition = position

        guard let session = session else { return }

        session.beginConfiguration()
        if let input = cameraInput {
            session.removeInput(input)
            cameraInput = nil
        }

        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: cameraPosition)

        let camera = deviceDiscoverySession.devices.first
        if let selectedCamera = camera {
            if let input = try? AVCaptureDeviceInput(device: selectedCamera) {
                if session.canAddInput(input) {
                    session.addInput(input)
                    cameraInput = input
                }
            }
        }

        session.commitConfiguration()
    }
    
    // light 옵션
    func setTorchLight(isOn: Bool) {
        if torchLightIsOn == isOn { return }

        torchLightIsOn = isOn
        if let camera = selectedCamera {
            if camera.hasTorch {
                try? camera.lockForConfiguration()
                if isOn {
                    camera.torchMode = .on
                } else {
                    camera.torchMode = .off
                }
                camera.unlockForConfiguration()
            }
        }
    }
    
    func getVideoOrientation() -> AVCaptureVideoOrientation {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, windowScene.activationState == .foregroundActive
            else { return .portrait }

        let interfaceOrientation = windowScene.interfaceOrientation

        switch interfaceOrientation {
        case .unknown:
            return .portrait
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        @unknown default:
            return .portrait
        }
    }

    func updateCameraView() {
        previewLayer?.connection?.videoOrientation = getVideoOrientation()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = self.bounds
    }
}

//MARK: Camera Extension
extension CameraPreview {
    
    func convertToViewCoordinate(point: CGPoint) -> CGPoint {
        let orientation = getVideoOrientation()

        var pointX: CGFloat = 0
        var pointY: CGFloat = 0

        switch orientation {
        case .portrait:
            let scale = self.bounds.width / 720
            let previewWidth = 720 * scale
            let previewHeight = 1280 * scale

            let croppedFrameY = previewHeight / 2 - self.bounds.height / 2

            let x = 1.0 - point.y
            let y = point.x

            pointX = x * previewWidth
            pointY = (y * previewHeight) - croppedFrameY
        case .landscapeRight:
            let scale = self.bounds.width / 1280
            let previewWidth = 1280 * scale
            let previewHeight = 720 * scale

            let croppedFrameY = previewHeight / 2 - self.bounds.height / 2

            pointX = point.x * previewWidth
            pointY = (point.y * previewHeight) - croppedFrameY
        case .landscapeLeft:
            let scale = self.bounds.width / 1280
            let previewWidth = 1280 * scale
            let previewHeight = 720 * scale

            let croppedFrameY = previewHeight / 2 - self.bounds.height / 2

            let x = 1.0 - point.x
            let y = 1.0 - point.y

            pointX = x * previewWidth
            pointY = (y * previewHeight) - croppedFrameY
        case .portraitUpsideDown:
            let scale = self.bounds.width / 720
            let previewWidth = 720 * scale
            let previewHeight = 1280 * scale

            let croppedFrameY = previewHeight / 2 - self.bounds.height / 2

            let x = 1.0 - point.y
            let y = point.x

            pointX = x * previewWidth
            pointY = (y * previewHeight) - croppedFrameY
        @unknown default:
            pointX = 0
            pointY = 0
        }

        return CGPoint(x: pointX, y: pointY)
    }
    
    @objc func removeBarcodeFrame() {
        shapeLayer?.removeFromSuperlayer()
    }
    
    func drawFrame(corners: [CGPoint], lineWidth: CGFloat = 1, lineColor: UIColor = UIColor.red, fillColor: UIColor = UIColor.clear) -> Void {

        removeFrameTimer?.invalidate()
        removeFrameTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(removeBarcodeFrame), userInfo: nil, repeats: false)

        if shapeLayer != nil {
            shapeLayer?.removeFromSuperlayer()
        }
        let bezierPath = UIBezierPath()
        var first = true

        corners.forEach {
            if first {
                first = false
                bezierPath.move(to: $0)
            } else {
                bezierPath.addLine(to: $0)
            }
        }

        if corners.count > 0 {
            let pnt = corners[0]
            bezierPath.addLine(to: pnt)
        }

        shapeLayer?.frame = self.bounds
        shapeLayer = CAShapeLayer()
        shapeLayer?.path = bezierPath.cgPath
        shapeLayer?.strokeColor = lineColor.cgColor
        shapeLayer?.fillColor = fillColor.cgColor
        shapeLayer?.lineWidth = lineWidth

        if let shapeLayer = shapeLayer {
            self.layer.addSublayer(shapeLayer)
        }
    }
}


//MARK: QrCode delegate
extension CameraPreview: AVCaptureMetadataOutputObjectsDelegate {

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }

            var corners: [CGPoint] = []
            readableObject.corners.forEach {
                let point = convertToViewCoordinate(point: $0)
                corners.append(point)
            }
            
            // qr 코드의 인식 범위 조정을 이렇게 제한 할수도 있지 않을까?
//            print("width : \(corners[3].x - corners[0].x)")
//            if corners[3].x - corners[0].x < 80 {
//                return
//            }
            
            let frame = CodeFrame(corners: corners, cameraPreviewView: self)
            onDraw?(frame)
            
            if let stringValue = readableObject.stringValue {
                let barcode = CodeData(value: stringValue, type: readableObject.type)
                foundBarcode(barcode)
            }
        }
    }

    func foundBarcode(_ code: CodeData) {
        let now = Date()

        // 마지막 코드값을 저장해두었다가 코드가 다를 경우 인식 하거나
        // 3초가 지난 뒤에는 같은코드라도 다시 인식
        if lastScannedCode?.value != code.value {
            lastTime = now
            onFound?(code)
            lastScannedCode = code
        } else if now.timeIntervalSince(lastTime) >= scanInterval {
            lastTime = now
            onFound?(code)
            lastScannedCode = code
        }
    }
}
