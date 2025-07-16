import webSocket from '@ohos.net.webSocket'
import { ChatMessage, SendMessageRequest, MarkAsReadRequest } from '../model/ChatMessage'

/**
 * WebSocket连接状态
 */
export enum WebSocketStatus {
  DISCONNECTED = 'disconnected',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  ERROR = 'error'
}

/**
 * WebSocket消息类型
 */
export enum WebSocketMessageType {
  REGISTER = 'register',
  SEND_PRIVATE_MESSAGE = 'send_private_message',
  MARK_AS_READ = 'mark_as_read',
  GET_ONLINE_STATUS = 'get_online_status'
}

/**
 * WebSocket事件类型
 */
export enum WebSocketEventType {
  RECEIVE_PRIVATE_MESSAGE = 'receive_private_message',
  MESSAGE_SENT = 'message_sent',
  MESSAGE_READ = 'message_read',
  ONLINE_STATUS = 'online_status',
  OFFLINE_MESSAGES = 'offline_messages'
}

/**
 * WebSocket连接监听器接口
 */
export interface WebSocketConnectionListener {
  onConnected(): void
  onDisconnected(): void
  onError(error: string): void
}

/**
 * WebSocket消息监听器接口
 */
export interface WebSocketMessageListener {
  onMessageReceived(message: ChatMessage): void
  onMessageSent(success: boolean, messageId?: number): void
  onMessageRead(readerId: number): void
  onOnlineStatusReceived(status: Record<number, boolean>): void
  onOfflineMessagesReceived(messages: ChatMessage[]): void
}

/**
 * WebSocket管理器
 */
export class WebSocketManager {
  private static instance: WebSocketManager
  private webSocket: webSocket.WebSocket | null = null
  private url: string = ''
  private status: WebSocketStatus = WebSocketStatus.DISCONNECTED
  private connectionListeners: WebSocketConnectionListener[] = []
  private messageListeners: WebSocketMessageListener[] = []
  private reconnectTimer: number | null = null
  private reconnectAttempts: number = 0
  private maxReconnectAttempts: number = 5
  private reconnectDelay: number = 3000
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  static getInstance(): WebSocketManager {
    if (!WebSocketManager.instance) {
      WebSocketManager.instance = new WebSocketManager()
    }
    return WebSocketManager.instance
  }
  
  /**
   * 连接WebSocket
   */
  async connect(url: string): Promise<void> {
    if (this.status === WebSocketStatus.CONNECTING || this.status === WebSocketStatus.CONNECTED) {
      console.log('WebSocket已连接或正在连接中')
      return
    }
    
    this.url = url
    this.status = WebSocketStatus.CONNECTING
    
    try {
      this.webSocket = webSocket.createWebSocket()
      
      // 设置连接监听器
      this.webSocket.on('open', () => {
        console.log('WebSocket连接成功')
        this.status = WebSocketStatus.CONNECTED
        this.reconnectAttempts = 0
        this.notifyConnectionListeners('connected')
      })
      
      this.webSocket.on('close', () => {
        console.log('WebSocket连接关闭')
        this.status = WebSocketStatus.DISCONNECTED
        this.notifyConnectionListeners('disconnected')
        this.scheduleReconnect()
      })
      
      this.webSocket.on('error', (error) => {
        console.error('WebSocket连接错误:', error)
        this.status = WebSocketStatus.ERROR
        this.notifyConnectionListeners('error', error.message)
        this.scheduleReconnect()
      })
      
      this.webSocket.on('message', (data) => {
        this.handleMessage(data)
      })
      
      // 开始连接
      await this.webSocket.connect(this.url)
      
    } catch (error) {
      console.error('WebSocket连接失败:', error)
      this.status = WebSocketStatus.ERROR
      this.notifyConnectionListeners('error', error.message)
      this.scheduleReconnect()
    }
  }
  
