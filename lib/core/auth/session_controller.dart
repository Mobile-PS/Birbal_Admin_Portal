import 'package:flutter/foundation.dart';

import '../../data/models/otp_request_result.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../storage/token_store.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._authRepository, this._tokenStore);

  final AuthRepository _authRepository;
  final TokenStore _tokenStore;

  bool _ready = false;
  bool _signedIn = false;
  UserModel? _user;

  bool get isReady => _ready;
  bool get isSignedIn => _signedIn;
  UserModel? get user => _user;

  Future<void> bootstrap() async {
    final token = await _tokenStore.readToken();
    _signedIn = token != null && token.isNotEmpty;
    _user = _signedIn ? await _authRepository.currentUser() : null;
    _ready = true;
    notifyListeners();
  }

  Future<OtpRequestResult> requestOtp({
    required String identifier,
    required String type,
  }) {
    return _authRepository.requestOtp(identifier: identifier, type: type);
  }

  Future<UserModel> verifyOtp({
    required String identifier,
    required String otp,
    required String type,
  }) async {
    final user = await _authRepository.verifyOtp(
      identifier: identifier,
      otp: otp,
      type: type,
    );
    _user = user;
    _signedIn = true;
    notifyListeners();
    return user;
  }

  Future<void> logout() async {
    await _authRepository.logout();
    markSignedOut();
  }

  void markSignedOut() {
    if (!_signedIn && _user == null) return;
    _signedIn = false;
    _user = null;
    notifyListeners();
  }
}
