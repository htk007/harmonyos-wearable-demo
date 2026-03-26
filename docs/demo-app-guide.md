# HarmonyOS Wearable Health Demo — Uygulama Rehberi

> Demo uygulamasını anlamak, sunmak ve geliştirmek için kapsamlı rehber.

---

## 1. Uygulamaya Genel Bakış

`harmonyos-wearable-demo`, HarmonyOS wearable geliştirme ortamını tanıtmak amacıyla hazırlanmış referans kalitesinde bir demo projesidir. Gerçek bir ürün uygulamasında bulunması beklenen tüm temel unsurları içerir:

- **Çok sayfalı navigasyon** (Tabs / Alt Menü)
- **Sensör API entegrasyonu** (gerçek cihaz + mock fallback)
- **Cihazlar arası senkronizasyon** (distributed data)
- **Yeniden kullanılabilir UI komponentleri**
- **Lifecycle ve izin yönetimi**

---

## 2. Sayfa Açıklamaları

### 2.1 Index (Ana Dashboard)

**Dosya:** `src/main/ets/pages/Index.ets`

Ana dashboard, uygulamanın giriş noktasıdır. Şu unsurları içerir:

| Bileşen | Açıklama |
|---------|----------|
| Canlı saat | `setInterval` ile her saniye güncellenen saat gösterimi |
| Adım progress halkası | `RingProgress` komponenti ile günlük hedefi dairesel gösterir |
| HealthCard Grid | Kalp atışı, adım, kalori, uyku skoru, mesafe kartları |
| Alt navigasyon | 4 sekme: Ana Sayfa, Kalp, Adım, Uyku |

**Öğretici Noktalar:**
```typescript
// @State ile reaktif değişken
@State currentHeartRate: number = 0

// Mock veri güncelleme (gerçek sensör simülasyonu)
private startMockDataUpdate(): void {
  setInterval(() => {
    this.currentHeartRate = Math.floor(60 + Math.random() * 40)
  }, 3000)
}
```

---

### 2.2 HeartRate (Kalp Atışı Monitörü)

**Dosya:** `src/main/ets/pages/HeartRate.ets`

| Özellik | Teknik Detay |
|---------|-------------|
| Gerçek zamanlı BPM | `sensor.on(SensorId.HEART_RATE)` callback'i |
| Nabız animasyonu | `@State` + CSS `scale` animasyonu |
| İstatistik kartları | Min / Maks / Ortalama hesaplaması |
| BPM zonu tablosu | Bradikardi < 60, Normal 60-100, Yüksek 100-120, Taşikardi > 120 |
| Uyarı banner | 120 BPM üzeri veya 50 BPM altında görünür |

**Öğretici Noktalar:**
```typescript
// Sensör kaydı
sensor.on(sensor.SensorId.HEART_RATE, (data: sensor.HeartRateResponse) => {
  this.currentBPM = data.heartRate
  this.updateStats(data.heartRate)
}, { interval: 1000000000 }) // nanosaniye cinsinden

// Temizlik (memory leak önleme)
aboutToDisappear() {
  sensor.off(sensor.SensorId.HEART_RATE)
}
```

---

### 2.3 StepCounter (Adım Sayar)

**Dosya:** `src/main/ets/pages/StepCounter.ets`

| Özellik | Teknik Detay |
|---------|-------------|
| Dairesel progress | `RingProgress` component, renk ilerlemeye göre değişir |
| Animasyonlu sayaç | 0'dan değere smooth animasyon |
| Kalori hesabı | `steps * 0.04` yaklaşık formül |
| Mesafe hesabı | `steps * 0.762` metre (ortalama adım boyu) |
| Saatlik dağılım | Canvas ile çubuk grafik |
| Hedef seçici | 5K / 7.5K / 10K / 15K |

**Öğretici Noktalar:**
```typescript
// Pedometer sensör kullanımı
sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
  this.stepCount = data.steps
  this.updateDerivedMetrics()
}, { interval: 'game' }) // 'game' = ~200ms güncelleme
```

---

### 2.4 SleepTracker (Uyku Analizi)

**Dosya:** `src/main/ets/pages/SleepTracker.ets`

3 sekmeli yapı:

| Sekme | İçerik |
|-------|--------|
| **Analiz** | Dairesel uyku skoru, evre dağılım progress barları |
| **Geçmiş** | 7 günlük çubuk grafik + günlük liste |
| **Öneriler** | 6 adet kişiselleştirilmiş öneri kartı |

**Öğretici Noktalar:**
```typescript
// Uyku verisi Health Kit'ten okuma
health.getHealthData({
  dataType: health.HealthDataType.SLEEP,
  startTime: yesterdayMidnight,
  endTime: todayNoon
}).then((data) => {
  this.processSleepData(data)
})
```

---

## 3. Komponent Açıklamaları

### 3.1 HealthCard

**Dosya:** `src/main/ets/components/HealthCard.ets`

```typescript
// Kullanım örneği
HealthCard({
  title: '❤️ Kalp Atışı',
  value: '72',
  unit: 'BPM',
  iconName: 'heart',
  trend: 'up',           // 'up' | 'down' | 'stable'
  accentColor: '#FF4757',
  onClick: () => { router.pushUrl({ url: 'pages/HeartRate' }) }
})
```

**Props Tablosu:**

