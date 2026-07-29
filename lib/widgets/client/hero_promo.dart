import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:catrans_app/models/catalog/catalog_promotion.dart';

class HeroPromo extends StatefulWidget {
  final List<CatalogPromotion> promotions;
  final bool isLoading;
  final String? error;

  const HeroPromo({
    super.key,
    required this.promotions,
    this.isLoading = false,
    this.error,
  });

  @override
  State<HeroPromo> createState() => _HeroPromoState();
}

class _HeroPromoState extends State<HeroPromo> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HeroPromo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.promotions.length) {
      _currentPage = 0;
    }
  }

  void _autoScroll() {
    if (!mounted) return;
    if (widget.promotions.length > 1 && _pageController.hasClients) {
      _pageController.animateToPage(
        (_currentPage + 1) % widget.promotions.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _PromoFrame(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.error != null) {
      return _PromoFrame(
        child: Center(
          child: Text(
            widget.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF5D6475)),
          ),
        ),
      );
    }

    if (widget.promotions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: widget.promotions.map(_buildPromotion).toList(),
          ),
          if (widget.promotions.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: widget.promotions.length,
                  effect: WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: Colors.white,
                    dotColor: Colors.white.withOpacity(0.45),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPromotion(CatalogPromotion promotion) {
    final imageUrl = promotion.imageUrl;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0F056B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Container(color: Colors.black.withOpacity(0.36)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  promotion.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (promotion.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    promotion.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoFrame extends StatelessWidget {
  final Widget child;

  const _PromoFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E5EF)),
      ),
      child: child,
    );
  }
}
