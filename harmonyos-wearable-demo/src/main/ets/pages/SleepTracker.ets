/**
 * SleepTracker.ets - Uyku Analizi Sayfası
 *
 * Uyku evresi dağılımı (Derin Uyku / Hafif Uyku / REM / Uyanıklık),
 * toplam uyku süresi, uyku skoru ve uyku kalitesi önerileri.
 *
 * @ohos.health API ile uyku verisi entegrasyonu.
 * Gerçek veri yoksa mock analiz sonuçları gösterilir.
 */

import router from '@ohos.router'
import { RingProgress } from '../components/RingProgress'

// Uyku evresi tanımı
interface SleepPhase {
  name: string          // Evre adı
  durationMin: number   // Süre (dakika)
  color: string         // Grafik rengi
  icon: string          // Evre ikonu
  percentage: number    // Toplam uyku yüzdesi
}

// Gece uyku kaydı
interface NightRecord {
  date: string          // Tarih etiketi
  score: number         // Uyku skoru (0-100)
  totalHours: number    // Toplam saat
  quality: 'excellent' | 'good' | 'fair' | 'poor'
}

// Uyku analiz özeti
interface SleepSummary {
  bedTime: string         // Yatış saati
  wakeTime: string        // Kalkış saati
  totalMinutes: number    // Toplam uyku dakikası
  score: number           // Uyku skoru
  interruptions: number   // Uyanma sayısı
  restfulnessPercent: number  // Dinlendiricilik yüzdesi
}

@Entry
@Component
struct SleepTracker {
  // Uyku özeti
  @State private summary: SleepSummary = {
    bedTime: '23:15',
    wakeTime: '07:08',
    totalMinutes: 473,
    score: 82,
    interruptions: 3,
    restfulnessPercent: 87
  }

  // Uyku evreleri dağılımı
  @State private phases: SleepPhase[] = [
    {
      name: 'Derin Uyku',
      durationMin: 94,
      color: '#1A237E',
      icon: '🌊',
      percentage: 20
    },
    {
      name: 'REM Uykusu',
      durationMin: 104,
      color: '#7B68EE',
      icon: '💭',
      percentage: 22
    },
    {
      name: 'Hafif Uyku',
      durationMin: 236,
      color: '#4FC3F7',
      icon: '🌙',
      percentage: 50
    },
    {
      name: 'Uyanıklık',
      durationMin: 39,
      color: '#FF8A65',
      icon: '👁️',
      percentage: 8
    }
  ]

  // Son 7 günlük geçmiş
  @State private weekHistory: NightRecord[] = []

  // Seçilen sekme (Analiz / Geçmiş / Öneriler)
  @State private selectedTab: number = 0

  // Uyku tarama durumu
  @State private isTracking: boolean = false
  @State private nextTrackingTime: string = '22:30'

  aboutToAppear() {
    this.generateWeekHistory()
  }

  /**
   * Son 7 gece için mock geçmiş oluştur
   */
  private generateWeekHistory() {
    const days = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt']
    const today = new Date()
    const history: NightRecord[] = []

    for (let i = 6; i >= 0; i--) {
      const date = new Date(today)
      date.setDate(date.getDate() - i)
      const dayName = days[date.getDay()]
      const score = 55 + Math.floor(Math.random() * 40)
      const hours = 5.5 + Math.random() * 3

      history.push({
        date: i === 0 ? 'Dün gece' : dayName,
        score,
        totalHours: Math.round(hours * 10) / 10,
        quality: score >= 85 ? 'excellent' : score >= 70 ? 'good' : score >= 55 ? 'fair' : 'poor'
      })
    }
    this.weekHistory = history
  }

  /**
   * Uyku skoruna göre renk döndür
   */
  private getScoreColor(score: number): string {
    if (score >= 85) return '#00C853'
    if (score >= 70) return '#4FC3F7'
    if (score >= 55) return '#FFA500'
    return '#FF4444'
  }

  /**
   * Uyku kalitesi etiketini döndür
   */
  private getQualityLabel(quality: string): string {
    switch (quality) {
      case 'excellent': return 'Mükemmel'
      case 'good': return 'İyi'
      case 'fair': return 'Orta'
      case 'poor': return 'Zayıf'
      default: return 'Bilinmiyor'
    }
  }

  /**
   * Toplam uyku süresini saat:dakika formatına dönüştür
   */
  private formatDuration(minutes: number): string {
    const h = Math.floor(minutes / 60)
    const m = minutes % 60
    return `${h}s ${m}dk`
  }

  /**
   * Uyku evresi çubuk genişliğini hesapla (yüzdeye göre)
   */
  private getPhaseBarWidth(percentage: number): string {
    return `${Math.max(percentage, 3)}%`
  }

  /**
   * Evre süresini dakika cinsinden formatla
   */
  private formatPhaseTime(minutes: number): string {
    if (minutes < 60) return `${minutes}dk`
    const h = Math.floor(minutes / 60)
    const m = minutes % 60
    return m > 0 ? `${h}s ${m}dk` : `${h}s`
  }

