import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

/// 의견 보내기. 컨트롤러를 State에 보관(build마다 재생성돼 입력이 사라지던 버그 수정) +
/// mailto(메일앱 없으면 실패) 대신 서버(feedback 테이블) 저장.
class FeedbackModal extends ConsumerStatefulWidget {
  const FeedbackModal({super.key});

  @override
  ConsumerState<FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends ConsumerState<FeedbackModal> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    try {
      final user = ref.read(authProvider).value;

      // 디바이스 정보(선택, 실패해도 본문은 보냄).
      String deviceId = '';
      String os = '';
      String appVersion = '';
      try {
        final di = DeviceInfoPlugin();
        appVersion = (await PackageInfo.fromPlatform()).version;
        if (isIOS) {
          final info = await di.iosInfo;
          deviceId = info.identifierForVendor ?? '';
          os = '${info.systemName} ${info.systemVersion}';
        } else {
          final info = await di.androidInfo;
          deviceId = info.id;
          os = 'Android ${info.version.release}';
        }
      } catch (_) {/* noop */}

      await Supabase.instance.client.from('feedback').insert({
        'user_id': user?.id,
        'content': text,
        'email': user?.email,
        'device_id': deviceId,
        'os': os,
        'app_version': appVersion,
      });

      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(
        content: Text('의견 보내주셔서 감사해요', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF242424),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(const SnackBar(
        content: Text('의견을 보내는 중 문제가 생겼어요. 잠시 후 다시 시도해요',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF242424),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '의견 남기기',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLength: 500,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              enableInteractiveSelection: true,
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '의견을 입력해주세요',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _sending ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('취소하기', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: _sending ? null : _send,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('보내기', style: TextStyle(color: Colors.black, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
