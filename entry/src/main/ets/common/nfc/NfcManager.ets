import nfc from '@ohos.nfc'
import tag from '@ohos.nfcTag'

/**
 * NFC模式枚举
 */
export enum NfcMode {
  READER = 'reader',  // 读卡器模式
  CARD = 'card'       // 卡片模式
}

/**
 * NFC监听器接口
 */
export interface NfcListener {
  onTagDiscovered(tagData: any): void
  onTagWritten(success: boolean): void
  onError(error: string): void
}

/**
 * NFC管理器
 */
export class NfcManager {
  private static instance: NfcManager
  private nfcController: nfc.NfcController | null = null
  private currentMode: NfcMode = NfcMode.READER
  private listeners: NfcListener[] = []
  private isInitialized: boolean = false
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  static getInstance(): NfcManager {
    if (!NfcManager.instance) {
      NfcManager.instance = new NfcManager()
    }
    return NfcManager.instance
  }
  
  /**
   * 初始化NFC
   */
  async init(): Promise<void> {
    if (this.isInitialized) return
    
    try {
      // 检查NFC是否可用
      const isNfcAvailable = await nfc.isNfcAvailable()
      if (!isNfcAvailable) {
        throw new Error('设备不支持NFC')
      }
      
      // 检查NFC是否开启
      const isNfcOpen = await nfc.isNfcOpen()
      if (!isNfcOpen) {
        throw new Error('NFC未开启，请在设置中开启NFC')
      }
      
      // 创建NFC控制器
      this.nfcController = nfc.getNfcController()
      
      // 设置NFC监听器
      this.setupNfcListeners()
      
      this.isInitialized = true
      console.log('NFC管理器初始化成功')
      
    } catch (error) {
      console.error('NFC管理器初始化失败:', error)
      throw error
    }
  }
  
  /**
   * 设置NFC模式
   */
  setMode(mode: NfcMode): void {
    this.currentMode = mode
    console.log(`NFC模式切换为: ${mode}`)
  }
  
  /**
   * 获取当前模式
   */
  getMode(): NfcMode {
    return this.currentMode
  }
  
  /**
   * 读取NFC标签
   */
  async readNfcTag(): Promise<Uint8Array | null> {
    if (!this.isInitialized) {
      throw new Error('NFC未初始化')
    }
    
    if (this.currentMode !== NfcMode.READER) {
      throw new Error('当前不是读卡器模式')
    }
    
    try {
      // 这里需要实现具体的NFC读取逻辑
      // 由于鸿蒙系统的NFC API可能还在发展中，这里提供一个框架
      
      // 等待NFC标签靠近
      const tagData = await this.waitForNfcTag()
      
      if (tagData) {
        // 解析标签数据
        const parsedData = this.parseNfcData(tagData)
        return parsedData
      }
      
      return null
    } catch (error) {
      console.error('读取NFC标签失败:', error)
      throw error
    }
  }
  
  /**
   * 写入NFC标签
   */
  async writeNfcTag(data: Uint8Array): Promise<boolean> {
    if (!this.isInitialized) {
      throw new Error('NFC未初始化')
    }
    
    if (this.currentMode !== NfcMode.CARD) {
      throw new Error('当前不是卡片模式')
    }
    
    try {
      // 这里需要实现具体的NFC写入逻辑
      // 由于鸿蒙系统的NFC API可能还在发展中，这里提供一个框架
      
      // 等待NFC读取器靠近
      const success = await this.waitForNfcReader(data)
      
      if (success) {
        this.notifyTagWritten(true)
        return true
      }
      
      return false
    } catch (error) {
      console.error('写入NFC标签失败:', error)
      this.notifyError(error.message)
      return false
    }
  }
  
  /**
   * 添加NFC监听器
   */
  addListener(listener: NfcListener): void {
    this.listeners.push(listener)
  }
  
  /**
   * 移除NFC监听器
   */
  removeListener(listener: NfcListener): void {
    const index = this.listeners.indexOf(listener)
    if (index > -1) {
      this.listeners.splice(index, 1)
    }
  }
  
  /**
   * 设置NFC监听器
   */
  private setupNfcListeners(): void {
    if (!this.nfcController) return
    
    // 监听NFC标签发现
    this.nfcController.on('nfcTagDiscovered', (tagInfo: tag.TagInfo) => {
      this.handleTagDiscovered(tagInfo)
    })
    
    // 监听NFC错误
    this.nfcController.on('nfcError', (error: nfc.NfcError) => {
      this.handleNfcError(error)
    })
  }
  
