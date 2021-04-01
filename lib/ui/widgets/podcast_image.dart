// Copyright 2020-2021 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/core/environment.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

/// This class handles rendering of podcast images from a url. Images will be
/// cached for quicker fetching on subsequent requests. An optional placeholder
/// and error placeholder can be specified which will be rendered whilst the image
/// is loading or has failed to load.
///
/// We cache the image at a fixed sized of [cacheHeight] and [cacheWidth] regardless
/// of render size. By doing this, large podcast artwork will not slow the
/// application down and the same image rendered at different sizes will return
/// the same cache hit reducing the need for fetching the image several times for
/// differing render sizes.
// ignore: must_be_immutable
class PodcastImage extends StatefulWidget {
  @override
  Key key;

  final String url;
  final double height;
  final double width;
  final BoxFit fit;
  Widget placeholder;
  Widget errorPlaceholder;

  PodcastImage({
    this.key,
    @required this.url,
    this.height = 480.0,
    this.width = 480.0,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorPlaceholder,
  }) : super(key: key);

  @override
  _PodcastImageState createState() => _PodcastImageState();
}

class _PodcastImageState extends State<PodcastImage> with TickerProviderStateMixin {
  static const cacheWidth = 480;

  AnimationController _controller;
  Animation<double> _animation;

  /// There appears to be a bug in extended image that causes images to
  /// be re-fetched if headers have been set. We'll leave headers for now.
  final headers = <String, String>{'User-Agent': Environment.userAgent()};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      widget.url,
      key: widget.key,
      width: widget.height,
      height: widget.width,
      cacheWidth: cacheWidth,
      fit: widget.fit,
      cache: true,
      loadStateChanged: (ExtendedImageState state) {
        Widget renderWidget;

        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            _controller.reset();

            renderWidget = widget.placeholder ??
                SizedBox(
                  width: widget.width,
                  height: widget.height,
                );
            break;
          case LoadState.completed:
            if (state.wasSynchronouslyLoaded) {
              renderWidget = ExtendedRawImage(
                image: state.extendedImageInfo?.image,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
              );
            } else {
              _controller.forward();

              renderWidget = FadeTransition(
                opacity: _animation,
                child: ExtendedRawImage(
                  image: state.extendedImageInfo?.image,
                  width: widget.width,
                  height: widget.height,
                  fit: widget.fit,
                ),
              );
            }
            break;
          case LoadState.failed:
            _controller.reset();

            renderWidget = widget.errorPlaceholder ??
                Container(
                  color: Colors.red,
                  width: widget.width,
                  height: widget.height,
                );
            break;
        }

        return renderWidget;
      },
    );
  }
}
