//
//  CameraView.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/19.
//

import SwiftUI

struct ScanView: View {
    @StateObject private var model = CameraDataModel()
    private let pixels = PhotoPreset.getList()
    @State private var selection: PhotoPreset = .SUPER
    
    var body: some View {
        NavigationView {
            VStack {
                if self.model.showCapture,
                   let photoData = model.photoData,
                   let captureImg = photoData.captureImg.image,
                   let cgImg = photoData.captureImg.asCgImage,
                   let originImageWidth = photoData.imageSize.width {
                    NavigationLink(
                        destination: ShowCaptureView(phModel:self.model.photoModel,cgImage: cgImg, captureImage: captureImg, originImageWidth: CGFloat(originImageWidth)),
                        isActive: self.$model.showCapture) {
                            EmptyView()
                        }
                }
                ScanHeaderView(showFlash: $model.showFlash,
                               showPixelSelector: $model.showPixelSelector,
                               showCrop: $model.showCrop,
                               showHelpLine: $model.showHelpLine)
                
                
                CameraPreview(image:  $model.previewImage,
                              showCrop: $model.showCrop,
                              showHelpLine: $model.showHelpLine,
                              cropRect: $model.cropRect,
                              camera: model.camera)
                .overlay(alignment: .center, content: {
                    if self.model.showLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                            .scaleEffect(3)
                    }
                })
                .onAppear {
                    self.model.camera.isPreviewPaused = false
                }
                .onDisappear {
                    self.model.camera.isPreviewPaused = true
                }
                .overlay(alignment: .top, content: {
                    if(self.model.showPixelSelector) {
                        Picker("Select Room Type", selection: self.$selection) {
                            ForEach(pixels, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .background(Color.black)
                        .padding(.top, -2)
                        .pickerStyle(.segmented)
                    }
                })
                .overlay(alignment: .bottom, content: {
                    buttonsView()
                })
                .onChange(of: self.selection, perform: { newValue in
                    debugPrint("PhotoPreset", newValue)
                    model.camera.changePixel(preset: newValue.getPreset())
                })
                
                Spacer()
                
            }
            .allowsHitTesting(!self.model.showLoading)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
            .statusBar(hidden: false)
            .like_task {
                await model.camera.start()
                await model.photoModel.loadPhotos()
                await model.photoModel.loadThumbnail()
            }
            .onDisappear{
                model.camera.isPreviewPaused = true
            }
            .onAppear {
                model.camera.isPreviewPaused = false
            }
        }.navigationViewStyle(.stack)
    }
    
    
    private func buttonsView() -> some View {
        HStack(spacing: 60) {
            Spacer()
            NavigationLink {
                PhotoCollectionView(photoCollection: model.photoModel.photoCollection)
                    .onAppear {
                        model.camera.isPreviewPaused = true
                    }
            } label: {
                Label {
                    Text("Gallery")
                } icon: {
                    ThumbnailView(image: model.photoModel.thumbnailImage)
                }
            }
            
            Button {
                self.model.takePhoto()
            } label: {
                Label {
                    Text("Take Photo")
                } icon: {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 3)
                            .frame(width: 62, height: 62)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                    }
                }
            }
            
            Button {
                model.camera.switchCaptureDevice()
            } label: {
                Label("Switch Camera", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color.white)
            }
            
            Spacer()
            
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .padding()
    }
    
}
