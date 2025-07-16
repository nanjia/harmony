import { defineConfig } from '@hvigor/hvigor';

export default defineConfig({
  app: {
    buildMode: 'debug',
    productType: 'phone',
    compileSdkVersion: '10',
    compatibleSdkVersion: '10'
  },
  module: {
    srcPath: 'src/main',
    package: 'com.example.harmonychat',
    mainAbility: '.EntryAbility'
  }
}); 