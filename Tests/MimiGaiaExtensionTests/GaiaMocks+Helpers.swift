//
//  Mocks.swift
//  MimiGaiaExtension-iOS
//
//  Created by Hozefa Indorewala on 13.11.25.
//
import GaiaCore
import GaiaBase
import Packets
import PluginBase
import Foundation

/// Mock implementation of GaiaDeviceProtocol for testing
final class MockGaiaDevice: GaiaDeviceProtocol, @unchecked Sendable {
    var version: GaiaBase.GaiaDeviceVersion = .v3
    var deviceType: GaiaBase.GaiaDeviceType = .earbud
    var name: String = "MockDevice"
    var state: GaiaBase.GaiaDeviceState = .gaiaReady
    var connectionKind: ConnectionKind = .ble
    var rssi: Int = -50
    var serialNumber: String = "MOCK123"
    var secondEarbudSerialNumber: String? = nil
    var deviceVariant: String = "MockVariant"
    var applicationVersion: String = "1.0"
    var apiVersion: String = "1.0"
    var isCharging: Bool = false
    var bluetoothAddress: String? = nil
    var supportedFeatures: [GaiaDeviceQCPluginFeatureID] = []
    var equivalentConnectionIDsForReconnection: [String] = []
    var connectionID: String = "mock-connection-id"

    func plugin(featureID: GaiaDeviceQCPluginFeatureID) -> GaiaDevicePluginProtocol? { nil }
    func vendorExtension(vendorID: UInt16) -> GaiaDeviceVendorExtensionProtocol? { nil }
    func reset() {}
    func startConnection() {}
    func connectGaia() {}
}

/// Mock implementation of GaiaDeviceConnectionProtocol for testing
final class MockGaiaConnection: GaiaDeviceConnectionProtocol, @unchecked Sendable {

    // Track sent data for verification
    var sentData: [(channel: GaiaDeviceConnectionChannel, payload: Data, acknowledgementExpected: Bool)] = []

    // Callback to simulate responses
    var responseHandler: (@Sendable (GaiaDeviceConnectionChannel, Data, Bool) -> Void)?

    // GaiaDeviceConnectionProtocol requirements
    weak var delegate: GaiaDeviceConnectionDelegate?
    var connectionKind: ConnectionKind = .ble
    var connectionID: String = "mock-connection"
    var name: String = "MockConnection"
    var connected: Bool = true
    var state: GaiaDeviceConnectionState = .ready
    var rssi: Int = -50
    var isDataLengthExtensionSupported: Bool = true
    var maximumWriteLength: Int = 512
    var maximumWriteWithoutResponseLength: Int = 512
    var optimumWriteLength: Int = 512
    var maxReceivePayloadSizeForGaia: Int = 512
    var maxSendPayloadSizeForGaia: Int = 512

    func start() {}

    func sendData(channel: GaiaDeviceConnectionChannel, payload: Data, acknowledgementExpected: Bool) {
        sentData.append((channel, payload, acknowledgementExpected))
        responseHandler?(channel, payload, acknowledgementExpected)
    }

    func acknowledgementReceived() {}

    func transportParametersReceived(protocolVersion: Int, maxSendSize: Int, optimumSendSize: Int, maxReceiveSize: Int) {}

    func equivalentConnectionIDsForReconnection(btAddresses: [String], serialNumbers: [String]) -> [String] {
        return [connectionID]
    }

    func reset() {
        sentData.removeAll()
        responseHandler = nil
    }
}

extension UInt16 {
    var bigEndianBytes: [UInt8] {
        [UInt8((self >> 8) & 0xFF), UInt8(self & 0xFF)]
    }
}
