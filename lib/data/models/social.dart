import '../../core/utils/json.dart';

/// Client-owned lists synced with `PUT /api/sync/friends|conversations|messages`.
/// `toJson()` must produce exactly what the web app sends (see types.ts).

class FriendUser {
  const FriendUser({
    required this.id,
    required this.name,
    this.avatar = '',
    this.bio = '',
    this.location = '',
    this.mutualFriendsCount = 0,
    this.friendshipStatus = 'none',
    this.isBlocked,
  });

  final String id;
  final String name;
  final String avatar;
  final String bio;
  final String location;
  final int mutualFriendsCount;
  final String friendshipStatus; // friends | request_sent | request_received | none
  final bool? isBlocked;

  factory FriendUser.fromJson(Json j) => FriendUser(
        id: jStr(j, 'id'),
        name: jStr(j, 'name'),
        avatar: jStr(j, 'avatar'),
        bio: jStr(j, 'bio'),
        location: jStr(j, 'location'),
        mutualFriendsCount: jInt(j, 'mutualFriendsCount'),
        friendshipStatus: jStr(j, 'friendshipStatus', 'none'),
        isBlocked: j['isBlocked'] is bool ? j['isBlocked'] as bool : null,
      );

  Json toJson() => compact({
        'id': id,
        'name': name,
        'avatar': avatar,
        'bio': bio,
        'location': location,
        'mutualFriendsCount': mutualFriendsCount,
        'friendshipStatus': friendshipStatus,
        'isBlocked': isBlocked,
      });

  FriendUser withStatus(String status) => FriendUser(
        id: id,
        name: name,
        avatar: avatar,
        bio: bio,
        location: location,
        mutualFriendsCount: mutualFriendsCount,
        friendshipStatus: status,
        isBlocked: isBlocked,
      );
}

class Conversation {
  const Conversation({
    required this.id,
    required this.participant,
    this.lastMessage = '',
    this.lastTimestamp = '',
    this.unreadCount = 0,
    this.isRequest,
  });

  final String id;
  final FriendUser participant;
  final String lastMessage;
  final String lastTimestamp;
  final int unreadCount;
  final bool? isRequest;

  factory Conversation.fromJson(Json j) => Conversation(
        id: jStr(j, 'id'),
        participant: FriendUser.fromJson(jMap(j, 'participant')),
        lastMessage: jStr(j, 'lastMessage'),
        lastTimestamp: jStr(j, 'lastTimestamp'),
        unreadCount: jInt(j, 'unreadCount'),
        isRequest: j['isRequest'] is bool ? j['isRequest'] as bool : null,
      );

  Json toJson() => compact({
        'id': id,
        'participant': participant.toJson(),
        'lastMessage': lastMessage,
        'lastTimestamp': lastTimestamp,
        'unreadCount': unreadCount,
        'isRequest': isRequest,
      });

  Conversation copyWith({String? lastMessage, String? lastTimestamp, int? unreadCount}) => Conversation(
        id: id,
        participant: participant,
        lastMessage: lastMessage ?? this.lastMessage,
        lastTimestamp: lastTimestamp ?? this.lastTimestamp,
        unreadCount: unreadCount ?? this.unreadCount,
        isRequest: isRequest,
      );
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    required this.timestamp,
    this.status = 'sent',
  });

  final String id;
  final String conversationId;
  final String senderId; // 'me' or friend id
  final String text;
  final String? mediaUrl;
  final String timestamp;
  final String status; // sent | delivered | read

  bool get isMine => senderId == 'me';

  factory Message.fromJson(Json j) => Message(
        id: jStr(j, 'id'),
        conversationId: jStr(j, 'conversationId'),
        senderId: jStr(j, 'senderId'),
        text: jStr(j, 'text'),
        mediaUrl: jStrN(j, 'mediaUrl'),
        timestamp: jStr(j, 'timestamp'),
        status: jStr(j, 'status', 'sent'),
      );

  Json toJson() => compact({
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp,
        'status': status,
      });
}
