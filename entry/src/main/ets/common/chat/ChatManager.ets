import { ChatMessage, Conversation } from '../model/ChatMessage'
import { ApiManager } from '../api/ApiManager'
import { WebSocketManager } from '../websocket/WebSocketManager'
import { ApiConfig } from '../api/ApiConfig'

export interface ChatListener {
  onNewMessage(message: ChatMessage): void
  onMessageRead(senderId: number): void
  onConversationUpdated(conversation: Conversation): void
  onError(error: string): void
}

export class ChatManager {
  private static instance: ChatManager
  private apiManager: ApiManager = ApiManager.getInstance()
  private webSocketManager: WebSocketManager = WebSocketManager.getInstance()
  private listeners: ChatListener[] = []
  private conversations: Conversation[] = []
  private messages: Map<number, ChatMessage[]> = new Map() // otherUserId -> messages
  private currentUserId: number = -1
  
  private constructor() {}
  
  static getInstance(): ChatManager {
    if (!ChatManager.instance) {
      ChatManager.instance = new ChatManager()
    }
    return ChatManager.instance
  }
  
  async connect(userId: number): Promise<void> {
    this.currentUserId = userId
    console.info('聊天管理器连接成功，用户ID:', userId)
  }
  
  async disconnect(): Promise<void> {
    this.currentUserId = -1
    this.conversations = []
    this.messages.clear()
    console.info('聊天管理器已断开连接')
  }
  
  // 加载会话列表
  async loadConversationsFromServer(): Promise<Conversation[]> {
    try {
      const conversations = await this.apiManager.getConversations()
      this.conversations = conversations
      console.info('会话列表加载成功，共', conversations.length, '个会话')
      return conversations
    } catch (error) {
      console.error('加载会话列表失败:', error)
      throw error
    }
  }
  
  // 获取会话列表
  getConversations(): Conversation[] {
    return this.conversations
  }
  
  // 获取指定会话的消息
  async getMessages(otherUserId: number): Promise<ChatMessage[]> {
    try {
      // 先从缓存获取
      if (this.messages.has(otherUserId)) {
        return this.messages.get(otherUserId)!
      }
      
      // 从服务器获取
      const messages = await this.apiManager.getMessages(otherUserId)
      this.messages.set(otherUserId, messages)
      console.info(`获取与用户 ${otherUserId} 的聊天消息，共 ${messages.length} 条`)
      return messages
    } catch (error) {
      console.error('获取聊天消息失败:', error)
      throw error
    }
  }
  
  // 发送消息
  async sendMessage(receiverId: number, message: string, messageType: string = 'text'): Promise<ChatMessage> {
    try {
      if (this.currentUserId === -1) {
        throw new Error('用户未连接')
      }
      
      // 通过WebSocket发送消息
      await this.webSocketManager.sendPrivateMessage(this.currentUserId, receiverId, message, messageType)
      
      // 创建本地消息对象
      const chatMessage = new ChatMessage({
        senderId: this.currentUserId,
        receiverId: receiverId,
        message: message,
        messageType: messageType,
        isRead: false,
        createdAt: new Date().toISOString()
      })
      
      // 添加到本地缓存
      this.addMessageToCache(receiverId, chatMessage)
      
      // 更新会话列表
      this.updateConversation(receiverId, message)
      
      console.info('消息发送成功:', chatMessage)
      return chatMessage
    } catch (error) {
      console.error('发送消息失败:', error)
      throw error
    }
  }
  
  // 标记消息为已读
  async markAsRead(senderId: number): Promise<void> {
    try {
      if (this.currentUserId === -1) {
        throw new Error('用户未连接')
      }
      
      // 通过WebSocket标记已读
      await this.webSocketManager.markAsRead(this.currentUserId, senderId)
      
      // 更新本地消息状态
      this.markMessagesAsRead(senderId)
      
      // 更新会话未读数
      this.updateConversationUnreadCount(senderId, 0)
      
      console.info('消息已标记为已读')
    } catch (error) {
      console.error('标记消息已读失败:', error)
      throw error
    }
  }
  
  // 获取离线消息
  async fetchOfflineMessages(): Promise<any[]> {
    try {
      const offlineMessages = await this.apiManager.getOfflineMessages()
      console.info('获取离线消息成功，共', offlineMessages.length, '条')
      
      // 处理离线消息
      for (const offlineMsg of offlineMessages) {
        if (offlineMsg.message_type === 'chat_message') {
          const messageData = offlineMsg.message_data
          const chatMessage = new ChatMessage({
            id: messageData.messageId,
            senderId: messageData.senderId,
            receiverId: this.currentUserId,
            message: messageData.message,
            messageType: messageData.messageType,
            isRead: false,
            createdAt: messageData.createdAt,
            senderName: messageData.senderName,
            senderAvatar: messageData.senderAvatar
          })
          
          this.addMessageToCache(messageData.senderId, chatMessage)
          this.updateConversation(messageData.senderId, messageData.message)
        }
      }
      
      // 标记离线消息为已读
      if (offlineMessages.length > 0) {
        await this.apiManager.markOfflineMessagesAsRead()
      }
      
      return offlineMessages
    } catch (error) {
      console.error('获取离线消息失败:', error)
      throw error
    }
  }
  
