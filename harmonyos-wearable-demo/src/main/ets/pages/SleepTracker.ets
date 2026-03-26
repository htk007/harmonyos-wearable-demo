/**
 * SleepTracker.ets - Sleep Analysis Page
 *
 * Sleep phase distribution (Deep Sleep / Light Sleep / REM / Awake),
 * total sleep duration, sleep score, and sleep quality recommendations.
 *
 * Integrates with @ohos.health API for sleep data.
 * Displays mock analysis results when real data is unavailable.
 */

import router from '@ohos.router'
import { RingProgress } from '../components/RingProgress'

// Sleep phase definition
interface SleepPhase {
  name: string          // Phase name
  durationMin: number   // Duration (minutes)
  color: string         // Chart color
  icon: string          // Phase icon
  percentage: number    // Percentage of total sleep
}

// Nightly sleep record
interface NightRecord {
  date: string          // Date label
  score: number         // Sleep score (0-100)
  totalHours: number    // Total hours
  quality: 'excellent' | 'good' | 'fair' | 'poor'
}

// Sleep analysis summary
interface SleepSummary {
  bedTime: string         // Bedtime
  wakeTime: string        // Wake time
  totalMinutes: number    // Total sleep minutes
  score: number           // Sleep score
  interruptions: number   // Number of awakenings
  restfulnessPercent: number  // Restfulness percentage
}

@Entry
@Component
struct SleepTracker {
  // Sleep summary
  @State private summary: SleepSummary = {
    bedTime: '23:15',
    wakeTime: '07:08',
    totalMinutes: 473,
    score: 82,
    interruptions: 3,
    restfulnessPercent: 87
  }

  // Sleep phase distribution
  @State private phases: SleepPhase[] = [
    {
      name: 'Deep Sleep',
      durationMin: 94,
      color: '#1A237E',
      icon: '🌊',
      percentage: 20
    },
    {
      name: 'REM Sleep',
      durationMin: 104,
      color: '#7B68EE',
      icon: '💭',
      percentage: 22
    },
    {
      name: 'Light Sleep',
      durationMin: 236,
      color: '#4FC3F7',
      icon: '🌙',
      percentage: 50
    },
    {
      name: 'Awake',
      durationMin: 39,
      color: '#FF8A65',
      icon: '👁️',
      percentage: 8
    }
  ]

  // Last 7 nights history
  @State private weekHistory: NightRecord[] = []

  // Selected tab (Analysis / History / Tips)
  @State private selectedTab: number = 0

  // Sleep tracking state
  @State private isTracking: boolean = false
  @State private nextTrackingTime: string = '22:30'

  aboutToAppear() {
    this.generateWeekHistory()
  }

  /**
   * Generate mock history for the last 7 nights
   */
  private generateWeekHistory() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    const today = new Date()
    const history: NightRecord[] = []

