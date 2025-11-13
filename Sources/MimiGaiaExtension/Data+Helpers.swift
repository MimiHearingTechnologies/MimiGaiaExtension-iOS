//
//  Data+Helpers.swift
//  MimiGaiaExtension-iOS
//
//  Created by Hozefa Indorewala on 13.11.25.
//
import Foundation

extension Data {

    func chunked(size: Int) -> [Data] {
        var chunks: [Data] = []
        var offset = 0

        while offset < count {
            let chunkSize = Swift.min(size, count - offset)
            let chunk = self[offset..<offset + chunkSize]
            chunks.append(chunk)
            offset += chunkSize
        }

        return chunks
    }
}
