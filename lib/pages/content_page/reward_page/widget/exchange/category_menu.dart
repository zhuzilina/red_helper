import 'package:flutter/material.dart';

class CategoryMenu extends StatefulWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  const CategoryMenu({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  _CategoryMenuState createState() => _CategoryMenuState();
}

class _CategoryMenuState extends State<CategoryMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        itemBuilder:
            (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => widget.onCategorySelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            widget.selectedIndex == index
                                ? Colors.orange
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    widget.categories[index],
                    style: TextStyle(
                      color:
                          widget.selectedIndex == index
                              ? Colors.orange
                              : Colors.grey[600],
                      fontWeight:
                          widget.selectedIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
