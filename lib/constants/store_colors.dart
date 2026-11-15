import 'package:flutter/material.dart';

/// Light card colors for store ids > 34 (ids 1-34 keep their hand-picked colors).
/// 97 entries = 87 stores + 10 spare; ids beyond that wrap around.
const _kFirstGeneratedId = 35;
const _kPaletteSize = 97;

final List<Map<String, Color>> _palette = List.generate(_kPaletteSize, (i) {
  // golden-angle hue spread, skipping the red zone (hue 345-15) so nothing looks "error red"
  final hue = 20 + (i * 137.508) % 320;
  final light = [0.36, 0.42, 0.32][i % 3];
  final border = HSLColor.fromAHSL(1, hue, 0.60, light).toColor();
  final bg = HSLColor.fromAHSL(1, hue, 0.75, 0.96).toColor();
  return {'border': border, 'background': bg, 'nameColor': border};
});

Map<String, Color> generatedStoreColors(int storeId) =>
    _palette[(storeId - _kFirstGeneratedId) % _kPaletteSize];
