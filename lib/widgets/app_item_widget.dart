import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_info.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../services/cache_service.dart';

class AppItemWidget extends StatefulWidget {
  final AppInfo app;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool animationsEnabled;

  const AppItemWidget({
    super.key,
    required this.app,
    required this.onTap,
    required this.onLongPress,
    this.animationsEnabled = true,
  });

  @override
  State<AppItemWidget> createState() => _AppItemWidgetState();
}

class _AppItemWidgetState extends State<AppItemWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Keep widget alive for better performance
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  // OPTIMIZED: Icon loading state
  Widget? _cachedIconWidget;
  bool _isLoadingIcon = false;
  final CacheService _cacheService = CacheService.instance;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadIconIfNeeded();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: Duration(
        milliseconds: widget.animationsEnabled ? AppConstants.animationDurationMs : 0,
      ),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  // OPTIMIZED: Load icon with caching
  Future<void> _loadIconIfNeeded() async {
    if (widget.app.icon != null) {
      _buildIconWidget();
      return;
    }

    if (_isLoadingIcon) return;
    
    setState(() {
      _isLoadingIcon = true;
    });

    try {
      // Try to get icon from cache first
      final cachedIcon = await _cacheService.getCachedAppIcon(widget.app.packageName);
      if (cachedIcon != null && mounted) {
        widget.app.copyWith(icon: cachedIcon);
        _buildIconWidget();
        setState(() {
          _isLoadingIcon = false;
        });
        return;
      }

      // If no cached icon, it will be loaded by the background service
      if (mounted) {
        setState(() {
          _isLoadingIcon = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading icon for ${widget.app.packageName}: $e');
      if (mounted) {
        setState(() {
          _isLoadingIcon = false;
        });
      }
    }
  }

  // OPTIMIZED: Build and cache icon widget
  void _buildIconWidget() {
    if (widget.app.icon != null) {
      _cachedIconWidget = Image.memory(
        widget.app.icon!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium, // Balance quality vs performance
        isAntiAlias: true,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Icon error for ${widget.app.packageName}: $error');
          return _buildFallbackIcon(Provider.of<ThemeProvider>(context, listen: false));
        },
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.animationsEnabled) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.animationsEnabled) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.animationsEnabled) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isPressed
                        ? themeProvider.getSurfaceColor(context).withOpacity(0.5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // OPTIMIZED: App icon with better loading
                      Container(
                        width: themeProvider.iconSize,
                        height: themeProvider.iconSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            themeProvider.iconSize * 0.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08), // Lighter shadow
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            themeProvider.iconSize * 0.2,
                          ),
                          child: _buildIconContent(themeProvider),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingSmall),
                      
                      // OPTIMIZED: App name with better text rendering
                      SizedBox(
                        width: themeProvider.iconSize + 8,
                        child: Text(
                          widget.app.displayName,
                          style: TextStyle(
                            color: themeProvider.getTextColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.2, // Better line height
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // OPTIMIZED: Status indicators
                      if (widget.app.isFavorite || widget.app.launchCount > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.app.isFavorite)
                                Icon(
                                  Icons.favorite,
                                  size: 10,
                                  color: Colors.red.withOpacity(0.7),
                                ),
                              if (widget.app.isFavorite && widget.app.launchCount > 5)
                                const SizedBox(width: 2),
                              if (widget.app.launchCount > 5)
                                Icon(
                                  Icons.star,
                                  size: 10,
                                  color: Colors.amber.withOpacity(0.7),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // OPTIMIZED: Icon content with loading states
  Widget _buildIconContent(ThemeProvider themeProvider) {
    if (_cachedIconWidget != null) {
      return _cachedIconWidget!;
    }
    
    if (_isLoadingIcon) {
      return _buildLoadingIcon(themeProvider);
    }
    
    if (widget.app.icon != null) {
      _buildIconWidget();
      return _cachedIconWidget ?? _buildFallbackIcon(themeProvider);
    }
    
    return _buildFallbackIcon(themeProvider);
  }

  // OPTIMIZED: Loading icon placeholder
  Widget _buildLoadingIcon(ThemeProvider themeProvider) {
    return Container(
      width: themeProvider.iconSize,
      height: themeProvider.iconSize,
      decoration: BoxDecoration(
        color: themeProvider.getSurfaceColor(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(themeProvider.iconSize * 0.2),
      ),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  // OPTIMIZED: Better fallback icon
  Widget _buildFallbackIcon(ThemeProvider themeProvider) {
    return Container(
      width: themeProvider.iconSize,
      height: themeProvider.iconSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeProvider.getSurfaceColor(context),
            themeProvider.getSurfaceColor(context).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(themeProvider.iconSize * 0.2),
      ),
      child: Icon(
        _getAppIcon(),
        size: themeProvider.iconSize * 0.5,
        color: themeProvider.getTextColor(context).withOpacity(0.6),
      ),
    );
  }

  // Get appropriate icon based on app type
  IconData _getAppIcon() {
    final packageName = widget.app.packageName.toLowerCase();
    
    if (packageName.contains('camera')) return Icons.camera_alt;
    if (packageName.contains('music') || packageName.contains('spotify')) return Icons.music_note;
    if (packageName.contains('video') || packageName.contains('youtube')) return Icons.play_arrow;
    if (packageName.contains('message') || packageName.contains('sms')) return Icons.message;
    if (packageName.contains('phone') || packageName.contains('call')) return Icons.phone;
    if (packageName.contains('browser') || packageName.contains('chrome')) return Icons.web;
    if (packageName.contains('email') || packageName.contains('gmail')) return Icons.email;
    if (packageName.contains('calendar')) return Icons.calendar_today;
    if (packageName.contains('calculator')) return Icons.calculate;
    if (packageName.contains('settings')) return Icons.settings;
    if (packageName.contains('gallery') || packageName.contains('photos')) return Icons.photo;
    if (packageName.contains('maps')) return Icons.map;
    if (packageName.contains('weather')) return Icons.wb_sunny;
    if (packageName.contains('game')) return Icons.games;
    
    return Icons.android;
  }

  @override
  void didUpdateWidget(AppItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reload icon if app changed
    if (oldWidget.app.packageName != widget.app.packageName) {
      _cachedIconWidget = null;
      _loadIconIfNeeded();
    }
    
    // Update cached icon if icon data changed
    if (oldWidget.app.icon != widget.app.icon && widget.app.icon != null) {
      _buildIconWidget();
    }
  }
} 