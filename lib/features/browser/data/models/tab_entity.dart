import 'package:objectbox/objectbox.dart';

@Entity()
class TabEntity {
  @Id()
  int id;

  String tabId;
  int tabIndex;
  String url;
  String title;
  bool isActive;

  TabEntity({
    this.id = 0,
    required this.tabId,
    required this.tabIndex,
    required this.url,
    required this.title,
    required this.isActive,
  });
}
