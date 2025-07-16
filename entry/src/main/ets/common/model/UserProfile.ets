import hilog from '@ohos.hilog';

export class UserProfile {
  id: number = 0;
  name: string = '';
  email: string = '';
  phone: string = '';
  address: string = '';
  avatar: string = '';
  socialLinks: Map<string, string> = new Map();
  createdAt: string = '';
  updatedAt: string = '';

  constructor(
    name: string = '',
    email: string = '',
    phone: string = '',
    address: string = '',
    avatar: string = '',
    socialLinks: Map<string, string> = new Map()
  ) {
    this.name = name;
    this.email = email;
    this.phone = phone;
    this.address = address;
    this.avatar = avatar;
    this.socialLinks = socialLinks;
  }

  /**
   * 将 UserProfile 转换为 JSON 字符串
   */
  toJson(): string {
    const socialLinksObj = {};
    this.socialLinks.forEach((value, key) => {
      socialLinksObj[key] = value;
    });

    return JSON.stringify({
      id: this.id,
      name: this.name,
      email: this.email,
      phone: this.phone,
      address: this.address,
      avatar: this.avatar,
      socialLinks: socialLinksObj,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    });
  }

  /**
   * 将 UserProfile 转换为字节数组（用于 NFC 传输）
   */
  toBytes(): Uint8Array {
    return new TextEncoder().encode(this.toJson());
  }

  /**
   * 从 JSON 字符串创建 UserProfile
   */
  static fromJson(json: string): UserProfile | null {
    try {
      const obj = JSON.parse(json);
      const profile = new UserProfile();
      profile.id = obj.id || 0;
      profile.name = obj.name || '';
      profile.email = obj.email || '';
      profile.phone = obj.phone || '';
      profile.address = obj.address || '';
      profile.avatar = obj.avatar || '';
      profile.createdAt = obj.createdAt || '';
      profile.updatedAt = obj.updatedAt || '';

      if (obj.socialLinks) {
        Object.keys(obj.socialLinks).forEach(key => {
          profile.socialLinks.set(key, obj.socialLinks[key]);
        });
      }

      return profile;
    } catch (error) {
      hilog.error(0x0000, 'UserProfile', 'Failed to parse JSON: %{public}s', error.message);
      return null;
    }
  }

  /**
   * 从字节数组创建 UserProfile
   */
  static fromBytes(bytes: Uint8Array): UserProfile | null {
    try {
      const json = new TextDecoder().decode(bytes);
      return UserProfile.fromJson(json);
    } catch (error) {
      hilog.error(0x0000, 'UserProfile', 'Failed to parse bytes: %{public}s', error.message);
      return null;
    }
  }

  /**
   * 从消息创建 UserProfile（兼容旧版本）
   */
  static fromNdefMessage(message: string): UserProfile {
    return UserProfile.fromJson(message) || new UserProfile(
      '未知用户',
      '',
      '',
      ''
    );
  }
} 