import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../customView/CustomAppBar.dart';

Color _hex(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));

class _Coupon {
  final String bg, text, subtext;
  const _Coupon(this.bg, this.text, this.subtext);
}

class _Palette {
  final String id, name, description;
  final bool recommended;
  final Map<String, String> colors;
  final _Coupon percent, amount, delivery;
  const _Palette(this.id, this.name, this.description, this.recommended,
      this.colors, this.percent, this.amount, this.delivery);
}

const _swatchLabels = {
  'primary': 'Primary',
  'secondary': 'Secondary',
  'accent': 'Accent',
  'background': 'Background',
  'surface': 'Surface',
  'text': 'Text',
  'text-secondary': 'Text\nSecondary',
  'icons': 'Icons',
  'border': 'Border',
};

const _palettes = <_Palette>[
  _Palette(
    'classic-food-red', 'Classic Food Red',
    'Bold restaurant red with a warm, inviting background', false,
    {'primary': '#E9251A', 'secondary': '#FFF4EF', 'accent': '#FF6B35', 'background': '#FFF4EF', 'surface': '#FFFFFF', 'text': '#202124', 'text-secondary': '#6B625E', 'icons': '#E9251A', 'border': '#F0DCD5'},
    _Coupon('#FFF0ED', '#E9251A', '#B84B42'), _Coupon('#FFF1E8', '#FF6B35', '#A8542C'), _Coupon('#F0F8E9', '#287A32', '#557A4D'),
  ),
  _Palette(
    'royal-indian-heritage', 'Royal Indian Heritage',
    'Premium Indian cultural design with royal red, antique gold, and warm ivory', true,
    {'primary': '#C8202F', 'secondary': '#791C24', 'accent': '#D6A64F', 'background': '#FFF5E5', 'surface': '#FFFFFF', 'text': '#211B19', 'text-secondary': '#795B50', 'icons': '#791C24', 'border': '#E5CFA9'},
    _Coupon('#FBE6E5', '#C8202F', '#8C4145'), _Coupon('#F8EACB', '#80551A', '#927849'), _Coupon('#E7F0E2', '#386B3F', '#648067'),
  ),
  _Palette(
    'fresh-green', 'Fresh Green',
    'Fresh, bright green with a clean natural appearance', false,
    {'primary': '#16803C', 'secondary': '#F1FAF0', 'accent': '#65D957', 'background': '#F1FAF0', 'surface': '#FFFFFF', 'text': '#183322', 'text-secondary': '#F1FAF0', 'icons': '#16803C', 'border': '#D5E8D3'},
    _Coupon('#E8F6E9', '#16803C', '#426D4A'), _Coupon('#F0F9DF', '#568C19', '#66804C'), _Coupon('#E0F5ED', '#087F68', '#4D7D70'),
  ),
  _Palette(
    'modern-blue', 'Modern Blue',
    'Modern blue with cool, clean surfaces', false,
    {'primary': '#4338E8', 'secondary': '#F1F7FF', 'accent': '#5A8EFF', 'background': '#F1F7FF', 'surface': '#FFFFFF', 'text': '#172B4D', 'text-secondary': '#F1F7FF', 'icons': '#4338E8', 'border': '#D8E3F4'},
    _Coupon('#EAE9FF', '#4338E8', '#625CA8'), _Coupon('#E5F0FF', '#2563EB', '#5276AD'), _Coupon('#E0F7FA', '#087F8C', '#4D7F88'),
  ),
  _Palette(
    'spicy-orange', 'Spicy Orange',
    'Energetic orange with warm golden accents', false,
    {'primary': '#FF7000', 'secondary': '#FFF7E8', 'accent': '#FFCA2E', 'background': '#FFF7E8', 'surface': '#FFFFFF', 'text': '#592A13', 'text-secondary': '#592A13', 'icons': '#FF7000', 'border': '#F0DFC2'},
    _Coupon('#FFE9DD', '#E64A00', '#A64F2A'), _Coupon('#FFF0C2', '#B85C00', '#8C672C'), _Coupon('#EAF5D7', '#4B7F16', '#637C43'),
  ),
  _Palette(
    'premium-purple', 'Premium Purple',
    'Premium purple with soft lavender accents', false,
    {'primary': '#8D00DE', 'secondary': '#F7F2FF', 'accent': '#D081FF', 'background': '#F7F2FF', 'surface': '#FFFFFF', 'text': '#2E194C', 'text-secondary': '#F7F2FF', 'icons': '#8D00DE', 'border': '#E5D5F3'},
    _Coupon('#F2E5FF', '#8D00DE', '#8155A0'), _Coupon('#FCE7FF', '#B423C8', '#995DA0'), _Coupon('#E6F7F0', '#16856B', '#548477'),
  ),
  _Palette(
    'dark-cinematic', 'Dark Cinematic',
    'Dark premium theme with vivid red and golden accents', false,
    {'primary': '#FF003B', 'secondary': '#F5F5F5', 'accent': '#FFB547', 'background': '#111315', 'surface': '#222529', 'text': '#F5F5F5', 'text-secondary': '#B8BBC1', 'icons': '#FFFFFF', 'border': '#393C42'},
    _Coupon('#4A1E2C', '#FF003B', '#DC859D'), _Coupon('#4A3F2E', '#FFB547', '#DCC4A1'), _Coupon('#244840', '#2EE6A6', '#93D5C2'),
  ),
  _Palette(
    'warm-espresso-orange', 'Warm Espresso Orange',
    'Rich espresso surfaces with warm orange highlights', false,
    {'primary': '#F58A36', 'secondary': '#FFF1DC', 'accent': '#FFBE73', 'background': '#29221E', 'surface': '#382D27', 'text': '#FFF1DC', 'text-secondary': '#C9B9A8', 'icons': '#FFBE73', 'border': '#59463A'},
    _Coupon('#493027', '#FF9478', '#D7AA98'), _Coupon('#4B3927', '#FFC56E', '#D9BE98'), _Coupon('#303E32', '#A5D6A7', '#B0C5AF'),
  ),
  _Palette(
    'sage-garden', 'Sage Garden',
    'Soft natural green with warm neutral surfaces', true,
    {'primary': '#527A55', 'secondary': '#F5F7F0', 'accent': '#A9C89A', 'background': '#F5F7F0', 'surface': '#FFFFFF', 'text': '#26372A', 'text-secondary': '#F5F7F0', 'icons': '#527A55', 'border': '#DCE5D7'},
    _Coupon('#E7EFE1', '#3F6945', '#627C62'), _Coupon('#F6EBD4', '#80652E', '#8B7955'), _Coupon('#E2F0E7', '#356C50', '#5C806A'),
  ),
  _Palette(
    'eucalyptus-mint', 'Eucalyptus Mint',
    'Muted eucalyptus green with cool mint accents', false,
    {'primary': '#39766C', 'secondary': '#F2F7F6', 'accent': '#A8D5C7', 'background': '#F2F7F6', 'surface': '#FFFFFF', 'text': '#233B37', 'text-secondary': '#F2F7F6', 'icons': '#39766C', 'border': '#D8E7E3'},
    _Coupon('#E0EFEB', '#316A60', '#5D8078'), _Coupon('#E9F0D9', '#5E7138', '#718052'), _Coupon('#DCEFE8', '#286B58', '#568073'),
  ),
  _Palette(
    'spicy-green', 'Spicy Green',
    'Bold herb green with vibrant lime and warm cream', false,
    {'primary': '#247A3D', 'secondary': '#FFF7E8', 'accent': '#B8D943', 'background': '#FFF7E8', 'surface': '#FFFFFF', 'text': '#263A24', 'text-secondary': '#FFF7E8', 'icons': '#247A3D', 'border': '#E5DFC9'},
    _Coupon('#E8F3DF', '#247A3D', '#587A4A'), _Coupon('#FFF0C2', '#A65A00', '#8C672C'), _Coupon('#DDF4E5', '#167548', '#4D7D60'),
  ),
];

