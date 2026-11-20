import sensor from '@ohos.sensor';
import { FlutterEngine } from '@ohos/flutter_ohos';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import MethodChannel, {
  MethodCallHandler,
  MethodResult,
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import EventChannel, {
  EventSink,
  StreamHandler,
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';

const METHOD_CHANNEL_NAME = 'native_device_orientation';
const EVENT_CHANNEL_NAME = 'native_device_orientation_events';

const PORTRAIT_UP = 'portraitUp';
const PORTRAIT_DOWN = 'portraitDown';
const LANDSCAPE_LEFT = 'landscapeLeft';
const LANDSCAPE_RIGHT = 'landscapeRight';

/**
 * Supplies the event and method channels expected by native_device_orientation.
 * The package has no OpenHarmony implementation, so the application owns this
 * small adapter and uses the system gravity sensor to calculate the same
 * four Flutter orientation names as its Android implementation.
 */
class OrientationStreamHandler implements StreamHandler {
  private eventSink: EventSink | null = null;
  private listening: boolean = false;
  private paused: boolean = false;
  private lastOrientation: string | null = null;
  private checkIsAutoRotate: boolean = false;

  private sensorCallback = (data: sensor.GravityResponse): void => {
    if (this.paused || this.eventSink == null) {
      return;
    }

    const orientation = this.calculateOrientation(data);
    if (orientation == null || orientation === this.lastOrientation) {
      return;
    }
    this.lastOrientation = orientation;

    if (this.checkIsAutoRotate) {
      this.eventSink.success({
        orientation: orientation,
        // OpenHarmony does not expose the Android rotation-lock setting to
        // this adapter. The Flutter caller only enables this flag when it
        // needs the value, so report the sensor result as available.
        isAutoRotate: true,
      });
    } else {
      this.eventSink.success(orientation);
    }
  };

  onListen(args: Object, events: EventSink): void {
    this.eventSink = events;
    this.paused = false;
    this.lastOrientation = null;
    this.checkIsAutoRotate = this.readCheckIsAutoRotate(args);
    this.startSensor();
  }

  onCancel(args: Object): void {
    this.stopSensor();
    this.eventSink = null;
    this.lastOrientation = null;
  }

  pause(): void {
    this.paused = true;
    this.stopSensor();
  }

  resume(): void {
    this.paused = false;
    if (this.eventSink != null) {
      this.startSensor();
    }
  }

  private readCheckIsAutoRotate(args: Object): boolean {
    if (args == null) {
      return false;
    }
    const parameters = args as Map<string, Object>;
    return parameters.get('checkIsAutoRotate') === true;
  }

  private startSensor(): void {
    if (this.listening) {
      return;
    }
    try {
      sensor.on(sensor.SensorId.GRAVITY, this.sensorCallback, { interval: 'ui' });
      this.listening = true;
    } catch {
      this.eventSink?.error('sensor_unavailable', 'Gravity sensor is unavailable', null);
    }
  }

  private stopSensor(): void {
    if (!this.listening) {
      return;
    }
    try {
      sensor.off(sensor.SensorId.GRAVITY, this.sensorCallback);
    } finally {
      this.listening = false;
    }
  }

  private calculateOrientation(data: sensor.GravityResponse): string | null {
    // Keep the same 30-degree flat-device rejection used by the Android
    // implementation. It prevents accidental rotations while the device is
    // lying nearly flat.
    const x = -data.x;
    const y = -data.y;
    const z = -data.z;
    const magnitude = x * x + y * y;
    const tan30 = Math.tan(Math.PI / 6);
    if (magnitude / (z * z) < tan30 * tan30) {
      return null;
    }

    let angle = 90 - Math.round(Math.atan2(-y, x) * 180 / Math.PI);
    while (angle >= 360) {
      angle -= 360;
    }
    while (angle < 0) {
      angle += 360;
    }

    if (angle < 10 || angle > 350) {
      return PORTRAIT_UP;
    }
    if (angle > 80 && angle < 100) {
      return LANDSCAPE_RIGHT;
    }
    if (angle > 170 && angle < 190) {
      return PORTRAIT_DOWN;
    }
    if (angle > 260 && angle < 280) {
      return LANDSCAPE_LEFT;
    }
    return null;
  }
}

class OrientationMethodHandler implements MethodCallHandler {
  private readonly streamHandler: OrientationStreamHandler;

  constructor(streamHandler: OrientationStreamHandler) {
    this.streamHandler = streamHandler;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'pause':
        this.streamHandler.pause();
        result.success(null);
        break;
      case 'resume':
        this.streamHandler.resume();
        result.success(null);
        break;
      default:
        result.notImplemented();
        break;
    }
  }
}

export default class OhosOrientationPlugin {
  private readonly streamHandler = new OrientationStreamHandler();
  private methodChannel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;

  registerWith(flutterEngine: FlutterEngine): void {
    const messenger = flutterEngine.getDartExecutor();
    this.methodChannel = new MethodChannel(messenger, METHOD_CHANNEL_NAME);
    this.methodChannel.setMethodCallHandler(
      new OrientationMethodHandler(this.streamHandler),
    );
    this.eventChannel = new EventChannel(messenger, EVENT_CHANNEL_NAME);
    this.eventChannel.setStreamHandler(this.streamHandler);
  }
}
