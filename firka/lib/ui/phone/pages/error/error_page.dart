import 'package:firka/ui/model/style.dart';
import 'package:flutter/material.dart';
import 'package:firka/helpers/image_preloader.dart';
import 'package:firka/helpers/firka_bundle.dart';
import 'package:firka/helpers/swear_generator.dart';

class ErrorPage extends StatelessWidget {
  final String exception;

  const ErrorPage({super.key, required this.exception});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: appStyle.colors.background,
        body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(children: [
                    SizedBox(height: 48),
                    Container(
                      width: 50,
                      height: 50,
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        image: DecorationImage(
                          image: PreloadedImageProvider(FirkaBundle(),
                              ('assets/images/logos/dave_error.png')),
                          fit: BoxFit.cover,
                        ),
                        shape: ContinuousRectangleBorder(),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 32),
                        child: Column(children: [
                          Text(
                            'e-Kréta, te',
                            style: appStyle.fonts.H_16px
                                .copyWith(color: appStyle.colors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            //'a,',
                            generateSwearSentence(),
                            style: appStyle.fonts.H_H2.copyWith(
                                color: appStyle.colors.textPrimary,
                                fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                        ])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "Valami probléma történt, ez természetesen az EduDev Zrt. hibája minden esetben",
                        style: appStyle.fonts.B_14R.copyWith(
                          color: appStyle.colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]),
                  Column(
                    children: [
                      Stack(children: [
                        Container(
                            height: 300,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: appStyle.colors.card,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(exception,
                                style: appStyle.fonts.B_14R.copyWith(
                                    color: appStyle.colors.textPrimary,
                                    fontFamily: 'RobotoMono'))),
                        Positioned(
                          bottom: 0,
                          right: 16,
                          child: Container(
                            width: 60,
                            height: 76,
                            clipBehavior: Clip.antiAlias,
                            decoration: ShapeDecoration(
                              image: DecorationImage(
                                  image: PreloadedImageProvider(FirkaBundle(),
                                      ('assets/images/cactus_error_screen.png')),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.srgbToLinearGamma()),
                              shape: ContinuousRectangleBorder(),
                            ),
                          ),
                        )
                      ]),
                      SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                          // TODO: report bug
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              foregroundColor: appStyle.colors.textPrimary,
                              backgroundColor: appStyle.colors.accent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                              shadowColor: appStyle.colors.shadowColor,
                              minimumSize: Size.fromHeight(48)),
                          child: Text("Hiba jelentése",
                              style: appStyle.fonts.H_18px
                                  .copyWith(fontWeight: FontWeight.w700))),
                      SizedBox(
                        height: 8,
                      ),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              foregroundColor: appStyle.colors.textSecondary,
                              backgroundColor:
                                  appStyle.colors.buttonSecondaryFill,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                              shadowColor: appStyle.colors.shadowColor,
                              minimumSize: Size.fromHeight(48)),
                          child: Text("Vissza", style: appStyle.fonts.B_16R))
                    ],
                  )
                ])));

    return Scaffold(
      appBar: AppBar(
        title: Text('Error Occurred'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              'An error occurred!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.red,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Details:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              exception,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.redAccent,
                  ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
