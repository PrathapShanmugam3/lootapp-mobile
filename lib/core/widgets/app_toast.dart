import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../network/api_client.dart';

enum ToastType { success, error, warning, info }

class _ToastStyle {
  const _ToastStyle(this.colors, this.icon, this.title);
  final List<Color> colors;
  final IconData icon;
  final String title;
}

const _styles = {
  ToastType.success: _ToastStyle([Color(0xFF34D399), Color(0xFF059669)], Icons.check_rounded, 'Success'),
  ToastType.error: _ToastStyle([Color(0xFFFB7185), Color(0xFFE11D48)], Icons.close_rounded, 'Something went wrong'),
  ToastType.warning: _ToastStyle([Color(0xFFFBBF24), Color(0xFFD97706)], Icons.priority_high_rounded, 'Heads up'),
  ToastType.info: _ToastStyle([Color(0xFFA855F7), Color(0xFF7C3AED)], Icons.info_outline_rounded, 'Note'),
};

OverlayEntry? _current;
GlobalKey<_ToastCardState>? _currentKey;

/// Branded floating toast shown at the top of the screen. Replaces any toast
/// already showing; dismissible by tap or swipe. Use instead of SnackBar.
void showToast(BuildContext context, String message, {ToastType type = ToastType.info, String? title, Duration? duration}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  _currentKey?.currentState?.dismiss(immediate: true);
  _current = null;

  switch (type) {
    case ToastType.error:
    case ToastType.warning:
      HapticFeedback.mediumImpact();
    case ToastType.success:
      HapticFeedback.lightImpact();
    case ToastType.info:
      break;
  }

  final key = GlobalKey<_ToastCardState>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastCard(
      key: key,
      message: message,
      title: title,
      style: _styles[type]!,
      duration: duration ?? (type == ToastType.error ? const Duration(milliseconds: 4200) : const Duration(milliseconds: 3000)),
      onRemoved: () {
        if (entry.mounted) entry.remove();
        if (identical(_current, entry)) {
          _current = null;
          _currentKey = null;
        }
      },
    ),
  );
  _current = entry;
  _currentKey = key;
  overlay.insert(entry);
}

void showSuccessToast(BuildContext context, String message, {String? title}) => showToast(context, message, type: ToastType.success, title: title);

void showInfoToast(BuildContext context, String message, {String? title}) => showToast(context, message, type: ToastType.info, title: title);

void showWarningToast(BuildContext context, String message, {String? title}) => showToast(context, message, type: ToastType.warning, title: title);

/// Error toast from a raw message or exception — turns Dio/Api exceptions
/// into a short human sentence instead of a stack-trace-looking string.
void showErrorToast(BuildContext context, Object error, {String? title}) => showToast(context, friendlyError(error), type: ToastType.error, title: title);

String friendlyError(Object error) {
  if (error is String) return error;
  if (error is ApiException) return error.message;
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again.';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The server is taking too long. Please try again.';
      default:
        final data = error.response?.data;
        if (data is Map && data['message'] != null) return data['message'].toString();
        return 'Request failed. Please try again.';
    }
  }
  final text = error.toString().replaceFirst(RegExp(r'^(\w*Exception|Error):\s*'), '').trim();
  return text.isEmpty ? 'Please try again.' : text;
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({super.key, required this.message, required this.title, required this.style, required this.duration, required this.onRemoved});

  final String message;
  final String? title;
  final _ToastStyle style;
  final Duration duration;
  final VoidCallback onRemoved;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 520), reverseDuration: const Duration(milliseconds: 220));
  late final AnimationController _life = AnimationController(vsync: this, duration: widget.duration);
  double _dragDy = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _enter.forward();
    _life.forward().whenComplete(() {
      if (mounted && _life.isCompleted) dismiss();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _life.dispose();
    super.dispose();
  }

  Future<void> dismiss({bool immediate = false}) async {
    if (_closing) return;
    _closing = true;
    _life.stop();
    if (!immediate && mounted) await _enter.reverse();
    widget.onRemoved();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;
    final accent = widget.style.colors.last;

    return Positioned(
      top: media.padding.top + 10,
      left: 14,
      right: 14,
      child: AnimatedBuilder(
        animation: _enter,
        builder: (context, child) {
          final t = reduceMotion ? _enter.value : (_enter.status == AnimationStatus.reverse ? Curves.easeIn.transform(_enter.value) : Curves.easeOutBack.transform(_enter.value));
          return Opacity(
            opacity: _enter.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * -70 + _dragDy),
              child: Transform.scale(scale: 0.94 + 0.06 * t.clamp(0.0, 1.0), child: child),
            ),
          );
        },
        child: GestureDetector(
          onTap: dismiss,
          onVerticalDragUpdate: (d) => setState(() => _dragDy = (_dragDy + d.delta.dy).clamp(-120.0, 20.0)),
          onVerticalDragEnd: (d) {
            if (_dragDy < -24 || (d.primaryVelocity ?? 0) < -300) {
              dismiss();
            } else {
              setState(() => _dragDy = 0);
            }
          },
          child: Dismissible(
            key: const ValueKey('toast'),
            direction: DismissDirection.horizontal,
            onDismissed: (_) => dismiss(immediate: true),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withValues(alpha: 0.16)),
                  boxShadow: [
                    BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: 24, offset: const Offset(0, 10)),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 6, 11),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.style.colors),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Icon(widget.style.icon, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title ?? widget.style.title,
                                  style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1C1235)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.message,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF6B6285), height: 1.35),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: dismiss,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9A92B4)),
                            tooltip: 'Dismiss',
                          ),
                        ],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _life,
                      builder: (_, __) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 1 - _life.value,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(gradient: LinearGradient(colors: widget.style.colors)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
