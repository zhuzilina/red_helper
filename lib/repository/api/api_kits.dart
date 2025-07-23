// 加载Token
import 'package:shared_preferences/shared_preferences.dart';

Future<String> loadToken() async {
  String token = '';
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token') ?? '';
    return token;
  } catch (e) {
    return token;
  }
}