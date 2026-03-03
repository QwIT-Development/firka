import 'dart:io';

import 'package:path/path.dart' as p;

void main() async {
  final root = _projectRoot();
  var ran = false;

  if (_iconsOutOfDate(root)) {
    stdout.writeln('Icons out of date, running flutter_launcher_icons...');
    await _run('dart', ['run', 'flutter_launcher_icons'], root);
    ran = true;
  }

  if (_l10nOutOfDate(root)) {
    stdout.writeln('l10n out of date, running flutter gen-l10n...');
    await _run('flutter', [
      'gen-l10n',
      '--template-arb-file',
      'app_hu.arb',
    ], root);
    ran = true;
  }

  if (_isarOutOfDate(root)) {
    stdout.writeln(
      'Isar generated dart files out of date, running build_runner...',
    );
    await _run('dart', ['run', 'build_runner', 'build'], root);
    ran = true;
  }

  if (!ran) {
    stdout.writeln('All generated files are up to date.');
  }
}

String _projectRoot() {
  final script = p.canonicalize(Platform.script.toFilePath());
  return p.dirname(p.dirname(script));
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

bool _iconsOutOfDate(String root) {
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

  final inputs = [
    config,
    pubspec,
    imagePath,
    monochrome,
    background,
    foreground,
  ].where((f) => f.existsSync()).map((f) => File(p.canonicalize(f.path)));
  final output = File(
    p.join(
      root,
      'android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml',
    ),
  );
  return _anyNewerThan(inputs, output);
}

bool _l10nOutOfDate(String root) {
  final l10nDir = p.join(root, 'lib/l10n');
  final l10nYml = File(p.join(root, 'l10n.yml'));
  final arbs = Directory(l10nDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .map((f) => File(p.canonicalize(f.path)))
      .toList();
  final inputs = [l10nYml, ...arbs].where((f) => f.existsSync()).cast<File>();
  final output = File(p.join(root, 'lib/l10n/app_localizations.dart'));
  return _anyNewerThan(inputs, output);
}

bool _isarOutOfDate(String root) {
  final modelsDir = p.join(root, 'lib/data/models');
  if (!Directory(modelsDir).existsSync()) return false;

  for (final entity in Directory(modelsDir).listSync()) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final content = entity.readAsStringSync();
    if (!content.contains("part '") || !content.contains('.g.dart')) continue;

    final baseName = p.basenameWithoutExtension(entity.path);
    final gPath = p.join(modelsDir, '$baseName.g.dart');
    final dartFile = File(p.canonicalize(entity.path));
    final gFile = File(gPath);
    if (_anyNewerThan([dartFile], gFile)) return true;
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
