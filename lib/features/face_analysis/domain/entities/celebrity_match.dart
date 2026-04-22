import 'package:equatable/equatable.dart';

class CelebrityMatch extends Equatable {
  final String name;
  final double confidence; // 0-100
  final String? imageUrl;
  final CelebrityFeatures features;

  const CelebrityMatch({
    required this.name,
    required this.confidence,
    this.imageUrl,
    required this.features,
  });

  @override
  List<Object?> get props => [name, confidence, imageUrl, features];
}

class CelebrityFeatures extends Equatable {
  final int eyes;
  final int nose;
  final int mouth;

  const CelebrityFeatures({
    required this.eyes,
    required this.nose,
    required this.mouth,
  });

  @override
  List<Object?> get props => [eyes, nose, mouth];

  // Get the average score
  int get averageScore => ((eyes + nose + mouth) / 3).toInt();

  // Get top feature
  String get topFeature {
    if (eyes >= nose && eyes >= mouth) return 'eyes';
    if (nose >= mouth) return 'nose';
    return 'mouth';
  }
}
