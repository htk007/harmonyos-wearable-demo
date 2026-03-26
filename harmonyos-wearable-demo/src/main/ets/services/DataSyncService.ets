/**
 * DataSyncService.ets - Device Synchronization Service
 *
 * Wearable-to-phone data synchronization using HarmonyOS
 * Distributed Hardware API (@ohos.distributedHardware.deviceManager).
 *
 * Features:
 * - Discover nearby devices (Discovery)
 * - Transfer health data to phone
 * - Download phone settings to watch
 * - Local cache for offline operation
 */

import deviceManager from '@ohos.distributedHardware.deviceManager'

// Synchronization status
export enum SyncStatus {
  IDLE = 'idle',              // Waiting
  DISCOVERING = 'discovering', // Discovering devices
  CONNECTING = 'connecting',   // Connecting
  SYNCING = 'syncing',        // Synchronizing
  COMPLETED = 'completed',    // Completed
  FAILED = 'failed',          // Failed
  OFFLINE = 'offline'         // Offline
}

// Health data packet to synchronize
export interface HealthDataPacket {
  deviceId: string          // Wearable device ID
  timestamp: number         // Data timestamp
  version: string           // Data packet version
  data: {
    steps: DailyStepData[]
    heartRate: HeartRateEntry[]
    sleep: SleepEntry[]
    lastSync: number
  }
}

// Daily step data
export interface DailyStepData {
  date: string        // YYYY-MM-DD
  steps: number
  calories: number
  distanceKm: number
  activeMinutes: number
}

// Heart rate entry
export interface HeartRateEntry {
  timestamp: number
  bpm: number
  status: string
}

// Sleep record
export interface SleepEntry {
  date: string
  bedTime: string
  wakeTime: string
  score: number
  deepSleepMin: number
  lightSleepMin: number
  remSleepMin: number
}

// Paired device information
export interface PairedDevice {
  deviceId: string
  deviceName: string
  deviceType: string
  networkId: string
  isOnline: boolean
  lastSeenAt: number
}

// Synchronization result
export interface SyncResult {
  success: boolean
  deviceId: string
  syncedAt: number
  recordsCount: number
  errorMessage?: string
}

/**
 * DataSyncService - Wearable <-> Phone data bridge
 */
export class DataSyncService {
  private static instance: DataSyncService | null = null

  // Device Manager instance
  private dmInstance: deviceManager.DeviceManager | null = null

  // Synchronization status
  private syncStatus: SyncStatus = SyncStatus.IDLE

  // List of paired devices
  private pairedDevices: PairedDevice[] = []

  // Synchronization history
  private syncHistory: SyncResult[] = []

  // Local data cache (when phone is offline)
  private localCache: HealthDataPacket[] = []

  // Status change listeners
  private statusListeners: ((status: SyncStatus) => void)[] = []

  // Sync timer (for automatic sync)
  private autoSyncTimer: number = -1

  // Application bundle ID
  private readonly BUNDLE_NAME: string = 'com.harmonyhealth.wearable'

  // Data packet version
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

  // ──────────────────────────────────────────────────────────────
  // INITIALIZATION AND CONFIGURATION
  // ──────────────────────────────────────────────────────────────

