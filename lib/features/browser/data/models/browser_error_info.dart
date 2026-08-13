import 'package:equatable/equatable.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class BrowserErrorInfo extends Equatable {
  final int errorCode;
  final String errorText;
  final String failedUrl;

  const BrowserErrorInfo({
    required this.errorCode,
    required this.errorText,
    required this.failedUrl,
  });

  /// Maps Chromium/CEF numeric error codes to human-readable error names (e.g. ERR_NAME_NOT_RESOLVED).
  String cefErrorName([AppLocalizations? l10n]) {
    switch (errorCode) {
      case -105:
        return l10n?.errNameNotResolvedCode ?? 'ERR_NAME_NOT_RESOLVED';
      case -102:
        return l10n?.errConnectionRefusedCode ?? 'ERR_CONNECTION_REFUSED';
      case -118:
        return l10n?.errConnectionTimedOutCode ?? 'ERR_CONNECTION_TIMED_OUT';
      case -106:
        return l10n?.errInternetDisconnectedCode ?? 'ERR_INTERNET_DISCONNECTED';
      case -101:
        return l10n?.errConnectionResetCode ?? 'ERR_CONNECTION_RESET';
      case -100:
        return l10n?.errConnectionClosedCode ?? 'ERR_CONNECTION_CLOSED';
      case -109:
        return l10n?.errAddressUnreachableCode ?? 'ERR_ADDRESS_UNREACHABLE';
      case -200:
        return l10n?.errCertCommonNameInvalidCode ??
            'ERR_CERT_COMMON_NAME_INVALID';
      case -201:
        return l10n?.errCertDateInvalidCode ?? 'ERR_CERT_DATE_INVALID';
      case -202:
        return l10n?.errCertAuthorityInvalidCode ??
            'ERR_CERT_AUTHORITY_INVALID';
      case -300:
        return l10n?.errInvalidUrlCode ?? 'ERR_INVALID_URL';
      case -302:
        return l10n?.errUnknownUrlSchemeCode ?? 'ERR_UNKNOWN_URL_SCHEME';
      case -310:
        return l10n?.errTooManyRedirectsCode ?? 'ERR_TOO_MANY_REDIRECTS';
      default:
        if (errorText.isNotEmpty && errorText.startsWith('ERR_')) {
          return errorText;
        }
        return l10n?.errFailedCode(errorCode) ?? 'ERR_FAILED ($errorCode)';
    }
  }

  /// Human-readable explanation of why the page could not be loaded.
  String readableDescription([AppLocalizations? l10n]) {
    final host = hostName;
    switch (errorCode) {
      case -105:
        return l10n?.errNameNotResolvedDescription(host) ??
            '$host took too long to respond or could not be resolved.';
      case -102:
        return l10n?.errConnectionRefusedDescription(host) ??
            '$host refused to connect.';
      case -118:
        return l10n?.errConnectionTimedOutDescription(host) ??
            '$host took too long to respond.';
      case -106:
        return l10n?.errInternetDisconnectedDescription ??
            'Your computer is offline.';
      case -101:
        return l10n?.errConnectionResetDescription(host) ??
            'The connection to $host was reset.';
      case -100:
      case -109:
        return l10n?.errUnreachableDescription(host) ?? '$host is unreachable.';
      default:
        return l10n?.errDefaultDescription(failedUrl) ??
            'The webpage at $failedUrl might be temporarily down or it may have moved permanently to a new web address.';
    }
  }

  /// Extracts the host domain name for display.
  String get hostName {
    try {
      final uri = Uri.parse(
        failedUrl.startsWith('http') ? failedUrl : 'http://$failedUrl',
      );
      return uri.host.isNotEmpty ? uri.host : failedUrl;
    } catch (_) {
      return failedUrl;
    }
  }

  @override
  List<Object?> get props => [errorCode, errorText, failedUrl];
}
