import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:boardverse/core/theme/theme.dart';
import '../../data/datasources/base/lobby_remote_datasource.dart';
import '../../domain/entities/lobby_entity.dart';

class JoinByCodePage extends StatefulWidget {
  final LobbyRemoteDatasource remoteDatasource;
  final void Function(LobbyEntity lobby)? onJoined;
  final VoidCallback? onCancel;

  const JoinByCodePage({
    super.key,
    required this.remoteDatasource,
    this.onJoined,
    this.onCancel,
  });

  @override
  State<JoinByCodePage> createState() => _JoinByCodePageState();
}

class _JoinByCodePageState extends State<JoinByCodePage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    final text = _codeController.text.toUpperCase();
    if (text.length == 8 && text != _codeController.text) {
      _codeController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _joinLobby() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final code = _codeController.text.trim().toUpperCase();
    final result = await widget.remoteDatasource.joinLobbyByCode(code);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (lobby) {
        setState(() {
          _isLoading = false;
        });
        widget.onJoined?.call(lobby);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tham gia phòng'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: widget.onCancel ?? () => Navigator.pop(context),
        ),
      ),
      // SafeArea + padding gọn — chỉ chiếm phần giữa màn hình, không
      // phình to header illustration như bản cũ (icon 120×120 + 3 dòng
      // title/subtitle khiến UI chiếm hết viewport).
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Compact header — icon nhỏ + title ngắn gọn trên 1 dòng.
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: AppRadius.radiusMdAll,
                      ),
                      child: Icon(
                        Icons.link,
                        size: 20,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Nhập mã phòng 8 ký tự',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mã do chủ phòng chia sẻ qua Zalo, Messenger, …',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Code input — font vừa phải (titleLarge thay vì headlineMedium)
                // + contentPadding nhỏ để input cao vừa tay, không phình to.
                TextFormField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    UpperCaseTextFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: 'K7H3NP9X',
                    hintStyle: theme.textTheme.titleLarge?.copyWith(
                      color: colors.outline,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                    errorText: _errorMessage,
                    counterText: '',
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMdAll,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMdAll,
                      borderSide: BorderSide(
                        color: colors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMdAll,
                      borderSide: BorderSide(
                        color: colors.error,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mã phòng';
                    }
                    if (value.trim().length != 8) {
                      return 'Mã phòng phải có 8 ký tự';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _joinLobby(),
                ),

                const SizedBox(height: AppSpacing.md),

                // Join button — primary CTA. Đã bỏ button "Hủy" vì trên
                // AppBar đã có nút close (X) — UX tiêu chuẩn mobile, tránh
                // duplicate CTA cùng chức năng gây phình UI.
                FilledButton(
                  onPressed: _isLoading ? null : _joinLobby,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Tham gia'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Formatter để auto uppercase text input.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
