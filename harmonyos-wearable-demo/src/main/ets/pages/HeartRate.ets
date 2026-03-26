/**
 * HeartRate.ets - Kalp Atışı Monitör Sayfası
 *
 * Gerçek zamanlı BPM izleme, minimum/maksimum/ortalama değerler,
 * taşikardi (>120 BPM) ve bradikardi (<50 BPM) uyarıları.
 *
 * @ohos.sensor API ile akselerometre/PPG sensörü entegrasyonu.
 * Gerçek donanım yoksa mock data simülasyonu kullanılır.
 */

import router from '@ohos.router'
import sensor from '@ohos.sensor'

// Kalp atışı ölçüm kaydı
interface HeartRateRecord {
  bpm: number
  timestamp: number
  status: 'normal' | 'high' | 'low' | 'critical'
}

// BPM eşik değerleri
const THRESHOLD = {
  BRADYCARDIA: 50,    // Bradikardi alt sınırı
  NORMAL_LOW: 60,     // Normal aralık alt sınırı
  NORMAL_HIGH: 100,   // Normal aralık üst sınırı
  TACHYCARDIA: 120    // Taşikardi üst sınırı
}

@Entry
@Component
struct HeartRate {
  // Anlık BPM değeri
  @State private currentBPM: number = 72

  // İstatistik değerleri
  @State private minBPM: number = 72
  @State private maxBPM: number = 72
  @State private avgBPM: number = 72

  // Ölçüm geçmişi (son 20 değer)
  @State private history: HeartRateRecord[] = []

  // Ölçüm durumu
  @State private isMeasuring: boolean = false
  @State private measureProgress: number = 0
  @State private statusMessage: string = 'Ölçüm başlatmak için dokunun'
  @State private alertMessage: string = ''
  @State private showAlert: boolean = false

  // Nabız animasyonu
  @State private pulseScale: number = 1.0

  // Zamanlayıcılar
  private measureTimer: number = -1
  private pulseTimer: number = -1
  private mockDataTimer: number = -1
  private sensorSubscribed: boolean = false

  /**
   * Bileşen yüklendiğinde başlangıç verilerini hazırla
   */
  aboutToAppear() {
    this.initMockHistory()
    this.startPulseAnimation()
    // İlk ölçümü otomatik başlat
    this.startMeasurement()
  }

  /**
   * Bileşen yok edildiğinde kaynakları temizle
   */
  aboutToDisappear() {
    this.stopAllTimers()
    this.unsubscribeSensor()
  }

  /**
   * Tüm zamanlayıcıları durdur
   */
  private stopAllTimers() {
    if (this.measureTimer !== -1) clearInterval(this.measureTimer)
    if (this.pulseTimer !== -1) clearInterval(this.pulseTimer)
    if (this.mockDataTimer !== -1) clearInterval(this.mockDataTimer)
  }

  /**
   * Nabız animasyonu - kalp atışı efekti
   */
  private startPulseAnimation() {
    this.pulseTimer = setInterval(() => {
      // Kalp ikonunu büyüt/küçült animasyonu
      this.pulseScale = 1.2
      setTimeout(() => {
        this.pulseScale = 1.0
      }, 150)
    }, 60000 / Math.max(this.currentBPM, 40)) // BPM'e göre hız ayarla
  }

  /**
   * Başlangıç için 10 mock geçmiş kaydı oluştur
   */
  private initMockHistory() {
    const baseTime = Date.now()
    for (let i = 9; i >= 0; i--) {
      const bpm = 65 + Math.floor(Math.random() * 20)
      this.history.push({
        bpm,
        timestamp: baseTime - i * 300000, // 5 dakika aralıklı
        status: this.getBPMStatus(bpm)
      })
    }
    this.recalculateStats()
  }

