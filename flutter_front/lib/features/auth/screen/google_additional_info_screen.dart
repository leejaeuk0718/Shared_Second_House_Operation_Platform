import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/google_signin_provider.dart';

class GoogleAdditionalInfoScreen extends StatefulWidget {
  const GoogleAdditionalInfoScreen({super.key});

  @override
  State<GoogleAdditionalInfoScreen> createState() =>
      _GoogleAdditionalInfoScreenState();
}

class _GoogleAdditionalInfoScreenState
    extends State<GoogleAdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  static final _phoneRegex = RegExp(r'^01(?:0|1|[6-9])[0-9]{7,8}$');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<GoogleSignInProvider>();
    final success =
    await provider.completeSignUpWithPhoneNumber(_phoneController.text.trim());

    if (success && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoogleSignInProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('추가 정보 입력')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${provider.pendingNickname ?? ''}님, 반가워요!',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.pendingEmail ?? '',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                const Text('휴대폰 번호',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                  const InputDecoration(hintText: '01012345678 (하이픈 없이)'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '휴대폰 번호를 입력해주세요';
                    }
                    if (!_phoneRegex.hasMatch(value.trim())) {
                      return '올바른 휴대폰 번호 형식이 아닙니다.';
                    }
                    return null;
                  },
                ),
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: provider.step == GoogleSignInStep.submitting
                      ? null
                      : _handleSubmit,
                  child: provider.step == GoogleSignInStep.submitting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.4),
                  )
                      : const Text('가입 완료'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}