// BLEManager.swift
import Foundation
import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @Published var connectionState = "Disconnected"
    @Published var isConnected = false
    
    var centralManager: CBCentralManager!
    var esp32Peripheral: CBPeripheral?
    private var connectionTimeoutTimer: Timer?
    
    // BLE UUIDs
    let serviceUUID = CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")
    let driveCharUUID = CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214")
    let speedCharUUID = CBUUID(string: "19B10002-E8F2-537E-4F6C-D104768A1214")
    let headlightCharUUID = CBUUID(string: "19B10003-E8F2-537E-4F6C-D104768A1214")
    
    var driveChar: CBCharacteristic?
    var speedChar: CBCharacteristic?
    var headlightChar: CBCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Scanning
    func startScan() {
        if centralManager.state == .poweredOn {
            connectionState = "Scanning for LegoCar..."
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ])
        } else {
            connectionState = "Bluetooth is OFF"
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScan()
        } else {
            connectionState = "Bluetooth is OFF"
            isConnected = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Prevent connection spam
        guard esp32Peripheral?.state != .connecting else { return }
        
        centralManager.stopScan()
        esp32Peripheral = peripheral
        esp32Peripheral?.delegate = self
        
        connectionState = "Connecting..."
        centralManager.connect(peripheral, options: nil)
        
        // Connection timeout
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            guard let self = self, let p = self.esp32Peripheral, p.state != .connected else { return }
            self.centralManager.cancelPeripheralConnection(p)
            self.esp32Peripheral = nil
            self.connectionState = "Timeout. Retrying..."
            self.startScan()
        }
    }
    
    // Connecting
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionTimeoutTimer?.invalidate()
        connectionState = "Connected"
        isConnected = true
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionTimeoutTimer?.invalidate()
        connectionState = "Connection Failed. Retrying..."
        isConnected = false
        esp32Peripheral = nil
        startScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionState = "Disconnected"
        isConnected = false
        esp32Peripheral = nil
        startScan()
    }
    
    // Discovering Services & Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for char in characteristics {
            if char.uuid == driveCharUUID { driveChar = char }
            if char.uuid == speedCharUUID { speedChar = char }
            if char.uuid == headlightCharUUID { headlightChar = char }
        }
    }
    
    // Sending Commands
    func sendDriveCommand(direction: UInt8) {
        guard let peripheral = esp32Peripheral, let char = driveChar else { return }
        let data = Data([direction])
        peripheral.writeValue(data, for: char, type: .withResponse)
    }
    
    func sendSpeedCommand(rpm: UInt8) {
        guard let peripheral = esp32Peripheral, let char = speedChar else { return }
        let data = Data([rpm])
        peripheral.writeValue(data, for: char, type: .withResponse)
    }
    
    func sendHeadlightCommand(isOn: Bool) {
        guard let peripheral = esp32Peripheral, let char = headlightChar else { return }
        let data = Data([isOn ? 1 : 0])
        peripheral.writeValue(data, for: char, type: .withResponse)
    }
}