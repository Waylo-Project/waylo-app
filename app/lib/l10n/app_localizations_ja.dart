// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'waylo';

  @override
  String get commonNext => '次へ';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDelete => '削除';

  @override
  String get commonSave => '保存';

  @override
  String get commonGotIt => '了解';

  @override
  String get commonSomethingWrong => '問題が発生しました。もう一度お試しください。';

  @override
  String get welcomeTagline => 'あなたの場所を\n友だちと共有';

  @override
  String get welcomeSignUp => '無料で始める';

  @override
  String get authLogIn => 'ログイン';

  @override
  String get authEmailLabel => 'メール';

  @override
  String get authPasswordLabel => 'パスワード';

  @override
  String get authInvalidEmail => '有効なメールアドレスを入力してください';

  @override
  String get authEnterPassword => 'パスワードを入力してください';

  @override
  String get signUpCreateAccount => 'アカウント作成';

  @override
  String get signUpEmailQuestion => 'メールアドレスを入力';

  @override
  String get signUpPasswordQuestion => 'パスワードを作成';

  @override
  String get signUpPasswordRequirements => '• 10文字以上\n• 英字と数字を含める';

  @override
  String get signUpBirthDateQuestion => '生年月日を教えてください';

  @override
  String get signUpBirthDateHint => 'YYYY-MM-DD';

  @override
  String signUpAgeRestriction(int minAge) {
    return '$minAge歳以上のみ登録できます。';
  }

  @override
  String get signUpGenderQuestion => '性別を教えてください';

  @override
  String get signUpGenderSelect => '性別を選択';

  @override
  String get genderMale => '男性';

  @override
  String get genderFemale => '女性';

  @override
  String get genderNonBinary => 'ノンバイナリー';

  @override
  String get genderOther => 'その他';

  @override
  String get genderPreferNotToSay => '回答しない';

  @override
  String get signUpUsernameQuestion => 'ユーザー名を決めてください';

  @override
  String get signUpUsernameRequirements =>
      '• 1〜30文字\n• 英字、数字、「.」「_」が使えます\n•「.」「_」で始めたり終えたりできません\n連続した「..」（ピリオド2つ）は使えません';

  @override
  String get signUpConfirmEmailNotice => 'メールでアカウントを確認してからログインしてください。';

  @override
  String get signUpUsernameTaken => 'このユーザー名は既に使われています。';

  @override
  String get profileLoadError => 'プロフィールを読み込めませんでした。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionProfile => 'プロフィール';

  @override
  String get settingsSectionAccount => 'アカウント';

  @override
  String get settingsSectionPreferences => '環境設定';

  @override
  String get settingsSectionAbout => '情報';

  @override
  String get settingsUsername => 'ユーザー名';

  @override
  String get settingsDisplayName => '表示名';

  @override
  String get settingsEmail => 'メール';

  @override
  String get settingsPassword => 'パスワード';

  @override
  String get settingsChange => '変更';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsThemeSystem => 'システム設定';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsPhotoVisibility => '写真の公開範囲';

  @override
  String get settingsFriendsOnly => '友だちのみ';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsTermsOfService => '利用規約';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsEdit => '編集';

  @override
  String get settingsDeleteAccount => 'アカウント削除';

  @override
  String settingsSignedInAs(String username) {
    return '@$username でログイン中';
  }

  @override
  String get settingsProfilePhoto => 'プロフィール写真';

  @override
  String get settingsTakePhoto => '写真を撮る';

  @override
  String get settingsChooseFromGallery => 'ギャラリーから選択';

  @override
  String get settingsRemovePhoto => '写真を削除';

  @override
  String get settingsAppLanguage => 'アプリの言語';

  @override
  String get settingsLanguageSystem => 'システムのデフォルト';

  @override
  String get settingsLanguageNote => '今後さらに多くの言語に対応します。言語を選ぶとアプリ全体に適用されます。';

  @override
  String get settingsVisibilityFriendsDesc =>
      'あなたの写真は友だちにのみ、そしてあなたの地図上でのみ表示されます。';

  @override
  String get settingsVisibilityFixedNote =>
      '現在は変更できません — waylo をシンプルに保ち、信頼できる人にだけ写真を公開するためです。';

  @override
  String get settingsDeleteTitle => 'アカウントを削除しますか？';

  @override
  String get settingsDeleteBody => 'アカウント、写真、友だち関係が完全に削除されます。元に戻せません。';

  @override
  String settingsCouldNotDeleteAccount(String error) {
    return 'アカウントを削除できませんでした: $error';
  }

  @override
  String get settingsUsernameHint => 'ユーザー名';

  @override
  String get settingsEnterUsername => 'ユーザー名を入力してください。';

  @override
  String settingsCouldNotUpdateUsername(String error) {
    return 'ユーザー名を変更できませんでした: $error';
  }

  @override
  String get settingsDisplayNameHint => '名前';

  @override
  String settingsCouldNotUpdateDisplayName(String error) {
    return '表示名を変更できませんでした: $error';
  }

  @override
  String get settingsEmailHint => 'you@email.com';

  @override
  String settingsCouldNotUpdateEmail(String error) {
    return 'メールを変更できませんでした: $error';
  }

  @override
  String settingsEmailChangeSent(String email) {
    return '$email に確認メールを送信しました。メール内のリンクをタップすると変更が完了します。';
  }

  @override
  String get settingsNewPassword => '新しいパスワード';

  @override
  String get settingsPasswordHint => '10文字以上、英字と数字を含む';

  @override
  String get settingsPasswordTooShort => 'パスワードは10文字以上で、英字と数字を含める必要があります。';

  @override
  String settingsCouldNotUpdatePassword(String error) {
    return 'パスワードを変更できませんでした: $error';
  }

  @override
  String settingsCouldNotUpdatePhoto(String error) {
    return '写真を変更できませんでした: $error';
  }

  @override
  String settingsCouldNotRemovePhoto(String error) {
    return '写真を削除できませんでした: $error';
  }

  @override
  String get avatarNewProfilePhoto => '新しいプロフィール写真';

  @override
  String get avatarPhotoAccessOff =>
      '写真へのアクセスがオフです。\n写真を選ぶにはアクセスを許可するか、新しく撮影してください。';

  @override
  String get avatarOpenSettings => '設定を開く';

  @override
  String avatarCouldNotCrop(String error) {
    return '写真を切り抜けませんでした: $error';
  }

  @override
  String get friendsSegRecent => '最近';

  @override
  String get friendsSegFriends => '友だち';

  @override
  String get friendsSegRequests => 'リクエスト';

  @override
  String friendsFailed(String error) {
    return '失敗: $error';
  }

  @override
  String get friendsRequestSent => 'リクエストを送信しました';

  @override
  String get friendsEmptyFriends => 'まだ友だちがいません。\n検索アイコンをタップして友だちを探しましょう。';

  @override
  String friendsCountHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '友だち$count人',
    );
    return '$_temp0';
  }

  @override
  String friendsRemoveTitle(String username) {
    return '@$username さんを削除しますか？';
  }

  @override
  String get friendsRemoveBody => 'お互いの地図が見られなくなります。';

  @override
  String get friendsRemove => '削除';

  @override
  String friendsRemoved(String username) {
    return '@$username さんを削除しました';
  }

  @override
  String get friendsEmptyRequests => '保留中のリクエストはありません。';

  @override
  String get friendsRequestsHeader => '友だちリクエスト';

  @override
  String get friendsAccept => '承認';

  @override
  String get friendsDecline => '拒否';

  @override
  String friendsAdded(String username) {
    return '@$username さんを追加しました';
  }

  @override
  String get friendsDeclined => '拒否しました';

  @override
  String friendsMutual(int count) {
    return '共通の友だち$count人';
  }

  @override
  String friendsSearchFailed(String error) {
    return '検索に失敗しました: $error';
  }

  @override
  String get friendsStatusSent => '送信済み';

  @override
  String get friendsAdd => '追加';

  @override
  String get friendsSearchHint => 'ユーザー名を検索';

  @override
  String get friendsNoOneFound => '見つかりませんでした。\n別のユーザー名を試してください。';

  @override
  String get friendsSearchPrompt => 'ユーザー名を検索して友だちを追加しましょう。';

  @override
  String get friendsNoPlaces => 'まだ場所がありません';

  @override
  String friendsCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countか国',
    );
    return '$_temp0';
  }

  @override
  String friendsCountriesMore(int count) {
    return '+$countか国';
  }

  @override
  String get friendsFindTitle => '友だちを探す';

  @override
  String get friendsJustIn => '新着';

  @override
  String get recentLast24h => '過去24時間';

  @override
  String recentPostsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '投稿$count件',
    );
    return '$_temp0';
  }

  @override
  String recentFriendsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '友だち$count人',
    );
    return '$_temp0';
  }

  @override
  String get timeNow => 'たった今';

  @override
  String timeMinutesShort(int count) {
    return '$count分';
  }

  @override
  String timeHoursShort(int count) {
    return '$count時間';
  }

  @override
  String timeDaysShort(int count) {
    return '$count日';
  }

  @override
  String get commonBack => '戻る';

  @override
  String get postNewPost => '新規投稿';

  @override
  String get postPickPhoto => '写真を選択';

  @override
  String get postRecents => '最近の項目';

  @override
  String get postPhotoAccessOff => '写真へのアクセスがオフです。\nアクセスを許可するか、写真を撮影してください。';

  @override
  String get postRatioOriginal => '元のサイズ';

  @override
  String get postRatioFree => '自由';

  @override
  String get postCropTitle => '切り抜き';

  @override
  String get postCropHint => 'フレームをドラッグ・角を引いてサイズ変更';

  @override
  String get postPreparing => '準備中…';

  @override
  String postCouldNotPrepare(String error) {
    return '写真を準備できませんでした: $error';
  }

  @override
  String get postDetailsTitle => '詳細';

  @override
  String get postInvalidCoords => '有効な緯度と経度を入力してください。';

  @override
  String get postSourceExif => '写真の位置情報から';

  @override
  String get postSourceDevice => '現在地';

  @override
  String get postSourceMapDefault => 'ドラッグしてピンを配置';

  @override
  String get postTimeAutoNote => '時刻は写真から自動的に取得されます。';

  @override
  String get postSearchPlace => '場所を検索';

  @override
  String get postPlaceNameLabel => '場所の名前';

  @override
  String get postPlaceNameHint => 'この場所に名前を付ける';

  @override
  String get postDateLabel => '日付';

  @override
  String get postCaptionLabel => 'キャプション';

  @override
  String get postCaptionOptional => '· 任意';

  @override
  String get postCaptionHint => 'この場所について一言…';

  @override
  String get postEnterCoordsManually => '座標を手動で入力';

  @override
  String get postLatLabel => '緯度';

  @override
  String get postLngLabel => '経度';

  @override
  String get postGoToCoords => '座標へ移動';

  @override
  String get postPost => '投稿';

  @override
  String get mapTabMap => '地図';

  @override
  String get mapAddPhotoTooltip => '写真を追加';

  @override
  String get mapYou => 'あなた';

  @override
  String get mapStyleLabel => '地図スタイル';

  @override
  String get mapComingSoon => '近日公開';

  @override
  String get mapSignOut => 'ログアウト';

  @override
  String get mapCustomizationComingSoon => '地図のカスタマイズは近日公開予定です。';

  @override
  String get mapPosted => '投稿しました！';

  @override
  String mapCouldNotPost(String error) {
    return '投稿できませんでした: $error';
  }

  @override
  String friendMapTitle(String username) {
    return '@$username さんの地図';
  }

  @override
  String get photoSomewhere => 'どこか';

  @override
  String get photoEditPost => '投稿を編集';

  @override
  String get photoDeletePost => '投稿を削除';

  @override
  String get photoDeleteTitle => 'この投稿を削除しますか？';

  @override
  String get photoDeleteBody => '地図から完全に削除されます。';

  @override
  String photoCouldNotSave(String error) {
    return '保存できませんでした: $error';
  }

  @override
  String photoCouldNotPostComment(String error) {
    return '投稿できませんでした: $error';
  }

  @override
  String photoCouldNotDelete(String error) {
    return '削除できませんでした: $error';
  }

  @override
  String photoLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'いいね$count件',
    );
    return '$_temp0';
  }

  @override
  String get photoNoLikes => 'まだいいねがありません';

  @override
  String get photoLike => 'いいね';

  @override
  String get photoLiked => 'いいね済み';

  @override
  String get photoComments => 'コメント';

  @override
  String photoCommentsCount(int count) {
    return 'コメント · $count';
  }

  @override
  String get photoNoComments => '最初のメッセージを残しましょう。';

  @override
  String get photoCouldNotLoad => '写真を読み込めませんでした';

  @override
  String get photoAddComment => 'コメントを入力…';

  @override
  String get photoReply => '返信';

  @override
  String photoReplyingTo(String username) {
    return '@$username さんへ返信';
  }

  @override
  String timeWeeksShort(int count) {
    return '$count週';
  }

  @override
  String get mapEmptyOwn => 'まだ写真がありません — + をタップして最初の1枚を追加。';

  @override
  String mapEmptyFriend(String username) {
    return '@$username さんはまだ写真を投稿していません。';
  }

  @override
  String get mapEmptyRecent => '過去24時間に友だちの写真はありません。';

  @override
  String get mapLoadError => '地図を読み込めませんでした。';

  @override
  String get mapGuidePost => '+ をタップして最初の写真を地図に追加しましょう。';
}
