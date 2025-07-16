import { ChatMessage, ChatConversation, SendMessageRequest, MarkAsReadRequest } from './ChatMessage'
import { ApiManager } from '../api/ApiManager'
import { WebSocketManager } from '../api/WebSocketManager'
import { LocalDataManager } from './LocalDataManager'

/**
 * 聊天监听器接口
 */
export interface ChatListener {
  onMessageReceived(message: ChatMessage): void
  onMessageSent(success: boolean, messageId?: number): void
  onMessageRead(readerId: number): void
  onOnlineStatusReceived(status: Record<number, boolean>): void
  onConnected(): void
  onDisconnected(): void
  onError(error: string): void
}

/**
 * 聊天管理器
 */
export class ChatManager {
  private static instance: ChatManager
  private apiManager: ApiManager = ApiManager.getInstance()
  private webSocketManager: WebSocketManager = WebSocketManager.getInstance()
  private localDataManager: LocalDataManager = LocalDataManager.getInstance()
  private listeners: ChatListener[] = []
  private currentUserId: number = -1
  private messageCache: Map<number, ChatMessage[]> = new Map()
  private conversationCache: ChatConversation[] = []
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  static getInstance(): ChatManager {
    if (!ChatManager.instance) {
      ChatManager.instance = new ChatManager()
    }
    return ChatManager.instance
  }
  
  /**
   * 连接聊天服务
   */
  async connect(userId: number): Promise<void> {
    this.currentUserId = userId
    
    // 设置WebSocket监听器
    this.setupWebSocketListeners()
    
    // 加载本地缓存数据
    await this.loadLocalData()
    
    // 从服务器同步数据
    await this.syncFromServer()
  }
  
  /**
   * 断开连接
   */
  disconnect(): void {
    this.currentUserId = -1
    this.removeWebSocketListeners()
    this.listeners = []
  }
  
  /**
   * 添加监听器
   */
  addListener(listener: ChatListener): void {
    this.listeners.push(listener)
  }
  
  /**
   * 移除监听器
   */
  removeListener(listener: ChatListener): void {
    const index = this.listeners.indexOf(listener)
    if (index > -1) {
      this.listeners.splice(index, 1)
    }
  }
  
  /**
   * 发送消息
   */
  async sendMessage(receiverId: number, message: string): Promise<ChatMessage> {
    const request = new SendMessageRequest(this.currentUserId, receiverId, message)
    
    // 创建本地消息对象
    const localMessage = new ChatMessage(this.currentUserId, receiverId, message)
    localMessage.createdAt = new Date()
    localMessage.senderName = '我'
    
    // 添加到本地缓存
    this.addMessageToCache(receiverId, localMessage)
    
    // 保存到本地存储
    await this.localDataManager.saveMessage(localMessage)
    
    // 通过WebSocket发送
    await this.webSocketManager.sendPrivateMessage(request)
    
    return localMessage
  }
  
  /**
   * 标记消息为已读
   */
  async markAsRead(senderId: number): Promise<void> {
    const request = new MarkAsReadRequest(this.currentUserId, senderId)
    
    // 更新本地消息状态
    const messages = this.messageCache.get(senderId) || []
    messages.forEach(msg => {
      if (msg.senderId === senderId && !msg.isRead) {
        msg.isRead = true
      }
    })
    
    // 更新会话未读数
    this.updateConversationUnreadCount(senderId, 0)
    
    // 保存到本地存储
    await this.localDataManager.markMessagesAsRead(senderId)
    
    // 通过WebSocket发送已读状态
    await this.webSocketManager.markAsRead(request)
  }
  
  /**
   * 获取与指定用户的消息
   */
  async getMessages(otherUserId: number): Promise<ChatMessage[]> {
    // 先从缓存获取
    let messages = this.messageCache.get(otherUserId) || []
    
    // 如果缓存为空，从本地存储加载
    if (messages.length === 0) {
      messages = await this.localDataManager.getMessagesWithUser(otherUserId)
      this.messageCache.set(otherUserId, messages)
    }
    
    return messages
  }
  
  /**
   * 获取会话列表
   */
  async getConversations(): Promise<ChatConversation[]> {
    return this.conversationCache
  }
  
  /**
   * 从服务器加载会话列表
   */
  async loadConversationsFromServer(): Promise<void> {
    try {
      const response = await this.apiManager.getConversations(this.currentUserId)
      if (response.success && response.data) {
        this.conversationCache = response.data
        await this.localDataManager.saveConversations(response.data)
      }
    } catch (error) {
      console.error('加载会话列表失败:', error)
    }
  }
  
  /**
   * 获取离线消息
   */
  async fetchOfflineMessages(): Promise<void> {
    try {
      const response = await this.apiManager.getOfflineMessages(this.currentUserId)
      if (response.success && response.data && response.data.length > 0) {
        // 处理离线消息
        response.data.forEach(message => {
          this.addMessageToCache(message.senderId, message)
          this.updateConversationWithMessage(message)
        })
        
        // 保存到本地存储
        await this.localDataManager.saveMessages(response.data)
        
        // 标记为已读
        const messageIds = response.data.map(msg => msg.id)
        await this.apiManager.markOfflineMessagesAsRead(this.currentUserId, messageIds)
      }
    } catch (error) {
      console.error('获取离线消息失败:', error)
    }
  }
  
