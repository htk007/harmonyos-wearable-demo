# HarmonyOS Wearable API Cheatsheet

> **TR:** Bu cheatsheet, HarmonyOS wearable uygulama geliştirirken en sık kullanılan API'leri, dekoratörleri ve bileşenleri hızlı referans için derler.
>
> **EN:** This cheatsheet compiles the most commonly used APIs, decorators, and components for HarmonyOS wearable development as a quick reference.

---

## İçindekiler / Table of Contents

1. [ArkUI Dekoratörler / ArkUI Decorators](#1-arkui-dekoratörler--arkui-decorators)
2. [Temel Layout Bileşenleri / Core Layout Components](#2-temel-layout-bileşenleri--core-layout-components)
3. [Sensör API'leri / Sensor APIs](#3-sensör-apileri--sensor-apis)
4. [Health Kit API'leri / Health Kit APIs](#4-health-kit-apileri--health-kit-apis)
5. [Distributed Data / Dağıtık Veri](#5-distributed-data--dağıtık-veri)
6. [İzinler / Permissions](#6-i̇zinler--permissions)
7. [Wearable-Özel UI / Wearable-Specific UI](#7-wearable-özel-ui--wearable-specific-ui)
8. [Lifecycle / Yaşam Döngüsü](#8-lifecycle--yaşam-döngüsü)

---

## 1. ArkUI Dekoratörler / ArkUI Decorators

**TR:** ArkUI dekoratörleri, bileşen davranışını ve state yönetimini tanımlar. Doğru dekoratörü seçmek, reaktif ve verimli UI geliştirmenin temelidir.

**EN:** ArkUI decorators define component behavior and state management. Choosing the right decorator is fundamental to reactive and efficient UI development.

### Dekoratör Referans Tablosu / Decorator Reference Table

| Dekoratör / Decorator | Kapsam / Scope | Açıklama (TR) | Description (EN) |
|---|---|---|---|
| `@Entry` | Sayfa / Page | Bir ArkTS dosyasında tek giriş noktası | Single entry point in an ArkTS file |
| `@Component` | Struct | Yeniden kullanılabilir UI bileşeni tanımlar | Defines a reusable UI component |
| `@State` | Bileşen / Component | Bileşene özel reaktif state; değişince UI güncellenir | Component-local reactive state; UI updates on change |
| `@Prop` | Bileşen / Component | Ebeveynden tek yönlü veri akışı (salt okunur kopya) | One-way data flow from parent (read-only copy) |
| `@Link` | Bileşen / Component | Ebeveyn ile çift yönlü bağ | Two-way binding with parent |
| `@Observed` + `@ObjectLink` | Nesne / Object | Karmaşık nesne değişikliklerini izler | Tracks changes in complex objects |
| `@Provide` + `@Consume` | Ağaç / Tree | Derinlemesine bileşen ağacı arasında veri paylaşımı | Share data deep across the component tree |
| `@Builder` | Fonksiyon / Function | Tekrar kullanılabilir UI blokları tanımlar | Defines reusable UI blocks |
| `@Styles` | Stil / Style | Ortak stil özelliklerini gruplar | Groups common style properties |
| `@Extend` | Stil / Style | Mevcut bileşen stillerini genişletir | Extends existing component styles |
| `@Watch` | State | State değişikliğini dinler | Listens to state changes |
| `@StorageLink` | Uygulama / App | AppStorage ile iki yönlü bağ | Two-way binding with AppStorage |
| `@LocalStorageLink` | Sayfa / Page | LocalStorage ile iki yönlü bağ | Two-way binding with LocalStorage |

### @State — Bileşen İçi State

```typescript
@Entry
@Component
struct StateDemo {
  // Primitive state / İlkel state
  @State count: number = 0;
  @State label: string = 'Merhaba / Hello';
  @State isVisible: boolean = true;

  // Nesne state'i — nesne referansı değişmeli / Object state — object reference must change
  @State userInfo: { name: string; age: number } = { name: 'Ali', age: 28 };

  // Dizi state'i / Array state
  @State items: string[] = ['Item 1', 'Item 2'];

  build() {
    Column({ space: 8 }) {
      Text(`Count: ${this.count}`).fontSize(16).fontColor('#FFFFFF')
      Button('Artır / Increment')
        .onClick(() => { this.count++; })
        .height(44)

      // Nesneyi güncellemek için yeni referans ata
      // Assign a new reference to update an object
      Button('Güncelle / Update User')
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

### @Prop ve @Link — Ebeveyn-Çocuk İletişimi / Parent-Child Communication

```typescript
// Çocuk bileşeni / Child component
@Component
struct ChildProp {
  @Prop value: number = 0;           // Tek yönlü / One-way
  @Link sharedValue: number;         // Çift yönlü / Two-way

  build() {
    Column({ space: 6 }) {
      Text(`Prop (tek yön): ${this.value}`).fontColor('#AAAAAA').fontSize(13)
      Text(`Link (çift yön): ${this.sharedValue}`).fontColor('#4CAF50').fontSize(13)
      Button('Link\'i Artır / Increment Link')
        .height(36).fontSize(12)
        .onClick(() => { this.sharedValue++; }) // Ebeveyni de günceller / Also updates parent
    }
  }
}

// Ebeveyn bileşeni / Parent component
@Entry
@Component
struct ParentComponent {
  @State parentCount: number = 10;
  @State sharedCount: number = 0;

  build() {
    Column({ space: 10 }) {
      Text(`Ebeveyn / Parent: ${this.parentCount}`).fontColor('#FFFFFF').fontSize(16)
      Text(`Paylaşılan / Shared: ${this.sharedCount}`).fontColor('#FFFFFF').fontSize(16)

      ChildProp({
        value: this.parentCount,
        sharedValue: $sharedCount   // $ ile referans geçir / Pass by reference with $
      })
    }
    .width('100%').height('100%').backgroundColor('#111111')
    .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  }
}
```

### @Builder — Yeniden Kullanılabilir UI Blokları / Reusable UI Blocks

```typescript
@Entry
@Component
struct BuilderDemo {
  @State heartRate: number = 72;
  @State steps: number = 6500;

  // Bileşen içi @Builder / Component-scoped @Builder
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
      this.MetricCard('❤️', 'Kalp Atışı / HR', `${this.heartRate} bpm`, '#F44336')
      this.MetricCard('👟', 'Adım / Steps', `${this.steps}`, '#4CAF50')
    }
    .width('100%').height('100%').backgroundColor('#0A0A0A')
    .padding(16)
    .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  }
}
```

### @Styles ve @Extend

```typescript
// @Styles — stil grupları / style groups
@Styles
function darkCard() {
  .backgroundColor('#1E1E1E')
  .borderRadius(12)
  .padding(12)
}

// @Extend — bileşen stillerini genişletme / extending component styles
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
        Text('8,432').metricValue()    // @Extend kullanımı / @Extend usage
        Text('Adım / Steps').fontSize(12).fontColor('#888888')
      }
      .darkCard()                       // @Styles kullanımı / @Styles usage

      Button('Başlat / Start').primaryBtn()
    }
    .width('100%').height('100%').backgroundColor('#000000')
    .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  }
}
```

### @Watch — State Değişikliğini Dinleme / Listening to State Changes

```typescript
@Entry
@Component
struct WatchDemo {
  @State @Watch('onHeartRateChange') heartRate: number = 0;

  onHeartRateChange(propName: string): void {
    // propName = 'heartRate'
    if (this.heartRate > 120) {
      console.warn(`[Watch] Yüksek nabız / High HR: ${this.heartRate}`);
      // Titreşim gibi bir uyarı tetikle / Trigger an alert like vibration
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

## 2. Temel Layout Bileşenleri / Core Layout Components

**TR:** ArkUI layout bileşenleri, ekranda öğelerin nasıl konumlandırıldığını belirler.

**EN:** ArkUI layout components determine how elements are positioned on screen.

### Layout Referans Tablosu / Layout Reference Table

| Bileşen / Component | Yön / Direction | Temel Özellikler / Key Props | Kullanım / Use Case |
|---|---|---|---|
| `Column` | Dikey / Vertical | `space`, `alignItems`, `justifyContent` | Dikey liste, form / Vertical list, form |
| `Row` | Yatay / Horizontal | `space`, `alignItems`, `justifyContent` | Yatay liste, toolbar / Horizontal list, toolbar |
| `Stack` | Üst üste / Overlapping | `alignContent` | Arka plan, overlay / Background, overlay |
| `Flex` | Esnek / Flexible | `direction`, `wrap`, `justifyContent`, `alignItems` | Dinamik düzen / Dynamic layout |
| `List` | Kaydırılabilir / Scrollable | `space`, `divider`, `lanes` | Uzun veri listeleri / Long data lists |
| `Grid` | Izgara / Grid | `columnsTemplate`, `rowsTemplate`, `columnsGap` | Uygulama ızgarası / App grid |
| `Scroll` | Kaydırma / Scroll | `scrollable`, `scrollBar` | Özel kaydırma / Custom scrolling |
| `Swiper` | Slayt / Slide | `index`, `autoPlay`, `loop` | Onboarding, sayfalar / Onboarding, pages |

### Column & Row

```typescript
@Entry
@Component
struct ColumnRowDemo {
  build() {
    // Column: dikey / vertical
    Column({ space: 12 }) {
      // Row: yatay / horizontal
      Row({ space: 8 }) {
        Text('Öğe 1 / Item 1')
          .fontSize(14).fontColor('#FFFFFF')
          .layoutWeight(1)                // Eşit alan kapla / Take equal space
        Text('Öğe 2 / Item 2')
          .fontSize(14).fontColor('#FFFFFF')
          .layoutWeight(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 8, right: 8 })

      Column({ space: 4 }) {
        Text('Başlık / Title').fontSize(18).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
        Text('Alt başlık / Subtitle').fontSize(13).fontColor('#888888')
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

### List — Kaydırılabilir Liste / Scrollable List

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
    { id: 1, type: 'Adım / Steps', value: '8,432', time: '09:00' },
    { id: 2, type: 'Kalp / HR', value: '72 bpm', time: '09:15' },
    { id: 3, type: 'Kalori / Cal', value: '342 kcal', time: '10:00' },
    { id: 4, type: 'Mesafe / Dist', value: '6.2 km', time: '11:00' },
    { id: 5, type: 'Uyku / Sleep', value: '7.5 saat / h', time: '07:30' },
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

### Stack — Üst Üste Katmanlar / Overlapping Layers

```typescript
@Entry
@Component
struct StackDemo {
  build() {
    Stack({ alignContent: Alignment.Center }) {
      // Arka plan katmanı / Background layer
      Circle({ width: 180, height: 180 })
        .fill('#1A1A2E')

      // Orta katman / Middle layer
      Circle({ width: 160, height: 160 })
        .fill('none')
        .stroke('#0A84FF')
        .strokeWidth(4)

      // Üst katman: içerik / Top layer: content
      Column() {
        Text('72').fontSize(48).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
        Text('BPM').fontSize(14).fontColor('#0A84FF')
      }
    }
    .width('100%').height('100%').backgroundColor('#000000')
  }
}
```

### Swiper — Sayfa Kaydırma / Page Swiper

```typescript
@Entry
@Component
struct SwiperDemo {
  @State currentPage: number = 0;
  private pages: string[] = ['Adım / Steps', 'Kalp / Heart', 'Uyku / Sleep'];

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

## 3. Sensör API'leri / Sensor APIs

**TR:** `@kit.SensorServiceKit` (veya `@ohos.sensor`) wearable sensörlerine erişim sağlar. Her sensörün kendi izni ve veri formatı vardır.

**EN:** `@kit.SensorServiceKit` (or `@ohos.sensor`) provides access to wearable sensors. Each sensor has its own permission and data format.

### Sensör Referans Tablosu / Sensor Reference Table

| Sensör ID | İzin / Permission | Veri Alanları / Data Fields | Güncelleme Sıklığı / Update Freq |
|---|---|---|---|
| `sensor.SensorId.PEDOMETER` | `ACTIVITY_MOTION` | `steps: number` | Adım başı / Per step |
| `sensor.SensorId.HEART_RATE` | `READ_HEALTH_DATA` | `heartRate: number`, `accuracy: number` | ~1 saniye / ~1 second |
| `sensor.SensorId.ACCELEROMETER` | Yok / None | `x: number`, `y: number`, `z: number` | 100ms - 1s |
| `sensor.SensorId.GYROSCOPE` | Yok / None | `x: number`, `y: number`, `z: number` | 100ms - 1s |
| `sensor.SensorId.MAGNETIC_FIELD` | Yok / None | `x: number`, `y: number`, `z: number` | 100ms - 1s |
| `sensor.SensorId.BAROMETER` | Yok / None | `pressure: number` | 1s |
| `sensor.SensorId.AMBIENT_LIGHT` | Yok / None | `intensity: number` | 200ms |
| `sensor.SensorId.ORIENTATION` | Yok / None | `alpha: number`, `beta: number`, `gamma: number` | 100ms |
| `sensor.SensorId.PEDOMETER_DETECTION` | `ACTIVITY_MOTION` | `scalar: number` (0 veya 1) | Adım algılandığında / On step detect |
| `sensor.SensorId.SIGNIFICANT_MOTION` | `ACTIVITY_MOTION` | `scalar: number` | Hareket algılandığında / On motion |

### Import ve Temel Kullanım / Import and Basic Usage

```typescript
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

// Interval seçenekleri / Interval options:
// 'normal'  = ~200ms  (genel kullanım / general use)
// 'ui'      = ~60ms   (UI animasyonları / UI animations)
// 'game'    = ~20ms   (oyun / gaming)
// 'fastest' = cihaza bağlı / device dependent
// Ya da nanosaniye cinsinden sayı / Or a number in nanoseconds
```

### PEDOMETER

```typescript
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

// Başlat / Start
sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
  const steps: number = data.steps;
  console.info(`[Sensor] Steps: ${steps}`);
}, { interval: 'normal' });

// Durdur / Stop
sensor.off(sensor.SensorId.PEDOMETER);

// Tek seferlik okuma / One-time reading
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
  // m/s² cinsinden / in m/s²
  const x: number = data.x;
  const y: number = data.y;
  const z: number = data.z;
  // Toplam ivme büyüklüğü / Total acceleration magnitude
  const magnitude = Math.sqrt(x * x + y * y + z * z);
  console.info(`[Sensor] Accel: ${x.toFixed(2)}, ${y.toFixed(2)}, ${z.toFixed(2)} | Mag: ${magnitude.toFixed(2)}`);
}, { interval: 100000000 }); // 100ms in ns

sensor.off(sensor.SensorId.ACCELEROMETER);
```

### GYROSCOPE

```typescript
import { sensor } from '@kit.SensorServiceKit';

sensor.on(sensor.SensorId.GYROSCOPE, (data: sensor.GyroscopeResponse) => {
  // rad/s cinsinden / in rad/s
  const x: number = data.x; // Pitch
  const y: number = data.y; // Roll
  const z: number = data.z; // Yaw
  console.info(`[Sensor] Gyro: pitch=${x.toFixed(3)}, roll=${y.toFixed(3)}, yaw=${z.toFixed(3)}`);
}, { interval: 'game' });

sensor.off(sensor.SensorId.GYROSCOPE);
```

### Hata Yönetimi ile Sensör Başlatma / Sensor Start with Error Handling

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
    // Yaygın hata kodları / Common error codes:
    // 14500101 = Sensor not supported on this device
    // 14500102 = Permission denied
    // 14500103 = Sensor is already subscribed
    console.error(`[Sensor] Failed to start sensor ${sensorId}: ${error.code} - ${error.message}`);
    return false;
  }
}

// Kullanım / Usage
startSensorSafely(sensor.SensorId.PEDOMETER, (data) => {
  const pedometerData = data as sensor.PedometerResponse;
  console.info(`Steps: ${pedometerData.steps}`);
});
```

---

## 4. Health Kit API'leri / Health Kit APIs

**TR:** `@ohos.health` modülü (Health Kit), kullanıcının sağlık verilerine standart ve güvenli bir şekilde erişim sağlar. Bu veriler cihaz üzerinde güvenli biçimde saklanır.

**EN:** The `@ohos.health` module (Health Kit) provides standardized and secure access to user health data. This data is stored securely on the device.

### Health Kit Veri Tipleri / Health Kit Data Types

| Veri Tipi / Data Type | Enum Değeri / Enum Value | Açıklama (TR) | Description (EN) |
|---|---|---|---|
| Adım sayısı | `HealthDataType.STEP_COUNT` | Günlük adım sayısı | Daily step count |
| Kalori | `HealthDataType.CALORIES_CONSUMED` | Harcanan kalori | Calories burned |
| Mesafe | `HealthDataType.DISTANCE` | Yürünen mesafe | Distance walked |
| Kalp atışı | `HealthDataType.HEART_RATE` | Anlık nabız | Instantaneous heart rate |
| Uyku | `HealthDataType.SLEEP` | Uyku süresi ve aşamaları | Sleep duration and stages |
| SpO2 | `HealthDataType.OXYGEN_SATURATION` | Kan oksijen saturasyonu | Blood oxygen saturation |
| Stres | `HealthDataType.STRESS` | Stres seviyesi | Stress level |
| Aktivite | `HealthDataType.EXERCISE` | Egzersiz oturumları | Exercise sessions |

### Günlük Sağlık Verisi Okuma / Reading Daily Health Data

```typescript
import health from '@ohos.health';
import { BusinessError } from '@kit.BasicServicesKit';

// Bugünün adım verisini oku / Read today's step data
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

// Uyku verisini oku / Read sleep data
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

// Health data yaz / Write health data
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

### Health Dashboard Bileşeni / Health Dashboard Component

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
      // Adım verisi / Step data
      const stepRecords = await health.readData({
        dataType: health.HealthDataType.STEP_COUNT,
        startTime: dayStart,
        endTime: now,
      });
      if (stepRecords?.length) {
        this.steps = stepRecords.reduce((s, r) => s + (r.value as number), 0);
      }

      // Kalori verisi / Calorie data
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
      Text('Sağlık / Health').fontSize(18).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 8 })

      Grid() {
        GridItem() {
          this.HealthCard('👟', `${this.steps.toLocaleString()}`, 'Adım / Steps', '#4CAF50')
        }
        GridItem() {
          this.HealthCard('❤️', `${this.heartRate}`, 'BPM', '#F44336')
        }
        GridItem() {
          this.HealthCard('🔥', `${this.calories}`, 'kcal', '#FF9800')
        }
        GridItem() {
          this.HealthCard('💤', `${this.sleepHours.toFixed(1)}h`, 'Uyku / Sleep', '#9C27B0')
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

## 5. Distributed Data / Dağıtık Veri

**TR:** `@ohos.distributedKVStore` modülü, HarmonyOS cihazları arasında (telefon ↔ saat) gerçek zamanlı veri paylaşımı sağlar. Dağıtık veri yönetimi, çoklu cihaz deneyiminin temelini oluşturur.

**EN:** The `@ohos.distributedKVStore` module provides real-time data sharing between HarmonyOS devices (phone ↔ watch). Distributed data management is the foundation of multi-device experiences.

### Kurulum / Setup

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

### Veri Yazma ve Okuma / Write and Read Data

```typescript
// Veri yaz / Write data
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

// Veri oku / Read data
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

### Değişiklikleri Dinleme / Listening to Changes

```typescript
// Veri değişikliği dinleyicisi / Data change listener
function subscribeToChanges(store: distributedKVStore.SingleKVStore, onUpdate: (data: object) => void): void {
  store.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL, (data) => {
    console.info(`[KVStore] Data changed: ${JSON.stringify(data)}`);
    onUpdate(data);
  });
}

// Dinleyiciyi kaldır / Remove listener
function unsubscribeFromChanges(store: distributedKVStore.SingleKVStore): void {
  store.off('dataChange');
}
```

### Dağıtık Veri Senkronizasyonu / Distributed Data Sync

```typescript
// Cihazlar arası senkronizasyon tetikle / Trigger cross-device sync
async function syncWithDevices(store: distributedKVStore.SingleKVStore): Promise<void> {
  try {
    // deviceIds boş bırakılırsa tüm güvenilir cihazlar ile senkronize edilir
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

## 6. İzinler / Permissions

**TR:** HarmonyOS uygulamaları, hassas kaynaklara erişmeden önce ilgili izinleri hem `module.json5`'te bildirmeli, hem de çalışma zamanında kullanıcıdan istemelidir.

**EN:** HarmonyOS applications must both declare the relevant permissions in `module.json5` and request them from the user at runtime before accessing sensitive resources.

### Wearable İzin Referans Tablosu / Wearable Permission Reference Table

| İzin / Permission | Tür / Type | Kullanım / Usage | API |
|---|---|---|---|
| `ohos.permission.ACTIVITY_MOTION` | user_grant | Hareket ve adım sensörleri | `sensor.PEDOMETER`, `sensor.PEDOMETER_DETECTION`, `sensor.SIGNIFICANT_MOTION` |
| `ohos.permission.READ_HEALTH_DATA` | user_grant | Sağlık verisi okuma | `sensor.HEART_RATE`, `health.readData()` |
| `ohos.permission.WRITE_HEALTH_DATA` | user_grant | Sağlık verisi yazma | `health.writeData()` |
| `ohos.permission.LOCATION` | user_grant | GPS konumu | `geoLocationManager` |
| `ohos.permission.APPROXIMATELY_LOCATION` | user_grant | Yaklaşık konum | `geoLocationManager` |
| `ohos.permission.DISTRIBUTED_DATASYNC` | user_grant | Dağıtık veri senkronizasyonu | `distributedKVStore` |
| `ohos.permission.VIBRATE` | system_grant | Titreşim | `vibrator` |
| `ohos.permission.KEEP_BACKGROUND_RUNNING` | system_grant | Arka plan çalışma | Background task |
| `ohos.permission.INTERNET` | system_grant | İnternet erişimi | HTTP, WebSocket |
| `ohos.permission.NOTIFICATION_CONTROLLER` | system_grant | Bildirim yönetimi | `notificationManager` |

> **TR Notu:** `user_grant` izinleri çalışma zamanında kullanıcıdan istenmeli; `system_grant` izinleri yalnızca `module.json5`'e eklenmesi yeterlidir.
>
> **EN Note:** `user_grant` permissions must be requested from the user at runtime; `system_grant` permissions only need to be added to `module.json5`.

### module.json5'te İzin Bildirimi / Permission Declaration in module.json5

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

### Çalışma Zamanı İzin İsteme / Runtime Permission Request

```typescript
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

class PermissionManager {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  // Tek izin kontrol ve istek / Single permission check and request
  async ensurePermission(permission: Permissions): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();

    // Önce mevcut durumu kontrol et / First check current status
    try {
      const tokenId = this.context.applicationInfo.accessTokenId;
      const status = await atManager.checkAccessToken(tokenId, permission);

      if (status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true;
      }
    } catch (err) {
      // Token kontrolü başarısız, izni iste / Token check failed, request permission
    }

    // İzni kullanıcıdan iste / Request permission from user
    try {
      const result = await atManager.requestPermissionsFromUser(this.context, [permission]);
      return result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[Permission] Request error: ${error.code}`);
      return false;
    }
  }

  // Birden fazla izni toplu iste / Request multiple permissions at once
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

## 7. Wearable-Özel UI / Wearable-Specific UI

**TR:** HarmonyOS wearable platformu, saat kadranı geliştirme, dijital taç (crown) olayları ve titreşim geri bildirimi gibi wearable'a özgü yetenekler sunar.

**EN:** The HarmonyOS wearable platform offers wearable-specific capabilities such as watch face development, digital crown events, and vibration feedback.

### Crown (Dijital Taç) Olayları / Crown (Digital Crown) Events

**TR:** Bazı akıllı saatler dijital taç içerir. Bu taçtan gelen dönme olaylarını yakalayabilirsiniz.

**EN:** Some smartwatches include a digital crown. You can capture rotation events from this crown.

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
    // Crown olaylarını yakala / Capture crown events
    .focusable(true)
    .onKeyEvent((event: KeyEvent) => {
      // Crown dönüşü KeyCode.KEYCODE_VOLUME_UP / KEYCODE_VOLUME_DOWN olarak gelir
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

### Titreşim API / Vibration API

**TR:** `@ohos.vibrator` modülü, wearable cihazda haptic geri bildirim sağlar. `ohos.permission.VIBRATE` izni gerektirir.

**EN:** The `@ohos.vibrator` module provides haptic feedback on wearable devices. Requires the `ohos.permission.VIBRATE` permission.

```typescript
import vibrator from '@ohos.vibrator';
import { BusinessError } from '@kit.BasicServicesKit';

// Önceden tanımlı efektler / Predefined effects
async function vibrateEffect(effect: string = 'haptic.clock.timer'): Promise<void> {
  try {
    await vibrator.startVibration({
      type: 'preset',
      effectId: effect,
      // Yaygın efektler / Common effects:
      // 'haptic.clock.timer'     — saat tıklaması / clock tick
      // 'haptic.long_press.light' — hafif uzun basış / light long press
      // 'haptic.long_press.medium' — orta uzun basış / medium long press
      count: 1,
    }, {
      usage: 'touch', // 'touch' | 'alarm' | 'notification' | 'communication' | 'unknown'
    });
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[Vibrator] Effect error: ${error.code}`);
  }
}

// Özel titreşim deseni / Custom vibration pattern
async function vibratePattern(pattern: number[]): Promise<void> {
  // pattern: [bekle, titrет, bekle, titret, ...] ms cinsinden
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

// Titreşimi durdur / Stop vibration
async function stopVibration(): Promise<void> {
  try {
    await vibrator.stopVibration();
  } catch (err) {
    const error = err as BusinessError;
    console.error(`[Vibrator] Stop error: ${error.code}`);
  }
}

// Kullanım örnekleri / Usage examples
async function demonstrateVibration(): Promise<void> {
  // Başarı titreşimi / Success vibration
  await vibrateEffect('haptic.clock.timer');

  // Uyarı titreşimi (3 kısa) / Warning vibration (3 short)
  for (let i = 0; i < 3; i++) {
    await vibrator.startVibration({ type: 'time', duration: 100 }, { usage: 'alarm' });
    await new Promise(resolve => setTimeout(resolve, 200));
  }
}
```

### Watch Face Geliştirme Temelleri / Watch Face Development Basics

**TR:** Özel saat kadranları `@ohos.app.form` modülü ile Service Widget olarak geliştirilir. Wearable'da özel watch face için `formType: watchface` olmalıdır.

**EN:** Custom watch faces are developed as Service Widgets using the `@ohos.app.form` module. For custom watch faces on wearables, `formType: watchface` is required.

```typescript
// Watch face için temel ArkUI şablonu / Basic ArkUI template for watch face
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
    this.dateString = now.toLocaleDateString('tr-TR', {
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
      // Arka plan / Background
      Circle({ width: '100%', height: '100%' }).fill('#0A0A0A')

      // Saat çerçevesi / Watch bezel
      Circle({ width: '95%', height: '95%' })
        .fill('none')
        .stroke('#333333')
        .strokeWidth(2)

      // Saat ve tarih / Time and date
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

## 8. Lifecycle / Yaşam Döngüsü

**TR:** HarmonyOS Stage modeli, uygulamanın ve bileşenlerin yaşam döngüsünü yönetir. Doğru lifecycle metodlarını kullanmak, bellek sızıntılarını ve sensör açık kalmasını önler.

**EN:** The HarmonyOS Stage model manages the lifecycle of applications and components. Using the correct lifecycle methods prevents memory leaks and sensors being left on.

### UIAbility Lifecycle

| Metod / Method | Tetikleyici / Trigger | Kullanım Amacı (TR) | Use Case (EN) |
|---|---|---|---|
| `onCreate(want, launchParam)` | İlk başlatma | Başlangıç verileri yükle, kaynakları başlat | Load initial data, initialize resources |
| `onWindowStageCreate(stage)` | Pencere hazır | UI yükle (`loadContent`), event listener kur | Load UI (`loadContent`), set up event listeners |
| `onForeground()` | Ön plana geldi | Sensörleri başlat, timer'ları başlat | Start sensors, start timers |
| `onBackground()` | Arka plana gitti | Sensörleri durdur, UI timer'ları iptal et | Stop sensors, cancel UI timers |
| `onWindowStageDestroy()` | Pencere kapandı | Pencere kaynaklarını serbest bırak | Release window resources |
| `onDestroy()` | Uygulama kapandı | Tüm kaynakları temizle, verileri kaydet | Clean up all resources, save data |

```typescript
import { UIAbility, Want, AbilityConstant, window } from '@kit.AbilityKit';
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0xFF00;
const TAG = 'WearableAbility';

export default class EntryAbility extends UIAbility {
  private sensorStarted: boolean = false;

  // UIAbility ilk kez oluşturulduğunda / When UIAbility is created for the first time
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate');
    // Uygulama başlatma işlemleri / Application initialization tasks
    // - Veri tabanı bağlantısı / Database connection
    // - Uygulama ayarları yükleme / Load app settings
    // - Analitik başlatma / Analytics initialization
  }

  // Pencere oluşturulduğunda / When window is created
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageCreate');

    // Ana sayfayı yükle / Load main page
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, `loadContent failed: ${err.code}`);
        return;
      }
      hilog.info(DOMAIN, TAG, 'loadContent succeeded');
    });
  }

  // Uygulama ön plana geldiğinde / When app comes to foreground
  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'onForeground');

    if (!this.sensorStarted) {
      this.startBackgroundSensors();
      this.sensorStarted = true;
    }
  }

  // Uygulama arka plana gittiğinde / When app goes to background
  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground');

    // Yalnızca UI güncellemeleri için kullanılan sensörleri durdur
    // Stop sensors only used for UI updates
    // Not: Sağlık takibi gibi süregelen sensörler arka planda devam edebilir
    // Note: Ongoing sensors like health tracking may continue in background
    this.stopUISensors();
  }

  // Pencere yok edildiğinde / When window is destroyed
  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
    // Pencere event listener'larını kaldır / Remove window event listeners
  }

  // UIAbility yok edildiğinde / When UIAbility is destroyed
  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');

    // Tüm sensörleri kapat / Stop all sensors
    this.stopAllSensors();

    // Verileri kaydet / Save data
    // Bağlantıları kapat / Close connections
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
    // UI'ya yönelik sürekli güncellemeleri durdur / Stop continuous UI-oriented updates
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

### Bileşen Lifecycle / Component Lifecycle

**TR:** `@Component` bileşenleri de kendi yaşam döngüsü metodlarına sahiptir:

**EN:** `@Component` components also have their own lifecycle methods:

| Metod / Method | Açıklama (TR) | Description (EN) |
|---|---|---|
| `aboutToAppear()` | Bileşen oluşturulmadan önce, `build()` öncesi | Before component is created, before `build()` |
| `aboutToDisappear()` | Bileşen yok edilmeden önce | Before component is destroyed |
| `onPageShow()` | Sayfa görünür olduğunda (sadece `@Entry`) | When page becomes visible (`@Entry` only) |
| `onPageHide()` | Sayfa gizlendiğinde (sadece `@Entry`) | When page is hidden (`@Entry` only) |
| `onBackPress()` | Geri tuşuna basıldığında (sadece `@Entry`) | When back button is pressed (`@Entry` only) |

```typescript
@Entry
@Component
struct LifecycleDemo {
  @State data: string[] = [];
  private sensorActive: boolean = false;

  // Bileşen oluşturulmadan önce veri yükle / Load data before component is created
  aboutToAppear(): void {
    console.info('[Lifecycle] aboutToAppear — Sensörler başlatılıyor / Starting sensors');
    this.loadInitialData();
    this.startSensors();
    this.sensorActive = true;
  }

  // Bileşen yok edilmeden önce temizlik yap / Clean up before component is destroyed
  aboutToDisappear(): void {
    console.info('[Lifecycle] aboutToDisappear — Temizlik yapılıyor / Cleaning up');
    if (this.sensorActive) {
      sensor.off(sensor.SensorId.PEDOMETER);
      sensor.off(sensor.SensorId.HEART_RATE);
      this.sensorActive = false;
    }
  }

  // Sayfa görünür olduğunda (navigasyon geri gelince de tetiklenir)
  // When page is visible (also triggered on navigation back)
  onPageShow(): void {
    console.info('[Lifecycle] onPageShow');
    // Verileri yenile / Refresh data
  }

  // Sayfa gizlendiğinde / When page is hidden
  onPageHide(): void {
    console.info('[Lifecycle] onPageHide');
    // Animasyonları durdur / Stop animations
  }

  // Geri tuşunu özelleştir / Customize back button
  onBackPress(): boolean {
    console.info('[Lifecycle] onBackPress');
    // true döndürmek varsayılan geri davranışını engeller
    // Returning true prevents default back behavior
    return false; // false = varsayılan davranış / false = default behavior
  }

  private async loadInitialData(): Promise<void> {
    // Başlangıç verilerini yükle / Load initial data
    this.data = ['Yükleniyor... / Loading...'];
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

## Hızlı Referans / Quick Reference

### Sık Kullanılan Import'lar / Commonly Used Imports

```typescript
// Sensörler / Sensors
import { sensor } from '@kit.SensorServiceKit';

// Sağlık / Health
import health from '@ohos.health';

// Dağıtık veri / Distributed data
import distributedKVStore from '@ohos.data.distributedKVStore';

// İzin yönetimi / Permission management
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

// Titreşim / Vibration
import vibrator from '@ohos.vibrator';

// Hata tipi / Error type
import { BusinessError } from '@kit.BasicServicesKit';

// Loglama / Logging
import { hilog } from '@kit.PerformanceAnalysisKit';

// Tercihler / Preferences
import dataPreferences from '@ohos.data.preferences';

// HTTP / Network
import http from '@ohos.net.http';
```

### Sensör Interval Değerleri / Sensor Interval Values

| Seçenek / Option | Nanosaniye / Nanoseconds | Kullanım / Use Case |
|---|---|---|
| `'fastest'` | Cihaz minimumu / Device minimum | Gerçek zamanlı oyun / Real-time gaming |
| `'game'` | ~20,000,000 ns (20ms) | Hareket izleme / Motion tracking |
| `'ui'` | ~60,000,000 ns (60ms) | UI animasyonları / UI animations |
| `'normal'` | ~200,000,000 ns (200ms) | Genel kullanım / General use |
| `1000000000` | 1,000,000,000 ns (1s) | Sağlık izleme / Health monitoring |

---

*Son güncelleme / Last updated: March 2026 | HarmonyOS API Level 11+ | DevEco Studio 4.1+*
