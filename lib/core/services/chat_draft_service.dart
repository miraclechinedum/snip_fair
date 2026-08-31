import 'package:shared_preferences/shared_preferences.dart';

/// Local-only draft store for the chat input field. Persists what a user was
/// typing when they left a chat mid-message, restores it when they come back.
///
/// - Purely local — nothing ever hits the network.
/// - Keyed by `<userId>:<conversationId>` so drafts don't leak across users
///   on a shared device.
/// - Wiped for the logged-out user in `AppCubit.onLogout` for the same reason.
///
/// Uses a static singleton so callers (chat screen, conversation list row)
/// can read drafts synchronously during `build`. Initialise once from
/// bootstrap before `runApp`.
class ChatDraftService {
  ChatDraftService._(this._prefs);

  static const String _prefix = 'chat_draft:';

  static ChatDraftService? _instance;

  /// Initialise from bootstrap once, before any UI builds. Safe to call more
  /// than once — subsequent calls are no-ops.
  static Future<void> init() async {
    if (_instance != null) return;
    final prefs = await SharedPreferences.getInstance();
    _instance = ChatDraftService._(prefs);
  }

  static ChatDraftService get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'ChatDraftService.init() must be called before '
        'ChatDraftService.instance',
      );
    }
    return i;
  }

  final SharedPreferences _prefs;

  String _key(String userId, String conversationId) =>
      '$_prefix$userId:$conversationId';

  /// Saves (or overwrites) a draft. Whitespace-only drafts are treated as
  /// empty and clear the existing entry — an empty draft is the same as no
  /// draft.
  Future<void> save({
    required String userId,
    required String conversationId,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      await clear(userId: userId, conversationId: conversationId);
      return;
    }
    await _prefs.setString(_key(userId, conversationId), text);
  }

  /// Synchronous read for use during `build`. Returns null if no draft.
  String? get({
    required String userId,
    required String conversationId,
  }) {
    return _prefs.getString(_key(userId, conversationId));
  }

  Future<void> clear({
    required String userId,
    required String conversationId,
  }) async {
    await _prefs.remove(_key(userId, conversationId));
  }

  /// Wipes every draft belonging to [userId]. Called on logout so the next
  /// user on the device never sees stale drafts from the previous account.
  Future<void> clearAllForUser(String userId) async {
    final needle = '$_prefix$userId:';
    final keys = _prefs.getKeys()
        .where((k) => k.startsWith(needle))
        .toList(growable: false);
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
