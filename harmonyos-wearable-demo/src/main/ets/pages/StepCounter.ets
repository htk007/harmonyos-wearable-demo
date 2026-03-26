/**
 * StepCounter.ets - Adım Sayar Sayfası
 *
 * Günlük adım hedefi takibi (varsayılan: 10.000 adım),
 * dairesel progress göstergesi, kalori tahmini ve mesafe hesaplama.
 *
 * @ohos.sensor API ile pedometer sensörü entegrasyonu.
 * Gerçek donanım yoksa mock data simülasyonu kullanılır.
 */

import router from '@ohos.router'
import sensor from '@ohos.sensor'
import { RingProgress } from '../components/RingProgress'

// Günlük adım kaydı
interface DailyStepRecord {
  hour: number       // Saat (0-23)
  steps: number      // O saatte atılan adım
  active: boolean    // Aktif saat mi?
}

// Adım sayar istatistikleri
interface StepStats {
  totalSteps: number
  dailyGoal: number
  calories: number
  distanceKm: number
  activeMinutes: number
  currentPace: number    // Adım/dakika
}

// Kullanıcı parametreleri (kalori/mesafe hesabı için)
const USER_PARAMS = {
  WEIGHT_KG: 70,
  HEIGHT_CM: 175,
  STRIDE_LENGTH_M: 0.78  // Ortalama adım uzunluğu (metre)
}

// MET değeri (yürüme için metabolik eşdeğer)
const WALKING_MET = 3.5

@Entry
@Component
struct StepCounter {
  // Adım istatistikleri
  @State private stats: StepStats = {
    totalSteps: 7842,
    dailyGoal: 10000,
    calories: 312,
    distanceKm: 6.12,
    activeMinutes: 68,
    currentPace: 0
  }

  // Saatlik dağılım grafiği verileri
  @State private hourlyData: DailyStepRecord[] = []

  // Canlı adım sayacı animasyon değeri
  @State private displayedSteps: number = 0

  // Aktif sayma durumu
  @State private isTracking: boolean = true
  @State private statusMessage: string = 'Takip aktif'

  // Pedometer sensörü bağlı mı?
  private sensorConnected: boolean = false
  private mockStepTimer: number = -1
  private animationTimer: number = -1

  /**
   * Başlangıçta verileri hazırla ve sensörü başlat
   */
  aboutToAppear() {
    this.generateHourlyData()
    this.subscribePedometer()
    this.animateStepCount()
  }

  /**
   * Temizleme
   */
  aboutToDisappear() {
    if (this.mockStepTimer !== -1) clearInterval(this.mockStepTimer)
    if (this.animationTimer !== -1) clearInterval(this.animationTimer)
    if (this.sensorConnected) {
      try {
        sensor.off(sensor.SensorId.PEDOMETER)
      } catch (e) {
        // Hata durumunda sessizce geç
      }
    }
  }

  /**
   * Adım sayısını animasyonlu göster (0'dan başlayıp mevcut değere çıkar)
   */
  private animateStepCount() {
    const target = this.stats.totalSteps
    const duration = 800  // ms
    const steps = 30
    const increment = target / steps
    let current = 0

    this.animationTimer = setInterval(() => {
      current += increment
      if (current >= target) {
        this.displayedSteps = target
        clearInterval(this.animationTimer)
      } else {
        this.displayedSteps = Math.round(current)
      }
    }, duration / steps)
  }

  /**
   * Son 24 saatlik saatlik adım dağılımını oluştur
   */
  private generateHourlyData() {
    const currentHour = new Date().getHours()
    const data: DailyStepRecord[] = []

    for (let h = 0; h <= 23; h++) {
      let steps = 0
      let active = false

      if (h <= currentHour) {
        if (h >= 7 && h <= 9) {
          // Sabah rutini
          steps = 400 + Math.floor(Math.random() * 300)
          active = true
        } else if (h >= 12 && h <= 13) {
          // Öğle yürüyüşü
          steps = 800 + Math.floor(Math.random() * 400)
          active = true
        } else if (h >= 17 && h <= 19) {
          // Akşam yürüyüşü
          steps = 1200 + Math.floor(Math.random() * 600)
          active = true
        } else if (h >= 6 && h <= currentHour) {
          // Diğer aktif saatler
          steps = Math.floor(Math.random() * 200)
          active = steps > 50
        }
      }

      data.push({ hour: h, steps, active })
    }
    this.hourlyData = data
  }

