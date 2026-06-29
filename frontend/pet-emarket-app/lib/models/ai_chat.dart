class AiChatAnswer {
  const AiChatAnswer({
    required this.answer,
    required this.knowledgeTags,
    required this.recommendedActions,
    required this.healthWarning,
  });

  final String answer;
  final List<String> knowledgeTags;
  final List<String> recommendedActions;
  final bool healthWarning;

  factory AiChatAnswer.fromJson(Map<String, dynamic> json) {
    return AiChatAnswer(
      answer: json['answer']?.toString() ?? '',
      knowledgeTags: (json['knowledgeTags'] is List) ? (json['knowledgeTags'] as List).map((item) => item.toString()).toList() : const [],
      recommendedActions: (json['recommendedActions'] is List) ? (json['recommendedActions'] as List).map((item) => item.toString()).toList() : const [],
      healthWarning: json['healthWarning'] == true,
    );
  }
}
