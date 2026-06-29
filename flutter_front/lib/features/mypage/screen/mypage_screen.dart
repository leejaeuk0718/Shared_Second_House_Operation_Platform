import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/mypage_provider.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyPageProvider>().fetchMyInfo();
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('로그아웃', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  void _showEditInfoSheet() {
    final provider = context.read<MyPageProvider>();
    final usernameController = TextEditingController(text: provider.username);
    final nicknameController = TextEditingController(text: provider.nickname);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Consumer<MyPageProvider>(
            builder: (ctx, mypageProvider, _) {
              return Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('정보 수정',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: '아이디'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '아이디를 입력해주세요';
                        if (!RegExp(r'^[a-zA-Z0-9]{4,20}$').hasMatch(v.trim())) {
                          return '아이디는 특수문자를 제외한 4~20자로 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nicknameController,
                      decoration: const InputDecoration(labelText: '닉네임'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '닉네임을 입력해주세요';
                        if (!RegExp(r'^[가-힣a-zA-Z0-9]{2,10}$').hasMatch(v.trim())) {
                          return '2~10자의 한글, 영문, 숫자만 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    if (mypageProvider.infoErrorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(mypageProvider.infoErrorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: mypageProvider.isUpdatingInfo
                          ? null
                          : () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await mypageProvider.updateInfo(
                          newUsername: usernameController.text.trim(),
                          newNickname: nicknameController.text.trim(),
                        );
                        if (success && ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: mypageProvider.isUpdatingInfo
                          ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2))
                          : const Text('저장'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showChangePasswordSheet() {
    final provider = context.read<MyPageProvider>();
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Consumer<MyPageProvider>(
            builder: (ctx, mypageProvider, _) {
              return Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('비밀번호 변경',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: currentPwController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '현재 비밀번호'),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? '현재 비밀번호를 입력해주세요' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPwController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '새 비밀번호'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '새 비밀번호를 입력해주세요';
                        if (!RegExp(
                            r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@#$%^&+=!])(?!.*\s).{8,16}$')
                            .hasMatch(v)) {
                          return '영문, 숫자, 특수문자를 포함해 8~16자로 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    if (mypageProvider.passwordErrorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(mypageProvider.passwordErrorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: mypageProvider.isUpdatingPassword
                          ? null
                          : () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await mypageProvider.updatePassword(
                          currentPassword: currentPwController.text,
                          newPassword: newPwController.text,
                        );
                        if (success && ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
                          );
                        }
                      },
                      child: mypageProvider.isUpdatingPassword
                          ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2))
                          : const Text('변경'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('탈퇴하면 계정 정보가 삭제되며 복구할 수 없어요. 계속하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('탈퇴', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final mypageProvider = context.read<MyPageProvider>();
    final success = await mypageProvider.withdraw();

    if (success && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } else if (mounted && mypageProvider.withdrawErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mypageProvider.withdrawErrorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('마이페이지')),
      body: Consumer<MyPageProvider>(
        builder: (context, provider, _) {
          if (provider.loadStatus == MyPageLoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadStatus == MyPageLoadStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('정보를 불러오지 못했어요.'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => provider.fetchMyInfo(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.nickname ?? '',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    _infoRow('아이디', provider.username ?? '-'),
                    _infoRow('이메일', provider.email ?? '-'),
                    _infoRow('휴대폰 번호', provider.phoneNumber ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _menuTile('정보 수정', Icons.edit_outlined, _showEditInfoSheet),
              _menuTile('비밀번호 변경', Icons.lock_outline, _showChangePasswordSheet),
              // 내 예약 추가
              _menuTile('내 예약', Icons.calendar_today_outlined,
                      () => Navigator.pushNamed(context, '/my/reservations')),
              // 내 구독 추가
              _menuTile('내 구독', Icons.home_outlined,
                      () => Navigator.pushNamed(context, '/my/subscriptions')),
              _menuTile('로그아웃', Icons.logout, _handleLogout),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: _handleWithdraw,
                  child: const Text('회원 탈퇴',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textPrimary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}