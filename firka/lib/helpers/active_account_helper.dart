import 'db/models/token_model.dart';

int resolveActiveAccountIndex(dynamic settings) {
  try {
    final dynamic profileSettings = settings.group("profile_settings");
    final dynamic accountPicker = profileSettings["e_kreta_account_picker"];
    final dynamic accountIndex = accountPicker.accountIndex;
    if (accountIndex is int && accountIndex >= 0) {
      return accountIndex;
    }
  } catch (_) {
  }

  return 0;
}

TokenModel? pickActiveToken({
  required List<TokenModel> tokens,
  required dynamic settings,
  int? preferredStudentIdNorm,
}) {
  if (tokens.isEmpty) return null;

  if (preferredStudentIdNorm != null) {
    for (final token in tokens) {
      if (token.studentIdNorm == preferredStudentIdNorm) {
        return token;
      }
    }
  }

  final accountIndex = resolveActiveAccountIndex(settings);
  if (accountIndex < tokens.length) {
    return tokens[accountIndex];
  }

  return tokens.first;
}
