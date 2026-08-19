import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';

class GoogleSignInHelper {
  static final GoogleSignIn _g = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: ApiConfig.googleWebClientId.isEmpty
        ? null
        : ApiConfig.googleWebClientId,
  );

  static bool get configured => ApiConfig.googleWebClientId.isNotEmpty;

  static Future<({String? idToken, String? accessToken})> signIn() async {
    final acc = await _g.signIn();
    if (acc == null) {
      throw Exception('Cancelaste Google');
    }
    final auth = await acc.authentication;
    if ((auth.idToken == null || auth.idToken!.isEmpty) &&
        (auth.accessToken == null || auth.accessToken!.isEmpty)) {
      throw Exception('Google no devolvió token');
    }
    return (idToken: auth.idToken, accessToken: auth.accessToken);
  }
}
