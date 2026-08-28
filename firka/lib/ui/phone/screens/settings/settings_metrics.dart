import "package:flutter/widgets.dart";

const settingsDesignWidth = 376.0;
const settingsItemHeight = 56.0;
const settingsItemRounding = 16.0;

double settingsScale(BuildContext context) =>
    MediaQuery.sizeOf(context).width / settingsDesignWidth;
