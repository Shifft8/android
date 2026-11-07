// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get confirmDelete => 'Are you sure you want to delete this address?';

  @override
  String get appTitle => 'Address Manager';

  @override
  String get welcomeMessage => 'Welcome to Address Manager!';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Russian';

  @override
  String get languagePolish => 'Polish';

  @override
  String get languageUkrainian => 'Ukrainian';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get login => 'Login';

  @override
  String get loginButton => 'Sign in';

  @override
  String get register => 'Register';

  @override
  String get registerButton => 'Sign up';

  @override
  String get registerButtonFull => 'Sign up';

  @override
  String get logoutButton => 'Logout';

  @override
  String get profile => 'Profile';

  @override
  String get noProfileData => 'No profile data';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get phone => 'Phone';

  @override
  String get country => 'Country';

  @override
  String get city => 'City';

  @override
  String get email => 'Email';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get notes => 'Notes';

  @override
  String get noNotes => 'No notes';

  @override
  String get newNote => 'New note';

  @override
  String get addNote => 'Add note';

  @override
  String get editNote => 'Edit note';

  @override
  String get deleteNoteQuestion => 'Delete note?';

  @override
  String get deleteNoteWarning => 'This action cannot be undone.';

  @override
  String get addresses => 'Addresses';

  @override
  String get addressList => 'Address list';

  @override
  String get addAddress => 'Add address';

  @override
  String get editAddress => 'Edit address';

  @override
  String get noAddresses => 'No addresses found';

  @override
  String get noAddressesYet => 'No addresses yet';

  @override
  String get myAddresses => 'My addresses';

  @override
  String get address => 'Address';

  @override
  String get addressDetails => 'Address details';

  @override
  String get houseNumber => 'House Number';

  @override
  String get house => 'House';

  @override
  String get street => 'Street';

  @override
  String get code => 'Code';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get search => 'Search...';

  @override
  String get share => 'Share';

  @override
  String get selectNotesForSharing => 'Select notes for sharing';

  @override
  String get navigationCar => 'Navigation car';

  @override
  String get navigationTransit => 'Navigation transit';

  @override
  String get welcome => 'Welcome';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get added => 'Added';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get error => 'Error';

  @override
  String get errorLogin => 'Login error';

  @override
  String get errorAuth => 'Error';

  @override
  String get errorNoAuth => 'Error: user not authorized';

  @override
  String get errorAddAddress => 'Error adding address';

  @override
  String get errorCountryCityEmpty => 'Please enter country and city';

  @override
  String get noAuth => 'Not authorized';

  @override
  String get changePassword => 'Change password';

  @override
  String get oldPassword => 'Old password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get changePasswordButton => 'Update password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordChangedSuccess => 'Password successfully changed';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordButton => 'Reset password';

  @override
  String get resetPasswordEmailSent => 'If an account with this email exists, check your inbox.';

  @override
  String get password => 'Password';

  @override
  String get profileUpdated => 'Profile successfully updated!';

  @override
  String get errorEmptyFields => 'Name and Email cannot be empty!';

  @override
  String get emailNotVerified => 'Your Email is not verified. We sent a new verification link. Please check your inbox!';

  @override
  String get category => 'Category';

  @override
  String get title => 'Title';

  @override
  String get resetEmailRequired => 'Enter your email address.';

  @override
  String get resetEmailInvalid => 'Enter a valid email address.';

  @override
  String get resetNetworkError => 'Connection failed. Check your network and try again.';

  @override
  String get resetTooManyRequests => 'Too many requests. Please wait and try again.';

  @override
  String get resetRequestError => 'Unable to send the request. Please try again later.';

  @override
  String get backToLogin => 'Back to sign in';

  @override
  String get profileLoadError => 'Unable to load your profile. Try again.';

  @override
  String get profileSaveError => 'Unable to save your profile. Your changes are still in the form.';

  @override
  String get profilePermissionDenied => 'Access to this profile was denied.';

  @override
  String get profileNetworkError => 'Connection failed. Check your network and try again.';

  @override
  String get profileChanged => 'The profile changed or was removed. Cancel and reload it before saving.';

  @override
  String get profileRetry => 'Try again';

  @override
  String get profileMissing => 'Your profile has not been created yet. Fill it in to continue.';

  @override
  String get profileCreate => 'Complete profile';

  @override
  String get profileName => 'Name';

  @override
  String get profileNameRequired => 'Enter your name.';

  @override
  String get changeEmailTitle => 'Change email';

  @override
  String get newEmail => 'New email';

  @override
  String get emailChangeSame => 'Enter an email different from your current address.';

  @override
  String get emailChangeSent => 'Confirmation requested. Your current email stays unchanged until you confirm the link in the new inbox.';

  @override
  String get emailChangeCheck => 'I confirmed my new email';

  @override
  String get emailChangePending => 'The new email is not confirmed yet. Check your inbox and the link.';

  @override
  String get emailChangeSuccess => 'Email changed and profile synchronized.';

  @override
  String get emailSyncFailed => 'Your Auth email changed, but the profile could not be synchronized.';

  @override
  String get emailSyncRetry => 'Retry profile synchronization';

  @override
  String get emailChangeReauth => 'Enter your current password to confirm your identity.';

  @override
  String get emailChangeWrongPassword => 'The current password is incorrect. Try again.';

  @override
  String get emailChangeProvider => 'Sign in again using your account provider. Password reauthentication is not available for this account.';

  @override
  String get emailChangeSession => 'Your session is no longer valid. Sign out and sign in again.';

  @override
  String get emailChangeGeneric => 'Unable to complete the request. Please try again.';

  @override
  String get emailChangeInUse => 'This email cannot be used. Choose another address.';

  @override
  String get emailChangeResend => 'Resend confirmation';

  @override
  String get emailChangeSend => 'Send confirmation';

  @override
  String get emailChangeExpired => 'The link is expired or invalid. Request a new confirmation email.';

  @override
  String get emailSyncMissing => 'Your Auth email changed. Complete your missing profile to save its copy.';

  @override
  String get passwordRequired => 'Enter a password.';

  @override
  String get passwordTooShort => 'Use at least 6 characters.';

  @override
  String get passwordWeak => 'The new password does not meet the account password policy. Choose a stronger password.';

  @override
  String get passwordRecentLogin => 'Fresh authentication is required. Sign in again before changing your password.';

  @override
  String get passwordChangeFailed => 'Unable to change the password. Please try again.';

  @override
  String get passwordChangeUncertain => 'The connection was lost while changing the password. It may already have changed. Check sign-in or use Forgot password.';

  @override
  String get passwordProviderUnavailable => 'Password change is unavailable for accounts without a password sign-in provider.';

  @override
  String get passwordEmailUnverified => 'Verify your email before changing your password.';

  @override
  String get passwordBackToProfile => 'Back to profile';
}
