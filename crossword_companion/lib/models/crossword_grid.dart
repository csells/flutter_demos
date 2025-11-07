import 'grid_cell.dart';

class CrosswordGrid {
  CrosswordGrid({
    required this.width,
    required this.height,
    required this.cells,
  });

  factory CrosswordGrid.fromJson(Map<String, dynamic> json) => CrosswordGrid(
    width: json['width'],
    height: json['height'],
    cells: (json['cells'] as List)
        .map((cellJson) => GridCell.fromJson(cellJson))
        .toList(),
  );
  final int width;
  final int height;
  final List<GridCell> cells;

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'cells': cells.map((cell) => cell.toJson()).toList(),
  };

  CrosswordGrid copyWith({int? width, int? height, List<GridCell>? cells}) =>
      CrosswordGrid(
        width: width ?? this.width,
        height: height ?? this.height,
        cells: cells ?? this.cells,
      );
}
