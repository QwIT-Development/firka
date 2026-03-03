import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart' as yaml;

const _lockFileName = 'codegen-lock.yaml';

void main() async {
  final root = _projectRoot();
  var ran = false;

  if (_iconsOutOfDate(root)) {
    final inputs = _iconsInputs(root);
    stdout.writeln('Icons out of date, running flutter_launcher_icons...');
    await _run('dart', ['run', 'flutter_launcher_icons'], root);
    _updateLockWithHashes(root, 'icons', _computeHashes(root, inputs));
    ran = true;
  }

  if (_l10nOutOfDate(root)) {
    final inputs = _l10nInputs(root);
    stdout.writeln('l10n out of date, running flutter gen-l10n...');
    await _run('flutter', [
      'gen-l10n',
      '--template-arb-file',
      'app_hu.arb',
    ], root);
    _updateLockWithHashes(root, 'l10n', _computeHashes(root, inputs));
    ran = true;
  }

  if (_isarOutOfDate(root)) {
    final inputs = _isarInputs(root);
    final hashes = _computeHashes(root, inputs);
    stdout.writeln(
      'Isar generated dart files out of date, running build_runner...',
    );
    await _run('dart', ['run', 'build_runner', 'build'], root);
    _updateLockWithHashes(root, 'isar', hashes);
    ran = true;
  }

  if (!ran) {
    stdout.writeln('All generated files are up to date.');
  }
}

String _projectRoot() {
  final script = p.canonicalize(Platform.script.toFilePath());
  return p.canonicalize(p.dirname(p.dirname(script)));
}

String _lockPath(String root) => p.join(root, _lockFileName);

Map<String, Map<String, String>>? _readLock(String root) {
  final file = File(_lockPath(root));
  if (!file.existsSync()) return null;
  try {
    final content = file.readAsStringSync();
    final decoded = yaml.loadYaml(content);
    if (decoded is! Map) return null;
    final result = <String, Map<String, String>>{};
    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      final inner = entry.value as Map;
      result[entry.key.toString()] = inner.map(
        (k, v) => MapEntry(
          Platform.isWindows ? k.toString().toLowerCase() : k.toString(),
          v?.toString() ?? '',
        ),
      );
    }
    return result;
  } catch (_) {
    return null;
  }
}

void _writeLock(String root, Map<String, Map<String, String>> lock) {
  final buf = StringBuffer();
  for (final stepEntry in lock.entries) {
    buf.writeln('${stepEntry.key}:');
    for (final fileEntry in stepEntry.value.entries) {
      buf.writeln(
        '  "${_escapeYaml(fileEntry.key)}": "${_escapeYaml(fileEntry.value)}"',
      );
    }
  }
  File(_lockPath(root)).writeAsStringSync(buf.toString());
}

String _escapeYaml(String s) =>
    s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');

String _fileHash(File file) {
  final bytes = file.readAsBytesSync();
  final digest = sha256.convert(bytes);
  return digest.toString();
}

String _relativePath(String root, File file) {
  final rel = p.relative(file.path, from: root);
  final normalized = rel.replaceAll('\\', '/');
  return Platform.isWindows ? normalized.toLowerCase() : normalized;
}

bool _hashesMatch(
  String root,
  String stepName,
  List<File> inputs,
  Map<String, Map<String, String>>? lock,
) {
  if (lock == null || !lock.containsKey(stepName)) return false;
  final stepHashes = lock[stepName]!;
  for (final f in inputs) {
    final rel = _relativePath(root, f);
    final stored = stepHashes[rel];
    if (stored == null || stored != _fileHash(f)) return false;
  }
  if (stepHashes.length != inputs.length) return false;
  return true;
}

Map<String, String> _computeHashes(String root, List<File> inputs) {
  return {for (final f in inputs) _relativePath(root, f): _fileHash(f)};
}

void _updateLockWithHashes(
  String root,
  String stepName,
  Map<String, String> hashes,
) {
  final lock = _readLock(root) ?? <String, Map<String, String>>{};
  lock[stepName] = Map.from(hashes);
  _writeLock(root, lock);
}

DateTime? _modified(File file) {
  if (!file.existsSync()) return null;
  return file.lastModifiedSync();
}

bool _anyNewerThan(Iterable<File> inputs, File output) {
  final outTime = _modified(output);
  if (outTime == null) return true;
  for (final f in inputs) {
    final t = _modified(f);
    if (t != null && t.isAfter(outTime)) return true;
  }
  return false;
}

List<File> _iconsInputs(String root) {
  final config = File(p.join(root, 'flutter_launcher_icons.yaml'));
  final pubspec = File(p.join(root, 'pubspec.yaml'));
  final imagePath = File(p.join(root, 'assets/images/logos/colored_logo.png'));
  final monochrome = File(
    p.join(root, 'assets/images/logos/monochrome_logo.png'),
  );
  final background = File(
    p.join(root, 'assets/images/logos/colored_logo_without_mustache.png'),
  );
  final foreground = File(
    p.join(root, 'assets/images/logos/colored_logo_only_mustache.png'),
  );
  return [config, pubspec, imagePath, monochrome, background, foreground]
      .where((f) => f.existsSync())
      .map((f) => File(p.canonicalize(f.path)))
      .toList();
}

bool _iconsOutOfDate(String root) {
  final inputs = _iconsInputs(root);
  final output = File(
    p.join(
      root,
      'android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml',
    ),
  );
  if (!_anyNewerThan(inputs, output)) return false;
  return !_hashesMatch(root, 'icons', inputs, _readLock(root));
}

List<File> _l10nInputs(String root) {
  final l10nDir = p.join(root, 'lib/l10n');
  final l10nYml = File(p.join(root, 'l10n.yml'));
  final arbs = Directory(l10nDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .map((f) => File(p.canonicalize(f.path)))
      .toList();
  return [l10nYml, ...arbs].where((f) => f.existsSync()).cast<File>().toList();
}

bool _l10nOutOfDate(String root) {
  final inputs = _l10nInputs(root);
  final output = File(p.join(root, 'lib/l10n/app_localizations.dart'));
  if (!_anyNewerThan(inputs, output)) return false;
  return !_hashesMatch(root, 'l10n', inputs, _readLock(root));
}

List<File> _isarInputs(String root) {
  final modelsDir = p.join(root, 'lib/data/models');
  if (!Directory(modelsDir).existsSync()) return [];
  final list = <File>[];
  for (final entity in Directory(modelsDir).listSync()) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final content = entity.readAsStringSync();
    if (!content.contains("part '") || !content.contains('.g.dart')) continue;
    list.add(File(p.canonicalize(entity.path)));
  }
  return list;
}

bool _isarOutOfDate(String root) {
  final inputs = _isarInputs(root);
  if (inputs.isEmpty) return false;
  final modelsDir = p.join(root, 'lib/data/models');
  for (final dartFile in inputs) {
    final baseName = p.basenameWithoutExtension(dartFile.path);
    final gFile = File(p.join(modelsDir, '$baseName.g.dart'));
    if (_anyNewerThan([dartFile], gFile)) {
      return !_hashesMatch(root, 'isar', inputs, _readLock(root));
    }
  }
  return false;
}

Future<bool> _run(
  String executable,
  List<String> args,
  String workingDirectory,
) async {
  final result = await Process.run(
    executable,
    args,
    workingDirectory: workingDirectory,
    runInShell: true,
  );
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
  return true;
}