  /**
   * BPM değerine göre durum döndürür
   */
  private getBPMStatus(bpm: number): 'normal' | 'high' | 'low' | 'critical' {
    if (bpm >= THRESHOLD.TACHYCARDIA) return 'critical'
    if (bpm > THRESHOLD.NORMAL_HIGH) return 'high'
    if (bpm < THRESHOLD.BRADYCARDIA) return 'critical'
    if (bpm < THRESHOLD.NORMAL_LOW) return 'low'
    return 'normal'
  }

  /**
   * Min/Maks/Ort istatistiklerini yeniden hesapla
   */
  private recalculateStats() {
    if (this.history.length === 0) return
    const bpms = this.history.map(r => r.bpm)
    this.minBPM = Math.min(...bpms)
    this.maxBPM = Math.max(...bpms)
    this.avgBPM = Math.round(bpms.reduce((a, b) => a + b, 0) / bpms.length)
  }

  /**
   * Kalp atışı sensörüne abone olmayı dene.
   * Başarısız olursa mock data'ya geç.
   */
  private subscribeSensor() {
    try {
      // HarmonyOS PPG sensörü (kalp atışı için)
      sensor.on(sensor.SensorId.HEART_RATE, (data: sensor.HeartRateResponse) => {
        if (data && data.heartRate > 0) {
          this.updateBPM(data.heartRate)
        }
      }, { interval: 1000000000 }) // 1 saniye aralık (nanosecond)
      this.sensorSubscribed = true
      console.info('[HeartRate] Gerçek sensör bağlandı')
    } catch (error) {
      // Sensör mevcut değil, mock kullan
      console.warn(`[HeartRate] Sensör bağlanamadı, mock kullanılıyor: ${JSON.stringify(error)}`)
      this.startMockSensor()
    }
  }

  /**
   * Sensör aboneliğini iptal et
   */
  private unsubscribeSensor() {
    if (this.sensorSubscribed) {
      try {
        sensor.off(sensor.SensorId.HEART_RATE)
        this.sensorSubscribed = false
      } catch (e) {
        console.warn('[HeartRate] Sensör aboneliği iptal edilemedi')
      }
    }
  }

  /**
   * Mock sensör simülasyonu - 1 saniyede bir BPM günceller
   */
  private startMockSensor() {
    // Gerçekçi kalp atışı simülasyonu
    let trend = 0
    this.mockDataTimer = setInterval(() => {
      trend += (Math.random() - 0.5) * 0.5
      trend = Math.max(-5, Math.min(5, trend))
      const newBPM = Math.round(this.currentBPM + trend + (Math.random() - 0.5) * 2)
      this.updateBPM(Math.max(45, Math.min(140, newBPM)))
    }, 1000)
  }

  /**
   * BPM değerini güncelle ve uyarı kontrolü yap
   */
  private updateBPM(bpm: number) {
    this.currentBPM = bpm
    const status = this.getBPMStatus(bpm)

    // Taşikardi kontrolü
    if (status === 'critical' && bpm >= THRESHOLD.TACHYCARDIA) {
      this.alertMessage = `⚠️ TAŞİKARDİ UYARISI\nKalp atışınız çok yüksek: ${bpm} BPM`
      this.showAlert = true
    } else if (status === 'critical' && bpm < THRESHOLD.BRADYCARDIA) {
      this.alertMessage = `⚠️ BRADİKARDİ UYARISI\nKalp atışınız çok düşük: ${bpm} BPM`
      this.showAlert = true
    } else {
      this.showAlert = false
    }

    // Geçmişe kaydet (her 10 saniyede bir)
    const now = Date.now()
    const lastRecord = this.history[this.history.length - 1]
    if (!lastRecord || now - lastRecord.timestamp > 10000) {
      this.history.push({ bpm, timestamp: now, status })
      // Son 50 kaydı tut
      if (this.history.length > 50) {
        this.history = this.history.slice(-50)
      }
      this.recalculateStats()
    }
  }

