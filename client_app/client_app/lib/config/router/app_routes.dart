enum AppRoutes {
  // Main routes
  main(name: 'main', path: '/main'),
  home(name: 'home', path: '/home'),
  activity(name: 'activity', path: '/activity'),
  food(name: 'food', path: '/food'),

  // Auth routes
  auth(name: 'auth', path: '/auth'),
  login(name: 'login', path: '/login'),
  signUp(name: 'sign-up', path: '/sign-up'),
  otp(name: 'otp-verification', path: '/otp-verification'),
  resetPassword(name: 'reset-password', path: '/reset-password'),
  verifyReset(name: 'verify-reset', path: '/verify-reset'),

  // Init routes
  onBoarding(name: 'onBoarding', path: '/onBoarding'),
  language(name: 'language', path: '/language'),

  // Profile flow routes
  profileSelection(name: 'profileSelection', path: '/profile-selection'),
  profileSwitch(name: 'profileSwitch', path: '/profile-switch'),
  createProfile(name: 'createProfile', path: '/create-profile'),
  manageProfiles(name: 'manageProfiles', path: '/manage-profiles'),
  accountSettings(name: 'accountSettings', path: '/account-settings'),

  // Subscription routes
  choosePlan(name: 'choose-plan', path: '/choose-plan'),
  paymentIntro(name: 'payment-intro', path: '/payment-intro'),

  // Profile and settings
  profile(name: 'profile', path: '/profile'),
  setting(name: 'setting', path: '/setting'),
  changePin(name: 'changePin', path: '/change-pin'),
  personalDetails(name: 'personalDetails', path: '/personal-details'),
  notification(name: 'notification', path: '/notification'),
  search(name: 'search', path: 'search');

  const AppRoutes({required this.name, required this.path});

  final String name;
  final String path;
}
