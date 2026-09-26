/// Donation screen with preset amounts and external payment link.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timecash/utils/constants.dart';
import 'package:timecash/utils/theme.dart';
import 'package:timecash/widgets/common_widgets.dart';

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
            content: Text('Donation link is not available right now.')),
      );
      return;
    }

    // Build UPI link
    final upiUrl = Uri.parse(
      'upi://pay?pa=${AppConstants.donationUpiId}'
      '&pn=${Uri.encodeComponent(AppConstants.donationUpiName)}'
      '&am=$amount'
      '&cu=INR'
      '&tn=${Uri.encodeComponent("TimeCash Donation")}',
    );

    try {
      if (await canLaunchUrl(upiUrl)) {
        await launchUrl(upiUrl, mode: LaunchMode.externalApplication);
        setState(() => _showThankYou = true);
      } else if (AppConstants.donationPaymentLink.isNotEmpty) {
        // Fallback to web payment link
        await launchUrl(
          Uri.parse(AppConstants.donationPaymentLink),
          mode: LaunchMode.externalApplication,
        );
        setState(() => _showThankYou = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No UPI app found. Please install one.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open payment app: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Support the Developer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Heart icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.pink, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Support TimeCash',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'TimeCash is free and offline. If it helps you manage your time or money, you can support the developer with any amount you like. Donation is completely optional.',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

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
                    width: 80,
                    height: 56,
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
                          fontSize: 18,
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
            const SizedBox(height: 24),

            // Donate button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: _amount > 0
                    ? 'Donate ₹$_amount'
                    : 'Select an Amount',
                icon: Icons.favorite_rounded,
                color: Colors.pink,
                onPressed: _amount > 0 ? _donate : null,
              ),
            ),
            const SizedBox(height: 12),

            // Disclaimer
            Text(
              'You will complete the payment in your UPI/payment app. TimeCash does not store card or bank details.',
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
                      'Your donation helps keep TimeCash free and ad-free.',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── Footer ────────────────────────────────────
            Divider(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              thickness: 1,
            ),
            const SizedBox(height: 20),

            // Social links row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialIconButton(
                  icon: Icons.code_rounded,
                  label: 'GitHub',
                  url: AppConstants.githubProfileUrl,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                const SizedBox(width: 24),
                _SocialIconButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Instagram',
                  url: AppConstants.instagramUrl,
                  color: const Color(0xFFE1306C),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Copyright
            Text(
              '© ${DateTime.now().year} ${AppConstants.developerName}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Made with ❤️ in India',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'TimeCash is open-source and free to use.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[700] : Colors.grey[400],
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

/// A tappable social-media icon with label for the donation footer.
class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String url;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