  // 删除会话
  async deleteConversation(otherUserId: number): Promise<void> {
    try {
      await this.apiManager.deleteConversation(otherUserId)
      
      // 从本地缓存中移除
      this.conversations = this.conversations.filter(conv => conv.otherUserId !== otherUserId)
      this.messages.delete(otherUserId)
      
      console.info('会话删除成功')
    } catch (error) {
      console.error('删除会话失败:', error)
      throw error
    }
  }
  
  // 添加监听器
  addListener(listener: ChatListener): void {
    this.listeners.push(listener)
  }
  
  // 移除监听器
  removeListener(listener: ChatListener): void {
    const index = this.listeners.indexOf(listener)
    if (index > -1) {
      this.listeners.splice(index, 1)
    }
  }
  
  // 处理新消息
  handleNewMessage(messageData: any): void {
    const message = ChatMessage.fromJson(messageData)
    
    // 添加到缓存
    this.addMessageToCache(message.senderId, message)
    
    // 更新会话
    this.updateConversation(message.senderId, message.message)
    
    // 通知监听器
    this.listeners.forEach(listener => {
      listener.onNewMessage(message)
    })
  }
  
  // 处理消息已读
  handleMessageRead(data: any): void {
    const senderId = data.readerId
    
    // 更新本地消息状态
    this.markMessagesAsRead(senderId)
    
    // 更新会话未读数
    this.updateConversationUnreadCount(senderId, 0)
    
    // 通知监听器
    this.listeners.forEach(listener => {
      listener.onMessageRead(senderId)
    })
  }
  
  // 添加消息到缓存
  private addMessageToCache(otherUserId: number, message: ChatMessage): void {
    if (!this.messages.has(otherUserId)) {
      this.messages.set(otherUserId, [])
    }
    
    const messages = this.messages.get(otherUserId)!
    messages.push(message)
    
    // 按时间排序
    messages.sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime())
  }
  
  // 标记消息为已读
  private markMessagesAsRead(senderId: number): void {
    if (this.messages.has(senderId)) {
      const messages = this.messages.get(senderId)!
      messages.forEach(message => {
        if (message.senderId === senderId && !message.isRead) {
          message.isRead = true
        }
      })
    }
  }
  
  // 更新会话
  private updateConversation(otherUserId: number, lastMessage: string): void {
    const existingIndex = this.conversations.findIndex(conv => conv.otherUserId === otherUserId)
    
    if (existingIndex >= 0) {
      // 更新现有会话
      const conversation = this.conversations[existingIndex]
      conversation.lastMessage = lastMessage
      conversation.lastMessageTime = new Date().toISOString()
      
      // 如果是接收到的消息，增加未读数
      if (this.messages.has(otherUserId)) {
        const messages = this.messages.get(otherUserId)!
        const unreadCount = messages.filter(msg => 
          msg.senderId === otherUserId && !msg.isRead
        ).length
        conversation.unreadCount = unreadCount
      }
      
      // 移到顶部
      this.conversations.splice(existingIndex, 1)
      this.conversations.unshift(conversation)
    } else {
      // 创建新会话
      const newConversation = new Conversation({
        otherUserId: otherUserId,
        otherUserName: '未知用户', // 可以从联系人列表获取
        otherUserAvatar: '',
        lastMessage: lastMessage,
        lastMessageTime: new Date().toISOString(),
        unreadCount: 1
      })
      
      this.conversations.unshift(newConversation)
    }
    
    // 通知监听器
    const conversation = this.conversations.find(conv => conv.otherUserId === otherUserId)
    if (conversation) {
      this.listeners.forEach(listener => {
        listener.onConversationUpdated(conversation)
      })
    }
  }
  
  // 更新会话未读数
  private updateConversationUnreadCount(otherUserId: number, count: number): void {
    const conversation = this.conversations.find(conv => conv.otherUserId === otherUserId)
    if (conversation) {
      conversation.unreadCount = count
      
      // 通知监听器
      this.listeners.forEach(listener => {
        listener.onConversationUpdated(conversation)
      })
    }
  }
  
  // 获取总未读数
  getTotalUnreadCount(): number {
    return this.conversations.reduce((total, conv) => total + conv.unreadCount, 0)
  }
  
  // 清空缓存
  clearCache(): void {
    this.messages.clear()
    console.info('聊天缓存已清空')
  }
  
  // 搜索消息
  searchMessages(keyword: string): ChatMessage[] {
    const results: ChatMessage[] = []
    
    for (const messages of this.messages.values()) {
      const matched = messages.filter(message => 
        message.message.toLowerCase().includes(keyword.toLowerCase())
      )
      results.push(...matched)
    }
    
    return results.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
  }
} 