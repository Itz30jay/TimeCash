/// About the Developer & optional donation screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flowra/utils/constants.dart';
import 'package:flowra/utils/theme.dart';
import 'package:flowra/widgets/common_widgets.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  int? _selectedAmount;
  final _customController = TextEditingController();
  bool _showThankYou = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int get _amount {
    if (_selectedAmount != null) return _selectedAmount!;
    return int.tryParse(_customController.text.trim()) ?? 0;
  }

  Future<void> _launchUrlHelper(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  void _copyUpiId() {
    Clipboard.setData(const ClipboardData(text: AppConstants.donationUpiId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI ID copied to clipboard: ${AppConstants.donationUpiId}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _donate() async {
    final amount = _amount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter an amount')),
      );
      return;
    }

    if (!AppConstants.isDonationEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Donation is currently not available.')),
      );
      return;
    }

    // Build UPI link with properly encoded parameters
    final upiUrl = Uri.parse(
      'upi://pay?pa=${Uri.encodeComponent(AppConstants.donationUpiId)}'
      '&pn=${Uri.encodeComponent(AppConstants.donationUpiName)}'
      '&am=$amount'
      '&cu=INR'
      '&tn=${Uri.encodeComponent("Flowra Donation")}',
    );

    try {
      if (await canLaunchUrl(upiUrl)) {
        await launchUrl(upiUrl, mode: LaunchMode.externalApplication);
        setState(() => _showThankYou = true);
        return;
      }

      // Fallback try launchUrl directly in case query permissions differ
      try {
        final launched = await launchUrl(upiUrl, mode: LaunchMode.externalApplication);
        if (launched) {
          setState(() => _showThankYou = true);
          return;
        }
      } catch (_) {}

      if (AppConstants.donationPaymentLink.isNotEmpty) {
        // Fallback to web payment link
        await launchUrl(
          Uri.parse(AppConstants.donationPaymentLink),
          mode: LaunchMode.externalApplication,
        );
        setState(() => _showThankYou = true);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No UPI app found. You can copy the UPI ID below to pay directly.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No UPI app found. You can copy the UPI ID below to pay directly.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('About the Developer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─── 1. Developer Intro Block ─────────────────────────
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primaryIndigo.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryIndigo.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 52,
                  color: AppTheme.primaryIndigo,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.developerName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Independent Developer & Creator of Flowra\nBuilding offline-first productivity tools.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ─── 2. Social Link Buttons ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.code_rounded, size: 20),
                    label: const Text('GitHub', overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => _launchUrlHelper(AppConstants.githubProfileUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_rounded, size: 20),
                    label: const Text('Instagram', overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE1306C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _launchUrlHelper(AppConstants.instagramUrl),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ─── 3. Existing Donation UI ──────────────────────────
            Divider(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              thickness: 1,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.pink, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Support Flowra',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Flowra is free and 100% offline. If it helps you manage your time or money, consider supporting its development with an optional donation.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Preset amounts
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: AppConstants.donationPresets.map((amount) {
                final isSelected = _selectedAmount == amount;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAmount = isSelected ? null : amount;
                      _customController.clear();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 76,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryIndigo
                          : AppTheme.primaryIndigo.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryIndigo
                            : AppTheme.primaryIndigo.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '₹$amount',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.primaryIndigo,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom amount
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Custom amount',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.edit_rounded),
              ),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
              onChanged: (_) =>
                  setState(() => _selectedAmount = null),
            ),
            const SizedBox(height: 20),

            // Donate button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onLongPress: _copyUpiId,
                child: PrimaryButton(
                  label: _amount > 0
                      ? 'Donate ₹$_amount'
                      : 'Select an Amount',
                  icon: Icons.favorite_rounded,
                  color: Colors.pink,
                  onPressed: _amount > 0 ? _donate : null,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Copy UPI ID button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _copyUpiId,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(
                  'Copy UPI ID: ${AppConstants.donationUpiId}',
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Disclaimer
            Text(
              'You will complete the payment in your UPI/payment app. Flowra does not store card or bank details.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            // Thank you message
            if (_showThankYou) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.successGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.successGreen, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Thank you for your support! 🙏',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your donation helps keep Flowra free and ad-free.',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ─── 4. Footer ────────────────────────────────────────
            Divider(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              thickness: 1,
            ),
            const SizedBox(height: 16),
            Text(
              '© ${DateTime.now().year} ${AppConstants.developerName}. All rights reserved.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Made with ❤️ in India',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'If Flowra helps you, consider supporting its development ❤️',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
