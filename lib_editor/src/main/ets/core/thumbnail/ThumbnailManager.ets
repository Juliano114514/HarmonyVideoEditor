import { AbsSegment, ImageSegment, SegmentType, VideoSegment } from 'lib_data';
import { IThumbnailProvider, ImageThumbnailProvider, VideoThumbnailProvider } from './ThumbnailProvider';
import { image } from '@kit.ImageKit';

export class ThumbnailManager {
  private static instance: ThumbnailManager
  private providers: Map<string, IThumbnailProvider> = new Map()
  // TODO: 换成 LRUCache
  private frameCache: Map<string, image.PixelMap | string> = new Map();

  private constructor() {}

  public static getInstance(): ThumbnailManager {
    if (!ThumbnailManager.instance) {
      ThumbnailManager.instance = new ThumbnailManager();
    }
    return ThumbnailManager.instance;
  }

  private getProvider(segment: AbsSegment): IThumbnailProvider {
    let provider = this.providers.get(segment.id);
    if (!provider) {
      if (segment.type === SegmentType.VIDEO) {
        provider = new VideoThumbnailProvider(segment as VideoSegment);
      } else if (segment.type === SegmentType.IMAGE) {
        provider = new ImageThumbnailProvider(segment as ImageSegment);
      } else {
        throw new Error("Unsupported segment type for thumbnails");
      }
      this.providers.set(segment.id, provider);
    }
    return provider;
  }

  public async fetchFrame(segment: AbsSegment, timeUs: number): Promise<image.PixelMap | string> {
    // 粗略对齐时间戳，利用缓存（例如对齐到 0.5 秒）以提高缓存命中率
    const cacheKey = `${segment.id}_${Math.floor(timeUs / 100000) * 100000}`;
    const cached = this.frameCache.get(cacheKey);
    if (cached !== undefined) {
      return cached;
    }
    const provider = this.getProvider(segment);
    const frame = await provider.getThumbnail(timeUs);

    // 写入缓存，防止重复请求
    this.frameCache.set(cacheKey, frame);
    return frame;
  }

  public releaseSegment(segmentId: string) {
    const provider = this.providers.get(segmentId)
    if(provider) {
      provider.release()
      this.providers.delete(segmentId)
    }
    // TODO: 实际业务中还需清理 frameCache 中的对应帧
  }
}