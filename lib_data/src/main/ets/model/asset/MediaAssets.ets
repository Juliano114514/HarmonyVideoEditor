import { AbsAsset, IAssetParams } from './Asset';
import { MediaType } from '../common/Enums';

export interface VideoAssetParams extends IAssetParams {
  duration: number  // 单位：微秒(μs)
  width: number
  height: number
}

export interface AudioAssetParams extends IAssetParams {
  duration: number;
}

export interface ImageAssetParams extends IAssetParams {
  width: number;
  height: number;
}

export class VideoAsset extends AbsAsset {
  public readonly duration: number
  public readonly width: number
  public readonly height: number

  constructor(params: VideoAssetParams) {
    super(params, MediaType.VIDEO);
    this.duration = params.duration;
    this.width = params.width;
    this.height = params.height;
  }
}

export class AudioAsset extends AbsAsset {
  public readonly duration: number;

  constructor(params: AudioAssetParams) {
    super(params, MediaType.AUDIO);
    this.duration = params.duration;
  }
}

export class ImageAsset extends AbsAsset {
  public readonly width: number;
  public readonly height: number;

  constructor(params: ImageAssetParams) {
    super(params, MediaType.IMAGE);
    this.width = params.width;
    this.height = params.height;
  }
}