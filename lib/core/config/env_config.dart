import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  /// 공유 링크가 붙는 공개 도메인. Cloudflare Worker가 여기서 받아
  /// Supabase 엣지 함수로 프록시한다(supabase.co는 HTML을 못 서빙함).
  /// 미설정이면 supabaseUrl로 폴백 - 링크는 열리지만 OG/랜딩이 깨진다.
  static String get shareLinkBase {
    if (!dotenv.isInitialized) return '';
    final v = dotenv.env['SHARE_LINK_BASE'] ?? '';
    return v.isNotEmpty ? v : supabaseUrl;
  }

  static String get supabaseAnonKey {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }
}
