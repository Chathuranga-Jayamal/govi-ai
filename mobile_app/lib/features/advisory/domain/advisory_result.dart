/// Result of a POST /advisory call.
class AdvisoryResult {
  const AdvisoryResult({required this.reply, required this.sources});

  factory AdvisoryResult.fromJson(Map<String, dynamic> json) => AdvisoryResult(
    reply: json['reply'] as String,
    sources: (json['sources'] as List<dynamic>)
        .map((source) => source as String)
        .toList(),
  );

  final String reply;
  final List<String> sources;
}
