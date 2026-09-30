import 'package:flutter/material.dart';

class BgScaffold extends StatelessWidget {
  final String backgroundAsset;
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;
  final double backgroundScale;

  const BgScaffold({
    super.key,
    required this.backgroundAsset,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
    this.backgroundScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        child: Stack(
          children: [
            // Background fullscreen responsive
            Positioned.fill(
              child: ClipRect(
                child: Transform.scale(
                  scale: backgroundScale,
                  child: Image.asset(
                    backgroundAsset,
                    fit: BoxFit.fill,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            // Konten di atas background
            child,
          ],
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
