import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// The application name, shown as the MaterialApp title.
  ///
  /// In en, this message translates to:
  /// **'waylo'**
  String get appTitle;

  /// Generic 'Next' button advancing to the next step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// Generic 'Retry' button after a recoverable error.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Generic 'Cancel' button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic 'Delete' confirmation button.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Generic 'Save' button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Generic acknowledgement button that dismisses an info sheet.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// Generic fallback error message for an unexpected failure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get commonSomethingWrong;

  /// Tagline on the signed-out welcome screen. The \n is a line break.
  ///
  /// In en, this message translates to:
  /// **'Share your places\nwith friends'**
  String get welcomeTagline;

  /// Primary button on the welcome screen that starts sign-up.
  ///
  /// In en, this message translates to:
  /// **'Sign up for free'**
  String get welcomeSignUp;

  /// Log in: used as the welcome link, the sign-in app bar title, and the sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogIn;

  /// Field label for the email input on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Field label for the password input on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Validation error when the email is missing or malformed.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authInvalidEmail;

  /// Validation error when the password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authEnterPassword;

  /// App bar title shared by every sign-up step.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpCreateAccount;

  /// Prompt on the sign-up email step.
  ///
  /// In en, this message translates to:
  /// **'What\'s your email?'**
  String get signUpEmailQuestion;

  /// Prompt on the sign-up password step.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get signUpPasswordQuestion;

  /// Password rules shown under the password field. Each \n is a line break.
  ///
  /// In en, this message translates to:
  /// **'• At least 10 characters\n• Must include letters and numbers'**
  String get signUpPasswordRequirements;

  /// Prompt on the sign-up date-of-birth step.
  ///
  /// In en, this message translates to:
  /// **'What\'s your date of birth?'**
  String get signUpBirthDateQuestion;

  /// Placeholder showing the expected date format. Keep the literal Y/M/D pattern.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get signUpBirthDateHint;

  /// Inline error on the date-of-birth step when the entered age is below the minimum sign-up age.
  ///
  /// In en, this message translates to:
  /// **'You must be at least {minAge} to sign up.'**
  String signUpAgeRestriction(int minAge);

  /// Prompt on the sign-up gender step.
  ///
  /// In en, this message translates to:
  /// **'What\'s your gender?'**
  String get signUpGenderQuestion;

  /// Placeholder text in the gender dropdown before a choice is made.
  ///
  /// In en, this message translates to:
  /// **'Select your gender'**
  String get signUpGenderSelect;

  /// Gender option label. The stored value stays canonical English; this is display only.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// Gender option label (display only).
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// Gender option label (display only).
  ///
  /// In en, this message translates to:
  /// **'Non-binary'**
  String get genderNonBinary;

  /// Gender option label (display only).
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// Gender option label (display only).
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderPreferNotToSay;

  /// Prompt on the sign-up username step.
  ///
  /// In en, this message translates to:
  /// **'What\'s your username?'**
  String get signUpUsernameQuestion;

  /// Username rules shown under the username field. Each \n is a line break.
  ///
  /// In en, this message translates to:
  /// **'• 1-30 characters\n• Can contain letters, numbers, \'.\' and \'_\'\n• Cannot start or end with \'.\' or \'_\'\nNo consecutive \'..\' (double periods)'**
  String get signUpUsernameRequirements;

  /// Shown when sign-up succeeds but the session needs email confirmation.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account, then log in.'**
  String get signUpConfirmEmailNotice;

  /// Error when the chosen username already exists (sign-up and settings).
  ///
  /// In en, this message translates to:
  /// **'That username is already taken.'**
  String get signUpUsernameTaken;

  /// Shown by the auth gate when the signed-in user's profile fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile.'**
  String get profileLoadError;

  /// Settings screen app bar title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section header above the profile rows.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsSectionProfile;

  /// Section header above the account rows.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// Section header above the preferences rows.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// Section header above the about rows.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// Row label and edit dialog title for the username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get settingsUsername;

  /// Row label and edit dialog title for the display name.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get settingsDisplayName;

  /// Row label and edit dialog title for the email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmail;

  /// Row label for the password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsPassword;

  /// Value shown on the password row, hinting it opens a change dialog.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settingsChange;

  /// Row label for the app language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Row label and sheet title for the light/dark theme setting.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Theme option that follows the device's light/dark setting.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeSystem;

  /// Theme option: always light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Theme option: always dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Row label and sheet title for the photo-visibility setting.
  ///
  /// In en, this message translates to:
  /// **'Photo visibility'**
  String get settingsPhotoVisibility;

  /// The fixed photo-visibility value: friends only.
  ///
  /// In en, this message translates to:
  /// **'Friends only'**
  String get settingsFriendsOnly;

  /// Row label for the app version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Row label linking to the Terms of Service.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// Row label linking to the Privacy Policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// Edit pill on the profile hero card.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get settingsEdit;

  /// Label on the delete-account card.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// Footer showing which account is signed in.
  ///
  /// In en, this message translates to:
  /// **'Signed in as @{username}'**
  String settingsSignedInAs(String username);

  /// Title of the profile-photo action sheet.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get settingsProfilePhoto;

  /// Profile-photo sheet action: open the camera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get settingsTakePhoto;

  /// Profile-photo sheet action: pick from the gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get settingsChooseFromGallery;

  /// Profile-photo sheet action: remove the current avatar.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get settingsRemovePhoto;

  /// Title of the language picker sheet.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// Language option that follows the device's language setting.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// Helper text under the language options.
  ///
  /// In en, this message translates to:
  /// **'More languages are on the way. Choosing a language updates the whole app.'**
  String get settingsLanguageNote;

  /// Explanation of the friends-only visibility rule.
  ///
  /// In en, this message translates to:
  /// **'Your photos are visible to your friends, and only on your own map.'**
  String get settingsVisibilityFriendsDesc;

  /// Note that the visibility rule cannot currently be changed.
  ///
  /// In en, this message translates to:
  /// **'This is fixed for now — it keeps waylo simple and your photos private to people you trust.'**
  String get settingsVisibilityFixedNote;

  /// Title of the delete-account confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get settingsDeleteTitle;

  /// Body of the delete-account confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your account, photos, and friendships. This can’t be undone.'**
  String get settingsDeleteBody;

  /// Error dialog when deleting the account fails.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account: {error}'**
  String settingsCouldNotDeleteAccount(String error);

  /// Placeholder in the username edit field.
  ///
  /// In en, this message translates to:
  /// **'username'**
  String get settingsUsernameHint;

  /// Inline error when the username edit field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a username.'**
  String get settingsEnterUsername;

  /// Snackbar when updating the username fails. {error} is the raw error.
  ///
  /// In en, this message translates to:
  /// **'Could not update username: {error}'**
  String settingsCouldNotUpdateUsername(String error);

  /// Placeholder in the display-name edit field.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get settingsDisplayNameHint;

  /// Snackbar when updating the display name fails.
  ///
  /// In en, this message translates to:
  /// **'Could not update display name: {error}'**
  String settingsCouldNotUpdateDisplayName(String error);

  /// Placeholder in the email edit field.
  ///
  /// In en, this message translates to:
  /// **'you@email.com'**
  String get settingsEmailHint;

  /// Snackbar when updating the email fails.
  ///
  /// In en, this message translates to:
  /// **'Could not update email: {error}'**
  String settingsCouldNotUpdateEmail(String error);

  /// Notice after requesting an email change: it takes effect only once the confirmation link sent to the new address is clicked.
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to {email}. Your email changes once you tap it.'**
  String settingsEmailChangeSent(String email);

  /// Title of the new-password edit dialog.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get settingsNewPassword;

  /// Placeholder in the new-password edit field.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters, with letters and numbers'**
  String get settingsPasswordHint;

  /// Inline error when the new password does not meet the policy.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 10 characters and include letters and numbers.'**
  String get settingsPasswordTooShort;

  /// Snackbar when updating the password fails.
  ///
  /// In en, this message translates to:
  /// **'Could not update password: {error}'**
  String settingsCouldNotUpdatePassword(String error);

  /// Snackbar when updating the avatar fails.
  ///
  /// In en, this message translates to:
  /// **'Could not update photo: {error}'**
  String settingsCouldNotUpdatePhoto(String error);

  /// Snackbar when removing the avatar fails.
  ///
  /// In en, this message translates to:
  /// **'Could not remove photo: {error}'**
  String settingsCouldNotRemovePhoto(String error);

  /// Title bar of the avatar picker screen.
  ///
  /// In en, this message translates to:
  /// **'New profile photo'**
  String get avatarNewProfilePhoto;

  /// Shown in the avatar picker grid when photo permission is denied.
  ///
  /// In en, this message translates to:
  /// **'Photo access is off.\nAllow access to choose a photo, or take a new one.'**
  String get avatarPhotoAccessOff;

  /// Button to open the OS settings to grant photo access.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get avatarOpenSettings;

  /// Snackbar when capturing the cropped avatar fails.
  ///
  /// In en, this message translates to:
  /// **'Could not crop the photo: {error}'**
  String avatarCouldNotCrop(String error);

  /// Segmented-control tab: the recent (last 24h) map.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get friendsSegRecent;

  /// Segmented-control tab: the friends list. Also used as the 'already a friend' status label in search results.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsSegFriends;

  /// Segmented-control tab: incoming friend requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get friendsSegRequests;

  /// Generic failure snackbar on the friends screen.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String friendsFailed(String error);

  /// Snackbar confirming a friend request was sent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get friendsRequestSent;

  /// Empty state for the friends list.
  ///
  /// In en, this message translates to:
  /// **'No friends yet.\nTap the search icon to find people.'**
  String get friendsEmptyFriends;

  /// Section header above the friends list, showing the count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 friend} other{{count} friends}}'**
  String friendsCountHeader(int count);

  /// Title of the remove-friend confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Remove @{username}?'**
  String friendsRemoveTitle(String username);

  /// Body of the remove-friend confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'You\'ll stop seeing each other\'s maps.'**
  String get friendsRemoveBody;

  /// Remove action: dialog button and the swipe-to-remove background label.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get friendsRemove;

  /// Snackbar confirming a friend was removed.
  ///
  /// In en, this message translates to:
  /// **'Removed @{username}'**
  String friendsRemoved(String username);

  /// Empty state for the requests list.
  ///
  /// In en, this message translates to:
  /// **'No pending requests.'**
  String get friendsEmptyRequests;

  /// Section header above the incoming requests.
  ///
  /// In en, this message translates to:
  /// **'Wants to be friends'**
  String get friendsRequestsHeader;

  /// Button to accept an incoming friend request.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendsAccept;

  /// Button to decline an incoming friend request.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get friendsDecline;

  /// Snackbar confirming a request was accepted.
  ///
  /// In en, this message translates to:
  /// **'Added @{username}'**
  String friendsAdded(String username);

  /// Snackbar confirming a request was declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get friendsDeclined;

  /// Count of mutual friends shown on a request card.
  ///
  /// In en, this message translates to:
  /// **'{count} mutual'**
  String friendsMutual(int count);

  /// Snackbar when the username search fails.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String friendsSearchFailed(String error);

  /// Status label on a search result whose request was already sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get friendsStatusSent;

  /// Button on a search result to send a friend request.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get friendsAdd;

  /// Placeholder in the find-friends search field.
  ///
  /// In en, this message translates to:
  /// **'Search username'**
  String get friendsSearchHint;

  /// Shown when a username search returns no results.
  ///
  /// In en, this message translates to:
  /// **'No one found.\nTry a different username.'**
  String get friendsNoOneFound;

  /// Shown before any search has been made.
  ///
  /// In en, this message translates to:
  /// **'Search a username to add friends.'**
  String get friendsSearchPrompt;

  /// Passport strip text when a friend has posted no places.
  ///
  /// In en, this message translates to:
  /// **'No places yet'**
  String get friendsNoPlaces;

  /// Passport strip summary of how many countries a friend has posted from.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 country} other{{count} countries}}'**
  String friendsCountries(int count);

  /// Passport strip summary when there are more than three countries.
  ///
  /// In en, this message translates to:
  /// **'+{count} countries'**
  String friendsCountriesMore(int count);

  /// App bar title of the find-friends screen.
  ///
  /// In en, this message translates to:
  /// **'Find friends'**
  String get friendsFindTitle;

  /// Header of the recent-posts strip on the Recent panel.
  ///
  /// In en, this message translates to:
  /// **'JUST IN'**
  String get friendsJustIn;

  /// Leading label of the recent-map summary pill.
  ///
  /// In en, this message translates to:
  /// **'Last 24h'**
  String get recentLast24h;

  /// Post count in the recent-map summary pill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 post} other{{count} posts}}'**
  String recentPostsCount(int count);

  /// Friend count in the recent-map summary pill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 friend} other{{count} friends}}'**
  String recentFriendsCount(int count);

  /// Relative time for something that just happened.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// Compact relative time in minutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String timeMinutesShort(int count);

  /// Compact relative time in hours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String timeHoursShort(int count);

  /// Compact relative time in days.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String timeDaysShort(int count);

  /// Generic 'Back' button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Title of the photo picker / first post step.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get postNewPost;

  /// Placeholder shown in the crop stage before a photo is chosen.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo'**
  String get postPickPhoto;

  /// Header above the recent-photos library grid.
  ///
  /// In en, this message translates to:
  /// **'Recents'**
  String get postRecents;

  /// Shown in the post picker grid when photo permission is denied.
  ///
  /// In en, this message translates to:
  /// **'Photo access is off.\nAllow access, or take a photo.'**
  String get postPhotoAccessOff;

  /// Crop ratio chip: frame the whole (original aspect) photo. Display only; the internal key stays 'Original'.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get postRatioOriginal;

  /// Crop ratio chip: free-form crop. Display only; the internal key stays 'Free'.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get postRatioFree;

  /// App bar title of the crop step.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get postCropTitle;

  /// Hint overlay on the crop stage.
  ///
  /// In en, this message translates to:
  /// **'Drag the frame · pull a corner to resize'**
  String get postCropHint;

  /// Loading overlay label while the cropped photo is prepared.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get postPreparing;

  /// Snackbar when preparing the cropped photo fails.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare the photo: {error}'**
  String postCouldNotPrepare(String error);

  /// App bar title of the post details step.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get postDetailsTitle;

  /// Snackbar when manually entered coordinates are invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid latitude and longitude.'**
  String get postInvalidCoords;

  /// Source chip: the pin started from the photo's embedded location.
  ///
  /// In en, this message translates to:
  /// **'From the photo\'s location'**
  String get postSourceExif;

  /// Source chip: the pin started from the device location.
  ///
  /// In en, this message translates to:
  /// **'Your current location'**
  String get postSourceDevice;

  /// Source chip: no location known, so the user drags to place the pin.
  ///
  /// In en, this message translates to:
  /// **'Drag to place the pin'**
  String get postSourceMapDefault;

  /// Note under the date field explaining the time is taken from the photo.
  ///
  /// In en, this message translates to:
  /// **'Time is kept automatically from the photo.'**
  String get postTimeAutoNote;

  /// Placeholder in the place-search field on the post map.
  ///
  /// In en, this message translates to:
  /// **'Search a place'**
  String get postSearchPlace;

  /// Field label for the place name.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get postPlaceNameLabel;

  /// Placeholder in the place-name field.
  ///
  /// In en, this message translates to:
  /// **'Name this place'**
  String get postPlaceNameHint;

  /// Field label for the post date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get postDateLabel;

  /// Field label for the caption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get postCaptionLabel;

  /// Marker next to the caption label indicating it is optional. Keep the leading separator.
  ///
  /// In en, this message translates to:
  /// **'· optional'**
  String get postCaptionOptional;

  /// Placeholder in the caption field.
  ///
  /// In en, this message translates to:
  /// **'Say something about this place…'**
  String get postCaptionHint;

  /// Toggle that reveals the manual coordinate inputs.
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates manually'**
  String get postEnterCoordsManually;

  /// Short label for the latitude input.
  ///
  /// In en, this message translates to:
  /// **'LAT'**
  String get postLatLabel;

  /// Short label for the longitude input.
  ///
  /// In en, this message translates to:
  /// **'LNG'**
  String get postLngLabel;

  /// Button that moves the map to the typed coordinates.
  ///
  /// In en, this message translates to:
  /// **'Go to coordinates'**
  String get postGoToCoords;

  /// Primary button that creates the post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postPost;

  /// Bottom pill segment that shows your own map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTabMap;

  /// Tooltip on the (+) compose button.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get mapAddPhotoTooltip;

  /// The 'You' menu button tooltip and the username fallback in that menu.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get mapYou;

  /// Menu item for map customization.
  ///
  /// In en, this message translates to:
  /// **'Map style'**
  String get mapStyleLabel;

  /// Subtitle marking a not-yet-available menu item.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get mapComingSoon;

  /// Menu item that signs the user out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get mapSignOut;

  /// Snackbar shown when tapping the not-yet-available map style item.
  ///
  /// In en, this message translates to:
  /// **'Map customization is coming soon.'**
  String get mapCustomizationComingSoon;

  /// Snackbar confirming a post was created.
  ///
  /// In en, this message translates to:
  /// **'Posted!'**
  String get mapPosted;

  /// Snackbar when creating a post fails.
  ///
  /// In en, this message translates to:
  /// **'Could not post: {error}'**
  String mapCouldNotPost(String error);

  /// App bar title of a friend's map.
  ///
  /// In en, this message translates to:
  /// **'@{username}\'s map'**
  String friendMapTitle(String username);

  /// Fallback place name when none is known for a photo.
  ///
  /// In en, this message translates to:
  /// **'Somewhere'**
  String get photoSomewhere;

  /// Own-post menu item to edit the caption.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get photoEditPost;

  /// Own-post menu item to delete the post.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get photoDeletePost;

  /// Title of the delete-post confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get photoDeleteTitle;

  /// Body of the delete-post confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your map for good.'**
  String get photoDeleteBody;

  /// Snackbar when saving the edited caption fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {error}'**
  String photoCouldNotSave(String error);

  /// Snackbar when posting a comment fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t post: {error}'**
  String photoCouldNotPostComment(String error);

  /// Snackbar when deleting a comment or post fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete: {error}'**
  String photoCouldNotDelete(String error);

  /// Like count next to the reactor cluster.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 like} other{{count} likes}}'**
  String photoLikesCount(int count);

  /// Shown when a post has no likes.
  ///
  /// In en, this message translates to:
  /// **'No likes yet'**
  String get photoNoLikes;

  /// Like pill label when not yet liked.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get photoLike;

  /// Like pill label when already liked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get photoLiked;

  /// Comments section header before the count is loaded.
  ///
  /// In en, this message translates to:
  /// **'COMMENTS'**
  String get photoComments;

  /// Comments section header with the count.
  ///
  /// In en, this message translates to:
  /// **'COMMENTS · {count}'**
  String photoCommentsCount(int count);

  /// Empty state when a post has no comments.
  ///
  /// In en, this message translates to:
  /// **'Be the first to leave a note.'**
  String get photoNoComments;

  /// Shown when a photo image fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load photo'**
  String get photoCouldNotLoad;

  /// Placeholder in the comment composer.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get photoAddComment;

  /// Small action under a comment that starts a reply to it.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get photoReply;

  /// Banner above the composer while writing a reply.
  ///
  /// In en, this message translates to:
  /// **'Replying to @{username}'**
  String photoReplyingTo(String username);

  /// Compact relative time in weeks.
  ///
  /// In en, this message translates to:
  /// **'{count}w'**
  String timeWeeksShort(int count);

  /// Empty-state hint on your own map when you have no posts.
  ///
  /// In en, this message translates to:
  /// **'No photos yet — tap + to pin your first one.'**
  String get mapEmptyOwn;

  /// Empty-state hint on a friend's map when they have no posts.
  ///
  /// In en, this message translates to:
  /// **'@{username} hasn’t posted any photos yet.'**
  String mapEmptyFriend(String username);

  /// Empty-state hint on the Recent (last 24h) friends map.
  ///
  /// In en, this message translates to:
  /// **'No photos from friends in the last 24 hours.'**
  String get mapEmptyRecent;

  /// Shown over the map when the initial load fails (with a Retry button).
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the map.'**
  String get mapLoadError;

  /// One-time coach mark for new sign-ups, pointing at the + button.
  ///
  /// In en, this message translates to:
  /// **'Tap + to put your first photo on the map.'**
  String get mapGuidePost;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
