## 1.0.0

### Initial Release

App UI is a professional, production-ready Flutter UI component library inspired by shadcn/ui's philosophy.

#### Features

**Design System**
- Comprehensive design token system with centralized constants
- Complete color palette with primary, secondary, accent, semantic, and dark mode variants
- Typography system with headings, body text, and labels
- Standardized spacing scale (xs to xxxl)
- Border radius scale (sm to full)
- Elevation shadow definitions (sm to xl)
- Built-in light and dark theme support

**Components**
- **AppButton**: Primary, secondary, tertiary, ghost, icon, and custom variants with loading states
- **AppIconButton**: Circular icon-only buttons with multiple variants and sizes
- **AppTextField**: Outlined, filled, and underlined text inputs with validation and icons
- **AppDropdown**: Single and multi-select dropdowns with search functionality
- **AppCheckbox**: Checkboxes with labels, descriptions, and multiple variants
- **AppRadio**: Radio buttons with labels, descriptions, and multiple variants
- **AppDataCard**: Metric cards with change indicators, icons, gradients, and images
- **AppDialog**: Confirmation, success, error, warning, info, and custom dialogs
- **AppModal**: Customizable modal overlays

**Accessibility**
- WCAG AA compliant contrast ratios
- Minimum 44x44 pixel touch targets
- Semantic labels for screen readers
- Keyboard navigation support
- Focus indicators
- State announcements for assistive technologies

**Developer Experience**
- Factory constructor pattern for easy component creation
- Type-safe enums for variants and sizes
- Immutable widgets for predictable behavior
- Comprehensive dartdoc comments
- Extensive examples and documentation
- Zero manual styling through design tokens

#### Documentation

- Comprehensive README with quick start guide
- Detailed EXAMPLES.md with usage patterns for all components
- DESIGN_TOKENS.md guide explaining the token system
- Inline dartdoc comments on all public APIs
- Theme configuration examples
- Common UI patterns and best practices

#### Testing

- Property-based tests for component correctness
- Unit tests for component behavior
- Accessibility compliance testing
