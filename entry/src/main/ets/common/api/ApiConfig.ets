export class ApiConfig {
  // 服务器基础URL
  static readonly BASE_URL: string = 'http://45.32.222.180:3001'
  
  // WebSocket服务器URL
  static readonly WS_URL: string = 'ws://45.32.222.180:3001'
  
  // API超时时间（毫秒）
  static readonly TIMEOUT: number = 30000
  
  // 重试次数
  static readonly MAX_RETRY_COUNT: number = 3
  
  // 重试延迟（毫秒）
  static readonly RETRY_DELAY: number = 1000
  
  // 特殊token（用于首次创建档案）
  static readonly SPECIAL_TOKEN: string = 'special_create_profile_token'
  
  // 应用版本信息
  static readonly APP_VERSION: string = '1.0.0'
  static readonly APP_BUILD_NUMBER: number = 90
  
  // 推送相关配置
  static readonly PUSH_SERVICE_URL: string = 'http://45.32.222.180:3001'
  
  // NFC相关配置
  static readonly NFC_APDU_SERVICE_AID: string = 'F0010203040506'
  static readonly NFC_APDU_SELECT_AID: string = '00A4040007F0010203040506'
  
  // 文件上传相关配置
  static readonly MAX_FILE_SIZE: number = 10 * 1024 * 1024 // 10MB
  static readonly ALLOWED_FILE_TYPES: string[] = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'video/mp4',
    'audio/mp3',
    'audio/wav',
    'application/pdf',
    'text/plain'
  ]
  
  // 缓存配置
  static readonly CACHE_EXPIRE_TIME: number = 24 * 60 * 60 * 1000 // 24小时
  static readonly MAX_CACHE_SIZE: number = 50 * 1024 * 1024 // 50MB
  
  // 网络配置
  static readonly NETWORK_TIMEOUT: number = 15000
  static readonly NETWORK_RETRY_COUNT: number = 2
  
  // 安全配置
  static readonly JWT_EXPIRE_TIME: number = 7 * 24 * 60 * 60 * 1000 // 7天
  static readonly REFRESH_TOKEN_EXPIRE_TIME: number = 30 * 24 * 60 * 60 * 1000 // 30天
  
  // 调试配置
  static readonly DEBUG_MODE: boolean = true
  static readonly LOG_LEVEL: string = 'info' // 'debug', 'info', 'warn', 'error'
  
  // 功能开关
  static readonly ENABLE_PUSH: boolean = true
  static readonly ENABLE_NFC: boolean = true
  static readonly ENABLE_AUTO_UPDATE: boolean = true
  static readonly ENABLE_OFFLINE_MESSAGE: boolean = true
  static readonly ENABLE_CONTACT_SYNC: boolean = true
  
  // 界面配置
  static readonly THEME_COLOR: string = '#007DFF'
  static readonly BACKGROUND_COLOR: string = '#F5F5F5'
  static readonly TEXT_COLOR: string = '#333333'
  static readonly SECONDARY_TEXT_COLOR: string = '#666666'
  
  // 动画配置
  static readonly ANIMATION_DURATION: number = 300
  static readonly TRANSITION_DURATION: number = 200
  
  // 列表配置
  static readonly PAGE_SIZE: number = 20
  static readonly REFRESH_THRESHOLD: number = 50
  
  // 消息配置
  static readonly MAX_MESSAGE_LENGTH: number = 1000
  static readonly MESSAGE_PREVIEW_LENGTH: number = 50
  
  // 头像配置
  static readonly AVATAR_SIZE: number = 40
  static readonly AVATAR_CORNER_RADIUS: number = 20
  
  // 按钮配置
  static readonly BUTTON_HEIGHT: number = 48
  static readonly BUTTON_CORNER_RADIUS: number = 8
  
  // 输入框配置
  static readonly INPUT_HEIGHT: number = 40
  static readonly INPUT_CORNER_RADIUS: number = 6
  
  // 卡片配置
  static readonly CARD_CORNER_RADIUS: number = 12
  static readonly CARD_SHADOW_RADIUS: number = 8
  static readonly CARD_SHADOW_OFFSET: number = 2
  
  // 间距配置
  static readonly MARGIN_SMALL: number = 8
  static readonly MARGIN_MEDIUM: number = 16
  static readonly MARGIN_LARGE: number = 24
  static readonly MARGIN_XLARGE: number = 32
  
  // 字体大小配置
  static readonly FONT_SIZE_SMALL: number = 12
  static readonly FONT_SIZE_MEDIUM: number = 14
  static readonly FONT_SIZE_LARGE: number = 16
  static readonly FONT_SIZE_XLARGE: number = 18
  static readonly FONT_SIZE_TITLE: number = 20
  static readonly FONT_SIZE_HEADER: number = 24
} 