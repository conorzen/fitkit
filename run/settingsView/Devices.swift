//
//  Devices.swift
//  run
//
//  Created by Conor Reid Admin on 09/02/2025.
//

import SwiftUI
import CoreBluetooth
import WatchConnectivity

struct Devices: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var showPairingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            // Apple Watch Section
            Section(header: Text("Apple Watch")) {
                HStack {
                    Image(systemName: "applewatch")
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Apple Watch")
                        if WCSession.isSupported() {
                            Text("Connected")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("No Watch Connected")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    Spacer()
                }
            }
            
            // Heart Rate Monitors Section
            Section(header: Text("Heart Rate Monitors")) {
                // Polar H10
                HStack {
                    Image(systemName: "heart.circle")
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Polar H10")
                        Text(bluetoothManager.connectedDevice?.peripheral.name ?? "Not Connected")
                            .font(.caption)
                            .foregroundColor(bluetoothManager.connectedDevice != nil ? .green : .red)
                    }
                    Spacer()
                    if bluetoothManager.connectedDevice == nil {
                        Button(bluetoothManager.isScanning ? "Scanning..." : "Connect") {
                            bluetoothManager.startScanning()
                        }
                        .disabled(bluetoothManager.isScanning)
                    } else {
                        Button("Disconnect") {
                            bluetoothManager.disconnect()
                        }
                    }
                }
                
                // Available Devices
                if bluetoothManager.isScanning {
                    ForEach(bluetoothManager.discoveredDevices) { device in
                        Button {
                            bluetoothManager.connect(to: device)
                        } label: {
                            HStack {
                                Text(device.peripheral.name ?? "Unknown Device")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Devices")
        .alert("Bluetooth Error", isPresented: $showPairingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            bluetoothManager.onError = { error in
                alertMessage = error
                showPairingAlert = true
            }
        }
    }
}

// MARK: - Bluetooth Manager
class BluetoothManager: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var discoveredDevices: [IdentifiablePeripheral] = []
    @Published var connectedDevice: IdentifiablePeripheral?
    
    private var centralManager: CBCentralManager!
    var onError: ((String) -> Void)?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            DispatchQueue.main.async {
                self.onError?("Bluetooth is not available")
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isScanning = true
            self.discoveredDevices.removeAll()
        }
        
        // Look for Polar H10 specifically
        centralManager.scanForPeripherals(withServices: [CBUUID(string: "180D")]) // Heart Rate Service UUID
    }
    
    func connect(to device: IdentifiablePeripheral) {
        centralManager.connect(device.peripheral, options: nil)
    }
    
    func disconnect() {
        if let device = connectedDevice {
            centralManager.cancelPeripheralConnection(device.peripheral)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            DispatchQueue.main.async {
                self.onError?("Bluetooth is not available")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let identifiablePeripheral = IdentifiablePeripheral(peripheral)
        DispatchQueue.main.async {
            if !self.discoveredDevices.contains(where: { $0.id == identifiablePeripheral.id }) {
                self.discoveredDevices.append(identifiablePeripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.connectedDevice = IdentifiablePeripheral(peripheral)
            self.isScanning = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.connectedDevice = nil
        }
    }
}

// MARK: - Helper Types
struct IdentifiablePeripheral: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    
    init(_ peripheral: CBPeripheral) {
        self.id = peripheral.identifier
        self.peripheral = peripheral
    }
}

#Preview {
    NavigationView {
        Devices()
    }
}
