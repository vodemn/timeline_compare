import 'dart:convert';

class TimelineStats {
  final String label;
  final int timeExtentMicros;

  const TimelineStats({
    required this.label,
    required this.timeExtentMicros,
  });

  factory TimelineStats.fromFileContent(String label, DateTime timestamp, String fileContents) {
    final map = json.decode(fileContents) as Map<String, dynamic>;
    return TimelineStats(
      label: label,
      timeExtentMicros: map["timeExtentMicros"],
    );
  }

  Map<String, dynamic> toJson() {
    return {"timeExtentMicros": timeExtentMicros};
  }
}
