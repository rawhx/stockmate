import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/router/app_routes.dart';
import 'package:stockmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:stockmate/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:stockmate/features/auth/presentation/widgets/auth_form_scaffold.dart';
import 'package:stockmate/features/auth/presentation/widgets/auth_validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({this.showEmailVerificationMessage = false, super.key});

  final bool showEmailVerificationMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final success = await context.read<AuthProvider>().signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (success && mounted) context.go(AppRoutes.root);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>(
      (provider) => provider.isLoading,
    );
    final errorMessage = context.select<AuthProvider, String?>(
      (provider) => provider.errorMessage,
    );

    return AuthFormScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue managing your inventory.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showEmailVerificationMessage) ...[
                const _SuccessBanner(
                  message: 'Account created. Please check your email to verify your account.',
                ),
                const SizedBox(height: 16),
              ],
              if (errorMessage != null) ...[
                AuthErrorBanner(message: errorMessage),
                const SizedBox(height: 16),
              ],
              TextFormField(
                key: const Key('login_email'),
                controller: _emailController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: AuthValidators.requiredEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('login_password'),
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: isLoading
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: AuthValidators.requiredPassword,
                onFieldSubmitted: isLoading ? null : (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('login_submit'),
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        context.read<AuthProvider>().clearError();
                        context.go(AppRoutes.register);
                      },
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: TextStyle(color: colors.onPrimaryContainer)),
    );
  }
}
