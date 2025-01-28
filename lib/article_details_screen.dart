import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'config.dart';

class ArticleDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> article;

  const ArticleDetailsScreen({super.key, required this.article});

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();

    // Initialize Banner Ad
    _bannerAd = BannerAd(
      adUnitId: Config.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Failed to load a banner ad: ${error.message}');
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final title = article['title'] ?? 'No Title Available';
    final content = article['content'] ?? 'No Content Available';
    final imageUrl = article['imageUrl'];
    final publishedAt = article['publishedAt'] ?? 'Unknown Date';
    DateTime parsedDate = DateTime.parse(publishedAt);

    String timeAgo = timeago.format(parsedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Döwür News',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF151172),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Published: $timeAgo',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  if (imageUrl != null)
                    Image.network(imageUrl, fit: BoxFit.cover)
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 20),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          // Banner Ad at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: _isBannerAdReady
                ? SizedBox(
              height: _bannerAd.size.height.toDouble(),
              width: _bannerAd.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd),
            )
                : const Text(
              'Ad not ready',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ), // Placeholder for when the ad is not ready
          ),
        ],
      ),
    );
  }

}
