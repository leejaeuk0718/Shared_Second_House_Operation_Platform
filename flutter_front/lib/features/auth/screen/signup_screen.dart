import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/signup_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9]{4,20}$');
  static final _passwordRegex =
  RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@#$%^&+=!])(?!.*\s).{8,16}$');
  static final _nicknameRegex = RegExp(r'^[가-힣a-zA-Z0-9]{2,10}$');
  static final _emailRegex = RegExp(r'\w+@\w+\.\w+(\.\w+)?');
  static final _phoneRegex = RegExp(r'^01(?:0|1|[6-9])[0-9]{7,8}$');

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final signupProvider = context.read<SignupProvider>();
    final success = await signupProvider.signup(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      nickname: _nicknameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해주세요.')),
      );
      Navigator.of(context).pop(); // 로그인 화면으로 복귀
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Consumer<SignupProvider>(
              builder: (context, signupProvider, _) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionLabel('아이디'),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          hintText: '영문, 숫자 4~20자',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '아이디를 입력해주세요';
                          }
                          if (!_usernameRegex.hasMatch(value.trim())) {
                            return '아이디는 특수문자를 제외한 4~20자 사이로 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildSectionLabel('비밀번호'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '영문, 숫자, 특수문자 포함 8~16자',
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호를 입력해주세요';
                          }
                          if (!_passwordRegex.hasMatch(value)) {
                            return '비밀번호는 영문, 숫자, 특수문자(@#\$%^&+=!)를 모두 포함해 8~16자로 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordConfirmController,
                        obscureText: _obscurePasswordConfirm,
                        decoration: InputDecoration(
                          hintText: '비밀번호 확인',
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePasswordConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() =>
                            _obscurePasswordConfirm = !_obscurePasswordConfirm),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호 확인을 입력해주세요';
                          }
                          if (value != _passwordController.text) {
                            return '비밀번호가 일치하지 않습니다';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildSectionLabel('닉네임'),
                      TextFormField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          hintText: '한글, 영문, 숫자 2~10자',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '닉네임을 입력해주세요';
                          }
                          if (!_nicknameRegex.hasMatch(value.trim())) {
                            return '닉네임은 2~10자의 한글, 영문, 숫자만 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildSectionLabel('이메일'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'example@email.com',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '이메일을 입력해주세요';
                          }
                          if (!_emailRegex.hasMatch(value.trim())) {
                            return '이메일 형식이 올바르지 않습니다.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildSectionLabel('휴대폰 번호'),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: "01012345678 (하이픈 없이)",
                        ),
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

                      if (signupProvider.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          signupProvider.errorMessage!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed:
                        signupProvider.isLoading ? null : _handleSignup,
                        child: signupProvider.isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.4),
                        )
                            : const Text('회원가입'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}