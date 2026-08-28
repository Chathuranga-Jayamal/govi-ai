/// Result of a POST /disease/predict call.
class PredictionResult {
  const PredictionResult({
    required this.status,
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.message,
    required this.heatmapUrl,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      status: json['status'] as String,
      crop: json['crop'] as String?,
      disease: json['disease'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      message: json['message'] as String?,
      heatmapUrl: json['heatmap_url'] as String?,
    );
  }

  /// "ok" | "low_confidence" | "not_a_leaf"
  final String status;
  final String? crop;
  final String? disease;
  final double confidence;
  final String? message;
  final String? heatmapUrl;

  bool get isOk => status == 'ok';
  bool get isLowConfidence => status == 'low_confidence';
  bool get isNotALeaf => status == 'not_a_leaf';
}
