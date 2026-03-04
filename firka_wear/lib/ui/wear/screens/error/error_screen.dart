import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wear_plus/wear_plus.dart';

import 'package:firka_wear/ui/theme/style.dart';

final int _kMaxQrPayloadChars = 410;

String errorPayload(Object exception, [StackTrace? stackTrace]) {
  final buffer = StringBuffer();
  buffer.writeln(exception.toString());
  if (stackTrace != null) buffer.write(stackTrace.toString());
  final s = buffer.toString();
  return s.length > _kMaxQrPayloadChars
      ? s.substring(0, _kMaxQrPayloadChars)
      : s;
}

/// Full-screen error UI: encodes [exception] (and [stackTrace]) into a QR code
/// scaled to fit the watch's circular display so it is not clipped.
class WearErrorScreen extends StatelessWidget {
  final Object exception;
  final StackTrace? stackTrace;

  const WearErrorScreen({super.key, required this.exception, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

    final payload = errorPayload(exception, stackTrace);
    return Scaffold(
      backgroundColor: wearStyle.colors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: WatchShape(
              builder: (context, shape, child) {
                return SizedBox(
                  width: 350.w,
                  height: 350.h,
                  child: QrImageView(
                    data: payload,
                    version: 13,
                    backgroundColor: wearStyle.colors.background,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: wearStyle.colors.textPrimary,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: wearStyle.colors.textPrimary,
                    ),
                  ),
                );
              },
              child: const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
