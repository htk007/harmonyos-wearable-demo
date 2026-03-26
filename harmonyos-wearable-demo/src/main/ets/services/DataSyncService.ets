/**
 * DataSyncService.ets - Cihaz Senkronizasyon Servisi
 *
 * HarmonyOS Distributed Hardware API (@ohos.distributedHardware.deviceManager)
 * kullanarak wearable - telefon arası veri senkronizasyonu.
 *
 * Özellikler:
 * - Yakındaki cihazları keşfet (Discovery)
 * - Sağlık verilerini telefona aktar
 * - Telefon ayarlarını saate indir
 * - Çevrimdışı durumda lokal önbellek
 */

import deviceManager from '@ohos.distributedHardware.deviceManager'

// Senkronizasyon durumu
export enum SyncStatus {
  IDLE = 'idle',              // Bekliyor
  DISCOVERING = 'discovering', // Cihaz keşfediliyor
  CONNECTING = 'connecting',   // Bağlanıyor
  SYNCING = 'syncing',        // Senkronize ediliyor
  COMPLETED = 'completed',    // Tamamlandı
  FAILED = 'failed',          // Başarısız
  OFFLINE = 'offline'         // Çevrimdışı
}

// Senkronize edilecek sağlık verisi paketi
export interface HealthDataPacket {
  deviceId: string          // Wearable cihaz ID
  timestamp: number         // Veri zaman damgası
  version: string           // Veri paketi versiyonu
  data: {
    steps: DailyStepData[]
    heartRate: HeartRateEntry[]
    sleep: SleepEntry[]
    lastSync: number
  }
}

// Günlük adım verisi
export interface DailyStepData {
  date: string        // YYYY-MM-DD
  steps: number
  calories: number
  distanceKm: number
  activeMinutes: number
}

// Kalp atışı girişi
export interface HeartRateEntry {
  timestamp: number
  bpm: number
  status: string
}

// Uyku kaydı
export interface SleepEntry {
  date: string
  bedTime: string
  wakeTime: string
  score: number
  deepSleepMin: number
  lightSleepMin: number
  remSleepMin: number
}

// Bağlı cihaz bilgisi
export interface PairedDevice {
  deviceId: string
  deviceName: string
  deviceType: string
  networkId: string
  isOnline: boolean
  lastSeenAt: number
}

// Senkronizasyon sonucu
export interface SyncResult {
  success: boolean
  deviceId: string
  syncedAt: number
  recordsCount: number
  errorMessage?: string
}

/**
 * DataSyncService - Wearable <-> Telefon veri köprüsü
 */
export class DataSyncService {
  private static instance: DataSyncService | null = null

  // Device Manager instance
  private dmInstance: deviceManager.DeviceManager | null = null

  // Senkronizasyon durumu
  private syncStatus: SyncStatus = SyncStatus.IDLE

  // Eşleştirilmiş cihazlar listesi
  private pairedDevices: PairedDevice[] = []

  // Senkronizasyon geçmişi
  private syncHistory: SyncResult[] = []

  // Lokal veri önbelleği (telefon çevrimdışı olduğunda)
  private localCache: HealthDataPacket[] = []

  // Durum değişikliği dinleyicileri
  private statusListeners: ((status: SyncStatus) => void)[] = []

  // Senkronizasyon zamanlayıcısı (otomatik senkron için)
  private autoSyncTimer: number = -1

  // Uygulama bundle ID
  private readonly BUNDLE_NAME: string = 'com.harmonyhealth.wearable'

  // Veri paketi versiyonu
  private readonly DATA_VERSION: string = '1.0.0'

  private constructor() {
    this.initDeviceManager()
  }

  static getInstance(): DataSyncService {
    if (!DataSyncService.instance) {
      DataSyncService.instance = new DataSyncService()
    }
    return DataSyncService.instance
  }

  // ────────────────────────────────────────────────────────────────
  // BAŞLATMA VE KONFİGÜRASYON
  // ────────────────────────────────────────────────────────────────

