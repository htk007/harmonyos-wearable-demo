# Getting Started: HarmonyOS Wearable Application Development

> This guide provides a comprehensive starting point for developers who want to build wearable applications within the HarmonyOS ecosystem.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Requirements](#2-requirements)
3. [Project Setup](#3-project-setup)
4. [First ArkTS Component](#4-first-arkts-component)
5. [Sensor APIs](#5-sensor-apis)
6. [Wearable UI Best Practices](#6-wearable-ui-best-practices)
7. [Testing and Deployment](#7-testing-and-deployment)

---

## 1. Introduction

HarmonyOS is a distributed operating system developed by Huawei. It provides a powerful application platform for smartwatches, fitness bands, and other wearable devices. The HarmonyOS wearable ecosystem is equipped with the ArkTS programming language, the ArkUI framework, and comprehensive sensor/health APIs. This ecosystem enables developers to create seamless distributed experiences across devices — from phones to watches.

### Why HarmonyOS Wearable?

- **Distributed Architecture:** Simplified data/UI sharing between phone and watch.
- **ArkTS:** TypeScript-based with static type safety for a modern development experience.
- **Rich Sensor Support:** Heart rate, pedometer, SpO2, and more.
- **Health Kit:** Standard API access to health data.
- **Low Power Consumption:** Wearable-focused optimization capabilities.

---

## 2. Requirements

Ensure the following components are ready before setting up your development environment.

### 2.1 DevEco Studio Installation

DevEco Studio is Huawei's official IDE for developing HarmonyOS applications. Version 4.1 or higher is required.

**Steps:**

1. Download DevEco Studio 4.1+ from the [HarmonyOS Developer Portal](https://developer.harmonyos.com/en/develop/deveco-studio).

2. During installation, select to also install the **HarmonyOS SDK**.

3. On first launch, install **API Level 11** or higher from the SDK Manager.

**System Requirements:**

| Property | Minimum | Recommended |
|---|---|---|
| OS | Windows 10 64-bit / macOS 12 | Windows 11 / macOS 13+ |
| RAM | 8 GB | 16 GB+ |
| Disk | 10 GB free | 30 GB+ SSD |
| JDK | JDK 17 | JDK 17 (bundled) |

### 2.2 HarmonyOS SDK (API Level 11+)

API Level 11 or higher is required to access wearable APIs. Wearable-specific features such as sensor, Health Kit, and distributed data are supported from this level onwards.

Verify the following are installed in SDK Manager:
- `HarmonyOS SDK > API 11 > ArkTS SDK`
- `HarmonyOS SDK > API 11 > Toolchains`
- `HarmonyOS SDK > API 11 > Previewer`

### 2.3 Wearable Emulator Setup

To test without a physical device, you need to set up the HarmonyOS wearable emulator.

**Steps:**

1. Open **Tools > Device Manager** in DevEco Studio.

2. Click **New Emulator** and select the **Wearable** category.

3. Select a device profile (e.g., `HUAWEI Watch GT 4 Pro` or `Generic Wearable Round`).

4. Download the system image with API Level 11 and launch the emulator.

### 2.4 Basic ArkTS Knowledge

ArkTS is HarmonyOS's primary application development language built on top of TypeScript. Familiarity with the following concepts is recommended:

- Basic TypeScript syntax
- Decorators (`@Entry`, `@Component`, `@State`)
- Async/await and Promise usage
- Module system (`import`/`export`)

---

## 3. Project Setup

Follow the steps below to create a new HarmonyOS wearable project.

### 3.1 New Project in DevEco Studio

1. Open DevEco Studio and select **File > New > New Project**.

2. Select the **HarmonyOS** tab, then choose the **Empty Ability** template from the **Application** category.

3. Enter project settings:
   - **Project name:** `MyWearableApp`
   - **Bundle name:** `com.example.mywearableapp`
   - **Save location:** Your preferred directory
   - **Compile SDK:** `API 11`
   - **Model:** `Stage`

4. Click **Finish**.

### 3.2 module.json5 Configuration

Edit the `module.json5` file to specify that the project targets wearable devices.

File path: `entry/src/main/module.json5`

```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "wearable"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:icon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": ["entity.system.home"],
            "actions": ["action.system.home"]
          }
        ]
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.ACTIVITY_MOTION",
        "reason": "$string:permission_motion_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.READ_HEALTH_DATA",
        "reason": "$string:permission_health_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 3.3 Directory Structure

The directory structure of the created project is as follows:

```
MyWearableApp/
├── AppScope/
│   ├── app.json5              # App-level config
│   └── resources/
│       └── base/
│           └── element/
│               └── string.json
├── entry/
│   └── src/
│       └── main/
│           ├── ets/
│           │   ├── entryability/
│           │   │   └── EntryAbility.ets   # Entry point
│           │   └── pages/
│           │       └── Index.ets          # Main page
│           ├── resources/
│           │   ├── base/
│           │   │   ├── element/           # String, color, float resources
│           │   │   └── media/             # Images
│           │   └── en_US/                 # Language resources
│           └── module.json5               # Module config
├── oh-package.json5           # Package dependencies
└── build-profile.json5        # Build config
```

---

## 4. First ArkTS Component

Let's create a simple wearable component with ArkTS. Learn to work with ArkUI decorators and basic components.

### 4.1 Basic @Entry @Component Example

Every page must contain at least one component marked with the `@Entry` decorator. `@Component` defines reusable UI components.

File: `entry/src/main/ets/pages/Index.ets`

```typescript
import { sensor } from '@kit.SensorServiceKit';

// Reusable sub-component
@Component
struct StepCounter {
  @Prop steps: number = 0;

  build() {
    Column() {
      Text(`${this.steps}`)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Text('Steps')
        .fontSize(14)
        .fontColor('#AAAAAA')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
  }
}

// Main page component
@Entry
@Component
struct Index {
  @State stepCount: number = 0;
  @State heartRate: number = 0;
  @State isMonitoring: boolean = false;

  build() {
    Column() {
      // Header
      Text('My Watch App')
        .fontSize(18)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .margin({ top: 20, bottom: 16 })

      // Step counter card
      Column() {
        StepCounter({ steps: this.stepCount })
      }
      .width('80%')
      .padding(16)
      .backgroundColor('#1A1A2E')
      .borderRadius(12)
      .margin({ bottom: 12 })

      // Heart rate info
      Row() {
        Text('HR: ')
          .fontSize(16)
          .fontColor('#AAAAAA')
        Text(`${this.heartRate} bpm`)
          .fontSize(16)
          .fontColor('#FF4444')
          .fontWeight(FontWeight.Bold)
      }
      .margin({ bottom: 20 })

      // Control button
      Button(this.isMonitoring ? 'Stop' : 'Start')
        .width('70%')
        .height(40)
        .fontSize(14)
        .backgroundColor(this.isMonitoring ? '#FF4444' : '#0A84FF')
        .onClick(() => {
          this.isMonitoring = !this.isMonitoring;
          if (this.isMonitoring) {
            this.startSensors();
          } else {
            this.stopSensors();
          }
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D0D1A')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
  }

  private startSensors(): void {
    console.info('[WearableApp] Sensors started');
    // Sensor start code in the section below
  }

  private stopSensors(): void {
    sensor.off(sensor.SensorId.PEDOMETER);
    sensor.off(sensor.SensorId.HEART_RATE);
    console.info('[WearableApp] Sensors stopped');
  }
}
```

### 4.2 State Management with @State

`@State` defines a component's internal reactive state. When state changes, the bound UI updates automatically.

```typescript
@Entry
@Component
struct CounterExample {
  // @State: component owns its state
  @State count: number = 0;
  @State message: string = 'Counter';

  build() {
    Column({ space: 12 }) {
      Text(this.message)
        .fontSize(16)
        .fontColor('#CCCCCC')

      Text(`${this.count}`)
        .fontSize(48)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)

      Row({ space: 8 }) {
        Button('-')
          .width(44)
          .height(44)
          .fontSize(20)
          .onClick(() => {
            if (this.count > 0) this.count--;
          })

        Button('+')
          .width(44)
          .height(44)
          .fontSize(20)
          .onClick(() => {
            this.count++;
            if (this.count >= 10) {
              this.message = 'Great!';
            }
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

### 4.3 Core ArkUI Components

Examples of the most commonly used ArkUI components in wearable apps:

```typescript
@Entry
@Component
struct UIComponentsDemo {
  @State selectedIndex: number = 0;
  private menuItems: string[] = ['Home', 'Health', 'Activity'];

  build() {
    Column() {
      // Text component
      Text('HarmonyOS Watch')
        .fontSize(20)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // Row — horizontal layout
      Row({ space: 8 }) {
        ForEach(this.menuItems, (item: string, index: number) => {
          Text(item)
            .fontSize(12)
            .fontColor(this.selectedIndex === index ? '#0A84FF' : '#888888')
            .onClick(() => {
              this.selectedIndex = index;
            })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({ top: 8, bottom: 8 })

      // Column — vertical layout
      Column({ space: 6 }) {
        this.buildMetricCard('Steps', '8,432', '#4CAF50')
        this.buildMetricCard('Calories', '342 kcal', '#FF9800')
        this.buildMetricCard('Distance', '6.2 km', '#2196F3')
      }
      .width('100%')
      .padding({ left: 8, right: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#121212')
  }

  @Builder
  buildMetricCard(label: string, value: string, color: string) {
    Row() {
      Column() {
        Text(label)
          .fontSize(11)
          .fontColor('#888888')
        Text(value)
          .fontSize(16)
          .fontColor(color)
          .fontWeight(FontWeight.SemiBold)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#1E1E1E')
    .borderRadius(8)
  }
}
```

---

## 5. Sensor APIs

HarmonyOS provides access to sensors on wearable devices through the `@ohos.sensor` module. Make sure the required permissions are added to `module.json5` before use.

### 5.1 @ohos.sensor Module

```typescript
import { sensor } from '@kit.SensorServiceKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 5.2 Pedometer Sensor Example

The pedometer sensor monitors the user's step data in real time. Requires the `ohos.permission.ACTIVITY_MOTION` permission.

```typescript
import { sensor } from '@kit.SensorServiceKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct PedometerDemo {
  @State steps: number = 0;
  @State permissionGranted: boolean = false;
  private context = getContext(this) as common.UIAbilityContext;

  aboutToAppear(): void {
    this.requestPermission();
  }

  aboutToDisappear(): void {
    this.stopPedometer();
  }

  // Request permission
  async requestPermission(): Promise<void> {
    const permissions: Permissions[] = ['ohos.permission.ACTIVITY_MOTION'];
    const atManager = abilityAccessCtrl.createAtManager();

    try {
      const result = await atManager.requestPermissionsFromUser(this.context, permissions);
      if (result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.permissionGranted = true;
        this.startPedometer();
      } else {
        console.warn('[Pedometer] Permission denied');
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[Pedometer] Permission error: ${error.code} - ${error.message}`);
    }
  }

  // Start sensor
  startPedometer(): void {
    try {
      sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
        // data.steps: cumulative step count (until device reboot)
        this.steps = data.steps;
        console.info(`[Pedometer] Steps: ${data.steps}`);
      }, {
        interval: 1000000000 // 1 second in nanoseconds
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[Pedometer] Start error: ${error.code} - ${error.message}`);
    }
  }

  // Stop sensor
  stopPedometer(): void {
    try {
      sensor.off(sensor.SensorId.PEDOMETER);
      console.info('[Pedometer] Sensor stopped');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[Pedometer] Stop error: ${error.code}`);
    }
  }

  build() {
    Column({ space: 16 }) {
      Text('Pedometer')
        .fontSize(18)
        .fontColor('#FFFFFF')

      Text(`${this.steps}`)
        .fontSize(52)
        .fontColor('#4CAF50')
        .fontWeight(FontWeight.Bold)

      Text('steps')
        .fontSize(14)
        .fontColor('#888888')

      if (!this.permissionGranted) {
        Text('Waiting for permission...')
          .fontSize(12)
          .fontColor('#FF9800')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

### 5.3 Heart Rate Sensor

The heart rate sensor provides real-time pulse data. Requires the `ohos.permission.READ_HEALTH_DATA` permission.

```typescript
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct HeartRateDemo {
  @State heartRate: number = 0;
  @State accuracy: number = 0;

  aboutToAppear(): void {
    this.startHeartRateSensor();
  }

  aboutToDisappear(): void {
    sensor.off(sensor.SensorId.HEART_RATE);
  }

  startHeartRateSensor(): void {
    try {
      sensor.on(sensor.SensorId.HEART_RATE, (data: sensor.HeartRateResponse) => {
        // data.heartRate: heart rate value in BPM
        this.heartRate = data.heartRate;

        // Accuracy levels:
        // 0 = Unreliable, 1 = Low, 2 = Medium, 3 = High
        this.accuracy = data.accuracy ?? 0;

        console.info(`[HeartRate] BPM: ${data.heartRate}, Accuracy: ${this.accuracy}`);
      }, {
        interval: 'normal' // 'normal' | 'ui' | 'game' | 'fastest' or nanoseconds
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[HeartRate] Error: ${error.code} - ${error.message}`);
    }
  }

  getHeartRateColor(): string {
    if (this.heartRate < 60) return '#2196F3';   // Low
    if (this.heartRate < 100) return '#4CAF50';  // Normal
    if (this.heartRate < 140) return '#FF9800';  // High
    return '#F44336';                             // Very high
  }

  build() {
    Column({ space: 12 }) {
      Text('Heart Rate')
        .fontSize(16)
        .fontColor('#CCCCCC')

      Row({ space: 4 }) {
        Text(`${this.heartRate}`)
          .fontSize(48)
          .fontColor(this.getHeartRateColor())
          .fontWeight(FontWeight.Bold)
        Column() {
          Text('BPM')
            .fontSize(14)
            .fontColor('#888888')
          Text(`±${this.accuracy}`)
            .fontSize(10)
            .fontColor('#666666')
        }
        .justifyContent(FlexAlign.End)
        .margin({ bottom: 8 })
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0A0A0A')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

### 5.4 Permission Management

Critical permissions for wearable apps must be declared in `module.json5` and requested from the user at runtime.

```typescript
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// Batch permission request
async function requestWearablePermissions(context: common.UIAbilityContext): Promise<boolean> {
  const permissions: Permissions[] = [
    'ohos.permission.ACTIVITY_MOTION',
    'ohos.permission.READ_HEALTH_DATA',
    'ohos.permission.LOCATION'
  ];

  const atManager = abilityAccessCtrl.createAtManager();

  try {
    const result = await atManager.requestPermissionsFromUser(context, permissions);
    const allGranted = result.authResults.every(
      (status) => status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
    );

    if (allGranted) {
      console.info('[Permissions] All permissions granted');
    } else {
      const denied = permissions.filter(
        (_, i) => result.authResults[i] !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      );
      console.warn(`[Permissions] Denied: ${denied.join(', ')}`);
    }

    return allGranted;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[Permissions] Error: ${error.code} - ${error.message}`);
    return false;
  }
}
```

---

## 6. Wearable UI Best Practices

UI design in wearable applications differs significantly from phone applications. You should apply design principles optimized for small and often circular screens.

### 6.1 Small Screen Design Principles

- **Content priority:** Show only the most important information; remove unnecessary elements.
- **Large, readable text:** Minimum 14sp font size, at least 36sp for headings.
- **High contrast:** Light text on dark background (WCAG AA standard).
- **One-handed use:** Scrolling down is sufficient; avoid complex navigation.

### 6.2 Circular/Square Screen Compatibility

Some smartwatches have circular screens, others are square. Content should not be clipped at corners for either form factor.

```typescript
@Entry
@Component
struct CircularAdaptiveLayout {
  build() {
    // Shape-adaptive container
    Column() {
      // Increase corner padding on circular screens
      Column({ space: 8 }) {
        Text('Watch Face')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)

        Text('10:42')
          .fontSize(52)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Light)

        Text('Thu, 26 Mar')
          .fontSize(14)
          .fontColor('#AAAAAA')
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      // 15% horizontal padding keeps content safe on circular screens
      .padding({
        left: '15%',
        right: '15%',
        top: '10%',
        bottom: '10%'
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
```

### 6.3 Font Size and Touch Target Sizes

Touch targets should be at least 7x7mm (approximately 48x48dp). This is especially important on wearable screens.

| Element | Min Size | Recommended |
|---|---|---|
| Button | 44 x 44 vp | 48 x 48 vp |
| Icon Button | 40 x 40 vp | 44 x 44 vp |
| List Item | height 40 vp | 48 vp |
| Title Font | 18 sp | 20-24 sp |
| Body Font | 14 sp | 16 sp |
| Caption | 11 sp | 12 sp |

```typescript
@Component
struct AccessibleButton {
  label: string = '';
  onPress: () => void = () => {};

  build() {
    Button(this.label)
      // Minimum touch target size
      .width(48)
      .height(48)
      // Minimum font size
      .fontSize(14)
      // Adequate padding
      .padding({ left: 12, right: 12 })
      .onClick(this.onPress)
  }
}
```

### 6.4 Battery Optimization

Battery capacity is limited on wearable devices. Turn sensors on only when needed and off when not in use.

```typescript
@Entry
@Component
struct BatteryOptimizedApp {
  @State isActive: boolean = false;
  private sensorTimer: number = -1;

  // Use sensor at timed intervals (not continuously)
  startOptimizedSensing(): void {
    this.sensorTimer = setInterval(() => {
      // Short measurement every 30 seconds
      sensor.on(sensor.SensorId.HEART_RATE, (data: sensor.HeartRateResponse) => {
        console.info(`[Battery] Quick HR read: ${data.heartRate}`);
        // Turn off immediately after reading
        sensor.off(sensor.SensorId.HEART_RATE);
      });
    }, 30000); // 30 seconds
  }

  stopOptimizedSensing(): void {
    if (this.sensorTimer !== -1) {
      clearInterval(this.sensorTimer);
      this.sensorTimer = -1;
    }
    sensor.off(sensor.SensorId.HEART_RATE);
    sensor.off(sensor.SensorId.PEDOMETER);
  }

  aboutToDisappear(): void {
    // Stop sensors when component is destroyed
    this.stopOptimizedSensing();
  }

  build() {
    Column() {
      Text('Battery Saver Mode')
        .fontSize(16)
        .fontColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

---

## 7. Testing and Deployment

Test your application on the emulator first, then deploy to a real device.

### 7.1 Testing on Emulator

1. In DevEco Studio, select **Run > Run 'entry'** or use the `Shift+F10` shortcut.

2. Select your wearable emulator from Device Manager.

3. Build and deploy happen automatically.

**Sensor Simulation on Emulator:**

You can send virtual sensor data from DevEco Studio's **Extended Controls** panel:

- **Steps:** Set virtual pedometer value
- **Heart Rate:** Enter simulated heart rate value
- **Location:** Simulate GPS coordinates

### 7.2 Debug on Real Device

To test on a real HarmonyOS wearable device:

1. Enable **Developer Options** on the watch: Settings > About > Tap Build Number 7 times.

2. Enable **USB Debugging**: Developer Options > USB Debugging.

3. Connect the watch to your computer via USB or Bluetooth.

4. Verify your device appears in Device Manager in DevEco Studio.

### 7.3 hdc Commands

`hdc` (HarmonyOS Device Connector) is the command-line tool for device management. It is located in the `DevEco Studio/sdk/toolchains/` directory.

```bash
# List connected devices
hdc list targets

# Deploy app package
hdc app install MyWearableApp.hap

# Uninstall application
hdc app uninstall com.example.mywearableapp

# Monitor device logs
hdc hilog

# Filter logs by tag
hdc hilog | grep "WearableApp"

# Start application
hdc shell aa start -a EntryAbility -b com.example.mywearableapp

# Stop application
hdc shell aa force-stop com.example.mywearableapp

# Send file to device
hdc file send ./localfile.txt /data/local/tmp/

# Get file from device
hdc file recv /data/local/tmp/logfile.txt ./

# View device information
hdc shell param get const.product.model

# Check battery status
hdc shell hidumper -s BatteryService -a info
```

### 7.4 Common Issues and Solutions

| Issue | Possible Cause | Solution |
|---|---|---|
| Device not visible | No USB driver | Install Huawei USB driver |
| Build error | API Level mismatch | Check API level in `build-profile.json5` |
| No sensor data | Permission denied | Verify permissions in `module.json5` |
| App crash on launch | ArkTS type error | Check detailed error in logcat |
| Slow emulator | Insufficient RAM | Increase emulator RAM |

---

## Next Steps

After completing this guide, we recommend exploring the following topics:

- **Health Kit:** `@ohos.health` module for comprehensive health data APIs
- **Distributed DevKit:** Data sharing between phone and watch
- **Watch Face Development:** Custom watch face development
- **ArkUI Animation:** Component animations and transition effects
- **Notification Management:** Wearable notification management
- **API Cheatsheet:** See `api-cheatsheet.md` for the full API reference

---

*Last updated: March 2026 | HarmonyOS API Level 11+ | DevEco Studio 4.1+*
