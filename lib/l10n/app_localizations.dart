import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
    Locale('ru'),
    Locale('uk')
  ];

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address?'**
  String get confirmDelete;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Address Manager'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Address Manager!'**
  String get welcomeMessage;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @languagePolish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get languagePolish;

  /// No description provided for @languageUkrainian.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get languageUkrainian;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerButton;

  /// No description provided for @registerButtonFull.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerButtonFull;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @noProfileData.
  ///
  /// In en, this message translates to:
  /// **'No profile data'**
  String get noProfileData;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get newNote;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @deleteNoteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get deleteNoteQuestion;

  /// No description provided for @deleteNoteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteNoteWarning;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @addressList.
  ///
  /// In en, this message translates to:
  /// **'Address list'**
  String get addressList;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get editAddress;

  /// No description provided for @noAddresses.
  ///
  /// In en, this message translates to:
  /// **'No addresses found'**
  String get noAddresses;

  /// No description provided for @noAddressesYet.
  ///
  /// In en, this message translates to:
  /// **'No addresses yet'**
  String get noAddressesYet;

  /// No description provided for @myAddresses.
  ///
  /// In en, this message translates to:
  /// **'My addresses'**
  String get myAddresses;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address details'**
  String get addressDetails;

  /// No description provided for @houseNumber.
  ///
  /// In en, this message translates to:
  /// **'House Number'**
  String get houseNumber;

  /// No description provided for @house.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get house;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @selectNotesForSharing.
  ///
  /// In en, this message translates to:
  /// **'Select notes for sharing'**
  String get selectNotesForSharing;

  /// No description provided for @navigationCar.
  ///
  /// In en, this message translates to:
  /// **'Navigation car'**
  String get navigationCar;

  /// No description provided for @navigationTransit.
  ///
  /// In en, this message translates to:
  /// **'Navigation transit'**
  String get navigationTransit;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorLogin.
  ///
  /// In en, this message translates to:
  /// **'Login error'**
  String get errorLogin;

  /// No description provided for @errorAuth.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorAuth;

  /// No description provided for @errorNoAuth.
  ///
  /// In en, this message translates to:
  /// **'Error: user not authorized'**
  String get errorNoAuth;

  /// No description provided for @errorAddAddress.
  ///
  /// In en, this message translates to:
  /// **'Error adding address'**
  String get errorAddAddress;

  /// No description provided for @errorCountryCityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter country and city'**
  String get errorCountryCityEmpty;

  /// No description provided for @noAuth.
  ///
  /// In en, this message translates to:
  /// **'Not authorized'**
  String get noAuth;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @changePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get changePasswordButton;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password successfully changed'**
  String get passwordChangedSuccess;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordButton;

  /// No description provided for @resetPasswordEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If an account with this email exists, check your inbox.'**
  String get resetPasswordEmailSent;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile successfully updated!'**
  String get profileUpdated;

  /// No description provided for @errorEmptyFields.
  ///
  /// In en, this message translates to:
  /// **'Name and Email cannot be empty!'**
  String get errorEmptyFields;

  /// No description provided for @emailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Your Email is not verified. We sent a new verification link. Please check your inbox!'**
  String get emailNotVerified;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @resetEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get resetEmailRequired;

  /// No description provided for @resetEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get resetEmailInvalid;

  /// No description provided for @resetNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check your network and try again.'**
  String get resetNetworkError;

  /// No description provided for @resetTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait and try again.'**
  String get resetTooManyRequests;

  /// No description provided for @resetRequestError.
  ///
  /// In en, this message translates to:
  /// **'Unable to send the request. Please try again later.'**
  String get resetRequestError;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToLogin;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your profile. Try again.'**
  String get profileLoadError;

  /// No description provided for @profileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save your profile. Your changes are still in the form.'**
  String get profileSaveError;

  /// No description provided for @profilePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Access to this profile was denied.'**
  String get profilePermissionDenied;

  /// No description provided for @profileNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check your network and try again.'**
  String get profileNetworkError;

  /// No description provided for @profileChanged.
  ///
  /// In en, this message translates to:
  /// **'The profile changed or was removed. Cancel and reload it before saving.'**
  String get profileChanged;

  /// No description provided for @profileRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get profileRetry;

  /// No description provided for @profileMissing.
  ///
  /// In en, this message translates to:
  /// **'Your profile has not been created yet. Fill it in to continue.'**
  String get profileMissing;

  /// No description provided for @profileCreate.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get profileCreate;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get profileNameRequired;

  /// No description provided for @changeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmailTitle;

  /// No description provided for @newEmail.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get newEmail;

  /// No description provided for @emailChangeSame.
  ///
  /// In en, this message translates to:
  /// **'Enter an email different from your current address.'**
  String get emailChangeSame;

  /// No description provided for @emailChangeSent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation requested. Your current email stays unchanged until you confirm the link in the new inbox.'**
  String get emailChangeSent;

  /// No description provided for @emailChangeCheck.
  ///
  /// In en, this message translates to:
  /// **'I confirmed my new email'**
  String get emailChangeCheck;

  /// No description provided for @emailChangePending.
  ///
  /// In en, this message translates to:
  /// **'The new email is not confirmed yet. Check your inbox and the link.'**
  String get emailChangePending;

  /// No description provided for @emailChangeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email changed and profile synchronized.'**
  String get emailChangeSuccess;

  /// No description provided for @emailSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Your Auth email changed, but the profile could not be synchronized.'**
  String get emailSyncFailed;

  /// No description provided for @emailSyncRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry profile synchronization'**
  String get emailSyncRetry;

  /// No description provided for @emailChangeReauth.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password to confirm your identity.'**
  String get emailChangeReauth;

  /// No description provided for @emailChangeWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The current password is incorrect. Try again.'**
  String get emailChangeWrongPassword;

  /// No description provided for @emailChangeProvider.
  ///
  /// In en, this message translates to:
  /// **'Sign in again using your account provider. Password reauthentication is not available for this account.'**
  String get emailChangeProvider;

  /// No description provided for @emailChangeSession.
  ///
  /// In en, this message translates to:
  /// **'Your session is no longer valid. Sign out and sign in again.'**
  String get emailChangeSession;

  /// No description provided for @emailChangeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete the request. Please try again.'**
  String get emailChangeGeneric;

  /// No description provided for @emailChangeInUse.
  ///
  /// In en, this message translates to:
  /// **'This email cannot be used. Choose another address.'**
  String get emailChangeInUse;

  /// No description provided for @emailChangeResend.
  ///
  /// In en, this message translates to:
  /// **'Resend confirmation'**
  String get emailChangeResend;

  /// No description provided for @emailChangeSend.
  ///
  /// In en, this message translates to:
  /// **'Send confirmation'**
  String get emailChangeSend;

  /// No description provided for @emailChangeExpired.
  ///
  /// In en, this message translates to:
  /// **'The link is expired or invalid. Request a new confirmation email.'**
  String get emailChangeExpired;

  /// No description provided for @emailSyncMissing.
  ///
  /// In en, this message translates to:
  /// **'Your Auth email changed. Complete your missing profile to save its copy.'**
  String get emailSyncMissing;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pl', 'ru', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pl': return AppLocalizationsPl();
    case 'ru': return AppLocalizationsRu();
    case 'uk': return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
