import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const CustomFooter({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background white container with shadow and curved top corners
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 64,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    outlineIcon: Icons.home_outlined,
                    solidIcon: Icons.home,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 1,
                    outlineIcon: Icons.folder_open_outlined,
                    solidIcon: Icons.folder,
                    label: 'Projects',
                  ),
                  // Spacer and text label for floating TO-DO button
                  _buildCenterNavItem(),
                  _buildNavItem(
                    index: 3,
                    outlineIcon: Icons.calendar_month_outlined,
                    solidIcon: Icons.calendar_month,
                    label: 'Calendar',
                  ),
                  _buildNavItem(
                    index: 4,
                    outlineIcon: Icons.menu_outlined,
                    solidIcon: Icons.menu,
                    label: 'Menu',
                  ),
                ],
              ),
            ),
          ),
          // Floating Circular TO-DO Action Button
          Positioned(
            top: 2,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () => onTabSelected(2),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_box_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData outlineIcon,
    required IconData solidIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B);
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? solidIcon : outlineIcon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    final isSelected = currentIndex == 2;
    final color = isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B);
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(2),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 26),
            Text(
              'TO-DO',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}