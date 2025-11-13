# MimiGaiaExtension-iOS

## Overview

The `MimiGaiaExtension` library provides an interface for communicating with Mimi-enabled Qualcomm devices through the Gaia protocol.

## Usage

### Creating the Extension

First, create an instance of `MimiAutomaticProcessingGaiaExtension`:

```swift
let mimiGaiaExtension = MimiAutomaticProcessingGaiaExtension(
    device: gaiaDevice,
    connection: gaiaConnection,
    notificationCenter: .default
)
```

### Verifying Device Compatibility

Check if the connected device supports Mimi functionality:

```swift
let isMimiSupported = try await mimiGaiaExtension.isMimiDevice()
if isMimiSupported {
    print("Device supports Mimi Processing")
}
```

### Configuring Mimi Automatic Processing

Use the extension to create a `MimiAutomaticProcessingConfiguration`:

```swift
let configuration = try MimiAutomaticProcessingConfiguration {
    Processor {
        Applicator(timeout: 2.0) { value in
            try await mimiGaiaExtension.send(value)
        }
    }
}
```

Once configured, activate Mimi processing:

```swift
try await processing.activate(configuration: configuration)
```

## Requirements

- iOS 15.0+
- Swift 5.5+
- Gaia SDK
