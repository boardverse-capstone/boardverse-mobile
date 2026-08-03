import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shimmer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/topup_cubit.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import 'topup_page.dart';

/// Màn hình ví BVC - hiển thị số dư và lịch sử giao dịch
///
/// Đường dẫn: /wallet
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
      (failure) {
        // Handle error silently or show snackbar
      },
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
              // Refresh wallet after successful top-up
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví BVC'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WalletCubit>().refresh();
              _refreshTransactions();
            },
          ),
        ],
      ),
      body: BlocConsumer<WalletCubit, WalletState>(
        listener: (context, state) {
          if (state is WalletLoaded) {
            // Refresh transactions when wallet is refreshed
            _refreshTransactions();
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<WalletCubit>().refresh();
              await _refreshTransactions();
            },
            child: CustomScrollView(
              slivers: [
                // Balance Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: _buildBalanceSection(context, state),
                  ),
                ),

                // Transaction History Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lịch sử giao dịch',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to full transaction history
                          },
                          child: const Text('Xem tất cả'),
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
                          // Load more indicator
                          return Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Center(
                              child: TextButton(
                                onPressed: _loadMore,
                                child: const Text('Tải thêm'),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                      childCount: _transactions.length + (_hasMore ? 1 : 0),
                    ),
                  ),

                // Bottom padding
                SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToTopUp(100), // Default 100 BVC
        icon: const Icon(Icons.add),
        label: const Text('Nạp BVC'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                context.read<WalletCubit>().refresh();
              },
              child: const Text('Thử lại'),
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
      // Initial or unknown state - show placeholder
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
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Chưa có giao dịch nào',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Nạp BVC để bắt đầu sử dụng',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
