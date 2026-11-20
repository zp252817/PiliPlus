
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import OhosOrientationPlugin from '../orientation/OhosOrientationPlugin';

export default class EntryAbility extends FlutterAbility {
  private orientationPlugin: OhosOrientationPlugin | null = null;

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    this.orientationPlugin = new OhosOrientationPlugin()
    this.orientationPlugin.registerWith(flutterEngine)
  }
}