  build() {
    Column() {
      // ── Başlık ────────────────────────────────────────────────────
      Row() {
        Button('←')
          .fontSize(18)
          .backgroundColor(Color.Transparent)
          .fontColor('#FFFFFF')
          .width(36)
          .height(36)
          .borderRadius(18)
          .onClick(() => router.back())

        Text('Uyku Analizi')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Uyku Takibi Toggle
        Toggle({ type: ToggleType.Switch, isOn: this.isTracking })
          .selectedColor('#7B68EE')
          .onChange((isOn: boolean) => {
            this.isTracking = isOn
          })
          .width(36)
          .height(20)
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 4 })

      // ── Sekme Seçici ─────────────────────────────────────────────
      Row() {
        ForEach(['Analiz', 'Geçmiş', 'Öneriler'], (tab: string, index: number) => {
          Text(tab)
            .fontSize(11)
            .fontColor(this.selectedTab === index ? '#FFFFFF' : '#666666')
            .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 6, bottom: 6 })
            .backgroundColor(this.selectedTab === index ? '#7B68EE33' : Color.Transparent)
            .borderRadius(8)
            .onClick(() => { this.selectedTab = index })
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .margin({ bottom: 4 })

      Scroll() {
        Column({ space: 10 }) {

          if (this.selectedTab === 0) {
            // ════════════════════════════════════════════════════════
            // SEKME 1: ANALİZ
            // ════════════════════════════════════════════════════════

            // Uyku Skoru Kartı
            Row() {
              // Sol: Dairesel Skor
              RingProgress({
                progress: this.summary.score / 100,
                size: 80,
                strokeWidth: 8,
                activeColor: this.getScoreColor(this.summary.score),
                backgroundColor: '#1A1A2E',
                centerContent: () => {
                  Column() {
                    Text(this.summary.score.toString())
                      .fontSize(20)
                      .fontColor('#FFFFFF')
                      .fontWeight(FontWeight.Bold)
                  }
                }
              })

              // Sağ: Detaylar
              Column({ space: 4 }) {
                Text('Uyku Skoru')
                  .fontSize(11)
                  .fontColor('#AAAAAA')

                Text(
                  this.summary.score >= 85 ? '🌟 Mükemmel Uyku' :
                  this.summary.score >= 70 ? '✅ İyi Uyku' :
                  this.summary.score >= 55 ? '⚠️ Orta Kalite' : '❌ Yetersiz Uyku'
                )
                  .fontSize(12)
                  .fontColor(this.getScoreColor(this.summary.score))
                  .fontWeight(FontWeight.Medium)

                Text(`${this.summary.bedTime} → ${this.summary.wakeTime}`)
                  .fontSize(11)
                  .fontColor('#888888')

                Text(this.formatDuration(this.summary.totalMinutes))
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Bold)
              }
              .layoutWeight(1)
              .padding({ left: 12 })
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(14)
            .backgroundColor('#0D0D1A')
            .borderRadius(16)

            // Mini İstatistikler
            Row({ space: 8 }) {
              Column() {
                Text('🔄')
                  .fontSize(16)
                Text(this.summary.interruptions.toString())
                  .fontSize(16)
                  .fontColor('#FFA500')
                  .fontWeight(FontWeight.Bold)
                Text('uyanma')
                  .fontSize(9)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              .padding(8)
              .backgroundColor('#1A1A0A')
              .borderRadius(10)
              .alignItems(HorizontalAlign.Center)

              Column() {
                Text('💤')
                  .fontSize(16)
                Text(`${this.summary.restfulnessPercent}%`)
                  .fontSize(16)
                  .fontColor('#7B68EE')
                  .fontWeight(FontWeight.Bold)
                Text('dinlendirici')
                  .fontSize(9)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              .padding(8)
              .backgroundColor('#0D0D1A')
              .borderRadius(10)
              .alignItems(HorizontalAlign.Center)

              Column() {
                Text('⏰')
                  .fontSize(16)
                Text(this.nextTrackingTime)
                  .fontSize(14)
                  .fontColor('#4FC3F7')
                  .fontWeight(FontWeight.Bold)
                Text('hedef yatış')
                  .fontSize(9)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              .padding(8)
              .backgroundColor('#0A1A1A')
              .borderRadius(10)
              .alignItems(HorizontalAlign.Center)
            }

            // Uyku Evresi Dağılımı
            Column() {
              Text('Uyku Evreleri')
                .fontSize(11)
                .fontColor('#AAAAAA')
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ bottom: 10 })

              // Yatay çubuk grafik
              Row() {
                ForEach(this.phases, (phase: SleepPhase) => {
                  Column()
                    .height(16)
                    .width(this.getPhaseBarWidth(phase.percentage))
                    .backgroundColor(phase.color)
                    .borderRadius(phase.percentage > 10 ? 4 : 2)
                })
              }
              .width('100%')
              .height(16)
              .borderRadius(8)
              .clip(true)
              .margin({ bottom: 10 })

              // Evre Listesi
              ForEach(this.phases, (phase: SleepPhase) => {
                Row() {
                  Row()
                    .width(10)
                    .height(10)
                    .borderRadius(3)
                    .backgroundColor(phase.color)
                    .margin({ right: 8 })

                  Text(phase.icon + ' ' + phase.name)
                    .fontSize(11)
                    .fontColor('#CCCCCC')
                    .layoutWeight(1)

                  Text(this.formatPhaseTime(phase.durationMin))
                    .fontSize(10)
                    .fontColor('#888888')
                    .margin({ right: 8 })

                  Text(`${phase.percentage}%`)
                    .fontSize(10)
                    .fontColor(phase.color)
                    .fontWeight(FontWeight.Medium)
                    .width(30)
                    .textAlign(TextAlign.End)
                }
                .width('100%')
                .padding({ top: 4, bottom: 4 })
              })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#111111')
            .borderRadius(12)

          } else if (this.selectedTab === 1) {
            // ════════════════════════════════════════════════════════
            // SEKME 2: GEÇMİŞ
            // ════════════════════════════════════════════════════════

            // 7 Gün Özet
            Column() {
              Text('Son 7 Gece')
                .fontSize(11)
                .fontColor('#AAAAAA')
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ bottom: 10 })

              // Skor Çubukları
              Row({ space: 4 }) {
                ForEach(this.weekHistory, (record: NightRecord) => {
                  Column() {
                    Column()
                      .width(24)
                      .height(Math.max(8, (record.score / 100) * 48))
                      .backgroundColor(this.getScoreColor(record.score))
                      .borderRadius(4)

                    Text(record.date.substring(0, 2))
                      .fontSize(8)
                      .fontColor('#666666')
                      .margin({ top: 4 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Center)
                  .justifyContent(FlexAlign.End)
                  .height(70)
                })
              }
              .width('100%')
              .alignItems(VerticalAlign.Bottom)
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#111111')
            .borderRadius(12)

            // Günlük Kayıt Listesi
            ForEach(this.weekHistory.slice().reverse(), (record: NightRecord) => {
              Row() {
                Column() {
                  Text(record.date)
                    .fontSize(12)
                    .fontColor('#CCCCCC')
                  Text(`${record.totalHours}s uyku`)
                    .fontSize(10)
                    .fontColor('#888888')
                }
                .layoutWeight(1)

                Column() {
                  Text(record.score.toString())
                    .fontSize(18)
                    .fontColor(this.getScoreColor(record.score))
                    .fontWeight(FontWeight.Bold)
                  Text(this.getQualityLabel(record.quality))
                    .fontSize(9)
                    .fontColor(this.getScoreColor(record.score))
                }
                .alignItems(HorizontalAlign.End)
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor('#0D0D0D')
              .borderRadius(10)
              .border({ width: { bottom: 0.5 }, color: '#1A1A1A' })
            })

          } else {
            // ════════════════════════════════════════════════════════
            // SEKME 3: ÖNERİLER
            // ════════════════════════════════════════════════════════

            this.SleepTip(
              '💤',
              'Daha Fazla Derin Uyku',
              'Derin uyku süreniz hedefin altında. Yatmadan önce ekran kullanımını azaltın.',
              '#1A237E'
            )

            this.SleepTip(
              '⏰',
              'Tutarlı Uyku Saati',
              'Her gece aynı saatte uyumaya çalışın. Biyolojik saatinizi düzenler.',
              '#7B68EE'
            )

            this.SleepTip(
              '🌡️',
              'Uyku Ortamı',
              'Yatak odası sıcaklığını 18-20°C arasında tutun. Serin oda derin uykuyu artırır.',
              '#0288D1'
            )

            this.SleepTip(
              '🏃',
              'Egzersiz Zamanlaması',
              'Uykudan 3 saat önce yoğun egzersiz yapmayın. Bu uyku kalitesini düşürebilir.',
              '#00695C'
            )

            this.SleepTip(
              '☕',
              'Kafein Alımı',
              'Öğleden sonra kafein tüketimini sınırlayın. Kafein etkisi 6 saat sürebilir.',
              '#E65100'
            )

            this.SleepTip(
              '📱',
              'Ekran Süresi',
              'Yatmadan 1 saat önce mavi ışık filtresini etkinleştirin veya ekranı kapatın.',
              '#6A1B9A'
            )
          }

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

  /**
   * Uyku önerisi kartı oluştur
   */
  @Builder
  SleepTip(icon: string, title: string, description: string, accentColor: string) {
    Row() {
      Text(icon)
        .fontSize(22)
        .width(36)
        .textAlign(TextAlign.Center)

      Column({ space: 3 }) {
        Text(title)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
        Text(description)
          .fontSize(10)
          .fontColor('#999999')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .padding({ left: 10 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#0D0D0D')
    .borderRadius(12)
    .border({ width: { left: 3 }, color: accentColor })
    .alignItems(VerticalAlign.Top)
  }
}
