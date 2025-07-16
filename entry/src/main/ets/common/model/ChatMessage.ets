/**
 * 聊天消息数据模型
 */
export class ChatMessage {
  id: number;
  senderId: number;
  receiverId: number;
  message: string;
  messageType: string;
  isRead: boolean;
  createdAt: Date;
  senderName?: string;
  senderAvatar?: string;

  constructor(
    id: number,
    senderId: number,
    receiverId: number,
    message: string,
    messageType: string = 'text',
    isRead: boolean = false,
    createdAt: Date = new Date(),
    senderName?: string,
    senderAvatar?: string
  ) {
    this.id = id;
    this.senderId = senderId;
    this.receiverId = receiverId;
    this.message = message;
    this.messageType = messageType;
    this.isRead = isRead;
    this.createdAt = createdAt;
    this.senderName = senderName;
    this.senderAvatar = senderAvatar;
  }

  /**
   * 判断消息是否来自当前用户
   */
  isFromMe(myUserId: number): boolean {
    return this.senderId === myUserId;
  }

  /**
   * 转换为JSON对象
   */
  toJson(): object {
    return {
      id: this.id,
      senderId: this.senderId,
      receiverId: this.receiverId,
      message: this.message,
      messageType: this.messageType,
      isRead: this.isRead,
      createdAt: this.createdAt.getTime(),
      senderName: this.senderName,
      senderAvatar: this.senderAvatar
    }
  }

  /**
   * 从JSON对象创建ChatMessage
   */
  static fromJson(json: any): ChatMessage {
    const message = new ChatMessage()
    message.id = json.id || 0
    message.senderId = json.senderId || 0
    message.receiverId = json.receiverId || 0
    message.message = json.message || ''
    message.messageType = json.messageType || 'text'
    message.isRead = json.isRead || false
    message.createdAt = new Date(json.createdAt || Date.now())
    message.senderName = json.senderName || ''
    message.senderAvatar = json.senderAvatar || ''
    return message
  }
}

/**
 * 聊天会话数据模型
 */
export class ChatConversation {
  id: number;
  otherUserId: number;
  otherUserName: string;
  otherUserAvatar?: string;
  lastMessage?: string;
  lastMessageTime?: Date;
  unreadCount: number;
  createdAt: Date;

  constructor(
    id: number,
    otherUserId: number,
    otherUserName: string,
    otherUserAvatar?: string,
    lastMessage?: string,
    lastMessageTime?: Date,
    unreadCount: number = 0,
    createdAt: Date = new Date()
  ) {
    this.id = id;
    this.otherUserId = otherUserId;
    this.otherUserName = otherUserName;
    this.otherUserAvatar = otherUserAvatar;
    this.lastMessage = lastMessage;
    this.lastMessageTime = lastMessageTime;
    this.unreadCount = unreadCount;
    this.createdAt = createdAt;
  }

  /**
   * 转换为JSON对象
   */
  toJson(): object {
    return {
      id: this.id,
      otherUserId: this.otherUserId,
      otherUserName: this.otherUserName,
      otherUserAvatar: this.otherUserAvatar,
      lastMessage: this.lastMessage,
      lastMessageTime: this.lastMessageTime.getTime(),
      unreadCount: this.unreadCount,
      createdAt: this.createdAt.getTime()
    }
  }

  /**
   * 从JSON对象创建ChatConversation
   */
  static fromJson(json: any): ChatConversation {
    const conversation = new ChatConversation()
    conversation.id = json.id || 0
    conversation.otherUserId = json.otherUserId || 0
    conversation.otherUserName = json.otherUserName || ''
    conversation.otherUserAvatar = json.otherUserAvatar || ''
    conversation.lastMessage = json.lastMessage || ''
    conversation.lastMessageTime = new Date(json.lastMessageTime || Date.now())
    conversation.unreadCount = json.unreadCount || 0
    conversation.createdAt = new Date(json.createdAt || Date.now())
    return conversation
  }
}

/**
 * 聊天用户数据模型
 */
export class ChatUser {
  id: number;
  name: string;
  email?: string;
  avatar?: string;

  constructor(
    id: number,
    name: string,
    email?: string,
    avatar?: string
  ) {
    this.id = id;
    this.name = name;
    this.email = email;
    this.avatar = avatar;
  }

  /**
   * 转换为JSON对象
   */
  toJson(): object {
    return {
      id: this.id,
      name: this.name,
      email: this.email,
      avatar: this.avatar
    }
  }

  /**
   * 从JSON对象创建ChatUser
   */
  static fromJson(json: any): ChatUser {
    const user = new ChatUser()
    user.id = json.id || 0
    user.name = json.name || ''
    user.email = json.email || ''
    user.avatar = json.avatar || ''
    return user
  }
}

/**
 * 发送消息请求数据模型
 */
export class SendMessageRequest {
  senderId: number;
  receiverId: number;
  message: string;
  messageType: string;

  constructor(
    senderId: number,
    receiverId: number,
    message: string,
    messageType: string = 'text'
  ) {
    this.senderId = senderId;
    this.receiverId = receiverId;
    this.message = message;
    this.messageType = messageType;
  }

  /**
   * 转换为JSON对象
   */
  toJson(): object {
    return {
      senderId: this.senderId,
      receiverId: this.receiverId,
      message: this.message,
      messageType: this.messageType
    }
  }
}

/**
 * 标记已读请求数据模型
 */
export class MarkAsReadRequest {
  userId: number;
  senderId: number;

  constructor(userId: number, senderId: number) {
    this.userId = userId;
    this.senderId = senderId;
  }

  /**
   * 转换为JSON对象
   */
  toJson(): object {
    return {
      userId: this.userId,
      senderId: this.senderId
    }
  }
} 