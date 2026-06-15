import { MediaType } from '../common/Enums'
import { util } from '@kit.ArkTS'

export interface IAssetParams {
  uri: string
  name: string
  fileSize?: number
}

export abstract class AbsAsset {
  public readonly id: string;
  public readonly uri: string;
  public readonly name: string;
  public readonly fileSize: number;
  public readonly mediaType: MediaType;

  protected constructor(params: IAssetParams, mediaType: MediaType) {
    this.id = util.generateRandomUUID(true)
    this.uri = params.uri
    this.name = params.name
    this.fileSize = params.fileSize ?? 0
    this.mediaType = mediaType
  }
}