//
//  PhotoItemView.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/19.
//

import SwiftUI
import Photos

struct PhotoItemView: View {
    var asset: PhotoAsset
    var cache: CachedImageManager?
    var imageSize: CGSize
    
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?

    var body: some View {
        
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .like_task {
            guard image == nil, let cache = cache else { return }
            imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
                Task {
                    if let result = result,let  uiImage = result.image  {
                        self.image = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
}
