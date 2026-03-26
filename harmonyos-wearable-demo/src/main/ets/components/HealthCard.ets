/**
 * HealthCard.ets - Tekrar Kullanılabilir Sağlık Metrik Kartı
 *
 * Başlık, değer, birim, ikon ve trend göstergesi içeren
 * wearable ekranına uygun kompakt sağlık kartı bileşeni.
 *
 * Kullanım:
 * HealthCard({
 *   title: 'Kalp Atışı',
 *   value: '72',
 *   unit: 'BPM',
 *   iconName: '💓',
 *   trend: 'up',
 *   accentColor: '#00C853',
 *   onClick: () => navigateTo(...)
 * })
 */

// Trend yönü tipi
type TrendDirection = 'up' | 'down' | 'stable'

/**
 * HealthCard bileşeni prop arayüzü
 */
@Component
export struct HealthCard {
  // Kart başlığı (örn: "Kalp Atışı")
  @Prop title: string = ''

  // Gösterilecek ana değer (örn: "72")
  @Prop value: string = '—'

  // Değer birimi (örn: "BPM", "adım", "kcal")
  @Prop unit: string = ''

  // Emoji veya metin ikon (örn: "💓", "👟")
  @Prop iconName: string = '📊'

  // Trend yönü: 'up' | 'down' | 'stable'
  @Prop trend: TrendDirection = 'stable'

  // Vurgu rengi (progress, ikonlar, border için)
  @Prop accentColor: string = '#00C853'

  // Alt açıklama metni (isteğe bağlı)
  @Prop subtitle: string = ''

  // Tıklama işleyicisi
  onClick: () => void = () => {}

  // Kart basılı durumu (animasyon için)
  @State private isPressed: boolean = false

  /**
   * Trend simgesini döndür
   */
  private getTrendIcon(): string {
    switch (this.trend) {
      case 'up': return '↑'
      case 'down': return '↓'
      default: return '→'
    }
  }

  /**
   * Trend rengini döndür
   */
  private getTrendColor(): string {
    switch (this.trend) {
      case 'up': return '#00C853'
      case 'down': return '#FF4444'
      default: return '#888888'
    }
  }

  build() {
    Row() {
      // ── Sol: İkon Bölgesi ─────────────────────────────────────
      Column() {
        Text(this.iconName)
          .fontSize(24)
      }
      .width(44)
      .height(44)
      .backgroundColor(`${this.accentColor}22`)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // ── Orta: Başlık ve Değer ─────────────────────────────────
      Column() {
        Text(this.title)
          .fontSize(10)
          .fontColor('#888888')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 4 }) {
          Text(this.value)
            .fontSize(20)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.unit)
            .fontSize(10)
            .fontColor('#888888')
            .alignSelf(ItemAlign.End)
            .margin({ bottom: 2 })
        }

        if (this.subtitle) {
          Text(this.subtitle)
            .fontSize(9)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .padding({ left: 10 })
      .alignItems(HorizontalAlign.Start)

      // ── Sağ: Trend Göstergesi ve Ok ──────────────────────────
      Column({ space: 2 }) {
        Text(this.getTrendIcon())
          .fontSize(14)
          .fontColor(this.getTrendColor())
          .fontWeight(FontWeight.Bold)

        Text('›')
          .fontSize(16)
          .fontColor('#444444')
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)

    }
    .width('100%')
    .padding({ left: 12, right: 10, top: 12, bottom: 12 })
    .backgroundColor(this.isPressed ? '#1A1A1A' : '#111111')
    .borderRadius(14)
    .border({
      width: { left: 3 },
      color: this.accentColor
    })
    .alignItems(VerticalAlign.Center)
    .scale({ x: this.isPressed ? 0.97 : 1.0, y: this.isPressed ? 0.97 : 1.0 })
    .animation({ duration: 100, curve: Curve.EaseOut })
    .onClick(() => {
      this.onClick()
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })
  }
}
