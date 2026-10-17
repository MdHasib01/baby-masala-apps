import '../../core/utils/json.dart';

/// Topics accepted by the API (`POST_TOPICS` in the backend).
const postTopics = ['খাবার', 'ঘুম', 'বিকাশ', 'মায়ের গল্প'];

class Post {
  const Post({
    required this.id,
    this.authorId,
    required this.authorName,
    required this.authorAvatar,
    this.isVerifiedBuyer = false,
    required this.topic,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    this.likes = 0,
    this.likedByMe = false,
    this.savedByMe = false,
    this.commentsCount = 0,
    this.status = 'approved',
  });

  final String id;
  final String? authorId;
  final String authorName;
  final String authorAvatar;
  final bool isVerifiedBuyer;
  final String topic;
  final String content;
  final String? mediaUrl;
  final String? mediaType; // 'image' | 'video'
  final String createdAt; // Bengali relative label, e.g. "২ ঘণ্টা আগে"
  final int likes;
  final bool likedByMe;
  final bool savedByMe;
  final int commentsCount;
  final String status; // 'approved' | 'pending' | 'rejected'

  bool get isVideo =>
      mediaType == 'video' ||
      (mediaUrl != null && RegExp(r'\.(mp4|webm|mov|m4v)(\?|$)|video', caseSensitive: false).hasMatch(mediaUrl!));

  factory Post.fromJson(Json j) => Post(
        id: jStr(j, 'id'),
        authorId: jStrN(j, 'authorId'),
        authorName: jStr(j, 'authorName'),
        authorAvatar: jStr(j, 'authorAvatar'),
        isVerifiedBuyer: jBool(j, 'isVerifiedBuyer'),
        topic: jStr(j, 'topic'),
        content: jStr(j, 'content'),
        mediaUrl: jStrN(j, 'mediaUrl'),
        mediaType: jStrN(j, 'mediaType'),
        createdAt: jStr(j, 'createdAt'),
        likes: jInt(j, 'likes'),
        likedByMe: jBool(j, 'likedByMe'),
        savedByMe: jBool(j, 'savedByMe'),
        commentsCount: jInt(j, 'commentsCount'),
        status: jStr(j, 'status', 'approved'),
      );

  Post copyWith({bool? savedByMe}) => Post(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        isVerifiedBuyer: isVerifiedBuyer,
        topic: topic,
        content: content,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        createdAt: createdAt,
        likes: likes,
        likedByMe: likedByMe,
        savedByMe: savedByMe ?? this.savedByMe,
        commentsCount: commentsCount,
        status: status,
      );
}

class Comment {
  const Comment({
    required this.id,
    required this.postId,
    this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
    this.likes = 0,
  });

  final String id;
  final String postId;
  final String? authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String createdAt;
  final int likes;

  factory Comment.fromJson(Json j) => Comment(
        id: jStr(j, 'id'),
        postId: jStr(j, 'postId'),
        authorId: jStrN(j, 'authorId'),
        authorName: jStr(j, 'authorName'),
        authorAvatar: jStr(j, 'authorAvatar'),
        content: jStr(j, 'content'),
        createdAt: jStr(j, 'createdAt'),
        likes: jInt(j, 'likes'),
      );
}
