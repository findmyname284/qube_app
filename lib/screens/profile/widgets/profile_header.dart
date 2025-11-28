import 'package:flutter/material.dart';
import 'package:qube/models/me.dart';
import 'package:qube/screens/profile/widgets/skeletons/profile_header_skeleton.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.isLoading,
    required this.isLoggedIn,
    required this.profile,
    required this.showBalance,
    required this.onToggleBalance,
    this.onTopUp,
  });

  final bool isLoading;
  final bool isLoggedIn;
  final Profile? profile;
  final bool showBalance;
  final VoidCallback onToggleBalance;
  final VoidCallback? onTopUp;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const LoadingHeader();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161821).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarBadge(
                isLoggedIn: isLoggedIn,
                isConfirmed: profile?.isConfirmed ?? false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn ? (profile?.login ?? 'Пользователь') : 'Гость',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isLoggedIn
                          ? _Balance(
                              show: showBalance,
                              balance: profile!.amount,
                              bonusBalance: profile!.bonusAmount,
                              onToggle: onToggleBalance,
                            )
                          : const Text(
                              'Войдите для доступа ко всем функциям',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Кнопка внизу
          if (isLoggedIn) ...[
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFFA363D9)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTopUp,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Пополнить баланс',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFFA363D9)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTopUp,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Войти в аккаунт',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.isLoggedIn, required this.isConfirmed});
  final bool isLoggedIn;
  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isLoggedIn
                ? const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA363D9)],
                  )
                : LinearGradient(
                    colors: [
                      const Color(0xFF1E1F2E),
                      const Color(0xFF1E1F2E).withOpacity(0.8),
                    ],
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        if (isLoggedIn && isConfirmed)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF00B894),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x8000B894), blurRadius: 8)],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({
    required this.show,
    required this.balance,
    this.bonusBalance,
    required this.onToggle,
  });
  final bool show;
  final String balance;
  final String? bonusBalance;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1F2E).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              show ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  show ? 'Баланс: $balance ₸' : 'Баланс: ••••• ₸',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (bonusBalance != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    show ? 'Бонус: $bonusBalance ₸' : 'Бонус: ••••• ₸',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