  /**
   * 处理NFC标签发现
   */
  private handleTagDiscovered(tagInfo: tag.TagInfo): void {
    try {
      console.log('发现NFC标签:', tagInfo)
      
      // 根据当前模式处理标签
      if (this.currentMode === NfcMode.READER) {
        this.handleReaderMode(tagInfo)
      } else if (this.currentMode === NfcMode.CARD) {
        this.handleCardMode(tagInfo)
      }
      
    } catch (error) {
      console.error('处理NFC标签失败:', error)
      this.notifyError(error.message)
    }
  }
  
  /**
   * 处理读卡器模式
   */
  private async handleReaderMode(tagInfo: tag.TagInfo): Promise<void> {
    try {
      // 读取标签数据
      const tagData = await this.readTagData(tagInfo)
      
      if (tagData) {
        this.notifyTagDiscovered(tagData)
      }
    } catch (error) {
      console.error('读卡器模式处理失败:', error)
      this.notifyError(error.message)
    }
  }
  
  /**
   * 处理卡片模式
   */
  private async handleCardMode(tagInfo: tag.TagInfo): Promise<void> {
    try {
      // 在卡片模式下，等待读取器读取数据
      // 这里可以实现HCE（Host Card Emulation）功能
      console.log('卡片模式：等待读取器读取数据')
    } catch (error) {
      console.error('卡片模式处理失败:', error)
      this.notifyError(error.message)
    }
  }
  
  /**
   * 处理NFC错误
   */
  private handleNfcError(error: nfc.NfcError): void {
    console.error('NFC错误:', error)
    this.notifyError(error.message || 'NFC操作失败')
  }
  
  /**
   * 读取标签数据
   */
  private async readTagData(tagInfo: tag.TagInfo): Promise<any> {
    try {
      // 这里需要根据具体的标签类型实现读取逻辑
      // 支持NDEF、ISO-DEP等格式
      
      if (tagInfo.isNdefSupported) {
        return await this.readNdefData(tagInfo)
      } else if (tagInfo.isIsoDepSupported) {
        return await this.readIsoDepData(tagInfo)
      } else {
        throw new Error('不支持的标签类型')
      }
    } catch (error) {
      console.error('读取标签数据失败:', error)
      throw error
    }
  }
  
  /**
   * 读取NDEF数据
   */
  private async readNdefData(tagInfo: tag.TagInfo): Promise<any> {
    try {
      // 创建NDEF标签对象
      const ndefTag = tag.getNdefTag(tagInfo)
      
      // 读取NDEF消息
      const ndefMessage = await ndefTag.readNdefMessage()
      
      // 解析NDEF消息
      return this.parseNdefMessage(ndefMessage)
    } catch (error) {
      console.error('读取NDEF数据失败:', error)
      throw error
    }
  }
  
  /**
   * 读取ISO-DEP数据
   */
  private async readIsoDepData(tagInfo: tag.TagInfo): Promise<any> {
    try {
      // 创建ISO-DEP标签对象
      const isoDepTag = tag.getIsoDepTag(tagInfo)
      
      // 连接ISO-DEP
      await isoDepTag.connect()
      
      // 发送APDU命令读取数据
      const response = await isoDepTag.transmit(new Uint8Array([0x00, 0xB0, 0x00, 0x00, 0x00]))
      
      // 断开连接
      await isoDepTag.disconnect()
      
      return response
    } catch (error) {
      console.error('读取ISO-DEP数据失败:', error)
      throw error
    }
  }
  
  /**
   * 解析NDEF消息
   */
  private parseNdefMessage(ndefMessage: any): any {
    try {
      // 解析NDEF记录
      const records = ndefMessage.records || []
      
      for (const record of records) {
        if (record.tnf === 1) { // NFC Forum Well Known Type
          const type = new TextDecoder().decode(record.type)
          
          if (type === 'T') { // Text Record
            return this.parseTextRecord(record)
          } else if (type === 'U') { // URI Record
            return this.parseUriRecord(record)
          }
        } else if (record.tnf === 4) { // NFC Forum External Type
          const type = new TextDecoder().decode(record.type)
          
          if (type === 'application/vnd.com.example.profile') {
            return this.parseProfileRecord(record)
          }
        }
      }
      
      return null
    } catch (error) {
      console.error('解析NDEF消息失败:', error)
      throw error
    }
  }
  