  /**
   * 断开WebSocket连接
   */
  disconnect(): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer)
      this.reconnectTimer = null
    }
    
    if (this.webSocket) {
      this.webSocket.close()
      this.webSocket = null
    }
    
    this.status = WebSocketStatus.DISCONNECTED
    this.notifyConnectionListeners('disconnected')
  }
  
  /**
   * 发送消息
   */
  async emit(event: string, data: any): Promise<void> {
    if (this.status !== WebSocketStatus.CONNECTED || !this.webSocket) {
      console.error('WebSocket未连接，无法发送消息')
      return
    }
    
    try {
      const message = {
        event: event,
        data: data
      }
      
      await this.webSocket.send(JSON.stringify(message))
      console.log('WebSocket消息发送成功:', event, data)
    } catch (error) {
      console.error('WebSocket消息发送失败:', error)
      throw error
    }
  }
  
  /**
   * 注册用户
   */
  async register(userId: number): Promise<void> {
    await this.emit(WebSocketMessageType.REGISTER, userId)
  }
  
  /**
   * 发送私聊消息
   */
  async sendPrivateMessage(request: SendMessageRequest): Promise<void> {
    await this.emit(WebSocketMessageType.SEND_PRIVATE_MESSAGE, request.toJson())
  }
  
  /**
   * 标记消息为已读
   */
  async markAsRead(request: MarkAsReadRequest): Promise<void> {
    await this.emit(WebSocketMessageType.MARK_AS_READ, request.toJson())
  }
  
  /**
   * 获取在线状态
   */
  async getOnlineStatus(userIds: number[]): Promise<void> {
    await this.emit(WebSocketMessageType.GET_ONLINE_STATUS, userIds)
  }
  
  /**
   * 添加连接监听器
   */
  addConnectionListener(listener: WebSocketConnectionListener): void {
    this.connectionListeners.push(listener)
  }
  
  /**
   * 移除连接监听器
   */
  removeConnectionListener(listener: WebSocketConnectionListener): void {
    const index = this.connectionListeners.indexOf(listener)
    if (index > -1) {
      this.connectionListeners.splice(index, 1)
    }
  }
  
  /**
   * 添加消息监听器
   */
  addMessageListener(listener: WebSocketMessageListener): void {
    this.messageListeners.push(listener)
  }
  
  /**
   * 移除消息监听器
   */
  removeMessageListener(listener: WebSocketMessageListener): void {
    const index = this.messageListeners.indexOf(listener)
    if (index > -1) {
      this.messageListeners.splice(index, 1)
    }
  }
  
  /**
   * 获取连接状态
   */
  getStatus(): WebSocketStatus {
    return this.status
  }
  
  /**
   * 是否已连接
   */
  isConnected(): boolean {
    return this.status === WebSocketStatus.CONNECTED
  }
  
  /**
   * 处理接收到的消息
   */
  private handleMessage(data: string): void {
    try {
      const message = JSON.parse(data)
      console.log('收到WebSocket消息:', message)
      
      switch (message.event) {
        case WebSocketEventType.RECEIVE_PRIVATE_MESSAGE:
          this.handlePrivateMessage(message.data)
          break
          
        case WebSocketEventType.MESSAGE_SENT:
          this.handleMessageSent(message.data)
          break
          
        case WebSocketEventType.MESSAGE_READ:
          this.handleMessageRead(message.data)
          break
          
        case WebSocketEventType.ONLINE_STATUS:
          this.handleOnlineStatus(message.data)
          break
          
        case WebSocketEventType.OFFLINE_MESSAGES:
          this.handleOfflineMessages(message.data)
          break
          
        default:
          console.log('未知的WebSocket消息类型:', message.event)
      }
    } catch (error) {
      console.error('解析WebSocket消息失败:', error)
    }
  }
  
  /**
   * 处理私聊消息
   */
  private handlePrivateMessage(data: any): void {
    const message = ChatMessage.fromJson(data)
    if (message) {
      this.messageListeners.forEach(listener => {
        listener.onMessageReceived(message)
      })
    }
  }
  
  /**
   * 处理消息发送结果
   */
  private handleMessageSent(data: any): void {
    this.messageListeners.forEach(listener => {
      listener.onMessageSent(data.success, data.messageId)
    })
  }
  
  /**
   * 处理消息已读
   */
  private handleMessageRead(data: any): void {
    this.messageListeners.forEach(listener => {
      listener.onMessageRead(data.readerId)
    })
  }
  
  /**
   * 处理在线状态
   */
  private handleOnlineStatus(data: Record<number, boolean>): void {
    this.messageListeners.forEach(listener => {
      listener.onOnlineStatusReceived(data)
    })
  }
  
  /**
   * 处理离线消息
   */
  private handleOfflineMessages(data: any): void {
    const messages = data.messages.map((msg: any) => ChatMessage.fromJson(msg))
      .filter((msg: ChatMessage | null) => msg !== null)
    
    this.messageListeners.forEach(listener => {
      listener.onOfflineMessagesReceived(messages)
    })
  }
  
  /**
   * 通知连接监听器
   */
  private notifyConnectionListeners(event: string, error?: string): void {
    this.connectionListeners.forEach(listener => {
      switch (event) {
        case 'connected':
          listener.onConnected()
          break
        case 'disconnected':
          listener.onDisconnected()
          break
        case 'error':
          listener.onError(error || '未知错误')
          break
      }
    })
  }
  
  /**
   * 安排重连
   */
  private scheduleReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.log('WebSocket重连次数已达上限，停止重连')
      return
    }
    
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer)
    }
    
    this.reconnectAttempts++
    const delay = this.reconnectDelay * this.reconnectAttempts
    
    console.log(`WebSocket将在 ${delay}ms 后尝试重连 (第 ${this.reconnectAttempts} 次)`)
    
    this.reconnectTimer = setTimeout(() => {
      this.connect(this.url)
    }, delay) as unknown as number
  }
  
  /**
   * 销毁WebSocket管理器
   */
  destroy(): void {
    this.disconnect()
    this.connectionListeners = []
    this.messageListeners = []
  }
} 