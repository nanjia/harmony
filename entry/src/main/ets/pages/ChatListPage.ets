import { ChatConversation } from '../common/model/ChatMessage'
import { ApiManager } from '../common/api/ApiManager'
import { WebSocketManager } from '../common/api/WebSocketManager'
import { LocalDataManager } from '../common/model/LocalDataManager'

@Component
export struct ChatListPage {
  @State conversations: ChatConversation[] = []
  @State isLoading: boolean = false
  @State refreshing: boolean = false
  
  @Prop onConversationSelected?: (conversation: ChatConversation) => void
  
  private apiManager: ApiManager = ApiManager.getInstance()
  private webSocketManager: WebSocketManager = WebSocketManager.getInstance()
  private localDataManager: LocalDataManager = LocalDataManager.getInstance()
  
  aboutToAppear() {
    this.loadConversations()
    this.setupWebSocketListener()
  }
  
  aboutToDisappear() {
    this.removeWebSocketListener()
  }
  
  async loadConversations() {
    this.isLoading = true
    try {
      const userId = await this.apiManager.getUserId()
      const response = await this.apiManager.getConversations(userId)
      
      if (response.success && response.data) {
        this.conversations = response.data
      }
    } catch (error) {
      console.error('加载会话列表失败:', error)
    } finally {
      this.isLoading = false
    }
  }
  
  async refreshConversations() {
    this.refreshing = true
    await this.loadConversations()
    this.refreshing = false
  }
  
  setupWebSocketListener() {
    this.webSocketManager.addMessageListener({
      onMessageReceived: (message) => {
        this.handleNewMessage(message)
      },
      onMessageSent: (success, messageId) => {
        // 消息发送成功，不需要特殊处理
      },
      onMessageRead: (readerId) => {
        this.handleMessageRead(readerId)
      },
      onOnlineStatusReceived: (status) => {
        // 在线状态更新，暂时不需要处理
      },
      onOfflineMessagesReceived: (messages) => {
        this.handleOfflineMessages(messages)
      }
    })
  }
  
  removeWebSocketListener() {
    this.webSocketManager.removeMessageListener({} as any)
  }
  
  handleNewMessage(message: any) {
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
    if (message.senderId !== this.getCurrentUserId()) {
      conversation.unreadCount++
    }
  }
  
  handleMessageRead(readerId: number) {
    // 更新未读消息数
    const conversation = this.conversations.find(c => c.otherUserId === readerId)
    if (conversation) {
      conversation.unreadCount = 0
    }
  }
  
  handleOfflineMessages(messages: any[]) {
    console.log(`收到 ${messages.length} 条离线消息`)
    
    // 更新会话列表
    messages.forEach(message => {
      this.handleNewMessage(message)
    })
  }
  
  getCurrentUserId(): number {
    // 从本地存储获取当前用户ID
    return this.localDataManager.getCurrentUserId() || -1
  }
  
  formatTime(date: Date): string {
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))
    
    if (diffDays === 0) {
      // 今天，显示时间
      return date.toLocaleTimeString('zh-CN', { 
        hour: '2-digit', 
        minute: '2-digit' 
      })
    } else if (diffDays === 1) {
      // 昨天
      return '昨天'
    } else if (diffDays < 7) {
      // 一周内，显示星期
      const weekdays = ['日', '一', '二', '三', '四', '五', '六']
      return '星期' + weekdays[date.getDay()]
    } else {
      // 超过一周，显示日期
      return date.toLocaleDateString('zh-CN', { 
        month: '2-digit', 
        day: '2-digit' 
      })
    }
  }
  
  build() {
    Column() {
      // 顶部工具栏
      Row() {
        Text('聊天')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        
        Blank()
        
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_search'))
            .width(20)
            .height(20)
        }
        .width(40)
        .height(40)
        .backgroundColor('transparent')
        .onClick(() => {
          // 搜索功能
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      
      // 会话列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
          Text('加载中...')
            .fontSize(16)
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: this.refreshing, offset: 120, friction: 100 }) {
          List() {
            ForEach(this.conversations, (conversation: ChatConversation) => {
              ListItem() {
                this.ConversationItem(conversation)
              }
            })
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F5F5F5')
        }
        .onRefreshing(() => {
          this.refreshConversations()
        })
      }
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  ConversationItem(conversation: ChatConversation) {
    Row() {
      // 头像
      Stack() {
        Circle()
          .width(50)
          .height(50)
          .fill(conversation.otherUserAvatar ? Color.Transparent : '#E0E0E0')
        
        if (conversation.otherUserAvatar) {
          Image(conversation.otherUserAvatar)
            .width(50)
            .height(50)
            .borderRadius(25)
        } else {
          Text(conversation.otherUserName.charAt(0).toUpperCase())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#666')
        }
        
        // 未读消息数
        if (conversation.unreadCount > 0) {
          Badge({
            count: conversation.unreadCount,
            position: BadgePosition.RightTop,
            style: { color: Color.White, fontSize: 12, badgeSize: 18 }
          })
        }
      }
      .margin({ right: 16 })
      
      // 会话信息
      Column() {
        Row() {
          Text(conversation.otherUserName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          
          Blank()
          
          Text(this.formatTime(conversation.lastMessageTime))
            .fontSize(12)
            .fontColor('#999')
        }
        .width('100%')
        .margin({ bottom: 4 })
        
        Row() {
          Text(conversation.lastMessage || '暂无消息')
            .fontSize(14)
            .fontColor('#666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          
          if (conversation.unreadCount > 0) {
            Text(conversation.unreadCount.toString())
              .fontSize(12)
              .fontColor(Color.White)
              .backgroundColor('#FF3B30')
              .borderRadius(10)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ left: 8 })
          }
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .margin({ bottom: 1 })
    .onClick(() => {
      this.onConversationSelected?.(conversation)
    })
  }
} 