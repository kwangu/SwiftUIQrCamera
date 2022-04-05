//
//  ContentView.swift
//  SwifUIQrCode
//
//  Created by 강관구 on 2022/04/05.
//

import SwiftUI

struct ContentView: View {
    @State var openQrCamera = false
    
    var body: some View {
        Button(action: {
            openQrCamera.toggle()
        }, label: {
            Text("Open Qrcode View")
        })
        .fullScreenCover(isPresented: $openQrCamera, onDismiss: {

        }, content: {
            QrCameraView()
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
