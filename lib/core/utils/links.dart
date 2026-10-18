import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/common.dart';
import '../config/env.dart';

/// Opens a web page in the browser.
Future<void> openUrl(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) toast(context, 'লিংকটি খোলা যায়নি: $url');
}

/// Opens the mail app addressed to support.
Future<void> emailSupport(BuildContext context, {String subject = 'Baby Care সাপোর্ট'}) async {
  final uri = Uri(scheme: 'mailto', path: Env.supportEmail, query: 'subject=${Uri.encodeComponent(subject)}');
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) toast(context, 'ইমেইল অ্যাপ পাওয়া যায়নি। লিখুন: ${Env.supportEmail}');
}

/// "1.0.0 (1)" from the installed package.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});