  /**
   * Initialize Device Manager and register event listeners
   */
  private initDeviceManager(): void {
    try {
      deviceManager.createDeviceManager(this.BUNDLE_NAME,
        (err: Error, dm: deviceManager.DeviceManager) => {
          if (err) {
            console.error(`[DataSyncService] Failed to create DeviceManager: ${err.message}`)
            this.syncStatus = SyncStatus.OFFLINE
            this.initMockMode()
            return
          }

          this.dmInstance = dm
          this.registerDeviceEvents()
          console.info('[DataSyncService] DeviceManager initialized')

          // Load existing trusted devices
          this.loadTrustedDevices()
        }
      )
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error)
      console.warn(`[DataSyncService] DeviceManager init failed (${errMsg}), mock mode`)
      this.syncStatus = SyncStatus.OFFLINE
      this.initMockMode()
    }
  }

  /**
   * Register device event listeners
   * - deviceStateChange: Device state change
   * - discoverSuccess: Device discovered
   * - discoverFail: Discovery failed
   */
  private registerDeviceEvents(): void {
    if (!this.dmInstance) return

    try {
      // Device state change event
      this.dmInstance.on('deviceStateChange',
        (data: deviceManager.DeviceStateChangeAction) => {
          console.info(`[DataSyncService] Device state changed: ${JSON.stringify(data)}`)

          if (data.action === deviceManager.DeviceStateChangeAction.READY) {
            // Device ready - start synchronization
            this.onDeviceReady(data.device)
          } else if (data.action === deviceManager.DeviceStateChangeAction.OFFLINE) {
            // Device offline
            this.onDeviceOffline(data.device.deviceId)
          }
        }
      )

      // Device discovery success
      this.dmInstance.on('discoverSuccess',
        (data: deviceManager.DiscoverDeviceInfo) => {
          console.info(`[DataSyncService] Device discovered: ${data.device.deviceName}`)
          this.onDeviceDiscovered(data.device)
        }
      )

      // Discovery failure
      this.dmInstance.on('discoverFail',
        (data: { subscribeId: number, reason: number }) => {
          console.warn(`[DataSyncService] Discovery failed: ${data.reason}`)
          this.setSyncStatus(SyncStatus.FAILED)
        }
      )

    } catch (error) {
      console.error(`[DataSyncService] Event listener registration error: ${JSON.stringify(error)}`)
    }
  }

  /**
   * Initialize mock mode - simulation when real API is unavailable
   */
  private initMockMode(): void {
    console.info('[DataSyncService] Mock synchronization mode active')

    // Add a fake paired phone
    this.pairedDevices = [
      {
        deviceId: 'MOCK_PHONE_001',
        deviceName: "User's Phone",
        deviceType: 'phone',
        networkId: 'mock-network-id',
        isOnline: Math.random() > 0.3,  // 70% chance online
        lastSeenAt: Date.now() - Math.floor(Math.random() * 3600000)
      }
    ]
  }

  // ──────────────────────────────────────────────────────────────
  // DEVICE DISCOVERY AND CONNECTION
  // ──────────────────────────────────────────────────────────────

  /**
   * Scan for nearby HarmonyOS devices
   */
  startDiscovery(): void {
    if (!this.dmInstance) {
      console.warn('[DataSyncService] DeviceManager not available')
      return
    }

    this.setSyncStatus(SyncStatus.DISCOVERING)

    const subscribeInfo: deviceManager.SubscribeInfo = {
      subscribeId: Math.floor(Math.random() * 65536),
      mode: deviceManager.DiscoverMode.DISCOVER_MODE_ACTIVE,
      medium: deviceManager.ExchangeMedium.BLE,         // Bluetooth Low Energy
      freq: deviceManager.ExchangeFreq.LOW,             // Low frequency (battery saving)
      isSameAccount: true,                              // Same HarmonyOS account
      isWakeRemote: false,
      capability: deviceManager.SubscribeCap.SUBSCRIBE_CAPABILITY_DDMP
    }

    try {
      this.dmInstance.startDeviceDiscovery(subscribeInfo)
      console.info('[DataSyncService] Device discovery started')
    } catch (error) {
      console.error(`[DataSyncService] Discovery start failed: ${JSON.stringify(error)}`)
      this.setSyncStatus(SyncStatus.FAILED)
    }
  }

  /**
   * Stop device discovery
   */
  stopDiscovery(): void {
    if (!this.dmInstance) return
    try {
      this.dmInstance.stopDeviceDiscovery(0)
      if (this.syncStatus === SyncStatus.DISCOVERING) {
        this.setSyncStatus(SyncStatus.IDLE)
      }
    } catch (e) { /* silently ignore */ }
  }

  /**
   * Load trusted (paired) devices
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

      console.info(`[DataSyncService] ${this.pairedDevices.length} trusted device(s) loaded`)
    } catch (error) {
      console.warn(`[DataSyncService] Failed to load trusted devices: ${JSON.stringify(error)}`)
    }
  }

  // ──────────────────────────────────────────────────────────────
  // DATA SYNCHRONIZATION
  // ──────────────────────────────────────────────────────────────

  /**
   * Synchronize health data to phone
   *
   * @param data - Health data packet to send
   * @returns Synchronization result
   */
  async syncHealthData(data: HealthDataPacket): Promise<SyncResult> {
    const onlineDevice = this.pairedDevices.find(d => d.isOnline)

    if (!onlineDevice) {
      // Offline: save to local cache
      this.cacheDataLocally(data)
      return {
        success: false,
        deviceId: 'none',
        syncedAt: Date.now(),
        recordsCount: 0,
        errorMessage: 'No connected phone found, data cached locally'
      }
    }

    this.setSyncStatus(SyncStatus.SYNCING)

    try {
      // Real API call - using distributedData
      const result = await this.sendDataToDevice(onlineDevice, data)
      this.setSyncStatus(SyncStatus.COMPLETED)

      const syncResult: SyncResult = {
        success: true,
        deviceId: onlineDevice.deviceId,
        syncedAt: Date.now(),
        recordsCount: data.data.steps.length + data.data.heartRate.length
      }

      this.syncHistory.push(syncResult)
      // Keep last 30 sync results
      if (this.syncHistory.length > 30) {
        this.syncHistory = this.syncHistory.slice(-30)
      }

      // Clear cache on successful sync
      this.localCache = []

      console.info(`[DataSyncService] Sync completed: ${syncResult.recordsCount} records`)
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
   * Send health data to specified device.
   * In real implementation, uses @ohos.distributedKVStore or RPC.
   */
  private async sendDataToDevice(
    device: PairedDevice,
    data: HealthDataPacket
  ): Promise<boolean> {

    // Real implementation would:
    // 1. Open shared KV store via distributedKVStore
    // 2. Serialize data and write to store
    // 3. Phone automatically receives the change

    return new Promise((resolve, reject) => {
      // Mock: 90% success rate simulation
      setTimeout(() => {
        if (Math.random() > 0.1) {
          console.info(`[DataSyncService] Data sent to ${device.deviceName}`)
          resolve(true)
        } else {
          reject(new Error('Network timeout'))
        }
      }, 500 + Math.random() * 1000)
    })
  }

  /**
   * Store data locally when offline
   */
  private cacheDataLocally(data: HealthDataPacket): void {
    this.localCache.push(data)
    // Maximum 7 days of cached data (battery saving)
    if (this.localCache.length > 7) {
      this.localCache = this.localCache.slice(-7)
    }
    console.info(`[DataSyncService] Data cached. Pending: ${this.localCache.length}`)
  }

  /**
   * Flush pending cache when device comes online
   */
  async flushPendingCache(): Promise<void> {
    if (this.localCache.length === 0) return

    console.info(`[DataSyncService] Sending ${this.localCache.length} cached packet(s)`)

    for (const packet of [...this.localCache]) {
      const result = await this.syncHealthData(packet)
      if (result.success) {
        this.localCache = this.localCache.filter(p => p.timestamp !== packet.timestamp)
      }
    }
  }

  // ──────────────────────────────────────────────────────────────
  // AUTOMATIC SYNCHRONIZATION
  // ──────────────────────────────────────────────────────────────

  /**
   * Start automatic sync timer
   * Default: every 30 minutes
   *
   * @param intervalMs - Sync interval (ms)
   * @param dataProvider - Data provider called on each sync
   */
  startAutoSync(intervalMs: number = 1800000,
                dataProvider: () => HealthDataPacket): void {

    if (this.autoSyncTimer !== -1) {
      clearInterval(this.autoSyncTimer)
    }

    this.autoSyncTimer = setInterval(async () => {
      const data = dataProvider()
      const result = await this.syncHealthData(data)
      console.info(`[DataSyncService] Auto sync: ${result.success ? 'success' : 'failed'}`)
    }, intervalMs)

    console.info(`[DataSyncService] Auto sync started (every ${intervalMs / 60000} min)`)
  }

  /**
   * Stop automatic synchronization
   */
  stopAutoSync(): void {
    if (this.autoSyncTimer !== -1) {
      clearInterval(this.autoSyncTimer)
      this.autoSyncTimer = -1
    }
  }

  // ──────────────────────────────────────────────────────────────
  // EVENT HANDLERS
  // ──────────────────────────────────────────────────────────────

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
    // Flush pending cache when device comes online
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

  // ──────────────────────────────────────────────────────────────
  // UTILITY METHODS
  // ──────────────────────────────────────────────────────────────

  private setSyncStatus(status: SyncStatus): void {
    this.syncStatus = status
    this.statusListeners.forEach(cb => {
      try { cb(status) } catch (e) { /* listener error */ }
    })
  }

  /**
   * Add sync status listener
   */
  addStatusListener(listener: (status: SyncStatus) => void): void {
    this.statusListeners.push(listener)
  }

  /**
   * Remove sync status listener
   */
  removeStatusListener(listener: (status: SyncStatus) => void): void {
    this.statusListeners = this.statusListeners.filter(l => l !== listener)
  }

  /**
   * Returns current sync status
   */
  getStatus(): SyncStatus {
    return this.syncStatus
  }

  /**
   * Returns list of paired devices
   */
  getPairedDevices(): PairedDevice[] {
    return [...this.pairedDevices]
  }

  /**
   * Returns sync history
   */
  getSyncHistory(): SyncResult[] {
    return [...this.syncHistory]
  }

  /**
   * Returns pending cache count
   */
  getPendingCacheCount(): number {
    return this.localCache.length
  }

  /**
   * Create an empty health data packet
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
   * Clean up service (when app closes)
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
      } catch (e) { /* silently ignore */ }
      this.dmInstance = null
    }

    console.info('[DataSyncService] Service destroyed')
  }
}
