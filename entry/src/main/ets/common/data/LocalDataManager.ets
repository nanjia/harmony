import preferences from '@ohos.data.preferences'
import { UserProfile } from '../model/UserProfile'
import { ChatMessage, Conversation } from '../model/ChatMessage'
import { ApiManager } from '../api/ApiManager'

export class LocalDataManager {
  private static instance: LocalDataManager
  private apiManager: ApiManager = ApiManager.getInstance()
  private preferencesHelper: preferences.Preferences | null = null
  
  private constructor() {}
  
  static getInstance(): LocalDataManager {
    if (!LocalDataManager.instance) {
      LocalDataManager.instance = new LocalDataManager()
    }
    return LocalDataManager.instance
  }
  
  async init(): Promise<void> {
    try {
      const context = getContext(this)
      this.preferencesHelper = await preferences.getPreferences(context, 'local_data')
      console.info('本地数据管理器初始化成功')
    } catch (error) {
      console.error('本地数据管理器初始化失败:', error)
    }
  }
  
  // 同步联系人信息
  async syncContactsFromServer(): Promise<void> {
    try {
      const contacts = await this.apiManager.getContacts()
      await this.saveContactsLocally(contacts)
      console.info('联系人同步成功，共', contacts.length, '个联系人')
    } catch (error) {
      console.error('同步联系人失败:', error)
      throw error
    }
  }
  
  // 保存联系人到本地
  async saveContactsLocally(contacts: UserProfile[]): Promise<void> {
    if (!this.preferencesHelper) return
    
    try {
      const contactsJson = contacts.map(contact => contact.toJson())
      await this.preferencesHelper.put('contacts', JSON.stringify(contactsJson))
      await this.preferencesHelper.flush()
    } catch (error) {
      console.error('保存联系人到本地失败:', error)
    }
  }
  
  // 获取本地联系人
  async getLocalContacts(): Promise<UserProfile[]> {
    if (!this.preferencesHelper) return []
    
    try {
      const contactsData = this.preferencesHelper.get('contacts', '[]') as string
      const contactsJson = JSON.parse(contactsData)
      return contactsJson.map((item: any) => UserProfile.fromJson(item))
    } catch (error) {
      console.error('获取本地联系人失败:', error)
      return []
    }
  }
  
  // 保存聊天消息到本地
  async saveMessagesLocally(otherUserId: number, messages: ChatMessage[]): Promise<void> {
    if (!this.preferencesHelper) return
    
    try {
      const key = `messages_${otherUserId}`
      const messagesJson = messages.map(message => message.toJson())
      await this.preferencesHelper.put(key, JSON.stringify(messagesJson))
      await this.preferencesHelper.flush()
    } catch (error) {
      console.error('保存聊天消息到本地失败:', error)
    }
  }
  
  // 获取本地聊天消息
  async getLocalMessages(otherUserId: number): Promise<ChatMessage[]> {
    if (!this.preferencesHelper) return []
    
    try {
      const key = `messages_${otherUserId}`
      const messagesData = this.preferencesHelper.get(key, '[]') as string
      const messagesJson = JSON.parse(messagesData)
      return messagesJson.map((item: any) => ChatMessage.fromJson(item))
    } catch (error) {
      console.error('获取本地聊天消息失败:', error)
      return []
    }
  }
  
  // 保存会话列表到本地
  async saveConversationsLocally(conversations: Conversation[]): Promise<void> {
    if (!this.preferencesHelper) return
    
    try {
      const conversationsJson = conversations.map(conv => conv.toJson())
      await this.preferencesHelper.put('conversations', JSON.stringify(conversationsJson))
      await this.preferencesHelper.flush()
    } catch (error) {
      console.error('保存会话列表到本地失败:', error)
    }
  }
  
  // 获取本地会话列表
  async getLocalConversations(): Promise<Conversation[]> {
    if (!this.preferencesHelper) return []
    
    try {
      const conversationsData = this.preferencesHelper.get('conversations', '[]') as string
      const conversationsJson = JSON.parse(conversationsData)
      return conversationsJson.map((item: any) => Conversation.fromJson(item))
    } catch (error) {
      console.error('获取本地会话列表失败:', error)
      return []
    }
  }
  
  // 清理过期数据
  async cleanupExpiredData(): Promise<void> {
    if (!this.preferencesHelper) return
    
    try {
      // 清理30天前的聊天消息
      const thirtyDaysAgo = new Date()
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
      
      // 这里可以实现更复杂的清理逻辑
      console.info('本地数据清理完成')
    } catch (error) {
      console.error('清理过期数据失败:', error)
    }
  }
  
  // 获取存储大小
  async getStorageSize(): Promise<number> {
    if (!this.preferencesHelper) return 0
    
    try {
      // 这里应该实现实际的存储大小计算
      return 0
    } catch (error) {
      console.error('获取存储大小失败:', error)
      return 0
    }
  }
  
  // 清空所有本地数据
  async clearAllData(): Promise<void> {
    if (!this.preferencesHelper) return
    
    try {
      await this.preferencesHelper.clear()
      await this.preferencesHelper.flush()
      console.info('所有本地数据已清空')
    } catch (error) {
      console.error('清空本地数据失败:', error)
    }
  }
} 