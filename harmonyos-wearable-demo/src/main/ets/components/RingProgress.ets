/**
 * RingProgress.ets - Circular Progress Bar Component
 *
 * A customizable circular progress indicator suitable for wearable screens.
 * Drawn using the Canvas API, with support for custom center content.
 *
 * Usage:
 * RingProgress({
 *   progress: 0.75,      // 0.0 - 1.0
 *   size: 120,           // Size in pixels
 *   strokeWidth: 10,     // Line thickness
 *   activeColor: '#00C853',
 *   backgroundColor: '#1A3A1A',
 *   centerContent: () => { Text('75%') }  // Optional center content
 * })
 */

/**
 * RingProgress component
 * Draws a custom circular progress ring using Canvas 2D API.
 */
@Component
export struct RingProgress {
  // Progress value (0.0 - 1.0)
  @Prop progress: number = 0.0

  // Component size (px)
  @Prop size: number = 120

  // Ring stroke thickness (px)
  @Prop strokeWidth: number = 10

  // Active segment color
  @Prop activeColor: string = '#00C853'

  // Background ring color
  @Prop backgroundColor: string = '#1A3A1A'

  // Custom content builder for the center area
  @BuilderParam centerContent: () => void = () => {}

  // Canvas rendering context
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  // Animated progress value
  @State private displayProgress: number = 0.0

  // Animation timer
  private animTimer: number = -1

  /**
   * Start progress animation on mount
   */
  aboutToAppear() {
    // Animate from 0 to target value
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
   * Redraw when progress value changes
   */
  onProgressChange() {
    this.displayProgress = Math.max(0, Math.min(1, this.progress))
    this.drawRing()
  }

  /**
   * Draws the circular progress ring on canvas.
   *
   * Algorithm:
   * 1. Background ring: full circle (0 - 2π)
   * 2. Active ring: draw from -π/2 by progress * 2π
   * 3. Apply color
   * 4. lineCap = 'round' for rounded ends
   */
  private drawRing() {
    const ctx = this.context
    const size = this.size
    const cx = size / 2   // Center X
    const cy = size / 2   // Center Y
    const radius = (size - this.strokeWidth) / 2
    const startAngle = -Math.PI / 2  // 12 o'clock position

    // Clear canvas
    ctx.clearRect(0, 0, size, size)

    // ── Background Ring ──────────────────────────────────────────
    ctx.beginPath()
    ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
    ctx.strokeStyle = this.backgroundColor
    ctx.lineWidth = this.strokeWidth
    ctx.lineCap = 'round'
    ctx.stroke()

    // ── Active Progress Ring ─────────────────────────────────────
    if (this.displayProgress > 0) {
      const endAngle = startAngle + (2 * Math.PI * this.displayProgress)

      ctx.beginPath()
      ctx.arc(cx, cy, radius, startAngle, endAngle)
      ctx.strokeStyle = this.activeColor
      ctx.lineWidth = this.strokeWidth
      ctx.lineCap = 'round'
      ctx.stroke()

      // Gold glow effect when 100% complete
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

    // ── Start Point Glow Effect ──────────────────────────────────
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
      // Canvas layer - draws the rings
      Canvas(this.context)
        .width(this.size)
        .height(this.size)
        .onReady(() => {
          this.drawRing()
        })

      // Center content layer
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
 * MiniRingProgress - Compact version (for use inside cards)
 *
 * Smaller circular progress indicator without center content.
 */
@Component
export struct MiniRingProgress {
  // Progress value (0.0 - 1.0)
  @Prop progress: number = 0.0

  // Size (px) - default: 40px
  @Prop size: number = 40

  // Stroke thickness
  @Prop strokeWidth: number = 5

  // Active color
  @Prop activeColor: string = '#00C853'

  // Background color
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

    // Background
    ctx.beginPath()
    ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
    ctx.strokeStyle = this.backgroundColor
    ctx.lineWidth = this.strokeWidth
    ctx.stroke()

    // Active segment
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
