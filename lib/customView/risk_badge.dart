import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/repository/api_repository.dart';
import '../models/risk_model.dart';

/// Risk strip coloured by server `level`. Tap / long-press for reasons and
/// (staff) alert review. Renders nothing when [risk] is null.
class RiskBadge extends StatefulWidget {
  final Risk? risk;
  final VoidCallback? onChanged; // called after a successful alert review
  const RiskBadge({super.key, required this.risk, this.onChanged});

  @override
  State<RiskBadge> createState() => _RiskBadgeState();
}

class _RiskBadgeState extends State<RiskBadge> {
  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
      style: const TextStyle(fontFamily: 'Sora'), child: _build(context));

  Widget _build(BuildContext context) {
    final r = widget.risk;
    if (r == null) return const SizedBox.shrink();
    final loc = r.location;
    return GestureDetector(
      onTap: () => _openSheet(r),
      onLongPress: () => _openSheet(r),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(6, 8, 6, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: r.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: r.accent.withOpacity(0.25)),
        ),
        child: Row(children: [
          _svg('security', r.accent, 18),
          const SizedBox(width: 6),
          Text('${r.labelKey.tr} • ${'risk_score'.tr} ${r.score ?? 0}',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,fontFamily: 'Sora' ,color: r.accent)),
          const Spacer(),
          if (loc != null) ...[
            _svg('risk_location', Colors.black87, 16),
            const SizedBox(width: 2),
            Flexible(
                child: Text(loc,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12))),
          ],
        ]),
      ),
    );
  }

  void _openSheet(Risk r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            RiskCard(risk: r, onChanged: () {
              Navigator.pop(ctx);
              widget.onChanged?.call();
            }),
          ]),
        ),
      ),
    );
  }
}

class _DbIpCredit extends StatelessWidget {
  final String? ip;
  const _DbIpCredit({this.ip});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        const _InfoDot(),
        const SizedBox(width: 4),
        GestureDetector(
          // iplocation.net reads ?query= and prefills the lookup field.
          onTap: () => launchUrl(
              Uri.https('www.iplocation.net', '/ip-lookup',
                  {if (ip != null && ip!.isNotEmpty) 'query': ip!}),
              mode: LaunchMode.externalApplication),
          child: const Text('iplocation.net',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue,
                  decoration: TextDecoration.underline)),
        ),
      ]);
}

Widget _svg(String name, Color c, [double size = 20]) => SvgPicture.asset(
      'assets/images/$name.svg',
      width: size,
      height: size,
      // security.svg is a full-colour illustration: don't tint it.
      colorFilter: name == 'security' ? null : ColorFilter.mode(c, BlendMode.srcIn),
    );

/// Flag emoji from ISO country code ("DE" -> flag). Empty when unknown.
String _flag(String? cc) {
  if (cc == null || cc.length != 2) return '';
  return String.fromCharCodes(
      cc.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 65));
}

/// "IP security" card for detail screens (place last).
class RiskCard extends StatelessWidget {
  final Risk? risk;
  final VoidCallback? onChanged;
  const RiskCard({super.key, required this.risk, this.onChanged});

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
      style: const TextStyle(fontFamily: 'Sora'), child: _build(context));

  Widget _build(BuildContext context) {
    final r = risk;
    if (r == null) return const SizedBox.shrink();
    final a = r.accent;
    final flag = _flag(r.countryCode);

    Widget row(String icon, String label, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(children: [
            _svg(icon, Colors.black87, 20),
            const SizedBox(width: 12),
            Expanded(
                flex: 4,
                child: Text(label, style: const TextStyle(fontSize: 13))),
            Expanded(flex: 6, child: value),
          ]),
        );
    const bold = TextStyle(fontSize: 13, fontWeight: FontWeight.w800);
    const divider = Divider(height: 1, color: Color(0x14000000));

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: a.withOpacity(0.45), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          color: r.color,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _svg('security', a, 34),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('risk_title'.tr,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: a))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              if (r.level == 'green')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2F6FED),
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _svg('risk_check', Colors.white, 13),
                    const SizedBox(width: 5),
                    Text('risk_verified'.tr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: a, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _svg('security', Colors.white, 14),
                  const SizedBox(width: 5),
                  Text(r.labelKey.tr,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Column(children: [
            row(
                'risk_location',
                'risk_location'.tr,
                Row(children: [
                  Expanded(
                      child: Text(r.location ?? '—',
                          style: bold, overflow: TextOverflow.ellipsis)),
                  if (flag.isNotEmpty)
                    Text(flag, style: const TextStyle(fontSize: 22)),
                ])),
            divider,
            row('risk_wifi', 'risk_ip'.tr, Text(r.ipAddress ?? '—', style: bold)),
            divider,
            row(
                'security',
                'risk_status'.tr,
                Text(
                    '${r.labelKey.tr} – ${'${r.labelKey}_desc'.tr} (${r.score ?? 0}/100)',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: a))),
            if (r.alertStatus != null) ...[
              divider,
              row('risk_info', 'risk_alert_status'.tr,
                  Text(r.alertStatus!, style: bold)),
            ],
          ]),
        ),
        if (r.reasons.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: r.reasons
                    .map((e) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('• ${e.detail ?? e.rule ?? ''}',
                            style: const TextStyle(fontSize: 12))))
                    .toList()),
          ),
        // Info box
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            _svg('risk_info', const Color(0xFF2F6FED), 22),
            const SizedBox(width: 10),
            Expanded(
                child: Text('risk_info_text'.tr,
                    style: const TextStyle(fontSize: 12))),
          ]),
        ),
        if (r.location != null)
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: _DbIpCredit(ip: r.ipAddress)),
        if (r.alertId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Wrap(spacing: 8, children: [
              for (final s in const ['confirmed', 'dismissed', 'open'])
                OutlinedButton(
                  onPressed: r.alertStatus == s
                      ? null
                      : () async {
                          final ok =
                              await CallService().patchFraudAlert(r.alertId!, s);
                          Get.snackbar('', ok ? 'risk_$s'.tr : 'error'.tr);
                          if (ok) onChanged?.call();
                        },
                  child: Text('risk_$s'.tr),
                ),
            ]),
          ),
      ]),
    );
  }
}

class _InfoDot extends StatelessWidget {
  const _InfoDot();
  @override
  Widget build(BuildContext context) => _svg('risk_info', Colors.black54, 13);
}
