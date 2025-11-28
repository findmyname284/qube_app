import 'dart:async';
import 'package:flutter/material.dart';

class OptimizedNetworkImage extends StatefulWidget {
  final String imageUrl;

  const OptimizedNetworkImage({super.key, required this.imageUrl});

  @override
  State<OptimizedNetworkImage> createState() => _OptimizedNetworkImageState();
}

class _OptimizedNetworkImageState extends State<OptimizedNetworkImage> {
  late final Future<ImageInfo> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  Future<ImageInfo> _loadImage() async {
    final completer = Completer<ImageInfo>();
    final imageStream = NetworkImage(
      widget.imageUrl,
    ).resolve(const ImageConfiguration());

    final listener = ImageStreamListener((ImageInfo info, bool sync) {
      if (!completer.isCompleted) {
        completer.complete(info);
      }
    });

    imageStream.addListener(listener);

    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        imageStream.removeListener(listener);
        completer.completeError('Timeout');
      }
    });

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageInfo>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return RawImage(image: snapshot.data!.image, fit: BoxFit.cover);
        } else if (snapshot.hasError) {
          return const SizedBox.shrink();
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
