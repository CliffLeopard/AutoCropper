//
//  CIImage++.swift
//  ScanPro
//
//  Created by CliffLeopard on 2022/10/17.
//

import Foundation
import SwiftUI

extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
    
    var asCgImage:CGImage? {
        if self.cgImage == nil {
            return CIContext(options: nil).createCGImage(self, from: self.extent)
        } else {
            return self.cgImage
        }
    }
    
    var asUIImage:UIImage? {
        if let cgImgage = self.asCgImage {
            return UIImage(cgImage: cgImgage)
        } else {
            return nil
        }
    }
    
    var png:Data? {
        return CIContext().jpegRepresentation(of: self, colorSpace: CGColorSpaceCreateDeviceRGB())
    }
    
    // 预览图使用
    func cropByRate(sizeRate:CGFloat) -> CIImage {
        let size = self.extent.size
        if(size.height > size.width * sizeRate) {
            return self.cropped(to: CGRectMake(0, 0, size.width, size.width * sizeRate))
        } else if (size.height < size.width * sizeRate) {
            return self.cropped(to: CGRectMake(0, 0, size.height/sizeRate, size.height))
        } else {
            return self
        }
    }
    
    // 拍照存储图使用 正常的width/height 永远大于0
    func cropByRateAndOrientation(sizeRate:CGFloat, orientation:CGImagePropertyOrientation) -> CIImage {
        let size = self.extent.size
        if orientation == .up {
            if size.width == size.height * sizeRate {
                return self
            } else  if size.width > size.height * sizeRate {
                return self.cropped(to: CGRectMake(size.width - size.width*sizeRate,0, size.width,size.height))
            } else {
                return self.cropped(to: CGRectMake(0, 0, size.width ,size.width / sizeRate ))
            }
        }
        
        if orientation == .down {
            if size.width == size.height * sizeRate {
                return self
            } else if size.width > size.height * sizeRate {
                return self.cropped(to: CGRectMake(0,0, size.height * sizeRate ,size.height))
            } else {
                return self.cropped(to: CGRectMake(0,0, size.width,size.width / sizeRate))
            }
        }
        
        if orientation == .left {
            if size.height == size.width * sizeRate {
                return self
            } else if size.height > size.width * sizeRate {
                return self.cropped(to: CGRectMake(0, size.height - size.width * sizeRate, size.width, size.height))
            } else {
                return self.cropped(to: CGRectMake(size.width - size.height/sizeRate,0, size.width,size.height))
            }
        }
        
        if orientation == .right {
            if size.height == size.width * sizeRate {
                return self
            } else if size.height > size.width * sizeRate {
                return self.cropped(to: CGRectMake(0, 0, size.width, size.width * sizeRate))
            } else {
                return self.cropped(to: CGRectMake(0, 0, size.height/sizeRate, size.height))
            }
        }
        return cropByRate(sizeRate: sizeRate)
    }
}

extension Image {
    var cgImage: CGImage? {
        let uiImage = self.asUIImage()
        return uiImage.cgImage
    }
}

extension CGImage {
    var png: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
    
    var frameRect:SCropRect {
        let topLeft = CGPointMake(0, 0)
        let topRight = CGPointMake(CGFloat(self.width), 0)
        let bottomLeft = CGPointMake(0, CGFloat(self.height))
        let bottomRight = CGPointMake(CGFloat(self.width), CGFloat(self.height))
        return SCropRect(topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight)
    }
}

extension UIImage {
    var frameRect:SCropRect {
        let topLeft = CGPointMake(0, 0)
        let topRight = CGPointMake(CGFloat(self.size.width), 0)
        let bottomLeft = CGPointMake(0, CGFloat(self.size.height))
        let bottomRight = CGPointMake(CGFloat(self.size.width), CGFloat(self.size.height))
        return SCropRect(topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight)
        
    }
}
