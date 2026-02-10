import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'image_url_cache.dart';

class FishSprite extends StatefulWidget {
  final String storagePath;
  final DateTime? updatedAt;
  final String bucket;
  final double width;
  final double height;
  final Duration duration;
  final bool flipX;
  final bool animate;

  const FishSprite({
    super.key,
    required this.storagePath,
    this.updatedAt,
    this.bucket = 'aquaverse',
    this.width = 72,
    this.height = 48,
    this.duration = const Duration(milliseconds: 600),
    this.flipX = false,
    this.animate = true,
  });

  @override
  State<FishSprite> createState() => _FishSpriteState();
}

class _FishSpriteState extends State<FishSprite> with TickerProviderStateMixin {
  AnimationController? _controller;
  String _url = '';

  @override
  void initState() {
    super.initState();
    _syncController();
    _buildUrl();
  }

  @override
  void didUpdateWidget(covariant FishSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath ||
        oldWidget.bucket != widget.bucket ||
        oldWidget.updatedAt != widget.updatedAt) {
      _buildUrl();
    }
    if (oldWidget.animate != widget.animate ||
        oldWidget.duration != widget.duration) {
      _syncController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _syncController() {
    _controller?.dispose();
    _controller = null;
    if (!widget.animate) return;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  void _buildUrl() {
    final p = widget.storagePath.trim();
    final spritePath = p.contains('/') ? p : 'biota/$p';
    
    if (spritePath.isEmpty) {
      _url = '';
      return;
    }

    // Pakai cache URL yang sudah kita buat tadi
    _url = ImageUrlCache.publicUrl(
      bucket: widget.bucket,
      path: spritePath,
      updatedAt: widget.updatedAt,
    );
  }

  int _currentFrame() {
    if (!widget.animate || _controller == null) return 0;
    return (_controller!.value * 4).floor() % 4;
  }

  @override
  Widget build(BuildContext context) {
    if (_url.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    final spriteContent = Stack(
      children: [
        Positioned(
          // Logic frame 2x2 tetap sama
          left: (_currentFrame() == 1 || _currentFrame() == 3) ? -widget.width : 0.0,
          top: (_currentFrame() == 2 || _currentFrame() == 3) ? -widget.height : 0.0,
          width: widget.width * 2,
          height: widget.height * 2,
          child: CachedNetworkImage(
            imageUrl: _url,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none, // Pixel art look
            
            // --- OPTIMASI RAM ---
            // Karena sheet-nya 2x2, cache-nya 2x lipat ukuran frame
            memCacheWidth: (widget.width * 2).round(),
            memCacheHeight: (widget.height * 2).round(),
            
            // --- OPTIMASI LOADING ---
            placeholder: (context, url) => const SizedBox.shrink(),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white24),
          ),
        ),
      ],
    );

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(widget.flipX ? -1.0 : 1.0, 1.0),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ClipRect(
          child: widget.animate 
            ? AnimatedBuilder(
                animation: _controller!,
                builder: (_, __) => spriteContent,
              )
            : spriteContent,
        ),
      ),
    );
  }
}