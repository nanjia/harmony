import notification from '@ohos.notification'
import notificationManager from '@ohos.notificationManager'
import { ApiManager } from '../api/ApiManager'

/**
 * 通知数据接口
 */
export interface NotificationData {
  title: string
  content: string
  userId: number
  messageId?: number
  type?: string
}

/**
 * 推送管理器
 */
export class PushManager {
  private static instance: PushManager
  private apiManager: ApiManager = ApiManager.getInstance()
  private isInitialized: boolean = false
  private notificationId: number = 1000
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  static getInstance(): PushManager {
    if (!PushManager.instance) {
      PushManager.instance = new PushManager()
    }
    return PushManager.instance
  }
  
  /**
   * 初始化推送管理器
   */
  async init(): Promise<void> {
    if (this.isInitialized) return
    
    try {
      // 请求通知权限
      await this.requestNotificationPermission()
      
      // 注册设备推送token
      await this.registerDeviceToken()
      
      this.isInitialized = true
      console.log('推送管理器初始化成功')
      
    } catch (error) {
      console.error('推送管理器初始化失败:', error)
      throw error
    }
  }
  
  /**
   * 请求通知权限
   */
  private async requestNotificationPermission(): Promise<void> {
    try {
      const permission = 'ohos.permission.NOTIFICATION_CONTROLLER'
      const result = await notificationManager.requestEnableNotification()
      
      if (result) {
        console.log('通知权限已获取')
      } else {
        console.warn('通知权限被拒绝')
      }
    } catch (error) {
      console.error('请求通知权限失败:', error)
      throw error
    }
  }
  
  /**
   * 注册设备推送token
   */
  private async registerDeviceToken(): Promise<void> {
    try {
      // 获取设备唯一标识符作为推送token
      const deviceToken = await this.getDeviceToken()
      const userId = await this.apiManager.getUserId()
      
      if (userId !== -1 && deviceToken) {
        const response = await this.apiManager.registerDevice(userId, deviceToken)
        if (response.success) {
          console.log('设备推送token注册成功')
        } else {
          console.warn('设备推送token注册失败:', response.error)
        }
      }
    } catch (error) {
      console.error('注册设备推送token失败:', error)
    }
  }
  
  /**
   * 获取设备token
   */
  private async getDeviceToken(): Promise<string> {
    try {
      // 这里应该获取真实的设备推送token
      // 由于鸿蒙系统的推送API可能还在发展中，这里使用设备ID作为替代
      const deviceId = await this.getDeviceId()
      return `harmony_${deviceId}`
    } catch (error) {
      console.error('获取设备token失败:', error)
      return 'harmony_default_token'
    }
  }
  
  /**
   * 获取设备ID
   */
  private async getDeviceId(): Promise<string> {
    try {
      // 这里应该使用鸿蒙系统的设备信息API
      // 暂时返回一个固定值
      return 'device_001'
    } catch (error) {
      console.error('获取设备ID失败:', error)
      return 'unknown_device'
    }
  }
  
  /**
   * 显示通知
   */
  async showNotification(data: NotificationData): Promise<void> {
    try {
      const notificationRequest = this.createNotificationRequest(data)
      await notificationManager.publish(notificationRequest)
      
      console.log('通知发送成功:', data.title)
    } catch (error) {
      console.error('发送通知失败:', error)
    }
  }
  
  /**
   * 创建通知请求
   */
  private createNotificationRequest(data: NotificationData): notification.NotificationRequest {
    const notificationId = this.getNextNotificationId()
    
    const notificationContent: notification.NotificationContent = {
      contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: {
        title: data.title,
        text: data.content,
        additionalText: `用户ID: ${data.userId}`
      }
    }
    
    const notificationRequest: notification.NotificationRequest = {
      id: notificationId,
      content: notificationContent,
      wantAgent: this.createWantAgent(data),
      deliveryTime: Date.now(),
      tapDismissed: true,
      autoDeletedTime: Date.now() + 24 * 60 * 60 * 1000, // 24小时后自动删除
      color: 0x007AFF,
      colorEnabled: true,
      isAlertOnce: false,
      isStopwatch: false,
      isCountDown: false,
      isUnremovable: false,
      badgeIconType: notification.SlotType.SERVICE_INFORMATION,
      badgeNumber: 1,
      showDeliveryTime: true,
      actionButtons: this.createActionButtons(data),
      smallIcon: $r('app.media.ic_notification'),
      largeIcon: $r('app.media.ic_notification'),
      bigText: data.content,
      briefText: data.title,
      chronometerAt: 0,
      isOngoing: false,
      isUnremovable: false,
      isStopwatch: false,
      isCountDown: false,
      isFloatingIcon: false,
      isSilent: false,
      isShowTimestamp: true,
      slotType: notification.SlotType.SERVICE_INFORMATION,
      sortKey: 'chat_message',
      sourceType: notification.SourceType.SERVICE,
      template: {
        name: 'chat_message_template',
        data: {
          title: data.title,
          content: data.content,
          userId: data.userId.toString(),
          messageId: data.messageId?.toString() || ''
        }
      }
    }
    
    return notificationRequest
  }
  
  /**
   * 创建WantAgent
   */
  private createWantAgent(data: NotificationData): any {
    // 创建点击通知时的跳转意图
    return {
      pkgName: 'com.example.myapp',
      abilityName: 'EntryAbility',
      parameters: {
        action: 'open_chat',
        userId: data.userId,
        messageId: data.messageId
      }
    }
  }
  
