/**
 * RingProgress.ets - Dairesel İlerleme Çubuğu Bileşeni
 *
 * Wearable ekranına uygun, özelleştirilebilir yuvarlak progress göstergesi.
 * Canvas API ile çizilir, merkeze özel içerik yerleştirilebilir.
 *
 * Kullanım:
 * RingProgress({
 *   progress: 0.75,      // 0.0 - 1.0 arası
 *   size: 120,           // Piksel cinsinden boyut
 *   strokeWidth: 10,     // Çizgi kalınlığı
 *   activeColor: '#00C853',
 *   backgroundColor: '#1A3A1A',
 *   centerContent: () => { Text('75%') }  // İsteğe bağlı merkez içerik
 * })
 */

/**
 * RingProgress bileşeni
 * Canvas 2D API ile özel dairesel progress çizer.
 */
@Component
export struct RingProgress {
  // İlerleme değeri (0.0 - 1.0)
  @Prop progress: number = 0.0

  // Bileşen boyutu (px)
  @Prop size: number = 120

  // Halka çizgisi kalınlığı (px)
  @Prop strokeWidth: number = 10

  // Aktif kısım rengi
  @Prop activeColor: string = '#00C853'

  // Arka plan halka rengi
  @Prop backgroundColor: string = '#1A3A1A'

  // Merkeze yerleştirilecek özel içerik oluşturucu
  @BuilderParam centerContent: () => void = () => {}

  // Canvas rendering context
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  // Animasyon için görüntülenen progress değeri
  @State private displayProgress: number = 0.0

  // Animasyon zamanlayıcısı
  private animTimer: number = -1

  /**
   * Başlangıçta progress animasyonunu başlat
   */
  aboutToAppear() {
    // 0'dan hedef değere animasyonlu geçiş
    const target = Math.max(0, Math.min(1, this.progress))
    const duration = 600 // ms
    const steps = 30
    const increment = target / steps
    let current = 0

    this.animTimer = setInterval(() => {
      current += increment
      if (current >= target) {
        this.displayProgress = target
        clearInterval(this.animTimer)
      } else {
        this.displayProgress = current
      }
      this.drawRing()
    }, duration / steps)
  }

  aboutToDisappear() {
    if (this.animTimer !== -1) {
      clearInterval(this.animTimer)
    }
  }

  /**
   * Progress değeri değiştiğinde yeniden çiz
   */
  onProgressChange() {
    this.displayProgress = Math.max(0, Math.min(1, this.progress))
    this.drawRing()
  }

  /**
   * Canvas'a dairesel progress halkasını çizer.
   *
   * Algoritma:
   * 1. Arka plan halkası: tam daire (0 - 2π)
   * 2. Aktif halka: -π/2'den başlayarak progress * 2π kadar çiz
   * 3. Gradient veya düz renk uygula
   * 4. Yuvarlatılmış uçlar için lineCap = 'round'
   */
  private drawRing() {
    const ctx = this.context
    const size = this.size
    const cx = size / 2   // Merkez X
    const cy = size / 2   // Merkez Y
    const radius = (size - this.strokeWidth) / 2
    const startAngle = -Math.PI / 2  // 12 o'clock konumu

    // Canvas'ı temizle
    ctx.clearRect(0, 0, size, size)

    // ── Arka Plan Halkası ────────────────────────────────────────
    ctx.beginPath()
    ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
    ctx.strokeStyle = this.backgroundColor
    ctx.lineWidth = this.strokeWidth
    ctx.lineCap = 'round'
    ctx.stroke()

    // ── Aktif Progress Halkası ───────────────────────────────────
    if (this.displayProgress > 0) {
      const endAngle = startAngle + (2 * Math.PI * this.displayProgress)

      ctx.beginPath()
      ctx.arc(cx, cy, radius, startAngle, endAngle)
      ctx.strokeStyle = this.activeColor
      ctx.lineWidth = this.strokeWidth
      ctx.lineCap = 'round'
      ctx.stroke()

      // %100 tamamlandığında altın ışıltı efekti
      if (this.displayProgress >= 0.99) {
        ctx.beginPath()
        ctx.arc(cx, cy, radius, startAngle, 2 * Math.PI + startAngle)
        ctx.strokeStyle = '#FFD700'
        ctx.lineWidth = this.strokeWidth * 0.3
        ctx.globalAlpha = 0.5
        ctx.stroke()
        ctx.globalAlpha = 1.0
      }
    }

    // ── Başlangıç Noktası Glow Efekti ────────────────────────────
    if (this.displayProgress > 0.02) {
      const dotX = cx + radius * Math.cos(startAngle)
      const dotY = cy + radius * Math.sin(startAngle)

      ctx.beginPath()
      ctx.arc(dotX, dotY, this.strokeWidth / 2.5, 0, 2 * Math.PI)
      ctx.fillStyle = this.activeColor
      ctx.fill()
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // Canvas katmanı - halkaları çizer
      Canvas(this.context)
        .width(this.size)
        .height(this.size)
        .onReady(() => {
          this.drawRing()
        })

      // Merkez içerik katmanı
      Column() {
        this.centerContent()
      }
      .width(this.size - this.strokeWidth * 2 - 8)
      .height(this.size - this.strokeWidth * 2 - 8)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width(this.size)
    .height(this.size)
  }
}

/**
 * MiniRingProgress - Kompakt versiyon (kartlar içinde kullanım için)
 *
 * Daha küçük, merkez içeriksiz dairesel progress göstergesi.
 */
@Component
export struct MiniRingProgress {
  // İlerleme değeri (0.0 - 1.0)
  @Prop progress: number = 0.0

  // Boyut (px) - varsayılan: 40px
  @Prop size: number = 40

  // Çizgi kalınlığı
  @Prop strokeWidth: number = 5

  // Aktif renk
  @Prop activeColor: string = '#00C853'

  // Arka plan rengi
  @Prop backgroundColor: string = '#1A3A1A'

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  private drawMiniRing() {
    const ctx = this.context
    const size = this.size
    const cx = size / 2
    const cy = size / 2
    const radius = (size - this.strokeWidth) / 2

    ctx.clearRect(0, 0, size, size)

    // Arka plan
    ctx.beginPath()
    ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
    ctx.strokeStyle = this.backgroundColor
    ctx.lineWidth = this.strokeWidth
    ctx.stroke()

    // Aktif kısım
    if (this.progress > 0) {
      const startAngle = -Math.PI / 2
      const endAngle = startAngle + (2 * Math.PI * Math.min(1, this.progress))

      ctx.beginPath()
      ctx.arc(cx, cy, radius, startAngle, endAngle)
      ctx.strokeStyle = this.activeColor
      ctx.lineWidth = this.strokeWidth
      ctx.lineCap = 'round'
      ctx.stroke()
    }
  }

  build() {
    Canvas(this.context)
      .width(this.size)
      .height(this.size)
      .onReady(() => {
        this.drawMiniRing()
      })
  }
}
