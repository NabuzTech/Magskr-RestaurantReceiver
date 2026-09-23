import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../api/repository/api_repository.dart';
import '../../../models/admin/add_store_config_model.dart';
import '../../../models/admin/store_config_model.dart';

class AddEditStoreConfig extends StatefulWidget {
  final GetStoreConfigModel? existing;

  const AddEditStoreConfig({super.key, this.existing});

  @override
  State<AddEditStoreConfig> createState() => _AddEditStoreConfigState();
}

class _AddEditStoreConfigState extends State<AddEditStoreConfig> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController domainCtrl;
  late final TextEditingController subdomainCtrl;
  late final TextEditingController storeIdCtrl;
  late final TextEditingController appNameCtrl;
  late final TextEditingController baseRouteCtrl;
  late final TextEditingController copyrightCtrl;
  String language = 'en';
  List<Footer> footerLinks = [];
  bool isSaving = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    domainCtrl = TextEditingController(text: e?.domain ?? '');
    subdomainCtrl = TextEditingController(text: e?.subdomain ?? '');
    storeIdCtrl = TextEditingController(text: e?.storeId?.toString() ?? '');
    appNameCtrl = TextEditingController(text: e?.appName ?? '');
    baseRouteCtrl = TextEditingController(text: e?.appBaseRoute ?? '');
    copyrightCtrl = TextEditingController(text: e?.copyrightText ?? '');
    language = e?.language ?? 'en';
  }

  @override
  void dispose() {
    domainCtrl.dispose();
    subdomainCtrl.dispose();
    storeIdCtrl.dispose();
    appNameCtrl.dispose();
    baseRouteCtrl.dispose();
    copyrightCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json', width: 120, height: 120)),
      barrierDismissible: false,
    );
    try {
      final body = {
        'domain': domainCtrl.text.trim(),
        'subdomain': subdomainCtrl.text.trim().isEmpty ? null : subdomainCtrl.text.trim(),
        'store_id': int.parse(storeIdCtrl.text.trim()),
        'app_name': appNameCtrl.text.trim(),
        'app_base_route': baseRouteCtrl.text.trim(),
        'copyright_text': copyrightCtrl.text.trim(),
        'language': language,
        'footer': footerLinks.map((f) => f.toJson()).toList(),
      };

      if (isEdit) {
        await CallService().updateStoreConfig(body, widget.existing!.domain ?? domainCtrl.text.trim());
      } else {
        await CallService().addStoreConfig(body);
      }

      if (Get.isDialogOpen ?? false) Get.back();
      Get.back(result: true);
      Get.snackbar('Success', isEdit ? 'Config updated' : 'Config created',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Failed to save config: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 14),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontFamily: 'Mulish', fontSize: 13),
            children: required ? const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : null,
          ),
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Mulish', fontSize: 12))),
            Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w600, fontSize: 12))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final e = widget.existing;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(isEdit ? 'Edit Store Config' : 'Add Store Config',
            style: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('Domain', required: true),
            TextFormField(
              controller: domainCtrl,
              decoration: _decoration('e.g. rapidopizza.de'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Domain is required' : null,
            ),
            if (isEdit)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Enter the domain used to identify this config in the update request.',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Mulish'),
                ),
              ),

            _label('Subdomain'),
            TextFormField(controller: subdomainCtrl, decoration: _decoration('e.g. shop.rapidopizza.de')),

            _label('Store ID', required: true),
            TextFormField(
              controller: storeIdCtrl,
              keyboardType: TextInputType.number,
              decoration: _decoration('e.g. 13'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Store ID is required';
                if (int.tryParse(v.trim()) == null) return 'Store ID must be a number';
                return null;
              },
            ),

            _label('App Name', required: true),
            TextFormField(
              controller: appNameCtrl,
              decoration: _decoration('e.g. Bombay Online Store'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'App Name is required' : null,
            ),

            _label('App Base Route'),
            TextFormField(controller: baseRouteCtrl, decoration: _decoration('e.g. order-online')),

            _label('Copyright Text', required: true),
            TextFormField(
              controller: copyrightCtrl,
              decoration: _decoration('e.g. © 2024 Bombay Online'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Copyright Text is required' : null,
            ),

            _label('Select Default Language', required: true),
            DropdownButtonFormField<String>(
              initialValue: language,
              decoration: _decoration(''),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English (en)')),
                DropdownMenuItem(value: 'de', child: Text('German (de)')),
              ],
              onChanged: (v) => setState(() => language = v ?? 'en'),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Footer Links', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Mulish', fontSize: 14)),
                  TextButton.icon(
                    onPressed: () => setState(() => footerLinks.add(Footer(label: '', link: ''))),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Link'),
                  ),
                ],
              ),
            ),
            if (footerLinks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No footer links yet.', style: TextStyle(color: Colors.grey, fontFamily: 'Mulish')),
              ),
            ...footerLinks.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              return Container(
                key: ValueKey(f),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: f.label,
                            decoration: _decoration('Label'),
                            onChanged: (v) => f.label = v,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => setState(() => footerLinks.removeAt(i)),
                        ),
                      ],
                    ),
                    TextFormField(
                      initialValue: f.link,
                      decoration: _decoration('Link URL'),
                      onChanged: (v) => f.link = v,
                    ),
                  ],
                ),
              );
            }),

            if (isEdit) ...[
              const SizedBox(height: 24),
              const Text('Current Store Info', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Mulish', fontSize: 14)),
              const Divider(),
              _infoRow('Country', e?.country ?? '-'),
              _infoRow('Distance Delivery', (e?.useDistanceDelivery ?? false) ? 'Enabled' : 'Disabled'),
              _infoRow('PayPal Client ID', e?.paypalLiveClientId ?? 'Not set'),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEdit ? 'Update Config' : 'Create Config',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Mulish', fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
