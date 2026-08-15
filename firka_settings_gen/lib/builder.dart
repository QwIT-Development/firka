import "package:analyzer/dart/analysis/utilities.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:build/build.dart";

Builder settingsSchemaBuilder(BuilderOptions options) =>
    SettingsSchemaBuilder();

const _settingAnnotations = {
  "BoolSetting",
  "DoubleSetting",
  "EnumSetting",
  "StringSetting",
};

/// Reads the @BoolSetting/@DoubleSetting/@EnumSetting/@StringSetting-annotated
/// getters on SettingsSchema and emits the typed Settings registry.
/// Parses settings_schema.dart syntactically (no resolution needed: the
/// annotation's source text is copied verbatim into the generated literal).
class SettingsSchemaBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    "settings_schema.dart": ["settings_schema.gen.dart"],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final source = await buildStep.readAsString(buildStep.inputId);
    final unit = parseString(content: source).unit;
    final schemaClass = unit.declarations
        .whereType<ClassDeclaration>()
        .firstWhere((c) => c.name.lexeme == "SettingsSchema");

    final entries = <(String name, String dartType, String annotationClass, String args)>[];
    for (final member in schemaClass.members) {
      if (member is! MethodDeclaration || !member.isGetter) continue;

      final annotation = member.metadata
          .where((a) => _settingAnnotations.contains(a.name.name))
          .firstOrNull;
      if (annotation == null) continue;

      entries.add((
        member.name.lexeme,
        member.returnType!.toSource(),
        annotation.name.name,
        annotation.arguments!.toSource(),
      ));
    }

    final buffer = StringBuffer()
      ..writeln("// GENERATED CODE - DO NOT MODIFY BY HAND")
      ..writeln()
      ..writeln('part of "settings_schema.dart";')
      ..writeln()
      ..writeln("class SettingsRegistry {");

    for (final (name, _, annotationClass, args) in entries) {
      buffer.writeln("  static const $name = $annotationClass$args;");
    }

    buffer
      ..writeln()
      ..writeln("  static const all = <Setting>[")
      ..writeln("    ${entries.map((e) => e.$1).join(', ')},")
      ..writeln("  ];")
      ..writeln("}")
      ..writeln()
      ..writeln("extension SettingsAccessors on SettingsRepository {");

    for (final (name, dartType, _, _) in entries) {
      buffer.writeln(
        "  SilentlySettable<$dartType> get $name => "
        "SilentlySettable(this, SettingsRegistry.$name);",
      );
    }

    buffer.writeln("}");

    await buildStep.writeAsString(
      buildStep.inputId.changeExtension(".gen.dart"),
      buffer.toString(),
    );
  }
}
