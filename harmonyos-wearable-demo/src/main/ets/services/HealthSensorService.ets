/**
 * HealthSensorService.ets - Health Sensor Service
 *
 * Provides access to HarmonyOS wearable sensors using @ohos.sensor API.
 * Supported sensors:
 *   - PEDOMETER (Step counter)
 *   - HEART_RATE (Heart rate monitor)
 *   - ACCELEROMETER (Activity detection)
 *
 * Automatically falls back to realistic mock data simulation
 * when real sensor hardware is unavailable.
 */

import sensor from '@ohos.sensor'

// Sensor data update callback types
type StepCallback = (steps: number) => void
type HeartRateCallback = (bpm: number) => void
type AccelerometerCallback = (x: number, y: number, z: number) => void

// Sensor status
export enum SensorStatus {
  DISCONNECTED = 'disconnected',    // Not connected
  CONNECTING = 'connecting',        // Connecting
  CONNECTED = 'connected',          // Connected (real sensor)
  MOCK = 'mock',                    // Mock mode active
  ERROR = 'error'                   // Error state
}

// Activity type (detected via accelerometer)
export enum ActivityType {
  STATIONARY = 'stationary',    // Not moving
  WALKING = 'walking',          // Walking
  RUNNING = 'running',          // Running
  CYCLING = 'cycling'           // Cycling
}

// Sensor reading data structure
export interface SensorReading {
  timestamp: number
  value: number
  unit: string
  accuracy: 'high' | 'medium' | 'low'
}

// Accelerometer data
export interface AccelerometerData {
  x: number
  y: number
  z: number
  magnitude: number     // Total acceleration magnitude
  timestamp: number
}

/**
 * HealthSensorService class
 * Used as a singleton.
 */
export class HealthSensorService {
  // Singleton instance
  private static instance: HealthSensorService | null = null

  // Sensor statuses
  private pedometerStatus: SensorStatus = SensorStatus.DISCONNECTED
  private heartRateStatus: SensorStatus = SensorStatus.DISCONNECTED
  private accelerometerStatus: SensorStatus = SensorStatus.DISCONNECTED

  // Callback lists (for multiple listeners)
  private stepCallbacks: StepCallback[] = []
  private heartRateCallbacks: HeartRateCallback[] = []
  private accelCallbacks: AccelerometerCallback[] = []

  // Mock sensor timers
  private mockPedometerTimer: number = -1
  private mockHeartRateTimer: number = -1
  private mockAccelTimer: number = -1

  // Last known values
  private lastStepCount: number = 0
  private lastHeartRate: number = 72
  private lastAccelData: AccelerometerData = { x: 0, y: 0, z: 9.8, magnitude: 9.8, timestamp: 0 }

  // Mock data simulation state
  private mockHeartRateTrend: number = 0
  private mockActivityLevel: number = 0.3
  private mockCurrentActivity: ActivityType = ActivityType.WALKING

  private constructor() {
    console.info('[HealthSensorService] Service initialized')
  }

  /**
   * Returns the singleton instance
   */
  static getInstance(): HealthSensorService {
    if (!HealthSensorService.instance) {
      HealthSensorService.instance = new HealthSensorService()
    }
    return HealthSensorService.instance
  }

  // ──────────────────────────────────────────────────────────────
  // PEDOMETER (STEP COUNTER)
  // ──────────────────────────────────────────────────────────────

  /**
   * Start the pedometer sensor.
   * Falls back to mock simulation on error.
   *
   * @param callback - Function called on each step update
   */
  startPedometer(callback: StepCallback): void {
    this.stepCallbacks.push(callback)

    if (this.pedometerStatus === SensorStatus.CONNECTED ||
        this.pedometerStatus === SensorStatus.MOCK) {
      // Already active, just add callback
      return
    }

    this.pedometerStatus = SensorStatus.CONNECTING

    try {
      // Connect to real pedometer sensor
      sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
        if (data.steps > 0) {
          this.lastStepCount += data.steps
          this.notifyStepCallbacks(this.lastStepCount)
        }
      }, {
        interval: 1000000000  // 1 second (in nanoseconds)
      })

