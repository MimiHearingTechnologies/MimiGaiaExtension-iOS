# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.2.0 - 2026-06-22

### Changed
- `MimiAutomaticProcessingGaiaExtension` is now an `actor` instead of a `class`; the `gaiaExtension` property and its backing storage are `nonisolated`.

### Removed
- `MimiAutomaticProcessingGaiaExtensionProtocol`.
- The `isMimiDevice()` method and its corresponding `isMimiDevice` Gaia command.

## 0.1.0

### Added
- Initial release of MimiGaiaExtension
