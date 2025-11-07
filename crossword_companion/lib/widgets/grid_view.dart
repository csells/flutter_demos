import 'package:flutter/material.dart';
import '../models/crossword_grid.dart';
import '../models/grid_cell.dart';
import '../styles.dart';

class CrosswordGridView extends StatefulWidget {
  const CrosswordGridView({
    required this.grid,
    required this.onCellTapped,
    super.key,
  });
  final CrosswordGrid grid;
  final Function(int) onCellTapped;

  @override
  State<CrosswordGridView> createState() => _CrosswordGridViewState();
}

class _CrosswordGridViewState extends State<CrosswordGridView> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: widget.grid.width,
    ),
    itemCount: widget.grid.cells.length,
    itemBuilder: (context, index) {
      final cell = widget.grid.cells[index];
      final letter = cell.userLetter ?? cell.acrossLetter ?? cell.downLetter;
      final hasConflict =
          cell.acrossLetter != null &&
          cell.downLetter != null &&
          cell.acrossLetter != cell.downLetter;
      final hasMatch =
          cell.acrossLetter != null &&
          cell.downLetter != null &&
          cell.acrossLetter == cell.downLetter;

      final letterColor = cell.userLetter != null
          ? userLetterColor
          : hasConflict
          ? conflictColor
          : hasMatch
          ? matchingColor
          : defaultLetterColor;

      var cellColor = cell.type == GridCellType.inactive
          ? Colors.black
          : emptyCellColor;

      if (_hoveredIndex == index) {
        cellColor = Color.alphaBlend(
          const Color.fromRGBO(0, 0, 0, 0.2),
          cellColor,
        );
      }

      return MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        child: GestureDetector(
          onTap: () => widget.onCellTapped(index),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: cellBorderColor),
              color: cellColor,
            ),
            child: Stack(
              children: [
                if (cell.clueNumber != null)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Text(
                      cell.clueNumber.toString(),
                      style: clueNumberStyle,
                    ),
                  ),
                if (letter != null)
                  Center(
                    child: Text(
                      letter,
                      style: letterStyle.copyWith(color: letterColor),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
