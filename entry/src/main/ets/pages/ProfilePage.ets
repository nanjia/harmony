import { UserProfile } from '../common/model/UserProfile'
import { ApiManager } from '../common/api/ApiManager'
import { NfcManager } from '../common/nfc/NfcManager'
import picker from '@ohos.file.picker'
import media from '@ohos.multimedia.media'

@Component
export struct ProfilePage {
  @State user: UserProfile | null = null
  @State isEditing: boolean = false
  @State isLoading: boolean = false
  @State showAvatarPicker: boolean = false
  
  @Prop onProfileUpdated?: (profile: UserProfile) => void
  
  private apiManager: ApiManager = ApiManager.getInstance()
  private nfcManager: NfcManager = NfcManager.getInstance()
  
  aboutToAppear() {
    this.loadProfile()
  }
  
  async loadProfile() {
    this.isLoading = true
    try {
      const userId = await this.apiManager.getUserId()
      const response = await this.apiManager.getProfile(userId)
      
      if (response.success && response.data) {
        this.user = response.data
      }
    } catch (error) {
      console.error('加载档案失败:', error)
    } finally {
      this.isLoading = false
    }
  }
  
  async saveProfile(profile: UserProfile) {
    try {
      const response = await this.apiManager.syncProfile(profile)
      
      if (response.success && response.data) {
        this.user = response.data
        this.onProfileUpdated?.(response.data)
        this.isEditing = false
      }
    } catch (error) {
      console.error('保存档案失败:', error)
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
        // 这里可以处理头像上传逻辑
        if (this.user) {
          this.user.avatar = uri
        }
      }
    } catch (error) {
      console.error('选择头像失败:', error)
    }
  }
  
  async shareProfile() {
    if (!this.user) return
    
    try {
      // 将档案写入NFC标签
      const profileData = this.user.toBytes()
      await this.nfcManager.writeNfcTag(profileData)
    } catch (error) {
      console.error('分享档案失败:', error)
    }
  }
  
  build() {
    Column() {
      // 顶部工具栏
      Row() {
        Text('档案')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        
        Blank()
        
        if (!this.isEditing) {
          Button('编辑')
            .fontSize(14)
            .backgroundColor('#007AFF')
            .onClick(() => {
              this.isEditing = true
            })
        } else {
          Row() {
            Button('取消')
              .fontSize(14)
              .backgroundColor('#999999')
              .onClick(() => {
                this.isEditing = false
              })
            
            Button('保存')
              .fontSize(14)
              .backgroundColor('#007AFF')
              .onClick(() => {
                if (this.user) {
                  this.saveProfile(this.user)
                }
              })
          }
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      
      // 档案内容
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
      } else if (this.user) {
        Scroll() {
          Column() {
            // 头像区域
            Column() {
              Stack() {
                Circle()
                  .width(100)
                  .height(100)
                  .fill(this.user.avatar ? Color.Transparent : '#E0E0E0')
                
                if (this.user.avatar) {
                  Image(this.user.avatar)
                    .width(100)
                    .height(100)
                    .borderRadius(50)
                } else {
                  Text(this.user.name.charAt(0).toUpperCase())
                    .fontSize(40)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#666')
                }
                
                if (this.isEditing) {
                  Button({ type: ButtonType.Circle }) {
                    Image($r('app.media.ic_camera'))
                      .width(20)
                      .height(20)
                  }
                  .width(32)
                  .height(32)
                  .backgroundColor('#007AFF')
                  .position({ x: '70%', y: '70%' })
                  .onClick(() => this.selectAvatar())
                }
              }
              .margin({ bottom: 16 })
              
              Text(this.user.name)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 8 })
              
              if (this.user.email) {
                Text(this.user.email)
                  .fontSize(16)
                  .fontColor('#666')
                  .margin({ bottom: 4 })
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Color.White)
            .margin({ bottom: 16 })
            
            // 基本信息
            Column() {
              Text('基本信息')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 16 })
              
              this.InfoItem('姓名', this.user.name, (value: string) => {
                if (this.isEditing) {
                  this.user!.name = value
                }
              })
              
              this.InfoItem('手机号', this.user.phone, (value: string) => {
                if (this.isEditing) {
                  this.user!.phone = value
                }
              })
              
              this.InfoItem('邮箱', this.user.email, (value: string) => {
                if (this.isEditing) {
                  this.user!.email = value
                }
              })
              
              this.InfoItem('地址', this.user.address, (value: string) => {
                if (this.isEditing) {
                  this.user!.address = value
                }
              })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .margin({ bottom: 16 })
            
            // 社交链接
            if (Object.keys(this.user.socialLinks).length > 0) {
              Column() {
                Text('社交链接')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 16 })
                
                ForEach(Object.entries(this.user.socialLinks), ([key, value]) => {
                  this.InfoItem(key, value, (newValue: string) => {
                    if (this.isEditing) {
                      this.user!.socialLinks[key] = newValue
                    }
                  })
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .margin({ bottom: 16 })
            }
            
            // 操作按钮
            if (!this.isEditing) {
              Column() {
                Button('分享档案')
                  .width('100%')
                  .height(50)
                  .backgroundColor('#007AFF')
                  .margin({ bottom: 12 })
                  .onClick(() => this.shareProfile())
                
                Button('导出档案')
                  .width('100%')
                  .height(50)
                  .backgroundColor('#28A745')
                  .margin({ bottom: 12 })
                  .onClick(() => {
                    // 导出档案功能
                  })
                
                Button('删除档案')
                  .width('100%')
                  .height(50)
                  .backgroundColor('#DC3545')
                  .onClick(() => {
                    // 删除档案功能
                  })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
            }
          }
          .padding(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  InfoItem(label: string, value: string, onChange?: (value: string) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('30%')
      
      if (this.isEditing && onChange) {
        TextInput({ text: value })
          .fontSize(16)
          .layoutWeight(1)
          .onChange(onChange)
      } else {
        Text(value || '未设置')
          .fontSize(16)
          .fontColor(value ? '#333' : '#999')
          .layoutWeight(1)
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .border({ width: { bottom: 1 }, color: '#E0E0E0' })
  }
} 