  /**
   * 创建操作按钮
   */
  private createActionButtons(data: NotificationData): notification.NotificationActionButton[] {
    return [
      {
        title: '回复',
        wantAgent: {
          pkgName: 'com.example.myapp',
          abilityName: 'EntryAbility',
          parameters: {
            action: 'reply_message',
            userId: data.userId,
            messageId: data.messageId
          }
        }
      },
      {
        title: '标记已读',
        wantAgent: {
          pkgName: 'com.example.myapp',
          abilityName: 'EntryAbility',
          parameters: {
            action: 'mark_as_read',
            userId: data.userId,
            messageId: data.messageId
          }
        }
      }
    ]
  }
  
  /**
   * 获取下一个通知ID
   */
  private getNextNotificationId(): number {
    return this.notificationId++
  }
  
  /**
   * 取消通知
   */
  async cancelNotification(notificationId: number): Promise<void> {
    try {
      await notificationManager.cancel(notificationId)
      console.log('通知已取消:', notificationId)
    } catch (error) {
      console.error('取消通知失败:', error)
    }
  }
  
  /**
   * 取消所有通知
   */
  async cancelAllNotifications(): Promise<void> {
    try {
      await notificationManager.cancelAll()
      console.log('所有通知已取消')
    } catch (error) {
      console.error('取消所有通知失败:', error)
    }
  }
  
  /**
   * 获取通知列表
   */
  async getNotifications(): Promise<notification.Notification[]> {
    try {
      const notifications = await notificationManager.getActiveNotifications()
      return notifications
    } catch (error) {
      console.error('获取通知列表失败:', error)
      return []
    }
  }
  
  /**
   * 检查通知权限
   */
  async checkNotificationPermission(): Promise<boolean> {
    try {
      const result = await notificationManager.isNotificationEnabled()
      return result
    } catch (error) {
      console.error('检查通知权限失败:', error)
      return false
    }
  }
  
  /**
   * 显示离线消息通知
   */
  async showOfflineMessageNotification(count: number): Promise<void> {
    const data: NotificationData = {
      title: '离线消息',
      content: `您有 ${count} 条离线消息`,
      userId: 0,
      type: 'offline_message'
    }
    
    await this.showNotification(data)
  }
  
  /**
   * 显示新消息通知
   */
  async showNewMessageNotification(senderName: string, message: string, userId: number, messageId?: number): Promise<void> {
    const data: NotificationData = {
      title: senderName,
      content: message,
      userId: userId,
      messageId: messageId,
      type: 'new_message'
    }
    
    await this.showNotification(data)
  }
  
  /**
   * 显示档案更新通知
   */
  async showProfileUpdateNotification(contactName: string): Promise<void> {
    const data: NotificationData = {
      title: '档案更新',
      content: `${contactName} 更新了个人档案`,
      userId: 0,
      type: 'profile_update'
    }
    
    await this.showNotification(data)
  }
  
  /**
   * 显示应用更新通知
   */
  async showUpdateNotification(version: string, description: string): Promise<void> {
    const data: NotificationData = {
      title: `发现新版本 ${version}`,
      content: description,
      userId: 0,
      type: 'app_update'
    }
    
    await this.showNotification(data)
  }
  
  /**
   * 处理通知点击事件
   */
  handleNotificationClick(parameters: any): void {
    const action = parameters.action
    
    switch (action) {
      case 'open_chat':
        this.handleOpenChat(parameters)
        break
      case 'reply_message':
        this.handleReplyMessage(parameters)
        break
      case 'mark_as_read':
        this.handleMarkAsRead(parameters)
        break
      default:
        console.log('未知的通知操作:', action)
    }
  }
  
  /**
   * 处理打开聊天
   */
  private handleOpenChat(parameters: any): void {
    const userId = parseInt(parameters.userId)
    const messageId = parameters.messageId ? parseInt(parameters.messageId) : undefined
    
    // 跳转到聊天页面
    router.pushUrl({
      url: 'pages/ChatPage',
      params: {
        otherUserId: userId,
        otherUserName: '联系人'
      }
    })
  }
  
  /**
   * 处理回复消息
   */
  private handleReplyMessage(parameters: any): void {
    const userId = parseInt(parameters.userId)
    const messageId = parameters.messageId ? parseInt(parameters.messageId) : undefined
    
    // 跳转到聊天页面并自动聚焦输入框
    router.pushUrl({
      url: 'pages/ChatPage',
      params: {
        otherUserId: userId,
        otherUserName: '联系人',
        autoFocus: true
      }
    })
  }
  
  /**
   * 处理标记已读
   */
  private async handleMarkAsRead(parameters: any): void {
    const userId = parseInt(parameters.userId)
    const messageId = parameters.messageId ? parseInt(parameters.messageId) : undefined
    
    try {
      // 标记消息为已读
      const currentUserId = await this.apiManager.getUserId()
      if (currentUserId !== -1) {
        // 这里可以调用API标记消息为已读
        console.log('标记消息为已读:', messageId)
      }
    } catch (error) {
      console.error('标记已读失败:', error)
    }
  }
  
  /**
   * 销毁推送管理器
   */
  destroy(): void {
    this.isInitialized = false
  }
} 