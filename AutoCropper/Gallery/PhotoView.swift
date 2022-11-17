//
//  PhotoView.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/19.
//

import SwiftUI
import Photos
struct PhotoView: View {
    var asset: PhotoAsset
    var cache: CachedImageManager?
    @State private var image: Image?
    @State private var originImage:UIImage?
    @State private var cropRect:SCropRect?
    @State private var showCropRect:SCropRect?
    @State private var imageRequestID: PHImageRequestID?
    private let imageSize = CGSize(width: 1024, height: 1024)
    
    @State var originImageWidth: CGFloat? = nil
    @State var rotation:Double = 0.0
    @State var showCrop = true
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        return VStack(spacing:0){
            if let image = self.image {
                image
                    .showCroper(self.$cropRect,originImageWidth:self.originImageWidth,showCrop: self.$showCrop)
                    .accessibilityLabel(asset.accessibilityLabel)
                    .rotationEffect(Angle(degrees: self.rotation))
            }
            Spacer()
        }
        .background(Color.secondary)
        .navigationTitle("Photo")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            VStack(spacing:0) {
                buttonsView()
            }
        }
        .like_task {
            await showOriginImg()
        }
    }
    
    private func buttonsView() -> some View {
        VStack(spacing:0){
            HStack(spacing:10) {
                // 展示Lens处理结果
                Button {
                    Task {
                        await showLensResult()
                    }
                } label: {
                    Label("lens", systemImage: "photo")
                }.labelStyle(VStackLabelStyle())
                
                // 展示Lens处理边框
                Button {
                    Task {
                        await lensShowBorderd()
                    }
                } label: {
                    Label("borde", systemImage: "checkerboard.rectangle")
                }.labelStyle(VStackLabelStyle())
                
                // 展示Lens Croper结果
                Button {
                    Task {
                        await showLensCropperd()
                    }
                } label: {
                    Label("croped", systemImage: "filemenu.and.selection")
                }.labelStyle(VStackLabelStyle())
            }
            .padding(8)
            .frame(width: screenWidth)
            .buttonStyle(.plain)
            .labelStyle(.iconOnly)
            .background(Color.secondary.colorInvert().opacity(0.8))
            
            HStack(spacing: 10) {
                // 展示原始视图
                Button {
                    Task {
                        await showOriginImg()
                    }
                } label: {
                    Label("image", systemImage: "photo.on.rectangle")
                }.labelStyle(VStackLabelStyle())
                
                // 展示TensorFlow处理结果
                Button {
                    Task {
                        await showTensorResult()
                    }
                } label: {
                    Label("tensor", systemImage: "photo")
                }.labelStyle(VStackLabelStyle())
                
                // 展示TensorFlow边框
                Button {
                    Task {
                        await showBorderd()
                    }
                } label: {
                    Label("borde", systemImage: "checkerboard.rectangle")
                }.labelStyle(VStackLabelStyle())
                
                // 展示TensorFlow Croper结果
                Button {
                    Task {
                        await showCropperd()
                    }
                } label: {
                    Label("croped", systemImage: "filemenu.and.selection")
                }.labelStyle(VStackLabelStyle())
                
                Button {
                    self.rotation =  Double((Int(self.rotation) + 90 ) % 360)
                } label: {
                    Label("rotate", systemImage: "rotate.right")
                }.labelStyle(VStackLabelStyle())
                
            }
            .padding(8)
            .frame(width: screenWidth)
            .buttonStyle(.plain)
            .labelStyle(.iconOnly)
            .background(Color.secondary.colorInvert().opacity(0.8))
        }
    }
    
    // 原始视图
    private func showOriginImg() async {
        guard let cache = cache else { return }
        let beginTime = Date().timeIntervalSince1970
        imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
            Task{ @MainActor in
                if let imgResult = result {
                    if imgResult.isLowerQuality {
                        if let uiImg = imgResult.image {
                            self.image = Image(uiImage: uiImg)
                        }
                    } else if let uiImg = imgResult.image {
                        self.originImage = uiImg
                        self.image = Image(uiImage: uiImg)
                        debugPrint("showOriginImg:",Date().timeIntervalSince1970 - beginTime)
                    }
                    self.cropRect = nil
                }
            }
        }
    }
    
    // 展示Lens处理结果
    private func showLensResult() async {
        guard let oImg = self.originImage else { return }
        let beginTime = Date().timeIntervalSince1970
        if let cgImg = oImg.cgImage,let uiImage = LensCropper.showEdges(cgImg: cgImg) {
            Task{@MainActor in
                self.image = Image(uiImage: uiImage)
            }
            debugPrint("LenPredictTime:",Date().timeIntervalSince1970 - beginTime)
        }
    }
    
    // 展示Lens处理边框
    private func lensShowBorderd() async {
        guard let oImg = self.originImage else { return }
        let beginTime = Date().timeIntervalSince1970
        if let cgImg = oImg.cgImage {
            self.originImageWidth = CGFloat(cgImg.width)
            self.cropRect = LensCropper.detectEdges(cgImg: cgImg)
            debugPrint("LensShowBorderdTime:",Date().timeIntervalSince1970 - beginTime)
        }
    }
    
    // 展示Lens裁剪结果
    private func showLensCropperd() async {
        guard let oImg = self.originImage else { return }
        if let cgImg = oImg.cgImage {
            let beginTime = Date().timeIntervalSince1970
            if let crop = getLensCropperRect(cgImg) {
                let resultImg = TFCropper.crop(cgImg: cgImg, rect: crop)
                self.image = Image(uiImage: UIImage(cgImage: resultImg))
                self.cropRect = nil
                debugPrint("showBorderd:",Date().timeIntervalSince1970 - beginTime)
            }
        }
    }
    
    
    
    // TenseorFlow处理结果
    private func showTensorResult() async {
        guard let oImg = self.originImage else { return }
        if let cgImg = oImg.cgImage {
            let beginTime = Date().timeIntervalSince1970
            // 展示Tensor预测结果
            if let resultImg = TFCropper.showEdges(cgImg: cgImg) {
                self.image = Image(uiImage: resultImg)
            } else {
                debugPrint("展示Tensor预测结果 失败")
            }
            debugPrint("showTensorResult:",Date().timeIntervalSince1970 - beginTime)
        }
    }
    
    // 展示边框
    private func showBorderd() async {
        guard let oImg = self.originImage else { return }
        let beginTime = Date().timeIntervalSince1970
        if let cgImg = oImg.cgImage {
            self.originImageWidth = CGFloat(cgImg.width)
            self.cropRect = TFCropper.detectEdges(cgImg: cgImg)
            debugPrint("showBorderd:",Date().timeIntervalSince1970 - beginTime)
            //                将边框绘制进图片中
            //            if let crt = ICropperTFImpl.detectEdges(cgImg: cgImg) {
            //                let resultImg = ICropperTFImpl.drawCropRect(cgImg: cgImg, cropRect: crt)
            //                self.image = Image(uiImage: UIImage(cgImage: resultImg))
            //                debugPrint("showBorderd:",Date().timeIntervalSince1970 - beginTime)
            //            }
        }
    }
    
    // 裁切结果
    private func showCropperd() async {
        guard let oImg = self.originImage else { return }
        if let cgImg = oImg.cgImage {
            let beginTime = Date().timeIntervalSince1970
            if let crop = getCropperRect(cgImg) {
                let resultImg = TFCropper.crop(cgImg: cgImg, rect: crop)
                self.image = Image(uiImage: UIImage(cgImage: resultImg))
                self.cropRect = nil
                debugPrint("showBorderd:",Date().timeIntervalSince1970 - beginTime)
            }
        }
    }
    
    private func getCropperRect(_ cgImg:CGImage) -> SCropRect? {
        return TFCropper.detectEdges(cgImg: cgImg)
    }
    
    private func getLensCropperRect(_ cgImg:CGImage) -> SCropRect? {
        return LensCropper.detectEdges(cgImg: cgImg)
    }
}

struct VStackLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
                .frame(width: 30, height: 20)
            configuration.title
        }
    }
}

//            // 收藏
//            Button {
//                Task {
//                    await asset.setIsFavorite(!asset.isFavorite)
//                }
//            } label: {
//                Label("Favorite", systemImage: asset.isFavorite ? "heart.fill" : "heart")
//                    .font(.system(size: 24))
//            }
//
//            // 删除
//            Button {
//                Task {
//                    await asset.delete()
//                    await MainActor.run {
//                        dismiss()
//                    }
//                }
//            } label: {
//                Label("Delete", systemImage: "trash")
//                    .font(.system(size: 24))
//            }
