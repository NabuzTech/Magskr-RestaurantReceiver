import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) {
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
          Icon(Icons.shield_outlined, size: 18, color: r.accent),
          const SizedBox(width: 6),
          Text('${r.labelKey.tr} • ${'risk_score'.tr} ${r.score ?? 0}',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: r.accent)),
          const Spacer(),
          if (loc != null) ...[
            const Icon(Icons.location_on_outlined, size: 16),
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
  const _DbIpCredit();
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => launchUrl(Uri.parse('https://db-ip.com'),
            mode: LaunchMode.externalApplication),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.info_outline, size: 13, color: Colors.black54),
          SizedBox(width: 4),
          Text('IP geolocation by DB-IP • ', style: TextStyle(fontSize: 11)),
          Text('db-ip.com',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue,
                  decoration: TextDecoration.underline)),
          SizedBox(width: 3),
          Icon(Icons.open_in_new, size: 12, color: Colors.blue),
        ]),
      );
}

/// "Risk Assessment" card for detail screens (place last).
class RiskCard extends StatelessWidget {
  final Risk? risk;
  final VoidCallback? onChanged;
  const RiskCard({super.key, required this.risk, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final r = risk;
    if (r == null) return const SizedBox.shrink();
    Widget col(String t, String v) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 2),
            Text(v,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        );
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: r.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: r.accent.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.shield_outlined, color: r.accent),
          const SizedBox(width: 6),
          Text('risk_assessment'.tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: r.accent, borderRadius: BorderRadius.circular(12)),
            child: Text(r.labelKey.tr,
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          col('risk_score'.tr, '${r.score ?? 0} / 100'),
          col('risk_alert_status'.tr, r.alertStatus ?? '—'),
          col('risk_location'.tr, r.location ?? '—'),
        ]),
        if (r.ipAddress != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Text('IP', style: TextStyle(fontSize: 12)),
            const Spacer(),
            Text(r.ipAddress!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ],
        ...r.reasons.map((e) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('• ${e.detail ?? e.rule ?? ''}',
                style: const TextStyle(fontSize: 12)))),
        if (r.location != null) ...[
          const SizedBox(height: 10),
          const _DbIpCredit(),
        ],
        if (r.alertId != null) ...[
          const Divider(),
          Wrap(spacing: 8, children: [
            for (final s in const ['confirmed', 'dismissed', 'open'])
              OutlinedButton(
                onPressed: r.alertStatus == s
                    ? null
                    : () async {
                        final ok = await CallService().patchFraudAlert(r.alertId!, s);
                        Get.snackbar('', ok ? 'risk_$s'.tr : 'error'.tr);
                        if (ok) onChanged?.call();
                      },
                child: Text('risk_$s'.tr),
              ),
          ]),
        ],
      ]),
    );
  }
}
