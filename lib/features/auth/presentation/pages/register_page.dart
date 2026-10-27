import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/router/app_routes.dart';
import 'package:stockmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:stockmate/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:stockmate/features/auth/presentation/widgets/auth_form_scaffold.dart';
import 'package:stockmate/features/auth/presentation/widgets/auth_validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await context.read<AuthProvider>().signUp(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted || result == null) return;

    if (result.requiresEmailConfirmation) {
      context.go('${AppRoutes.login}?registered=true');
    } else {
      context.go(AppRoutes.root);
    }
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
      title: 'Create your account',
      subtitle: 'Set up your StockMate workspace in a few steps.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (errorMessage != null) ...[
                AuthErrorBanner(message: errorMessage),
                const SizedBox(height: 16),
              ],
              TextFormField(
                key: const Key('register_full_name'),
                controller: _fullNameController,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: AuthValidators.requiredFullName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('register_email'),
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
                key: const Key('register_password'),
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
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
                        ? 'Show passwords'
                        : 'Hide passwords',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: AuthValidators.requiredPassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('register_confirm_password'),
                controller: _confirmPasswordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password.';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
                onFieldSubmitted: isLoading ? null : (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('register_submit'),
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        context.read<AuthProvider>().clearError();
                        context.go(AppRoutes.login);
                      },
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
