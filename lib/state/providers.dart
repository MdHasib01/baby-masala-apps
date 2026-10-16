import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/token_store.dart';
import '../data/services/baby_care_api.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(tokens: ref.watch(tokenStoreProvider)));

final apiProvider = Provider<BabyCareApi>((ref) => BabyCareApi(ref.watch(apiClientProvider)));
