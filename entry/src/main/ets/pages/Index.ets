import { ContactsPage } from './ContactsPage'
import { ChatListPage } from './ChatListPage'
import { ProfilePage } from './ProfilePage'
import { UpdatePage } from './UpdatePage'
import { SetupPage } from './SetupPage'
import { ApiManager } from '../common/api/ApiManager'
import { WebSocketManager, WebSocketStatus } from '../common/api/WebSocketManager'
import { UserProfile } from '../common/model/UserProfile'
import { ChatConversation } from '../common/model/ChatMessage'
import { NfcManager } from '../common/nfc/NfcManager'
import { PushManager } from '../common/push/PushManager'
import { UpdateManager } from '../common/update/UpdateManager'
import { LocalDataManager } from '../common/model/LocalDataManager'

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @State isReaderMode: boolean = true
  @State showUpdateDialog: boolean = false
  @State updateInfo: any = null
  @State messageText: string = ''
  @State contacts: UserProfile[] = []
  @State conversations: ChatConversation[] = []
  @State currentUser: UserProfile | null = null
  
  private apiManager: ApiManager = ApiManager.getInstance()
  private webSocketManager: WebSocketManager = WebSocketManager.getInstance()
  private nfcManager: NfcManager = NfcManager.getInstance()
  private pushManager: PushManager = PushManager.getInstance()
  private updateManager: UpdateManager = UpdateManager.getInstance()
  private localDataManager: LocalDataManager = LocalDataManager.getInstance()
  
  aboutToAppear() {
    this.initApp()
  }
  
  async initApp() {
    try {
      // 初始化API管理器
      await this.apiManager.initPreferences(getContext(this))
      
      // 检查是否是首次使用
      const isFirstTime = await this.apiManager.isFirstTime()
      if (isFirstTime) {
        // 跳转到设置页面
        router.pushUrl({ url: 'pages/SetupPage' })
        return
      }
      
      // 获取当前用户ID
      const userId = await this.apiManager.getUserId()
      if (userId === -1) {
        console.error('未找到用户ID')
        return
      }
      
      // 获取用户档案
      const profileResponse = await this.apiManager.getProfile(userId)
      if (profileResponse.success && profileResponse.data) {
        this.currentUser = profileResponse.data
      }
      
      // 初始化WebSocket连接
      await this.webSocketManager.connect('ws://45.32.222.180:3001')
      await this.webSocketManager.register(userId)
      
      // 初始化NFC管理器
      this.nfcManager.init()
      
      // 初始化推送管理器
      await this.pushManager.init()
      
      // 初始化更新管理器
      this.updateManager.init()
      
      // 加载数据
      await this.loadData()
      
      // 检查应用更新
      await this.checkAppUpdate()
      
      // 设置WebSocket监听器
      this.setupWebSocketListeners()
      
    } catch (error) {
      console.error('应用初始化失败:', error)
    }
  }
  
  async loadData() {
    try {
      const userId = await this.apiManager.getUserId()
      
      // 加载联系人
      const contactsResponse = await this.apiManager.getContacts(userId)
      if (contactsResponse.success && contactsResponse.data) {
        this.contacts = contactsResponse.data
      }
      
      // 加载会话列表
      const conversationsResponse = await this.apiManager.getConversations(userId)
      if (conversationsResponse.success && conversationsResponse.data) {
        this.conversations = conversationsResponse.data
      }
      
      // 获取离线消息
      const offlineResponse = await this.apiManager.getOfflineMessages(userId)
      if (offlineResponse.success && offlineResponse.data && offlineResponse.data.length > 0) {
        // 处理离线消息
        this.handleOfflineMessages(offlineResponse.data)
      }
      
    } catch (error) {
      console.error('加载数据失败:', error)
    }
  }
  
  async checkAppUpdate() {
    try {
      const currentVersion = '1.0.0' // 从应用配置获取
      const updateResponse = await this.apiManager.checkUpdate(currentVersion)
      
      if (updateResponse.success && updateResponse.data && updateResponse.data.hasUpdate) {
        this.updateInfo = updateResponse.data
        this.showUpdateDialog = true
      }
    } catch (error) {
      console.error('检查更新失败:', error)
    }
  }
  
  setupWebSocketListeners() {
    // 连接监听器
    this.webSocketManager.addConnectionListener({
      onConnected: () => {
        console.log('WebSocket连接成功')
        this.messageText = 'WebSocket已连接'
      },
      onDisconnected: () => {
        console.log('WebSocket连接断开')
        this.messageText = 'WebSocket连接断开'
      },
      onError: (error: string) => {
        console.error('WebSocket错误:', error)
        this.messageText = `WebSocket错误: ${error}`
      }
    })
    
    // 消息监听器
    this.webSocketManager.addMessageListener({
      onMessageReceived: (message) => {
        this.handleNewMessage(message)
      },
      onMessageSent: (success, messageId) => {
        if (success) {
          console.log('消息发送成功:', messageId)
        } else {
          console.error('消息发送失败')
        }
      },
      onMessageRead: (readerId) => {
        this.handleMessageRead(readerId)
      },
      onOnlineStatusReceived: (status) => {
        console.log('在线状态更新:', status)
      },
      onOfflineMessagesReceived: (messages) => {
        this.handleOfflineMessages(messages)
      }
    })
  }
  
  handleNewMessage(message: any) {
    // 更新会话列表
    this.updateConversationWithMessage(message)
    
    // 显示通知
    this.pushManager.showNotification({
      title: message.senderName || '新消息',
      content: message.message,
      userId: message.senderId
    })
  }
  
  handleMessageRead(readerId: number) {
    // 更新未读消息数
    this.updateUnreadCount(readerId, 0)
  }
  
  handleOfflineMessages(messages: any[]) {
    console.log(`收到 ${messages.length} 条离线消息`)
    
    // 更新会话列表
    messages.forEach(message => {
      this.updateConversationWithMessage(message)
    })
    
    // 显示通知
    this.pushManager.showNotification({
      title: '离线消息',
      content: `收到 ${messages.length} 条离线消息`,
      userId: 0
    })
  }
  
  updateConversationWithMessage(message: any) {
    // 查找或创建会话
    let conversation = this.conversations.find(c => c.otherUserId === message.senderId)
    
    if (!conversation) {
      conversation = new ChatConversation(message.senderId, message.senderName || '未知用户')
      this.conversations.unshift(conversation)
    } else {
      // 将会话移到顶部
      const index = this.conversations.indexOf(conversation)
      this.conversations.splice(index, 1)
      this.conversations.unshift(conversation)
    }
    
    // 更新会话信息
    conversation.lastMessage = message.message
    conversation.lastMessageTime = new Date(message.createdAt)
    
    // 如果不是自己发送的消息，增加未读数
    if (message.senderId !== this.currentUser?.id) {
      conversation.unreadCount++
    }
  }
  
  updateUnreadCount(userId: number, count: number) {
    const conversation = this.conversations.find(c => c.otherUserId === userId)
    if (conversation) {
      conversation.unreadCount = count
    }
  }
  
  toggleNfcMode() {
    this.isReaderMode = !this.isReaderMode
    this.nfcManager.setMode(this.isReaderMode)
    this.messageText = this.isReaderMode ? 'NFC读卡器模式' : 'NFC卡片模式'
  }
  
  build() {
    Column() {
      // 顶部状态栏
      Row() {
        Text(this.messageText)
          .fontSize(14)
          .fontColor('#666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Blank()
        
        Button(this.isReaderMode ? '读卡器' : '卡片')
          .fontSize(12)
          .backgroundColor(this.isReaderMode ? '#007AFF' : '#FF3B30')
          .onClick(() => this.toggleNfcMode())
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#F5F5F5')
      
      // 主内容区域
      Tabs({
        barPosition: BarPosition.End,
        index: this.currentIndex
      }) {
        // 联系人页面
        TabContent() {
          ContactsPage({
            contacts: this.contacts,
            onContactAdded: (contact: UserProfile) => {
              this.contacts.push(contact)
            }
          })
        }
        .tabBar('联系人')
        .icon($r('app.media.ic_contacts'))
        
        // 聊天列表页面
        TabContent() {
          ChatListPage({
            conversations: this.conversations,
            onConversationSelected: (conversation: ChatConversation) => {
              router.pushUrl({
                url: 'pages/ChatPage',
                params: {
                  otherUserId: conversation.otherUserId,
                  otherUserName: conversation.otherUserName
                }
              })
            }
          })
        }
        .tabBar('聊天')
        .icon($r('app.media.ic_chat'))
        
        // 档案页面
        TabContent() {
          ProfilePage({
            user: this.currentUser,
            onProfileUpdated: (profile: UserProfile) => {
              this.currentUser = profile
            }
          })
        }
        .tabBar('档案')
        .icon($r('app.media.ic_profile'))
      }
      .onChange((index: number) => {
        this.currentIndex = index
      })
    }
    .width('100%')
    .height('100%')
    
    // 更新对话框
    if (this.showUpdateDialog) {
      AlertDialog.show({
        title: '发现新版本',
        message: this.updateInfo?.description || '有新版本可用，是否立即更新？',
        primaryButton: {
          value: '立即更新',
          action: () => {
            this.updateManager.downloadAndInstall(this.updateInfo?.downloadUrl)
            this.showUpdateDialog = false
          }
        },
        secondaryButton: {
          value: '稍后再说',
          action: () => {
            this.showUpdateDialog = false
          }
        }
      })
    }
  }
  
  aboutToDisappear() {
    // 清理资源
    this.webSocketManager.removeConnectionListener({} as any)
    this.webSocketManager.removeMessageListener({} as any)
    this.nfcManager.destroy()
    this.pushManager.destroy()
    this.updateManager.destroy()
  }
} 