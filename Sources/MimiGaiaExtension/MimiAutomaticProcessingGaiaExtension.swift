//
//  MimiAutomaticProcessingGaiaExtension.swift
//  GaiaClient
//
//  Created by Hozefa Indorewala on 29.10.25.
//  Copyright © 2025 QTI. All rights reserved.
//

import Foundation
import GaiaCore
import GaiaBase
import Packets
import GaiaLogger

enum MimiGaiaCommand: UInt16 {
    case isMimiDevice = 0
    case protobufRequestMsgChunk = 1
    case protobufRequestMsgEnd = 2
    case protobufResponseMsgChunk = 3
    case protobufResponseMsgEnd = 4
}

public enum MimiGaiaError: Error {
    case emptyData
}

public protocol MimiAutomaticProcessingGaiaExtensionProtocol {

    var gaiaExtension: GaiaDeviceVendorExtensionProtocol { get }

    func isMimiDevice() async throws -> Bool
    func send(_ data: Data) async throws -> Data
}

public class MimiAutomaticProcessingGaiaExtension: MimiAutomaticProcessingGaiaExtensionProtocol {

    private struct Defaults {
        static let vendorID: UInt16 = 0x4AAA
        static let featureID: UInt8 = 0x20
        static let maxChunkSize: Int = 64 // bytes
    }

    public var gaiaExtension: GaiaDeviceVendorExtensionProtocol {
        _gaiaExtension
    }
    let _gaiaExtension: AsyncGaiaV3DeviceVendorExtension

    public required init(device: any GaiaDeviceProtocol,
                         connection: any GaiaDeviceConnectionProtocol,
                         notificationCenter: NotificationCenter) {
        nonisolated(unsafe) let unsafeDevice = device
        nonisolated(unsafe) let unsafeConnection = connection
        self._gaiaExtension = AsyncGaiaV3DeviceVendorExtension(vendorID: Defaults.vendorID, featureID: Defaults.featureID, name: "MimiAutomaticProcessingGaiaExtension", device: unsafeDevice, connection: unsafeConnection, notificationCenter: notificationCenter)
    }

    public func isMimiDevice() async throws -> Bool {
        let data = try await _gaiaExtension.sendCommand(commandID: MimiGaiaCommand.isMimiDevice.rawValue)
        return data[0] == 1
    }

    public func send(_ data: Data) async throws -> Data {
        let chunks = data.chunked(size: Defaults.maxChunkSize)
        
        guard !chunks.isEmpty else {
            throw MimiGaiaError.emptyData
        }
        
        let numberOfResponseChunks = try await sendRequestChunks(chunks)
        let responseData = try await receiveResponseChunks(count: numberOfResponseChunks)
        
        return responseData
    }
    
    private func sendRequestChunks(_ chunks: [Data]) async throws -> Int {
        var mutableChunks = chunks
        let lastChunk = mutableChunks.removeLast()
        
        // Send all chunks except the last one
        for chunk in mutableChunks {
            _ = try await _gaiaExtension.sendCommand(commandID: MimiGaiaCommand.protobufRequestMsgChunk.rawValue, payload: chunk)
        }
        
        // Send last chunk and get response count
        let response = try await _gaiaExtension.sendCommand(commandID: MimiGaiaCommand.protobufRequestMsgEnd.rawValue, payload: lastChunk)
        return Int(response[0])
    }
    
    private func receiveResponseChunks(count: Int) async throws -> Data {
        var returnData = Data()
        var remainingChunks = count
        
        while remainingChunks > 0 {
            let responseCommand: MimiGaiaCommand = remainingChunks > 1 
                ? .protobufResponseMsgChunk 
                : .protobufResponseMsgEnd
            
            let chunkedReturnData = try await _gaiaExtension.sendCommand(commandID: responseCommand.rawValue)
            returnData.append(chunkedReturnData)
            
            remainingChunks -= 1
        }
        
        return returnData
    }
}
