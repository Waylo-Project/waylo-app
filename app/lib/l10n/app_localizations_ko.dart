// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'waylo';

  @override
  String get commonNext => '다음';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonSave => '저장';

  @override
  String get commonGotIt => '확인';

  @override
  String get commonSomethingWrong => '문제가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get welcomeTagline => '내 장소를\n친구와 공유하세요';

  @override
  String get welcomeSignUp => '무료로 시작하기';

  @override
  String get authLogIn => '로그인';

  @override
  String get authEmailLabel => '이메일';

  @override
  String get authPasswordLabel => '비밀번호';

  @override
  String get authInvalidEmail => '올바른 이메일을 입력하세요';

  @override
  String get authEnterPassword => '비밀번호를 입력하세요';

  @override
  String get signUpCreateAccount => '계정 만들기';

  @override
  String get signUpEmailQuestion => '이메일을 입력하세요';

  @override
  String get signUpPasswordQuestion => '비밀번호를 만드세요';

  @override
  String get signUpPasswordRequirements => '• 10자 이상\n• 영문과 숫자를 포함해야 합니다';

  @override
  String get signUpBirthDateQuestion => '생년월일을 알려주세요';

  @override
  String get signUpBirthDateHint => 'YYYY-MM-DD';

  @override
  String signUpAgeRestriction(int minAge) {
    return '만 $minAge세 이상만 가입할 수 있습니다.';
  }

  @override
  String get signUpGenderQuestion => '성별을 알려주세요';

  @override
  String get signUpGenderSelect => '성별을 선택하세요';

  @override
  String get genderMale => '남성';

  @override
  String get genderFemale => '여성';

  @override
  String get genderNonBinary => '논바이너리';

  @override
  String get genderOther => '기타';

  @override
  String get genderPreferNotToSay => '응답하지 않음';

  @override
  String get signUpUsernameQuestion => '사용자 이름을 정하세요';

  @override
  String get signUpUsernameRequirements =>
      '• 1~30자\n• 영문, 숫자, \'.\', \'_\' 사용 가능\n• \'.\' 또는 \'_\'로 시작하거나 끝날 수 없음\n연속된 \'..\'(마침표 두 개) 불가';

  @override
  String get signUpConfirmEmailNotice => '이메일에서 계정을 확인한 뒤 로그인하세요.';

  @override
  String get signUpUsernameTaken => '이미 사용 중인 사용자 이름입니다.';

  @override
  String get profileLoadError => '프로필을 불러올 수 없습니다.';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionProfile => '프로필';

  @override
  String get settingsSectionAccount => '계정';

  @override
  String get settingsSectionPreferences => '환경설정';

  @override
  String get settingsSectionAbout => '정보';

  @override
  String get settingsUsername => '사용자 이름';

  @override
  String get settingsDisplayName => '표시 이름';

  @override
  String get settingsEmail => '이메일';

  @override
  String get settingsPassword => '비밀번호';

  @override
  String get settingsChange => '변경';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsAppearance => '화면 모드';

  @override
  String get settingsThemeSystem => '시스템 설정';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsPhotoVisibility => '사진 공개 범위';

  @override
  String get settingsFriendsOnly => '친구만';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsTermsOfService => '이용약관';

  @override
  String get settingsPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsEdit => '편집';

  @override
  String get settingsDeleteAccount => '계정 삭제';

  @override
  String settingsSignedInAs(String username) {
    return '@$username 으로 로그인됨';
  }

  @override
  String get settingsProfilePhoto => '프로필 사진';

  @override
  String get settingsTakePhoto => '사진 촬영';

  @override
  String get settingsChooseFromGallery => '갤러리에서 선택';

  @override
  String get settingsRemovePhoto => '사진 삭제';

  @override
  String get settingsAppLanguage => '앱 언어';

  @override
  String get settingsLanguageSystem => '시스템 기본값';

  @override
  String get settingsLanguageNote => '더 많은 언어가 곧 추가됩니다. 언어를 선택하면 앱 전체에 적용됩니다.';

  @override
  String get settingsVisibilityFriendsDesc => '내 사진은 친구에게만, 그리고 내 지도에서만 보입니다.';

  @override
  String get settingsVisibilityFixedNote =>
      '지금은 변경할 수 없습니다 — waylo를 단순하게 유지하고 신뢰하는 사람에게만 사진을 공개하기 위함입니다.';

  @override
  String get settingsDeleteTitle => '계정을 삭제할까요?';

  @override
  String get settingsDeleteBody => '계정, 사진, 친구 관계가 영구적으로 삭제됩니다. 되돌릴 수 없습니다.';

  @override
  String settingsCouldNotDeleteAccount(String error) {
    return '계정을 삭제하지 못했습니다: $error';
  }

  @override
  String get settingsUsernameHint => '사용자 이름';

  @override
  String get settingsEnterUsername => '사용자 이름을 입력하세요.';

  @override
  String settingsCouldNotUpdateUsername(String error) {
    return '사용자 이름을 변경할 수 없습니다: $error';
  }

  @override
  String get settingsDisplayNameHint => '이름';

  @override
  String settingsCouldNotUpdateDisplayName(String error) {
    return '표시 이름을 변경할 수 없습니다: $error';
  }

  @override
  String get settingsEmailHint => 'you@email.com';

  @override
  String settingsCouldNotUpdateEmail(String error) {
    return '이메일을 변경할 수 없습니다: $error';
  }

  @override
  String settingsEmailChangeSent(String email) {
    return '$email(으)로 확인 메일을 보냈습니다. 메일의 링크를 눌러야 변경이 완료됩니다.';
  }

  @override
  String get settingsNewPassword => '새 비밀번호';

  @override
  String get settingsPasswordHint => '10자 이상, 영문과 숫자 포함';

  @override
  String get settingsPasswordTooShort => '비밀번호는 10자 이상이며 영문과 숫자를 포함해야 합니다.';

  @override
  String settingsCouldNotUpdatePassword(String error) {
    return '비밀번호를 변경할 수 없습니다: $error';
  }

  @override
  String settingsCouldNotUpdatePhoto(String error) {
    return '사진을 변경할 수 없습니다: $error';
  }

  @override
  String settingsCouldNotRemovePhoto(String error) {
    return '사진을 삭제할 수 없습니다: $error';
  }

  @override
  String get avatarNewProfilePhoto => '새 프로필 사진';

  @override
  String get avatarPhotoAccessOff =>
      '사진 접근이 꺼져 있습니다.\n사진을 선택하려면 접근을 허용하거나 새로 촬영하세요.';

  @override
  String get avatarOpenSettings => '설정 열기';

  @override
  String avatarCouldNotCrop(String error) {
    return '사진을 자를 수 없습니다: $error';
  }

  @override
  String get friendsSegRecent => '최근';

  @override
  String get friendsSegFriends => '친구';

  @override
  String get friendsSegRequests => '요청';

  @override
  String friendsFailed(String error) {
    return '실패: $error';
  }

  @override
  String get friendsEmptyFriends => '아직 친구가 없습니다.\n검색 아이콘을 눌러 친구를 찾아보세요.';

  @override
  String friendsCountHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '친구 $count명',
    );
    return '$_temp0';
  }

  @override
  String friendsRemoveTitle(String username) {
    return '@$username 님을 삭제할까요?';
  }

  @override
  String get friendsRemoveBody => '서로의 지도를 더 이상 볼 수 없게 됩니다.';

  @override
  String get friendsRemove => '삭제';

  @override
  String get friendsEmptyRequests => '대기 중인 요청이 없습니다.';

  @override
  String get friendsRequestsHeader => '친구 요청';

  @override
  String get friendsAccept => '수락';

  @override
  String get friendsDecline => '거절';

  @override
  String friendsMutual(int count) {
    return '함께 아는 친구 $count명';
  }

  @override
  String friendsSearchFailed(String error) {
    return '검색 실패: $error';
  }

  @override
  String get friendsStatusSent => '보냄';

  @override
  String get friendsAdd => '추가';

  @override
  String get friendsSearchHint => '사용자 이름 검색';

  @override
  String get friendsNoOneFound => '검색 결과가 없습니다.\n다른 사용자 이름을 입력해 보세요.';

  @override
  String get friendsSearchPrompt => '사용자 이름을 검색해 친구를 추가하세요.';

  @override
  String get friendsNoPlaces => '아직 장소가 없습니다';

  @override
  String friendsCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개국',
    );
    return '$_temp0';
  }

  @override
  String friendsCountriesMore(int count) {
    return '+$count개국';
  }

  @override
  String get friendsFindTitle => '친구 찾기';

  @override
  String get friendsJustIn => '방금';

  @override
  String get recentLast24h => '최근 24시간';

  @override
  String recentPostsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '게시물 $count개',
    );
    return '$_temp0';
  }

  @override
  String recentFriendsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '친구 $count명',
    );
    return '$_temp0';
  }

  @override
  String get timeNow => '지금';

  @override
  String timeMinutesShort(int count) {
    return '$count분';
  }

  @override
  String timeHoursShort(int count) {
    return '$count시간';
  }

  @override
  String timeDaysShort(int count) {
    return '$count일';
  }

  @override
  String get commonBack => '뒤로';

  @override
  String get postNewPost => '새 게시물';

  @override
  String get postPhotoAccessOff => '사진 접근이 꺼져 있습니다.\n접근을 허용하거나 사진을 촬영하세요.';

  @override
  String get postRatioOriginal => '원본';

  @override
  String get postRatioFree => '자유';

  @override
  String get postCropTitle => '자르기';

  @override
  String get postCropHint => '프레임을 드래그하고 모서리를 당겨 크기를 조절하세요';

  @override
  String get postPreparing => '준비 중…';

  @override
  String postCouldNotPrepare(String error) {
    return '사진을 준비할 수 없습니다: $error';
  }

  @override
  String get postDetailsTitle => '세부 정보';

  @override
  String get postInvalidCoords => '올바른 위도와 경도를 입력하세요.';

  @override
  String get postSourceExif => '사진의 위치에서';

  @override
  String get postSourceDevice => '현재 위치';

  @override
  String get postSourceMapDefault => '드래그하여 핀을 놓으세요';

  @override
  String get postTimeAutoNote => '시간은 사진에서 자동으로 가져옵니다.';

  @override
  String get postSearchPlace => '장소 검색';

  @override
  String get postPlaceNameLabel => '장소 이름';

  @override
  String get postPlaceNameHint => '이 장소의 이름을 입력하세요';

  @override
  String get postDateLabel => '날짜';

  @override
  String get postCaptionLabel => '캡션';

  @override
  String get postCaptionOptional => '· 선택';

  @override
  String get postCaptionHint => '이 장소에 대해 한마디 남겨보세요…';

  @override
  String get postEnterCoordsManually => '좌표 직접 입력';

  @override
  String get postLatLabel => '위도';

  @override
  String get postLngLabel => '경도';

  @override
  String get postGoToCoords => '좌표로 이동';

  @override
  String get postPost => '게시';

  @override
  String get mapTabMap => '지도';

  @override
  String get mapAddPhotoTooltip => '사진 추가';

  @override
  String get mapYou => '나';

  @override
  String get mapSignOut => '로그아웃';

  @override
  String mapCouldNotPost(String error) {
    return '게시할 수 없습니다: $error';
  }

  @override
  String friendMapTitle(String username) {
    return '@$username 님의 지도';
  }

  @override
  String get photoSomewhere => '어딘가';

  @override
  String get photoEditPost => '게시물 수정';

  @override
  String get photoDeletePost => '게시물 삭제';

  @override
  String get photoDeleteTitle => '이 게시물을 삭제할까요?';

  @override
  String get photoDeleteBody => '지도에서 영구적으로 삭제됩니다.';

  @override
  String photoCouldNotSave(String error) {
    return '저장할 수 없습니다: $error';
  }

  @override
  String photoCouldNotPostComment(String error) {
    return '댓글을 작성할 수 없습니다: $error';
  }

  @override
  String photoCouldNotDelete(String error) {
    return '삭제할 수 없습니다: $error';
  }

  @override
  String photoLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '좋아요 $count개',
    );
    return '$_temp0';
  }

  @override
  String get photoNoLikes => '아직 좋아요가 없습니다';

  @override
  String get photoLike => '좋아요';

  @override
  String get photoLiked => '좋아요';

  @override
  String get photoComments => '댓글';

  @override
  String photoCommentsCount(int count) {
    return '댓글 · $count';
  }

  @override
  String get photoNoComments => '가장 먼저 글을 남겨보세요.';

  @override
  String get photoCouldNotLoad => '사진을 불러올 수 없습니다';

  @override
  String get photoAddComment => '댓글 입력…';

  @override
  String get photoReply => '답글';

  @override
  String photoReplyingTo(String username) {
    return '@$username님에게 답글';
  }

  @override
  String timeWeeksShort(int count) {
    return '$count주';
  }

  @override
  String mapEmptyFriend(String username) {
    return '@$username님이 아직 사진을 올리지 않았어요.';
  }

  @override
  String get mapEmptyRecent => '최근 24시간 동안 친구가 올린 사진이 없어요.';

  @override
  String get mapLoadError => '지도를 불러오지 못했어요.';

  @override
  String get mapGuidePost => '+ 를 눌러 첫 사진을 지도에 올려보세요.';
}
