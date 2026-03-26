/**
 * HealthSensorService.ets - Sağlık Sensör Servisi
 *
 * @ohos.sensor API kullanarak HarmonyOS wearable sensörlerine erişim sağlar.
 * Desteklenen sensörler:
 *   - PEDOMETER (Adım sayar)
 *   - HEART_RATE (Kalp atışı)
 *   - ACCELEROMETER (Akselerometre - aktivite tespiti için)
 *
 * Gerçek sensör donanımı yoksa otomatik olarak
 * gerçekçi mock data simülasyonuna geçer.
 */

import sensor from '@ohos.sensor'

// Sensör veri güncelleme callback tipleri
type StepCallback = (steps: number) => void
type HeartRateCallback = (bpm: number) => void
type AccelerometerCallback = (x: number, y: number, z: number) => void

// Sensör durumu
export enum SensorStatus {
  DISCONNECTED = 'disconnected',    // Bağlı değil
  CONNECTING = 'connecting',        // Bağlanıyor
  CONNECTED = 'connected',          // Bağlı (gerçek sensör)
  MOCK = 'mock',                    // Mock mod aktif
  ERROR = 'error'                   // Hata durumu
}

// Aktivite tipi (akselerometre ile tespit)
export enum ActivityType {
  STATIONARY = 'stationary',    // Hareketsiz
  WALKING = 'walking',          // Yürüyüş
  RUNNING = 'running',          // Koşu
  CYCLING = 'cycling'           // Bisiklet
}

// Sensor reading veri yapısı
export interface SensorReading {
  timestamp: number
  value: number
  unit: string
  accuracy: 'high' | 'medium' | 'low'
}

// Akselerometre verisi
export interface AccelerometerData {
  x: number
  y: number
  z: number
  magnitude: number     // Toplam ivme büyüklüğü
  timestamp: number
}

/**
 * HealthSensorService sınıfı
 * Singleton pattern ile kullanılır.
 */
export class HealthSensorService {
  // Singleton instance
  private static instance: HealthSensorService | null = null

  // Sensör durumları
  private pedometerStatus: SensorStatus = SensorStatus.DISCONNECTED
  private heartRateStatus: SensorStatus = SensorStatus.DISCONNECTED
  private accelerometerStatus: SensorStatus = SensorStatus.DISCONNECTED

  // Callback listesi (birden fazla dinleyici için)
  private stepCallbacks: StepCallback[] = []
  private heartRateCallbacks: HeartRateCallback[] = []
  private accelCallbacks: AccelerometerCallback[] = []

  // Mock sensör zamanlayıcıları
  private mockPedometerTimer: number = -1
  private mockHeartRateTimer: number = -1
  private mockAccelTimer: number = -1

  // Son bilinen değerler
  private lastStepCount: number = 0
  private lastHeartRate: number = 72
  private lastAccelData: AccelerometerData = { x: 0, y: 0, z: 9.8, magnitude: 9.8, timestamp: 0 }

  // Mock veri simülasyon state'i
  private mockHeartRateTrend: number = 0
  private mockActivityLevel: number = 0.3
  private mockCurrentActivity: ActivityType = ActivityType.WALKING

  private constructor() {
    console.info('[HealthSensorService] Servis başlatıldı')
  }

  /**
   * Singleton instance'ı döndür
   */
  static getInstance(): HealthSensorService {
    if (!HealthSensorService.instance) {
      HealthSensorService.instance = new HealthSensorService()
    }
    return HealthSensorService.instance
  }

  // ────────────────────────────────────────────────────────────────
  // PEDOMETER (ADIM SAYAR)
  // ────────────────────────────────────────────────────────────────

  /**
   * Adım sayar sensörünü başlat.
   * Hata durumunda mock simülasyona geç.
   *
   * @param callback - Her adım güncellemesinde çağrılacak fonksiyon
   */
  startPedometer(callback: StepCallback): void {
    this.stepCallbacks.push(callback)

    if (this.pedometerStatus === SensorStatus.CONNECTED ||
        this.pedometerStatus === SensorStatus.MOCK) {
      // Zaten aktif, sadece callback ekle
      return
    }

    this.pedometerStatus = SensorStatus.CONNECTING

    try {
      // Gerçek pedometer sensörüne bağlan
      sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
        if (data.steps > 0) {
          this.lastStepCount += data.steps
          this.notifyStepCallbacks(this.lastStepCount)
        }
      }, {
        interval: 1000000000  // 1 saniye (nanosecond cinsinden)
      })

