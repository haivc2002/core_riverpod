/// Configuration class for handling network authentication, token refreshing, and error handling.
class NetworkAuthConfig {
  /// The API endpoint path for refreshing the token.
  /// 
  /// This endpoint is combined with the base URL configured in `NetworkService`.
  /// When provided, the system automatically attempts to refresh the token when 
  /// an API request fails with a 401 error. If not provided, any failed API request 
  /// will return the error normally without attempting a refresh.
  final String? endpoint;

  /// A callback to retrieve the current access token.
  /// 
  /// This is synchronized with the `withToken` parameter in the `get`, `post`, `put`, 
  /// `delete`, and `patch` methods of `NetworkService`. If `withToken` is true, 
  /// this callback is executed to get the token (e.g., from FlutterSecureStorage, 
  /// SharedPreferences, Hive, etc.) and attach it to the request header.
  final Future<String> Function()? accessToken;

  /// A callback to retrieve the current refresh token.
  /// 
  /// This is used by the `buildRequestBody` callback. It uses a function to ensure 
  /// that the most accurate and up-to-date value of the refresh token is retrieved 
  /// right before the refresh API call is made.
  final Future<String> Function()? refreshToken;

  final Future<String> Function()? expirationAt;
  final Future<String> Function()? refreshTokenExpiresAt;

  /// A callback triggered when the token refresh process is successful.
  /// 
  /// Returns the JSON response from the successful refresh API call, allowing the 
  /// developer to parse, update, and persist the new token values.
  final Future<void> Function(Map<String, dynamic> response)? onRefreshSuccess;

  /// A callback triggered when a critical authentication error occurs (e.g., refresh fails, 
  /// or 401 persists).
  /// 
  /// - If not provided (null), a 401 error will run smoothly and return the error response 
  ///   normally without blocking the execution flow.
  /// - If provided, but `endpoint` is null, the system won't perform a refresh but will 
  ///   still trigger this `onAuthenticationError` event upon receiving a 401 error.
  /// 
  /// By default, when this event is triggered, it actively blocks the API execution process 
  /// (throwing an internal exception), stopping the asynchronous flow immediately. The 
  /// developer won't be able to catch the error downstream. This behavior is intentional 
  /// to prevent subsequent UI logic from running.
  /// 
  /// **Why block the execution?**
  /// Consider the following flow:
  /// ```dart
  /// openLoadingOverlay();
  /// final response = await executeWithAutomaticConnectionRecovery(() => getPosts()); 
  /// closeLoadingOverlay(); 
  /// ```
  /// If the API call fails and triggers a session expired dialog via this callback, 
  /// but the execution isn't blocked, `closeLoadingOverlay()` would run. Depending on 
  /// the custom routing/dialog implementation, closing the overlay might inadvertently 
  /// pop the session expired dialog instead, causing unexpected UI states and difficult debugging.
  final Function()? onAuthenticationError;

  /// A callback to construct the request body for the refresh API call.
  /// 
  /// Defines the body to be sent to the API configured with the `endpoint`, using 
  /// the `refreshToken` retrieved earlier.
  final Map<String, dynamic> Function(String refreshToken)? buildRequestBody;

  /// A flag to manually override the execution blocking behavior on authentication errors.
  /// 
  /// If set to `false`, the system will not block the execution flow after triggering 
  /// `onAuthenticationError`, and will instead return the Failure response normally.
  /// Defaults to `true` if `onAuthenticationError` is provided, otherwise `false`.
  final bool blockOnAuthenticationError;

  const NetworkAuthConfig({
    this.endpoint,
    this.accessToken,
    this.refreshToken,
    this.expirationAt,
    this.onRefreshSuccess,
    this.buildRequestBody,
    this.refreshTokenExpiresAt,
    this.onAuthenticationError,
    bool? blockOnAuthenticationError,
  }) : blockOnAuthenticationError =
            blockOnAuthenticationError ?? (onAuthenticationError != null);
}
