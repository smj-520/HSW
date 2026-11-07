import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../theme/app_colors.dart';

class HostelWalletGlyph extends StatelessWidget {
  const HostelWalletGlyph({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size;
    return SizedBox(
      width: s * 1.15,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: _CoinPile(scale: s * 0.22),
          ),
          Positioned(
            right: 0,
            top: s * 0.08,
            child: Container(
              width: s * 0.85,
              height: s * 0.62,
              decoration: BoxDecoration(
                color: AppColors.walletBody,
                borderRadius: BorderRadius.circular(s * 0.12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -s * 0.14,
                    left: s * 0.12,
                    child: Row(
                      children: [
                        _BillStub(width: s * 0.14, height: s * 0.32),
                        SizedBox(width: s * 0.03),
                        _BillStub(width: s * 0.14, height: s * 0.28),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillStub extends StatelessWidget {
  const _BillStub({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.billGreen,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
    );
  }
}

class _CoinPile extends StatelessWidget {
  const _CoinPile({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: scale * 3.2,
      height: scale * 3,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _coin(0, scale * 0.9),
          _coin(scale * 0.35, scale * 0.95),
          _coin(scale * 0.7, scale),
        ],
      ),
    );
  }

  Widget _coin(double left, double d) {
    return Positioned(
      left: left,
      bottom: 0,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.coinGold, AppColors.coinGoldDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class HostelBrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HostelBrandAppBar({
    super.key,
    this.showBack = true,
    this.onBack,
  });

  final bool showBack;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HostelWalletGlyph(size: 26),
            const SizedBox(width: 8),
            Text(
              AppI18n.t(
                context,
                en: 'Hostel Student Wallet',
                ar: 'محفظة الطالب السكنية',
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
      centerTitle: true,
    );
  }
}