  /**
   * 30 saniyelik aktif ölçüm döngüsü başlat
   */
  private startMeasurement() {
    this.isMeasuring = true
    this.measureProgress = 0
    this.statusMessage = 'Ölçülüyor...'
    this.subscribeSensor()

    // 30 saniye ilerleme çubuğu
    let elapsed = 0
    this.measureTimer = setInterval(() => {
      elapsed += 1
      this.measureProgress = elapsed / 30
      if (elapsed >= 30) {
        clearInterval(this.measureTimer)
        this.isMeasuring = false
        this.statusMessage = 'Ölçüm tamamlandı'
        // Continuous monitoring moduna geç
      }
    }, 1000)
  }

  /**
   * Durum rengini döndür
   */
  private getStatusColor(): string {
    const status = this.getBPMStatus(this.currentBPM)
    switch (status) {
      case 'critical': return '#FF4444'
      case 'high': return '#FFA500'
      case 'low': return '#4169E1'
      default: return '#00C853'
    }
  }

  /**
   * Durum mesajını döndür
   */
  private getBPMLabel(): string {
    const status = this.getBPMStatus(this.currentBPM)
    switch (status) {
      case 'critical': return this.currentBPM >= THRESHOLD.TACHYCARDIA ? 'TAŞİKARDİ' : 'BRADİKARDİ'
      case 'high': return 'YÜKSEK'
      case 'low': return 'DÜŞÜK'
      default: return 'NORMAL'
    }
  }

  /**
   * BPM grafik çubuğu yüksekliğini hesapla
   */
  private getBarHeight(bpm: number): number {
    const minH = 8
    const maxH = 40
    const normalized = (bpm - 40) / (160 - 40)
    return minH + normalized * (maxH - minH)
  }

