import http from '@ohos.net.http'
import preferences from '@ohos.data.preferences'
import { UserProfile } from '../model/UserProfile'
import { ChatMessage, ChatConversation, ChatUser, SendMessageRequest, MarkAsReadRequest } from '../model/ChatMessage'

/**
 * API配置
 */
class ApiConfig {
  static readonly BASE_URL = 'http://45.32.222.180:3001/'
  static readonly WS_BASE_URL = 'http://45.32.222.180:3001'
  
  // API端点
  static readonly ENDPOINTS = {
    PROFILE: 'api/profile',
    PROFILE_SYNC: 'api/profile/sync',
    PROFILE_CREATE: 'api/profile/create',
    CONTACTS: 'api/contacts',
    CHAT_MESSAGES: 'api/chat/messages',
    CONVERSATIONS: 'api/chat/conversations',
    OFFLINE_MESSAGES: 'api/push/offline-messages',
    DEVICE_REGISTER: 'api/push/register-device',
    UPDATE_CHECK: 'api/update/check'
  }
  
  // 响应状态码
  static readonly STATUS_CODES = {
    SUCCESS: 200,
    CREATED: 201,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    NOT_FOUND: 404,
    SERVER_ERROR: 500
  }
}

/**
 * API响应接口
 */
interface ApiResponse<T> {
  success: boolean
  data?: T
  message?: string
  error?: string
}

/**
 * API管理器
 */
export class ApiManager {
  private static instance: ApiManager
  private httpRequest: http.HttpRequest
  private preferencesHelper: preferences.Preferences | null = null
  
  private constructor() {
    this.httpRequest = http.createHttp()
  }
  
  /**
   * 获取单例实例
   */
  static getInstance(): ApiManager {
    if (!ApiManager.instance) {
      ApiManager.instance = new ApiManager()
    }
    return ApiManager.instance
  }
  
  /**
   * 初始化偏好设置
   */
  async initPreferences(context: Context): Promise<void> {
    try {
      this.preferencesHelper = await preferences.getPreferences(context, 'user_profile')
    } catch (error) {
      console.error('初始化偏好设置失败:', error)
    }
  }
  
  /**
   * 检查是否是首次使用
   */
  async isFirstTime(): Promise<boolean> {
    if (!this.preferencesHelper) return true
    
    try {
      const isFirstTime = await this.preferencesHelper.get('is_first_time', true)
      return isFirstTime as boolean
    } catch (error) {
      console.error('检查首次使用状态失败:', error)
      return true
    }
  }
  
  /**
   * 设置非首次使用
   */
  async setNotFirstTime(): Promise<void> {
    if (!this.preferencesHelper) return
    
    try {
      await this.preferencesHelper.put('is_first_time', false)
      await this.preferencesHelper.flush()
    } catch (error) {
      console.error('设置非首次使用失败:', error)
    }
  }
  
  /**
   * 获取用户ID
   */
  async getUserId(): Promise<number> {
    if (!this.preferencesHelper) return -1
    
    try {
      const userId = await this.preferencesHelper.get('user_id', -1)
      return userId as number
    } catch (error) {
      console.error('获取用户ID失败:', error)
      return -1
    }
  }
  
  /**
   * 保存用户ID
   */
  async saveUserId(userId: number): Promise<void> {
    if (!this.preferencesHelper) return
    
    try {
      await this.preferencesHelper.put('user_id', userId)
      await this.preferencesHelper.flush()
    } catch (error) {
      console.error('保存用户ID失败:', error)
    }
  }
  