      this.pedometerStatus = SensorStatus.CONNECTED
      console.info('[HealthSensorService] Pedometer sensörü bağlandı')

    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error)
      console.warn(`[HealthSensorService] Pedometer bağlanamadı (${errMsg}), mock başlatılıyor`)
      this.pedometerStatus = SensorStatus.MOCK
      this.startMockPedometer()
    }
  }

  /**
   * Adım sayar dinleyicisini kaldır
   */
  stopPedometer(callback: StepCallback): void {
    this.stepCallbacks = this.stepCallbacks.filter(cb => cb !== callback)

    if (this.stepCallbacks.length === 0) {
      if (this.pedometerStatus === SensorStatus.CONNECTED) {
        try {
          sensor.off(sensor.SensorId.PEDOMETER)
        } catch (e) { /* sessizce geç */ }
      }
      if (this.mockPedometerTimer !== -1) {
        clearInterval(this.mockPedometerTimer)
        this.mockPedometerTimer = -1
      }
      this.pedometerStatus = SensorStatus.DISCONNECTED
    }
  }

  /**
   * Mock pedometer simülasyonu
   * Gerçekçi adım deseni: yürüyüş dönemlerinde 80-120 adım/dakika
   */
  private startMockPedometer(): void {
    // Başlangıç adım sayısı (günün saatine göre)
    const hour = new Date().getHours()
    if (hour >= 8 && hour <= 20) {
      this.lastStepCount = Math.floor(1000 + Math.random() * 6000)
    } else {
      this.lastStepCount = Math.floor(Math.random() * 1000)
    }

    // Her saniye birkaç adım ekle
    this.mockPedometerTimer = setInterval(() => {
      // Aktivite seviyesine göre adım sayısını artır
      const stepsPerSecond = this.mockActivityLevel > 0.5
        ? Math.floor(Math.random() * 3) + 1  // Aktif: 1-3 adım/saniye
        : Math.random() < 0.3 ? 1 : 0       // Pasif: ara sıra 1 adım

      if (stepsPerSecond > 0) {
        this.lastStepCount += stepsPerSecond
        this.notifyStepCallbacks(this.lastStepCount)
      }

      // Aktivite seviyesini rastgele değiştir
      this.mockActivityLevel = Math.max(0, Math.min(1,
        this.mockActivityLevel + (Math.random() - 0.5) * 0.05
      ))
    }, 1000)
  }

  private notifyStepCallbacks(steps: number): void {
    this.stepCallbacks.forEach(cb => {
      try { cb(steps) } catch (e) { /* callback hatası */ }
    })
  }

  // ────────────────────────────────────────────────────────────────
  // HEART RATE (KALP ATIŞI)
  // ────────────────────────────────────────────────────────────────

  /**
   * Kalp atışı sensörünü başlat.
   *
   * @param callback - BPM güncellemesinde çağrılacak fonksiyon
   * @param intervalMs - Ölçüm aralığı (ms, varsayılan: 1000)
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
        interval: intervalMs * 1000000  // ms -> ns dönüşüm
      })

      this.heartRateStatus = SensorStatus.CONNECTED
      console.info('[HealthSensorService] Heart Rate sensörü bağlandı')

    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error)
      console.warn(`[HealthSensorService] Heart Rate bağlanamadı (${errMsg}), mock başlatılıyor`)
      this.heartRateStatus = SensorStatus.MOCK
      this.startMockHeartRate(intervalMs)
    }
  }

  /**
   * Kalp atışı monitörünü durdur
   */
  stopHeartRateMonitor(callback: HeartRateCallback): void {
    this.heartRateCallbacks = this.heartRateCallbacks.filter(cb => cb !== callback)

    if (this.heartRateCallbacks.length === 0) {
      if (this.heartRateStatus === SensorStatus.CONNECTED) {
        try {
          sensor.off(sensor.SensorId.HEART_RATE)
        } catch (e) { /* sessizce geç */ }
      }
      if (this.mockHeartRateTimer !== -1) {
        clearInterval(this.mockHeartRateTimer)
        this.mockHeartRateTimer = -1
      }
      this.heartRateStatus = SensorStatus.DISCONNECTED
    }
  }

  /**
   * Mock kalp atışı simülasyonu
   * Fizyolojik olarak gerçekçi BPM değişimleri üretir:
   * - Dinlenme: 60-80 BPM
   * - Hafif aktivite: 80-100 BPM
   * - Orta aktivite: 100-140 BPM
   * - Yoğun aktivite: 140-170 BPM
   */
  private startMockHeartRate(intervalMs: number): void {
    this.mockHeartRateTimer = setInterval(() => {
      // Aktivite seviyesine göre hedef BPM hesapla
      const targetBPM = this.calculateTargetBPM()

      // Gerçekçi geçiş: mevcut değeri hedefe doğru yavaşça yaklaştır
      const diff = targetBPM - this.lastHeartRate
      const step = diff * 0.1 + (Math.random() - 0.5) * 2

      this.lastHeartRate = Math.round(
        Math.max(45, Math.min(180, this.lastHeartRate + step))
      )

      this.notifyHeartRateCallbacks(this.lastHeartRate)
    }, intervalMs)
  }

  /**
   * Aktivite seviyesine göre hedef BPM hesapla
   */
  private calculateTargetBPM(): number {
    const activity = this.mockActivityLevel
    if (activity > 0.8) return 130 + Math.random() * 30  // Yoğun
    if (activity > 0.6) return 100 + Math.random() * 30  // Orta
    if (activity > 0.3) return 75 + Math.random() * 25   // Hafif
    return 60 + Math.random() * 20                        // Dinlenme
  }

  private notifyHeartRateCallbacks(bpm: number): void {
    this.heartRateCallbacks.forEach(cb => {
      try { cb(bpm) } catch (e) { /* callback hatası */ }
    })
  }

  // ────────────────────────────────────────────────────────────────
  // ACCELEROMETER (AKSELEROMETRe)
  // ────────────────────────────────────────────────────────────────

  /**
   * Akselerometre sensörünü başlat
   * Aktivite tespiti ve uyku analizi için kullanılır.
   *
   * @param callback - Akselerometre verisi callback'i
   * @param intervalMs - Örnekleme aralığı (ms)
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
      console.info('[HealthSensorService] Accelerometer bağlandı')

    } catch (error) {
      console.warn('[HealthSensorService] Accelerometer bağlanamadı, mock başlatılıyor')
      this.accelerometerStatus = SensorStatus.MOCK
      this.startMockAccelerometer(intervalMs)
    }
  }

  /**
   * Akselerometre sensörünü durdur
   */
  stopAccelerometer(callback: AccelerometerCallback): void {
    this.accelCallbacks = this.accelCallbacks.filter(cb => cb !== callback)

    if (this.accelCallbacks.length === 0) {
      if (this.accelerometerStatus === SensorStatus.CONNECTED) {
        try {
          sensor.off(sensor.SensorId.ACCELEROMETER)
        } catch (e) { /* sessizce geç */ }
      }
      if (this.mockAccelTimer !== -1) {
        clearInterval(this.mockAccelTimer)
        this.mockAccelTimer = -1
      }
      this.accelerometerStatus = SensorStatus.DISCONNECTED
    }
  }

  /**
   * Mock akselerometre verisi üreteci
   */
  private startMockAccelerometer(intervalMs: number): void {
    let phase = 0
    this.mockAccelTimer = setInterval(() => {
      phase += 0.1
      const noise = this.mockActivityLevel * 0.5

      // Aktiviteye göre farklı desen
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
      try { cb(x, y, z) } catch (e) { /* callback hatası */ }
    })
  }

  // ────────────────────────────────────────────────────────────────
  // YARDIMCI METODLAR
  // ────────────────────────────────────────────────────────────────

  /**
   * Akselerometre verisiyle aktivite tipini tahmin et
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
   * Sensör durumu bilgisini döndür
   */
  getSensorStatus(): Record<string, SensorStatus> {
    return {
      pedometer: this.pedometerStatus,
      heartRate: this.heartRateStatus,
      accelerometer: this.accelerometerStatus
    }
  }

  /**
   * Son kalp atışı değerini döndür
   */
  getLastHeartRate(): number {
    return this.lastHeartRate
  }

  /**
   * Son adım sayısını döndür
   */
  getLastStepCount(): number {
    return this.lastStepCount
  }

  /**
   * Son akselerometre verisini döndür
   */
  getLastAccelerometerData(): AccelerometerData {
    return this.lastAccelData
  }

  /**
   * Tüm sensörleri durdur (uygulama arka plana geçtiğinde)
   */
  stopAllSensors(): void {
    this.stepCallbacks = []
    this.heartRateCallbacks = []
    this.accelCallbacks = []

    try { sensor.off(sensor.SensorId.PEDOMETER) } catch (e) { /* sessizce */ }
    try { sensor.off(sensor.SensorId.HEART_RATE) } catch (e) { /* sessizce */ }
    try { sensor.off(sensor.SensorId.ACCELEROMETER) } catch (e) { /* sessizce */ }

    if (this.mockPedometerTimer !== -1) clearInterval(this.mockPedometerTimer)
    if (this.mockHeartRateTimer !== -1) clearInterval(this.mockHeartRateTimer)
    if (this.mockAccelTimer !== -1) clearInterval(this.mockAccelTimer)

    this.pedometerStatus = SensorStatus.DISCONNECTED
    this.heartRateStatus = SensorStatus.DISCONNECTED
    this.accelerometerStatus = SensorStatus.DISCONNECTED

    console.info('[HealthSensorService] Tüm sensörler durduruldu')
  }
}
