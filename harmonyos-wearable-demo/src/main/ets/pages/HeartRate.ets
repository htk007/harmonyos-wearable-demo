/**
 * HeartRate.ets - Heart Rate Monitor Page
 *
 * Real-time BPM monitoring, minimum/maximum/average values,
 * tachycardia (>120 BPM) and bradycardia (<50 BPM) alerts.
 *
 * Integrates with @ohos.sensor API for accelerometer/PPG sensor.
 * Falls back to mock data simulation when real hardware is unavailable.
 */

import router from '@ohos.router'
import sensor from '@ohos.sensor'

// Heart rate measurement record
interface HeartRateRecord {
  bpm: number
  timestamp: number
  status: 'normal' | 'high' | 'low' | 'critical'
}

// BPM threshold values
const THRESHOLD = {
  BRADYCARDIA: 50,    // Bradycardia lower limit
  NORMAL_LOW: 60,     // Normal range lower limit
  NORMAL_HIGH: 100,   // Normal range upper limit
  TACHYCARDIA: 120    // Tachycardia upper limit
}

@Entry
@Component
struct HeartRate {
  // Current BPM value
  @State private currentBPM: number = 72

  // Statistics values
  @State private minBPM: number = 72
  @State private maxBPM: number = 72
  @State private avgBPM: number = 72

  // Measurement history (last 20 values)
  @State private history: HeartRateRecord[] = []

  // Measurement state
  @State private isMeasuring: boolean = false
  @State private measureProgress: number = 0
  @State private statusMessage: string = 'Tap to start measuring'
  @State private alertMessage: string = ''
  @State private showAlert: boolean = false

  // Pulse animation
  @State private pulseScale: number = 1.0

  // Timers
  private measureTimer: number = -1
  private pulseTimer: number = -1
  private mockDataTimer: number = -1
  private sensorSubscribed: boolean = false

  /**
   * Prepare initial data when component loads
   */
  aboutToAppear() {
    this.initMockHistory()
    this.startPulseAnimation()
    // Auto-start first measurement
    this.startMeasurement()
  }

  /**
   * Clean up resources when component is destroyed
   */
  aboutToDisappear() {
    this.stopAllTimers()
    this.unsubscribeSensor()
  }

  /**
   * Stop all timers
   */
  private stopAllTimers() {
    if (this.measureTimer !== -1) clearInterval(this.measureTimer)
    if (this.pulseTimer !== -1) clearInterval(this.pulseTimer)
    if (this.mockDataTimer !== -1) clearInterval(this.mockDataTimer)
  }

  /**
   * Pulse animation - heartbeat effect
   */
  private startPulseAnimation() {
    this.pulseTimer = setInterval(() => {
      // Grow/shrink heart icon animation
      this.pulseScale = 1.2
      setTimeout(() => {
        this.pulseScale = 1.0
      }, 150)
    }, 60000 / Math.max(this.currentBPM, 40)) // Speed based on BPM
  }

  /**
   * Generate 10 mock history records for initial display
   */
  private initMockHistory() {
    const baseTime = Date.now()
    for (let i = 9; i >= 0; i--) {
      const bpm = 65 + Math.floor(Math.random() * 20)
      this.history.push({
        bpm,
        timestamp: baseTime - i * 300000, // 5-minute intervals
        status: this.getBPMStatus(bpm)
      })
    }
    this.recalculateStats()
  }

  /**
   * Returns status based on BPM value
   */
  private getBPMStatus(bpm: number): 'normal' | 'high' | 'low' | 'critical' {
    if (bpm >= THRESHOLD.TACHYCARDIA) return 'critical'
    if (bpm > THRESHOLD.NORMAL_HIGH) return 'high'
    if (bpm < THRESHOLD.BRADYCARDIA) return 'critical'
    if (bpm < THRESHOLD.NORMAL_LOW) return 'low'
    return 'normal'
  }

  /**
   * Recalculate Min/Max/Avg statistics
   */
  private recalculateStats() {
    if (this.history.length === 0) return
    const bpms = this.history.map(r => r.bpm)
    this.minBPM = Math.min(...bpms)
    this.maxBPM = Math.max(...bpms)
    this.avgBPM = Math.round(bpms.reduce((a, b) => a + b, 0) / bpms.length)
  }

  /**
   * Attempt to subscribe to heart rate sensor.
   * Falls back to mock data on failure.
   */
  private subscribeSensor() {
    try {
      // HarmonyOS PPG sensor (for heart rate)
      sensor.on(sensor.SensorId.HEART_RATE, (data: sensor.HeartRateResponse) => {
        if (data && data.heartRate > 0) {
          this.updateBPM(data.heartRate)
        }
      }, { interval: 1000000000 }) // 1 second interval (nanoseconds)
      this.sensorSubscribed = true
      console.info('[HeartRate] Real sensor connected')
    } catch (error) {
      // Sensor unavailable, use mock
      console.warn(`[HeartRate] Sensor unavailable, using mock: ${JSON.stringify(error)}`)
      this.startMockSensor()
    }
  }

  /**
   * Unsubscribe from sensor
   */
  private unsubscribeSensor() {
    if (this.sensorSubscribed) {
      try {
        sensor.off(sensor.SensorId.HEART_RATE)
        this.sensorSubscribed = false
      } catch (e) {
        console.warn('[HeartRate] Failed to unsubscribe from sensor')
      }
    }
  }

