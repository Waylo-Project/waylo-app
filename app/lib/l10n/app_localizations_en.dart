// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'waylo';

  @override
  String get commonNext => 'Next';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonSomethingWrong => 'Something went wrong. Try again.';

  @override
  String get welcomeTagline => 'Share your places\nwith friends';

  @override
  String get welcomeSignUp => 'Sign up for free';

  @override
  String get authLogIn => 'Log in';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authInvalidEmail => 'Enter a valid email';

  @override
  String get authEnterPassword => 'Enter your password';

  @override
  String get signUpCreateAccount => 'Create account';

  @override
  String get signUpEmailQuestion => 'What\'s your email?';

  @override
  String get signUpPasswordQuestion => 'Create a password';

  @override
  String get signUpPasswordRequirements =>
      '• At least 10 characters\n• Must include letters and numbers';

  @override
  String get signUpBirthDateQuestion => 'What\'s your date of birth?';

  @override
  String get signUpBirthDateHint => 'YYYY-MM-DD';

  @override
  String signUpAgeRestriction(int minAge) {
    return 'You must be at least $minAge to sign up.';
  }

  @override
  String get signUpGenderQuestion => 'What\'s your gender?';

  @override
  String get signUpGenderSelect => 'Select your gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderNonBinary => 'Non-binary';

  @override
  String get genderOther => 'Other';

  @override
  String get genderPreferNotToSay => 'Prefer not to say';

  @override
  String get signUpUsernameQuestion => 'What\'s your username?';

  @override
  String get signUpUsernameRequirements =>
      '• 1-30 characters\n• Can contain letters, numbers, \'.\' and \'_\'\n• Cannot start or end with \'.\' or \'_\'\nNo consecutive \'..\' (double periods)';

  @override
  String get signUpConfirmEmailNotice =>
      'Check your email to confirm your account, then log in.';

  @override
  String get signUpUsernameTaken => 'That username is already taken.';

  @override
  String get profileLoadError => 'Could not load your profile.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionProfile => 'Profile';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsUsername => 'Username';

  @override
  String get settingsDisplayName => 'Display name';

  @override
  String get settingsEmail => 'Email';

  @override
  String get settingsPassword => 'Password';

  @override
  String get settingsChange => 'Change';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPhotoVisibility => 'Photo visibility';

  @override
  String get settingsFriendsOnly => 'Friends only';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsEdit => 'Edit';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String settingsSignedInAs(String username) {
    return 'Signed in as @$username';
  }

  @override
  String get settingsProfilePhoto => 'Profile photo';

  @override
  String get settingsTakePhoto => 'Take a photo';

  @override
  String get settingsChooseFromGallery => 'Choose from gallery';

  @override
  String get settingsRemovePhoto => 'Remove photo';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageNote =>
      'More languages are on the way. Choosing a language updates the whole app.';

  @override
  String get settingsVisibilityFriendsDesc =>
      'Your photos are visible to your friends, and only on your own map.';

  @override
  String get settingsVisibilityFixedNote =>
      'This is fixed for now — it keeps waylo simple and your photos private to people you trust.';

  @override
  String get settingsDeleteTitle => 'Delete account?';

  @override
  String get settingsDeleteBody =>
      'This permanently removes your account, photos, and friendships. This can’t be undone.';

  @override
  String settingsCouldNotDeleteAccount(String error) {
    return 'Could not delete account: $error';
  }

  @override
  String get settingsUsernameHint => 'username';

  @override
  String get settingsEnterUsername => 'Enter a username.';

  @override
  String settingsCouldNotUpdateUsername(String error) {
    return 'Could not update username: $error';
  }

  @override
  String get settingsDisplayNameHint => 'Your name';

  @override
  String settingsCouldNotUpdateDisplayName(String error) {
    return 'Could not update display name: $error';
  }

  @override
  String get settingsEmailHint => 'you@email.com';

  @override
  String settingsCouldNotUpdateEmail(String error) {
    return 'Could not update email: $error';
  }

  @override
  String settingsEmailChangeSent(String email) {
    return 'We sent a confirmation link to $email. Your email changes once you tap it.';
  }

  @override
  String get settingsNewPassword => 'New password';

  @override
  String get settingsPasswordHint =>
      'At least 10 characters, with letters and numbers';

  @override
  String get settingsPasswordTooShort =>
      'Password must be at least 10 characters and include letters and numbers.';

  @override
  String settingsCouldNotUpdatePassword(String error) {
    return 'Could not update password: $error';
  }

  @override
  String settingsCouldNotUpdatePhoto(String error) {
    return 'Could not update photo: $error';
  }

  @override
  String settingsCouldNotRemovePhoto(String error) {
    return 'Could not remove photo: $error';
  }

  @override
  String get avatarNewProfilePhoto => 'New profile photo';

  @override
  String get avatarPhotoAccessOff =>
      'Photo access is off.\nAllow access to choose a photo, or take a new one.';

  @override
  String get avatarOpenSettings => 'Open settings';

  @override
  String avatarCouldNotCrop(String error) {
    return 'Could not crop the photo: $error';
  }

  @override
  String get friendsSegRecent => 'Recent';

  @override
  String get friendsSegFriends => 'Friends';

  @override
  String get friendsSegRequests => 'Requests';

  @override
  String friendsFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get friendsEmptyFriends =>
      'No friends yet.\nTap the search icon to find people.';

  @override
  String friendsCountHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends',
      one: '1 friend',
    );
    return '$_temp0';
  }

  @override
  String friendsRemoveTitle(String username) {
    return 'Remove @$username?';
  }

  @override
  String get friendsRemoveBody => 'You\'ll stop seeing each other\'s maps.';

  @override
  String get friendsRemove => 'Remove';

  @override
  String get friendsEmptyRequests => 'No pending requests.';

  @override
  String get friendsRequestsHeader => 'Wants to be friends';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsDecline => 'Decline';

  @override
  String friendsMutual(int count) {
    return '$count mutual';
  }

  @override
  String friendsSearchFailed(String error) {
    return 'Search failed: $error';
  }

  @override
  String get friendsStatusSent => 'Sent';

  @override
  String get friendsAdd => 'Add';

  @override
  String get friendsSearchHint => 'Search username';

  @override
  String get friendsNoOneFound => 'No one found.\nTry a different username.';

  @override
  String get friendsSearchPrompt => 'Search a username to add friends.';

  @override
  String get friendsNoPlaces => 'No places yet';

  @override
  String friendsCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count countries',
      one: '1 country',
    );
    return '$_temp0';
  }

  @override
  String friendsCountriesMore(int count) {
    return '+$count countries';
  }

  @override
  String get friendsFindTitle => 'Find friends';

  @override
  String get friendsJustIn => 'JUST IN';

  @override
  String get recentLast24h => 'Last 24h';

  @override
  String recentPostsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts',
      one: '1 post',
    );
    return '$_temp0';
  }

  @override
  String recentFriendsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends',
      one: '1 friend',
    );
    return '$_temp0';
  }

  @override
  String get timeNow => 'now';

  @override
  String timeMinutesShort(int count) {
    return '${count}m';
  }

  @override
  String timeHoursShort(int count) {
    return '${count}h';
  }

  @override
  String timeDaysShort(int count) {
    return '${count}d';
  }

  @override
  String get commonBack => 'Back';

  @override
  String get postNewPost => 'New post';

  @override
  String get postPhotoAccessOff =>
      'Photo access is off.\nAllow access, or take a photo.';

  @override
  String get postRatioOriginal => 'Original';

  @override
  String get postRatioFree => 'Free';

  @override
  String get postCropTitle => 'Crop';

  @override
  String get postCropHint => 'Drag the frame · pull a corner to resize';

  @override
  String get postPreparing => 'Preparing…';

  @override
  String postCouldNotPrepare(String error) {
    return 'Could not prepare the photo: $error';
  }

  @override
  String get postDetailsTitle => 'Details';

  @override
  String get postInvalidCoords => 'Enter a valid latitude and longitude.';

  @override
  String get postSourceExif => 'From the photo\'s location';

  @override
  String get postSourceDevice => 'Your current location';

  @override
  String get postSourceMapDefault => 'Drag to place the pin';

  @override
  String get postTimeAutoNote => 'Time is kept automatically from the photo.';

  @override
  String get postSearchPlace => 'Search a place';

  @override
  String get postPlaceNameLabel => 'Place name';

  @override
  String get postPlaceNameHint => 'Name this place';

  @override
  String get postDateLabel => 'Date';

  @override
  String get postCaptionLabel => 'Caption';

  @override
  String get postCaptionOptional => '· optional';

  @override
  String get postCaptionHint => 'Say something about this place…';

  @override
  String get postEnterCoordsManually => 'Enter coordinates manually';

  @override
  String get postLatLabel => 'LAT';

  @override
  String get postLngLabel => 'LNG';

  @override
  String get postGoToCoords => 'Go to coordinates';

  @override
  String get postPost => 'Post';

  @override
  String get mapTabMap => 'Map';

  @override
  String get mapAddPhotoTooltip => 'Add photo';

  @override
  String get mapYou => 'You';

  @override
  String get mapSignOut => 'Sign out';

  @override
  String mapCouldNotPost(String error) {
    return 'Could not post: $error';
  }

  @override
  String friendMapTitle(String username) {
    return '@$username\'s map';
  }

  @override
  String get photoSomewhere => 'Somewhere';

  @override
  String get photoEditPost => 'Edit post';

  @override
  String get photoDeletePost => 'Delete post';

  @override
  String get photoDeleteTitle => 'Delete this post?';

  @override
  String get photoDeleteBody => 'It will be removed from your map for good.';

  @override
  String photoCouldNotSave(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String photoCouldNotPostComment(String error) {
    return 'Couldn\'t post: $error';
  }

  @override
  String photoCouldNotDelete(String error) {
    return 'Couldn\'t delete: $error';
  }

  @override
  String photoLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
    );
    return '$_temp0';
  }

  @override
  String get photoNoLikes => 'No likes yet';

  @override
  String get photoLike => 'Like';

  @override
  String get photoLiked => 'Liked';

  @override
  String get photoComments => 'COMMENTS';

  @override
  String photoCommentsCount(int count) {
    return 'COMMENTS · $count';
  }

  @override
  String get photoNoComments => 'Be the first to leave a note.';

  @override
  String get photoCouldNotLoad => 'Couldn\'t load photo';

  @override
  String get photoAddComment => 'Add a comment…';

  @override
  String get photoReply => 'Reply';

  @override
  String photoReplyingTo(String username) {
    return 'Replying to @$username';
  }

  @override
  String timeWeeksShort(int count) {
    return '${count}w';
  }

  @override
  String mapEmptyFriend(String username) {
    return '@$username hasn’t posted any photos yet.';
  }

  @override
  String get mapEmptyRecent => 'No photos from friends in the last 24 hours.';

  @override
  String get mapLoadError => 'Couldn’t load the map.';

  @override
  String get mapGuidePost => 'Tap + to put your first photo on the map.';
}
