import '../models/editor_models.dart';

class PalettePresets {
  static final List<PaletteCategory> categories = [
    PaletteCategory(
      name: 'PRESETS',
      palettes: [
        ColorPalette(id: '091bfe66-16d9-4395-a478-65339cc29a3c', name: 'Palette 1', colors: [0xFFFFFFFF, 0xFF0088FC, 0xFFFE7801, 0xFFFCFCFC]),
        ColorPalette(id: '80829d17-2ff8-4185-9a81-2eb7e4f872e0', name: 'Palette 2', colors: [0xFFF2EDDB, 0xFFEA0055, 0xFF0D97F5, 0xFFE7C795]),
        ColorPalette(id: '684d293d-f259-4ba0-95b7-39d5ba8f269d', name: 'Palette 3', colors: [0xFF08192E, 0xFFFD6B6A, 0xFFFEFEFE, 0xFF505F72]),
        ColorPalette(id: 'bb09ae4a-a37c-43be-bd15-37c642deb132', name: 'Palette 4', colors: [0xFFFFFFFF, 0xFFFE533E, 0xFF1E1E1E, 0xFF232323]),
        ColorPalette(id: '27edf337-e226-4b79-8314-033da3344ec1', name: 'Palette 5', colors: [0xFFFFFFFF, 0xFF3252FF, 0xFF020202, 0xFF010101]),
        ColorPalette(id: 'dcbd5e83-c227-457b-9c1a-ea0854e6cf99', name: 'Palette 6', colors: [0xFF480004, 0xFFF5D93C, 0xFFFFFEFD, 0xFF0C0F14]),
        ColorPalette(id: '3a2aa2b5-0304-4bdd-babc-53559d8373cc', name: 'Palette 7', colors: [0xFFEBEAFE, 0xFF793AEE, 0xFF1F1B49, 0xFF1C1B46]),
        ColorPalette(id: '91fecf78-7d61-4203-9d5f-afca85aa4e5d', name: 'Palette 8', colors: [0xFF217868, 0xFFE5DABE, 0xFF1F1B49, 0xFFE5DABE]),
        ColorPalette(id: 'd5288044-4e4d-43f3-8d79-58f00ae5c7fb', name: 'Palette 9', colors: [0xFFE5DABE, 0xFF217868, 0xFF1F1B49, 0xFF217868]),
        ColorPalette(id: '759c3a7f-88f9-42fa-a3e2-a5eec039a890', name: 'Palette 10', colors: [0xFFE8E6EB, 0xFF024059, 0xFF024059, 0xFF024059]),
        ColorPalette(id: 'cbda8600-207b-4fe5-b119-ec0609da390c', name: 'Palette 11', colors: [0xFF024059, 0xFFE8E6EB, 0xFFE8E6EB, 0xFFE8E6EB]),
        ColorPalette(id: '627f895c-9832-43a7-b0fd-e66c8574394d', name: 'Palette 12', colors: [0xFF072146, 0xFFF3C5D0, 0xFFF3C5D0, 0xFFF3C5D0]),
        ColorPalette(id: '4e174bc4-0d06-496e-9398-7694abb14a27', name: 'Palette 13', colors: [0xFFF3C5D0, 0xFF072146, 0xFF072146, 0xFF072146]),
        ColorPalette(id: '11c6c7b7-fed6-4ec3-bd19-dd53f09419b3', name: 'Palette 14', colors: [0xFFA9C686, 0xFFF5F2EB, 0xFFF5F2EB, 0xFFF5F2EB]),
        ColorPalette(id: 'c49a5b3b-1cdb-4259-9b4c-f9118709d0d0', name: 'Palette 15', colors: [0xFFF5F2EB, 0xFFA9C686, 0xFFA9C686, 0xFFA9C686]),
        ColorPalette(id: '38f96949-95b6-4fc0-8d90-858aa02293b4', name: 'Palette 16', colors: [0xFFE8A938, 0xFFFCF0DA, 0xFFFCF0DA, 0xFFFCF0DA]),
        ColorPalette(id: '89e3d1bc-70b3-4506-b949-02c78d004249', name: 'Palette 17', colors: [0xFFFCF0DA, 0xFFE8A938, 0xFFE8A938, 0xFFE8A938]),
      ],
    ),
  ];
}

class PaletteCategory {
  final String name;
  final List<ColorPalette> palettes;

  PaletteCategory({required this.name, required this.palettes});
}
