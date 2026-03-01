class ApiResponse<T> {
  T? response;
  int statusCode;
  String? err;
  bool cached;

  ApiResponse(this.response, this.statusCode, this.err, this.cached);

  @override
  String toString() {
    return "ApiResponse("
        "response: $response, "
        "statusCode: $statusCode, "
        "err: \"$err\", "
        "cached: $cached"
        ")";
  }
}
