import webSocket from '@ohos.net.webSocket'
import { ApiConfig } from '../api/ApiConfig'
import { ChatMessage } from '../model/ChatMessage'
import { UserProfile } from '../model/UserProfile'

export interface WebSocketListener {
  onConnect(): void
  onDisconnect(): void
  onMessage(event: string, data: any): void
  onError(error: string): void
}

export class WebSocketManager {
  private static instance: WebSocketManager
  private ws: webSocket.WebSocket | null = null
  private url: string = ApiConfig.WS_URL
  private isConnected: boolean = false
  private reconnectAttempts: number = 0
  private maxReconnectAttempts: number = 5
  private reconnectDelay: number = 1000
  private listeners: WebSocketListener[] = []
  private messageQueue: Array<{ event: string, data: any }> = []
  
  private constructor() {}
  
  static getInstance(): WebSocketManager {
    if (!WebSocketManager.instance) {
      WebSocketManager.instance = new WebSocketManager()
    }
    return WebSocketManager.instance
  }
  
  async init(): Promise<void> {
    try {
      await this.connect()
    } catch (error) {
      console.error('WebSocket初始化失败:', error)
    }
  }
  
  async connect(): Promise<void> {
    if (this.isConnected) {
      console.info('WebSocket已连接')
      return
    }
    
    try {
      this.ws = webSocket.createWebSocket()
      
      // 设置连接监听
      this.ws.on('open', () => {
        console.info('WebSocket连接成功')
        this.isConnected = true
        this.reconnectAttempts = 0
        
        // 发送队列中的消息
        this.sendQueuedMessages()
        
        // 通知监听器
        this.listeners.forEach(listener => {
          listener.onConnect()
        })
      })
      
      // 设置消息监听
      this.ws.on('message', (data: string) => {
        try {
          const message = JSON.parse(data)
          console.info('收到WebSocket消息:', message)
          
          // 通知监听器
          this.listeners.forEach(listener => {
            listener.onMessage(message.event, message.data)
          })
        } catch (error) {
          console.error('解析WebSocket消息失败:', error)
        }
      })
      
      // 设置关闭监听
      this.ws.on('close', () => {
        console.info('WebSocket连接关闭')
        this.isConnected = false
        
        // 通知监听器
        this.listeners.forEach(listener => {
          listener.onDisconnect()
        })
        
        // 尝试重连
        this.scheduleReconnect()
      })
      
      // 设置错误监听
      this.ws.on('error', (error: string) => {
        console.error('WebSocket错误:', error)
        
        // 通知监听器
        this.listeners.forEach(listener => {
          listener.onError(error)
        })
      })
      
      // 连接到服务器
      await this.ws.connect(this.url)
      
    } catch (error) {
      console.error('WebSocket连接失败:', error)
      this.scheduleReconnect()
      throw error
    }
  }
  
  async disconnect(): Promise<void> {
    if (this.ws && this.isConnected) {
      try {
        await this.ws.close()
        this.isConnected = false
        console.info('WebSocket已断开连接')
      } catch (error) {
        console.error('WebSocket断开连接失败:', error)
      }
    }
  }
  
  async emit(event: string, data: any): Promise<void> {
    const message = {
      event: event,
      data: data
    }
    
    if (this.isConnected && this.ws) {
      try {
        await this.ws.send(JSON.stringify(message))
        console.info('发送WebSocket消息:', message)
      } catch (error) {
        console.error('发送WebSocket消息失败:', error)
        // 将消息加入队列，等待重连后发送
        this.messageQueue.push(message)
      }
    } else {
      // 连接未建立，将消息加入队列
      this.messageQueue.push(message)
      console.info('WebSocket未连接，消息已加入队列:', message)
    }
  }
  
  // 发送私聊消息
  async sendPrivateMessage(senderId: number, receiverId: number, message: string, messageType: string = 'text'): Promise<void> {
    await this.emit('send_private_message', {
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      messageType: messageType
    })
  }
  
  // 标记消息为已读
  async markAsRead(userId: number, senderId: number): Promise<void> {
    await this.emit('mark_as_read', {
      userId: userId,
      senderId: senderId
    })
  }
  
