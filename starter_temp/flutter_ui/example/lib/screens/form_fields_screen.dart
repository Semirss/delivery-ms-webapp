import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:go_router/go_router.dart';

class FormFieldsScreen extends StatefulWidget {
  const FormFieldsScreen({super.key});

  @override
  State<FormFieldsScreen> createState() => _FormFieldsScreenState();
}

class _FormFieldsScreenState extends State<FormFieldsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _searchController = TextEditingController();

  String? _selectedCountry;
  List<String> _selectedHobbies = [];
  bool _agreeToTerms = false;
  String _selectedGender = 'male';
  bool _showPassword = false;

  final List<String> _countries = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'Brazil',
  ];

  final List<String> _hobbies = [
    'Reading',
    'Gaming',
    'Sports',
    'Music',
    'Cooking',
    'Travel',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && context.canPop()) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppAppBar(
          titleText: 'Form Fields',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildSection(
                context,
                title: 'Text Field Variants',
                children: [
                  AppTextField.outlined(
                    label: 'Outlined Field',
                    hint: 'Enter your name',
                    controller: _nameController,
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField.filled(
                    label: 'Filled Field',
                    hint: 'Enter your email',
                    controller: _emailController,
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField.underlined(
                    label: 'Underlined Field',
                    hint: 'Enter your phone',
                    controller: _phoneController,
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              _buildSection(
                context,
                title: 'Text Fields with Icons',
                children: [
                  AppTextField.outlined(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    prefixIcon: Icons.lock,
                    obscureText: !_showPassword,
                    suffixIcon: _showPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    onSuffixPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField.outlined(
                    label: 'Search',
                    hint: 'Search for anything...',
                    controller: _searchController,
                    prefixIcon: Icons.search,
                    suffixIcon: Icons.clear,
                    onSuffixPressed: () {
                      _searchController.clear();
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField.filled(
                    label: 'Amount',
                    hint: '0.00',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    suffixIcon: Icons.info_outline,
                    onSuffixPressed: () {
                      _showSnackBar(context, 'Enter amount in USD');
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              _buildSection(
                context,
                title: 'Text Field States',
                children: [
                  AppTextField.outlined(
                    label: 'Normal State',
                    hint: 'This is a normal field',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField.outlined(
                    label: 'Error State',
                    hint: 'This field has an error',
                    errorText: 'This field is required',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField.outlined(
                    label: 'Disabled State',
                    hint: 'This field is disabled',
                    enabled: false,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              _buildSection(
                context,
                title: 'Multi-line Text Field',
                children: [
                  AppTextField.outlined(
                    label: 'Bio',
                    hint: 'Tell us about yourself...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField.filled(
                    label: 'Comments',
                    hint: 'Enter your comments here...',
                    maxLines: 6,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              _buildSection(
                context,
                title: 'Dropdowns',
                children: [
                  AppDropdown<String>.medium(
                    label: 'Country',
                    items: _countries,
                    value: _selectedCountry,
                    onChanged: (value) {
                      setState(() => _selectedCountry = value);
                    },
                    itemBuilder: (country) => country,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppDropdown<String>.searchable(
                    label: 'Searchable Country',
                    items: _countries,
                    value: _selectedCountry,
                    searchHint: 'Search countries...',
                    onChanged: (value) {
                      setState(() => _selectedCountry = value);
                    },
                    itemBuilder: (country) => country,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppDropdown<String>.multiSelect(
                    label: 'Hobbies (Multi-select)',
                    items: _hobbies,
                    values: _selectedHobbies,
                    onMultiChanged: (values) {
                      setState(() => _selectedHobbies = values);
                    },
                    itemBuilder: (hobby) => hobby,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              _buildSection(
                context,
                title: 'Checkboxes',
                children: [
                  AppCheckbox.primary(
                    label: 'I agree to the terms and conditions',
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() => _agreeToTerms = value ?? false);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCheckbox.secondary(
                    label: 'Subscribe to newsletter',
                    description:
                        'Receive updates about new features and releases',
                    value: false,
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCheckbox.compact(
                    label: 'Remember me',
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              _buildSection(
                context,
                title: 'Radio Buttons',
                children: [
                  AppRadio<String>.primary(
                    label: 'Male',
                    value: 'male',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() => _selectedGender = value ?? 'male');
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppRadio<String>.primary(
                    label: 'Female',
                    value: 'female',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() => _selectedGender = value ?? 'male');
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppRadio<String>.primary(
                    label: 'Other',
                    description: 'Prefer not to say or other gender identity',
                    value: 'other',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() => _selectedGender = value ?? 'male');
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AppButton.primary(
                label: 'Submit Form',
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _showSnackBar(context, 'Form submitted successfully!');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.heading3.copyWith(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...children,
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    AppSnackBar.show(
      context: context,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }
}
