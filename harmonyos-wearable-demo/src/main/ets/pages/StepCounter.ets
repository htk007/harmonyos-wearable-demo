/**
 * StepCounter.ets - Step Counter Page
 *
 * Daily step goal tracking (default: 10,000 steps),
 * circular progress indicator, calorie estimation, and distance calculation.
 *
 * Integrates with @ohos.sensor API for pedometer sensor.
 * Falls back to mock data simulation when real hardware is unavailable.
 */

import router from '@ohos.router'
import sensor from '@ohos.sensor'
import { RingProgress } from '../components/RingProgress'

// Daily step record
interface DailyStepRecord {
  hour: number       // Hour (0-23)
  steps: number      // Steps taken in that hour
  active: boolean    // Was it an active hour?
}

// Step counter statistics
interface StepStats {
  totalSteps: number
  dailyGoal: number
  calories: number
  distanceKm: number
  activeMinutes: number
  currentPace: number    // Steps per minute
}

// User parameters (for calorie/distance calculation)
const USER_PARAMS = {
  WEIGHT_KG: 70,
  HEIGHT_CM: 175,
  STRIDE_LENGTH_M: 0.78  // Average stride length (meters)
}

// MET value (metabolic equivalent for walking)
const WALKING_MET = 3.5

@Entry
@Component
struct StepCounter {
  // Step statistics
  @State private stats: StepStats = {
    totalSteps: 7842,
    dailyGoal: 10000,
    calories: 312,
    distanceKm: 6.12,
    activeMinutes: 68,
    currentPace: 0
  }

  // Hourly distribution chart data
  @State private hourlyData: DailyStepRecord[] = []

  // Live step counter animation value
  @State private displayedSteps: number = 0

  // Active tracking state
  @State private isTracking: boolean = true
  @State private statusMessage: string = 'Tracking active'

  // Pedometer sensor connected?
  private sensorConnected: boolean = false
  private mockStepTimer: number = -1
  private animationTimer: number = -1

  /**
   * Initialize data and start sensor on mount
   */
  aboutToAppear() {
    this.generateHourlyData()
    this.subscribePedometer()
    this.animateStepCount()
  }

  /**
   * Cleanup on unmount
   */
  aboutToDisappear() {
    if (this.mockStepTimer !== -1) clearInterval(this.mockStepTimer)
    if (this.animationTimer !== -1) clearInterval(this.animationTimer)
    if (this.sensorConnected) {
      try {
        sensor.off(sensor.SensorId.PEDOMETER)
      } catch (e) {
        // Silently ignore errors
      }
    }
  }

  /**
   * Animate step count from 0 to current value
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
   * Generate hourly step distribution for the last 24 hours
   */
  private generateHourlyData() {
    const currentHour = new Date().getHours()
    const data: DailyStepRecord[] = []

    for (let h = 0; h <= 23; h++) {
      let steps = 0
      let active = false

      if (h <= currentHour) {
        if (h >= 7 && h <= 9) {
          // Morning routine
          steps = 400 + Math.floor(Math.random() * 300)
          active = true
        } else if (h >= 12 && h <= 13) {
          // Lunch walk
          steps = 800 + Math.floor(Math.random() * 400)
          active = true
        } else if (h >= 17 && h <= 19) {
          // Evening walk
          steps = 1200 + Math.floor(Math.random() * 600)
          active = true
        } else if (h >= 6 && h <= currentHour) {
          // Other active hours
          steps = Math.floor(Math.random() * 200)
          active = steps > 50
        }
      }

      data.push({ hour: h, steps, active })
    }
    this.hourlyData = data
  }

