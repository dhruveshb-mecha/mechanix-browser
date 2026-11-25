/// How a visit to a page started, recorded on each history visit.
///
/// A trimmed version of Chromium's core page transition types, limited to what
/// this browser can tell apart. Stored by name, so values can be reordered or
/// added without a migration.
enum PageTransition {
  /// Followed a link, or a navigation that couldn't be classified.
  link,

  /// The user typed the URL in the address bar.
  typed,

  /// Opened from a bookmark or favorite.
  autoBookmark,

  /// Opened from a search query or search suggestion.
  generated,

  /// The page was reloaded.
  reload,

  /// Reached through a redirect; `from_visit` points at the visit before it.
  redirect,
}
