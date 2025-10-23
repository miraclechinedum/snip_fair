import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:snip_fair/features/stylists/stylist_profile/views/stylist_seller_details_screen.dart';
import 'package:snip_fair/gen/assets.gen.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    Key? key,
    required this.imagePaths,
    this.height = 200,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.viewportFraction = 1.0,
  }) : super(key: key);

  final List<String> imagePaths;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final double viewportFraction;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late final PageController _controller;
  bool hasError = false;
  int _current = 0;
  Timer? _timer;
  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.autoPlay && widget.imagePaths.length > 1) {
      _timer = Timer.periodic(widget.autoPlayInterval, (_) {
        final next = (_current + 1) % widget.imagePaths.length;
        if (mounted) {
          _controller.animateToPage(
            next,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _stopAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didUpdateWidget(covariant ImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldRestart = oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.autoPlayInterval != widget.autoPlayInterval ||
        oldWidget.imagePaths.length != widget.imagePaths.length;

    if (shouldRestart) {
      _stopAutoPlay();
      if (widget.autoPlay && widget.imagePaths.length > 1) {
        _startAutoPlay();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: widget.viewportFraction);
    if (widget.autoPlay && widget.imagePaths.length > 1) {
      _timer = Timer.periodic(widget.autoPlayInterval, (_) {
        final next = (_current + 1) % widget.imagePaths.length;
        if (mounted) {
          _controller.animateToPage(
            next,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagePaths.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: ColoredBox(
          color: Colors.grey.shade200,
          child: Center(child: SvgPicture.asset(Assets.images.logo)),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) => setState(() => _current = index),
            itemBuilder: (context, index) {
              final url = widget.imagePaths[index];
              return GestureDetector(
                onTap: () {
                  // Handle image tap if needed
                  if (hasError) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageView(imagePath: url),
                    ),
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Image.asset(
                    Assets.images.loading.path,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  errorWidget: (context, url, error) {
                    hasError = true;
                    return ColoredBox(
                      color: Colors.grey.shade200,
                      child:
                          Center(child: SvgPicture.asset(Assets.images.logo)),
                    );
                  },
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.imagePaths.length, (i) {
                final isActive = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
