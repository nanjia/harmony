import { UserProfile } from '../common/model/UserProfile'
import { ApiManager } from '../common/api/ApiManager'
import picker from '@ohos.file.picker'

@Entry
@Component
struct SetupPage {
  @State currentStep: number = 0
  @State profile: UserProfile = new UserProfile()
  @State isLoading: boolean = false
  @State showAvatarPicker: boolean = false
  
  private apiManager: ApiManager = ApiManager.getInstance()
  
  aboutToAppear() {
    // 初始化设置页面
  }
  
  async createProfile() {
    if (!this.profile.name.trim()) {
      AlertDialog.show({
        title: '提示',
        message: '请输入姓名',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      })
      return
    }
    
    this.isLoading = true
    try {
      const response = await this.apiManager.createProfile(this.profile)
      
      if (response.success && response.data) {
        // 创建成功，跳转到主页面
        router.replaceUrl({ url: 'pages/Index' })
      } else {
        AlertDialog.show({
          title: '创建失败',
          message: response.error || '创建档案失败，请重试',
          primaryButton: {
            value: '确定',
            action: () => {}
          }
        })
      }
    } catch (error) {
      console.error('创建档案失败:', error)
      AlertDialog.show({
        title: '创建失败',
        message: '网络错误，请检查网络连接后重试',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      })
    } finally {
      this.isLoading = false
    }
  }
  
  async selectAvatar() {
    try {
      const photoPicker = new picker.PhotoViewPicker()
      const photoSelectOptions: picker.PhotoSelectOptions = {
        MIMEType: picker.PhotoViewMIMEType.IMAGE_TYPE,
        maxSelectNumber: 1
      }
      
      const photoView = await photoPicker.select(photoSelectOptions)
      if (photoView && photoView.photoUris && photoView.photoUris.length > 0) {
        const uri = photoView.photoUris[0]
        this.profile.avatar = uri
      }
    } catch (error) {
      console.error('选择头像失败:', error)
    }
  }
  
  nextStep() {
    if (this.currentStep < 2) {
      this.currentStep++
    }
  }
  
  prevStep() {
    if (this.currentStep > 0) {
      this.currentStep--
    }
  }
  
  build() {
    Column() {
      // 顶部进度条
      Row() {
        ForEach([0, 1, 2], (step: number) => {
          Circle()
            .width(12)
            .height(12)
            .fill(step <= this.currentStep ? '#007AFF' : '#E0E0E0')
            .margin({ right: 8 })
        })
      }
      .width('100%')
      .padding(20)
      .justifyContent(FlexAlign.Center)
      
      // 主内容区域
      Column() {
        if (this.currentStep === 0) {
          this.WelcomeStep()
        } else if (this.currentStep === 1) {
          this.BasicInfoStep()
        } else if (this.currentStep === 2) {
          this.AvatarStep()
        }
      }
      .layoutWeight(1)
      .padding(20)
      
      // 底部按钮
      Row() {
        if (this.currentStep > 0) {
          Button('上一步')
            .backgroundColor('#999999')
            .onClick(() => this.prevStep())
        }
        
        Blank()
        
        if (this.currentStep < 2) {
          Button('下一步')
            .backgroundColor('#007AFF')
            .onClick(() => this.nextStep())
        } else {
          Button('完成')
            .backgroundColor('#007AFF')
            .onClick(() => this.createProfile())
        }
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    
    // 加载对话框
    if (this.isLoading) {
      this.LoadingDialog()
    }
  }
  
  @Builder
  WelcomeStep() {
    Column() {
      Image($r('app.media.ic_welcome'))
        .width(200)
        .height(200)
        .margin({ bottom: 40 })
      
      Text('欢迎使用NFC联系人交换')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 20 })
      
      Text('通过NFC技术快速交换联系人信息，建立社交网络')
        .fontSize(16)
        .fontColor('#666')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 40 })
      
      Column() {
        this.FeatureItem('NFC快速交换', '靠近设备即可交换联系人信息')
        this.FeatureItem('实时聊天', '与联系人进行即时通讯')
        this.FeatureItem('档案管理', '管理个人档案和社交链接')
        this.FeatureItem('离线消息', '支持离线消息推送')
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  BasicInfoStep() {
    Column() {
      Text('基本信息')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 40 })
      
      Column() {
        this.InputItem('姓名', (value: string) => {
          this.profile.name = value
        }, true)
        
        this.InputItem('手机号', (value: string) => {
          this.profile.phone = value
        })
        
        this.InputItem('邮箱', (value: string) => {
          this.profile.email = value
        })
        
        this.InputItem('地址', (value: string) => {
          this.profile.address = value
        })
      }
      .width('100%')
    }
    .width('100%')
  }
  
  @Builder
  AvatarStep() {
    Column() {
      Text('选择头像')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 40 })
      
      Stack() {
        Circle()
          .width(150)
          .height(150)
          .fill(this.profile.avatar ? Color.Transparent : '#E0E0E0')
        
        if (this.profile.avatar) {
          Image(this.profile.avatar)
            .width(150)
            .height(150)
            .borderRadius(75)
        } else {
          Text(this.profile.name.charAt(0).toUpperCase())
            .fontSize(60)
            .fontWeight(FontWeight.Bold)
            .fontColor('#666')
        }
        
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_camera'))
            .width(24)
            .height(24)
        }
        .width(48)
        .height(48)
        .backgroundColor('#007AFF')
        .position({ x: '70%', y: '70%' })
        .onClick(() => this.selectAvatar())
      }
      .margin({ bottom: 40 })
      
      Text('点击相机图标选择头像')
        .fontSize(16)
        .fontColor('#666')
        .textAlign(TextAlign.Center)
      
      Text('（可选）')
        .fontSize(14)
        .fontColor('#999')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder
  FeatureItem(title: string, description: string) {
    Row() {
      Circle()
        .width(8)
        .height(8)
        .fill('#007AFF')
        .margin({ right: 12, top: 6 })
      
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 })
        
        Text(description)
          .fontSize(14)
          .fontColor('#666')
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }
  
  @Builder
  InputItem(label: string, onChange: (value: string) => void, required: boolean = false) {
    Column() {
      Row() {
        Text(label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        
        if (required) {
          Text('*')
            .fontSize(16)
            .fontColor('#FF3B30')
        }
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      TextInput({ placeholder: `请输入${label}` })
        .width('100%')
        .height(50)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ left: 16, right: 16 })
        .onChange(onChange)
    }
    .width('100%')
    .margin({ bottom: 20 })
  }
  
  @Builder
  LoadingDialog() {
    Dialog() {
      Column() {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ bottom: 16 })
        
        Text('正在创建档案...')
          .fontSize(16)
          .fontColor('#666')
      }
      .padding(20)
    }
    .width('80%')
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
} 