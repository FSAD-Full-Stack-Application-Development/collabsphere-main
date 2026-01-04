import 'package:flutter/material.dart';
import '../theme.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool loading;
  final bool fullWidth;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.fullWidth = true,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          gradient:
              _isHovering ? AppTheme.gradientHover : AppTheme.gradientMain,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            _isHovering
                ? const BoxShadow(
                  color: Color(0x66E8B44C),
                  offset: Offset(0, 8),
                  blurRadius: 20,
                )
                : const BoxShadow(
                  color: Color(0x4DE8B44C),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child:
              widget.loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                  : Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    );
  }
}

class GradientLogo extends StatelessWidget {
  final double size;
  const GradientLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.gradientMain,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [AppTheme.shadowMd],
      ),
      alignment: Alignment.center,
      child: Text(
        'C',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
