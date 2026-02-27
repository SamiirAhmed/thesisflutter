import 'dart:async';
import 'package:flutter/material.dart';

/// Premium gradient header shown at the top of student and teacher dashboards.
/// Displays a high-impact university announcement banner.
class DashboardHeader extends StatefulWidget {
  final String name;
  final String roleName;
  final int roleId;

  const DashboardHeader({
    super.key,
    required this.name,
    required this.roleName,
    required this.roleId,
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/banner.jpg',
      'tag': 'EXAM APPEAL',
      'title': 'Academic Appeal\nTracking System',
      'desc': 'Submit and monitor your exam appeals in real-time.',
    },
    {
      'image': 'assets/banner3.png',
      'tag': 'CLASS ISSUE',
      'title': 'Report Your\nClassroom Issues',
      'desc': 'Ensure a better learning experience for everyone.',
    },
    {
      'image': 'assets/banner2.jpg',
      'tag': 'CAMPUS ENVIRONMENT',
      'title': 'Campus Cleaning &\nEnvironment Care',
      'desc': 'Report campus environment issues to the administration.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        child: Stack(
          children: [
            // Image Slider
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _slides[index]['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF1A237E),
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white24,
                          size: 40,
                        ),
                      ),
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.9),
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF1E88E5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _slides[index]['tag']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _slides[index]['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _slides[index]['desc']!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Dots
                          Row(
                            children: List.generate(_slides.length, (dotIndex) {
                              final isActive = _currentPage == dotIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 6),
                                width: isActive ? 24 : 6,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
