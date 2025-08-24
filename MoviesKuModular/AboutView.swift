//
//  AboutView.swift
//  MoviesKuModular
//
//  Created by zeekands on 24/08/25.
//


import SwiftUI

struct AboutView: View {
  var body: some View {
    VStack(spacing: 16) {
      Spacer()
      Image("about")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 150, height: 150)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
      
      Text("Aziz Kandias")
        .font(.title)
        .fontWeight(.bold)
      
      Spacer()
      

      Text("App Version: 1.0.0")
        .font(.footnote)
        .foregroundColor(.secondary)
    }
    .padding()
    .navigationTitle("About")
  }
}
