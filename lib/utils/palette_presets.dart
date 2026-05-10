import '../models/editor_models.dart';

class PalettePresets {
  static final List<PaletteCategory> categories = [
    PaletteCategory(
      name: 'NEON & CYBER',
      palettes: [
        ColorPalette(id: 'p1', name: 'Cyberpunk', colors: [0xFFF000FF, 0xFF00FFFF, 0xFF7000FF, 0xFF000000, 0xFFFFFFFF]),
        ColorPalette(id: 'p2', name: 'Tokyo Night', colors: [0xFF7AA2F7, 0xFFBB9AF7, 0xFF7DCFFF, 0xFF1A1B26, 0xFFF7768E]),
        ColorPalette(id: 'p3', name: 'Synthwave', colors: [0xFFFF2A6D, 0xFFD1F7FF, 0xFF05D9E8, 0xFF005678, 0xFF01012B]),
        ColorPalette(id: 'p4', name: 'Matrix', colors: [0xFF00FF41, 0xFF008F11, 0xFF003B00, 0xFF0D0208, 0xFFFFFFFF]),
      ],
    ),
    PaletteCategory(
      name: 'MINIMAL & SLATE',
      palettes: [
        ColorPalette(id: 'p5', name: 'Nord', colors: [0xFF2E3440, 0xFF3B4252, 0xFF434C5E, 0xFF4C566A, 0xFFD8DEE9, 0xFFE5E9F0]),
        ColorPalette(id: 'p6', name: 'Dracula', colors: [0xFF282A36, 0xFF44475A, 0xFFF8F8F2, 0xFF6272A4, 0xFF8BE9FD, 0xFF50FA7B]),
        ColorPalette(id: 'p7', name: 'One Dark', colors: [0xFF282C34, 0xFFABB2BF, 0xFFE06C75, 0xFF98C379, 0xFFD19A66, 0xFF61AFEF]),
        ColorPalette(id: 'p8', name: 'Monochrome', colors: [0xFF000000, 0xFF333333, 0xFF666666, 0xFF999999, 0xFFCCCCCC, 0xFFFFFFFF]),
      ],
    ),
    PaletteCategory(
      name: 'NATURE & EARTH',
      palettes: [
        ColorPalette(id: 'p9', name: 'Forest', colors: [0xFF1B4332, 0xFF2D6A4F, 0xFF40916C, 0xFF52B788, 0xFF74C69D, 0xFF95D5B2]),
        ColorPalette(id: 'p10', name: 'Autumn', colors: [0xFF582F0E, 0xFF7F4F24, 0xFF936639, 0xFFA68A64, 0xFFB6AD90, 0xFFC2C5AA]),
        ColorPalette(id: 'p11', name: 'Ocean', colors: [0xFF03045E, 0xFF0077B6, 0xFF00B4D8, 0xFF90E0EF, 0xFFCAF0F8, 0xFFFFFFFF]),
        ColorPalette(id: 'p12', name: 'Desert', colors: [0xFFBC6C25, 0xFFDDA15E, 0xFFFEFAE0, 0xFF283618, 0xFF606C38]),
      ],
    ),
    PaletteCategory(
      name: 'PASTEL & SOFT',
      palettes: [
        ColorPalette(id: 'p13', name: 'Cotton Candy', colors: [0xFFFFC8DD, 0xFFFFA2CC, 0xFFFFAFCC, 0xFFBDE0FE, 0xFFA2D2FF]),
        ColorPalette(id: 'p14', name: 'Marshmallow', colors: [0xFFFEEAFA, 0xFFF9F1F0, 0xFFEBF4F5, 0xFFFFF1E6, 0xFFDFE7FD]),
        ColorPalette(id: 'p15', name: 'Lavender', colors: [0xFFE7C6FF, 0xFFC8B6FF, 0xFFB8C0FF, 0xFFBBD0FF, 0xFFD8BBFF]),
        ColorPalette(id: 'p16', name: 'Peach', colors: [0xFFFFE5D9, 0xFFFFCAD4, 0xFFF4ACB7, 0xFF9D8189, 0xFFFFD7BA]),
      ],
    ),
    PaletteCategory(
      name: 'RETRO & VINTAGE',
      palettes: [
        ColorPalette(id: 'p17', name: '80s Disco', colors: [0xFFFF0054, 0xFFFF5400, 0xFFFFBD00, 0xFFE9FF70, 0xFF00B4D8]),
        ColorPalette(id: 'p18', name: 'Vinyl', colors: [0xFF222222, 0xFFE63946, 0xFFF1FAEE, 0xFFA8DADC, 0xFF457B9D, 0xFF1D3557]),
        ColorPalette(id: 'p19', name: 'Polaroid', colors: [0xFFFEF9EF, 0xFFFFCB77, 0xFF17C3B2, 0xFF227C9D, 0xFFFE6D73]),
        ColorPalette(id: 'p20', name: 'Antique', colors: [0xFF8D99AE, 0xFF2B2D42, 0xFFEDF2F4, 0xFFEF233C, 0xFFD90429]),
      ],
    ),
    PaletteCategory(
      name: 'LUXURY & RICH',
      palettes: [
        ColorPalette(id: 'p21', name: 'Royal Gold', colors: [0xFF000000, 0xFFD4AF37, 0xFFAF9500, 0xFFC0C0C0, 0xFFFFFFFF]),
        ColorPalette(id: 'p22', name: 'Emerald', colors: [0xFF004B23, 0xFF006400, 0xFF007200, 0xFF008000, 0xFF38B000, 0xFF70E000]),
        ColorPalette(id: 'p23', name: 'Ruby', colors: [0xFF641220, 0xFF6E1423, 0xFF85182A, 0xFFA11D33, 0xFFB21E35, 0xFFBD1F36]),
        ColorPalette(id: 'p24', name: 'Midnight', colors: [0xFF010101, 0xFF141414, 0xFF2B2D42, 0xFF8D99AE, 0xFFEDF2F4]),
      ],
    ),
    PaletteCategory(
      name: 'VIBRANT & POP',
      palettes: [
        ColorPalette(id: 'p25', name: 'Candy Shop', colors: [0xFFFF0000, 0xFFFF8700, 0xFFFFD300, 0xFFDEFF0A, 0xFFA1FF0A, 0xFF0AFF99]),
        ColorPalette(id: 'p26', name: 'Lego', colors: [0xFFE3000B, 0xFF0055BF, 0xFFFFD500, 0xFFFFFFFF, 0xFF000000]),
        ColorPalette(id: 'p27', name: 'Google', colors: [0xFF4285F4, 0xFFEA4335, 0xFFFBBC05, 0xFF34A853]),
        ColorPalette(id: 'p28', name: 'Instagram', colors: [0xFF405DE6, 0xFF5851DB, 0xFF833AB4, 0xFFC13584, 0xFFE1306C, 0xFFFD1D1D]),
      ],
    ),
  ];
}

class PaletteCategory {
  final String name;
  final List<ColorPalette> palettes;

  PaletteCategory({required this.name, required this.palettes});
}
