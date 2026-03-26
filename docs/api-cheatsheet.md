# HarmonyOS Wearable API Cheatsheet

> This cheatsheet compiles the most commonly used APIs, decorators, and components for HarmonyOS wearable development as a quick reference.

---

## Table of Contents

1. [ArkUI Decorators](#1-arkui-decorators)
2. [Core Layout Components](#2-core-layout-components)
3. [Sensor APIs](#3-sensor-apis)
4. [Health Kit APIs](#4-health-kit-apis)
5. [Distributed Data](#5-distributed-data)
6. [Permissions](#6-permissions)
7. [Wearable-Specific UI](#7-wearable-specific-ui)
8. [Lifecycle](#8-lifecycle)

---

## 1. ArkUI Decorators

ArkUI decorators define component behavior and state management. Choosing the right decorator is fundamental to reactive and efficient UI development.

### Decorator Reference Table

| Decorator | Scope | Description |
|---|---|---|
| `@Entry` | Page | Single entry point in an ArkTS file |
| `@Component` | Struct | Defines a reusable UI component |
| `@State` | Component | Component-local reactive state; UI updates on change |
| `@Prop` | Component | One-way data flow from parent (read-only copy) |
| `@Link` | Component | Two-way binding with parent |
| `@Observed` + `@ObjectLink` | Object | Tracks changes in complex objects |
| `@Provide` + `@Consume` | Tree | Share data deep across the component tree |
| `@Builder` | Function | Defines reusable UI blocks |
| `@Styles` | Style | Groups common style properties |
| `@Extend` | Style | Extends existing component styles |
| `@Watch` | State | Listens to state changes |
| `@StorageLink` | App | Two-way binding with AppStorage |
| `@LocalStorageLink` | Page | Two-way binding with LocalStorage |

### @State — Component-Local State

```typescript
@Entry
@Component
struct StateDemo {
  // Primitive state
  @State count: number = 0;
  @State label: string = 'Hello';
  @State isVisible: boolean = true;

  // Object state — object reference must change
  @State userInfo: { name: string; age: number } = { name: 'Ali', age: 28 };

  // Array state
  @State items: string[] = ['Item 1', 'Item 2'];

  build() {
    Column({ space: 8 }) {
      Text(`Count: ${this.count}`).fontSize(16).fontColor('#FFFFFF')
      Button('Increment')
        .onClick(() => { this.count++; })
        .height(44)

      // Assign a new reference to update an object
      Button('Update User')
        .onClick(() => {
          this.userInfo = { ...this.userInfo, age: this.userInfo.age + 1 };
        })
        .height(44)
    }
    .width('100%').height('100%').backgroundColor('#000000')
    .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  }
}
```

### @Prop and @Link — Parent-Child Communication

```typescript
// Child component
@Component
struct ChildProp {
  @Prop value: number = 0;           // One-way
  @Link sharedValue: number;         // Two-way

  build() {
    Column({ space: 6 }) {
      Text(`Prop (one-way): ${this.value}`).fontColor('#AAAAAA').fontSize(13)
      Text(`Link (two-way): ${this.sharedValue}`).fontColor('#4CAF50').fontSize(13)
      Button('Increment Link')
        .height(36).fontSize(12)
        .onClick(() => { this.sharedValue++; }) // Also updates parent
    }
  }
}

// Parent component
@Entry
@Component
struct ParentComponent {
  @State parentCount: number = 10;
  @State sharedCount: number = 0;

  build() {
    Column({ space: 10 }) {
      Text(`Parent: ${this.parentCount}`).fontColor('#FFFFFF').fontSize(16)
      Text(`Shared: ${this.sharedCount}`).fontColor('#FFFFFF').fontSize(16)

      ChildProp({
        value: this.parentCount,
        sharedValue: $sharedCount   // Pass by reference with $
      })
    }
    .width('100%').height('100%').backgroundColor('#111111')
    .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  }
}
```

### @Builder — Reusable UI Blocks

```typescript
@Entry
@Component
struct BuilderDemo {
  @State heartRate: number = 72;
  @State steps: number = 6500;

  // Component-scoped @Builder
  @Builder
  MetricCard(icon: string, label: string, value: string, color: string) {
    Row({ space: 8 }) {
      Text(icon).fontSize(20)
      Column() {
        Text(label).fontSize(11).fontColor('#888888')
        Text(value).fontSize(16).fontColor(color).fontWeight(FontWeight.SemiBold)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#1E1E1E')
    .borderRadius(10)
  }

  build() {
    Column({ space: 8 }) {
      this.MetricCard('❤️', 'Heart Rate', `${this.heartRate} bpm`, '#F44336')
      this.MetricCard('👟', 'Steps', `${this.steps}`, '#4CAF50')
    }
    .width('100%').height('100%').backgroundColor('#0A0A0A')
    .padding(16)
    .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  }
}
```

### @Styles and @Extend

```typescript
// @Styles — style groups
@Styles
function darkCard() {
  .backgroundColor('#1E1E1E')
  .borderRadius(12)
  .padding(12)
}

// @Extend — extending component styles
@Extend(Text)
function metricValue() {
  .fontSize(32)
  .fontWeight(FontWeight.Bold)
  .fontColor('#FFFFFF')
}

@Extend(Button)
function primaryBtn() {
  .width('80%')
  .height(44)
  .fontSize(14)
  .backgroundColor('#0A84FF')
}

@Entry
@Component
struct StylesDemo {
  build() {
    Column({ space: 10 }) {
      Column() {
        Text('8,432').metricValue()    // @Extend usage
        Text('Steps').fontSize(12).fontColor('#888888')
      }
      .darkCard()                       // @Styles usage

      Button('Start').primaryBtn()
    }
    .width('100%').height('100%').backgroundColor('#000000')
    .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  }
}
```

### @Watch — Listening to State Changes

```typescript
@Entry
@Component
struct WatchDemo {
  @State @Watch('onHeartRateChange') heartRate: number = 0;

  onHeartRateChange(propName: string): void {
    // propName = 'heartRate'
    if (this.heartRate > 120) {
      console.warn(`[Watch] High HR: ${this.heartRate}`);
      // Trigger an alert like vibration
    }
  }

  build() {
    Column() {
      Text(`${this.heartRate} BPM`).fontSize(32).fontColor('#FF4444')
    }
    .width('100%').height('100%').backgroundColor('#000000')
    .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  }
}
```

---

## 2. Core Layout Components

ArkUI layout components determine how elements are positioned on screen.

### Layout Reference Table

| Component | Direction | Key Props | Use Case |
|---|---|---|---|
| `Column` | Vertical | `space`, `alignItems`, `justifyContent` | Vertical list, form |
| `Row` | Horizontal | `space`, `alignItems`, `justifyContent` | Horizontal list, toolbar |
| `Stack` | Overlapping | `alignContent` | Background, overlay |
| `Flex` | Flexible | `direction`, `wrap`, `justifyContent`, `alignItems` | Dynamic layout |
| `List` | Scrollable | `space`, `divider`, `lanes` | Long data lists |
| `Grid` | Grid | `columnsTemplate`, `rowsTemplate`, `columnsGap` | App grid |
| `Scroll` | Scroll | `scrollable`, `scrollBar` | Custom scrolling |
| `Swiper` | Slide | `index`, `autoPlay`, `loop` | Onboarding, pages |

### Column & Row

```typescript
@Entry
@Component
struct ColumnRowDemo {
  build() {
    // Column: vertical
    Column({ space: 12 }) {
      // Row: horizontal
      Row({ space: 8 }) {
        Text('Item 1')
          .fontSize(14).fontColor('#FFFFFF')
          .layoutWeight(1)                // Take equal space
        Text('Item 2')
          .fontSize(14).fontColor('#FFFFFF')
          .layoutWeight(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 8, right: 8 })

      Column({ space: 4 }) {
        Text('Title').fontSize(18).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
        Text('Subtitle').fontSize(13).fontColor('#888888')
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%').backgroundColor('#111111')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .padding(16)
  }
}
```

### List — Scrollable List

```typescript
interface HealthRecord {
  id: number;
  type: string;
  value: string;
  time: string;
}

@Entry
@Component
struct ListDemo {
  @State records: HealthRecord[] = [
    { id: 1, type: 'Steps', value: '8,432', time: '09:00' },
    { id: 2, type: 'HR', value: '72 bpm', time: '09:15' },
    { id: 3, type: 'Calories', value: '342 kcal', time: '10:00' },
    { id: 4, type: 'Distance', value: '6.2 km', time: '11:00' },
    { id: 5, type: 'Sleep', value: '7.5 h', time: '07:30' },
  ];

  build() {
    List({ space: 6 }) {
      ForEach(this.records, (item: HealthRecord) => {
        ListItem() {
          Row() {
            Column() {
              Text(item.type).fontSize(13).fontColor('#888888')
              Text(item.value).fontSize(16).fontColor('#FFFFFF').fontWeight(FontWeight.SemiBold)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text(item.time).fontSize(12).fontColor('#555555')
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#1A1A1A')
          .borderRadius(8)
        }
      }, (item: HealthRecord) => item.id.toString())
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .padding({ left: 8, right: 8, top: 8 })
    .divider({ strokeWidth: 0 })
  }
}
```

### Stack — Overlapping Layers

```typescript
@Entry
@Component
struct StackDemo {
  build() {
    Stack({ alignContent: Alignment.Center }) {
      // Background layer
      Circle({ width: 180, height: 180 })
        .fill('#1A1A2E')

      // Middle layer
      Circle({ width: 160, height: 160 })
        .fill('none')
        .stroke('#0A84FF')
        .strokeWidth(4)

      // Top layer: content
      Column() {
        Text('72').fontSize(48).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
        Text('BPM').fontSize(14).fontColor('#0A84FF')
      }
    }
    .width('100%').height('100%').backgroundColor('#000000')
  }
}
```

### Swiper — Page Swiper

```typescript
@Entry
@Component
struct SwiperDemo {
  @State currentPage: number = 0;
  private pages: string[] = ['Steps', 'Heart', 'Sleep'];

  build() {
    Column() {
      Swiper() {
        ForEach(this.pages, (page: string, index: number) => {
          Column() {
            Text(page)
              .fontSize(20).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
          }
          .width('100%').height(200)
          .backgroundColor(index === 0 ? '#1A3A1A' : index === 1 ? '#3A1A1A' : '#1A1A3A')
          .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
          .borderRadius(16)
        })
      }
      .width('100%')
      .autoPlay(false)
      .loop(false)
      .indicator(
        new DotIndicator()
          .color('#444444')
          .selectedColor('#FFFFFF')
      )
      .onChange((index: number) => {
        this.currentPage = index;
      })
    }
    .width('100%').height('100%').backgroundColor('#000000').padding(12)
  }
}
```

---

## 3. Sensor APIs

`@kit.SensorServiceKit` (or `@ohos.sensor`) provides access to wearable sensors. Each sensor has its own permission and data format.

### Sensor Reference Table

| Sensor ID | Permission | Data Fields | Update Freq |
|---|---|---|---|
| `sensor.SensorId.PEDOMETER` | `ACTIVITY_MOTION` | `steps: number` | Per step |
| `sensor.SensorId.HEART_RATE` | `READ_HEALTH_DATA` | `heartRate: number`, `accuracy: number` | ~1 second |
| `sensor.SensorId.ACCELEROMETER` | None | `x: number`, `y: number`, `z: number` | 100ms - 1s |
| `sensor.SensorId.GYROSCOPE` | None | `x: number`, `y: number`, `z: number` | 100ms - 1s |
| `sensor.SensorId.MAGNETIC_FIELD` | None | `x: number`, `y: number`, `z: number` | 100ms - 1s |
| `sensor.SensorId.BAROMETER` | None | `pressure: number` | 1s |
| `sensor.SensorId.AMBIENT_LIGHT` | None | `intensity: number` | 200ms |
| `sensor.SensorId.ORIENTATION` | None | `alpha: number`, `beta: number`, `gamma: number` | 100ms |
| `sensor.SensorId.PEDOMETER_DETECTION` | `ACTIVITY_MOTION` | `scalar: number` (0 or 1) | On step detect |
| `sensor.SensorId.SIGNIFICANT_MOTION` | `ACTIVITY_MOTION` | `scalar: number` | On motion |

### Import and Basic Usage

```typescript
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

// Interval options:
// 'normal'  = ~200ms  (general use)
// 'ui'      = ~60ms   (UI animations)
// 'game'    = ~20ms   (gaming)
// 'fastest' = device dependent
// Or a number in nanoseconds
```

### PEDOMETER

```typescript
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

// Start
sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
  const steps: number = data.steps;
  console.info(`[Sensor] Steps: ${steps}`);
}, { interval: 'normal' });

// Stop
sensor.off(sensor.SensorId.PEDOMETER);

// One-time reading
sensor.once(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
  console.info(`[Sensor] Current steps: ${data.steps}`);
});
```

### HEART_RATE

```typescript
import { sensor } from '@kit.SensorServiceKit';

sensor.on(sensor.SensorId.HEART_RATE, (data: sensor.HeartRateResponse) => {
  const bpm: number = data.heartRate;
  // accuracy: 0=Unreliable, 1=Low, 2=Medium, 3=High
  const accuracy: number = data.accuracy;
  console.info(`[Sensor] HR: ${bpm} bpm (accuracy: ${accuracy})`);
}, { interval: 'normal' });

sensor.off(sensor.SensorId.HEART_RATE);
```

### ACCELEROMETER

```typescript
import { sensor } from '@kit.SensorServiceKit';

sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
  // in m/s²
  const x: number = data.x;
  const y: number = data.y;
  const z: number = data.z;
  // Total acceleration magnitude
  const magnitude = Math.sqrt(x * x + y * y + z * z);
  console.info(`[Sensor] Accel: ${x.toFixed(2)}, ${y.toFixed(2)}, ${z.toFixed(2)} | Mag: ${magnitude.toFixed(2)}`);
}, { interval: 100000000 }); // 100ms in ns

sensor.off(sensor.SensorId.ACCELEROMETER);
```

### GYROSCOPE

```typescript
import { sensor } from '@kit.SensorServiceKit';

sensor.on(sensor.SensorId.GYROSCOPE, (data: sensor.GyroscopeResponse) => {
  // in rad/s
  const x: number = data.x; // Pitch
  const y: number = data.y; // Roll
  const z: number = data.z; // Yaw
  console.info(`[Sensor] Gyro: pitch=${x.toFixed(3)}, roll=${y.toFixed(3)}, yaw=${z.toFixed(3)}`);
}, { interval: 'game' });

sensor.off(sensor.SensorId.GYROSCOPE);
```

### Sensor Start with Error Handling

```typescript
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

function startSensorSafely(
  sensorId: sensor.SensorId,
  callback: (data: object) => void,
  interval: string | number = 'normal'
): boolean {
  try {
    sensor.on(sensorId, callback, { interval });
    return true;
  } catch (err) {
    const error = err as BusinessError;
    // Common error codes:
    // 14500101 = Sensor not supported on this device
    // 14500102 = Permission denied
    // 14500103 = Sensor is already subscribed
    console.error(`[Sensor] Failed to start sensor ${sensorId}: ${error.code} - ${error.message}`);
    return false;
  }
}

// Usage
startSensorSafely(sensor.SensorId.PEDOMETER, (data) => {
  const pedometerData = data as sensor.PedometerResponse;
  console.info(`Steps: ${pedometerData.steps}`);
});
```

---

## 4. Health Kit APIs

The `@ohos.health` module (Health Kit) provides standardized and secure access to user health data. This data is stored securely on the device.

### Health Kit Data Types

| Data Type | Enum Value | Description |
|---|---|---|
| Step count | `HealthDataType.STEP_COUNT` | Daily step count |
| Calories | `HealthDataType.CALORIES_CONSUMED` | Calories burned |
| Distance | `HealthDataType.DISTANCE` | Distance walked |
| Heart rate | `HealthDataType.HEART_RATE` | Instantaneous heart rate |
| Sleep | `HealthDataType.SLEEP` | Sleep duration and stages |
| SpO2 | `HealthDataType.OXYGEN_SATURATION` | Blood oxygen saturation |
| Stress | `HealthDataType.STRESS` | Stress level |
| Activity | `HealthDataType.EXERCISE` | Exercise sessions |

### Reading Daily Health Data

```typescript
import health from '@ohos.health';
import { BusinessError } from '@kit.BasicServicesKit';

// Read today's step data
async function getTodaySteps(): Promise<number> {
  const today = new Date();
  const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const endOfDay = new Date(startOfDay.getTime() + 86400000 - 1); // 23:59:59

  try {
    const request: health.ReadDataRequest = {
      dataType: health.HealthDataType.STEP_COUNT,
      startTime: startOfDay.getTime(),
      endTime: endOfDay.getTime(),
    };

    const records = await health.readData(request);
    if (records && records.length > 0) {
      const totalSteps = records.reduce((sum, record) => sum + (record.value as number), 0);
      console.info(`[HealthKit] Today's steps: ${totalSteps}`);
      return totalSteps;
    }
    return 0;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[HealthKit] Error: ${error.code} - ${error.message}`);
    return 0;
  }
}

// Read sleep data
async function getLastNightSleep(): Promise<health.SleepRecord | null> {
  const now = Date.now();
  const yesterday = now - 86400000;

  try {
    const request: health.ReadDataRequest = {
      dataType: health.HealthDataType.SLEEP,
      startTime: yesterday,
      endTime: now,
    };

    const records = await health.readData(request);
    if (records && records.length > 0) {
      return records[records.length - 1] as health.SleepRecord;
    }
    return null;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[HealthKit] Sleep read error: ${error.code}`);
    return null;
  }
}

// Write health data
async function writeStepData(steps: number, startTime: number, endTime: number): Promise<void> {
  try {
    const record: health.HealthDataRecord = {
      dataType: health.HealthDataType.STEP_COUNT,
      startTime,
      endTime,
      value: steps,
    };

    await health.writeData([record]);
    console.info(`[HealthKit] Step data written: ${steps} steps`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[HealthKit] Write error: ${error.code} - ${error.message}`);
  }
}
```

### Health Dashboard Component

```typescript
import health from '@ohos.health';

@Entry
@Component
struct HealthDashboard {
  @State steps: number = 0;
  @State heartRate: number = 0;
  @State sleepHours: number = 0;
  @State calories: number = 0;

  aboutToAppear(): void {
    this.loadHealthData();
  }

  async loadHealthData(): Promise<void> {
    const now = Date.now();
    const dayStart = now - (now % 86400000);

    try {
      // Step data
      const stepRecords = await health.readData({
        dataType: health.HealthDataType.STEP_COUNT,
        startTime: dayStart,
        endTime: now,
      });
      if (stepRecords?.length) {
        this.steps = stepRecords.reduce((s, r) => s + (r.value as number), 0);
      }

      // Calorie data
      const calRecords = await health.readData({
        dataType: health.HealthDataType.CALORIES_CONSUMED,
        startTime: dayStart,
        endTime: now,
      });
      if (calRecords?.length) {
        this.calories = Math.round(calRecords.reduce((s, r) => s + (r.value as number), 0));
      }
    } catch (err) {
      console.error('[Dashboard] Failed to load health data');
    }
  }

  build() {
    Column({ space: 8 }) {
      Text('Health').fontSize(18).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 8 })

      Grid() {
        GridItem() {
          this.HealthCard('👟', `${this.steps.toLocaleString()}`, 'Steps', '#4CAF50')
        }
        GridItem() {
          this.HealthCard('❤️', `${this.heartRate}`, 'BPM', '#F44336')
        }
        GridItem() {
          this.HealthCard('🔥', `${this.calories}`, 'kcal', '#FF9800')
        }
        GridItem() {
          this.HealthCard('💤', `${this.sleepHours.toFixed(1)}h`, 'Sleep', '#9C27B0')
        }
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width('100%')
    }
    .width('100%').height('100%').backgroundColor('#000000').padding(12)
  }

  @Builder
  HealthCard(icon: string, value: string, label: string, color: string) {
    Column({ space: 4 }) {
      Text(icon).fontSize(24)
      Text(value).fontSize(20).fontColor(color).fontWeight(FontWeight.Bold)
      Text(label).fontSize(11).fontColor('#888888')
    }
    .width('100%').padding(12)
    .backgroundColor('#1A1A1A').borderRadius(12)
    .alignItems(HorizontalAlign.Center)
  }
}
```

---

## 5. Distributed Data

The `@ohos.distributedKVStore` module provides real-time data sharing between HarmonyOS devices (phone ↔ watch). Distributed data management is the foundation of multi-device experiences.

### Setup

```typescript
import distributedKVStore from '@ohos.data.distributedKVStore';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const STORE_ID = 'WearableHealthStore';

async function createDistributedStore(
  context: common.UIAbilityContext
): Promise<distributedKVStore.SingleKVStore | null> {
  const kvManager = distributedKVStore.createKVManager({
    bundleName: context.applicationInfo.name,
    context: context,
  });

  const options: distributedKVStore.Options = {
    createIfMissing: true,
    encrypt: false,
    backup: false,
    autoSync: true,
    kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
    securityLevel: distributedKVStore.SecurityLevel.S1,
  };

  try {
    const store = await kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options);
    console.info('[KVStore] Store created successfully');
    return store;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[KVStore] Create error: ${error.code} - ${error.message}`);
    return null;
  }
}
```

### Write and Read Data

```typescript
// Write data
async function writeHealthData(store: distributedKVStore.SingleKVStore, steps: number, heartRate: number): Promise<void> {
  try {
    await store.put('currentSteps', steps);
    await store.put('currentHeartRate', heartRate);
    await store.put('lastUpdated', Date.now());
    console.info(`[KVStore] Written: steps=${steps}, hr=${heartRate}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[KVStore] Write error: ${error.code}`);
  }
}

// Read data
async function readHealthData(
  store: distributedKVStore.SingleKVStore
): Promise<{ steps: number; heartRate: number } | null> {
  try {
    const stepsEntry = await store.get('currentSteps');
    const hrEntry = await store.get('currentHeartRate');

    return {
      steps: stepsEntry.value as number,
      heartRate: hrEntry.value as number,
    };
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[KVStore] Read error: ${error.code}`);
    return null;
  }
}
```

### Listening to Changes

```typescript
// Data change listener
function subscribeToChanges(store: distributedKVStore.SingleKVStore, onUpdate: (data: object) => void): void {
  store.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL, (data) => {
    console.info(`[KVStore] Data changed: ${JSON.stringify(data)}`);
    onUpdate(data);
  });
}

// Remove listener
function unsubscribeFromChanges(store: distributedKVStore.SingleKVStore): void {
  store.off('dataChange');
}
```

### Distributed Data Sync

```typescript
// Trigger cross-device sync
async function syncWithDevices(store: distributedKVStore.SingleKVStore): Promise<void> {
  try {
    // If deviceIds is empty, sync with all trusted devices
    await store.sync([], distributedKVStore.SyncMode.PULL_ONLY);
    console.info('[KVStore] Sync triggered');
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[KVStore] Sync error: ${error.code}`);
  }
}
```

---

## 6. Permissions

HarmonyOS applications must both declare the relevant permissions in `module.json5` and request them from the user at runtime before accessing sensitive resources.

### Wearable Permission Reference Table

| Permission | Type | Usage | API |
|---|---|---|---|
| `ohos.permission.ACTIVITY_MOTION` | user_grant | Motion and step sensors | `sensor.PEDOMETER`, `sensor.PEDOMETER_DETECTION`, `sensor.SIGNIFICANT_MOTION` |
| `ohos.permission.READ_HEALTH_DATA` | user_grant | Read health data | `sensor.HEART_RATE`, `health.readData()` |
| `ohos.permission.WRITE_HEALTH_DATA` | user_grant | Write health data | `health.writeData()` |
| `ohos.permission.LOCATION` | user_grant | GPS location | `geoLocationManager` |
| `ohos.permission.APPROXIMATELY_LOCATION` | user_grant | Approximate location | `geoLocationManager` |
| `ohos.permission.DISTRIBUTED_DATASYNC` | user_grant | Distributed data sync | `distributedKVStore` |
| `ohos.permission.VIBRATE` | system_grant | Vibration | `vibrator` |
| `ohos.permission.KEEP_BACKGROUND_RUNNING` | system_grant | Background execution | Background task |
| `ohos.permission.INTERNET` | system_grant | Internet access | HTTP, WebSocket |
| `ohos.permission.NOTIFICATION_CONTROLLER` | system_grant | Notification management | `notificationManager` |

> **Note:** `user_grant` permissions must be requested from the user at runtime; `system_grant` permissions only need to be added to `module.json5`.

### Permission Declaration in module.json5

```json
{
  "module": {
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
      },
      {
        "name": "ohos.permission.VIBRATE"
      },
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

### Runtime Permission Request

```typescript
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

class PermissionManager {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  // Single permission check and request
  async ensurePermission(permission: Permissions): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();

    // First check current status
    try {
      const tokenId = this.context.applicationInfo.accessTokenId;
      const status = await atManager.checkAccessToken(tokenId, permission);

      if (status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true;
      }
    } catch (err) {
      // Token check failed, request permission
    }

    // Request permission from user
    try {
      const result = await atManager.requestPermissionsFromUser(this.context, [permission]);
      return result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[Permission] Request error: ${error.code}`);
      return false;
    }
  }

  // Request multiple permissions at once
  async ensurePermissions(permissions: Permissions[]): Promise<Map<Permissions, boolean>> {
    const atManager = abilityAccessCtrl.createAtManager();
    const result = new Map<Permissions, boolean>();

    try {
      const response = await atManager.requestPermissionsFromUser(this.context, permissions);
      permissions.forEach((perm, index) => {
        result.set(perm, response.authResults[index] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
      });
    } catch (err) {
      permissions.forEach(perm => result.set(perm, false));
    }

    return result;
  }
}
```

---

## 7. Wearable-Specific UI

The HarmonyOS wearable platform offers wearable-specific capabilities such as watch face development, digital crown events, and vibration feedback.

### Crown (Digital Crown) Events

Some smartwatches include a digital crown. You can capture rotation events from this crown.

```typescript
@Entry
@Component
struct CrownEventDemo {
  @State crownValue: number = 0;
  @State scrollOffset: number = 0;

  build() {
    Column() {
      Text(`Crown: ${this.crownValue}`)
        .fontSize(18).fontColor('#FFFFFF')

      Slider({
        value: this.crownValue,
        min: 0,
        max: 100,
        style: SliderStyle.InSet
      })
      .width('80%')
      .selectedColor('#0A84FF')
      .onChange((value: number) => {
        this.crownValue = Math.round(value);
      })
    }
    .width('100%').height('100%').backgroundColor('#000000')
    .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
    // Capture crown events
    .focusable(true)
    .onKeyEvent((event: KeyEvent) => {
      // Crown rotation comes as KeyCode.KEYCODE_VOLUME_UP / KEYCODE_VOLUME_DOWN
      if (event.type === KeyType.Down) {
        if (event.keyCode === 2043) { // KEYCODE_VOLUME_UP / Crown clockwise
          this.crownValue = Math.min(100, this.crownValue + 2);
        } else if (event.keyCode === 2044) { // KEYCODE_VOLUME_DOWN / Crown counter-clockwise
          this.crownValue = Math.max(0, this.crownValue - 2);
        }
      }
    })
  }
}
```

### Vibration API

The `@ohos.vibrator` module provides haptic feedback on wearable devices. Requires the `ohos.permission.VIBRATE` permission.

```typescript
import vibrator from '@ohos.vibrator';
import { BusinessError } from '@kit.BasicServicesKit';

// Predefined effects
async function vibrateEffect(effect: string = 'haptic.clock.timer'): Promise<void> {
  try {
    await vibrator.startVibration({
      type: 'preset',
      effectId: effect,
      // Common effects:
      // 'haptic.clock.timer'     — clock tick
      // 'haptic.long_press.light' — light long press
      // 'haptic.long_press.medium' — medium long press
      count: 1,
    }, {
      usage: 'touch', // 'touch' | 'alarm' | 'notification' | 'communication' | 'unknown'
    });
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[Vibrator] Effect error: ${error.code}`);
  }
}

// Custom vibration pattern
async function vibratePattern(pattern: number[]): Promise<void> {
  // pattern: [wait, vibrate, wait, vibrate, ...] in ms
  try {
    await vibrator.startVibration({
      type: 'time',
      duration: pattern.reduce((sum, val) => sum + val, 0),
    }, {
      usage: 'notification',
    });
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[Vibrator] Pattern error: ${error.code}`);
  }
}

