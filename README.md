# 鸿蒙聊天应用

这是一个基于鸿蒙系统（HarmonyOS）开发的聊天应用，实现了与Android版本相同的功能。

## 功能特性

### 核心功能
- **用户档案管理**: 创建、编辑和同步用户个人信息
- **联系人管理**: 添加、删除和管理联系人列表
- **实时聊天**: 基于WebSocket的实时消息通信
- **NFC功能**: 通过NFC标签快速交换联系人信息
- **推送通知**: 离线消息推送和实时通知
- **应用更新**: 自动检查和下载应用更新

### 技术特性
- **MVVM架构**: 使用鸿蒙的声明式UI和状态管理
- **模块化设计**: 清晰的分层架构和模块划分
- **离线支持**: 本地数据缓存和离线消息处理
- **实时同步**: WebSocket连接和消息队列管理
- **安全认证**: Token-based身份验证

## 项目结构

```
harmony/
├── entry/src/main/ets/
│   ├── pages/                 # 页面组件
│   │   ├── Index.ets         # 主页面
│   │   ├── ContactsPage.ets  # 联系人页面
│   │   ├── ChatListPage.ets  # 聊天列表页面
│   │   ├── ProfilePage.ets   # 档案页面
│   │   ├── SetupPage.ets     # 设置页面
│   │   └── UpdatePage.ets    # 更新页面
│   ├── common/               # 公共模块
│   │   ├── api/             # API相关
│   │   │   ├── ApiManager.ets
│   │   │   └── ApiConfig.ets
│   │   ├── model/           # 数据模型
│   │   │   ├── UserProfile.ets
│   │   │   └── ChatMessage.ets
│   │   ├── websocket/       # WebSocket管理
│   │   │   └── WebSocketManager.ets
│   │   ├── chat/            # 聊天管理
│   │   │   └── ChatManager.ets
│   │   ├── nfc/             # NFC功能
│   │   │   └── NfcManager.ets
│   │   ├── push/            # 推送管理
│   │   │   └── PushManager.ets
│   │   ├── update/          # 更新管理
│   │   │   └── UpdateManager.ets
│   │   └── data/            # 本地数据管理
│   │       └── LocalDataManager.ets
│   └── entryability/        # 应用入口
│       └── EntryAbility.ets
├── resources/               # 资源文件
└── module.json5            # 模块配置
```

## 开发环境要求

- **DevEco Studio**: 4.0或更高版本
- **HarmonyOS SDK**: API 9或更高版本
- **Node.js**: 16.0或更高版本
- **鸿蒙设备**: 支持HarmonyOS 3.0或更高版本的设备

## 安装和运行

### 1. 克隆项目
```bash
git clone <repository-url>
cd harmony
```

### 2. 打开项目
使用DevEco Studio打开项目目录

### 3. 配置设备
- 连接鸿蒙设备或启动模拟器
- 确保设备已开启开发者选项和USB调试

### 4. 运行应用
- 点击DevEco Studio的运行按钮
- 选择目标设备
- 等待应用安装和启动

## 配置说明

### 服务器配置
在 `ApiConfig.ets` 中配置服务器地址：

```typescript
export class ApiConfig {
  static readonly BASE_URL: string = 'http://your-server-ip:3001'
  static readonly WS_URL: string = 'ws://your-server-ip:3001'
}
```

### 权限配置
应用需要以下权限：
- `ohos.permission.INTERNET`: 网络访问
- `ohos.permission.NFC`: NFC功能
- `ohos.permission.NOTIFICATION_CONTROLLER`: 推送通知
- `ohos.permission.READ_MEDIA`: 读取媒体文件
- `ohos.permission.WRITE_MEDIA`: 写入媒体文件

## 主要功能实现

### 1. 用户档案管理
- 首次使用时的档案创建向导
- 档案信息的编辑和同步
- 头像上传和社交链接管理

### 2. 联系人管理
- 联系人列表显示和管理
- NFC标签读取和写入
- 联系人信息的快速交换

### 3. 实时聊天
- WebSocket实时通信
- 消息发送和接收
- 消息状态管理（已读/未读）
- 离线消息处理

### 4. NFC功能
- NFC标签读取
- 联系人信息写入
- 数据格式化和解析

### 5. 推送通知
- 离线消息推送
- 实时通知显示
- 通知权限管理

### 6. 应用更新
- 自动检查更新
- 增量更新支持
- 更新进度显示

## 架构设计

### MVVM模式
- **Model**: 数据模型和业务逻辑
- **View**: 声明式UI组件
- **ViewModel**: 状态管理和数据绑定

### 模块化设计
- **API层**: 网络请求和数据处理
- **业务层**: 核心业务逻辑
- **UI层**: 用户界面组件
- **工具层**: 通用工具和辅助功能

### 数据流
1. UI组件触发事件
2. ViewModel处理业务逻辑
3. Model更新数据状态
4. 通过数据绑定更新UI

## 性能优化

### 1. 内存管理
- 及时释放不需要的资源
- 使用弱引用避免内存泄漏
- 合理使用缓存机制

### 2. 网络优化
- 请求合并和批量处理
- 数据压缩和缓存
- 断线重连机制

### 3. UI优化
- 列表虚拟化
- 图片懒加载
- 动画性能优化

## 测试

### 单元测试
```bash
# 运行单元测试
npm test
```

### 集成测试
```bash
# 运行集成测试
npm run test:integration
```

### 性能测试
```bash
# 运行性能测试
npm run test:performance
```

## 部署

### 1. 构建应用
```bash
# 构建Release版本
npm run build:release
```

### 2. 签名应用
```bash
# 应用签名
npm run sign
```

### 3. 发布应用
- 上传到华为应用市场
- 或通过其他渠道分发

## 常见问题

### 1. NFC功能不工作
- 检查设备是否支持NFC
- 确认NFC权限已授予
- 验证NFC标签格式

### 2. 网络连接失败
- 检查网络连接状态
- 验证服务器地址配置
- 确认防火墙设置

### 3. 推送通知不显示
- 检查通知权限设置
- 验证推送服务配置
- 确认设备网络连接

## 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交代码更改
4. 创建Pull Request

## 许可证

本项目采用MIT许可证，详见LICENSE文件。

## 联系方式

如有问题或建议，请通过以下方式联系：
- 邮箱: [your-email@example.com]
- 项目Issues: [GitHub Issues链接]

## 更新日志

### v1.0.0 (2024-01-15)
- 初始版本发布
- 实现基础聊天功能
- 支持NFC联系人交换
- 添加推送通知功能 #   h a r m o n y  
 