import 'package:legado_reader/core/constant/source_type.dart';
import 'package:legado_reader/core/services/source_verification_service.dart';

class BrowserParams {
  final String url;
  final String title;
  final String? sourceName;
  final String? sourceOrigin;
  final int sourceType; // SourceType.book or SourceType.rss
  final bool sourceVerificationEnable;
  final bool refetchAfterSuccess;
  final VerificationRequest? verificationRequest;

  BrowserParams({
    required this.url,
    required this.title,
    this.sourceName,
    this.sourceOrigin,
    this.sourceType = SourceType.book,
    this.sourceVerificationEnable = false,
    this.refetchAfterSuccess = true,
    this.verificationRequest,
  });
}

