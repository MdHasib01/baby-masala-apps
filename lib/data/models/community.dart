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
    this.myReaction,
    this.reactionCounts = const {},
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
  /// 'like' | 'love' | 'haha' | 'care', or null when the viewer hasn't reacted.
  final String? myReaction;
  /// Reaction type → count (sums to [likes]).
  final Map<String, int> reactionCounts;
  final bool savedByMe;
  final int commentsCount;
  final String status; // 'approved' | 'pending' | 'rejected'

  /// Reaction types present on the post, most used first (for the summary row).
  List<String> get topReactions {
    final e = reactionCounts.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value - a.value);
    if (e.isEmpty && likes > 0) return const ['like'];
    return [for (final x in e) x.key];
  }

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
        myReaction: jStrN(j, 'myReaction') ?? (jBool(j, 'likedByMe') ? 'like' : null),
        reactionCounts: {
          for (final e in jMap(j, 'reactionCounts').entries)
            if (e.value is num) e.key: (e.value as num).toInt(),
        },
        savedByMe: jBool(j, 'savedByMe'),
        commentsCount: jInt(j, 'commentsCount'),
        status: jStr(j, 'status', 'approved'),
      );

  /// Optimistic local version of `POST /posts/:id/react {type}`: same type removes it,
  /// another type switches, none adds.
  Post withReaction(String type) {
    final counts = {...reactionCounts};
    final current = myReaction;
    void bump(String t, int by) => counts[t] = ((counts[t] ?? 0) + by).clamp(0, 1 << 30);
    String? next = type;
    var total = likes;
    if (current == type) {
      bump(type, -1);
      next = null;
      total--;
    } else if (current == null) {
      bump(type, 1);
      total++;
    } else {
      bump(current, -1);
      bump(type, 1);
    }
    return Post(
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
      likes: total.clamp(0, 1 << 30),
      likedByMe: next != null,
      myReaction: next,
      reactionCounts: counts,
      savedByMe: savedByMe,
      commentsCount: commentsCount,
      status: status,
    );
  }

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
        myReaction: myReaction,
        reactionCounts: reactionCounts,
        savedByMe: savedByMe ?? this.savedByMe,
        commentsCount: commentsCount,
        status: status,
      );
}

class Comment {
  const Comment({
    required this.id,
    required this.postId,
    this.parentId,
    this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
    this.likes = 0,
  });

  final String id;
  final String postId;
  /// Top-level comment this replies to; null for a top-level comment.
  final String? parentId;
  final String? authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String createdAt;
  final int likes;

  factory Comment.fromJson(Json j) => Comment(
        id: jStr(j, 'id'),
        postId: jStr(j, 'postId'),
        parentId: jStrN(j, 'parentId'),
        authorId: jStrN(j, 'authorId'),
        authorName: jStr(j, 'authorName'),
        authorAvatar: jStr(j, 'authorAvatar'),
        content: jStr(j, 'content'),
        createdAt: jStr(j, 'createdAt'),
        likes: jInt(j, 'likes'),
      );
}
