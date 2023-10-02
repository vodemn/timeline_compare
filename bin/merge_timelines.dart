import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:t_stats/t_stats.dart';
import 'package:timeline_compare/timeline.dart';

Future<int> main(
    {List<String> args = const [
      "/Users/vodemn/Documents/GitHub/m3_lightmeter/build/toggle_iso_picker_baseline_2023-10-02T13-33-18.946216.timeline.json",
      "/Users/vodemn/Documents/GitHub/m3_lightmeter/build/toggle_iso_picker_baseline_2023-10-02T13-33-33.662261.timeline.json"
    ]}) async {
  final parser = ArgParser();
  parser.addFlag('help', abbr: 'h', help: 'Show help.', defaultsTo: false);
  parser.addFlag('verbose', abbr: 'v', help: 'Verbose output', defaultsTo: false);
  var argResults = parser.parse(args);

  if (argResults['verbose']) {
    Logger.root.level = Level.ALL;
  } else {
    Logger.root.level = Level.INFO;
  }

  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
  });

  if (argResults['help'] || argResults.rest.length != 2) {
    print('Merges two or more timelines files.\n'
        '\n'
        'Usage:\n'
        '\tmerge_timelines run_1.timeline.json run_2.timeline.json\n'
        '\n');
    print(parser.usage);
    return 2;
  }

  final List<TimelineStats> timelines = [];
  for (final filename in argResults.rest) {
    log.info('Extracting $filename');
    final label = path.basenameWithoutExtension(filename);

    String data;
    DateTime lastModified;
    try {
      final file = File(filename);
      data = await file.readAsString();
      log.fine('Finished reading $file');
      lastModified = (await file.lastModified()).toUtc();
      log.finer('Finished getting last modified: $lastModified');
    } on FileSystemException catch (e) {
      stderr.writeln('ERROR: Could not read $filename');
      stderr.writeln('$e');
      return 1;
    }

    log.fine('Starting extraction');
    try {
      timelines.add(TimelineStats.fromFileContent(label, lastModified, data));
    } on FormatException catch (e) {
      stderr.writeln('ERROR: Problem parsing $filename');
      stderr.writeln('$e');
      return 1;
    }
    log.finer('Finished extraction');
  }

  final mergedTimelineName = "${timelines.first.label.split('.').first}_merged";
  final mergedTimeline = TimelineStats(
    label: mergedTimelineName,
    timeExtentMicros: Statistic.from(timelines.map((e) => e.timeExtentMicros)).mean.toInt(),
  );

  final mergedTimelineFile = path.setExtension(mergedTimelineName, '.json');
  try {
    final file = File(mergedTimelineFile);
    log.fine('Writing to $mergedTimelineFile');
    await file.writeAsString(json.encode(mergedTimeline.toJson()));
    log.fine('Finished writing');
  } on FileSystemException catch (e) {
    stderr.writeln('ERROR: Could not write $mergedTimelineName');
    stderr.writeln('$e');
    return 1;
  }

  log.info('File ${path.basename(mergedTimelineFile)} written.');

  return 0;
}

Logger log = Logger('merge_timelines');