  /**
   * 设置WebSocket监听器
   */
  private setupWebSocketListeners(): void {
    this.webSocketManager.addMessageListener({
      onMessageReceived: (message) => {
        this.handleNewMessage(message)
      },
      onMessageSent: (success, messageId) => {
        this.notifyMessageSent(success, messageId)
      },
      onMessageRead: (readerId) => {
        this.handleMessageRead(readerId)
      },
      onOnlineStatusReceived: (status) => {
        this.notifyOnlineStatusReceived(status)
      },
      onOfflineMessagesReceived: (messages) => {
        this.handleOfflineMessages(messages)
      }
    })
    
    this.webSocketManager.addConnectionListener({
      onConnected: () => {
        this.notifyConnected()
      },
      onDisconnected: () => {
        this.notifyDisconnected()
      },
      onError: (error) => {
        this.notifyError(error)
      }
    })
  }
  
  /**
   * 移除WebSocket监听器
   */
  private removeWebSocketListeners(): void {
    this.webSocketManager.removeMessageListener({} as any)
    this.webSocketManager.removeConnectionListener({} as any)
  }
  
  /**
   * 处理新消息
   */
  private handleNewMessage(message: ChatMessage): void {
    // 添加到缓存
    this.addMessageToCache(message.senderId, message)
    
    // 更新会话
    this.updateConversationWithMessage(message)
    
    // 保存到本地存储
    this.localDataManager.saveMessage(message)
    
    // 通知监听器
    this.notifyMessageReceived(message)
  }
  
  /**
   * 处理离线消息
   */
  private handleOfflineMessages(messages: ChatMessage[]): void {
    messages.forEach(message => {
      this.handleNewMessage(message)
    })
  }
  
  /**
   * 处理消息已读
   */
  private handleMessageRead(readerId: number): void {
    // 更新消息状态
    const messages = this.messageCache.get(readerId) || []
    messages.forEach(msg => {
      if (msg.senderId === readerId) {
        msg.isRead = true
      }
    })
    
    // 通知监听器
    this.notifyMessageRead(readerId)
  }
  
  /**
   * 添加消息到缓存
   */
  private addMessageToCache(userId: number, message: ChatMessage): void {
    const messages = this.messageCache.get(userId) || []
    messages.push(message)
    this.messageCache.set(userId, messages)
  }
  
  /**
   * 更新会话信息
   */
  private updateConversationWithMessage(message: ChatMessage): void {
    const otherUserId = message.senderId === this.currentUserId ? message.receiverId : message.senderId
    let conversation = this.conversationCache.find(c => c.otherUserId === otherUserId)
    
    if (!conversation) {
      conversation = new ChatConversation(otherUserId, message.senderName || '未知用户')
      this.conversationCache.unshift(conversation)
    } else {
      // 将会话移到顶部
      const index = this.conversationCache.indexOf(conversation)
      this.conversationCache.splice(index, 1)
      this.conversationCache.unshift(conversation)
    }
    
    // 更新会话信息
    conversation.lastMessage = message.message
    conversation.lastMessageTime = message.createdAt
    
    // 如果不是自己发送的消息，增加未读数
    if (message.senderId !== this.currentUserId) {
      conversation.unreadCount++
    }
  }
  
  /**
   * 更新会话未读数
   */
  private updateConversationUnreadCount(userId: number, count: number): void {
    const conversation = this.conversationCache.find(c => c.otherUserId === userId)
    if (conversation) {
      conversation.unreadCount = count
    }
  }
  
  /**
   * 加载本地数据
   */
  private async loadLocalData(): Promise<void> {
    try {
      // 加载会话列表
      this.conversationCache = await this.localDataManager.getConversations()
      
      // 加载消息缓存
      const conversations = await this.localDataManager.getConversations()
      for (const conv of conversations) {
        const messages = await this.localDataManager.getMessagesWithUser(conv.otherUserId)
        this.messageCache.set(conv.otherUserId, messages)
      }
    } catch (error) {
      console.error('加载本地数据失败:', error)
    }
  }
  
  /**
   * 从服务器同步数据
   */
  private async syncFromServer(): Promise<void> {
    try {
      await this.loadConversationsFromServer()
      await this.fetchOfflineMessages()
    } catch (error) {
      console.error('从服务器同步数据失败:', error)
    }
  }
  
  /**
   * 通知监听器 - 消息接收
   */
  private notifyMessageReceived(message: ChatMessage): void {
    this.listeners.forEach(listener => {
      listener.onMessageReceived(message)
    })
  }
  
  /**
   * 通知监听器 - 消息发送
   */
  private notifyMessageSent(success: boolean, messageId?: number): void {
    this.listeners.forEach(listener => {
      listener.onMessageSent(success, messageId)
    })
  }
  
  /**
   * 通知监听器 - 消息已读
   */
  private notifyMessageRead(readerId: number): void {
    this.listeners.forEach(listener => {
      listener.onMessageRead(readerId)
    })
  }
  
  /**
   * 通知监听器 - 在线状态
   */
  private notifyOnlineStatusReceived(status: Record<number, boolean>): void {
    this.listeners.forEach(listener => {
      listener.onOnlineStatusReceived(status)
    })
  }
  
  /**
   * 通知监听器 - 连接成功
   */
  private notifyConnected(): void {
    this.listeners.forEach(listener => {
      listener.onConnected()
    })
  }
  
  /**
   * 通知监听器 - 连接断开
   */
  private notifyDisconnected(): void {
    this.listeners.forEach(listener => {
      listener.onDisconnected()
    })
  }
  
  /**
   * 通知监听器 - 错误
   */
  private notifyError(error: string): void {
    this.listeners.forEach(listener => {
      listener.onError(error)
    })
  }
} 