  /**
   * Mock sensor simulation - updates BPM every second
   */
  private startMockSensor() {
    // Realistic heart rate simulation
    let trend = 0
    this.mockDataTimer = setInterval(() => {
      trend += (Math.random() - 0.5) * 0.5
      trend = Math.max(-5, Math.min(5, trend))
      const newBPM = Math.round(this.currentBPM + trend + (Math.random() - 0.5) * 2)
      this.updateBPM(Math.max(45, Math.min(140, newBPM)))
    }, 1000)
  }

  /**
   * Update BPM value and check for alerts
   */
  private updateBPM(bpm: number) {
    this.currentBPM = bpm
    const status = this.getBPMStatus(bpm)

    // Tachycardia check
    if (status === 'critical' && bpm >= THRESHOLD.TACHYCARDIA) {
      this.alertMessage = `⚠️ TACHYCARDIA ALERT\nYour heart rate is too high: ${bpm} BPM`
      this.showAlert = true
    } else if (status === 'critical' && bpm < THRESHOLD.BRADYCARDIA) {
      this.alertMessage = `⚠️ BRADYCARDIA ALERT\nYour heart rate is too low: ${bpm} BPM`
      this.showAlert = true
    } else {
      this.showAlert = false
    }

    // Save to history (every 10 seconds)
    const now = Date.now()
    const lastRecord = this.history[this.history.length - 1]
    if (!lastRecord || now - lastRecord.timestamp > 10000) {
      this.history.push({ bpm, timestamp: now, status })
      // Keep last 50 records
      if (this.history.length > 50) {
        this.history = this.history.slice(-50)
      }
      this.recalculateStats()
    }
  }

  /**
   * Start a 30-second active measurement cycle
   */
  private startMeasurement() {
    this.isMeasuring = true
    this.measureProgress = 0
    this.statusMessage = 'Measuring...'
    this.subscribeSensor()

    // 30-second progress bar
    let elapsed = 0
    this.measureTimer = setInterval(() => {
      elapsed += 1
      this.measureProgress = elapsed / 30
      if (elapsed >= 30) {
        clearInterval(this.measureTimer)
        this.isMeasuring = false
        this.statusMessage = 'Measurement complete'
        // Switch to continuous monitoring mode
      }
    }, 1000)
  }

  /**
   * Returns status color
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
   * Returns status label
   */
  private getBPMLabel(): string {
    const status = this.getBPMStatus(this.currentBPM)
    switch (status) {
      case 'critical': return this.currentBPM >= THRESHOLD.TACHYCARDIA ? 'TACHYCARDIA' : 'BRADYCARDIA'
      case 'high': return 'HIGH'
      case 'low': return 'LOW'
      default: return 'NORMAL'
    }
  }

  /**
   * Calculate bar height for BPM chart
   */
  private getBarHeight(bpm: number): number {
    const minH = 8
    const maxH = 40
    const normalized = (bpm - 40) / (160 - 40)
    return minH + normalized * (maxH - minH)
  }

  build() {
    Stack() {
      // ── Main Content ────────────────────────────────────────────
      Column() {
        // Back Button and Title
        Row() {
          Button('←')
            .fontSize(18)
            .backgroundColor(Color.Transparent)
            .fontColor('#FFFFFF')
            .width(36)
            .height(36)
            .borderRadius(18)
            .onClick(() => router.back())

          Text('Heart Rate')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // Empty space - for alignment
          Column().width(36)
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 8, bottom: 4 })

        Scroll() {
          Column({ space: 10 }) {

            // ── Live BPM Display ──────────────────────────────────
            Column() {
              // Heart Icon (with pulse animation)
              Text('❤️')
                .fontSize(32)
                .scale({ x: this.pulseScale, y: this.pulseScale })
                .animation({
                  duration: 150,
                  curve: Curve.EaseOut
                })

              // BPM Value
              Text(this.currentBPM.toString())
                .fontSize(48)
                .fontColor(this.getStatusColor())
                .fontWeight(FontWeight.Bold)
                .margin({ top: 4 })

              Text('BPM')
                .fontSize(14)
                .fontColor('#888888')

              // Status Label
              Text(this.getBPMLabel())
                .fontSize(12)
                .fontColor(this.getStatusColor())
                .fontWeight(FontWeight.Medium)
                .backgroundColor(`${this.getStatusColor()}22`)
                .borderRadius(8)
                .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                .margin({ top: 6 })

              // Measurement Progress Bar
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

            // ── Statistics Cards ──────────────────────────────────
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

              // Average
              Column() {
                Text('⌀ AVG')
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

            // ── Mini BPM Chart ────────────────────────────────────
            Column() {
              Text('Recent Readings')
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

            // ── Heart Rate Zones ──────────────────────────────────
            Column({ space: 6 }) {
              Text('Heart Rate Zones')
                .fontSize(11)
                .fontColor('#AAAAAA')
                .width('100%')
                .textAlign(TextAlign.Start)

              // Each zone row
              this.HeartRateZoneRow('Bradycardia', '< 50 BPM', '#4169E1', 50)
              this.HeartRateZoneRow('Normal', '60–100 BPM', '#00C853', 100)
              this.HeartRateZoneRow('Elevated', '100–120 BPM', '#FFA500', 120)
              this.HeartRateZoneRow('Tachycardia', '> 120 BPM', '#FF4444', 140)
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

      // ── Tachycardia/Bradycardia Alert Overlay ────────────────────
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
   * Build a heart rate zone row
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

      // Indicator if current value is in this zone
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
