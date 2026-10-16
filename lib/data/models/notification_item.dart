import '../../core/utils/json.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.read,
    required this.type,
  });

  final String id;
  final String title;
  final String message;
  final String time;
  final bool read;
  final String type; // reward | order | community | tip | friend | message | doctor

  factory NotificationItem.fromJson(Json j) => NotificationItem(
        id: jStr(j, 'id'),
        title: jStr(j, 'title'),
        message: jStr(j, 'message'),
        time: jStr(j, 'time'),
        read: jBool(j, 'read'),
        type: jStr(j, 'type', 'tip'),
      );

  NotificationItem markRead() =>
      NotificationItem(id: id, title: title, message: message, time: time, read: true, type: type);
}
