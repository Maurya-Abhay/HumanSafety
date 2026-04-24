import 'package:flutter/material.dart';
import '../core/theme.dart';

// Button Widgets
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
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
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading || isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          disabledBackgroundColor: AppColors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: textColor ?? AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;

  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ...existing code...

// Input Field
class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType inputType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final int maxLines;
  final int minLines;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.inputType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.maxLines = 1,
    this.minLines = 1,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          obscureText: isPassword,
          maxLines: isPassword ? 1 : maxLines,
          minLines: minLines,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// Card Widget
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;

  const CustomCard({
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// Emergency SOS Button
class SOSButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const SOSButton({
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? AppColors.accent : AppColors.error,
          boxShadow: [
            BoxShadow(
              color: isActive ? AppColors.accent.withOpacity(0.5) : AppColors.error.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'SOS',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Loading indicator
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ]
        ],
      ),
    );
  }
}

// Error widget
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorWidget({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            PrimaryButton(label: 'Retry', onPressed: onRetry!)
          ]
        ],
      ),
    );
  }
}

// Bottom Navigation Bar
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  const CustomBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      items: items
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ))
          .toList(),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  BottomNavItem({required this.icon, required this.label});
}

// Custom App Bar
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    required this.title,
    this.onBack,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
