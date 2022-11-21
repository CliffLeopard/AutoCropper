//
//  MLView.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/11/18.
//

import SwiftUI

struct MLView: View {
    var body: some View {
        VStack {
            Button("LoadKNN"){
                Task {
                    ModelLoader
                        .predictKnn()
                }
            }
            
            Button("LoadTri"){
                Task {
                    ModelLoader.predictTric()
                }
            }
        }
    }
}

struct MLView_Previews: PreviewProvider {
    static var previews: some View {
        MLView()
    }
}
