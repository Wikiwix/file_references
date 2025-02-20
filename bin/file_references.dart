import 'dart:io';

import 'package:path/path.dart' as p;

/// "Config"
const String path = '.';
hasReference(File file) =>
    (File referenceCandidate) => file.readAsStringSync().contains(
      RegExp(
        r'''[\n/'" ]''' + RegExp.escape(p.basename(referenceCandidate.path)),
      ),
    );

/// Config end

void main(List<String> arguments) {
  final directory = Directory(path);
  final files = directory.listSync(recursive: true).whereType<File>();
  final edges = files
      .map((file) {
        final fileHasReferenceTo = hasReference(file);
        return files
            .map(
              (otherFile) =>
                  fileHasReferenceTo(otherFile) ? (file, otherFile) : null,
            )
            .whereType<(File, File)>();
      })
      .expand((i) => i);
  final dotFile = '''
digraph FileReferences {
  # Left to right will help with the long labels
  rankdir="LR";
  # nodes
${files.map((file) => file.path.asDotId).join('\n').indented(2)}

  # edges
${edges.map(formatDotEdge).join('\n').indented(2)}
}
''';
  print(dotFile);
}

String formatDotEdge((File, File) edge) =>
    '${edge.$1.path.asDotId} -> ${edge.$2.path.asDotId}';

extension StringStuff on String {
  /// Make a string a valid DOT file [ID](https://graphviz.org/doc/info/lang.html#ids)
  String get asDotId => '"${replaceAll('"', '\\"')}"';

  String indented(final int indentation) =>
      split('\n').map((line) => repeatString(indentation) + line).join('\n');
}

String repeatString(int indentation, [String toRepeat = ' ']) =>
    Iterable.generate(indentation, (_) => toRepeat).join();
