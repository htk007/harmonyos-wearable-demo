# Getting Started: HarmonyOS Wearable Uygulama Geliştirme
# Getting Started: HarmonyOS Wearable Application Development

> **TR:** Bu rehber, HarmonyOS ekosisteminde giyilebilir (wearable) uygulama geliştirmeye başlamak isteyen geliştiriciler için kapsamlı bir başlangıç noktası sunar.
>
> **EN:** This guide provides a comprehensive starting point for developers who want to build wearable applications within the HarmonyOS ecosystem.

---

## İçindekiler / Table of Contents

1. [Giriş / Introduction](#1-giriş--introduction)
2. [Gereksinimler / Requirements](#2-gereksinimler--requirements)
3. [Proje Oluşturma / Project Setup](#3-proje-oluşturma--project-setup)
4. [İlk ArkTS Bileşeni / First ArkTS Component](#4-i̇lk-arkts-bileşeni--first-arkts-component)
5. [Sensör API'leri / Sensor APIs](#5-sensör-apileri--sensor-apis)
6. [Wearable UI Best Practices](#6-wearable-ui-best-practices)
7. [Test ve Deploy / Testing and Deployment](#7-test-ve-deploy--testing-and-deployment)

---

## 1. Giriş / Introduction

**TR:** HarmonyOS, Huawei tarafından geliştirilen dağıtık bir işletim sistemidir. Akıllı saatler, fitness bantları ve diğer giyilebilir cihazlar için güçlü bir uygulama platformu sunar. HarmonyOS wearable ekosistemi; ArkTS programlama dili, ArkUI framework'ü ve kapsamlı sensör/sağlık API'leri ile donatılmıştır. Bu ekosistem, geliştiricilere telefondan saate kadar kesintisiz dağıtık deneyimler oluşturma imkanı tanır.

**EN:** HarmonyOS is a distributed operating system developed by Huawei. It provides a powerful application platform for smartwatches, fitness bands, and other wearable devices. The HarmonyOS wearable ecosystem is equipped with the ArkTS programming language, the ArkUI framework, and comprehensive sensor/health APIs. This ecosystem enables developers to create seamless distributed experiences across devices — from phones to watches.

### Neden HarmonyOS Wearable? / Why HarmonyOS Wearable?

**TR:**
- **Dağıtık Mimari:** Telefon ve saat arasında veri/UI paylaşımı kolaylaşır.
- **ArkTS:** TypeScript tabanlı, statik tip güvenliği ile modern geliştirme deneyimi.
- **Zengin Sensör Desteği:** Kalp atışı, adım sayar, SpO2 ve daha fazlası.
- **Health Kit:** Sağlık verilerine standart API ile erişim.
- **Düşük Güç Tüketimi:** Wearable odaklı optimizasyon kabiliyetleri.

**EN:**
- **Distributed Architecture:** Simplified data/UI sharing between phone and watch.
- **ArkTS:** TypeScript-based with static type safety for a modern development experience.
- **Rich Sensor Support:** Heart rate, pedometer, SpO2, and more.
- **Health Kit:** Standard API access to health data.
- **Low Power Consumption:** Wearable-focused optimization capabilities.

---

## 2. Gereksinimler / Requirements

**TR:** Geliştirme ortamınızı kurmadan önce aşağıdaki bileşenlerin hazır olduğundan emin olun.

**EN:** Ensure the following components are ready before setting up your development environment.

### 2.1 DevEco Studio Kurulumu / DevEco Studio Installation

**TR:** DevEco Studio, HarmonyOS uygulamaları geliştirmek için Huawei'nin resmi IDE'sidir. Versiyon 4.1 veya üstü gereklidir.

**EN:** DevEco Studio is Huawei's official IDE for developing HarmonyOS applications. Version 4.1 or higher is required.

**Adımlar / Steps:**

1. [HarmonyOS Developer Portal](https://developer.harmonyos.com/en/develop/deveco-studio) adresinden DevEco Studio 4.1+ indirin.
   Download DevEco Studio 4.1+ from the [HarmonyOS Developer Portal](https://developer.harmonyos.com/en/develop/deveco-studio).

2. Kurulum sırasında **HarmonyOS SDK**'yı da yüklemeyi seçin.
   During installation, select to also install the **HarmonyOS SDK**.

3. İlk açılışta SDK Manager'dan **API Level 11** veya üstünü yükleyin.
   On first launch, install **API Level 11** or higher from the SDK Manager.

**Sistem Gereksinimleri / System Requirements:**

| Özellik / Property | Minimum | Önerilen / Recommended |
|---|---|---|
| İşletim Sistemi / OS | Windows 10 64-bit / macOS 12 | Windows 11 / macOS 13+ |
| RAM | 8 GB | 16 GB+ |
| Disk | 10 GB boş alan / free | 30 GB+ SSD |
| JDK | JDK 17 | JDK 17 (bundled) |

### 2.2 HarmonyOS SDK (API Level 11+)

**TR:** Wearable API'lerine erişmek için API Level 11 veya üstü gereklidir. Sensor, Health Kit ve distributed data gibi wearable'a özgü özellikler bu seviyeden itibaren desteklenmektedir.

**EN:** API Level 11 or higher is required to access wearable APIs. Wearable-specific features such as sensor, Health Kit, and distributed data are supported from this level onwards.

SDK Manager'da şunların yüklü olduğunu doğrulayın / Verify the following are installed in SDK Manager:
- `HarmonyOS SDK > API 11 > ArkTS SDK`
- `HarmonyOS SDK > API 11 > Toolchains`
- `HarmonyOS SDK > API 11 > Previewer`

### 2.3 Wearable Emulator Kurulumu / Wearable Emulator Setup

**TR:** Gerçek bir cihaz olmadan test yapabilmek için HarmonyOS wearable emülatörünü kurmanız gerekir.

**EN:** To test without a physical device, you need to set up the HarmonyOS wearable emulator.

**Adımlar / Steps:**

1. DevEco Studio'da **Tools > Device Manager** menüsünü açın.
   Open **Tools > Device Manager** in DevEco Studio.

2. **New Emulator** butonuna tıklayın ve **Wearable** kategorisini seçin.
   Click **New Emulator** and select the **Wearable** category.

3. Bir cihaz profili seçin (örn. `HUAWEI Watch GT 4 Pro` veya `Generic Wearable Round`).
   Select a device profile (e.g., `HUAWEI Watch GT 4 Pro` or `Generic Wearable Round`).

4. API Level 11 ile system image'ı indirin ve emülatörü başlatın.
   Download the system image with API Level 11 and launch the emulator.

### 2.4 ArkTS Temel Bilgisi / Basic ArkTS Knowledge

**TR:** ArkTS, TypeScript'in üzerine inşa edilmiş HarmonyOS'un birincil uygulama geliştirme dilidir. Aşağıdaki kavramlara aşina olmanız önerilir:

**EN:** ArkTS is HarmonyOS's primary application development language built on top of TypeScript. Familiarity with the following concepts is recommended:

- TypeScript temel sözdizimi / Basic TypeScript syntax
- Dekoratörler (`@Entry`, `@Component`, `@State`) / Decorators
- Async/await ve Promise kullanımı / Async/await and Promise usage
- Modül sistemi (`import`/`export`) / Module system

---

## 3. Proje Oluşturma / Project Setup

**TR:** Yeni bir HarmonyOS wearable projesi oluşturmak için aşağıdaki adımları izleyin.

**EN:** Follow the steps below to create a new HarmonyOS wearable project.

### 3.1 DevEco Studio'da Yeni Proje / New Project in DevEco Studio

1. DevEco Studio'yu açın ve **File > New > New Project** seçin.
   Open DevEco Studio and select **File > New > New Project**.

2. **HarmonyOS** sekmesini seçin, ardından **Application** kategorisinden **Empty Ability** template'ini seçin.
   Select the **HarmonyOS** tab, then choose the **Empty Ability** template from the **Application** category.

3. Proje ayarlarını girin / Enter project settings:
   - **Project name:** `MyWearableApp`
   - **Bundle name:** `com.example.mywearableapp`
   - **Save location:** Tercih ettiğiniz dizin / Your preferred directory
   - **Compile SDK:** `API 11`
   - **Model:** `Stage`

4. **Finish** butonuna tıklayın.
   Click **Finish**.

### 3.2 module.json5 Yapılandırması / module.json5 Configuration

**TR:** Projenin wearable cihaz için hedeflendiğini belirtmek üzere `module.json5` dosyasını düzenleyin.

**EN:** Edit the `module.json5` file to specify that the project targets wearable devices.

Dosya yolu / File path: `entry/src/main/module.json5`

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

### 3.3 Dizin Yapısı / Directory Structure

**TR:** Oluşturulan projenin dizin yapısı aşağıdaki gibidir:

**EN:** The directory structure of the created project is as follows:

```
MyWearableApp/
├── AppScope/
│   ├── app.json5              # Uygulama genel yapılandırması / App-level config
│   └── resources/
│       └── base/
│           └── element/
│               └── string.json
├── entry/
│   └── src/
│       └── main/
│           ├── ets/
│           │   ├── entryability/
│           │   │   └── EntryAbility.ets   # UIAbility giriş noktası / Entry point
│           │   └── pages/
│           │       └── Index.ets          # Ana sayfa / Main page
│           ├── resources/
│           │   ├── base/
│           │   │   ├── element/           # String, color, float kaynakları
│           │   │   └── media/             # Görseller / Images
│           │   └── en_US/                 # Dil kaynakları / Language resources
│           └── module.json5               # Modül yapılandırması / Module config
├── oh-package.json5           # Paket bağımlılıkları / Package dependencies
└── build-profile.json5        # Build yapılandırması / Build config
```

---

## 4. İlk ArkTS Bileşeni / First ArkTS Component

**TR:** ArkTS ile basit bir wearable bileşeni oluşturalım. ArkUI dekoratörleri ve temel bileşenler ile çalışmayı öğrenin.

**EN:** Let's create a simple wearable component with ArkTS. Learn to work with ArkUI decorators and basic components.

### 4.1 Basit @Entry @Component Örneği / Basic @Entry @Component Example

**TR:** Her sayfa en az bir `@Entry` dekoratörü ile işaretlenmiş bir bileşen içermelidir. `@Component` ise yeniden kullanılabilir UI bileşenlerini tanımlar.

**EN:** Every page must contain at least one component marked with the `@Entry` decorator. `@Component` defines reusable UI components.

Dosya: `entry/src/main/ets/pages/Index.ets`

```typescript
import { sensor } from '@kit.SensorServiceKit';

// Yeniden kullanılabilir alt bileşen / Reusable sub-component
@Component
struct StepCounter {
  @Prop steps: number = 0;

  build() {
    Column() {
      Text(`${this.steps}`)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Text('Adım / Steps')
        .fontSize(14)
        .fontColor('#AAAAAA')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
  }
}

// Ana sayfa bileşeni / Main page component
@Entry
@Component
struct Index {
  @State stepCount: number = 0;
  @State heartRate: number = 0;
  @State isMonitoring: boolean = false;

  build() {
    Column() {
      // Başlık / Header
      Text('My Watch App')
        .fontSize(18)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .margin({ top: 20, bottom: 16 })

      // Adım sayacı kartı / Step counter card
      Column() {
        StepCounter({ steps: this.stepCount })
      }
      .width('80%')
      .padding(16)
      .backgroundColor('#1A1A2E')
      .borderRadius(12)
      .margin({ bottom: 12 })

      // Kalp atışı bilgisi / Heart rate info
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

      // Kontrol butonu / Control button
      Button(this.isMonitoring ? 'Durdur / Stop' : 'Başlat / Start')
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
    // Sensör başlatma kodu aşağıdaki bölümde / Sensor start code in the section below
  }

  private stopSensors(): void {
    sensor.off(sensor.SensorId.PEDOMETER);
    sensor.off(sensor.SensorId.HEART_RATE);
    console.info('[WearableApp] Sensors stopped');
  }
}
```

### 4.2 @State ile State Yönetimi / State Management with @State

**TR:** `@State`, bir bileşenin dahili reaktif durumunu tanımlar. State değiştiğinde, bağlı UI otomatik olarak güncellenir.

**EN:** `@State` defines a component's internal reactive state. When state changes, the bound UI updates automatically.

```typescript
@Entry
@Component
struct CounterExample {
  // @State: bileşen kendi state'ini sahiplenir / component owns its state
  @State count: number = 0;
  @State message: string = 'Sayaç / Counter';

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
              this.message = 'Harika! / Great!';
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

### 4.3 ArkUI Temel Bileşenleri / Core ArkUI Components

**TR:** Wearable uygulamalarında en sık kullanılan ArkUI bileşenlerine örnekler:

**EN:** Examples of the most commonly used ArkUI components in wearable apps:

```typescript
@Entry
@Component
struct UIComponentsDemo {
  @State selectedIndex: number = 0;
  private menuItems: string[] = ['Ana Sayfa', 'Sağlık', 'Aktivite'];

  build() {
    Column() {
      // Text - Metin bileşeni / Text component
      Text('HarmonyOS Watch')
        .fontSize(20)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // Row - Yatay düzen / Horizontal layout
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

      // Column - Dikey düzen / Vertical layout
      Column({ space: 6 }) {
        this.buildMetricCard('Adım / Steps', '8,432', '#4CAF50')
        this.buildMetricCard('Kalori / Calories', '342 kcal', '#FF9800')
        this.buildMetricCard('Mesafe / Distance', '6.2 km', '#2196F3')
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

## 5. Sensör API'leri / Sensor APIs

**TR:** HarmonyOS, `@ohos.sensor` modülü aracılığıyla giyilebilir cihazlardaki sensörlere erişim sağlar. Kullanmadan önce gerekli izinlerin `module.json5`'e eklendiğinden emin olun.

**EN:** HarmonyOS provides access to sensors on wearable devices through the `@ohos.sensor` module. Make sure the required permissions are added to `module.json5` before use.

### 5.1 @ohos.sensor Modülü / @ohos.sensor Module

```typescript
import { sensor } from '@kit.SensorServiceKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 5.2 Adım Sayar (Pedometer) Sensor Örneği / Pedometer Sensor Example

**TR:** Adım sayar sensörü, kullanıcının adım verilerini gerçek zamanlı olarak izler. `ohos.permission.ACTIVITY_MOTION` iznini gerektirir.

**EN:** The pedometer sensor monitors the user's step data in real time. Requires the `ohos.permission.ACTIVITY_MOTION` permission.

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

  // İzin isteme / Request permission
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

  // Sensörü başlat / Start sensor
  startPedometer(): void {
    try {
      sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
        // data.steps: toplam adım sayısı (cihaz yeniden başlayana kadar birikimli)
        // data.steps: cumulative step count (until device reboot)
        this.steps = data.steps;
        console.info(`[Pedometer] Steps: ${data.steps}`);
      }, {
        interval: 1000000000 // nanosaniye cinsinden 1 saniye / 1 second in nanoseconds
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[Pedometer] Start error: ${error.code} - ${error.message}`);
    }
  }

  // Sensörü durdur / Stop sensor
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
      Text('Adım Sayacı / Pedometer')
        .fontSize(18)
        .fontColor('#FFFFFF')

      Text(`${this.steps}`)
        .fontSize(52)
        .fontColor('#4CAF50')
        .fontWeight(FontWeight.Bold)

      Text('adım / steps')
        .fontSize(14)
        .fontColor('#888888')

      if (!this.permissionGranted) {
        Text('İzin bekleniyor... / Waiting for permission...')
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

### 5.3 Kalp Atışı Sensörü / Heart Rate Sensor

**TR:** Kalp atışı sensörü anlık nabız verisini sağlar. `ohos.permission.READ_HEALTH_DATA` iznini gerektirir.

**EN:** The heart rate sensor provides real-time pulse data. Requires the `ohos.permission.READ_HEALTH_DATA` permission.

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
        // data.heartRate: nabız değeri (BPM cinsinden)
        // data.heartRate: heart rate value in BPM
        this.heartRate = data.heartRate;

        // Accuracy seviyeleri / Accuracy levels:
        // 0 = Unreliable, 1 = Low, 2 = Medium, 3 = High
        this.accuracy = data.accuracy ?? 0;

        console.info(`[HeartRate] BPM: ${data.heartRate}, Accuracy: ${this.accuracy}`);
      }, {
        interval: 'normal' // 'normal' | 'ui' | 'game' | 'fastest' veya nanosaniye
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[HeartRate] Error: ${error.code} - ${error.message}`);
    }
  }

  getHeartRateColor(): string {
    if (this.heartRate < 60) return '#2196F3';   // Düşük / Low
    if (this.heartRate < 100) return '#4CAF50';  // Normal
    if (this.heartRate < 140) return '#FF9800';  // Yüksek / High
    return '#F44336';                             // Çok yüksek / Very high
  }

  build() {
    Column({ space: 12 }) {
      Text('Kalp Atışı / Heart Rate')
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

### 5.4 İzin Yönetimi / Permission Management

**TR:** Wearable uygulamaları için kritik izinler `module.json5` dosyasında tanımlanmalı ve çalışma zamanında kullanıcıdan isteniyor olmalıdır.

**EN:** Critical permissions for wearable apps must be declared in `module.json5` and requested from the user at runtime.

```typescript
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// İzinleri toplu olarak isteme / Batch permission request
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

**TR:** Wearable uygulamalarında UI tasarımı, telefon uygulamalarından önemli ölçüde farklıdır. Küçük ve genellikle dairesel ekranlar için optimize edilmiş tasarım prensipleri uygulamalısınız.

**EN:** UI design in wearable applications differs significantly from phone applications. You should apply design principles optimized for small and often circular screens.

### 6.1 Küçük Ekran Tasarım Prensipleri / Small Screen Design Principles

**TR:**
- **İçerik önceliği:** Sadece en önemli bilgiyi gösterin; gereksiz öğeleri kaldırın.
- **Büyük ve okunabilir yazı:** Minimum 14sp font boyutu, en az 36sp başlıklar.
- **Yüksek kontrast:** Koyu arka plan üzerine açık metin (WCAG AA standardı).
- **Tek eldeli kullanım:** Aşağı kaydırma yeterli; karmaşık navigasyon kaçının.

**EN:**
- **Content priority:** Show only the most important information; remove unnecessary elements.
- **Large, readable text:** Minimum 14sp font size, at least 36sp for headings.
- **High contrast:** Light text on dark background (WCAG AA standard).
- **One-handed use:** Scrolling down is sufficient; avoid complex navigation.

### 6.2 Dairesel/Kare Ekran Uyumluluğu / Circular/Square Screen Compatibility

**TR:** Bazı akıllı saatler dairesel, bazıları kare ekrana sahiptir. Her iki form faktörü için içerik köşelerde kesilmemeli.

**EN:** Some smartwatches have circular screens, others are square. Content should not be clipped at corners for either form factor.

```typescript
@Entry
@Component
struct CircularAdaptiveLayout {
  build() {
    // Shape-adaptive container / Şekle uyarlanabilir container
    Column() {
      // Dairesel ekranda köşe padding'i artır
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

        Text('Per, 26 Mar')
          .fontSize(14)
          .fontColor('#AAAAAA')
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      // %15 yatay padding dairesel ekranda içeriği güvende tutar
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

### 6.3 Yazı Boyutu ve Dokunmatik Hedef Boyutları / Font Size and Touch Target Sizes

**TR:** Dokunmatik hedefler en az 7x7mm (yaklaşık 48x48dp) olmalıdır. Wearable ekranlarda bu özellikle önemlidir.

**EN:** Touch targets should be at least 7x7mm (approximately 48x48dp). This is especially important on wearable screens.

| Öğe / Element | Minimum Boyut / Min Size | Önerilen / Recommended |
|---|---|---|
| Buton / Button | 44 x 44 vp | 48 x 48 vp |
| İkon Butonu / Icon Button | 40 x 40 vp | 44 x 44 vp |
| Liste Öğesi / List Item | yükseklik 40 vp / height 40 vp | 48 vp |
| Başlık Fontu / Title Font | 18 sp | 20-24 sp |
| Gövde Fontu / Body Font | 14 sp | 16 sp |
| Alt Metin / Caption | 11 sp | 12 sp |

```typescript
@Component
struct AccessibleButton {
  label: string = '';
  onPress: () => void = () => {};

  build() {
    Button(this.label)
      // Minimum dokunmatik hedef boyutu / Minimum touch target size
      .width(48)
      .height(48)
      // Minimum font boyutu / Minimum font size
      .fontSize(14)
      // Yeterli padding / Adequate padding
      .padding({ left: 12, right: 12 })
      .onClick(this.onPress)
  }
}
```

### 6.4 Pil Optimizasyonu / Battery Optimization

**TR:** Wearable cihazlarda pil kapasitesi sınırlıdır. Sensörleri sadece gerektiğinde açın ve kapatın.

**EN:** Battery capacity is limited on wearable devices. Turn sensors on only when needed and off when not in use.

```typescript
@Entry
@Component
struct BatteryOptimizedApp {
  @State isActive: boolean = false;
  private sensorTimer: number = -1;

  // Sensörü zamanlanmış aralıklarla kullan (sürekli değil)
  // Use sensor at timed intervals (not continuously)
  startOptimizedSensing(): void {
    this.sensorTimer = setInterval(() => {
      // Her 30 saniyede bir kısa ölçüm / Short measurement every 30 seconds
      sensor.on(sensor.SensorId.HEART_RATE, (data: sensor.HeartRateResponse) => {
        console.info(`[Battery] Quick HR read: ${data.heartRate}`);
        // Okuma sonrası hemen kapat / Turn off immediately after reading
        sensor.off(sensor.SensorId.HEART_RATE);
      });
    }, 30000); // 30 saniye / 30 seconds
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
    // Bileşen yok edildiğinde sensörleri kapat
    // Stop sensors when component is destroyed
    this.stopOptimizedSensing();
  }

  build() {
    // ... UI
    Column() {
      Text('Pil Dostu Mod / Battery Saver Mode')
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

## 7. Test ve Deploy / Testing and Deployment

**TR:** Uygulamanızı önce emülatörde test edin, ardından gerçek bir cihaza deploy edin.

**EN:** Test your application on the emulator first, then deploy to a real device.

### 7.1 Emülatörde Test / Testing on Emulator

1. DevEco Studio'da **Run > Run 'entry'** seçin veya `Shift+F10` kısayolunu kullanın.
   In DevEco Studio, select **Run > Run 'entry'** or use the `Shift+F10` shortcut.

2. Device Manager'dan wearable emülatörünüzü seçin.
   Select your wearable emulator from Device Manager.

3. Build ve deploy otomatik gerçekleşir.
   Build and deploy happen automatically.

**Emülatörde Sensör Simülasyonu / Sensor Simulation on Emulator:**

DevEco Studio'nun **Extended Controls** panelinden sanal sensör verileri gönderebilirsiniz:
You can send virtual sensor data from DevEco Studio's **Extended Controls** panel:

- **Steps:** Virtual pedometer değeri ayarlayın / Set virtual pedometer value
- **Heart Rate:** Simüle edilmiş nabız değeri girin / Enter simulated heart rate value
- **Location:** GPS koordinatları simüle edin / Simulate GPS coordinates

### 7.2 Gerçek Cihazda Debug / Debug on Real Device

**TR:** Gerçek bir HarmonyOS wearable cihazda test etmek için:

**EN:** To test on a real HarmonyOS wearable device:

1. Saatte **Geliştirici Seçenekleri**'ni etkinleştirin: Ayarlar > Hakkında > Derleme numarasına 7 kez dokunun.
   Enable **Developer Options** on the watch: Settings > About > Tap Build Number 7 times.

2. **USB Hata Ayıklama**'yı etkinleştirin: Geliştirici Seçenekleri > USB Hata Ayıklama.
   Enable **USB Debugging**: Developer Options > USB Debugging.

3. Saati USB veya Bluetooth ile bilgisayara bağlayın.
   Connect the watch to your computer via USB or Bluetooth.

4. DevEco Studio'da cihazınızın Device Manager'da göründüğünü doğrulayın.
   Verify your device appears in Device Manager in DevEco Studio.

### 7.3 hdc Komutları / hdc Commands

**TR:** `hdc` (HarmonyOS Device Connector), cihaz yönetimi için komut satırı aracıdır. `DevEco Studio/sdk/toolchains/` dizininde bulunur.

**EN:** `hdc` (HarmonyOS Device Connector) is the command-line tool for device management. It is located in the `DevEco Studio/sdk/toolchains/` directory.

```bash
# Bağlı cihazları listele / List connected devices
hdc list targets

# Uygulama paketi deploy et / Deploy app package
hdc app install MyWearableApp.hap

# Uygulamayı kaldır / Uninstall application
hdc app uninstall com.example.mywearableapp

# Cihaz loglarını izle / Monitor device logs
hdc hilog

# Belirli tag ile log filtrele / Filter logs by tag
hdc hilog | grep "WearableApp"

# Uygulamayı başlat / Start application
hdc shell aa start -a EntryAbility -b com.example.mywearableapp

# Uygulamayı durdur / Stop application
hdc shell aa force-stop com.example.mywearableapp

# Dosya gönder / Send file to device
hdc file send ./localfile.txt /data/local/tmp/

# Cihazdan dosya al / Get file from device
hdc file recv /data/local/tmp/logfile.txt ./

# Cihaz bilgilerini görüntüle / View device information
hdc shell param get const.product.model

# Pil durumunu kontrol et / Check battery status
hdc shell hidumper -s BatteryService -a info
```

### 7.4 Yaygın Sorunlar ve Çözümleri / Common Issues and Solutions

| Sorun / Issue | Olası Neden / Possible Cause | Çözüm / Solution |
|---|---|---|
| Cihaz görünmüyor / Device not visible | USB sürücüsü yok / No USB driver | Huawei USB driver yükle / Install Huawei USB driver |
| Build hatası / Build error | API Level uyumsuzluğu / API Level mismatch | `build-profile.json5` API seviyesini kontrol et / Check API level |
| Sensör verisi gelmiyor / No sensor data | İzin reddedildi / Permission denied | `module.json5` izinlerini doğrula / Verify permissions |
| App crash on launch | ArkTS tip hatası / ArkTS type error | Logcat'te detaylı hatayı incele / Check detailed error in logcat |
| Emülatör yavaş / Slow emulator | RAM yetersiz / Insufficient RAM | Emülatör RAM'ini artır / Increase emulator RAM |

---

## Sonraki Adımlar / Next Steps

**TR:** Bu rehberi tamamladıktan sonra şu konuları araştırmanızı öneririz:

**EN:** After completing this guide, we recommend exploring the following topics:

- **Health Kit:** Kapsamlı sağlık verisi API'leri için `@ohos.health` modülü
- **Distributed DevKit:** Telefon-saat arası veri paylaşımı
- **Watch Face Development:** Özel saat kadranı geliştirme
- **ArkUI Animation:** Bileşen animasyonları ve geçiş efektleri
- **Notification Management:** Wearable bildirim yönetimi
- **API Cheatsheet:** Tüm API referansı için `api-cheatsheet.md` dosyasına bakın

---

*Son güncelleme / Last updated: March 2026 | HarmonyOS API Level 11+ | DevEco Studio 4.1+*
