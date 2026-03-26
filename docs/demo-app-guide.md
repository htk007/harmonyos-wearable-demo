# HarmonyOS Wearable Health Demo — Application Guide

> A comprehensive guide for understanding, presenting, and developing the demo application.

---

## 1. Application Overview

`harmonyos-wearable-demo` is a reference-quality demo project designed to introduce the HarmonyOS wearable development environment. It includes all the core elements expected in a real product implementation:

- **Multi-page navigation** (Tabs / Bottom Menu)
- **Sensor API integration** (real device + mock fallback)
- **Cross-device synchronization** (distributed data)
- **Reusable UI components**
- **Lifecycle and permission management**

---

## 2. Page Descriptions

### 2.1 Index (Main Dashboard)

**File:** `src/main/ets/pages/Index.ets`

The main dashboard is the entry point of the application. It includes the following elements:

| Component | Description |
|-----------|-------------|
| Live clock | Clock display updated every second via `setInterval` |
| Step progress ring | Circular daily goal display using the `RingProgress` component |
| HealthCard Grid | Heart rate, steps, calories, sleep score, distance cards |
| Bottom navigation | 4 tabs: Home, Heart, Steps, Sleep |

**Teaching Points:**
```typescript
// Reactive variable with @State
@State currentHeartRate: number = 0

// Mock data update (real sensor simulation)
private startMockDataUpdate(): void {
  setInterval(() => {
    this.currentHeartRate = Math.floor(60 + Math.random() * 40)
  }, 3000)
}
```

---

### 2.2 HeartRate (Heart Rate Monitor)

**File:** `src/main/ets/pages/HeartRate.ets`

| Feature | Technical Detail |
|---------|-----------------|
| Real-time BPM | `sensor.on(SensorId.HEART_RATE)` callback |
| Pulse animation | `@State` + CSS `scale` animation |
| Statistics cards | Min / Max / Average calculation |
| BPM zone table | Bradycardia < 60, Normal 60-100, High 100-120, Tachycardia > 120 |
| Alert banner | Visible above 120 BPM or below 50 BPM |

**Teaching Points:**
```typescript
// Sensor registration
sensor.on(sensor.SensorId.HEART_RATE, (data: sensor.HeartRateResponse) => {
  this.currentBPM = data.heartRate
  this.updateStats(data.heartRate)
}, { interval: 1000000000 }) // in nanoseconds

// Cleanup (preventing memory leak)
aboutToDisappear() {
  sensor.off(sensor.SensorId.HEART_RATE)
}
```

---

### 2.3 StepCounter (Step Counter)

**File:** `src/main/ets/pages/StepCounter.ets`

| Feature | Technical Detail |
|---------|-----------------|
| Circular progress | `RingProgress` component, color changes with progress |
| Animated counter | Smooth animation from 0 to value |
| Calorie calculation | `steps * 0.04` approximate formula |
| Distance calculation | `steps * 0.762` meters (average stride length) |
| Hourly distribution | Bar chart with Canvas |
| Goal selector | 5K / 7.5K / 10K / 15K |

**Teaching Points:**
```typescript
// Pedometer sensor usage
sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
  this.stepCount = data.steps
  this.updateDerivedMetrics()
}, { interval: 'game' }) // 'game' = ~200ms update
```

---

### 2.4 SleepTracker (Sleep Analysis)

**File:** `src/main/ets/pages/SleepTracker.ets`

3-tab structure:

| Tab | Content |
|-----|---------|
| **Analysis** | Circular sleep score, stage distribution progress bars |
| **History** | 7-day bar chart + daily list |
| **Recommendations** | 6 personalized recommendation cards |

**Teaching Points:**
```typescript
// Reading sleep data from Health Kit
health.getHealthData({
  dataType: health.HealthDataType.SLEEP,
  startTime: yesterdayMidnight,
  endTime: todayNoon
}).then((data) => {
  this.processSleepData(data)
})
```

---

## 3. Component Descriptions

### 3.1 HealthCard

**File:** `src/main/ets/components/HealthCard.ets`

```typescript
// Usage example
HealthCard({
  title: '❤️ Heart Rate',
  value: '72',
  unit: 'BPM',
  iconName: 'heart',
  trend: 'up',           // 'up' | 'down' | 'stable'
  accentColor: '#FF4757',
  onClick: () => { router.pushUrl({ url: 'pages/HeartRate' }) }
})
```

**Props Table:**

| Prop | Type | Description |
|------|------|-------------|
| `title` | `string` | Card title |
| `value` | `string` | Value to display |
| `unit` | `string` | Unit (BPM, steps, kcal...) |
| `trend` | `'up' \| 'down' \| 'stable'` | Trend icon direction |
| `accentColor` | `string` | Left border color |
| `onClick` | `() => void` | Click callback |

