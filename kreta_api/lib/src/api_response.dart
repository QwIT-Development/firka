class ApiResponse<T> {
  T? response;
  int statusCode;
  Object? err;
  bool cached;

  ApiResponse(this.response, this.statusCode, this.err, this.cached);

  ApiResponse.fail(this.err) : response = null, statusCode = 0, cached = false;

  ApiResponse.success(this.response, this.statusCode)
    : err = null,
      cached = false;

  ApiResponse.cached(this.response)
    : statusCode = 200,
      err = null,
      cached = true;

  @override
  String toString() {
    return "ApiResponse("
        "response: $response, "
        "statusCode: $statusCode, "
        "err: \"${err.toString()}\", "
        "cached: $cached"
        ")";
  }
}
