[![Github CI](https://github.com/ChimeHQ/Meter/workflows/CI/badge.svg)](https://github.com/ChimeHQ/Meter/actions)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)

# Meter

Meter is a companion library to [MetricKit](https://developer.apple.com/documentation/metrickit). It aims to provide the following capabilities:

- API for `MXCallStackTree`
- MXMetricManager-like interface for unsupported platforms
- On-device symbolication

Meter is still a work in progress.

## Integration

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/Meter.git")
]
```

### Carthage

```
github "ChimeHQ/Meter"
```

### Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.