class ThemePallet extends StatefulWidget {
  const ThemePallet({super.key});

  @override
  State<ThemePallet> createState() => _ThemePalletState();
}

class _ThemePalletState extends State<ThemePallet> {
  static const _orange = Color(0xFFFF5A1F);
  bool _loading = true;
  String? _error;
  Map<String, String?> _applied = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _storeId() async =>
      (await SharedPreferences.getInstance()).getString(valueShared_STORE_KEY) ?? '';

  Future<void> _apply(_Palette p) async {
    if (_isApplied(p)) return;
    setState(() => _loading = true);
    try {
      await CallService().applyNewTheme({
        'colors': p.colors,
        'coupons': {
          for (final e in {'percent': p.percent, 'amount': p.amount, 'delivery': p.delivery}.entries)
            e.key: {'bg': e.value.bg, 'subtext': e.value.subtext, 'text': e.value.text},
        },
        'store_id': int.tryParse(await _storeId()) ?? 0,
      });
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = (await CallService().getTheme(await _storeId())).colors;
      _applied = {
        'primary': c?.primary,
        'secondary': c?.secondary,
        'accent': c?.accent,
        'background': c?.background,
        'surface': c?.surface,
        'text': c?.text,
        'text-secondary': c?.textSecondary,
        'icons': c?.icons,
        'border': c?.border,
      };
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  bool _isApplied(_Palette p) =>
      _applied.isNotEmpty &&
      p.colors.entries.every((e) =>
          (_applied[e.key] ?? '').toUpperCase() == e.value.toUpperCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F4),
      appBar: const CustomAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Theme Palette',
                      style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              if (_error != null)
                MaterialBanner(
                  content: Text(_error!),
                  actions: [TextButton(onPressed: _load, child: const Text('Retry'))],
                ),
              Expanded(
                child: LayoutBuilder(builder: (context, box) {
                  const gap = 16.0;
                  final cols = box.maxWidth >= 1000 ? 3 : box.maxWidth >= 640 ? 2 : 1;
                  final w = (box.maxWidth - 32 - gap * (cols - 1)) / cols;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final p in _palettes) SizedBox(width: w, child: _card(p)),
                      ],
                    ),
                  );
                }),
              ),
            ]),
    );
  }

  Widget _card(_Palette p) {
    final applied = _isApplied(p);
    return GestureDetector(
      onTap: () => _apply(p),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: applied ? _orange : Colors.black12, width: applied ? 1.5 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(
            child: Text(p.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          if (applied) _badge('Applied', _orange),
          if (p.recommended && !applied) _badge('Recommended', const Color(0xFFFF9B73)),
          const Spacer(),
          if (applied)
            const CircleAvatar(
              radius: 11,
              backgroundColor: _orange,
              child: Icon(Icons.check, size: 15, color: Colors.white),
            ),
        ]),
        const SizedBox(height: 4),
        Text(p.description, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            for (final e in p.colors.entries) _swatch(_swatchLabels[e.key]!, e.value),
          ],
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _coupon('Percent', p.percent)),
          const SizedBox(width: 8),
          Expanded(child: _coupon('Amount', p.amount)),
          const SizedBox(width: 8),
          Expanded(child: _coupon('Delivery', p.delivery)),
        ]),
      ]),
    ));
  }

  Widget _badge(String t, Color c) => Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
        child: Text(t,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _swatch(String label, String hex) => SizedBox(
        width: 48,
        child: Column(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hex(hex),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12, width: 2),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Colors.black45, height: 1.1)),
        ]),
      );

  Widget _coupon(String title, _Coupon c) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _hex(c.bg), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(color: _hex(c.text), fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text('Example coupon', style: TextStyle(color: _hex(c.subtext), fontSize: 11)),
        ]),
      );
}
