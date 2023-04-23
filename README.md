[![Build Status][build status badge]][build status]
[![License][license badge]][license]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]

# Meter

Meter is a companion library to [MetricKit](https://developer.apple.com/documentation/metrickit). It aims to provide the following capabilities:

- API for `MXCallStackTree`
- Types for `MXDiagnostic` emulation and coding
- `MXMetricManager`-like interface for unsupported platforms
- On-device symbolication
- Account for MetricKit inconsistencies across platforms and types
- Support for custom exception reporting

If you're also looking for a way to transmit MetricKit data to your server, have a look at [MeterReporter](https://github.com/ChimeHQ/MeterReporter). It uses Meter under the hood, and takes care of the details.

## Integration

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/Meter")
]
```

## Expanded API

The MetricKit API for crash reporting is unwieldy. In particular, `MXCallStackTree` lacks any kind of interface for interacting with its structure. Meter includes some classes that make it easier to work with. In addition to providing an API for `MXCallStackTree`, Meter includes types to emulate and parse MetricKit diagnostics.

```swift
let data = mxTree.jsonRepresentation()
let tree = try CallStackTree.from(data: data)

for frame in tree.callStacks[0].frames {
    print("\(frame.address) \(frame.binaryName) \(frame.binaryUUID)")
}
```

## Custom Exceptions

MetricKit diagnostics does not capture or include uncaught NSExceptions. This can make it very difficult to debug certain kinds of crashes, particularly on macOS. Meter includes an `ExceptionInfo` type to help address this. These can be created from an `NSException` object, which will capture all the needed runtime information to emulate a standard `CallStack`.

How you actually get access to the `NSException` is not defined by Meter. But, if you have one, the `CrashDiagnostic` type also includes an `exceptionInfo` property that can accept one of these for easy encoding.

## MXMetricManager and Diagnostics Polyfill

MetricKit's crash reporting facilities require iOS 14/macOS 12.0, and isn't supported at all for tvOS or watchOS. You may want to start moving towards using it as a standard interface between your app and whatever system consumes the data. Meter offers an API that's very similar to MetricKit's `MXMetricManager` to help do just that.

```swift
// adding a subscriber
MeterPayloadManager.shared.add(obj)

extension MyObject: MeterPayloadSubscriber {
    func didReceive(_ payloads: [DiagnosticPayloadProtocol]) {
        // this will be called for both simulated payloads *and* MeterKit payloads on OSes it supports
        print("received payloads \(payloads)")
    }
}

// posting diagnostics
MeterPayloadManager.shared.deliver(payloads)
```

This makes it easier to support the full capabilities of MetricKit when available, and gracefully degrade when they aren't. It can be nice to have a uniform interface to whatever backend system you are using to consume the reports. And, as you move towards a supported minimum, and as (hopefully) Apple starts supporting MetricKit on all platforms, it will be easier to pull out Meter altogether.

Backwards compatibility is still up to you, though. One solution is [ImpactMeterAdapter](https://github.com/ChimeHQ/ImpactMeterAdapter), which uses [Impact](https://github.com/ChimeHQ/Impact) to collect crash data for OSes that don't support `MXCrashDiagnostic`.

## On-Device Symbolication

The stack traces provided by MetricKit, like other types of crash logs, are not symbolicated. There are a bunch of different ways to tackle this problem, but one very convenient option is just to do it as a post-processing step on the device where the crash occurred. This does come, however, with one major drawback. It only works when you still have access to the same binaries. OS updates will almost certainly change all the OS binaries. The same is true for an app update, though in that case, an off-line symbolication step using a dSYM is still doable.

Meter provides an API for performing symbolication, via the `Symbolicator` protocol. The core of this protocol should be usable to symbolicate any address, and is not tied to MetricKit. But, the protocol also does include a number of convenience methods that can operate on the various MetricKit classes. The result uses the Meter's wrapper classes to return `Frame` instances which include a `symbolInfo` property. This property can be accessed directly or just re-encoded for transport.

```swift
let symbolicator = DlfcnSymbolicator()
let symPayload = symbolicator.symbolicate(payload: diagnosticPayload)
```

### DlfcnSymbolicator

This class implements the `Symbolicator` protocol, and uses the functions with `dlfcn.h` to determine symbol/offset. This works, but does have some limitations. First, it relies on looking up symbols in the **currently executing** process, so it will only work if the needed binary is currently loaded.

Second, these functions return `<redacted>` for some binary's symbols on iOS. I know the symbol information is still accessible from the binary, so it's unclear why this is done.

This is a relatively inexpensive symbolication pass, and is a first effort. Further work here is definitely necessary.

## Suggestions or Feedback

We'd love to hear from you! Get in touch via an issue or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[build status]: https://github.com/ChimeHQ/Meter/actions
[build status badge]: https://github.com/ChimeHQ/Meter/workflows/CI/badge.svg
[license]: https://opensource.org/licenses/BSD-3-Clause
[license badge]: https://img.shields.io/github/license/ChimeHQ/Meter
[platforms]: https://swiftpackageindex.com/ChimeHQ/Meter
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FMeter%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/ChimeHQ/Meter/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