// Stop vibration
async function stopVibration(): Promise<void> {
  try {
    await vibrator.stopVibration();
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[Vibrator] Stop error: ${error.code}`);
  }
}

// Usage examples
async function demonstrateVibration(): Promise<void> {
  // Success vibration
  await vibrateEffect('haptic.clock.timer');

  // Warning vibration (3 short)
  for (let i = 0; i < 3; i++) {
    await vibrator.startVibration({ type: 'time', duration: 100 }, { usage: 'alarm' });
    await new Promise(resolve => setTimeout(resolve, 200));
  }
}
```

### Watch Face Development Basics

Custom watch faces are developed as Service Widgets using the `@ohos.app.form` module. For custom watch faces on wearables, `formType: watchface` is required.

```typescript
// Basic ArkUI template for watch face
@Entry
@Component
struct WatchFaceTemplate {
  @State hours: number = new Date().getHours() % 12;
  @State minutes: number = new Date().getMinutes();
  @State seconds: number = new Date().getSeconds();
  @State dateString: string = '';
  private timer: number = -1;

  aboutToAppear(): void {
    this.updateTime();
    this.timer = setInterval(() => {
      this.updateTime();
    }, 1000);
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) clearInterval(this.timer);
  }

  updateTime(): void {
    const now = new Date();
    this.hours = now.getHours() % 12;
    this.minutes = now.getMinutes();
    this.seconds = now.getSeconds();
    this.dateString = now.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric'
    });
  }

  formatTime(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // Background
      Circle({ width: '100%', height: '100%' }).fill('#0A0A0A')

      // Watch bezel
      Circle({ width: '95%', height: '95%' })
        .fill('none')
        .stroke('#333333')
        .strokeWidth(2)

      // Time and date
      Column({ space: 4 }) {
        Text(`${this.formatTime(this.hours)}:${this.formatTime(this.minutes)}`)
          .fontSize(52)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Light)
          .fontFamily('HarmonyOS Sans')

        Text(`:${this.formatTime(this.seconds)}`)
          .fontSize(20)
          .fontColor('#888888')
          .margin({ top: -8 })

        Text(this.dateString)
          .fontSize(13)
          .fontColor('#AAAAAA')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%')
  }
}
```

---

## 8. Lifecycle

The HarmonyOS Stage model manages the lifecycle of applications and components. Using the correct lifecycle methods prevents memory leaks and sensors being left on.

### UIAbility Lifecycle

| Method | Trigger | Use Case |
|---|---|---|
| `onCreate(want, launchParam)` | First launch | Load initial data, initialize resources |
| `onWindowStageCreate(stage)` | Window ready | Load UI (`loadContent`), set up event listeners |
| `onForeground()` | Came to foreground | Start sensors, start timers |
| `onBackground()` | Went to background | Stop sensors, cancel UI timers |
| `onWindowStageDestroy()` | Window closed | Release window resources |
| `onDestroy()` | App closed | Clean up all resources, save data |

```typescript
import { UIAbility, Want, AbilityConstant, window } from '@kit.AbilityKit';
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0xFF00;
const TAG = 'WearableAbility';

export default class EntryAbility extends UIAbility {
  private sensorStarted: boolean = false;

  // When UIAbility is created for the first time
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate');
    // Application initialization tasks
    // - Database connection
    // - Load app settings
    // - Analytics initialization
  }

  // When window is created
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageCreate');

    // Load main page
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, `loadContent failed: ${err.code}`);
        return;
      }
      hilog.info(DOMAIN, TAG, 'loadContent succeeded');
    });
  }

  // When app comes to foreground
  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'onForeground');

    if (!this.sensorStarted) {
      this.startBackgroundSensors();
      this.sensorStarted = true;
    }
  }

  // When app goes to background
  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground');

    // Stop sensors only used for UI updates
    // Note: Ongoing sensors like health tracking may continue in background
    this.stopUISensors();
  }

  // When window is destroyed
  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
    // Remove window event listeners
  }

  // When UIAbility is destroyed
  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');

    // Stop all sensors
    this.stopAllSensors();

    // Save data
    // Close connections
  }

  private startBackgroundSensors(): void {
    try {
      sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
        hilog.info(DOMAIN, TAG, `Steps: ${data.steps}`);
      }, { interval: 'normal' });
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, `Sensor start failed: ${error.code}`);
    }
  }

  private stopUISensors(): void {
    // Stop continuous UI-oriented updates
  }

  private stopAllSensors(): void {
    try {
      sensor.off(sensor.SensorId.PEDOMETER);
      sensor.off(sensor.SensorId.HEART_RATE);
      sensor.off(sensor.SensorId.ACCELEROMETER);
      sensor.off(sensor.SensorId.GYROSCOPE);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Error stopping sensors');
    }
  }
}
```

### Component Lifecycle

`@Component` components also have their own lifecycle methods:

| Method | Description |
|---|---|
| `aboutToAppear()` | Before component is created, before `build()` |
| `aboutToDisappear()` | Before component is destroyed |
| `onPageShow()` | When page becomes visible (`@Entry` only) |
| `onPageHide()` | When page is hidden (`@Entry` only) |
| `onBackPress()` | When back button is pressed (`@Entry` only) |

```typescript
@Entry
@Component
struct LifecycleDemo {
  @State data: string[] = [];
  private sensorActive: boolean = false;

  // Load data before component is created
  aboutToAppear(): void {
    console.info('[Lifecycle] aboutToAppear — Starting sensors');
    this.loadInitialData();
    this.startSensors();
    this.sensorActive = true;
  }

  // Clean up before component is destroyed
  aboutToDisappear(): void {
    console.info('[Lifecycle] aboutToDisappear — Cleaning up');
    if (this.sensorActive) {
      sensor.off(sensor.SensorId.PEDOMETER);
      sensor.off(sensor.SensorId.HEART_RATE);
      this.sensorActive = false;
    }
  }

  // When page is visible (also triggered on navigation back)
  onPageShow(): void {
    console.info('[Lifecycle] onPageShow');
    // Refresh data
  }

  // When page is hidden
  onPageHide(): void {
    console.info('[Lifecycle] onPageHide');
    // Stop animations
  }

  // Customize back button
  onBackPress(): boolean {
    console.info('[Lifecycle] onBackPress');
    // Returning true prevents default back behavior
    return false; // false = default behavior
  }

  private async loadInitialData(): Promise<void> {
    // Load initial data
    this.data = ['Loading...'];
  }

  private startSensors(): void {
    sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
      console.info(`Steps: ${data.steps}`);
    }, { interval: 'normal' });
  }

  build() {
    Column() {
      Text('Lifecycle Demo').fontSize(18).fontColor('#FFFFFF')
    }
    .width('100%').height('100%').backgroundColor('#000000')
    .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  }
}
```

---

## Quick Reference

### Commonly Used Imports

```typescript
// Sensors
import { sensor } from '@kit.SensorServiceKit';

// Health
import health from '@ohos.health';

// Distributed data
import distributedKVStore from '@ohos.data.distributedKVStore';

// Permission management
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

// Vibration
import vibrator from '@ohos.vibrator';

// Error type
import { BusinessError } from '@kit.BasicServicesKit';

// Logging
import { hilog } from '@kit.PerformanceAnalysisKit';

// Preferences
import dataPreferences from '@ohos.data.preferences';

// HTTP / Network
import http from '@ohos.net.http';
```

### Sensor Interval Values

| Option | Nanoseconds | Use Case |
|---|---|---|
| `'fastest'` | Device minimum | Real-time gaming |
| `'game'` | ~20,000,000 ns (20ms) | Motion tracking |
| `'ui'` | ~60,000,000 ns (60ms) | UI animations |
| `'normal'` | ~200,000,000 ns (200ms) | General use |
| `1000000000` | 1,000,000,000 ns (1s) | Health monitoring |

---

*Last updated: March 2026 | HarmonyOS API Level 11+ | DevEco Studio 4.1+*
