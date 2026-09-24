import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';

class StoreProfile extends StatefulWidget {
  const StoreProfile({super.key});

  @override
  State<StoreProfile> createState() => _StoreProfileState();
}

class _StoreProfileState extends State<StoreProfile> {
  final ImagePicker _picker = ImagePicker();
  String? storeId;
  String storeName = '';
  String logoUrl = '';
  String bannerUrl = '';
  File? logoFile;
  File? bannerFile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  // Remove query parameters (everything after '?')
  String _trimUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final i = url.indexOf('?');
    return i == -1 ? url : url.substring(0, i);
  }

  void _showLoader() {
    Get.dialog(
      Center(
        child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true),
      ),
      barrierDismissible: false,
    );
  }

  void _hideLoader() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  void _snack(String msg, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _loadStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      storeId = prefs.getString(valueShared_STORE_KEY);
      final bearer = prefs.getString(valueShared_BEARER_KEY);
      final store = await ApiRepo().getStoreData(bearer!, storeId!);
      setState(() {
        storeName = store.name ?? '';
        logoUrl = _trimUrl(store.imageUrl);
        bannerUrl = _trimUrl(store.bannerUrl);
      });
    } catch (e) {
      _snack('Failed to load store: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pick(bool isLogo) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text('camera'.tr),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    final image = await _picker.pickImage(
      source: source,
      maxWidth: isLogo ? 500 : 1200,
      maxHeight: isLogo ? 500 : 400,
      imageQuality: 80,
    );
    if (image == null) return;
    setState(() => isLogo ? logoFile = File(image.path) : bannerFile = File(image.path));
  }

  Future<String?> _upload(File file) async {
    final res = await CallService().uploadImage(file);
    if (res.url == null || res.url!.isEmpty) throw Exception('Image URL is empty');
    return _trimUrl(res.url);
  }

  Future<void> _save() async {
    if (storeId == null) return;
    _showLoader();
    try {
      if (logoFile != null) logoUrl = (await _upload(logoFile!))!;
      if (bannerFile != null) bannerUrl = (await _upload(bannerFile!))!;
      final body = {"image_url": logoUrl, "banner_url": bannerUrl};
      print("Update Store Images Body: $body");
      await CallService().updateStoreImages(body, storeId!);
      _hideLoader();
      setState(() {
        logoFile = null;
        bannerFile = null;
      });
      _snack('Store profile updated', color: Colors.green);
    } catch (e) {
      _hideLoader();
      _snack('Failed to update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Get.back()),
        title: Text(
          storeName.isEmpty ? 'Store Profile' : 'Store Profile — $storeName',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5E14),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(children: [_logoCard(), const SizedBox(height: 12), _bannerCard()]),
            ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  // Shows the picked file if any, else the network url, else a placeholder.
  Widget _image(File? file, String url, {BoxFit fit = BoxFit.cover}) {
    if (file != null) return Image.file(file, fit: fit);
    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    return Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]);
  }

  Widget _removeButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Icon(Icons.close, color: Colors.red, size: 20),
      ),
    );
  }

  Widget _chooseButton(String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.black87),
      label: Text(label, style: const TextStyle(color: Colors.black87)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _logoCard() {
    final hasImage = logoFile != null || logoUrl.isNotEmpty;
    return _card(
      'Store Logo',
      Row(
        children: [
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[200]!, width: 3),
                ),
                child: ClipOval(child: _image(logoFile, logoUrl, fit: BoxFit.contain)),
              ),
              if (hasImage)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _removeButton(() => setState(() {
                        logoFile = null;
                        logoUrl = '';
                      })),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upload Store Logo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Square image recommended for best results.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 10),
                _chooseButton('Choose Image', () => _pick(true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerCard() {
    final hasImage = bannerFile != null || bannerUrl.isNotEmpty;
    return _card(
      'Store Banner',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: AspectRatio(aspectRatio: 3, child: _image(bannerFile, bannerUrl)),
                ),
              ),
              if (hasImage)
                Positioned(
                  top: 6,
                  right: 6,
                  child: _removeButton(() => setState(() {
                        bannerFile = null;
                        bannerUrl = '';
                      })),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _chooseButton('Upload Banner', () => _pick(false)),
          const SizedBox(height: 6),
          Text('Recommended size: 1200×400 px', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}
