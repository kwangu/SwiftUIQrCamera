//
//  QrCameraView.swift
//  SwifUIQrCode
//
//  Created by 강관구 on 2022/04/05.
//

import SwiftUI
import AVFoundation

struct cameraFrame: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height
            
            path.addLines( [
                
                CGPoint(x: 0, y: height * 0.25),
                CGPoint(x: 0, y: 0),
                CGPoint(x:width * 0.25, y:0)
            ])
            
            path.addLines( [
                
                CGPoint(x: width * 0.75, y: 0),
                CGPoint(x: width, y: 0),
                CGPoint(x:width, y:height * 0.25)
            ])
            
            path.addLines( [
                
                CGPoint(x: width, y: height * 0.75),
                CGPoint(x: width, y: height),
                CGPoint(x:width * 0.75, y: height)
            ])
            
            path.addLines( [
                
                CGPoint(x:width * 0.25, y: height),
                CGPoint(x:0, y: height),
                CGPoint(x:0, y:height * 0.75)
               
            ])
            
        }
    }
}

struct QrCameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var codeValue = "test Value"
    @State var torchIsOn = false
    @State var cameraPosition = AVCaptureDevice.Position.back
    
    var body: some View {
        ZStack {
            ScannerView(
                supportBarcode: .constant([.qr]),
                torchLightIsOn: $torchIsOn,
                cameraPosition: $cameraPosition
            ){
                print("BarCodeType =",$0.type.rawValue, "Value =",$0.value)
                codeValue = $0.value
            }
            onDraw: {
                print("Preview View Size = \($0.cameraPreviewView.bounds)")
                print("Barcode Corners = \($0.corners)")
                
                let lineColor = UIColor.green
                let fillColor = UIColor(red: 0, green: 1, blue: 0.2, alpha: 0.4)
                
                //Draw Barcode corner
                $0.draw(lineWidth: 1, lineColor: lineColor, fillColor: fillColor)
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .overlay(cameraFrame()
                .stroke(lineWidth: 10)
                .frame(width: 200, height: 200)
                .foregroundColor(.red))
            
            
            VStack {
                ZStack {
                    Text("QR 코드 스캔")
                        .foregroundColor(Color.white)
                    
                    HStack {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Text("취소")
                                .foregroundColor(Color.red)
                        }).padding()
                        
                        Spacer()
                    }.frame(height: 44)
                }
                .padding(.top, getSafeArea().top)
                .background(Color.init(red: 60 / 255, green: 60 / 255, blue: 67 / 255, opacity: 0.36))
                
                Spacer()
            }
            
        }.edgesIgnoringSafeArea(.all)
    }
}

struct QrCameraView_Previews: PreviewProvider {
    static var previews: some View {
        QrCameraView()
    }
}

extension View {
    func getSafeArea() -> UIEdgeInsets {
        return UIApplication.shared.windows.first?.safeAreaInsets ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
