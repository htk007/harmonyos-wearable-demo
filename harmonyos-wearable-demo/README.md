# HarmonyOS Wearable Health Demo

> A comprehensive health tracking demo application written in ArkTS for the HarmonyOS wearable ecosystem.

---

## Overview

This project is a **health monitor demo application** built for the HarmonyOS wearable (smartwatch) platform. Created by the Developer Advocate team to help developers learn HarmonyOS Wearable APIs.

---

## Features

| Feature | Description |
|---------|-------------|
| 🫀 **Heart Rate Monitor** | Real-time BPM tracking, min/max/avg statistics, tachycardia alert |
| 👣 **Step Counter** | Daily goal tracking, calorie & distance calculation, hourly distribution chart |
| 😴 **Sleep Analysis** | Sleep phase distribution (Deep/REM/Light), sleep score, 7-day history |
| 📡 **Phone Sync** | Cross-device data sharing via Distributed Hardware API |

---

## Project Structure

```
harmonyos-wearable-demo/
├── src/
│   └── main/
│       ├── ets/
│       │   ├── pages/
│       │   │   ├── Index.ets          # Main dashboard
│       │   │   ├── HeartRate.ets      # Heart rate monitor
│       │   │   ├── StepCounter.ets    # Step counter
│       │   │   └── SleepTracker.ets   # Sleep analysis
│       │   ├── components/
│       │   │   ├── HealthCard.ets     # Reusable health metric card
│       │   │   └── RingProgress.ets   # Circular progress indicator
│       │   └── services/
│       │       ├── HealthSensorService.ets  # Sensor management
│       │       └── DataSyncService.ets      # Device synchronization
│       └── resources/
│           └── base/profile/
│               └── main_pages.json    # Page routes
├── module.json5                       # Module configuration
├── build-profile.json5                # Build settings
└── README.md
```

---

## APIs Used

```typescript
@ohos.sensor           // Pedometer, HeartRate, Accelerometer
@ohos.health           // Health data read/write
@ohos.distributedHardware.deviceManager  // Device discovery & sync
@ohos.vibrator         // Haptic feedback
```

### Required Permissions

```json
"requestPermissions": [
  { "name": "ohos.permission.ACTIVITY_MOTION" },
  { "name": "ohos.permission.READ_HEALTH_DATA" },
  { "name": "ohos.permission.DISTRIBUTED_DATASYNC" },
  { "name": "ohos.permission.USE_BLUETOOTH" },
  { "name": "ohos.permission.KEEP_BACKGROUND_RUNNING" },
  { "name": "ohos.permission.VIBRATE" }
]
```

---

## Setup

### Prerequisites

- **DevEco Studio** 4.1 or higher
- **HarmonyOS SDK** API Level 11+
- **Wearable Emulator** or a real HarmonyOS wearable device

### Steps

```bash
# 1. Open project
# DevEco Studio > File > Open > harmonyos-wearable-demo

# 2. Check SDK dependencies
# File > Project Structure > SDK Location

# 3. Start emulator
# Tools > Device Manager > New Emulator > Wearable

# 4. Run the app
# Run > Run 'entry' (Shift+F10)
```

### hdc Commands

```bash
# List connected devices
hdc list targets

# Install app
hdc install entry-default-signed.hap

# Follow logs
hdc hilog | grep "HealthDemo"
```

---

## Architecture

```
UI Layer (ArkUI Pages)
        ↓
Component Layer (HealthCard, RingProgress)
        ↓
Service Layer (HealthSensorService, DataSyncService)
        ↓
HarmonyOS APIs (@ohos.sensor, @ohos.health, @ohos.distributedHardware)
```

---

## Demo Notes

> **Mock Data:** When real sensor hardware is unavailable, the app automatically uses simulated data. Set the `useMockData` flag to `false` in `HealthSensorService` to switch to real sensor data.

---

## Related Resources

- [Getting Started Guide](../docs/getting-started.md)
- [API Cheatsheet](../docs/api-cheatsheet.md)
- [HarmonyOS Developer Docs](https://developer.harmonyos.com)
- [ArkTS Language Reference](https://developer.harmonyos.com/cn/docs/documentation/doc-references/arkts-overview-0000001531483156)

---

## Contributors

Prepared by: **HarmonyOS Developer Advocate Team**
Version: 1.0.0 | API Level: 11 | Date: March 2026
