//
//  PhotoDataModel.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/11/11.
//

import Foundation
import SwiftUI

class PhotoDataModel:ObservableObject {
    @Published var thumbnailImage: Image?          // 相册缩略图
    let photoCollection = PhotoCollection(smartAlbum: .smartAlbumUserLibrary)
    var isPhotosLoaded = false
    
    // 照片存储
    func savePhoto(imageData: Data) async {
        Task {
            do {
                try await photoCollection.addImage(imageData)
                debugPrint("Added image data to photo collection.")
            } catch let error {
                debugPrint("Failed to add image to photo collection: \(error.localizedDescription)")
            }
        }
    }
    
    // 加载相册中的图片
    func loadPhotos() async {
        guard !isPhotosLoaded else { return }
        let authorized = await PermissionCenter.checkAuthorization()
        guard authorized else {
            debugPrint("Photo library access was not authorized.")
            return
        }
        
        Task {
            do {
                try await self.photoCollection.load()
                await self.loadThumbnail()
            } catch let error {
                debugPrint("Failed to load photo collection: \(error.localizedDescription)")
            }
            self.isPhotosLoaded = true
        }
    }
    
    // 加载缩略图
    func loadThumbnail() async {
        guard let asset = photoCollection.photoAssets.first  else { return }
        await photoCollection.cache.requestImage(for: asset, targetSize: CGSize(width: 256, height: 256))  { result in
            if let result = result {
                Task { @MainActor in
                    if let uiImage = result.image {
                        self.thumbnailImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
}