  // 获取在线状态
  async getOnlineStatus(userIds: number[]): Promise<void> {
    await this.emit('get_online_status', userIds)
  }
  
  // 添加监听器
  addListener(listener: WebSocketListener): void {
    this.listeners.push(listener)
  }
  
  // 移除监听器
  removeListener(listener: WebSocketListener): void {
    const index = this.listeners.indexOf(listener)
    if (index > -1) {
      this.listeners.splice(index, 1)
    }
  }
  
  // 获取连接状态
  getConnectionStatus(): boolean {
    return this.isConnected
  }
  
  // 发送队列中的消息
  private async sendQueuedMessages(): Promise<void> {
    if (this.messageQueue.length === 0) return
    
    console.info(`发送队列中的 ${this.messageQueue.length} 条消息`)
    
    for (const message of this.messageQueue) {
      try {
        await this.emit(message.event, message.data)
      } catch (error) {
        console.error('发送队列消息失败:', error)
      }
    }
    
    // 清空队列
    this.messageQueue = []
  }
  
  // 安排重连
  private scheduleReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('WebSocket重连次数已达上限')
      return
    }
    
    this.reconnectAttempts++
    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1)
    
    console.info(`WebSocket将在 ${delay}ms 后尝试重连 (第 ${this.reconnectAttempts} 次)`)
    
    setTimeout(() => {
      this.connect().catch(error => {
        console.error('WebSocket重连失败:', error)
      })
    }, delay)
  }
  
  // 重置重连计数
  resetReconnectAttempts(): void {
    this.reconnectAttempts = 0
  }
  
  // 设置重连配置
  setReconnectConfig(maxAttempts: number, delay: number): void {
    this.maxReconnectAttempts = maxAttempts
    this.reconnectDelay = delay
  }
  
  // 获取队列长度
  getQueueLength(): number {
    return this.messageQueue.length
  }
  
  // 清空消息队列
  clearMessageQueue(): void {
    this.messageQueue = []
  }
  
  // 检查网络状态
  async checkNetworkStatus(): Promise<boolean> {
    try {
      const net = await import('@ohos.net.connection')
      const netManager = net.createNetConnection()
      const netType = await netManager.getNetType()
      return netType !== net.NetType.NONE
    } catch (error) {
      console.error('检查网络状态失败:', error)
      return false
    }
  }
  
  // 处理特定消息类型
  handleMessage(event: string, data: any): void {
    switch (event) {
      case 'receive_private_message':
        this.handlePrivateMessage(data)
        break
      case 'message_read':
        this.handleMessageRead(data)
        break
      case 'online_status':
        this.handleOnlineStatus(data)
        break
      case 'offline_messages':
        this.handleOfflineMessages(data)
        break
      case 'contact_updated':
        this.handleContactUpdated(data)
        break
      case 'new_message':
        this.handleNewMessage(data)
        break
      default:
        console.info('未处理的消息类型:', event)
    }
  }
  
  private handlePrivateMessage(data: any): void {
    const message = ChatMessage.fromJson(data)
    console.info('收到私聊消息:', message)
    
    // 这里可以触发UI更新或其他业务逻辑
    // 例如：更新聊天界面、显示通知等
  }
  
  private handleMessageRead(data: any): void {
    console.info('消息已读:', data)
    
    // 这里可以更新消息状态
    // 例如：更新聊天界面中的已读状态
  }
  
  private handleOnlineStatus(data: any): void {
    console.info('在线状态更新:', data)
    
    // 这里可以更新联系人列表中的在线状态
  }
  
  private handleOfflineMessages(data: any): void {
    console.info('收到离线消息:', data)
    
    // 这里可以处理离线消息
    // 例如：显示通知、更新未读数等
  }
  
  private handleContactUpdated(data: any): void {
    console.info('联系人信息更新:', data)
    
    // 这里可以更新联系人列表
    // 例如：刷新联系人界面
  }
  
  private handleNewMessage(data: any): void {
    console.info('新消息通知:', data)
    
    // 这里可以处理新消息通知
    // 例如：显示推送通知、更新未读数等
  }
} 