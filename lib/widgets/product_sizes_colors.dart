import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductSizesColors extends StatelessWidget {
  final List<String> sizes;
  final List<String> colors;
  final String? selectedSize;
  final String? selectedColor;
  final Function(String) onSizeSelected;
  final Function(String) onColorSelected;
  final double fontSize;

  const ProductSizesColors({
    Key? key,
    required this.sizes,
    required this.colors,
    required this.selectedSize,
    required this.selectedColor,
    required this.onSizeSelected,
    required this.onColorSelected,
    this.fontSize = 8.0,
  }) : super(key: key);

 @override
Widget build(BuildContext context) {
  return Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      ...sizes.map((size) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: _buildChip(
              label: size,
              isSelected: size == selectedSize,
              onTap: () => onSizeSelected(size),
              fontSize: fontSize,
            ),
          )),
      ...colors.map((color) => Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _buildChip(
              label: color,
              isSelected: color == selectedColor,
              onTap: () => onColorSelected(color),
              fontSize: fontSize,
              isColor: true,
            ),
          )),
    ],
  );
}


  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required double fontSize,
    bool isColor = false,
  }) {
    final backgroundColor = isColor ? _parseColor(label) : Colors.grey.shade200;
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    final textColor = brightness == Brightness.dark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.deepPurple.shade700 : Colors.grey.shade400,
            width: isSelected ? 2.0 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            color: textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorName) {
    final colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'black': Colors.black,
      'white': Colors.white,
      'brown': Colors.brown,
      'grey': Colors.grey,
      'yellow': Colors.yellow,
      'pink': Colors.pink,
      'purple': Colors.purple,
      'navyblue': Color(0xFF000080),
      'orange': Colors.orange,
      'cyan': Colors.cyan,
      'teal': Colors.teal,
      'indigo': Colors.indigo,
      'lime': Colors.lime,
      'amber': Colors.amber,
      'deeporange': Colors.deepOrange,
      'lightblue': Colors.lightBlue,
    };
    return colorMap[colorName.toLowerCase()] ?? Colors.grey;
  }
}
