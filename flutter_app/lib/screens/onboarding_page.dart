import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressBar(isMobile),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildWelcomeStep(isMobile),
                    _buildExtensionStep(isMobile),
                    _buildSecurityStep(isMobile),
                  ],
                ),
              ),
              _buildFooter(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 12 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(_totalPages, (index) {
              final isActive = index <= _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                width: isActive ? (isMobile ? 20 : 24) : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: Text(
              'Skip',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Back', style: TextStyle(color: Colors.white70)),
            )
          else
            const SizedBox.shrink(),
          
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 32,
                vertical: isMobile ? 12 : 16,
              ),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  _currentPage == _totalPages - 1 ? 'Finish' : 'Next',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 1: WELCOME
  Widget _buildWelcomeStep(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology, size: isMobile ? 60 : 80, color: const Color(0xFF22D3EE)),
          ).animate().fadeIn().scale(),
          SizedBox(height: isMobile ? 32 : 40),
          Text(
            'Welcome to Reset AI',
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          Text(
            'Keep your focus sharp. We track your work context and help you recover flow quickly after distractions.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  // STEP 2: EXTENSION
  Widget _buildExtensionStep(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.extension_outlined, size: isMobile ? 60 : 80, color: const Color(0xFF10B981)),
          SizedBox(height: isMobile ? 32 : 40),
          Text(
            'Chrome Extension',
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Install our extension to track activity and get AI-powered deep cognitive resumes.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 24 : 32),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Open Link
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Chrome Web Store'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF10B981)),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 12 : 16,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: SECURITY (Simplified Set Password)
  Widget _buildSecurityStep(bool isMobile) {
    return _SecurityForm(onSuccess: _nextPage, isMobile: isMobile);
  }
}

class _SecurityForm extends StatefulWidget {
  final VoidCallback onSuccess;
  final bool isMobile;
  const _SecurityForm({required this.onSuccess, required this.isMobile});

  @override
  State<_SecurityForm> createState() => _SecurityFormState();
}

class _SecurityFormState extends State<_SecurityForm> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _setPassword() async {
    final pass = _passwordController.text;
    if (pass.length < 6) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final success = await auth.setPasswordForUser(pass);
    setState(() => _isLoading = false);

    if (success) {
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to set password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if password already set
    final auth = context.watch<AuthService>();
    if (auth.hasPassword) {
       return Padding(
        padding: EdgeInsets.all(widget.isMobile ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.check_circle_outline, size: widget.isMobile ? 60 : 80, color: Colors.green),
             const SizedBox(height: 24),
             Text(
              'All Set!',
              style: TextStyle(
                fontSize: widget.isMobile ? 24 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
             const SizedBox(height: 16),
             Text(
              'Your account is secure.',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
       );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isMobile ? 24 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: widget.isMobile ? 60 : 80, color: const Color(0xFFF59E0B)),
          SizedBox(height: widget.isMobile ? 24 : 32),
          Text(
            'Secure Account',
            style: TextStyle(
              fontSize: widget.isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Set a password for extension login.',
            style: TextStyle(
              fontSize: widget.isMobile ? 14 : 16,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: widget.isMobile ? 24 : 32),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Password (min 6 chars)',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock, color: Colors.white54, size: 20),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _setPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Text('Set Password', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