  /**
   * Device Manager'ı başlat ve event listener'ları kaydet
   */
  private initDeviceManager(): void {
    try {
      deviceManager.createDeviceManager(this.BUNDLE_NAME,
        (err: Error, dm: deviceManager.DeviceManager) => {
          if (err) {
            console.error(`[DataSyncService] DeviceManager oluşturulamadı: ${err.message}`)
            this.syncStatus = SyncStatus.OFFLINE
            this.initMockMode()
            return
          }

          this.dmInstance = dm
          this.registerDeviceEvents()
          console.info('[DataSyncService] DeviceManager başlatıldı')

          // Mevcut güvenilir cihazları yükle
          this.loadTrustedDevices()
        }
      )
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error)
      console.warn(`[DataSyncService] DeviceManager başlatılamadı (${errMsg}), mock mod`)
      this.syncStatus = SyncStatus.OFFLINE
      this.initMockMode()
    }
  }

  /**
   * Cihaz event listener'larını kaydet
   * - deviceStateChange: Cihaz durumu değişimi
   * - discoverSuccess: Cihaz keşfedildi
   * - discoverFail: Keşif başarısız
   */
  private registerDeviceEvents(): void {
    if (!this.dmInstance) return

    try {
      // Cihaz durumu değişim olayı
      this.dmInstance.on('deviceStateChange',
        (data: deviceManager.DeviceStateChangeAction) => {
          console.info(`[DataSyncService] Cihaz durumu değişti: ${JSON.stringify(data)}`)

          if (data.action === deviceManager.DeviceStateChangeAction.READY) {
            // Cihaz hazır - senkronizasyon başlat
            this.onDeviceReady(data.device)
          } else if (data.action === deviceManager.DeviceStateChangeAction.OFFLINE) {
            // Cihaz çevrimdışı
            this.onDeviceOffline(data.device.deviceId)
          }
        }
      )

      // Cihaz keşif başarısı
      this.dmInstance.on('discoverSuccess',
        (data: deviceManager.DiscoverDeviceInfo) => {
          console.info(`[DataSyncService] Cihaz keşfedildi: ${data.device.deviceName}`)
          this.onDeviceDiscovered(data.device)
        }
      )

      // Keşif başarısızlığı
      this.dmInstance.on('discoverFail',
        (data: { subscribeId: number, reason: number }) => {
          console.warn(`[DataSyncService] Keşif başarısız: ${data.reason}`)
          this.setSyncStatus(SyncStatus.FAILED)
        }
      )

    } catch (error) {
      console.error(`[DataSyncService] Event listener kaydı hatası: ${JSON.stringify(error)}`)
    }
  }

  /**
   * Mock mod başlat - gerçek API yokken simülasyon
   */
  private initMockMode(): void {
    console.info('[DataSyncService] Mock senkronizasyon modu aktif')

    // Sahte eşleştirilmiş telefon ekle
    this.pairedDevices = [
      {
        deviceId: 'MOCK_PHONE_001',
        deviceName: 'Hasan\'ın Telefonu',
        deviceType: 'phone',
        networkId: 'mock-network-id',
        isOnline: Math.random() > 0.3,  // %70 ihtimalle online
        lastSeenAt: Date.now() - Math.floor(Math.random() * 3600000)
      }
    ]
  }

  // ────────────────────────────────────────────────────────────────
  // CİHAZ KEŞİF VE BAĞLANTI
  // ────────────────────────────────────────────────────────────────

  /**
   * Yakındaki HarmonyOS cihazlarını tara
   */
  startDiscovery(): void {
    if (!this.dmInstance) {
      console.warn('[DataSyncService] DeviceManager mevcut değil')
      return
    }

    this.setSyncStatus(SyncStatus.DISCOVERING)

    const subscribeInfo: deviceManager.SubscribeInfo = {
      subscribeId: Math.floor(Math.random() * 65536),
      mode: deviceManager.DiscoverMode.DISCOVER_MODE_ACTIVE,
      medium: deviceManager.ExchangeMedium.BLE,         // Bluetooth Low Energy
      freq: deviceManager.ExchangeFreq.LOW,             // Düşük frekans (batarya tasarrufu)
      isSameAccount: true,                              // Aynı HarmonyOS hesabı
      isWakeRemote: false,
      capability: deviceManager.SubscribeCap.SUBSCRIBE_CAPABILITY_DDMP
    }

    try {
      this.dmInstance.startDeviceDiscovery(subscribeInfo)
      console.info('[DataSyncService] Cihaz keşfi başlatıldı')
    } catch (error) {
      console.error(`[DataSyncService] Keşif başlatılamadı: ${JSON.stringify(error)}`)
      this.setSyncStatus(SyncStatus.FAILED)
    }
  }

  /**
   * Cihaz keşfini durdur
   */
  stopDiscovery(): void {
    if (!this.dmInstance) return
    try {
      this.dmInstance.stopDeviceDiscovery(0)
      if (this.syncStatus === SyncStatus.DISCOVERING) {
        this.setSyncStatus(SyncStatus.IDLE)
      }
    } catch (e) { /* sessizce geç */ }
  }

  /**
   * Güvenilir (eşleştirilmiş) cihazları yükle
   */
  private loadTrustedDevices(): void {
    if (!this.dmInstance) return

    try {
      const devices = this.dmInstance.getTrustedDeviceListSync()
      this.pairedDevices = devices.map((d: deviceManager.DeviceInfo) => ({
        deviceId: d.deviceId,
        deviceName: d.deviceName,
        deviceType: d.deviceTypeId === 0x0E ? 'phone' : 'tablet',
        networkId: d.networkId,
        isOnline: d.authForm > 0,
        lastSeenAt: Date.now()
      }))

      console.info(`[DataSyncService] ${this.pairedDevices.length} güvenilir cihaz yüklendi`)
    } catch (error) {
      console.warn(`[DataSyncService] Güvenilir cihazlar yüklenemedi: ${JSON.stringify(error)}`)
    }
  }

  // ────────────────────────────────────────────────────────────────
  // VERİ SENKRONİZASYONU
  // ────────────────────────────────────────────────────────────────

  /**
   * Sağlık verilerini telefona senkronize et
   *
   * @param data - Gönderilecek sağlık veri paketi
   * @returns Senkronizasyon sonucu
   */
  async syncHealthData(data: HealthDataPacket): Promise<SyncResult> {
    const onlineDevice = this.pairedDevices.find(d => d.isOnline)

    if (!onlineDevice) {
      // Çevrimdışı: Lokal önbelleğe kaydet
      this.cacheDataLocally(data)
      return {
        success: false,
        deviceId: 'none',
        syncedAt: Date.now(),
        recordsCount: 0,
        errorMessage: 'Bağlı telefon bulunamadı, veri önbelleğe alındı'
      }
    }

    this.setSyncStatus(SyncStatus.SYNCING)

    try {
      // Gerçek API çağrısı - distributedData kullanarak
      const result = await this.sendDataToDevice(onlineDevice, data)
      this.setSyncStatus(SyncStatus.COMPLETED)

      const syncResult: SyncResult = {
        success: true,
        deviceId: onlineDevice.deviceId,
        syncedAt: Date.now(),
        recordsCount: data.data.steps.length + data.data.heartRate.length
      }

      this.syncHistory.push(syncResult)
      // Son 30 senkronizasyonu tut
      if (this.syncHistory.length > 30) {
        this.syncHistory = this.syncHistory.slice(-30)
      }

      // Başarılı senkronda önbelleği temizle
      this.localCache = []

      console.info(`[DataSyncService] Senkronizasyon tamamlandı: ${syncResult.recordsCount} kayıt`)
      return syncResult

    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error)
      this.setSyncStatus(SyncStatus.FAILED)
      this.cacheDataLocally(data)

      return {
        success: false,
        deviceId: onlineDevice.deviceId,
        syncedAt: Date.now(),
        recordsCount: 0,
        errorMessage: errMsg
      }
    }
  }

  /**
   * Verilen cihaza sağlık verisini gönder
   * Gerçekte @ohos.distributedKVStore veya RPC kullanılır.
   */
  private async sendDataToDevice(
    device: PairedDevice,
    data: HealthDataPacket
  ): Promise<boolean> {

    // Gerçek implementasyonda:
    // 1. distributedKVStore ile paylaşımlı KV store aç
    // 2. Veriyi serialize et ve store'a yaz
    // 3. Telefon bu değişikliği otomatik alır

    return new Promise((resolve, reject) => {
      // Mock: %90 başarı oranı simülasyonu
      setTimeout(() => {
        if (Math.random() > 0.1) {
          console.info(`[DataSyncService] Veri ${device.deviceName}'a gönderildi`)
          resolve(true)
        } else {
          reject(new Error('Ağ zaman aşımı'))
        }
      }, 500 + Math.random() * 1000)
    })
  }

  /**
   * Çevrimdışıyken verileri lokal önbellekte sakla
   */
  private cacheDataLocally(data: HealthDataPacket): void {
    this.localCache.push(data)
    // Maksimum 7 günlük veri önbelleği (batarya tasarrufu)
    if (this.localCache.length > 7) {
      this.localCache = this.localCache.slice(-7)
    }
    console.info(`[DataSyncService] Veri önbelleğe alındı. Bekleyen: ${this.localCache.length}`)
  }

  /**
   * Cihaz çevrimiçi olduğunda bekleyen önbelleği gönder
   */
  async flushPendingCache(): Promise<void> {
    if (this.localCache.length === 0) return

    console.info(`[DataSyncService] ${this.localCache.length} önbellek paketi gönderiliyor`)

    for (const packet of [...this.localCache]) {
      const result = await this.syncHealthData(packet)
      if (result.success) {
        this.localCache = this.localCache.filter(p => p.timestamp !== packet.timestamp)
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // OTOMATİK SENKRONİZASYON
  // ────────────────────────────────────────────────────────────────

  /**
   * Otomatik senkronizasyon zamanlayıcısı başlat
   * Varsayılan: Her 30 dakikada bir
   *
   * @param intervalMs - Senkronizasyon aralığı (ms)
   * @param dataProvider - Her senkronda çağrılacak veri sağlayıcı
   */
  startAutoSync(intervalMs: number = 1800000,
                dataProvider: () => HealthDataPacket): void {

    if (this.autoSyncTimer !== -1) {
      clearInterval(this.autoSyncTimer)
    }

    this.autoSyncTimer = setInterval(async () => {
      const data = dataProvider()
      const result = await this.syncHealthData(data)
      console.info(`[DataSyncService] Otomatik senkron: ${result.success ? 'başarılı' : 'başarısız'}`)
    }, intervalMs)

    console.info(`[DataSyncService] Otomatik senkron başlatıldı (${intervalMs / 60000} dk)`)
  }

  /**
   * Otomatik senkronizasyonu durdur
   */
  stopAutoSync(): void {
    if (this.autoSyncTimer !== -1) {
      clearInterval(this.autoSyncTimer)
      this.autoSyncTimer = -1
    }
  }

  // ────────────────────────────────────────────────────────────────
  // EVENT HANDLERS
  // ────────────────────────────────────────────────────────────────

  private onDeviceReady(device: deviceManager.DeviceInfo): void {
    const existing = this.pairedDevices.find(d => d.deviceId === device.deviceId)
    if (existing) {
      existing.isOnline = true
      existing.lastSeenAt = Date.now()
    } else {
      this.pairedDevices.push({
        deviceId: device.deviceId,
        deviceName: device.deviceName,
        deviceType: 'phone',
        networkId: device.networkId,
        isOnline: true,
        lastSeenAt: Date.now()
      })
    }
    // Cihaz geldiğinde bekleyen önbelleği flush et
    this.flushPendingCache()
  }

  private onDeviceOffline(deviceId: string): void {
    const device = this.pairedDevices.find(d => d.deviceId === deviceId)
    if (device) {
      device.isOnline = false
    }
  }

  private onDeviceDiscovered(device: deviceManager.DeviceInfo): void {
    const exists = this.pairedDevices.some(d => d.deviceId === device.deviceId)
    if (!exists) {
      this.pairedDevices.push({
        deviceId: device.deviceId,
        deviceName: device.deviceName,
        deviceType: 'unknown',
        networkId: device.networkId,
        isOnline: false,
        lastSeenAt: Date.now()
      })
    }
  }

  // ────────────────────────────────────────────────────────────────
  // YARDIMCI METODLAR
  // ────────────────────────────────────────────────────────────────

  private setSyncStatus(status: SyncStatus): void {
    this.syncStatus = status
    this.statusListeners.forEach(cb => {
      try { cb(status) } catch (e) { /* listener hatası */ }
    })
  }

  /**
   * Senkronizasyon durumu dinleyicisi ekle
   */
  addStatusListener(listener: (status: SyncStatus) => void): void {
    this.statusListeners.push(listener)
  }

  /**
   * Senkronizasyon durumu dinleyicisini kaldır
   */
  removeStatusListener(listener: (status: SyncStatus) => void): void {
    this.statusListeners = this.statusListeners.filter(l => l !== listener)
  }

  /**
   * Mevcut senkronizasyon durumunu döndür
   */
  getStatus(): SyncStatus {
    return this.syncStatus
  }

  /**
   * Eşleştirilmiş cihaz listesini döndür
   */
  getPairedDevices(): PairedDevice[] {
    return [...this.pairedDevices]
  }

  /**
   * Senkronizasyon geçmişini döndür
   */
  getSyncHistory(): SyncResult[] {
    return [...this.syncHistory]
  }

  /**
   * Bekleyen önbellek sayısını döndür
   */
  getPendingCacheCount(): number {
    return this.localCache.length
  }

  /**
   * Boş bir sağlık veri paketi oluştur
   */
  createEmptyPacket(deviceId: string): HealthDataPacket {
    return {
      deviceId,
      timestamp: Date.now(),
      version: this.DATA_VERSION,
      data: {
        steps: [],
        heartRate: [],
        sleep: [],
        lastSync: Date.now()
      }
    }
  }

  /**
   * Servisi temizle (uygulama kapanırken)
   */
  destroy(): void {
    this.stopAutoSync()
    this.stopDiscovery()

    if (this.dmInstance) {
      try {
        this.dmInstance.off('deviceStateChange')
        this.dmInstance.off('discoverSuccess')
        this.dmInstance.off('discoverFail')
        this.dmInstance.release()
      } catch (e) { /* sessizce */ }
      this.dmInstance = null
    }

    console.info('[DataSyncService] Servis temizlendi')
  }
}
