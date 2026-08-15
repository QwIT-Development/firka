import "package:firka/app/app_state.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/ui/components/firka_card.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

class SettingsLicensePageView extends StatelessWidget {
  final AppInitialization data;

  const SettingsLicensePageView({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LicenseEntry>>(
      future: LicenseRegistry.licenses.toList(),
      builder:
          (BuildContext context, AsyncSnapshot<List<LicenseEntry>> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: appStyle.colors.accent),
              );
            }

            final licenses = snapshot.data!;
            final shownPackages = <String>{};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: licenses
                  .where(
                    (license) => license.packages.any(
                      (pkg) => !shownPackages.contains(pkg),
                    ),
                  )
                  .map((license) {
                    final packageName = license.packages.firstWhere(
                      (pkg) => !shownPackages.contains(pkg),
                      orElse: () => license.packages.first,
                    );
                    shownPackages.add(packageName);
                    final paragraphs = license.paragraphs
                        .map((p) => p.text)
                        .join('\n\n');

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: appStyle.colors.card,
                                    title: Text(
                                      packageName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: SingleChildScrollView(
                                      child: Text(
                                        paragraphs,
                                        style: appStyle.fonts.B_15SB.apply(
                                          color: appStyle.colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                          data.l10n.close,
                                          style: appStyle.fonts.B_14R.apply(
                                            color:
                                                appStyle.colors.textSecondary,
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: FirkaCard(
                              left: [
                                Text(
                                  packageName,
                                  style: appStyle.fonts.B_14R.apply(
                                    color: appStyle.colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
            );
          },
    );
  }
}
