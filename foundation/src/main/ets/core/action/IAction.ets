export interface IAction {
  readonly type: string; // 唯一标识符，用于路由分发
}

export interface IActionHandler<T extends IAction> {
  handle(action: T): void | Promise<void>;
}