  /**
   * 解析文本记录
   */
  private parseTextRecord(record: any): string {
    const payload = new Uint8Array(record.payload)
    const encoding = (payload[0] & 0x80) ? 'UTF-16' : 'UTF-8'
    const languageCodeLength = payload[0] & 0x3F
    
    const textData = payload.slice(1 + languageCodeLength)
    return new TextDecoder(encoding).decode(textData)
  }
  
  /**
   * 解析URI记录
   */
  private parseUriRecord(record: any): string {
    const payload = new Uint8Array(record.payload)
    const uriIdentifierCode = payload[0]
    
    const uriData = payload.slice(1)
    const uri = new TextDecoder().decode(uriData)
    
    // 根据URI标识符代码添加前缀
    const uriPrefixes = [
      '', 'http://www.', 'https://www.', 'http://', 'https://',
      'tel:', 'mailto:', 'ftp://anonymous:anonymous@', 'ftp://ftp.',
      'ftps://', 'sftp://', 'smb://', 'nfs://', 'ftp://', 'dav://',
      'news:', 'telnet://', 'imap:', 'rtsp://', 'urn:', 'pop:',
      'sip:', 'sips:', 'tftp:', 'btspp://', 'btl2cap://', 'btgoep://',
      'tcpobex://', 'irdaobex://', 'file://', 'urn:epc:id:', 'urn:epc:tag:',
      'urn:epc:pat:', 'urn:epc:raw:', 'urn:epc:', 'urn:nfc:'
    ]
    
    return uriPrefixes[uriIdentifierCode] + uri
  }
  
  /**
   * 解析档案记录
   */
  private parseProfileRecord(record: any): any {
    const payload = new Uint8Array(record.payload)
    const jsonString = new TextDecoder().decode(payload)
    
    try {
      return JSON.parse(jsonString)
    } catch (error) {
      console.error('解析档案记录失败:', error)
      throw error
    }
  }
  
  /**
   * 解析NFC数据
   */
  private parseNfcData(tagData: any): Uint8Array | null {
    try {
      if (typeof tagData === 'string') {
        return new TextEncoder().encode(tagData)
      } else if (tagData instanceof Uint8Array) {
        return tagData
      } else if (typeof tagData === 'object') {
        return new TextEncoder().encode(JSON.stringify(tagData))
      }
      
      return null
    } catch (error) {
      console.error('解析NFC数据失败:', error)
      return null
    }
  }
  
  /**
   * 等待NFC标签（读卡器模式）
   */
  private async waitForNfcTag(): Promise<any> {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error('等待NFC标签超时'))
      }, 30000) // 30秒超时
      
      const listener: NfcListener = {
        onTagDiscovered: (tagData) => {
          clearTimeout(timeout)
          this.removeListener(listener)
          resolve(tagData)
        },
        onTagWritten: () => {},
        onError: (error) => {
          clearTimeout(timeout)
          this.removeListener(listener)
          reject(new Error(error))
        }
      }
      
      this.addListener(listener)
    })
  }
  
  /**
   * 等待NFC读取器（卡片模式）
   */
  private async waitForNfcReader(data: Uint8Array): Promise<boolean> {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error('等待NFC读取器超时'))
      }, 30000) // 30秒超时
      
      const listener: NfcListener = {
        onTagDiscovered: () => {},
        onTagWritten: (success) => {
          clearTimeout(timeout)
          this.removeListener(listener)
          resolve(success)
        },
        onError: (error) => {
          clearTimeout(timeout)
          this.removeListener(listener)
          reject(new Error(error))
        }
      }
      
      this.addListener(listener)
    })
  }
  
  /**
   * 通知标签发现
   */
  private notifyTagDiscovered(tagData: any): void {
    this.listeners.forEach(listener => {
      listener.onTagDiscovered(tagData)
    })
  }
  
  /**
   * 通知标签写入
   */
  private notifyTagWritten(success: boolean): void {
    this.listeners.forEach(listener => {
      listener.onTagWritten(success)
    })
  }
  
  /**
   * 通知错误
   */
  private notifyError(error: string): void {
    this.listeners.forEach(listener => {
      listener.onError(error)
    })
  }
  
  /**
   * 销毁NFC管理器
   */
  destroy(): void {
    if (this.nfcController) {
      this.nfcController.off('nfcTagDiscovered')
      this.nfcController.off('nfcError')
      this.nfcController = null
    }
    
    this.listeners = []
    this.isInitialized = false
  }
} 
} 