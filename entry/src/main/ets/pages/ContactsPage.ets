import { UserProfile } from '../common/model/UserProfile'
import { ApiManager } from '../common/api/ApiManager'
import { NfcManager } from '../common/nfc/NfcManager'
import { LocalDataManager } from '../common/model/LocalDataManager'

@Component
export struct ContactsPage {
  @State contacts: UserProfile[] = []
  @State isLoading: boolean = false
  @State refreshing: boolean = false
  @State showAddDialog: boolean = false
  @State newContact: UserProfile = new UserProfile()
  
  @Prop onContactAdded?: (contact: UserProfile) => void
  
  private apiManager: ApiManager = ApiManager.getInstance()
  private nfcManager: NfcManager = NfcManager.getInstance()
  private localDataManager: LocalDataManager = LocalDataManager.getInstance()
  
  aboutToAppear() {
    this.loadContacts()
  }
  
  async loadContacts() {
    this.isLoading = true
    try {
      const userId = await this.apiManager.getUserId()
      const response = await this.apiManager.getContacts(userId)
      
      if (response.success && response.data) {
        this.contacts = response.data
      }
    } catch (error) {
      console.error('加载联系人失败:', error)
    } finally {
      this.isLoading = false
    }
  }
  
  async refreshContacts() {
    this.refreshing = true
    await this.loadContacts()
    this.refreshing = false
  }
  
  async addContact(contact: UserProfile) {
    try {
      const userId = await this.apiManager.getUserId()
      const response = await this.apiManager.addContact(userId, contact)
      
      if (response.success) {
        this.contacts.push(contact)
        this.onContactAdded?.(contact)
        this.showAddDialog = false
        this.newContact = new UserProfile()
      }
    } catch (error) {
      console.error('添加联系人失败:', error)
    }
  }
  
  async handleNfcRead() {
    try {
      const nfcData = await this.nfcManager.readNfcTag()
      if (nfcData) {
        const contact = UserProfile.fromBytes(nfcData)
        if (contact) {
          this.newContact = contact
          this.showAddDialog = true
        }
      }
    } catch (error) {
      console.error('NFC读取失败:', error)
    }
  }
  
  onContactClick(contact: UserProfile) {
    // 跳转到聊天页面
    router.pushUrl({
      url: 'pages/ChatPage',
      params: {
        otherUserId: contact.id,
        otherUserName: contact.name
      }
    })
  }
  
  build() {
    Column() {
      // 顶部工具栏
      Row() {
        Text('联系人')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        
        Blank()
        
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_add'))
            .width(20)
            .height(20)
        }
        .width(40)
        .height(40)
        .backgroundColor('#007AFF')
        .onClick(() => {
          this.showAddDialog = true
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      
      // 联系人列表
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
            ForEach(this.contacts, (contact: UserProfile) => {
              ListItem() {
                this.ContactItem(contact)
              }
            })
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F5F5F5')
        }
        .onRefreshing(() => {
          this.refreshContacts()
        })
      }
    }
    .width('100%')
    .height('100%')
    
    // 添加联系人对话框
    if (this.showAddDialog) {
      this.AddContactDialog()
    }
  }
  
  @Builder
  ContactItem(contact: UserProfile) {
    Row() {
      // 头像
      Stack() {
        Circle()
          .width(50)
          .height(50)
          .fill(contact.avatar ? Color.Transparent : '#E0E0E0')
        
        if (contact.avatar) {
          Image(contact.avatar)
            .width(50)
            .height(50)
            .borderRadius(25)
        } else {
          Text(contact.name.charAt(0).toUpperCase())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#666')
        }
      }
      .margin({ right: 16 })
      
      // 联系人信息
      Column() {
        Text(contact.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 })
        
        if (contact.phone) {
          Text(contact.phone)
            .fontSize(14)
            .fontColor('#666')
            .margin({ bottom: 2 })
        }
        
        if (contact.email) {
          Text(contact.email)
            .fontSize(14)
            .fontColor('#666')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 操作按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_chat'))
          .width(20)
          .height(20)
      }
      .width(40)
      .height(40)
      .backgroundColor('#007AFF')
      .onClick(() => this.onContactClick(contact))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .margin({ bottom: 1 })
  }
  
  @Builder
  AddContactDialog() {
    Dialog() {
      Column() {
        Text('添加联系人')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })
        
        // 联系人信息表单
        TextInput({ placeholder: '姓名' })
          .width('100%')
          .height(50)
          .margin({ bottom: 16 })
          .onChange((value: string) => {
            this.newContact.name = value
          })
        
        TextInput({ placeholder: '手机号' })
          .width('100%')
          .height(50)
          .margin({ bottom: 16 })
          .onChange((value: string) => {
            this.newContact.phone = value
          })
        
        TextInput({ placeholder: '邮箱' })
          .width('100%')
          .height(50)
          .margin({ bottom: 16 })
          .onChange((value: string) => {
            this.newContact.email = value
          })
        
        TextInput({ placeholder: '地址' })
          .width('100%')
          .height(50)
          .margin({ bottom: 20 })
          .onChange((value: string) => {
            this.newContact.address = value
          })
        
        // 操作按钮
        Row() {
          Button('NFC读取')
            .backgroundColor('#FF9800')
            .onClick(() => this.handleNfcRead())
          
          Blank()
          
          Button('取消')
            .backgroundColor('#999999')
            .onClick(() => {
              this.showAddDialog = false
              this.newContact = new UserProfile()
            })
          
          Button('添加')
            .backgroundColor('#007AFF')
            .onClick(() => this.addContact(this.newContact))
        }
        .width('100%')
      }
      .padding(20)
    }
    .width('80%')
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
} 