import 'package:objectbox/objectbox.dart';

enum BookmarkType {
  bookmark,
  favorite,
}

@Entity()
class Bookmark {
  @Id()
  int id;

  String url;

  String? title;

  String? iconUrl;

  int timestamp;

  String typeString;

  double score;

  Bookmark({
    this.id = 0,
    required this.url,
    this.title,
    this.iconUrl,
    required this.timestamp,
    required this.typeString,
    this.score = 0.0,
  });

  factory Bookmark.create({
    int id = 0,
    required String url,
    String? title,
    String? iconUrl,
    required int timestamp,
    required BookmarkType type,
    double score = 0.0,
  }) {
    return Bookmark(
      id: id,
      url: url,
      title: title,
      iconUrl: iconUrl,
      timestamp: timestamp,
      typeString: type.name,
      score: score,
    );
  }

  @Transient()
  BookmarkType get type {
    return BookmarkType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => BookmarkType.bookmark,
    );
  }

  set type(BookmarkType value) {
    typeString = value.name;
  }
}
