import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final Function(int) onSelect;
  final int selectedIndex;

  const Sidebar({super.key, required this.onSelect, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.grey.shade200,
      child: Column(
        children: [
          const SizedBox(height: 40),
          menuItem("Dashboard", 0),
          menuItem("Users", 1),
          menuItem("Orders", 2),
        ],
      ),
    );
  }

  Widget menuItem(String title, int index) {
    return ListTile(
      selected: index == selectedIndex,
      title: Text(title),
      onTap: () => onSelect(index),
    );
  }
}
