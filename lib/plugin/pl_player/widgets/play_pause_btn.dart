import 'dart:async';
import 'dart:io' show Platform;

import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:video_player/video_player.dart';

class PlayOrPauseButton extends StatefulWidget {
  final PlPlayerController plPlayerController;

  const PlayOrPauseButton({
    super.key,
    required this.plPlayerController,
  });

  @override
  PlayOrPauseButtonState createState() => PlayOrPauseButtonState();
}

class PlayOrPauseButtonState extends State<PlayOrPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  StreamSubscription<bool>? subscription;
  Player? player;
  VideoPlayerController? ohosPlayer;

  @override
  void initState() {
    super.initState();
    ohosPlayer = widget.plPlayerController.ohosVideoPlayerController;
    player = widget.plPlayerController.videoPlayerController;
    controller = AnimationController(
      vsync: this,
      value: Platform.isOhos
          ? (ohosPlayer?.value.isPlaying == true ? 1 : 0)
          : (player?.state.playing == true ? 1 : 0),
      duration: const Duration(milliseconds: 200),
    );
    if (Platform.isOhos) {
      ohosPlayer?.addListener(_onOhosPlayerChanged);
    } else {
      subscription = player?.stream.playing.listen((playing) {
        _updateAnimation(playing);
      });
    }
  }

  void _onOhosPlayerChanged() {
    if (!mounted) return;
    _updateAnimation(ohosPlayer?.value.isPlaying == true);
  }

  void _updateAnimation(bool playing) {
    if (playing) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    ohosPlayer?.removeListener(_onOhosPlayerChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = Platform.isOhos
        ? ohosPlayer?.value.isPlaying == true
        : player?.state.playing == true;
    return SizedBox(
      width: 42,
      height: 34,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.plPlayerController.onDoubleTapCenter,
        child: Center(
          child: AnimatedIcon(
            semanticLabel: isPlaying ? '暂停' : '播放',
            progress: controller,
            icon: AnimatedIcons.play_pause,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
