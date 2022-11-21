//
//  ModelLoader.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/11/18.
//

import Foundation
import CoreML

class ModelLoader {
    private static let modelFileExtension = "mlmodelc"
    private static let knnModelName = "KNN"
    private static let triModelName = "TriClassification"
    
    public static func predictKnn() {
        if let model = loadModel(modelFileName: knnModelName) {
            do {
                let modelDescription = model.modelDescription
                let desc = modelDescription.inputDescriptionsByName
                debugPrint("modelDescription",desc)
//                let imageInputDescription = description.inputDescriptionsByName["image"]!
//                let imageConstraint = imageInputDescription.imageConstraint!
                
                let outProvider = try model.prediction(from: KNNInputProvider())
                debugPrint("outProvider featureNames",outProvider.featureNames)
                let label = outProvider.featureValue(for: "label")
                let labelProbability = outProvider.featureValue(for: "labelProbability")
                let nearestLabels = outProvider.featureValue(for: "_debugNearestLabels")
                let nearestDistances = outProvider.featureValue(for: "_debugNearestDistances")
                debugPrint("label",label.debugDescription)
                debugPrint("labelProbability",labelProbability.debugDescription)
                debugPrint("nearestLabels",nearestLabels.debugDescription)
                debugPrint("nearestDistances",nearestDistances.debugDescription)
                
//                label?.stringValue
//                labelProbability?.dictionaryValue
//                nearestLabels?.sequenceValue
//                nearestDistances?.sequenceValue
            } catch {
                debugPrint("predic error", error.localizedDescription)
            }
        }
    }
    
    public static func predictTric() {
        if let model = loadModel(modelFileName: triModelName) {
            if let outProvider = try? model.prediction(from: TriInputProvider()) {
                debugPrint(outProvider.featureNames)
            } else {
                debugPrint("predic error")
            }
        }
    }
    
    private static func loadModel(modelFileName:String) -> MLModel? {
        guard let modelPath = Bundle.main.path(
            forResource: modelFileName,
            ofType: modelFileExtension) else {
            debugPrint("model not exit")
            return nil
        }
        let compile_url = URL(fileURLWithPath: modelPath)
        let config = MLModelConfiguration()
        do {
            let model =  try MLModel(contentsOf: compile_url,configuration: config)
            return model
        } catch {
            debugPrint("error",error.localizedDescription)
        }
        return nil
    }
}

class KNNInputProvider : MLFeatureProvider {
    var featureNames: Set<String> = ["features"]
    func featureValue(for featureName: String) -> MLFeatureValue? {
        debugPrint("featureName",featureName)
        if featureName == "features"{
            do {
//                let featureValue = try MLFeatureValue(cgImage: self.cgImage, constraint: self.constraint)
                let features:MLMultiArray =  try MLMultiArray(shape: [2048], dataType: MLMultiArrayDataType.float32)
                let featureValue =  MLFeatureValue(multiArray: features)
                return featureValue
            } catch {
                debugPrint("build featureValue error",error.localizedDescription)
            }
        } else {
            debugPrint("not expected featureName",featureName)
        }
        return nil
    }
}

class TriInputProvider:MLFeatureProvider {
    var featureNames: Set<String> = []
    func featureValue(for featureName: String) -> MLFeatureValue? {
        debugPrint("featureName",featureName)
        return nil
    }
}
