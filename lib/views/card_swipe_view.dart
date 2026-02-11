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

  void _showSortMenu(BuildContext context, DanceViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true, // Allow full height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Sort Characters By",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "(Scroll for more options)",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      // shrinkWrap: true, // Removed to allow proper scrolling in Expanded
                      children: [
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.heightDesc,
                          "Height (High to Low)",
                        ),
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.heightAsc,
                          "Height (Low to High)",
                        ),
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.weightDesc,
                          "Weight (Heavy to Light)",
                        ),
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.weightAsc,
                          "Weight (Light to Heavy)",
                        ),
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.physicPowerDesc,
                          "Physic Power (High to Low)",
                        ),
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.physicPowerAsc,
                          "Physic Power (Low to High)",
                        ),
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.magicPowerDesc,
                          "Magic Power (High to Low)",
                        ),
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.magicPowerAsc,
                          "Magic Power (Low to High)",
                        ),
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.utilityPowerDesc,
                          "Utility Power (High to Low)",
                        ),
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.utilityPowerAsc,
                          "Utility Power (Low to High)",
                        ),
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.totalPowerDesc,
                          "Total Power (High to Low)",
                        ),
                        _sortTile(
                          context,
                          viewModel,
                          SortFilter.totalPowerAsc,
                          "Total Power (Low to High)",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortTile(
    BuildContext context,
    DanceViewModel viewModel,
    SortFilter filter,
    String title,
  ) {
    final isSelected = viewModel.currentSort == filter;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blueAccent : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.blueAccent)
          : null,
      onTap: () {
        viewModel.sortVideos(filter);
        Navigator.pop(context);
        // Jump to the current video in case the index changed significantly
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(viewModel.currentIndex);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DanceViewModel>(context);

    // Synchronize page controller if viewmodel index changed from elsewhere
    if (_pageController.hasClients &&
        _pageController.page?.round() != viewModel.currentIndex) {
      Future.microtask(
        () => _pageController.jumpToPage(viewModel.currentIndex),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Cards PageView
          PageView.builder(
            controller: _pageController,
            itemCount: viewModel.characters.length,
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
                  character: viewModel.characters[index],
                  isActive: index == viewModel.currentIndex,
                ),
              );
            },
          ),

          // Top Bars (Sort Button)
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(
                Icons.sort_rounded,
                size: 30,
                color: Colors.white,
              ),
              onPressed: () => _showSortMenu(context, viewModel),
            ),
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

          if (viewModel.currentIndex < viewModel.characters.length - 1)
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
