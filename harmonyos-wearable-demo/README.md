# HarmonyOS Wearable Health Demo

> ArkTS ile yazılmış, HarmonyOS wearable ekosistemi için kapsamlı sağlık takip demo uygulaması.

---

## Genel Bakış / Overview

Bu proje, HarmonyOS wearable (akıllı saat) platformu için geliştirilmiş bir **sağlık monitörü demo uygulamasıdır**. Developer Advocate ekibi tarafından, geliştiricilerin HarmonyOS Wearable API'lerini öğrenmelerine yardımcı olmak amacıyla oluşturulmuştur.

> This project is a **health monitor demo application** built for the HarmonyOS wearable (smartwatch) platform. Created by the Developer Advocate team to help developers learn HarmonyOS Wearable APIs.

---

## Özellikler / Features

| Özellik | Açıklama |
|---------|----------|
| 🫀 **Kalp Atışı Monitörü** | Gerçek zamanlı BPM takibi, min/max/ort istatistikler, taşikardi uyarısı |
| 👣 **Adım Sayar** | Günlük hedef takibi, kalori & mesafe hesabı, saatlik dağılım grafiği |
| 😴 **Uyku Analizi** | Uyku evresi dağılımı (Derin/REM/Hafif), uyku skoru, 7 günlük geçmiş |
| 📡 **Telefon Senkronizasyonu** | Distributed Hardware API ile cihazlar arası veri paylaşımı |

---

## Proje Yapısı / Project Structure

```
harmonyos-wearable-demo/
├── src/
│   └── main/
│       ├── ets/
│       │   ├── pages/
│       │   │   ├── Index.ets          # Ana dashboard
│       │   │   ├── HeartRate.ets      # Kalp atışı monitörü
│       │   │   ├── StepCounter.ets    # Adım sayar
│       │   │   └── SleepTracker.ets   # Uyku analizi
│       │   ├── components/
│       │   │   ├── HealthCard.ets     # Tekrar kullanılabilir sağlık kartı
│       │   │   └── RingProgress.ets   # Dairesel ilerleme göstergesi
│       │   └── services/
│       │       ├── HealthSensorService.ets  # Sensör yönetimi
│       │       └── DataSyncService.ets      # Cihaz senkronizasyonu
│       └── resources/
│           └── base/profile/
│               └── main_pages.json    # Sayfa rotaları
├── module.json5                       # Modül konfigürasyonu
├── build-profile.json5                # Build ayarları
└── README.md
```

---

## Kullanılan API'ler / APIs Used

```typescript
@ohos.sensor           // Pedometer, HeartRate, Accelerometer
@ohos.health           // Health data read/write
@ohos.distributedHardware.deviceManager  // Device discovery & sync
@ohos.vibrator         // Haptic feedback
```

### Gerekli İzinler / Required Permissions

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

## Kurulum / Setup

### Gereksinimler / Prerequisites

- **DevEco Studio** 4.1 veya üzeri
- **HarmonyOS SDK** API Level 11+
- **Wearable Emulator** veya gerçek HarmonyOS wearable cihaz

### Adımlar / Steps

```bash
# 1. Projeyi aç / Open project
# DevEco Studio > File > Open > harmonyos-wearable-demo

# 2. SDK bağımlılıklarını kontrol et / Check SDK dependencies
# File > Project Structure > SDK Location

# 3. Emülatörü başlat / Start emulator
# Tools > Device Manager > New Emulator > Wearable

# 4. Uygulamayı çalıştır / Run the app
# Run > Run 'entry' (Shift+F10)
```

### hdc Komutları / hdc Commands

```bash
# Cihaz listesi / List devices
hdc list targets

# APK yükle / Install app
hdc install entry-default-signed.hap

# Log takibi / Follow logs
hdc hilog | grep "HealthDemo"
```

---

## Mimari / Architecture

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

## Demo Notları / Demo Notes

> **Mock Data:** Gerçek sensör donanımı olmadığında uygulama otomatik olarak simüle veri kullanır. `HealthSensorService` içindeki `useMockData` flag'ini `false` yaparak gerçek sensör verisine geçebilirsiniz.

> **Mock Data:** When real sensor hardware is unavailable, the app automatically uses simulated data. Set the `useMockData` flag to `false` in `HealthSensorService` to switch to real sensor data.

---

## İlgili Kaynaklar / Related Resources

- [Getting Started Guide](../docs/getting-started.md)
- [API Cheatsheet](../docs/api-cheatsheet.md)
- [HarmonyOS Developer Docs](https://developer.harmonyos.com)
- [ArkTS Language Reference](https://developer.harmonyos.com/cn/docs/documentation/doc-references/arkts-overview-0000001531483156)

---

## Katkıda Bulunanlar / Contributors

Hazırlayan: **HarmonyOS Developer Advocate Ekibi**
Versiyon: 1.0.0 | API Level: 11 | Tarih: Mart 2026