  build() {
    Stack() {
      // ── Ana İçerik ──────────────────────────────────────────────
      Column() {
        // Geri Butonu ve Başlık
        Row() {
          Button('←')
            .fontSize(18)
            .backgroundColor(Color.Transparent)
            .fontColor('#FFFFFF')
            .width(36)
            .height(36)
            .borderRadius(18)
            .onClick(() => router.back())

          Text('Kalp Atışı')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // Boş alan - hizalama için
          Column().width(36)
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 8, bottom: 4 })

        Scroll() {
          Column({ space: 10 }) {

            // ── Anlık BPM Göstergesi ──────────────────────────────
            Column() {
              // Kalp İkonu (nabız animasyonu ile)
              Text('❤️')
                .fontSize(32)
                .scale({ x: this.pulseScale, y: this.pulseScale })
                .animation({
                  duration: 150,
                  curve: Curve.EaseOut
                })

              // BPM Değeri
              Text(this.currentBPM.toString())
                .fontSize(48)
                .fontColor(this.getStatusColor())
                .fontWeight(FontWeight.Bold)
                .margin({ top: 4 })

              Text('BPM')
                .fontSize(14)
                .fontColor('#888888')

              // Durum Etiketi
              Text(this.getBPMLabel())
                .fontSize(12)
                .fontColor(this.getStatusColor())
                .fontWeight(FontWeight.Medium)
                .backgroundColor(`${this.getStatusColor()}22`)
                .borderRadius(8)
                .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                .margin({ top: 6 })

              // Ölçüm İlerleme Çubuğu
              if (this.isMeasuring) {
                Column() {
                  Progress({
                    value: this.measureProgress * 100,
                    total: 100,
                    type: ProgressType.Linear
                  })
                    .width('80%')
                    .height(4)
                    .color('#00C853')
                    .backgroundColor('#1A3A1A')

                  Text(this.statusMessage)
                    .fontSize(10)
                    .fontColor('#888888')
                    .margin({ top: 4 })
                }
                .margin({ top: 8 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#0D1B0D')
            .borderRadius(16)
            .alignItems(HorizontalAlign.Center)

            // ── İstatistik Kartları ───────────────────────────────
            Row({ space: 8 }) {
              // Min
              Column() {
                Text('↓ MIN')
                  .fontSize(9)
                  .fontColor('#888888')
                Text(this.minBPM.toString())
                  .fontSize(20)
                  .fontColor('#4169E1')
                  .fontWeight(FontWeight.Bold)
                Text('BPM')
                  .fontSize(9)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              .padding(10)
              .backgroundColor('#0A0A1A')
              .borderRadius(12)
              .alignItems(HorizontalAlign.Center)

              // Ortalama
              Column() {
                Text('⌀ ORT')
                  .fontSize(9)
                  .fontColor('#888888')
                Text(this.avgBPM.toString())
                  .fontSize(20)
                  .fontColor('#00C853')
                  .fontWeight(FontWeight.Bold)
                Text('BPM')
                  .fontSize(9)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              .padding(10)
              .backgroundColor('#0A1A0A')
              .borderRadius(12)
              .alignItems(HorizontalAlign.Center)

              // Max
              Column() {
                Text('↑ MAX')
                  .fontSize(9)
                  .fontColor('#888888')
                Text(this.maxBPM.toString())
                  .fontSize(20)
                  .fontColor('#FF6B35')
                  .fontWeight(FontWeight.Bold)
                Text('BPM')
                  .fontSize(9)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              .padding(10)
              .backgroundColor('#1A0A0A')
              .borderRadius(12)
              .alignItems(HorizontalAlign.Center)
            }

            // ── Mini BPM Grafik ───────────────────────────────────
            Column() {
              Text('Son Ölçümler')
                .fontSize(11)
                .fontColor('#AAAAAA')
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ bottom: 8 })

              Row({ space: 3 }) {
                ForEach(this.history.slice(-15), (record: HeartRateRecord) => {
                  Column()
                    .width(8)
                    .height(this.getBarHeight(record.bpm))
                    .backgroundColor(
                      record.status === 'critical' ? '#FF4444' :
                      record.status === 'high' ? '#FFA500' :
                      record.status === 'low' ? '#4169E1' : '#00C853'
                    )
                    .borderRadius(2)
                })
              }
              .width('100%')
              .height(48)
              .alignItems(VerticalAlign.Bottom)
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#111111')
            .borderRadius(12)

            // ── Kalp Atışı Bölgeleri ──────────────────────────────
            Column({ space: 6 }) {
              Text('Kalp Atışı Bölgeleri')
                .fontSize(11)
                .fontColor('#AAAAAA')
                .width('100%')
                .textAlign(TextAlign.Start)

              // Her bölge satırı
              this.HeartRateZoneRow('Bradikardi', '< 50 BPM', '#4169E1', 50)
              this.HeartRateZoneRow('Normal', '60–100 BPM', '#00C853', 100)
              this.HeartRateZoneRow('Yüksek', '100–120 BPM', '#FFA500', 120)
              this.HeartRateZoneRow('Taşikardi', '> 120 BPM', '#FF4444', 140)
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#111111')
            .borderRadius(12)

          }
          .padding({ left: 12, right: 12, bottom: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')

      // ── Taşikardi/Bradikardi Uyarı Katmanı ──────────────────────
      if (this.showAlert) {
        Column() {
          Text(this.alertMessage)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .padding(12)
            .backgroundColor('#CC000099')
            .borderRadius(12)
            .width('90%')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
        .padding({ bottom: 60 })
        .onClick(() => { this.showAlert = false })
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * Kalp atışı bölgesi satırı oluştur
   */
  @Builder
  HeartRateZoneRow(label: string, range: string, color: string, limit: number) {
    Row() {
      Row()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(color)
        .margin({ right: 8 })

      Text(label)
        .fontSize(11)
        .fontColor('#CCCCCC')
        .layoutWeight(1)

      Text(range)
        .fontSize(10)
        .fontColor('#888888')

      // Mevcut değer bu bölgedeyse gösterge
      if (this.getBPMStatus(this.currentBPM) !== 'normal' &&
          Math.abs(this.currentBPM - limit) < 25) {
        Text(' ←')
          .fontSize(10)
          .fontColor(color)
      }
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}