  /**
   * Pedometer sensörüne abone ol
   */
  private subscribePedometer() {
    try {
      sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
        if (data && data.steps > 0) {
          this.addSteps(data.steps)
          this.sensorConnected = true
        }
      }, { interval: 1000000000 })
      console.info('[StepCounter] Pedometer sensörü bağlandı')
    } catch (error) {
      console.warn(`[StepCounter] Pedometer bağlanamadı: ${JSON.stringify(error)}, mock kullanılıyor`)
      this.startMockPedometer()
    }
  }

  /**
   * Mock pedometer - her 2-4 saniyede 1-5 adım ekler
   */
  private startMockPedometer() {
    this.mockStepTimer = setInterval(() => {
      if (this.isTracking) {
        const newSteps = Math.floor(Math.random() * 5) + 1
        this.addSteps(newSteps)
      }
    }, 2000 + Math.random() * 2000)
  }

  /**
   * Yeni adımları istatistiklere ekle ve kalori/mesafeyi güncelle
   */
  private addSteps(newSteps: number) {
    const updatedTotal = this.stats.totalSteps + newSteps
    this.stats = {
      ...this.stats,
      totalSteps: Math.min(updatedTotal, this.stats.dailyGoal * 2),
      calories: this.calculateCalories(updatedTotal),
      distanceKm: this.calculateDistance(updatedTotal),
      currentPace: newSteps * 30  // Yaklaşık adım/dakika
    }
    this.displayedSteps = this.stats.totalSteps
  }

  /**
   * Kalori hesaplama formülü
   * Kalori = (MET × Ağırlık × Süre_saat)
   * Süre = Adım / Hız(adım/saat)
   */
  private calculateCalories(steps: number): number {
    const hoursWalked = steps / 5000  // ~5000 adım/saat varsayımı
    return Math.round(WALKING_MET * USER_PARAMS.WEIGHT_KG * hoursWalked)
  }

  /**
   * Mesafe hesaplama: Adım × Adım Uzunluğu
   */
  private calculateDistance(steps: number): number {
    return Math.round((steps * USER_PARAMS.STRIDE_LENGTH_M) / 100) / 10
  }

  /**
   * İlerleme yüzdesi (0.0 - 1.0)
   */
  private getProgress(): number {
    return Math.min(1.0, this.stats.totalSteps / this.stats.dailyGoal)
  }

  /**
   * Hedef tamamlama mesajı
   */
  private getMotivationMessage(): string {
    const progress = this.getProgress()
    const remaining = this.stats.dailyGoal - this.stats.totalSteps

    if (progress >= 1.0) return '🎉 Günlük hedefe ulaştın!'
    if (progress >= 0.9) return `Neredeyse! ${remaining} adım kaldı`
    if (progress >= 0.75) return `Harika gidiyorsun! ${remaining} adım kaldı`
    if (progress >= 0.5) return `Yarı yoldasın! ${remaining} adım kaldı`
    if (progress >= 0.25) return `Devam et! ${remaining} adım kaldı`
    return `Hadi başla! ${remaining} adım kaldı`
  }

  /**
   * Progress rengini ilerlemeye göre belirle
   */
  private getProgressColor(): string {
    const p = this.getProgress()
    if (p >= 1.0) return '#FFD700'  // Altın - tamamlandı
    if (p >= 0.75) return '#00C853' // Yeşil - çok iyi
    if (p >= 0.5) return '#4FC3F7'  // Mavi - iyi
    if (p >= 0.25) return '#FFA500' // Turuncu - orta
    return '#FF6B35'                 // Kırmızı - az
  }

  /**
   * Saatlik grafikte maksimum adımı bul
   */
  private getMaxHourlySteps(): number {
    return Math.max(...this.hourlyData.map(d => d.steps), 1)
  }

  build() {
    Column() {
      // ── Başlık Çubuğu ────────────────────────────────────────────
      Row() {
        Button('←')
          .fontSize(18)
          .backgroundColor(Color.Transparent)
          .fontColor('#FFFFFF')
          .width(36)
          .height(36)
          .borderRadius(18)
          .onClick(() => router.back())

        Text('Adım Sayar')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Takip Durumu Toggle
        Toggle({ type: ToggleType.Switch, isOn: this.isTracking })
          .selectedColor('#00C853')
          .onChange((isOn: boolean) => {
            this.isTracking = isOn
            this.statusMessage = isOn ? 'Takip aktif' : 'Takip duraklatıldı'
          })
          .width(36)
          .height(20)
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 4 })

      Scroll() {
        Column({ space: 10 }) {

          // ── Ana Dairesel Progress ─────────────────────────────────
          Column() {
            RingProgress({
              progress: this.getProgress(),
              size: 140,
              strokeWidth: 12,
              activeColor: this.getProgressColor(),
              backgroundColor: '#1A1A1A',
              centerContent: () => {
                Column() {
                  Text(this.displayedSteps.toLocaleString())
                    .fontSize(24)
                    .fontColor('#FFFFFF')
                    .fontWeight(FontWeight.Bold)

                  Text('/ ' + this.stats.dailyGoal.toLocaleString())
                    .fontSize(11)
                    .fontColor('#888888')

                  Text('ADIM')
                    .fontSize(9)
                    .fontColor('#666666')
                    .margin({ top: 2 })
                }
              }
            })

            Text(this.getMotivationMessage())
              .fontSize(11)
              .fontColor('#AAAAAA')
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
              .width('90%')

            // Durum göstergesi
            Row() {
              Circle({ width: 6, height: 6 })
                .fill(this.isTracking ? '#00C853' : '#888888')
              Text(` ${this.statusMessage}`)
                .fontSize(10)
                .fontColor('#888888')
            }
            .margin({ top: 4 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#0D0D0D')
          .borderRadius(16)
          .alignItems(HorizontalAlign.Center)

          // ── İstatistik Kartları Izgara ────────────────────────────
          Grid() {
            // Kalori
            GridItem() {
              Column() {
                Text('🔥')
                  .fontSize(20)
                Text(this.stats.calories.toString())
                  .fontSize(18)
                  .fontColor('#FF6B35')
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 4 })
                Text('kcal')
                  .fontSize(10)
                  .fontColor('#888888')
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#1A0A0A')
              .borderRadius(12)
              .alignItems(HorizontalAlign.Center)
            }

            // Mesafe
            GridItem() {
              Column() {
                Text('📍')
                  .fontSize(20)
                Text(this.stats.distanceKm.toFixed(1))
                  .fontSize(18)
                  .fontColor('#00BCD4')
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 4 })
                Text('km')
                  .fontSize(10)
                  .fontColor('#888888')
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#0A1A1A')
              .borderRadius(12)
              .alignItems(HorizontalAlign.Center)
            }

            // Aktif Dakika
            GridItem() {
              Column() {
                Text('⏱️')
                  .fontSize(20)
                Text(this.stats.activeMinutes.toString())
                  .fontSize(18)
                  .fontColor('#FFD700')
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 4 })
                Text('dk aktif')
                  .fontSize(10)
                  .fontColor('#888888')
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#1A1A0A')
              .borderRadius(12)
              .alignItems(HorizontalAlign.Center)
            }

            // Günlük Tamamlama %
            GridItem() {
              Column() {
                Text('🎯')
                  .fontSize(20)
                Text(`${Math.round(this.getProgress() * 100)}%`)
                  .fontSize(18)
                  .fontColor(this.getProgressColor())
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 4 })
                Text('hedef')
                  .fontSize(10)
                  .fontColor('#888888')
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#0D1A0D')
              .borderRadius(12)
              .alignItems(HorizontalAlign.Center)
            }
          }
          .columnsTemplate('1fr 1fr')
          .rowsGap(8)
          .columnsGap(8)
          .width('100%')

          // ── Saatlik Adım Grafiği ──────────────────────────────────
          Column() {
            Text('Saatlik Dağılım')
              .fontSize(11)
              .fontColor('#AAAAAA')
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 8 })

            // Grafik çubukları
            Row({ space: 1 }) {
              ForEach(this.hourlyData, (record: DailyStepRecord) => {
                Column()
                  .width(9)
                  .height(record.steps > 0
                    ? Math.max(4, (record.steps / this.getMaxHourlySteps()) * 36)
                    : 4)
                  .backgroundColor(
                    record.active
                      ? (record.steps > this.getMaxHourlySteps() * 0.7 ? '#00C853' : '#4FC3F7')
                      : '#2A2A2A'
                  )
                  .borderRadius(2)
              })
            }
            .width('100%')
            .height(44)
            .alignItems(VerticalAlign.Bottom)

            // Saat etiketleri (sadece önemli saatler)
            Row() {
              Text('00')
                .fontSize(8)
                .fontColor('#555555')
              Blank()
              Text('06')
                .fontSize(8)
                .fontColor('#555555')
              Blank()
              Text('12')
                .fontSize(8)
                .fontColor('#555555')
              Blank()
              Text('18')
                .fontSize(8)
                .fontColor('#555555')
              Blank()
              Text('23')
                .fontSize(8)
                .fontColor('#555555')
            }
            .width('100%')
            .margin({ top: 4 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#111111')
          .borderRadius(12)

          // ── Adım Hedefi Ayarı ─────────────────────────────────────
          Column() {
            Text('Günlük Hedef')
              .fontSize(11)
              .fontColor('#AAAAAA')
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 8 })

            Row({ space: 8 }) {
              ForEach([5000, 7500, 10000, 15000], (goal: number) => {
                Button(goal >= 1000 ? `${goal / 1000}K` : goal.toString())
                  .fontSize(11)
                  .height(28)
                  .layoutWeight(1)
                  .backgroundColor(
                    this.stats.dailyGoal === goal ? '#00C853' : '#1A1A1A'
                  )
                  .fontColor(
                    this.stats.dailyGoal === goal ? '#000000' : '#888888'
                  )
                  .borderRadius(8)
                  .onClick(() => {
                    this.stats = { ...this.stats, dailyGoal: goal }
                  })
              })
            }
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
  }
}
