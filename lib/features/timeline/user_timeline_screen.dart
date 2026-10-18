import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/social.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/image_crop_screen.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';
import '../community/post_card.dart';
import '../community/post_composer.dart';

/// `activeTimelineTarget` in App.tsx.
class TimelineTarget {
  const TimelineTarget.me()
      : isMe = true,
        friend = null,
        authorName = null,
        authorId = null;
  const TimelineTarget.other({this.friend, this.authorName, this.authorId}) : isMe = false;

  final bool isMe;
  final FriendUser? friend;
  final String? authorName;
  final String? authorId;
}

const _defaultCover = 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?w=1200&auto=format&fit=crop&q=80';

/// Port of components/social/UserTimelineScreen.tsx.
class UserTimelineScreen extends ConsumerStatefulWidget {
  const UserTimelineScreen({super.key, required this.target});
  final TimelineTarget target;

  @override
  ConsumerState<UserTimelineScreen> createState() => _UserTimelineScreenState();
}

class _UserTimelineScreenState extends ConsumerState<UserTimelineScreen> {
  String _tab = 'posts';

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final me = d.user;
    final t = widget.target;
    final isMe = t.isMe || t.friend?.name == me.name || t.authorName == me.name || (t.authorId != null && t.authorId == me.id);

    // Resolve the friend record (or build a public profile from their posts).
    final name = isMe ? me.name : (t.friend?.name ?? t.authorName ?? '');
    final authorPosts = d.posts.where((p) => t.authorId != null ? p.authorId == t.authorId : p.authorName == name);
    final friend = isMe
        ? null
        : d.friends.where((f) => f.id == t.friend?.id || f.name == name).firstOrNull ??
            t.friend ??
            FriendUser(
              id: t.authorId ?? 'user-${name.hashCode.abs()}',
              name: name,
              avatar: authorPosts.firstOrNull?.authorAvatar ?? '',
              bio: 'মাতৃত্বের সুন্দর যাত্রায় বেবি কেয়ার কমিউনিটির একজন সদস্য।',
              location: 'ঢাকা, বাংলাদেশ',
              mutualFriendsCount: 3,
            );

    final avatar = isMe ? me.avatar : friend!.avatar;
    final bio = isMe ? ((me.bio?.isNotEmpty ?? false) ? me.bio! : 'মাতৃত্বের সুদিন ও শিশু পরিচর্যা নিয়ে আমার অভিজ্ঞতা।') : friend!.bio;
    final location = isMe
        ? ((me.location?.isNotEmpty ?? false) ? me.location! : (me.defaultAddress?.details ?? 'ঢাকা, বাংলাদেশ'))
        : friend!.location;
    final cover = isMe ? (me.coverPhoto?.isNotEmpty ?? false ? me.coverPhoto! : _defaultCover) : _defaultCover;
    final posts = isMe
        ? d.posts.where((p) => p.authorId == me.id || p.authorName == me.name).toList()
        : authorPosts.toList();
    final photos = posts.where((p) => p.mediaUrl != null && !p.isVideo).map((p) => p.mediaUrl!).toList();

