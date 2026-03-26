/**
 * Index.ets - Ana Dashboard Sayfası
 *
 * HarmonyOS Wearable Sağlık Takip Uygulaması ana ekranı.
 * Adım sayar, kalp atışı ve uyku analizi özelliklerine
 * tab navigasyonu ile erişim sağlar.
 *
 * Wearable ekran boyutu: 466x466 px (yuvarlak) varsayımıyla tasarlanmıştır.
 */

import router from '@ohos.router'
import { HealthCard } from '../components/HealthCard'
import { RingProgress } from '../components/RingProgress'

// Sekme tanımları
interface TabItem {
  label: string
  icon: string
  route: string
}

// Anlık sağlık özeti verisi
interface HealthSummary {
  steps: number
  stepGoal: number
  heartRate: number
  sleepScore: number
  calories: number
  distance: number
}

@Entry
@Component
struct Index {
  // Aktif sekme indeksi
  @State private activeTab: number = 0

  // Sağlık özeti verileri (mock)
  @State private healthSummary: HealthSummary = {
    steps: 7842,
    stepGoal: 10000,
    heartRate: 72,
    sleepScore: 85,
    calories: 312,
    distance: 5.8
  }

  // Yükleniyor durumu
  @State private isLoading: boolean = true

  // Mevcut saat
  @State private currentTime: string = ''

  // Zamanlayıcı kimliği
  private timerId: number = -1

  // Tab konfigürasyonu
  private tabs: TabItem[] = [
    { label: 'Özet', icon: '❤', route: '' },
    { label: 'Adım', icon: '👟', route: 'pages/StepCounter' },
    { label: 'Kalp', icon: '💓', route: 'pages/HeartRate' },
    { label: 'Uyku', icon: '🌙', route: 'pages/SleepTracker' }
  ]

  /**
   * Bileşen oluşturulduğunda çalışır.
   * Saat güncellemesini ve mock veri simülasyonunu başlatır.
   */
  aboutToAppear() {
    this.updateTime()
    this.startMockDataSimulation()
    // 1 saniye aralıklarla saati güncelle
    this.timerId = setInterval(() => {
      this.updateTime()
    }, 1000)

    // Yükleme simülasyonu
    setTimeout(() => {
      this.isLoading = false
    }, 800)
  }

