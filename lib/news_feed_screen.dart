import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'article_details_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'config.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  NewsFeedScreenState createState() => NewsFeedScreenState();
}

class NewsFeedScreenState extends State<NewsFeedScreen> {
  List<dynamic> newsArticles = [];
  List<dynamic> filteredArticles = [];
  bool isLoading = true;
  String errorMessage = "";
  String selectedCategory = "Hemmesi";

  final List<String> categories = ["Hemmesi", "World", "Tech", "Sports", "Business", "Entertainment"];

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  Future<void> fetchNewsArticles() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final articleBox = await Hive.openBox('articles');

      if (articleBox.isNotEmpty) {
        final cachedArticles = articleBox.get('cachedArticles');
        setState(() {
          newsArticles = List<dynamic>.from(cachedArticles);
          filteredArticles = newsArticles;
          isLoading = false;
        });
      }

      final response = await http
          .get(Uri.parse('https://www.dowur-news.shop/api/news/all'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedResponse);
        setState(() {
          newsArticles = jsonResponse;
          filteredArticles = jsonResponse;
        });

        await articleBox.put('cachedArticles', jsonResponse);
      } else {
        setState(() {
          errorMessage =
          "Error: Failed to fetch articles. HTTP Code ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: Unable to fetch news. ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterArticles(String category) {
    setState(() {
      selectedCategory = category;
      if (category == "Hemmesi") {
        filteredArticles = newsArticles;
      } else {
        filteredArticles = newsArticles
            .where((article) => article['categoryName'] == category)
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Initialize Banner Ad
    _bannerAd = BannerAd(
      adUnitId:  Config.bannerAdUnitId, // Test Ad Unit ID
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
    fetchNewsArticles();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBannerAdReady) {
      print('Banner ad not ready');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Döwür News',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF151172),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Category Selector
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;

                    return GestureDetector(
                      onTap: () => filterArticles(category),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // News Articles
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage.isNotEmpty
                    ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) {
                    final article = filteredArticles[index];
                    final title = article['title'] ?? 'No Title Available';
                    final content = article['content'] ?? 'No Content Available';
                    final imageUrl = article['imageUrl'];
                    final publishedAt = article['publishedAt'] ?? 'Unknown Date';

                    DateTime parsedDate = DateTime.parse(publishedAt);
                    String timeAgo = timeago.format(parsedDate);

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ArticleDetailsScreen(article: article),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                content.length > 100
                                    ? '${content.substring(0, 100)}...'
                                    : content,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 10),
                              if (imageUrl != null)
                                Container(
                                  width: double.infinity,
                                  child: Image.network(
                                    imageUrl,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              const SizedBox(height: 5),
                              Text(
                                'Published: $timeAgo',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Banner Ad
          if (_isBannerAdReady)
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: _bannerAd.size.height.toDouble(),
                width: _bannerAd.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd),
              ),
            ),
        ],
      ),
    );
  }
}