    return Scaffold(
      appBar: AppBar(title: Text('$name - এর টাইমলাইন', overflow: TextOverflow.ellipsis)),
      body: ListView(padding: EdgeInsets.zero, children: [
        // ---- cover + avatar
        SizedBox(
          height: 230,
          child: Stack(children: [
            GestureDetector(
              onTap: () => isMe ? _photoMenu(cover: true, current: cover) : _viewPhoto(cover),
              child: NetImage(cover, height: 170, width: double.infinity),
            ),
            if (isMe)
              Positioned(
                right: 12,
                top: 124,
                child: _PhotoEditButton(tooltip: 'কভার ছবি পরিবর্তন', onTap: () => _photoMenu(cover: true, current: cover)),
              ),
            Positioned(
              left: 16,
              bottom: 0,
              child: GestureDetector(
                onTap: () => isMe ? _photoMenu(cover: false, current: avatar) : _viewPhoto(avatar),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                    child: AppAvatar(avatar, size: 100, ring: false),
                  ),
                  if (isMe)
                    Positioned(
                      right: 0,
                      bottom: 4,
                      child: _PhotoEditButton(tooltip: 'প্রোফাইল ছবি পরিবর্তন', onTap: () => _photoMenu(cover: false, current: avatar)),
                    ),
                ]),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(name, style: ts(20, weight: FontWeight.w800, color: AppColors.maroon))),
              const SizedBox(width: 6),
              const Icon(LucideIcons.shieldCheck, size: 18, color: AppColors.gold),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(LucideIcons.mapPin, size: 13, color: AppColors.grey500),
              const SizedBox(width: 4),
              Expanded(child: Text(location, style: ts(12, color: AppColors.grey600))),
            ]),
            Text(isMe ? '${toBnDigits(d.friends.where((f) => f.friendshipStatus == 'friends').length)} জন ফ্রেন্ড' : '${toBnDigits(friend!.mutualFriendsCount + 2)} জন ফ্রেন্ড',
                style: ts(12, weight: semi, color: AppColors.olive)),
            const SizedBox(height: 12),
            if (isMe)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _editProfile(),
                  icon: const Icon(LucideIcons.pencil, size: 15),
                  label: const Text('প্রোফাইল এডিট করুন'),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.sand))),
          child: Row(children: [
            _tabBtn('posts', 'পোস্ট (${toBnDigits(posts.length)})'),
            _tabBtn('about', 'পরিচিতি'),
            _tabBtn('photos', 'ছবি (${toBnDigits(photos.length)})'),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: switch (_tab) {
            'about' => _about(bio, location, dob: isMe ? me.dateOfBirth : null),
            'photos' => _photos(photos),
            _ => Column(children: [
                if (isMe) _composer(me.avatar),
                if (posts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('এই টাইমলাইনে এখনো কোনো পোস্ট নেই।', style: ts(12.5, color: AppColors.grey500)),
                  ),
                for (final p in posts) PostCard(key: ValueKey(p.id), post: p),
              ]),
          },
        ),
      ]),
    );
  }

  Widget _tabBtn(String id, String label) => Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _tab == id ? AppColors.maroon : Colors.transparent, width: 3)),
            ),
            alignment: Alignment.center,
            child: Text(label, style: ts(12.5, weight: bold, color: _tab == id ? AppColors.maroon : AppColors.grey500)),
          ),
        ),
      );

  Widget _composer(String avatar) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          padding: const EdgeInsets.all(12),
          onTap: () => showPostComposer(context, fixedTopic: 'মায়ের গল্প'),
          child: Row(children: [
            AppAvatar(avatar, size: 36),
            const SizedBox(width: 10),
            Expanded(child: Text('আজ আপনার মনে কী চলছে, আপু?', style: ts(12.5, color: AppColors.grey500))),
            const Icon(LucideIcons.image, size: 18, color: AppColors.olive),
          ]),
        ),
      );

  Widget _about(String bio, String location, {String? dob}) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('মায়ের পরিচিত ও বিবরণী', style: ts(14, weight: bold, color: AppColors.maroon)),
          const SizedBox(height: 12),
          Text('জীবনী / বায়ো', style: ts(11, weight: bold, color: AppColors.grey500)),
          Text(bio, style: ts(13, height: 1.5)),
          const SizedBox(height: 10),
          Text('এলাকা', style: ts(11, weight: bold, color: AppColors.grey500)),
          Text(location, style: ts(13)),
          if (dob != null && dob.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('জন্মতারিখ (শুধু আপনি দেখতে পারবেন)', style: ts(11, weight: bold, color: AppColors.grey500)),
            Text(formatBnDate(dob), style: ts(13)),
          ],
          const SizedBox(height: 14),
          const InfoBox(
            'গোপনীয়তা নীতি অনুযায়ী শিশুর জন্মতারিখ, এলার্জি তথ্য, অর্ডার হিস্ট্রি এবং ডাক্তার কনভার্সেশন টাইমলাইনে প্রদর্শিত হয় না।',
            icon: LucideIcons.shieldAlert,
            bg: AppColors.blue50,
            fg: AppColors.blue600,
          ),
        ]),
      );

  Widget _photos(List<String> photos) {
    if (photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('এই টাইমলাইনে কোনো ছবি নেই।', style: ts(12.5, color: AppColors.grey500)),
      );
    }
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (final url in photos)
          GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: InteractiveViewer(child: Center(child: NetImage(url, fit: BoxFit.contain))),
              ),
            ),
            child: NetImage(url, radius: 8),
          ),
      ],
    );
  }

  Future<void> _editProfile() =>
      showAppSheet<void>(context, title: 'প্রোফাইল এডিট করুন', builder: (_) => const _EditProfile());

  void _viewPhoto(String url) => showDialog<void>(
        context: context,
        builder: (ctx) => GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(child: Center(child: NetImage(url, fit: BoxFit.contain))),
        ),
      );

  /// Facebook-style: tap the photo or its pencil → view / upload new → crop → saved right away.
  Future<void> _photoMenu({required bool cover, required String current}) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(LucideIcons.eye),
            title: Text(cover ? 'কভার ছবি দেখুন' : 'প্রোফাইল ছবি দেখুন'),
            onTap: () => Navigator.pop(ctx, 'view'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.imageUp),
            title: Text(cover ? 'নতুন কভার ছবি দিন' : 'নতুন প্রোফাইল ছবি দিন'),
            onTap: () => Navigator.pop(ctx, 'upload'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'view') return _viewPhoto(current);

    try {
      final url = cover
          ? await pickAndCropImage(context, aspectRatio: _coverAspect, outputWidth: 1280, title: 'কভার ছবি ঠিক করুন')
          : await pickAndCropImage(context, circle: true, outputWidth: 500, title: 'প্রোফাইল ছবি ঠিক করুন');
      if (url == null || !mounted) return;
      final data = ref.read(appDataProvider.notifier);
      final me = ref.read(dataProvider).user;
      final saved = await ref.read(apiProvider).updateProfile(cover ? me.copyWith(coverPhoto: url) : me.copyWith(avatar: url));
      data.setUserFromServer(saved);
      if (mounted) toast(context, cover ? 'কভার ছবি আপডেট হয়েছে।' : 'প্রোফাইল ছবি আপডেট হয়েছে।');
      // The avatar is copied onto posts & comments server-side.
      if (!cover) await data.refreshQuietly();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }
}

