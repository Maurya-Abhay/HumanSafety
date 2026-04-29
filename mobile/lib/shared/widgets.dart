import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

// 1. PRIMARY BUTTON - Premium Smooth Ripple & Shadow
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 56, // Perfect premium height
      child: ElevatedButton(
        onPressed: isLoading || isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.white,
          disabledBackgroundColor: AppColors.grey.withOpacity(0.3),
          elevation: 0,
          splashFactory: InkRipple.splashFactory, // Smoother ripple effect
          shadowColor: (backgroundColor ?? AppColors.primary).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14), // Slightly refined curves
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith<double>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) return 0;
              if (states.contains(WidgetState.disabled)) return 0;
              return 4; // Gentle shadow when resting
            },
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5, // Reduced for premium typography
                ),
              ),
      ),
    );
  }
}

// 2. SECONDARY BUTTON - Outlined Minimalist
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final Color? color;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;
    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: themeColor.withOpacity(0.5), width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: themeColor,
          splashFactory: InkRipple.splashFactory,
        ).copyWith(
          side: WidgetStateProperty.resolveWith<BorderSide>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return BorderSide(color: themeColor, width: 2);
              }
              return BorderSide(color: themeColor.withOpacity(0.5), width: 1.5);
            },
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// 3. CUSTOM TEXT FIELD - Smooth Focus Transitions
class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType inputType;
  final bool isPassword;
  final bool readOnly;
  final bool filled;
  final Color? fillColor;
  final String? Function(String?)? validator;
  final int maxLines;
  final int minLines;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.inputType = TextInputType.text,
    this.isPassword = false,
    this.readOnly = false,
    this.filled = true,
    this.fillColor,
    this.validator,
    this.maxLines = 1,
    this.minLines = 1,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          obscureText: isPassword,
          readOnly: readOnly,
          maxLines: isPassword ? 1 : maxLines,
          minLines: minLines,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: isDark ? Colors.white30 : Colors.black38),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.primary, size: 22)
                : null,
            suffixIcon: suffixIcon,
            filled: filled,
            fillColor: fillColor ??
                (isDark
                    ? AppColors.greyDark.withOpacity(0.3)
                    : AppColors.greyLight.withOpacity(0.4)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

// 4. CUSTOM CARD - Animated Premium Card
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withOpacity(0.05),
        highlightColor: AppColors.primary.withOpacity(0.02),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: elevation ?? 15,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}

// 5. SOS BUTTON - Advanced Pulsing Animation
class SOSButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const SOSButton({
    super.key,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppColors.accent : AppColors.error;

    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => _controller.stop(),
      onTapUp: (_) => _controller.repeat(reverse: true),
      onTapCancel: () => _controller.repeat(reverse: true),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3 * _scaleAnimation.value),
                    blurRadius: 40 * _scaleAnimation.value,
                    spreadRadius: 15 * _scaleAnimation.value,
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.9),
                    color,
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 6. LOADING WIDGET - Smooth
class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
            strokeCap: StrokeCap.round, // Smooth edges on loader
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// 7. ERROR DISPLAY - Modernized
class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorDisplayWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 60, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              SecondaryButton(
                  label: 'Try Again', onPressed: onRetry!, width: 160)
            ]
          ],
        ),
      ),
    );
  }
}

// 8. CUSTOM BOTTOM NAV - Premium Edge-to-Edge Square Base with Custom Animations
// UPDATED: Pura Square aur Patla Footer
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<BottomNavItem> items;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // STICKY SQUARE DESIGN: No rounding at all
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            width: 1, // Ekdum patli line
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // PADDING REDUCED: Isse footer patla (sleek) dikhega
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return InkWell(
                // Modern touch feel
                onTap: onTap == null ? null : () => onTap!(index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade500,
                        size: 24, // Reduced size for premium look
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10, // Small & clean
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;
  const BottomNavItem({required this.icon, required this.label});
}

// 9. CUSTOM APP BAR - Glassmorphic Premium Feel
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final Widget? leadingWidget;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.leadingWidget,
    this.onBack,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glassmorphism
        child: AppBar(
          titleSpacing: 0,
          leadingWidth: showBackButton ? 64 : 120,
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 22),
                  onPressed: onBack ?? () => Navigator.pop(context),
                  splashRadius: 24,
                )
              : leadingWidget ?? _buildLogo(context),
          title: titleWidget ??
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
          centerTitle: true, // Center title looks much more premium
          elevation: 0,
          backgroundColor: (backgroundColor ?? AppColors.primary)
              .withOpacity(0.95), // Slight transparency for blur
          surfaceTintColor: Colors.transparent,
          actions: actions,
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: const Center(
              child: Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'LOGO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
