import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:si_eja/services/material_service.dart';

/// Widget yang merender gambar materi secara dinamis.
///
/// Mendukung:
/// - Gambar cloud dari Firebase Storage (network URL).
/// - Gambar lokal bawaan (`assets/images/kata/...`).
/// - Indikator loading halus dan fallback error aman (tidak pernah crash).
class MaterialImageWidget extends StatefulWidget {
  final String word;
  final String? huruf;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const MaterialImageWidget({
    Key? key,
    required this.word,
    this.huruf,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<MaterialImageWidget> createState() => _MaterialImageWidgetState();
}

class _MaterialImageWidgetState extends State<MaterialImageWidget> {
  String? _resolvedPathOrUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant MaterialImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word || oldWidget.huruf != widget.huruf) {
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    // Cek cache synchronous terlebih dahulu
    final cached = MaterialService().getCachedImageUrl(widget.word);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _resolvedPathOrUrl = cached;
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    final resolved = await MaterialService().resolveImageUrl(
      widget.word,
      hurufFallback: widget.huruf,
    );

    if (mounted) {
      setState(() {
        _resolvedPathOrUrl = resolved;
        _isLoading = false;
      });
    }
  }

  Widget _buildFallback() {
    if (widget.errorWidget != null) return widget.errorWidget!;
    return Center(
      child: Icon(
        Icons.pets,
        size: (widget.width != null) ? widget.width! * 0.5 : 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _resolvedPathOrUrl == null) {
      return widget.placeholder ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
    }

    final path = _resolvedPathOrUrl;
    if (path == null || path.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: _buildFallback(),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder ??
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    if (path.startsWith('data:image/')) {
      try {
        final commaIndex = path.indexOf(',');
        final base64String = commaIndex != -1 ? path.substring(commaIndex + 1) : path;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } catch (e) {
        return _buildFallback();
      }
    }

    // Aset lokal bawaan
    return Image.asset(
      path,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }
}