  /**
   * Subscribe to pedometer sensor
   */
  private subscribePedometer() {
    try {
      sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
        if (data && data.steps > 0) {
          this.addSteps(data.steps)
          this.sensorConnected = true
        }
      }, { interval: 1000000000 })
      console.info('[StepCounter] Pedometer sensor connected')
    } catch (error) {
      console.warn(`[StepCounter] Pedometer unavailable: ${JSON.stringify(error)}, using mock`)
      this.startMockPedometer()
    }
  }

  /**
   * Mock pedometer - adds 1-5 steps every 2-4 seconds
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
   * Add new steps to statistics and update calorie/distance
   */
  private addSteps(newSteps: number) {
    const updatedTotal = this.stats.totalSteps + newSteps
    this.stats = {
      ...this.stats,
      totalSteps: Math.min(updatedTotal, this.stats.dailyGoal * 2),
      calories: this.calculateCalories(updatedTotal),
      distanceKm: this.calculateDistance(updatedTotal),
      currentPace: newSteps * 30  // Approximate steps per minute
    }
    this.displayedSteps = this.stats.totalSteps
  }

  /**
   * Calorie calculation formula
   * Calories = (MET × Weight × Duration_hours)
   * Duration = Steps / Speed(steps/hour)
   */
  private calculateCalories(steps: number): number {
    const hoursWalked = steps / 5000  // ~5000 steps/hour assumption
    return Math.round(WALKING_MET * USER_PARAMS.WEIGHT_KG * hoursWalked)
  }

  /**
   * Distance calculation: Steps × Stride Length
   */
  private calculateDistance(steps: number): number {
    return Math.round((steps * USER_PARAMS.STRIDE_LENGTH_M) / 100) / 10
  }

  /**
   * Progress percentage (0.0 - 1.0)
   */
  private getProgress(): number {
    return Math.min(1.0, this.stats.totalSteps / this.stats.dailyGoal)
  }

  /**
   * Goal completion motivation message
   */
  private getMotivationMessage(): string {
    const progress = this.getProgress()
    const remaining = this.stats.dailyGoal - this.stats.totalSteps

    if (progress >= 1.0) return '🎉 Daily goal reached!'
    if (progress >= 0.9) return `Almost there! ${remaining} steps to go`
    if (progress >= 0.75) return `Great progress! ${remaining} steps to go`
    if (progress >= 0.5) return `Halfway there! ${remaining} steps to go`
    if (progress >= 0.25) return `Keep going! ${remaining} steps to go`
    return `Let's get moving! ${remaining} steps to go`
  }

  /**
   * Progress color based on completion
   */
  private getProgressColor(): string {
    const p = this.getProgress()
    if (p >= 1.0) return '#FFD700'  // Gold - complete
    if (p >= 0.75) return '#00C853' // Green - great
    if (p >= 0.5) return '#4FC3F7'  // Blue - good
    if (p >= 0.25) return '#FFA500' // Orange - fair
    return '#FF6B35'                 // Red - low
  }

  /**
   * Find maximum steps in hourly chart
   */
  private getMaxHourlySteps(): number {
    return Math.max(...this.hourlyData.map(d => d.steps), 1)
  }

  build() {
    Column() {
      // ── Title Bar ─────────────────────────────────────────────
      Row() {
        Button('←')
          .fontSize(18)
          .backgroundColor(Color.Transparent)
          .fontColor('#FFFFFF')
          .width(36)
          .height(36)
          .borderRadius(18)
          .onClick(() => router.back())

        Text('Step Counter')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Tracking toggle
        Toggle({ type: ToggleType.Switch, isOn: this.isTracking })
          .selectedColor('#00C853')
          .onChange((isOn: boolean) => {
            this.isTracking = isOn
            this.statusMessage = isOn ? 'Tracking active' : 'Tracking paused'
          })
          .width(36)
          .height(20)
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 4 })

      Scroll() {
        Column({ space: 10 }) {

          // ── Main Circular Progress ────────────────────────────
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

                  Text('STEPS')
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

            // Status indicator
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

          // ── Statistics Grid ───────────────────────────────────
          Grid() {
            // Calories
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

            // Distance
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

            // Active Minutes
            GridItem() {
              Column() {
                Text('⏱️')
                  .fontSize(20)
                Text(this.stats.activeMinutes.toString())
                  .fontSize(18)
                  .fontColor('#FFD700')
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 4 })
                Text('min active')
                  .fontSize(10)
                  .fontColor('#888888')
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#1A1A0A')
              .borderRadius(12)
              .alignItems(HorizontalAlign.Center)
            }

            // Daily Completion %
            GridItem() {
              Column() {
                Text('🎯')
                  .fontSize(20)
                Text(`${Math.round(this.getProgress() * 100)}%`)
                  .fontSize(18)
                  .fontColor(this.getProgressColor())
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 4 })
                Text('goal')
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

          // ── Hourly Step Chart ─────────────────────────────────
          Column() {
            Text('Hourly Distribution')
              .fontSize(11)
              .fontColor('#AAAAAA')
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 8 })

            // Chart bars
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

            // Hour labels (key hours only)
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

          // ── Daily Goal Selector ───────────────────────────────
          Column() {
            Text('Daily Goal')
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