  /**
   * Bileşen yok edildiğinde zamanlayıcıyı temizle
   */
  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
  }

  /**
   * Geçerli saati HH:MM formatında günceller
   */
  private updateTime() {
    const now = new Date()
    const hours = now.getHours().toString().padStart(2, '0')
    const minutes = now.getMinutes().toString().padStart(2, '0')
    this.currentTime = `${hours}:${minutes}`
  }

  /**
   * Mock veri simülasyonu - gerçek sensör verisini taklit eder
   * Her 3 saniyede bir kalp atışını hafifçe değiştirir
   */
  private startMockDataSimulation() {
    setInterval(() => {
      // Kalp atışını ±2 BPM aralığında simüle et
      const variation = Math.floor(Math.random() * 5) - 2
      this.healthSummary = {
        ...this.healthSummary,
        heartRate: Math.max(55, Math.min(110, this.healthSummary.heartRate + variation)),
        // Adımları yavaşça artır
        steps: Math.min(this.healthSummary.stepGoal, this.healthSummary.steps + Math.floor(Math.random() * 3))
      }
    }, 3000)
  }

  /**
   * Adım tamamlanma yüzdesini hesaplar
   */
  private getStepProgress(): number {
    return this.healthSummary.steps / this.healthSummary.stepGoal
  }

  /**
   * Kalp atışı durumuna göre renk döndürür
   */
  private getHeartRateColor(): string {
    const bpm = this.healthSummary.heartRate
    if (bpm > 120) return '#FF4444'  // Taşikardi uyarısı
    if (bpm > 100) return '#FFA500'  // Yüksek
    if (bpm < 50) return '#4169E1'   // Düşük
    return '#00C853'                  // Normal
  }

  /**
   * Belirtilen rotaya yönlendir
   */
  private navigateTo(route: string) {
    if (route) {
      router.pushUrl({ url: route })
        .catch((err: Error) => {
          console.error(`[Index] Navigasyon hatası: ${err.message}`)
        })
    }
  }

  build() {
    Column() {
      // ── Üst Durum Çubuğu ──────────────────────────────────────────
      Row() {
        Text(this.currentTime)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)

        Blank()

        // Batarya göstergesi (mock)
        Row() {
          Text('78%')
            .fontSize(11)
            .fontColor('#AAAAAA')
          Text(' 🔋')
            .fontSize(11)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 4 })

      if (this.isLoading) {
        // ── Yükleme Ekranı ──────────────────────────────────────────
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#00C853')
          Text('Sağlık verileri yükleniyor...')
            .fontSize(12)
            .fontColor('#888888')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      } else {
        // ── Ana İçerik ───────────────────────────────────────────────
        Scroll() {
          Column({ space: 12 }) {

            // Ana Halka Progress (Adım Sayar)
            Column() {
              RingProgress({
                progress: this.getStepProgress(),
                size: 120,
                strokeWidth: 10,
                activeColor: '#00C853',
                backgroundColor: '#1A3A1A',
                centerContent: () => {
                  Column() {
                    Text(this.healthSummary.steps.toLocaleString())
                      .fontSize(22)
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Bold)
                    Text('adım')
                      .fontSize(10)
                      .fontColor('#888888')
                  }
                }
              })

              Text(`Hedef: ${this.healthSummary.stepGoal.toLocaleString()} adım`)
                .fontSize(11)
                .fontColor('#888888')
                .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 8 })

            // ── Sağlık Metrik Kartları ─────────────────────────────
            // Kalp Atışı Kartı
            HealthCard({
              title: 'Kalp Atışı',
              value: this.healthSummary.heartRate.toString(),
              unit: 'BPM',
              iconName: '💓',
              trend: this.healthSummary.heartRate > 80 ? 'up' : 'stable',
              accentColor: this.getHeartRateColor(),
              onClick: () => this.navigateTo('pages/HeartRate')
            })

            // Adım Kartı
            HealthCard({
              title: 'Bugünkü Adımlar',
              value: this.healthSummary.steps.toLocaleString(),
              unit: 'adım',
              iconName: '👟',
              trend: 'up',
              accentColor: '#00C853',
              onClick: () => this.navigateTo('pages/StepCounter')
            })

            // Kalori Kartı
            HealthCard({
              title: 'Yakılan Kalori',
              value: this.healthSummary.calories.toString(),
              unit: 'kcal',
              iconName: '🔥',
              trend: 'up',
              accentColor: '#FF6B35',
              onClick: () => this.navigateTo('pages/StepCounter')
            })

            // Uyku Skoru Kartı
            HealthCard({
              title: 'Uyku Skoru',
              value: this.healthSummary.sleepScore.toString(),
              unit: '/ 100',
              iconName: '🌙',
              trend: this.healthSummary.sleepScore >= 75 ? 'up' : 'down',
              accentColor: '#7B68EE',
              onClick: () => this.navigateTo('pages/SleepTracker')
            })

            // Mesafe Kartı
            HealthCard({
              title: 'Mesafe',
              value: this.healthSummary.distance.toFixed(1),
              unit: 'km',
              iconName: '📍',
              trend: 'stable',
              accentColor: '#00BCD4',
              onClick: () => this.navigateTo('pages/StepCounter')
            })

          }
          .padding({ left: 12, right: 12, bottom: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }

      // ── Alt Tab Navigasyon ────────────────────────────────────────
      Row() {
        ForEach(this.tabs, (tab: TabItem, index: number) => {
          Column() {
            Text(tab.icon)
              .fontSize(index === this.activeTab ? 22 : 18)
              .opacity(index === this.activeTab ? 1.0 : 0.5)
              .animation({ duration: 200, curve: Curve.EaseOut })

            Text(tab.label)
              .fontSize(9)
              .fontColor(index === this.activeTab ? '#00C853' : '#666666')
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .height(50)
          .onClick(() => {
            this.activeTab = index
            if (tab.route) {
              this.navigateTo(tab.route)
            }
          })
        })
      }
      .width('100%')
      .backgroundColor('#0D0D0D')
      .border({ width: { top: 0.5 }, color: '#2A2A2A' })

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
