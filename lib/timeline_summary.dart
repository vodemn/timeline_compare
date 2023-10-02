import 'dart:convert';

class TimelineSummary {
  final String label;
  final FrameStats buildTime;
  final FrameStats rasterizerTime;

  const TimelineSummary({
    required this.label,
    required this.buildTime,
    required this.rasterizerTime,
  });

  factory TimelineSummary.fromFileContent(String label, DateTime timestamp, String fileContents) {
    final map = json.decode(fileContents) as Map<String, dynamic>;
    return TimelineSummary(
      label: label,
      buildTime: FrameStats.fromJson(FrameStatType.build, map),
      rasterizerTime: FrameStats.fromJson(FrameStatType.rasterizer, map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "label": label,
      "buildTime": buildTime.toJson(),
      "rasterizerTime": rasterizerTime.toJson(),
    };
  }
}

class FrameStats {
  final double averageFrameTimeMs;
  final double percentile90FrameTimeMs;
  final double percentile99FrameTimeMs;
  final double worstFrameTimeMs;

  const FrameStats({
    required this.averageFrameTimeMs,
    required this.percentile90FrameTimeMs,
    required this.percentile99FrameTimeMs,
    required this.worstFrameTimeMs,
  });

  factory FrameStats.fromJson(FrameStatType type, Map<String, dynamic> data) {
    return FrameStats(
      averageFrameTimeMs: data["average_frame_${type.name}_time_millis"],
      percentile90FrameTimeMs: data["90th_percentile_frame_${type.name}_time_millis"],
      percentile99FrameTimeMs: data["90th_percentile_frame_${type.name}_time_millis"],
      worstFrameTimeMs: data["worst_frame_${type.name}_time_millis"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "averageFrameTimeMs": averageFrameTimeMs,
      "percentile90FrameTimeMs": percentile90FrameTimeMs,
      "percentile99FrameTimeMs": percentile99FrameTimeMs,
      "worstFrameTimeMs": worstFrameTimeMs,
    };
  }
}

enum FrameStatType { build, rasterizer }
