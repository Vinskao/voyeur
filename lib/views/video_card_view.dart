import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_result.dart';
import '../viewmodels/dance_viewmodel.dart';
import 'video_player_view.dart';

class VideoCardView extends StatelessWidget {
  final VideoResult video;
  final bool isActive;

  const VideoCardView({super.key, required this.video, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DanceViewModel>(context, listen: false);
    final person = video.person;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Video Player or Thumbnail
          if (isActive)
            VideoPlayerView(video: video)
          else
            Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),

          // Character Stats Overlay
          if (person != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (person.heightCm != null)
                      _buildStatText(
                        "H: ${person.heightCm}cm",
                        isHighlighted:
                            viewModel.currentSort == SortFilter.heightAsc ||
                            viewModel.currentSort == SortFilter.heightDesc,
                      ),
                    if (person.weightKg != null)
                      _buildStatText(
                        "W: ${person.weightKg}kg",
                        isHighlighted:
                            viewModel.currentSort == SortFilter.weightAsc ||
                            viewModel.currentSort == SortFilter.weightDesc,
                      ),
                    if (person.physicPower != null)
                      _buildStatText(
                        "PHY: ${person.physicPower}",
                        isHighlighted:
                            viewModel.currentSort ==
                                SortFilter.physicPowerAsc ||
                            viewModel.currentSort == SortFilter.physicPowerDesc,
                      ),
                    if (person.magicPower != null)
                      _buildStatText(
                        "MAG: ${person.magicPower}",
                        isHighlighted:
                            viewModel.currentSort == SortFilter.magicPowerAsc ||
                            viewModel.currentSort == SortFilter.magicPowerDesc,
                      ),
                    if (person.totalPower != null)
                      _buildStatText(
                        "POW: ${person.totalPower}",
                        isHighlighted:
                            viewModel.currentSort == SortFilter.totalPowerAsc ||
                            viewModel.currentSort == SortFilter.totalPowerDesc,
                        color: Colors.orangeAccent,
                      ),
                  ],
                ),
              ),
            ),

          // Name Overlay
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                video.personName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatText(
    String text, {
    bool isHighlighted = false,
    Color color = Colors.white70,
  }) {
    return Text(
      text,
      style: TextStyle(
        color: isHighlighted ? Colors.blueAccent : color,
        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
