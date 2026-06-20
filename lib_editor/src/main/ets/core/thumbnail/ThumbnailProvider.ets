import { image } from '@kit.ImageKit';
import { media } from '@kit.MediaKit';
import { ImageSegment, VideoSegment } from 'lib_data';

export interface IThumbnailProvider {
  /**
   * 获取指定微秒时间戳的缩略图
   * @param timeUs 对于视频是具体时间，对于图片可忽略
   */
  getThumbnail(timeUs: number): Promise<image.PixelMap | string>;
  release(): void;
}

// 图片轨道，永远返回同一张图
export class ImageThumbnailProvider implements IThumbnailProvider {
  private readonly uri: string;
  constructor(segment: ImageSegment) { this.uri = segment.asset.uri; }
  async getThumbnail(timeUs: number): Promise<string> { return this.uri; }
  release(): void {} // 释放底层解码器是留给video的
}

// 视频轨道，需要封装 AVImageGenerator 抽帧逻辑
export class VideoThumbnailProvider implements IThumbnailProvider {
  private readonly uri: string
  private generator?: media.AVImageGenerator
  constructor(segment: VideoSegment) { this.uri = segment.asset.uri; }

  private async getGenerator(): Promise<media.AVImageGenerator> {
    if (!this.generator) {
      // TODO: 在实际鸿蒙开发中，需要根据 fd 构造 AVImageGenerator
      // 这里为演示核心链路，做保护处理
      this.generator = await media.createAVImageGenerator();
      this.generator.fdSrc = { fd: 0 }; // TODO: 替换为实际的 resourceManager/fileIO 打开的 FD
    }
    return this.generator;
  }

  async getThumbnail(timeUs: number): Promise<image.PixelMap | string> {
    try{
      const generator = await this.getGenerator()
      const pixelMap = await generator.fetchFrameByTime(
        timeUs,
        media.AVImageQueryOptions.AV_IMAGE_QUERY_CLOSEST_SYNC,
        {
          width: 256,
          height: 256
        })
      return pixelMap
    } catch (e) {
      console.error(`Fetch frame failed at ${timeUs}: ${e}`);
      return ""; // 失败返回空或默认占位图
    }
  }

  release(): void {
    if(this.generator) {
      this.generator.release()
    }
  }
}