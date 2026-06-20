import { AbsSegment, AVSegment, SegmentType } from 'lib_data';
import { ThumbnailManager } from '../../core/thumbnail/ThumbnailManager';
import { image } from '@kit.ImageKit';

/**
 * 轨道内素材的缩略图带条
 * 当轨道进行捏合缩放时，父组件只需改变 segmentWidth，本组件会自动重新计算帧分布
 */

@Component
export struct ThumbnailStrip {
  @Prop @Watch('onMetricsChange') segment: AbsSegment
  @Prop @Watch('onMetricsChange') segmentWidth: number = 0
  @Prop @Watch('onMetricsChange') thumbnailHeight: number = 50

  @State frames: Array<image.PixelMap | string> = [];

  aboutToAppear(): void {
    this.calculateAndFetchFrames();
  }

  private onMetricsChange(): void {
    this.calculateAndFetchFrames();
  }

  private async calculateAndFetchFrames(): Promise<void> {
    if(this.segmentWidth <= 0 || this.thumbnailHeight <= 0) return

    // TODO: 按照实际素材接近的宽高比，选择 1:1 2:3 3:2 16:9 9:16 几个比例
    // 假设缩略图是正方形（宽高比1:1，可以根据实际素材调整比例）
    const thumbWidth = this.thumbnailHeight;


    // TODO: 需要做好缓存
    const count = Math.ceil(this.segmentWidth / thumbWidth);  // 需要生成的缩略图总数量 (向上取整铺满)
    if (count <= 0) return;

    const durationUs = this.segment.duration // 素材总时长
    const timeStepUs = durationUs / count; // 每一张缩略图代表的时间跨度
    const isAV = this.segment.type === SegmentType.VIDEO || this.segment.type === SegmentType.AUDIO;
    const sourceOffsetUs = isAV ? (this.segment as AVSegment).sourceRange.start : 0;
    const newFrames: Array<image.PixelMap | string> = [];
    const manager = ThumbnailManager.getInstance();

    for (let i = 0; i < count; i++) {
      // 提取点位于该缩略图代表时间段的中间
      const targetTimeUs = sourceOffsetUs + (i * timeStepUs) + (timeStepUs / 2);

      // 异步获取（内部走缓存或真实抽帧）
      const frame = await manager.fetchFrame(this.segment, targetTimeUs);
      newFrames.push(frame);
    }

    this.frames = newFrames;
  }

  build() {
    Row() {
      ForEach(this.frames, (frame: image.PixelMap | string, index: number) => {
        Image(frame)
          .width(this.thumbnailHeight)
          .height(this.thumbnailHeight)
          .objectFit(ImageFit.Cover) // 保证裁剪铺满不拉伸变形
      }, (item: image.PixelMap | string, index: number) => index.toString())
    }
    .width(this.segmentWidth)
    .height(this.thumbnailHeight)
    .clip(true) // 宽度超出父容器时裁剪
  }
}