import 'package:objectbox/objectbox.dart';

@Entity()
class BrowserHistory {
  @Id()
  int id = 0;

  String url;
  String title;
  int timestamp;

  BrowserHistory({
    this.id = 0,
    required this.url,
    required this.title,
    required this.timestamp,
  });
}
