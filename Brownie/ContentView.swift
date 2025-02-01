//
//  ContentView.swift
//  Brownie
//
//  Created by Gregory Ennis on 2/1/25.
//

import SwiftUI

struct ContentView: View {
    private let brownNoise = BrownNoiseGenerator()

    var body: some View {
        VStack {
            Image(systemName: "waveform")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Brown Noise")
                .font(.caption)
                .foregroundStyle(.tint)
            
            if let errorMessage = brownNoise.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .onAppear {
            brownNoise.start()
        }
        .onDisappear {
            brownNoise.stop()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
