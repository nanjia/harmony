import { ChatMessage, SendMessageRequest, MarkAsReadRequest } from '../common/model/ChatMessage'
import { ApiManager } from '../common/api/ApiManager'
import { WebSocketManager } from '../common/api/WebSocketManager'
import { LocalDataManager } from '../common/model/LocalDataManager'

@Entry
@Component
struct ChatPage {
  @State messages: ChatMessage[] = []
  @State inputText: string = ''
  @State isLoading: boolean = false
  @State isSending: boolean = false
  
  private otherUserId: number = 0
  private otherUserName: string = ''
  private currentUserId: number = 0
  
  private apiManager: ApiManager = ApiManager.getInstance()
  private webSocketManager: WebSocketManager = WebSocketManager.getInstance()
  private localDataManager: LocalDataManager = LocalDataManager.getInstance()
  
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams()
    this.otherUserId = params?.otherUserId || 0
    this.otherUserName = params?.otherUserName || '未知用户'
    
    this.initChat()
  }
  
  async initChat() {
    try {
      // 获取当前用户ID
      this.currentUserId = await this.apiManager.getUserId()
      
      // 加载历史消息
      await this.loadHistoryMessages()
      
      // 设置WebSocket监听器
      this.setupWebSocketListener()
      
      // 标记消息为已读
      await this.markMessagesAsRead()
      
    } catch (error) {
      console.error('初始化聊天失败:', error)
    }
  }
  
  async loadHistoryMessages() {
    this.isLoading = true
    try {
      const response = await this.apiManager.getChatMessages(this.currentUserId, this.otherUserId)
      
      if (response.success && response.data) {
        this.messages = response.data
      }
    } catch (error) {
      console.error('加载历史消息失败:', error)
    } finally {
      this.isLoading = false
    }
  }
  
  setupWebSocketListener() {
    this.webSocketManager.addMessageListener({
      onMessageReceived: (message) => {
        if (message.senderId === this.otherUserId && message.receiverId === this.currentUserId) {
          this.handleNewMessage(message)
        }
      },
      onMessageSent: (success, messageId) => {
        this.isSending = false
        if (success) {
          console.log('消息发送成功:', messageId)
        } else {
          console.error('消息发送失败')
        }
      },
      onMessageRead: (readerId) => {
        // 消息被读取，可以更新UI状态
      },
      onOnlineStatusReceived: (status) => {
        // 在线状态更新
      },
      onOfflineMessagesReceived: (messages) => {
        // 离线消息处理
      }
    })
  }
  
  handleNewMessage(message: ChatMessage) {
    this.messages.push(message)
    // 标记为已读
    this.markMessagesAsRead()
  }
  
  async sendMessage() {
    if (!this.inputText.trim() || this.isSending) {
      return
    }
    
    this.isSending = true
    
    try {
      const request = new SendMessageRequest(
        this.currentUserId,
        this.otherUserId,
        this.inputText.trim()
      )
      
      // 先添加到本地消息列表
      const localMessage = new ChatMessage(
        this.currentUserId,
        this.otherUserId,
        this.inputText.trim()
      )
      localMessage.senderName = '我'
      localMessage.createdAt = new Date()
      this.messages.push(localMessage)
      
      // 清空输入框
      this.inputText = ''
      
      // 通过WebSocket发送消息
      await this.webSocketManager.sendPrivateMessage(request)
      
    } catch (error) {
      console.error('发送消息失败:', error)
      this.isSending = false
    }
  }
  
  async markMessagesAsRead() {
    try {
      const request = new MarkAsReadRequest(this.currentUserId, this.otherUserId)
      await this.webSocketManager.markAsRead(request)
    } catch (error) {
      console.error('标记已读失败:', error)
    }
  }
  
  formatTime(date: Date): string {
    return date.toLocaleTimeString('zh-CN', { 
      hour: '2-digit', 
      minute: '2-digit' 
    })
  }
  
  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_back'))
            .width(20)
            .height(20)
        }
        .width(40)
        .height(40)
        .backgroundColor('transparent')
        .onClick(() => {
          router.back()
        })
        
        Column() {
          Text(this.otherUserName)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          
          Text('在线')
            .fontSize(12)
            .fontColor('#666')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
        
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_more'))
            .width(20)
            .height(20)
        }
        .width(40)
        .height(40)
        .backgroundColor('transparent')
        .onClick(() => {
          // 显示更多选项
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: '#E0E0E0' })
      
      // 消息列表
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
        List() {
          ForEach(this.messages, (message: ChatMessage) => {
            ListItem() {
              this.MessageItem(message)
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
        .padding(16)
      }
      
      // 输入区域
      Row() {
        TextInput({ placeholder: '输入消息...', text: this.inputText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(Color.White)
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.inputText = value
          })
          .onSubmit(() => {
            this.sendMessage()
          })
        
        Button({ type: ButtonType.Circle }) {
          if (this.isSending) {
            LoadingProgress()
              .width(20)
              .height(20)
          } else {
            Image($r('app.media.ic_send'))
              .width(20)
              .height(20)
          }
        }
        .width(40)
        .height(40)
        .backgroundColor('#007AFF')
        .margin({ left: 8 })
        .onClick(() => {
          this.sendMessage()
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#E0E0E0' })
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  MessageItem(message: ChatMessage) {
    const isFromMe = message.isFromMe(this.currentUserId)
    
    Column() {
      Row() {
        if (isFromMe) {
          Blank()
        }
        
        Column() {
          // 消息气泡
          Text(message.message)
            .fontSize(16)
            .fontColor(isFromMe ? Color.White : '#333')
            .backgroundColor(isFromMe ? '#007AFF' : Color.White)
            .borderRadius(16)
            .padding(12)
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          
          // 时间
          Text(this.formatTime(message.createdAt))
            .fontSize(12)
            .fontColor('#999')
            .margin({ top: 4 })
        }
        .alignItems(isFromMe ? HorizontalAlign.End : HorizontalAlign.Start)
        .maxWidth('70%')
        
        if (!isFromMe) {
          Blank()
        }
      }
      .width('100%')
      .margin({ bottom: 16 })
    }
  }
  
  aboutToDisappear() {
    // 清理WebSocket监听器
    this.webSocketManager.removeMessageListener({} as any)
  }
} 