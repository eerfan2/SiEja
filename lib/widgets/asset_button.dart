import 'package:flutter/material.dart';

class AssetButton extends StatefulWidget {
  final String normalAsset;
  final String pressedAsset;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const AssetButton({
    super.key,
    required this.normalAsset,
    required this.pressedAsset,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  State<AssetButton> createState() => _AssetButtonState();
}

class _AssetButtonState extends State<AssetButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Image.asset(
          _isPressed ? widget.pressedAsset : widget.normalAsset,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback jika asset tidak ditemukan
            return Container(
              width: widget.width ?? 50,
              height: widget.height ?? 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }
}
