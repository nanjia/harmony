import AbilityStage from '@ohos.app.ability.AbilityStage';
import hilog from '@ohos.hilog';

export default class MyApplication extends AbilityStage {
  onCreate() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'AbilityStage onCreate');
  }
} 