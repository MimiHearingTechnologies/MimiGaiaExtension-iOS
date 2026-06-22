# MimiGaiaExtension-iOS

> ⚠️ This repository is **generated**. Its source of truth lives in the private
> `MimiFirmwareKit-Swift` repo and is synced automatically. Do not edit files here.

## Overview

The `MimiGaiaExtension` library provides an interface for communicating with
Mimi-enabled Qualcomm devices through the Gaia protocol.

**Note:** The MimiGaiaExtension currently only supports Protobuf-based Mimi
Automatic Processing. Support for Mimi Basic Processing has not been added yet.

## Requirements

- iOS 15.0+
- Swift 5.10+
- The following Gaia frameworks: `GaiaCore`, `Packets`, `GaiaBase`, `GaiaLogger`

### Gaia Frameworks

⚠️ The extension depends on the proprietary Qualcomm GAIA iOS frameworks. These
are not bundled here — you must provide your own copy and make the modules
available to the target that compiles these source files.

## Installation

This repository is distributed as source. Add the `.swift` files under
`Sources/MimiGaiaExtension/` to a target in your app that already links the Gaia
frameworks.

## Usage

### 1. Create and register the extension

```swift
VendorExtensionManager.shared.register { (device, connection, notificationCenter) -> GaiaDeviceVendorExtensionProtocol in
    let mimiExtension = MimiAutomaticProcessingGaiaExtension(device: device, connection: connection, notificationCenter: notificationCenter)
    self.mimiGaiaExtension = mimiExtension // Hold on to the extension
    return mimiExtension.gaiaExtension
}
```

### 2. Activate a Mimi Processing session

```swift
let configuration = try MimiAutomaticProcessingConfiguration {
    Processor {
        Applicator { value in
            try await self.mimiGaiaExtension.send(value)
        }
    }
}

try await processing.activate(configuration: configuration)
```

### 3. Deactivate on disconnection

Upon headphone disconnection, deactivate the Mimi Processing session; no specific
action is required for the Mimi GAIA extension itself.

```swift
try await processing.deactivate()
```
