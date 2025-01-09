//
//  IconCamera.swift
//  MOC
//
//  Created by 김태은 on 1/9/25.
//

import SwiftUI

struct IconCamera: View {
    var body: some View {
        Circle()
            .frame(width: 32, height: 32)
            .foregroundColor(Color("MOCBackground"))
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .inset(by: 0.5)
                    .stroke(Color("MOCLightGray"), lineWidth: 1)
            ).overlay(
                Image("IconCamera")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15)
            )
    }
}
