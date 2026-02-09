import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dance_viewmodel.dart';
import 'video_card_view.dart';

class CardSwipeView extends StatefulWidget {
  const CardSwipeView({super.key});

  @override
  State<CardSwipeView> createState() => _CardSwipeViewState();
}

class _CardSwipeViewState extends State<CardSwipeView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<DanceViewModel>(context, listen: false);
    _pageController = PageController(
      initialPage: viewModel.currentIndex,
      viewportFraction: 0.85,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DanceViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Cards PageView
          PageView.builder(
            controller: _pageController,
            itemCount: viewModel.videos.length,
            onPageChanged: (index) {
              viewModel.setCurrentIndex(index);
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
                  } else {
                    // Handle initial state before dimensions are available
                    value = (index == viewModel.currentIndex) ? 1.0 : 0.85;
                  }

                  return Center(
                    child: SizedBox(
                      height:
                          Curves.easeInOut.transform(value) *
                          MediaQuery.of(context).size.height *
                          0.85,
                      width:
                          Curves.easeInOut.transform(value) *
                          MediaQuery.of(context).size.width,
                      child: child,
                    ),
                  );
                },
                child: VideoCardView(
                  video: viewModel.videos[index],
                  isActive: index == viewModel.currentIndex,
                ),
              );
            },
          ),

          // Navigation Overlay (Arrows)
          if (viewModel.currentIndex > 0)
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavButton(
                  icon: Icons.chevron_left,
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),

          if (viewModel.currentIndex < viewModel.videos.length - 1)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavButton(
                  icon: Icons.chevron_right,
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),

          // Reload Button
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 50,
                  color: Colors.white70,
                ),
                onPressed: () => viewModel.reload(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black26,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 40, color: Colors.white54),
        onPressed: onPressed,
      ),
    );
  }
}