  /**
   * 创建用户档案
   */
  async createProfile(profile: UserProfile): Promise<ApiResponse<UserProfile>> {
    try {
      const response = await this.httpRequest.request(
        ApiConfig.BASE_URL + ApiConfig.ENDPOINTS.PROFILE_CREATE,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify(profile)
        }
      )
      
      if (response.responseCode === ApiConfig.STATUS_CODES.CREATED) {
        const data = JSON.parse(response.result.toString())
        const createdProfile = UserProfile.fromJson(JSON.stringify(data.profile))
        if (createdProfile) {
          await this.saveUserId(createdProfile.id)
          await this.setNotFirstTime()
          return { success: true, data: createdProfile }
        }
      }
      
      return { success: false, error: '创建档案失败' }
    } catch (error) {
      console.error('创建档案失败:', error)
      return { success: false, error: error.message }
    }
  }
  
  /**
   * 同步用户档案
   */
  async syncProfile(profile: UserProfile): Promise<ApiResponse<UserProfile>> {
    try {
      const response = await this.httpRequest.request(
        ApiConfig.BASE_URL + ApiConfig.ENDPOINTS.PROFILE_SYNC,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify(profile)
        }
      )
      
      if (response.responseCode === ApiConfig.STATUS_CODES.SUCCESS) {
        const data = JSON.parse(response.result.toString())
        const syncedProfile = UserProfile.fromJson(JSON.stringify(data.profile))
        if (syncedProfile) {
          await this.saveUserId(syncedProfile.id)
          return { success: true, data: syncedProfile }
        }
      }
      
      return { success: false, error: '同步档案失败' }
    } catch (error) {
      console.error('同步档案失败:', error)
      return { success: false, error: error.message }
    }
  }
  
  /**
   * 获取用户档案
   */
  async getProfile(userId: number): Promise<ApiResponse<UserProfile>> {
    try {
      const response = await this.httpRequest.request(
        `${ApiConfig.BASE_URL}${ApiConfig.ENDPOINTS.PROFILE}/${userId}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json'
          }
        }
      )
      
      if (response.responseCode === ApiConfig.STATUS_CODES.SUCCESS) {
        const data = JSON.parse(response.result.toString())
        const profile = UserProfile.fromJson(JSON.stringify(data.profile))
        if (profile) {
          return { success: true, data: profile }
        }
      }
      
      return { success: false, error: '获取档案失败' }
    } catch (error) {
      console.error('获取档案失败:', error)
      return { success: false, error: error.message }
    }
  }
  
  /**
   * 获取联系人列表
   */
  async getContacts(userId: number): Promise<ApiResponse<UserProfile[]>> {
    try {
      const response = await this.httpRequest.request(
        `${ApiConfig.BASE_URL}${ApiConfig.ENDPOINTS.CONTACTS}/${userId}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json'
          }
        }
      )
      
      if (response.responseCode === ApiConfig.STATUS_CODES.SUCCESS) {
        const data = JSON.parse(response.result.toString())
        const contacts = data.contacts.map((contact: any) => 
          UserProfile.fromJson(JSON.stringify(contact))
        ).filter((contact: UserProfile | null) => contact !== null)
        return { success: true, data: contacts }
      }
      
      return { success: false, error: '获取联系人失败' }
    } catch (error) {
      console.error('获取联系人失败:', error)
      return { success: false, error: error.message }
    }
  }
  
  /**
   * 添加联系人
   */
  async addContact(userId: number, contactProfile: UserProfile): Promise<ApiResponse<boolean>> {
    try {
      const response = await this.httpRequest.request(
        `${ApiConfig.BASE_URL}${ApiConfig.ENDPOINTS.CONTACTS}/${userId}`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify({ contactProfile })
        }
      )
      
      if (response.responseCode === ApiConfig.STATUS_CODES.CREATED) {
        return { success: true, data: true }
      }
      
      return { success: false, error: '添加联系人失败' }
    } catch (error) {
      console.error('添加联系人失败:', error)
      return { success: false, error: error.message }
    }
  }
  
  /**
   * 获取会话列表
   */
  async getConversations(userId: number): Promise<ApiResponse<ChatConversation[]>> {
    try {
      const response = await this.httpRequest.request(
        `${ApiConfig.BASE_URL}${ApiConfig.ENDPOINTS.CONVERSATIONS}/${userId}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json'
          }
        }
      )
      
      if (response.responseCode === ApiConfig.STATUS_CODES.SUCCESS) {
        const data = JSON.parse(response.result.toString())
        const conversations = data.conversations.map((conv: any) => 
          ChatConversation.fromJson(conv)
        )
        return { success: true, data: conversations }
      }
      
      return { success: false, error: '获取会话列表失败' }
    } catch (error) {
      console.error('获取会话列表失败:', error)
      return { success: false, error: error.message }
    }
  }
  
  /**
   * 获取聊天消息
   */
  async getChatMessages(userId1: number, userId2: number): Promise<ApiResponse<ChatMessage[]>> {
    try {
      const response = await this.httpRequest.request(
        `${ApiConfig.BASE_URL}${ApiConfig.ENDPOINTS.CHAT_MESSAGES}?user1=${userId1}&user2=${userId2}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json'
          }
        }
      )
      
      if (response.responseCode === ApiConfig.STATUS_CODES.SUCCESS) {
        const data = JSON.parse(response.result.toString())
        const messages = data.messages.map((msg: any) => 
          ChatMessage.fromJson(msg)
        )
        return { success: true, data: messages }
      }
      
      return { success: false, error: '获取聊天消息失败' }
    } catch (error) {
      console.error('获取聊天消息失败:', error)
      return { success: false, error: error.message }
    }
  }
  
  /**
   * 获取离线消息
   */
  async getOfflineMessages(userId: number): Promise<ApiResponse<ChatMessage[]>> {
    try {
      const response = await this.httpRequest.request(
        `${ApiConfig.BASE_URL}${ApiConfig.ENDPOINTS.OFFLINE_MESSAGES}/${userId}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json'
          }
        }
      )
      
      if (response.responseCode === ApiConfig.STATUS_CODES.SUCCESS) {
        const data = JSON.parse(response.result.toString())
        const messages = data.messages.map((msg: any) => 
          ChatMessage.fromJson(msg)
        )
        return { success: true, data: messages }
      }
      
      return { success: false, error: '获取离线消息失败' }
    } catch (error) {
      console.error('获取离线消息失败:', error)
      return { success: false, error: error.message }
    }
  }
  
  /**
   * 标记离线消息为已读
   */
  async markOfflineMessagesAsRead(userId: number, messageIds: number[]): Promise<ApiResponse<boolean>> {
    try {
      const response = await this.httpRequest.request(
        `${ApiConfig.BASE_URL}${ApiConfig.ENDPOINTS.OFFLINE_MESSAGES}/${userId}/read`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify({ messageIds })
        }
      )
      
      if (response.responseCode === ApiConfig.STATUS_CODES.SUCCESS) {
        return { success: true, data: true }
      }
      
      return { success: false, error: '标记已读失败' }
    } catch (error) {
      console.error('标记已读失败:', error)
      return { success: false, error: error.message }
    }
  }
  
  /**
   * 注册设备推送
   */
  async registerDevice(userId: number, deviceToken: string): Promise<ApiResponse<boolean>> {
    try {
      const response = await this.httpRequest.request(
        ApiConfig.BASE_URL + ApiConfig.ENDPOINTS.DEVICE_REGISTER,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify({ userId, deviceToken })
        }
      )
      
      if (response.responseCode === ApiConfig.STATUS_CODES.CREATED) {
        return { success: true, data: true }
      }
      
      return { success: false, error: '注册设备失败' }
    } catch (error) {
      console.error('注册设备失败:', error)
      return { success: false, error: error.message }
    }
  }
  
  /**
   * 检查应用更新
   */
  async checkUpdate(currentVersion: string): Promise<ApiResponse<any>> {
    try {
      const response = await this.httpRequest.request(
        `${ApiConfig.BASE_URL}${ApiConfig.ENDPOINTS.UPDATE_CHECK}?version=${currentVersion}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json'
          }
        }
      )
      
      if (response.responseCode === ApiConfig.STATUS_CODES.SUCCESS) {
        const data = JSON.parse(response.result.toString())
        return { success: true, data: data.update }
      }
      
      return { success: false, error: '检查更新失败' }
    } catch (error) {
      console.error('检查更新失败:', error)
      return { success: false, error: error.message }
    }
  }
  
  /**
   * 销毁HTTP请求
   */
  destroy(): void {
    if (this.httpRequest) {
      this.httpRequest.destroy()
    }
  }
} 