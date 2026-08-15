import "dart:io";

import "package:firka/app/app_state.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/ui/components/firka_card.dart";
import "package:flutter/material.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";
import "package:path/path.dart" as p;
import "package:share_plus/share_plus.dart";

class SettingsLogsView extends StatelessWidget {
  final AppInitialization data;

  const SettingsLogsView({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final logFileRegex = RegExp(r'^(\d{4})_(\d{2})_(\d{2})\.log$');
    final entries = data.appDir
        .listSync()
        .whereType<File>()
        .where((entity) => logFileRegex.hasMatch(entity.uri.pathSegments.last))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entity in entries) ...[
          GestureDetector(
            child: SizedBox(
              height: 52,
              child: FirkaCard(
                left: [
                  FirkaIconWidget(
                    FirkaIconType.majesticons,
                    Majesticon.noteTextSolid,
                    color: appStyle.colors.accent,
                  ),
                  Text(
                    entity.uri.pathSegments.last,
                    style: appStyle.fonts.B_16R.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () => _shareLog(entity),
          ),
          SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _shareLog(File entity) async {
    final name = entity.uri.pathSegments.last;

    try {
      logger.info("Compressing log file: ${entity.path}");
      final originalBytes = await entity.readAsBytes();
      final gzBytes = GZipCodec().encode(originalBytes);
      final tempDir = await Directory.systemTemp.createTemp('firka');
      final gzPath = p.join(tempDir.path, '${p.basename(entity.path)}.gz');
      final gzFile = await File(gzPath).writeAsBytes(gzBytes, flush: true);

      final params = ShareParams(
        text: name,
        files: [XFile(gzFile.path, mimeType: 'application/gzip')],
      );

      await SharePlus.instance.share(params);

      await gzFile.delete();
      await tempDir.delete();
    } catch (ex) {
      if (ex is Error) {
        logger.shout(
          "Failed to compress log file",
          ex.toString(),
          ex.stackTrace,
        );
      } else {
        logger.shout("Failed to compress log file", ex.toString());
      }

      logger.info("Sharing regular log file instead: ${entity.path}");
      final params = ShareParams(
        text: name,
        files: [XFile(entity.path, mimeType: 'text/plain')],
      );

      await SharePlus.instance.share(params);
    }
  }
}
