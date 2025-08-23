class TokenGrantResponse {
  final String idToken;
  final String accessToken;
  final int expiresIn;
  final String tokenType;
  final String refreshToken;
  final String scope;

  TokenGrantResponse(
      {required this.idToken,
      required this.accessToken,
      required this.expiresIn,
      required this.tokenType,
      required this.refreshToken,
      required this.scope});

  factory TokenGrantResponse.fromJson(Map<String, dynamic> json) {
    return TokenGrantResponse(
        idToken: json['id_token'],
        accessToken: json['access_token'],
        expiresIn: json['expires_in'],
        tokenType: json['token_type'],
        refreshToken: json['refresh_token'],
        scope: json['scope']);
  }

  @override
  String toString() {
    return 'TokenGrant(idToken: "$idToken", accessToken: "$accessToken", '
        'expiresIn: $expiresIn, '
        'tokenType: "$tokenType", '
        'refreshToken: "$refreshToken", '
        'scope: "$scope"'
        ')';
  }
}
