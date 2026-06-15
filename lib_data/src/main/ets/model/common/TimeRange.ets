// 单位：微秒(μs)
export class TimeRange {
  public start: number
  public end: number

  constructor(start: number, end: number) {
    if (end < start) {
      throw new Error(`TimeRange: end(${end}) cannot be less than start(${start})`);
    }
    this.start = start;
    this.end = end;
  }

  get duration(): number {
    return this.end - this.start;
  }
}