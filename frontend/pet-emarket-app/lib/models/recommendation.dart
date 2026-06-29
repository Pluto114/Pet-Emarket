import 'product.dart';

class RecommendationItem {
  const RecommendationItem({
    required this.product,
    required this.score,
    required this.strategy,
    required this.reasons,
    required this.itemCfScore,
    required this.markovScore,
    required this.hotScore,
    required this.distanceScore,
    required this.stockScore,
  });

  final Product product;
  final double score;
  final String strategy;
  final List<String> reasons;
  final double itemCfScore;
  final double markovScore;
  final double hotScore;
  final double distanceScore;
  final double stockScore;

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
      score: NumberParser.toDouble(json['score']),
      strategy: json['strategy']?.toString() ?? '',
      reasons: (json['reasons'] is List) ? (json['reasons'] as List).map((item) => item.toString()).toList() : const [],
      itemCfScore: NumberParser.toDouble(json['itemCfScore']),
      markovScore: NumberParser.toDouble(json['markovScore']),
      hotScore: NumberParser.toDouble(json['hotScore']),
      distanceScore: NumberParser.toDouble(json['distanceScore']),
      stockScore: NumberParser.toDouble(json['stockScore']),
    );
  }
}
