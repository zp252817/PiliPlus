import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Flutter texture backed video surface used by the HarmonyOS player.
class OhosVideoSurface extends StatelessWidget {
  const OhosVideoSurface({
    required this.controller,
    required this.fit,
    required this.fill,
    this.alignment = Alignment.center,
    super.key,
  });

  final VideoPlayerController controller;
  final BoxFit fit;
  final Color fill;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    if (!value.isInitialized) {
      return ColoredBox(color: fill);
    }

    return ColoredBox(
      color: fill,
      child: FittedBox(
        fit: fit,
        alignment: alignment,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: value.size.width,
          height: value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
