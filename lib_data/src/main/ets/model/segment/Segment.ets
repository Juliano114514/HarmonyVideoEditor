import { SegmentType } from '../common/Enums';
import { TimeRange } from '../common/TimeRange';
import { util } from '@kit.ArkTS';

export interface ISegmentParams {
  timelineRange: TimeRange
}

export abstract class AbsSegment {
  public readonly id: string;
  public readonly type: SegmentType;
  public timelineRange: TimeRange;

  // 通用的 UI 层属性（用于画中画等高级操作）
  public scale: number = 1.0;
  public posX: number = 0;
  public posY: number = 0;

  protected constructor(type: SegmentType, params: ISegmentParams) {
    this.id = util.generateRandomUUID(true);
    this.type = type;
    this.timelineRange = params.timelineRange;
  }

  get duration(): number {
    return this.timelineRange.duration;
  }
}