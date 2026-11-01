import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';

/// A stylist's social profile, ready to show and open.
class SocialProfileLink {
  const SocialProfileLink({required this.platform, required this.uri});

  final String platform;
  final Uri uri;
}

/// Social-media link rules shared by the stylist profile (display) and the
/// verification form (editing).
abstract final class SocialLinks {
  static const invalidUrlMessage =
      'Enter the full https:// link to your social media profile, for '
      'example https://www.instagram.com/yourname.';

  static final RegExp _host = RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)+$',
      caseSensitive: false);

  /// Mirrors Laravel's `SocialProfileUrl` rule: a full `https` URL with a
  /// dotted host and no credentials. Handles such as `@yourname` fail.
  static bool isValidProfileUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri != null &&
        uri.scheme.toLowerCase() == 'https' &&
        _host.hasMatch(uri.host) &&
        uri.userInfo.isEmpty;
  }

  /// The links worth showing: non-empty, parseable web URLs with a host.
  /// Anything else (handles, `javascript:`, blanks) is dropped, never shown
  /// as an empty placeholder.
  static List<SocialProfileLink> displayable(
    Iterable<({String? platform, String? url})> entries,
  ) {
    final links = <SocialProfileLink>[];
    for (final entry in entries) {
      final uri = Uri.tryParse(entry.url?.trim() ?? '');
      if (uri == null ||
          !(uri.scheme == 'https' || uri.scheme == 'http') ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        continue;
      }
      final platform = entry.platform?.trim() ?? '';
      links.add(
        SocialProfileLink(
          platform: platform.isEmpty ? _platformFromHost(uri.host) : platform,
          uri: uri,
        ),
      );
    }
    return links;
  }

  /// A recognisable icon where the app's icon set has one (Instagram);
  /// otherwise a neutral link icon, always shown with the platform's name.
  static IconData iconFor(SocialProfileLink link) {
    final name = '${link.platform} ${link.uri.host}'.toLowerCase();
    if (name.contains('instagram')) return Iconsax.instagram;
    return Iconsax.link_2;
  }

  static String _platformFromHost(String host) {
    final parts = host.toLowerCase().split('.')
      ..removeWhere((p) => p == 'www' || p == 'm');
    final name = parts.isEmpty ? host : parts.first;
    return name.isEmpty ? 'Link' : '${name[0].toUpperCase()}${name.substring(1)}';
  }
}