/// Cover frame shape — matches the 170 px tall cover on a ~360 px wide timeline.
const _coverAspect = 2.1;

/// Small round pencil button over a photo (Facebook-style, icon only).
class _PhotoEditButton extends StatelessWidget {
  const _PhotoEditButton({required this.onTap, required this.tooltip});

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.cream,
          shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(7),
              child: Icon(LucideIcons.pencil, size: 15, color: AppColors.maroon),
            ),
          ),
        ),
      );
}

/// Edit profile → `PATCH /me` (debounced via setUser).
class _EditProfile extends ConsumerStatefulWidget {
  const _EditProfile();

  @override
  ConsumerState<_EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<_EditProfile> {
  late final user = ref.read(dataProvider).user;
  late final _name = TextEditingController(text: user.name);
  late final _bio = TextEditingController(text: user.bio ?? '');
  late final _location = TextEditingController(text: user.location ?? '');
  late String _dob = user.dateOfBirth ?? '';
  late String _avatar = user.avatar;
  late String _cover = user.coverPhoto?.isNotEmpty ?? false ? user.coverPhoto! : _defaultCover;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final url = await pickAndCropImage(context, circle: true, outputWidth: 500, title: 'প্রোফাইল ছবি ঠিক করুন');
      if (url != null) setState(() => _avatar = url);
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _pickCover() async {
    try {
      final url = await pickAndCropImage(context, aspectRatio: _coverAspect, outputWidth: 1280, title: 'কভার ছবি ঠিক করুন');
      if (url != null) setState(() => _cover = url);
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dob) ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 12),
    );
    if (picked != null) setState(() => _dob = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      toast(context, 'নাম খালি রাখা যাবে না।');
      return;
    }
    final d = ref.read(dataProvider);
    final data = ref.read(appDataProvider.notifier);
    try {
      // Saved immediately (not debounced): the server also rewrites
      // the name/avatar copies on posts & comments, so we refresh.
      final saved = await ref.read(apiProvider).updateProfile(d.user.copyWith(
            name: _name.text.trim(),
            bio: _bio.text.trim(),
            location: _location.text.trim(),
            dateOfBirth: _dob,
            avatar: _avatar,
            coverPhoto: _cover,
          ));
      data.setUserFromServer(saved);
      if (mounted) {
        Navigator.pop(context);
        toast(context, 'প্রোফাইল আপডেট হয়েছে।');
      }
      await data.refreshQuietly();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ---- cover + avatar, laid out like the timeline header
      Stack(clipBehavior: Clip.none, children: [
        GestureDetector(
          onTap: _pickCover,
          child: AspectRatio(aspectRatio: _coverAspect, child: NetImage(_cover, width: double.infinity, radius: 12)),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: _PhotoEditButton(tooltip: 'কভার ছবি পরিবর্তন', onTap: _pickCover),
        ),
        Positioned(
          left: 12,
          bottom: -44,
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Stack(children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                child: AppAvatar(_avatar, size: 92, ring: false),
              ),
              Positioned(
                right: 0,
                bottom: 2,
                child: _PhotoEditButton(tooltip: 'প্রোফাইল ছবি পরিবর্তন', onTap: _pickAvatar),
              ),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 56),
      const FieldLabel('মায়ের নাম'),
      TextField(controller: _name, maxLength: 80, decoration: const InputDecoration(counterText: '')),
      const SizedBox(height: 8),
      const FieldLabel('সংক্ষিপ্ত বায়ো'),
      TextField(
        controller: _bio,
        minLines: 2,
        maxLines: 4,
        maxLength: 500,
        decoration: const InputDecoration(hintText: 'নিজের সম্পর্কে কিছু লিখুন', counterText: ''),
      ),
      const SizedBox(height: 8),
      const FieldLabel('এলাকা'),
      TextField(
        controller: _location,
        maxLength: 120,
        decoration: const InputDecoration(
          hintText: 'যেমন: মিরপুর, ঢাকা',
          counterText: '',
          prefixIcon: Icon(LucideIcons.mapPin, size: 17),
        ),
      ),
      const SizedBox(height: 8),
      const FieldLabel('জন্মতারিখ'),
      InkWell(
        onTap: _pickDob,
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.cake, size: 17),
            suffixIcon: _dob.isEmpty
                ? const Icon(LucideIcons.calendar, size: 18)
                : IconButton(
                    tooltip: 'মুছুন',
                    onPressed: () => setState(() => _dob = ''),
                    icon: const Icon(LucideIcons.x, size: 16),
                  ),
          ),
          child: Text(_dob.isEmpty ? 'তারিখ নির্বাচন করুন' : formatBnDate(_dob),
              style: ts(13, color: _dob.isEmpty ? AppColors.grey400 : null)),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text('জন্মতারিখ শুধু আপনি দেখতে পারবেন।', style: ts(10.5, color: AppColors.grey500)),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল'))),
        const SizedBox(width: 10),
        Expanded(child: BusyButton(label: 'সংরক্ষণ করুন', onPressed: _save)),
      ]),
    ]);
  }
}
