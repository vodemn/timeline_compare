import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:timeline_compare/timeline_summary.dart';

Future<int> main(List<String> args) async {
  final parser = ArgParser();
  parser.addFlag('help', abbr: 'h', help: 'Show help.', defaultsTo: false);
  parser.addFlag('verbose', abbr: 'v', help: 'Verbose output.', defaultsTo: false);
  parser.addFlag('delete-sources', abbr: 'D', help: 'Delete source files.', defaultsTo: false);
  var argResults = parser.parse(args);

  if (argResults['verbose']) {
    Logger.root.level = Level.ALL;
  } else {
    Logger.root.level = Level.INFO;
  }

  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
  });

  if (argResults['help'] || argResults.rest.length < 2) {
    print('Merges two or more timeline summaries files.\n'
        '\n'
        'Usage:\n'
        '\tmerge_timeline_summaries run_1.timeline_summary.json run_2.timeline_summary.json\n'
        '\n');
    print(parser.usage);
    return 2;
  }

  final List<TimelineSummary> summaries = [];
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
      if (argResults['delete-sources']) {
        file.deleteSync();
        log.info('Deleted $file');
      }
    } on FileSystemException catch (e) {
      stderr.writeln('ERROR: Could not read $filename');
      stderr.writeln('$e');
      return 1;
    }

    log.fine('Starting extraction');
    try {
      summaries.add(TimelineSummary.fromFileContent(label, lastModified, data));
    } on FormatException catch (e) {
      stderr.writeln('ERROR: Problem parsing $filename');
      stderr.writeln('$e');
      return 1;
    }
    log.finer('Finished extraction');
  }

  final mergedSummaryName = "${summaries.first.label}_summary_merged";
  final mergedSummary = TimelineSummary(
    label: mergedSummaryName,
    buildTime: summaries.map((e) => e.buildTime).toList().mean(),
    rasterizerTime: summaries.map((e) => e.rasterizerTime).toList().mean(),
  );

  final mergedSummaryFile = path.setExtension(mergedSummaryName, '.json');
  try {
    final file = File(mergedSummaryFile);
    log.fine('Writing to $mergedSummaryFile');
    await file.writeAsString(json.encode(mergedSummary.toJson()));
    log.fine('Finished writing');
  } on FileSystemException catch (e) {
    stderr.writeln('ERROR: Could not write $mergedSummaryName');
    stderr.writeln('$e');
    return 1;
  }

  log.info('File ${path.basename(mergedSummaryFile)} written.');

  return 0;
}

Logger log = Logger('merge_timeline_summaries');
