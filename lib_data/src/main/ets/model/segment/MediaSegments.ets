import { AbsSegment, ISegmentParams } from './Segment';
import { AbsAsset } from '../asset/Asset'
import { AudioAsset, ImageAsset, VideoAsset } from '../asset/MediaAssets';
import { SegmentType } from '../common/Enums';
import { TimeRange } from '../common/TimeRange';

export interface MediaSegmentParams extends ISegmentParams {
  asset: AbsAsset;
}

export interface AVSegmentParams extends MediaSegmentParams {
  sourceRange: TimeRange; // 音视频特有的源裁剪范围
  speed?: number;
}

/** 挂载 Asset 的抽象子类 */
export abstract class MediaSegment extends AbsSegment {
  public readonly asset: AbsAsset;

  protected constructor(type: SegmentType, params: MediaSegmentParams) {
    super(type, params);
    this.asset = params.asset;
  }
}

/** 音视频片段（自带源时长概念） */
export abstract class AVSegment extends MediaSegment {
  public sourceRange: TimeRange;
  public speed: number;

  protected constructor(type: SegmentType, params: AVSegmentParams) {
    super(type, params);
    this.sourceRange = params.sourceRange;
    this.speed = params.speed ?? 1.0;
  }
}

/** 最终落地的实体类 */
export class VideoSegment extends AVSegment {
  declare asset: VideoAsset; // 协变约束类型
  constructor(params: AVSegmentParams) { super(SegmentType.VIDEO, params); }
}

export class AudioSegment extends AVSegment {
  declare asset: AudioAsset;
  constructor(params: AVSegmentParams) { super(SegmentType.AUDIO, params); }
}

export class ImageSegment extends MediaSegment {
  declare asset: ImageAsset;
  // 图片没有 sourceRange，完全靠 timelineRange 控制时长
  constructor(params: MediaSegmentParams) { super(SegmentType.IMAGE, params); }
}