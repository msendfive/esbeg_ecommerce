import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/brands_model.dart';
import '../screens/brands_screen.dart';
import '../utilities/constants.dart';

// ---------------------------------------------------------------------------
// FooterWidget — global footer used at the bottom of every scrollable screen.
// Replaces: widgets/global_footer.dart  →  widgets/footer_widget.dart
// ---------------------------------------------------------------------------

class FooterWidget extends StatefulWidget {
  const FooterWidget({super.key});

  @override
  State<FooterWidget> createState() => _FooterWidgetState();
}

class _FooterWidgetState extends State<FooterWidget> {
  // ─── STATE ─────────────────────────────────────────────────────────────────

  List<Brand> _brands = [];
  bool _isLoading = true;

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  // ─── DATA ──────────────────────────────────────────────────────────────────

  Future<void> _fetchBrands() async {
    try {
      final response = await http.get(Uri.parse(kBrandEndpoint));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        if (mounted) {
          setState(() {
            _brands = data.map((e) => Brand.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Footer Brand Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurfaceColor,
      padding: const EdgeInsets.symmetric(
        vertical: kSpaceXL,
        horizontal: kSpaceXL,
      ),
      child: Column(
        children: [
          // ── Brand logos ─────────────────────────────────────────────────
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_brands.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: kSpace3XL,
              runSpacing: kSpaceXL,
              children: _brands.take(4).map((brand) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BrandsScreen(brandName: brand.name),
                    ),
                  ),
                  child: _BrandLogo(url: getBrandLogoUrl(brand.imageLogo)),
                );
              }).toList(),
            ),

          const SizedBox(height: kSpace3XL),

          // ── Footer links ────────────────────────────────────────────────
          const Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FooterLink('Term of Use'),
              _FooterSeparator(),
              _FooterLink('Return Policy'),
              _FooterSeparator(),
              _FooterLink('Size Guide'),
              _FooterSeparator(),
              _FooterLink('Contact'),
            ],
          ),

          const SizedBox(height: kSpaceXL),

          // ── Social icons ────────────────────────────────────────────────
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialBox(Icons.camera_alt_outlined),
              SizedBox(width: 18),
              _SocialBox(Icons.play_circle_outline),
              SizedBox(width: 18),
              _SocialBox(Icons.facebook_outlined),
            ],
          ),

          const SizedBox(height: kSpaceXL),

          // ── Payment method ──────────────────────────────────────────────
          const _PaymentBox(),

          const SizedBox(height: kSpaceXL),

          // ── Copyright ───────────────────────────────────────────────────
          Text(
            '© 2026 ESBEG Developer. All rights reserved.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: kPrimaryColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.85,
      child: Image.network(
        url,
        height: 30,
        color: kPrimaryColor,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (_, _, _) => const Icon(
          Icons.broken_image_outlined,
          color: kBorderColor,
          size: 30,
        ),
      ),
    );
  }
}

// ─── Social icon box ────────────────────────────────────────────────────────

class _SocialBox extends StatelessWidget {
  const _SocialBox(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kRadiusMD),
        border: Border.all(color: kBorderColor),
      ),
      child: Icon(icon, size: 22, color: kPrimaryColor),
    );
  }
}

// ─── Payment box ────────────────────────────────────────────────────────────

class _PaymentBox extends StatelessWidget {
  const _PaymentBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpace2XL,
        vertical: kSpaceMD,
      ),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kRadiusXL + 10),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance, color: kPrimaryColor, size: 22),
          const SizedBox(width: 10),
          Text(
            'Virtual Account',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: kTextPrimaryColor),
          ),
        ],
      ),
    );
  }
}

// ─── Footer link ────────────────────────────────────────────────────────────

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: kTextPrimaryColor),
      ),
    );
  }
}

// ─── Footer separator ───────────────────────────────────────────────────────

class _FooterSeparator extends StatelessWidget {
  const _FooterSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: kSpaceSM),
      child: Text('|', style: TextStyle(color: kTextSecondaryColor)),
    );
  }
}
