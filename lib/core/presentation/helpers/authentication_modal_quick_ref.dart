/// Quick reference for using AuthenticationRequiredBottomSheet
/// 
/// Import:
/// ```dart
/// import 'package:snip_fair/core/presentation/helpers/authentication_helpers.dart';
/// ```

/// ============================================================================
/// QUICK START - Most Common Pattern
/// ============================================================================

/// Pattern 1: Check auth before protected action
/// ```dart
/// onPressed: () async {
///   final appState = context.read<AppCubit>().state;
///   final isAuth = appState.status == AuthStatus.authenticated;
///
///   if (!await AuthenticationHelpers.checkAuthenticationRequired(
///     context,
///     isAuthenticated: isAuth,
///     title: 'Like this stylist',
///     subtitle: 'Save your favorites and get personalized recommendations.',
///   )) {
///     return; // User is not authenticated
///   }
///
///   // Perform the protected action
///   await performAction();
/// }
/// ```

/// ============================================================================
/// PATTERN 2: Just Show Modal
/// ============================================================================

/// ```dart
/// onPressed: () {
///   AuthenticationHelpers.showAuthenticationRequired(
///     context,
///     title: 'Book an appointment',
///     subtitle: 'Create an account to book with your favorite stylist.',
///   );
/// }
/// ```

/// ============================================================================
/// PATTERN 3: With Callbacks
/// ============================================================================

/// ```dart
/// onPressed: () {
///   AuthenticationHelpers.showAuthenticationRequired(
///     context,
///     title: 'Send a message',
///     subtitle: 'Connect with stylists to discuss your style.',
///     onLogin: () {
///       // Log event: user clicked login from message screen
///       analytics.logEvent('auth_modal_login_click', {
///         'action': 'send_message',
///       });
///     },
///     onSignup: () {
///       // Log event: user clicked signup from message screen
///       analytics.logEvent('auth_modal_signup_click', {
///         'action': 'send_message',
///       });
///     },
///   );
/// }
/// ```

/// ============================================================================
/// PATTERN 4: Get Return Value
/// ============================================================================

/// ```dart
/// onPressed: () async {
///   final result = await AuthenticationHelpers.showAuthenticationRequired(
///     context,
///     title: 'Rate this stylist',
///     subtitle: 'Share your experience with other users.',
///   );
///
///   if (result == 'login') {
///     log('User chose to login');
///   } else if (result == 'signup') {
///     log('User chose to signup');
///   } else {
///     log('User dismissed the modal');
///   }
/// }
/// ```

/// ============================================================================
/// COMMON PROTECTED ACTIONS & MESSAGES
/// ============================================================================

/// LIKING/FAVORITES
/// Title: 'Like this stylist'
/// Subtitle: 'Save your favorite stylists and get personalized recommendations.'
/// Icon: Icons.favorite_border (optional)

/// MESSAGING
/// Title: 'Send a message'
/// Subtitle: 'Connect with stylists to discuss your hair goals and preferences.'

/// BOOKING
/// Title: 'Book an appointment'
/// Subtitle: 'Reserve your time with your favorite stylist.'

/// REVIEWS
/// Title: 'Leave a review'
/// Subtitle: 'Share your experience to help other customers find great stylists.'

/// FOLLOWING
/// Title: 'Follow this stylist'
/// Subtitle: 'Get notified when they post new looks and offer special promotions.'

/// SAVING PREFERENCES
/// Title: 'Save your preferences'
/// Subtitle: 'Remember your style preferences for better recommendations.'

/// ============================================================================
/// KEY POINTS TO REMEMBER
/// ============================================================================

/// 1. Always check authentication status before showing modal:
///    - `appState.status == AuthStatus.authenticated`
///    - OR use `checkAuthenticationRequired()` helper

/// 2. Use `checkAuthenticationRequired()` for cleaner code:
///    - Combines the check and modal show in one call
///    - Returns bool indicating if user is authenticated
///    - Automatically handles navigation on button click

/// 3. The modal automatically handles navigation:
///    - Clicking "Sign In" → navigates to LoginRoute()
///    - Clicking "Sign Up" → navigates to SignupRoute()
///    - Clicking "Dismiss" → just closes modal

/// 4. Optional callbacks are for tracking/analytics:
///    - `onLogin` - triggered when user selects login
///    - `onSignup` - triggered when user selects signup
///    - Use for event tracking and analytics

/// 5. Customization:
///    - title: string
///    - subtitle: string  
///    - icon: IconData (defaults to Icons.lock_outline)
///    - onLogin/onSignup: VoidCallback (optional)

/// ============================================================================
