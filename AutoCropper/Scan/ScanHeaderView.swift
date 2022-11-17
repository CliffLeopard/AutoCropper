//
//  ScanHeaderView.swift
//  AutoCropper
//
//  Created by CliffLeopard on 2022/10/30.
//

import SwiftUI

struct ScanHeaderView: View {
    @Binding var showFlash:Bool
    @Binding var showPixelSelector:Bool
    @Binding var showCrop:Bool
    @Binding var showHelpLine:Bool
    
    var body: some View {
        HStack {
            Button {
                debugPrint("pressBack")
            } label: {
                Image(systemName: "chevron.backward")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 10, height: 18, alignment: .center)
                    .padding(.all, 5)
                    .padding(.leading, 10)
            }
            
            Spacer()
            ToggleImage(show: $showFlash, showName: "camera_flash_opened_black", disableName: "camera_flash_closed_black")
                .foregroundColor(Color.white)
            
            Button {
                self.showPixelSelector.toggle()
            } label: {
                Image("camera_hd_black")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20, alignment: .center)
                    .padding(.all, 5)
            }
            
            ToggleImage(show: $showCrop, showName: "camera_clip_opened_black", disableName: "camera_clip_closed")
            ToggleImage(show: $showHelpLine, showName: "grid", disableName: "grid.circle",useSF: true)
        }
        .padding(.trailing,15)
        .padding(.top,15)
        .background(Color.black)
    }
}

struct ToggleImage: View {
    @Binding var show:Bool
    var showName:String
    var disableName:String
    var useSF = false
    var body: some View {
        if show {
            getImage(showName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.white)
                .frame(width: useSF ? 18: 20, height: useSF ? 18:20, alignment: .center)
                .padding(.all, 5)
                .onTapGesture {
                    self.show.toggle()
                }
        } else {
            getImage(disableName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.white)
                .frame(width: useSF ? 18: 20, height: useSF ? 18:20, alignment: .center)
                .padding(.all, 5)
                .onTapGesture {
                    self.show.toggle()
                }
        }
    }
    
    func getImage(_ name:String) -> Image {
        if useSF {
            return Image(systemName: name)
        } else {
            return Image(name)
        }
    }
}