| Prop | Tip | Açıklama |
|------|-----|----------|
| `title` | `string` | Kart başlığı |
| `value` | `string` | Gösterilecek değer |
| `unit` | `string` | Birim (BPM, adım, kcal...) |
| `trend` | `'up' \| 'down' \| 'stable'` | Trend ikonu yönü |
| `accentColor` | `string` | Sol bordür rengi |
| `onClick` | `() => void` | Tıklama callback'i |

---

### 3.2 RingProgress

**Dosya:** `src/main/ets/components/RingProgress.ets`

Canvas 2D API ile manuel çizilmiş dairesel progress göstergesi.

```typescript
// Kullanım örneği
RingProgress({
  progress: 0.68,        // 0.0 - 1.0
  size: 120,             // px
  strokeWidth: 12,       // px
  color: '#2ED573',
  bgColor: '#2A2A2A'
}) {
  // Merkeze özel içerik (@BuilderParam)
  Text('6.800')
  Text('adım')
}
```

**Teknik Detay:**
- `Canvas` + `CanvasRenderingContext2D` ile çizim
- `arc()` metodu ile yay çizimi
- 0'dan hedefe 600ms `animateTo` ile smooth başlangıç
- `%100`'de altın rengi glow efekti

---

## 4. Servis Açıklamaları

### 4.1 HealthSensorService

**Dosya:** `src/main/ets/services/HealthSensorService.ets`

Singleton pattern ile tüm sensör aboneliklerini yönetir.

```typescript
// Kullanım
const sensorService = HealthSensorService.getInstance()

// Adım sayar başlat
sensorService.startPedometerListening((steps: number) => {
  this.stepCount = steps
})

// Kalp atışı başlat
sensorService.startHeartRateListening((bpm: number) => {
  this.heartRate = bpm
})

// Uygulama kapanışında temizlik
sensorService.stopAllSensors()
```

**Mock Mod:**
```typescript
// Gerçek sensör yoksa otomatik mock geçiş
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

**Dosya:** `src/main/ets/services/DataSyncService.ets`

Akıllı saat ile telefon arasında sağlık verisini senkronize eder.

```typescript
// Cihaz keşfi başlat
const syncService = DataSyncService.getInstance()
await syncService.startDeviceDiscovery()

// Anlık senkronizasyon
await syncService.syncHealthData({
  timestamp: Date.now(),
  heartRate: 72,
  steps: 6800,
  calories: 272,
  sleepScore: 85
})

// Otomatik senkronizasyon (30 dk aralıklı)
syncService.startAutoSync()
```

---

## 5. Konfigürasyon

### module.json5 Özeti

```json5
{
  "module": {
    "deviceTypes": ["wearable"],  // Sadece wearable hedef
    "abilities": [{
      "name": "EntryAbility",
      "orientation": "auto",       // Kare/yuvarlak ekran desteği
      "backgroundModes": ["healthSport", "dataTransfer"]
    }],
    "requestPermissions": [/* 6 izin */]
  }
}
```

### build-profile.json5 Özeti

```json5
{
  "app": { "compileSdkVersion": 11 },
  "targets": [
    { "name": "default" },         // Debug: obfuscation kapalı
    { "name": "release",           // Release: obfuscation açık
      "runtimeOS": "HarmonyOS" }
  ]
}
```

---

## 6. Demo Sunum Senaryosu

Bu uygulamayı bir developer meetup veya workshop'ta sunarken önerilen senaryo:

### Adım 1 — Büyük Resim (2 dk)
> "HarmonyOS wearable ekosistemi 3 temel yapı taşı üzerine kuruludur: ArkUI, ArkTS ve Distributed Stack. Bu demo, üçünü birlikte nasıl kullanacağınızı gösteriyor."

### Adım 2 — Ana Dashboard (3 dk)
- `Index.ets` dosyasını aç, `@State` ve reaktiviteyi göster
- `HealthCard` componentini incele — prop-based composition

### Adım 3 — Sensör Entegrasyonu (5 dk)
- `HealthSensorService.ets` üzerinden `sensor.on()` API'yi göster
- Mock vs gerçek sensör geçişini açıkla

### Adım 4 — Cihaz Senkronizasyonu (3 dk)
- `DataSyncService.ets` üzerinden distributed data kavramını anlat
- HarmonyOS'un ne/nasıl farklılaştığını vurgula

### Adım 5 — Canlı Demo (5 dk)
- Emülatörde uygulamayı çalıştır
- Adım ve kalp atışı simülasyonunu göster

---

## 7. Sık Sorulan Sorular

**S: Gerçek sensör verisi almak için ne yapmam gerekiyor?**
C: `HealthSensorService` içindeki `useMockData` flag'ini `false` yapın ve gerçek cihazda çalıştırın.

**S: iOS/Android'e port edebilir miyim?**
C: ArkTS ve ArkUI HarmonyOS'a özgüdür. Ancak mantık katmanı TypeScript'e yakın olduğu için cross-platform araçlara taşınabilir.

**S: Uyku verisini gerçekten nasıl alıyorsunuz?**
C: Gerçek implementasyonda `@ohos.health.HealthDataType.SLEEP` kullanılır. Demo'da simüle data yeterlidir.

**S: API Level 11'den eski cihazları destekliyor mu?**
C: `build-profile.json5`'te `compatibleSdkVersion: 10` ile API 10 cihazlarda da çalışır, ancak bazı özellikler kısıtlı olabilir.

---

Hazırlayan: **HarmonyOS Developer Advocate Ekibi**
Versiyon: 1.0.0 | Tarih: Mart 2026
