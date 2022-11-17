//
//  InputImpl.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/11/17.
//

import Foundation
import CoreML
class InputImpl:MLFeatureProvider {
    let cgImage:CGImage
    let constraint:MLImageConstraint
    init(cgImage:CGImage,constraint:MLImageConstraint) {
        self.cgImage = cgImage
        self.constraint = constraint
    }
    var featureNames: Set<String> = ["image"]
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "image"{
            do {
                let featureValue = try MLFeatureValue(cgImage: self.cgImage, constraint: self.constraint)
                return featureValue
            } catch {
                debugPrint("build featureValue error",error.localizedDescription)
            }
        }
        return nil
    }
}