      this.pedometerStatus = SensorStatus.CONNECTED
      console.info('[HealthSensorService] Pedometer sensor connected')

    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error)
      console.warn(`[HealthSensorService] Pedometer unavailable (${errMsg}), starting mock`)
      this.pedometerStatus = SensorStatus.MOCK
      this.startMockPedometer()
    }
  }

  /**
   * Remove pedometer listener
   */
  stopPedometer(callback: StepCallback): void {
    this.stepCallbacks = this.stepCallbacks.filter(cb => cb !== callback)

    if (this.stepCallbacks.length === 0) {
      if (this.pedometerStatus === SensorStatus.CONNECTED) {
        try {
          sensor.off(sensor.SensorId.PEDOMETER)
        } catch (e) { /* silently ignore */ }
      }
      if (this.mockPedometerTimer !== -1) {
        clearInterval(this.mockPedometerTimer)
        this.mockPedometerTimer = -1
      }
      this.pedometerStatus = SensorStatus.DISCONNECTED
    }
  }

  /**
   * Mock pedometer simulation
   * Realistic step pattern: 80-120 steps/minute during walking periods
   */
  private startMockPedometer(): void {
    // Initial step count based on time of day
    const hour = new Date().getHours()
    if (hour >= 8 && hour <= 20) {
      this.lastStepCount = Math.floor(1000 + Math.random() * 6000)
    } else {
      this.lastStepCount = Math.floor(Math.random() * 1000)
    }

    // Add a few steps each second
    this.mockPedometerTimer = setInterval(() => {
      // Step increment based on activity level
      const stepsPerSecond = this.mockActivityLevel > 0.5
        ? Math.floor(Math.random() * 3) + 1  // Active: 1-3 steps/second
        : Math.random() < 0.3 ? 1 : 0       // Inactive: occasional step

      if (stepsPerSecond > 0) {
        this.lastStepCount += stepsPerSecond
        this.notifyStepCallbacks(this.lastStepCount)
      }

      // Randomly vary activity level
      this.mockActivityLevel = Math.max(0, Math.min(1,
        this.mockActivityLevel + (Math.random() - 0.5) * 0.05
      ))
    }, 1000)
  }

  private notifyStepCallbacks(steps: number): void {
    this.stepCallbacks.forEach(cb => {
      try { cb(steps) } catch (e) { /* callback error */ }
    })
  }

  // ──────────────────────────────────────────────────────────────
  // HEART RATE
  // ──────────────────────────────────────────────────────────────

  /**
   * Start heart rate sensor.
   *
   * @param callback - Function called on BPM update
   * @param intervalMs - Measurement interval (ms, default: 1000)
   */
  startHeartRateMonitor(callback: HeartRateCallback, intervalMs: number = 1000): void {
    this.heartRateCallbacks.push(callback)

    if (this.heartRateStatus === SensorStatus.CONNECTED ||
        this.heartRateStatus === SensorStatus.MOCK) {
      return
    }

    this.heartRateStatus = SensorStatus.CONNECTING

    try {
      sensor.on(sensor.SensorId.HEART_RATE, (data: sensor.HeartRateResponse) => {
        if (data.heartRate > 0 && data.heartRate < 250) {
          this.lastHeartRate = data.heartRate
          this.notifyHeartRateCallbacks(data.heartRate)
        }
      }, {
        interval: intervalMs * 1000000  // ms -> ns conversion
      })

      this.heartRateStatus = SensorStatus.CONNECTED
      console.info('[HealthSensorService] Heart Rate sensor connected')

    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error)
      console.warn(`[HealthSensorService] Heart Rate unavailable (${errMsg}), starting mock`)
      this.heartRateStatus = SensorStatus.MOCK
      this.startMockHeartRate(intervalMs)
    }
  }

  /**
   * Stop heart rate monitor
   */
  stopHeartRateMonitor(callback: HeartRateCallback): void {
    this.heartRateCallbacks = this.heartRateCallbacks.filter(cb => cb !== callback)

    if (this.heartRateCallbacks.length === 0) {
      if (this.heartRateStatus === SensorStatus.CONNECTED) {
        try {
          sensor.off(sensor.SensorId.HEART_RATE)
        } catch (e) { /* silently ignore */ }
      }
      if (this.mockHeartRateTimer !== -1) {
        clearInterval(this.mockHeartRateTimer)
        this.mockHeartRateTimer = -1
      }
      this.heartRateStatus = SensorStatus.DISCONNECTED
    }
  }

  /**
   * Mock heart rate simulation
   * Generates physiologically realistic BPM changes:
   * - Resting: 60-80 BPM
   * - Light activity: 80-100 BPM
   * - Moderate activity: 100-140 BPM
   * - Intense activity: 140-170 BPM
   */
  private startMockHeartRate(intervalMs: number): void {
    this.mockHeartRateTimer = setInterval(() => {
      // Calculate target BPM based on activity level
      const targetBPM = this.calculateTargetBPM()

      // Smooth transition: gradually move current value toward target
      const diff = targetBPM - this.lastHeartRate
      const step = diff * 0.1 + (Math.random() - 0.5) * 2

      this.lastHeartRate = Math.round(
        Math.max(45, Math.min(180, this.lastHeartRate + step))
      )

      this.notifyHeartRateCallbacks(this.lastHeartRate)
    }, intervalMs)
  }

  /**
   * Calculate target BPM based on activity level
   */
  private calculateTargetBPM(): number {
    const activity = this.mockActivityLevel
    if (activity > 0.8) return 130 + Math.random() * 30  // Intense
    if (activity > 0.6) return 100 + Math.random() * 30  // Moderate
    if (activity > 0.3) return 75 + Math.random() * 25   // Light
    return 60 + Math.random() * 20                        // Resting
  }

  private notifyHeartRateCallbacks(bpm: number): void {
    this.heartRateCallbacks.forEach(cb => {
      try { cb(bpm) } catch (e) { /* callback error */ }
    })
  }

  // ──────────────────────────────────────────────────────────────
  // ACCELEROMETER
  // ──────────────────────────────────────────────────────────────

  /**
   * Start accelerometer sensor.
   * Used for activity detection and sleep analysis.
   *
   * @param callback - Accelerometer data callback
   * @param intervalMs - Sampling interval (ms)
   */
  startAccelerometer(callback: AccelerometerCallback, intervalMs: number = 100): void {
    this.accelCallbacks.push(callback)

    if (this.accelerometerStatus === SensorStatus.CONNECTED ||
        this.accelerometerStatus === SensorStatus.MOCK) {
      return
    }

    this.accelerometerStatus = SensorStatus.CONNECTING

    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
        this.lastAccelData = {
          x: data.x,
          y: data.y,
          z: data.z,
          magnitude: Math.sqrt(data.x ** 2 + data.y ** 2 + data.z ** 2),
          timestamp: Date.now()
        }
        this.notifyAccelCallbacks(data.x, data.y, data.z)
      }, {
        interval: intervalMs * 1000000
      })

      this.accelerometerStatus = SensorStatus.CONNECTED
      console.info('[HealthSensorService] Accelerometer connected')

    } catch (error) {
      console.warn('[HealthSensorService] Accelerometer unavailable, starting mock')
      this.accelerometerStatus = SensorStatus.MOCK
      this.startMockAccelerometer(intervalMs)
    }
  }

  /**
   * Stop accelerometer sensor
   */
  stopAccelerometer(callback: AccelerometerCallback): void {
    this.accelCallbacks = this.accelCallbacks.filter(cb => cb !== callback)

    if (this.accelCallbacks.length === 0) {
      if (this.accelerometerStatus === SensorStatus.CONNECTED) {
        try {
          sensor.off(sensor.SensorId.ACCELEROMETER)
        } catch (e) { /* silently ignore */ }
      }
      if (this.mockAccelTimer !== -1) {
        clearInterval(this.mockAccelTimer)
        this.mockAccelTimer = -1
      }
      this.accelerometerStatus = SensorStatus.DISCONNECTED
    }
  }

  /**
   * Mock accelerometer data generator
   */
  private startMockAccelerometer(intervalMs: number): void {
    let phase = 0
    this.mockAccelTimer = setInterval(() => {
      phase += 0.1
      const noise = this.mockActivityLevel * 0.5

      // Different pattern based on activity
      const x = Math.sin(phase * 1.1) * noise + (Math.random() - 0.5) * 0.1
      const y = Math.cos(phase * 0.9) * noise + (Math.random() - 0.5) * 0.1
      const z = 9.8 + Math.sin(phase * 2) * noise * 0.5

      this.lastAccelData = {
        x, y, z,
        magnitude: Math.sqrt(x ** 2 + y ** 2 + z ** 2),
        timestamp: Date.now()
      }
      this.notifyAccelCallbacks(x, y, z)
    }, intervalMs)
  }

  private notifyAccelCallbacks(x: number, y: number, z: number): void {
    this.accelCallbacks.forEach(cb => {
      try { cb(x, y, z) } catch (e) { /* callback error */ }
    })
  }

  // ──────────────────────────────────────────────────────────────
  // UTILITY METHODS
  // ──────────────────────────────────────────────────────────────

  /**
   * Detect activity type using accelerometer data
   */
  detectActivity(accelData: AccelerometerData): ActivityType {
    const mag = accelData.magnitude
    const variance = Math.abs(mag - 9.8)

    if (variance < 0.3) return ActivityType.STATIONARY
    if (variance < 2.0) return ActivityType.WALKING
    if (variance < 5.0) return ActivityType.RUNNING
    return ActivityType.CYCLING
  }

  /**
   * Returns sensor status information
   */
  getSensorStatus(): Record<string, SensorStatus> {
    return {
      pedometer: this.pedometerStatus,
      heartRate: this.heartRateStatus,
      accelerometer: this.accelerometerStatus
    }
  }

  /**
   * Returns the last heart rate value
   */
  getLastHeartRate(): number {
    return this.lastHeartRate
  }

  /**
   * Returns the last step count
   */
  getLastStepCount(): number {
    return this.lastStepCount
  }

  /**
   * Returns the last accelerometer data
   */
  getLastAccelerometerData(): AccelerometerData {
    return this.lastAccelData
  }

  /**
   * Stop all sensors (when app goes to background)
   */
  stopAllSensors(): void {
    this.stepCallbacks = []
    this.heartRateCallbacks = []
    this.accelCallbacks = []

    try { sensor.off(sensor.SensorId.PEDOMETER) } catch (e) { /* silently ignore */ }
    try { sensor.off(sensor.SensorId.HEART_RATE) } catch (e) { /* silently ignore */ }
    try { sensor.off(sensor.SensorId.ACCELEROMETER) } catch (e) { /* silently ignore */ }

    if (this.mockPedometerTimer !== -1) clearInterval(this.mockPedometerTimer)
    if (this.mockHeartRateTimer !== -1) clearInterval(this.mockHeartRateTimer)
    if (this.mockAccelTimer !== -1) clearInterval(this.mockAccelTimer)

    this.pedometerStatus = SensorStatus.DISCONNECTED
    this.heartRateStatus = SensorStatus.DISCONNECTED
    this.accelerometerStatus = SensorStatus.DISCONNECTED

    console.info('[HealthSensorService] All sensors stopped')
  }
}
