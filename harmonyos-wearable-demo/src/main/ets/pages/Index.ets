/**
 * Index.ets - Main Dashboard Page
 *
 * Entry screen for the HarmonyOS Wearable Health Tracking App.
 * Provides tab-based navigation to step counter, heart rate,
 * and sleep analysis features.
 *
 * Designed for wearable screen size: 466x466 px (round) assumed.
 */

import router from '@ohos.router'
import { HealthCard } from '../components/HealthCard'
import { RingProgress } from '../components/RingProgress'

// Tab item definition
interface TabItem {
  label: string
  icon: string
  route: string
}

// Instant health summary data
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
  // Active tab index
  @State private activeTab: number = 0

  // Health summary data (mock)
  @State private healthSummary: HealthSummary = {
    steps: 7842,
    stepGoal: 10000,
    heartRate: 72,
    sleepScore: 85,
    calories: 312,
    distance: 5.8
  }

  // Loading state
  @State private isLoading: boolean = true

  // Current time
  @State private currentTime: string = ''

  // Timer ID
  private timerId: number = -1

  // Tab configuration
  private tabs: TabItem[] = [
    { label: 'Summary', icon: '❤', route: '' },
    { label: 'Steps', icon: '👟', route: 'pages/StepCounter' },
    { label: 'Heart', icon: '💓', route: 'pages/HeartRate' },
    { label: 'Sleep', icon: '🌙', route: 'pages/SleepTracker' }
  ]

  /**
   * Called when the component is created.
   * Starts clock updates and mock data simulation.
   */
  aboutToAppear() {
    this.updateTime()
    this.startMockDataSimulation()
    // Update clock every second
    this.timerId = setInterval(() => {
      this.updateTime()
    }, 1000)

    // Loading simulation
    setTimeout(() => {
      this.isLoading = false
    }, 800)
  }

  /**
   * Clear timer when component is destroyed
   */
  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
  }

  /**
   * Updates the current time in HH:MM format
   */
  private updateTime() {
    const now = new Date()
    const hours = now.getHours().toString().padStart(2, '0')
    const minutes = now.getMinutes().toString().padStart(2, '0')
    this.currentTime = `${hours}:${minutes}`
  }

  /**
   * Mock data simulation - mimics real sensor data
   * Updates heart rate slightly every 3 seconds
   */
  private startMockDataSimulation() {
    setInterval(() => {
      // Simulate heart rate with ±2 BPM variation
      const variation = Math.floor(Math.random() * 5) - 2
      this.healthSummary = {
        ...this.healthSummary,
        heartRate: Math.max(55, Math.min(110, this.healthSummary.heartRate + variation)),
        // Gradually increase step count
        steps: Math.min(this.healthSummary.stepGoal, this.healthSummary.steps + Math.floor(Math.random() * 3))
      }
    }, 3000)
  }

  /**
   * Calculates step completion percentage
   */
  private getStepProgress(): number {
    return this.healthSummary.steps / this.healthSummary.stepGoal
  }

  /**
   * Returns color based on heart rate status
   */
  private getHeartRateColor(): string {
    const bpm = this.healthSummary.heartRate
    if (bpm > 120) return '#FF4444'  // Tachycardia warning
    if (bpm > 100) return '#FFA500'  // High
    if (bpm < 50) return '#4169E1'   // Low
    return '#00C853'                  // Normal
  }

  /**
   * Navigate to the specified route
   */
  private navigateTo(route: string) {
    if (route) {
      router.pushUrl({ url: route })
        .catch((err: Error) => {
          console.error(`[Index] Navigation error: ${err.message}`)
        })
    }
  }

  build() {
    Column() {
      // ── Status Bar ─────────────────────────────────────────────
      Row() {
        Text(this.currentTime)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)

        Blank()

        // Battery indicator (mock)
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
        // ── Loading Screen ─────────────────────────────────────
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#00C853')
          Text('Loading health data...')
            .fontSize(12)
            .fontColor('#888888')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      } else {
        // ── Main Content ────────────────────────────────────────
        Scroll() {
          Column({ space: 12 }) {

            // Main Ring Progress (Step Counter)
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
                    Text('steps')
                      .fontSize(10)
                      .fontColor('#888888')
                  }
                }
              })

              Text(`Goal: ${this.healthSummary.stepGoal.toLocaleString()} steps`)
                .fontSize(11)
                .fontColor('#888888')
                .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 8 })

            // ── Health Metric Cards ────────────────────────────
            // Heart Rate Card
            HealthCard({
              title: 'Heart Rate',
              value: this.healthSummary.heartRate.toString(),
              unit: 'BPM',
              iconName: '💓',
              trend: this.healthSummary.heartRate > 80 ? 'up' : 'stable',
              accentColor: this.getHeartRateColor(),
              onClick: () => this.navigateTo('pages/HeartRate')
            })

            // Steps Card
            HealthCard({
              title: "Today's Steps",
              value: this.healthSummary.steps.toLocaleString(),
              unit: 'steps',
              iconName: '👟',
              trend: 'up',
              accentColor: '#00C853',
              onClick: () => this.navigateTo('pages/StepCounter')
            })

            // Calories Card
            HealthCard({
              title: 'Calories Burned',
              value: this.healthSummary.calories.toString(),
              unit: 'kcal',
              iconName: '🔥',
              trend: 'up',
              accentColor: '#FF6B35',
              onClick: () => this.navigateTo('pages/StepCounter')
            })

            // Sleep Score Card
            HealthCard({
              title: 'Sleep Score',
              value: this.healthSummary.sleepScore.toString(),
              unit: '/ 100',
              iconName: '🌙',
              trend: this.healthSummary.sleepScore >= 75 ? 'up' : 'down',
              accentColor: '#7B68EE',
              onClick: () => this.navigateTo('pages/SleepTracker')
            })

            // Distance Card
            HealthCard({
              title: 'Distance',
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

      // ── Bottom Tab Navigation ──────────────────────────────────
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
