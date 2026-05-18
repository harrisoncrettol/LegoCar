// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject var bleManager = BLEManager()
    
    // UI State
    @State private var rpmSpeed: Double = 10.0
    @State private var headlightsOn: Bool = false
    
    var body: some View {
        HStack {
            // Drive Controls
            VStack(spacing: 40) {
                Text(bleManager.connectionState)
                    .font(.headline)
                    .foregroundColor(bleManager.isConnected ? .green : .orange)
                
                // Forward Button
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(bleManager.isConnected ? .blue : .gray)
                    .opacity(bleManager.isConnected ? 1.0 : 0.5)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if bleManager.isConnected { bleManager.sendDriveCommand(direction: 1) }
                            }
                            .onEnded { _ in
                                if bleManager.isConnected { bleManager.sendDriveCommand(direction: 0) }
                            }
                    )
                
                // Backward Button
                Image(systemName: "arrow.down.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(bleManager.isConnected ? .blue : .gray)
                    .opacity(bleManager.isConnected ? 1.0 : 0.5)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if bleManager.isConnected { bleManager.sendDriveCommand(direction: 2) }
                            }
                            .onEnded { _ in
                                if bleManager.isConnected { bleManager.sendDriveCommand(direction: 0) }
                            }
                    )
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // Settings
            VStack(spacing: 50) {
                Text("Car Settings")
                    .font(.largeTitle)
                    .bold()
                
                // Headlight Toggle
                Toggle(isOn: $headlightsOn) {
                    Text("Headlights")
                        .font(.title2)
                }
                .onChange(of: headlightsOn) { newValue in
                    bleManager.sendHeadlightCommand(isOn: newValue)
                }
                .frame(width: 200)
                .disabled(!bleManager.isConnected)
                
                // Speed Slider
                VStack {
                    Text("Speed: \(Int(rpmSpeed)) RPM")
                        .font(.title2)
                    
                    Slider(value: $rpmSpeed, in: 5...15, step: 1) { editing in
                        if !editing {
                            bleManager.sendSpeedCommand(rpm: UInt8(rpmSpeed))
                        }
                    }
                    .frame(width: 250)
                    .disabled(!bleManager.isConnected)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}