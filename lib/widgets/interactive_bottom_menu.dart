import 'package:flutter/material.dart';

class InteractiveMenuItem {
  final String label;
  final IconData icon;

  const InteractiveMenuItem({
    required this.label,
    required this.icon,
  });
}

class InteractiveBottomMenu extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<InteractiveMenuItem> items;
  final Color? accentColor;

  const InteractiveBottomMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.accentColor,
  });

  @override
  State<InteractiveBottomMenu> createState() => _InteractiveBottomMenuState();
}

class _InteractiveBottomMenuState extends State<InteractiveBottomMenu> {
  @override
  Widget build(BuildContext context) {
    final activeColor = widget.accentColor ?? Theme.of(context).primaryColor;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.items.length, (index) {
          final item = widget.items[index];
          final isActive = index == widget.selectedIndex;

          return GestureDetector(
            onTap: () => widget.onItemSelected(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 20 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: isActive ? activeColor : Colors.white54,
                    size: 24,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuint,
                    child: SizedBox(
                      width: isActive ? null : 0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: activeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
