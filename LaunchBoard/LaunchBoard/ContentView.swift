//
//  ContentView.swift
//  LaunchBoard
//
//  Created by Rachit Sharma on 13/06/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppListViewModel()
    
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 7)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 30) {
                ForEach(viewModel.apps) { app in
                    VStack {
                        Image(nsImage: app.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                        
                        Text(app.name)
                            .foregroundColor(.white)
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .shadow(radius: 2)
                    }
                    .onTapGesture {
                        print("🚀 Launching \(app.name)...")
                        
                        NSWorkspace.shared.open(app.url)
                        
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Color.black.opacity(0.2)
                Rectangle().fill(.ultraThinMaterial)
            }
        )
        .ignoresSafeArea()
        .onAppear {
            viewModel.fetchInstalledApps()
        }
    }
}