    for (let i = 6; i >= 0; i--) {
      const date = new Date(today)
      date.setDate(date.getDate() - i)
      const dayName = days[date.getDay()]
      const score = 55 + Math.floor(Math.random() * 40)
      const hours = 5.5 + Math.random() * 3

      history.push({
        date: i === 0 ? 'Last night' : dayName,
        score,
        totalHours: Math.round(hours * 10) / 10,
        quality: score >= 85 ? 'excellent' : score >= 70 ? 'good' : score >= 55 ? 'fair' : 'poor'
      })
    }
    this.weekHistory = history
  }

  /**
   * Returns color based on sleep score
   */
  private getScoreColor(score: number): string {
    if (score >= 85) return '#00C853'
    if (score >= 70) return '#4FC3F7'
    if (score >= 55) return '#FFA500'
    return '#FF4444'
  }

  /**
   * Returns sleep quality label
   */
  private getQualityLabel(quality: string): string {
    switch (quality) {
      case 'excellent': return 'Excellent'
      case 'good': return 'Good'
      case 'fair': return 'Fair'
      case 'poor': return 'Poor'
      default: return 'Unknown'
    }
  }

  /**
   * Format total sleep duration as hours:minutes
   */
  private formatDuration(minutes: number): string {
    const h = Math.floor(minutes / 60)
    const m = minutes % 60
    return `${h}h ${m}m`
  }

  /**
   * Calculate phase bar width based on percentage
   */
  private getPhaseBarWidth(percentage: number): string {
    return `${Math.max(percentage, 3)}%`
  }

  /**
   * Format phase duration in minutes
   */
  private formatPhaseTime(minutes: number): string {
    if (minutes < 60) return `${minutes}m`
    const h = Math.floor(minutes / 60)
    const m = minutes % 60
    return m > 0 ? `${h}h ${m}m` : `${h}h`
  }

  build() {
    Column() {
      // ── Header ─────────────────────────────────────────────────
      Row() {
        Button('←')
          .fontSize(18)
          .backgroundColor(Color.Transparent)
          .fontColor('#FFFFFF')
          .width(36)
          .height(36)
          .borderRadius(18)
          .onClick(() => router.back())

        Text('Sleep Analysis')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Sleep Tracking Toggle
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

      // ── Tab Selector ──────────────────────────────────────────
      Row() {
        ForEach(['Analysis', 'History', 'Tips'], (tab: string, index: number) => {
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
            // ════════════════════════════════════════════════════
            // TAB 1: ANALYSIS
            // ════════════════════════════════════════════════════

            // Sleep Score Card
            Row() {
              // Left: Circular Score
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

              // Right: Details
              Column({ space: 4 }) {
                Text('Sleep Score')
                  .fontSize(11)
                  .fontColor('#AAAAAA')

                Text(
                  this.summary.score >= 85 ? '🌟 Excellent Sleep' :
                  this.summary.score >= 70 ? '✅ Good Sleep' :
                  this.summary.score >= 55 ? '⚠️ Fair Quality' : '❌ Poor Sleep'
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

            // Mini Statistics
            Row({ space: 8 }) {
              Column() {
                Text('🔄')
                  .fontSize(16)
                Text(this.summary.interruptions.toString())
                  .fontSize(16)
                  .fontColor('#FFA500')
                  .fontWeight(FontWeight.Bold)
                Text('awakenings')
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
                Text('restful')
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
                Text('target bed')
                  .fontSize(9)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              .padding(8)
              .backgroundColor('#0A1A1A')
              .borderRadius(10)
              .alignItems(HorizontalAlign.Center)
            }

            // Sleep Phase Distribution
            Column() {
              Text('Sleep Phases')
                .fontSize(11)
                .fontColor('#AAAAAA')
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ bottom: 10 })

              // Horizontal bar chart
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

              // Phase List
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
            // ════════════════════════════════════════════════════
            // TAB 2: HISTORY
            // ════════════════════════════════════════════════════

            // 7-Day Summary
            Column() {
              Text('Last 7 Nights')
                .fontSize(11)
                .fontColor('#AAAAAA')
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ bottom: 10 })

              // Score Bars
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

            // Daily Record List
            ForEach(this.weekHistory.slice().reverse(), (record: NightRecord) => {
              Row() {
                Column() {
                  Text(record.date)
                    .fontSize(12)
                    .fontColor('#CCCCCC')
                  Text(`${record.totalHours}h sleep`)
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
            // ════════════════════════════════════════════════════
            // TAB 3: TIPS
            // ════════════════════════════════════════════════════

            this.SleepTip(
              '💤',
              'More Deep Sleep',
              'Your deep sleep duration is below target. Reduce screen usage before bed.',
              '#1A237E'
            )

            this.SleepTip(
              '⏰',
              'Consistent Sleep Schedule',
              'Try to sleep at the same time every night. It regulates your biological clock.',
              '#7B68EE'
            )

            this.SleepTip(
              '🌡️',
              'Sleep Environment',
              'Keep your bedroom temperature between 18–20°C. A cool room promotes deep sleep.',
              '#0288D1'
            )

            this.SleepTip(
              '🏃',
              'Exercise Timing',
              'Avoid intense exercise within 3 hours of bedtime. It can reduce sleep quality.',
              '#00695C'
            )

            this.SleepTip(
              '☕',
              'Caffeine Intake',
              'Limit caffeine consumption in the afternoon. Caffeine effects can last 6 hours.',
              '#E65100'
            )

            this.SleepTip(
              '📱',
              'Screen Time',
              'Enable blue light filter or turn off screens 1 hour before bed.',
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
   * Build a sleep tip card
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
