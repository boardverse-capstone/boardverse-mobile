import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shimmer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/topup_cubit.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import 'topup_page.dart';

/// Neo-brutalism Màn hình ví BVC.
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.I<WalletCubit>()..loadWallet(includeHeld: true),
        ),
      ],
      child: const _WalletPageContent(),
    );
  }
}

class _WalletPageContent extends StatefulWidget {
  const _WalletPageContent();

  @override
  State<_WalletPageContent> createState() => _WalletPageContentState();
}

class _WalletPageContentState extends State<_WalletPageContent> {
  final List<TransactionEntity> _transactions = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final repository = GetIt.I<WalletRepository>();
    final result = await repository.getTransactions(
      page: _currentPage,
      pageSize: _pageSize,
    );

    result.fold(
      (failure) {},
      (transactions) {
        setState(() {
          if (_currentPage == 1) {
            _transactions.clear();
          }
          _transactions.addAll(transactions);
          _hasMore = transactions.length >= _pageSize;
        });
      },
    );
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadTransactions();

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _navigateToTopUp(int amountBvc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => TopUpCubit(repository: GetIt.I<WalletRepository>()),
          child: TopUpPage(
            initialAmountVnd: amountBvc * 1000,
            onSuccess: () {
              context.read<WalletCubit>().refresh();
              _refreshTransactions();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _refreshTransactions() async {
    setState(() {
      _currentPage = 1;
    });
    await _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'VÍ BVC',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.black,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.black,
                  blurRadius: 0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.black, size: 20),
              onPressed: () {
                context.read<WalletCubit>().refresh();
                _refreshTransactions();
              },
            ),
          ),
        ],
      ),
      body: BlocConsumer<WalletCubit, WalletState>(
        listener: (context, state) {
          if (state is WalletLoaded) {
            _refreshTransactions();
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context.read<WalletCubit>().refresh();
              await _refreshTransactions();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Balance Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _buildBalanceSection(context, state),
                  ),
                ),

                // Transaction History Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LỊCH SỬ GIAO DỊCH',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.secondary,
                              width: 1.5,
                            ),
                          ),
                          child: const Text(
                            'XEM TẤT CẢ',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Transaction List
                if (_transactions.isEmpty && !_isLoadingMore)
                  SliverToBoxAdapter(
                    child: _buildEmptyTransactions(textTheme),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < _transactions.length) {
                          return TransactionTile(
                            transaction: _transactions[index],
                          );
                        } else if (_hasMore) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: NeoBrutalismTheme.borderWidth,
                                ),
                                boxShadow: NeoBrutalismTheme.lightShadow(
                                  shadowColor:
                                      AppColors.black.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _loadMore,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      'TẢI THÊM',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                      childCount: _transactions.length + (_hasMore ? 1 : 0),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.black, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppColors.black,
              blurRadius: 0,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'wallet_topup_fab',
          onPressed: () => _navigateToTopUp(100),
          icon: const Icon(Icons.add, color: AppColors.white),
          label: const Text(
            'NẠP BVC',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildBalanceSection(BuildContext context, WalletState state) {
    if (state is WalletLoading) {
      return AppShimmer.box(
        context: context,
        height: 200,
        width: double.infinity,
      );
    }

    if (state is WalletError) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error, width: 2),
          boxShadow: NeoBrutalismTheme.lightShadow(
            shadowColor: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.black, width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    context.read<WalletCubit>().refresh();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'THỬ LẠI',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    WalletEntity wallet;
    if (state is WalletLoaded) {
      wallet = state.wallet;
    } else if (state is WalletInsufficientBalance) {
      wallet = state.wallet;
    } else {
      wallet = const WalletEntity(
        userId: '',
        availableBalance: 0,
        heldBalance: 0,
        riskLevel: RiskLevel.low,
        isCoolingOff: false,
        accountStatus: AccountStatus.active,
      );
    }

    return BalanceCard(
      wallet: wallet,
      onTopUpPressed: () => _navigateToTopUp(100),
    );
  }

  Widget _buildEmptyTransactions(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'CHƯA CÓ GIAO DỊCH NÀO',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nạp BVC để bắt đầu sử dụng',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}