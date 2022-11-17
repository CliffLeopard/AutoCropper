//
//  ShowCropperView.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/11/10.
//

import SwiftUI

struct ShowCaptureView: View {
    @StateObject var phModel:PhotoDataModel
    @State var cgImage:CGImage
    @State var captureImage: Image
    var originImageWidth:CGFloat
    @State var cropRect:SCropRect?
    @State var state:CropState = .originImg
    @State var showCrop = true
    var body: some View {
        VStack {
            captureImage
                .showCroper(self.$cropRect, originImageWidth: self.originImageWidth,showCrop: self.$showCrop)
            
            if let lable = state.label() {
                Spacer()
                HStack{
                    Spacer()
                    Button {
                        self.onNext()
                    } label: {
                        Text(lable)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                            .padding(.horizontal,8)
                            .padding(.vertical,4)
                            .background(Color.purple)
                            .cornerRadius(4)
                    }
                }
                Spacer()
            }
        }
        .navigationTitle("CaptureImage")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear{
            DispatchQueue.global().async {
                let rect = LensCropper.detectEdges(cgImg: cgImage)
                Task{@MainActor in
                    if let notNilRect = rect {
                        self.cropRect = notNilRect
                    } else {
                        self.cropRect = SCropRect(width: CGFloat(cgImage.width), heiht: CGFloat(cgImage.height))
                    }
                }
            }
        }
    }
    
    func onNext() {
        switch self.state {
        case .originImg:
            Task {
                if let cropRect = self.cropRect {
                    let cropedCGImg = TFCropper.crop(cgImg: self.cgImage, rect: cropRect)
                    Task{@MainActor in
                        self.showCrop = false
                        self.cgImage = cropedCGImg
                        self.captureImage = Image(uiImage: UIImage(cgImage: cropedCGImg))
                        self.state = self.state.next()
                    }
                }
            }
        case .cropRect:
            Task {
                if let data = self.cgImage.png {
                    await phModel.savePhoto(imageData: data)
                    Task{@MainActor in
                        self.state = self.state.next()
                    }
                }
            }
            self.showCrop = false
        case .cropImage:
            self.showCrop = false
        case .savedImage:
            self.showCrop = false
        }
    }
}
enum CropState {
    case originImg
    case cropRect
    case cropImage
    case savedImage
    
    func next() -> CropState {
        switch self {
        case .originImg:
            return .cropRect
        case .cropRect:
            return .cropImage
        case .cropImage:
            return .savedImage
        case .savedImage:
            return .originImg
        }
    }
    
    func label() -> String? {
        switch self {
        case .originImg:
            return "裁剪"
        case .cropRect:
            return "存储"
        case .cropImage:
            return "完成"
        case .savedImage:
            return nil
        }
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}


