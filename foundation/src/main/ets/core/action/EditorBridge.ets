import { IAction, IActionHandler } from './IAction'

export class EditorBridge {
  private static instance: EditorBridge

  // 维护 Action Type 到具体 Handler 的映射表
  private handlerTable: Map<string, IActionHandler<IAction>> = new Map();

  private constructor() {}

  public static getInstance(): EditorBridge {
    if(!EditorBridge.instance) {
      EditorBridge.instance = new EditorBridge()
    }
    return EditorBridge.instance
  }

  /**
   * 注册 Action 处理器
   * @param type Action 的唯一标识符
   * @param handler 处理该 Action 的具体实现
   */
  public registerHandler<T extends IAction>(type: string, handler: IActionHandler<T>): void {
    // 采用 事件-handler 一对一绑定的储存，实现一个随用随调
    this.handlerTable.set(type, handler as IActionHandler<IAction>);
  }

  /**
   * 卸载处理器 (避免内存泄漏)
   */
  public unregisterHandler(type: string): void {
    this.handlerTable.delete(type);
  }

  /**
   * 派发 Action
   * 支持异步流转，方便在 Handler 中处理如视频解码、特效加载等耗时操作
   */
  public async dispatch<T extends IAction>(action: T): Promise<void> {
    const handler = this.handlerTable.get(action.type)
    if(handler){
      await handler.handle(action)
    } else{
      console.warn(`EditorBridge: 未找到 [${action.type}] 对应的 Handler`);
    }
  }
}