---

### 3.2 RingProgress

**File:** `src/main/ets/components/RingProgress.ets`

Circular progress indicator drawn manually with the Canvas 2D API.

```typescript
// Usage example
RingProgress({
  progress: 0.68,        // 0.0 - 1.0
  size: 120,             // px
  strokeWidth: 12,       // px
  color: '#2ED573',
  bgColor: '#2A2A2A'
}) {
  // Custom content in center (@BuilderParam)
  Text('6,800')
  Text('steps')
}
```

**Technical Details:**
- Drawing with `Canvas` + `CanvasRenderingContext2D`
- Arc drawing with `arc()` method
- Smooth start from 0 to target with 600ms `animateTo`
- Gold glow effect at 100%

---

## 4. Service Descriptions

### 4.1 HealthSensorService

**File:** `src/main/ets/services/HealthSensorService.ets`

Manages all sensor subscriptions using the singleton pattern.

```typescript
// Usage
const sensorService = HealthSensorService.getInstance()

// Start step counter
sensorService.startPedometerListening((steps: number) => {
  this.stepCount = steps
})

// Start heart rate
sensorService.startHeartRateListening((bpm: number) => {
  this.heartRate = bpm
})

// Cleanup on app close
sensorService.stopAllSensors()
```

**Mock Mode:**
```typescript
// Automatic mock fallback when no real sensor is available
private initializeSensor(sensorId: SensorId): void {
  try {
    sensor.getSensorList((err, list) => {
      const hasSensor = list.some(s => s.sensorId === sensorId)
      this.useMockData = !hasSensor
      hasSensor ? this.startRealSensor(sensorId) : this.startMockSensor(sensorId)
    })
  } catch(e) {
    this.useMockData = true
    this.startMockSensor(sensorId)
  }
}
```

---

### 4.2 DataSyncService

**File:** `src/main/ets/services/DataSyncService.ets`

Synchronizes health data between the smartwatch and phone.

```typescript
// Start device discovery
const syncService = DataSyncService.getInstance()
await syncService.startDeviceDiscovery()

// Instant synchronization
await syncService.syncHealthData({
  timestamp: Date.now(),
  heartRate: 72,
  steps: 6800,
  calories: 272,
  sleepScore: 85
})

// Automatic synchronization (30-minute intervals)
syncService.startAutoSync()
```

---

## 5. Configuration

### module.json5 Summary

```json5
{
  "module": {
    "deviceTypes": ["wearable"],  // Wearable target only
    "abilities": [{
      "name": "EntryAbility",
      "orientation": "auto",       // Square/round screen support
      "backgroundModes": ["healthSport", "dataTransfer"]
    }],
    "requestPermissions": [/* 6 permissions */]
  }
}
```

### build-profile.json5 Summary

```json5
{
  "app": { "compileSdkVersion": 11 },
  "targets": [
    { "name": "default" },         // Debug: obfuscation off
    { "name": "release",           // Release: obfuscation on
      "runtimeOS": "HarmonyOS" }
  ]
}
```

---

## 6. Demo Presentation Scenario

Recommended scenario when presenting this application at a developer meetup or workshop:

### Step 1 — The Big Picture (2 min)
> "The HarmonyOS wearable ecosystem is built on three core pillars: ArkUI, ArkTS, and the Distributed Stack. This demo shows you how to use all three together."

### Step 2 — Main Dashboard (3 min)
- Open `Index.ets`, demonstrate `@State` and reactivity
- Examine the `HealthCard` component — prop-based composition

### Step 3 — Sensor Integration (5 min)
- Show the `sensor.on()` API through `HealthSensorService.ets`
- Explain the mock vs. real sensor fallback

### Step 4 — Device Synchronization (3 min)
- Explain the distributed data concept through `DataSyncService.ets`
- Highlight what makes HarmonyOS different and how

### Step 5 — Live Demo (5 min)
- Run the application in the emulator
- Show the step and heart rate simulation

---

## 7. Frequently Asked Questions

**Q: What do I need to do to receive real sensor data?**
A: Set the `useMockData` flag inside `HealthSensorService` to `false` and run on a real device.

**Q: Can I port this to iOS/Android?**
A: ArkTS and ArkUI are specific to HarmonyOS. However, since the logic layer is close to TypeScript, it can be migrated to cross-platform tools.

**Q: How do you actually retrieve sleep data?**
A: In a real implementation, `@ohos.health.HealthDataType.SLEEP` is used. Simulated data is sufficient for the demo.

**Q: Does it support devices older than API Level 11?**
A: With `compatibleSdkVersion: 10` in `build-profile.json5`, it works on API 10 devices as well, though some features may be limited.

---

Prepared by: **HarmonyOS Developer Advocate Team**
Version: 1.0.0 | Date: March 2026
