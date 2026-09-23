// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'waylo';

  @override
  String get commonNext => '下一步';

  @override
  String get commonRetry => '重试';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSave => '保存';

  @override
  String get commonGotIt => '知道了';

  @override
  String get commonSomethingWrong => '出了点问题，请重试。';

  @override
  String get welcomeTagline => '与好友分享\n你的地点';

  @override
  String get welcomeSignUp => '免费注册';

  @override
  String get authLogIn => '登录';

  @override
  String get authEmailLabel => '邮箱';

  @override
  String get authPasswordLabel => '密码';

  @override
  String get authInvalidEmail => '请输入有效的邮箱';

  @override
  String get authEnterPassword => '请输入密码';

  @override
  String get signUpCreateAccount => '创建账户';

  @override
  String get signUpEmailQuestion => '请输入你的邮箱';

  @override
  String get signUpPasswordQuestion => '创建密码';

  @override
  String get signUpPasswordRequirements => '• 至少10个字符\n• 必须包含字母和数字';

  @override
  String get signUpBirthDateQuestion => '请告诉我们你的出生日期';

  @override
  String get signUpBirthDateHint => 'YYYY-MM-DD';

  @override
  String signUpAgeRestriction(int minAge) {
    return '须年满$minAge岁才能注册。';
  }

  @override
  String get signUpGenderQuestion => '请告诉我们你的性别';

  @override
  String get signUpGenderSelect => '选择你的性别';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get genderNonBinary => '非二元性别';

  @override
  String get genderOther => '其他';

  @override
  String get genderPreferNotToSay => '不愿透露';

  @override
  String get signUpUsernameQuestion => '设置你的用户名';

  @override
  String get signUpUsernameRequirements =>
      '• 1–30个字符\n• 可包含字母、数字、“.”和“_”\n• 不能以“.”或“_”开头或结尾\n不能有连续的“..”（两个句点）';

  @override
  String get signUpConfirmEmailNotice => '请在邮箱中确认账户后登录。';

  @override
  String get signUpUsernameTaken => '该用户名已被使用。';

  @override
  String get profileLoadError => '无法加载你的个人资料。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionProfile => '个人资料';

  @override
  String get settingsSectionAccount => '账户';

  @override
  String get settingsSectionPreferences => '偏好设置';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsUsername => '用户名';

  @override
  String get settingsDisplayName => '显示名称';

  @override
  String get settingsEmail => '邮箱';

  @override
  String get settingsPassword => '密码';

  @override
  String get settingsChange => '更改';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsPhotoVisibility => '照片可见范围';

  @override
  String get settingsFriendsOnly => '仅好友';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsTermsOfService => '服务条款';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsEdit => '编辑';

  @override
  String get settingsDeleteAccount => '删除账户';

  @override
  String settingsSignedInAs(String username) {
    return '已以 @$username 登录';
  }

  @override
  String get settingsProfilePhoto => '头像';

  @override
  String get settingsTakePhoto => '拍照';

  @override
  String get settingsChooseFromGallery => '从相册选择';

  @override
  String get settingsRemovePhoto => '删除照片';

  @override
  String get settingsAppLanguage => '应用语言';

  @override
  String get settingsLanguageSystem => '系统默认';

  @override
  String get settingsLanguageNote => '更多语言即将推出。选择语言会应用到整个应用。';

  @override
  String get settingsVisibilityFriendsDesc => '你的照片仅对好友可见，且只显示在你自己的地图上。';

  @override
  String get settingsVisibilityFixedNote =>
      '目前无法更改——这是为了让 waylo 保持简单，并只向你信任的人展示照片。';

  @override
  String get settingsDeleteTitle => '删除账户？';

  @override
  String get settingsDeleteBody => '这将永久删除你的账户、照片和好友关系，且无法撤销。';

  @override
  String settingsCouldNotDeleteAccount(String error) {
    return '无法删除账户：$error';
  }

  @override
  String get settingsUsernameHint => '用户名';

  @override
  String get settingsEnterUsername => '请输入用户名。';

  @override
  String settingsCouldNotUpdateUsername(String error) {
    return '无法更新用户名：$error';
  }

  @override
  String get settingsDisplayNameHint => '你的名字';

  @override
  String settingsCouldNotUpdateDisplayName(String error) {
    return '无法更新显示名称：$error';
  }

  @override
  String get settingsEmailHint => 'you@email.com';

  @override
  String settingsCouldNotUpdateEmail(String error) {
    return '无法更新邮箱：$error';
  }

  @override
  String settingsEmailChangeSent(String email) {
    return '我们已向 $email 发送确认链接。点击链接后邮箱才会更改。';
  }

  @override
  String get settingsNewPassword => '新密码';

  @override
  String get settingsPasswordHint => '至少10个字符，包含字母和数字';

  @override
  String get settingsPasswordTooShort => '密码至少需要10个字符，并且包含字母和数字。';

  @override
  String settingsCouldNotUpdatePassword(String error) {
    return '无法更新密码：$error';
  }

  @override
  String settingsCouldNotUpdatePhoto(String error) {
    return '无法更新照片：$error';
  }

  @override
  String settingsCouldNotRemovePhoto(String error) {
    return '无法删除照片：$error';
  }

  @override
  String get avatarNewProfilePhoto => '新头像';

  @override
  String get avatarPhotoAccessOff => '照片访问已关闭。\n请允许访问以选择照片，或拍摄新照片。';

  @override
  String get avatarOpenSettings => '打开设置';

  @override
  String avatarCouldNotCrop(String error) {
    return '无法裁剪照片：$error';
  }

  @override
  String get friendsSegRecent => '最近';

  @override
  String get friendsSegFriends => '好友';

  @override
  String get friendsSegRequests => '请求';

  @override
  String friendsFailed(String error) {
    return '失败：$error';
  }

  @override
  String get friendsRequestSent => '请求已发送';

  @override
  String get friendsEmptyFriends => '还没有好友。\n点击搜索图标查找他人。';

  @override
  String friendsCountHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 位好友',
    );
    return '$_temp0';
  }

  @override
  String friendsRemoveTitle(String username) {
    return '删除 @$username？';
  }

  @override
  String get friendsRemoveBody => '你们将不再能看到彼此的地图。';

  @override
  String get friendsRemove => '删除';

  @override
  String friendsRemoved(String username) {
    return '已删除 @$username';
  }

  @override
  String get friendsEmptyRequests => '没有待处理的请求。';

  @override
  String get friendsRequestsHeader => '好友请求';

  @override
  String get friendsAccept => '接受';

  @override
  String get friendsDecline => '拒绝';

  @override
  String friendsAdded(String username) {
    return '已添加 @$username';
  }

  @override
  String get friendsDeclined => '已拒绝';

  @override
  String friendsMutual(int count) {
    return '$count 位共同好友';
  }

  @override
  String friendsSearchFailed(String error) {
    return '搜索失败：$error';
  }

  @override
  String get friendsStatusSent => '已发送';

  @override
  String get friendsAdd => '添加';

  @override
  String get friendsSearchHint => '搜索用户名';

  @override
  String get friendsNoOneFound => '未找到任何人。\n试试其他用户名。';

  @override
  String get friendsSearchPrompt => '搜索用户名以添加好友。';

  @override
  String get friendsNoPlaces => '还没有地点';

  @override
  String friendsCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个国家',
    );
    return '$_temp0';
  }

  @override
  String friendsCountriesMore(int count) {
    return '+$count 个国家';
  }

  @override
  String get friendsFindTitle => '查找好友';

  @override
  String get friendsJustIn => '刚刚';

  @override
  String get recentLast24h => '过去24小时';

  @override
  String recentPostsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条帖子',
    );
    return '$_temp0';
  }

  @override
  String recentFriendsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 位好友',
    );
    return '$_temp0';
  }

  @override
  String get timeNow => '刚刚';

  @override
  String timeMinutesShort(int count) {
    return '$count分钟';
  }

  @override
  String timeHoursShort(int count) {
    return '$count小时';
  }

  @override
  String timeDaysShort(int count) {
    return '$count天';
  }

  @override
  String get commonBack => '返回';

  @override
  String get postNewPost => '新帖子';

  @override
  String get postPickPhoto => '选择照片';

  @override
  String get postRecents => '最近';

  @override
  String get postPhotoAccessOff => '照片访问已关闭。\n请允许访问，或拍摄照片。';

  @override
  String get postRatioOriginal => '原始';

  @override
  String get postRatioFree => '自由';

  @override
  String get postCropTitle => '裁剪';

  @override
  String get postCropHint => '拖动框 · 拉动边角调整大小';

  @override
  String get postPreparing => '准备中…';

  @override
  String postCouldNotPrepare(String error) {
    return '无法准备照片：$error';
  }

  @override
  String get postDetailsTitle => '详情';

  @override
  String get postInvalidCoords => '请输入有效的纬度和经度。';

  @override
  String get postSourceExif => '来自照片的位置';

  @override
  String get postSourceDevice => '你的当前位置';

  @override
  String get postSourceMapDefault => '拖动以放置图钉';

  @override
  String get postTimeAutoNote => '时间会自动从照片中获取。';

  @override
  String get postSearchPlace => '搜索地点';

  @override
  String get postPlaceNameLabel => '地点名称';

  @override
  String get postPlaceNameHint => '为这个地点命名';

  @override
  String get postDateLabel => '日期';

  @override
  String get postCaptionLabel => '说明';

  @override
  String get postCaptionOptional => '· 可选';

  @override
  String get postCaptionHint => '说点关于这个地点的话…';

  @override
  String get postEnterCoordsManually => '手动输入坐标';

  @override
  String get postLatLabel => '纬度';

  @override
  String get postLngLabel => '经度';

  @override
  String get postGoToCoords => '前往坐标';

  @override
  String get postPost => '发布';

  @override
  String get mapTabMap => '地图';

  @override
  String get mapAddPhotoTooltip => '添加照片';

  @override
  String get mapYou => '你';

  @override
  String get mapStyleLabel => '地图样式';

  @override
  String get mapComingSoon => '即将推出';

  @override
  String get mapSignOut => '退出登录';

  @override
  String get mapCustomizationComingSoon => '地图自定义即将推出。';

  @override
  String get mapPosted => '已发布！';

  @override
  String mapCouldNotPost(String error) {
    return '无法发布：$error';
  }

  @override
  String friendMapTitle(String username) {
    return '@$username 的地图';
  }

  @override
  String get photoSomewhere => '某处';

  @override
  String get photoEditPost => '编辑帖子';

  @override
  String get photoDeletePost => '删除帖子';

  @override
  String get photoDeleteTitle => '删除这条帖子？';

  @override
  String get photoDeleteBody => '它将从你的地图上被永久删除。';

  @override
  String photoCouldNotSave(String error) {
    return '无法保存：$error';
  }

  @override
  String photoCouldNotPostComment(String error) {
    return '无法发布：$error';
  }

  @override
  String photoCouldNotDelete(String error) {
    return '无法删除：$error';
  }

  @override
  String photoLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个赞',
    );
    return '$_temp0';
  }

  @override
  String get photoNoLikes => '还没有赞';

  @override
  String get photoLike => '赞';

  @override
  String get photoLiked => '已赞';

  @override
  String get photoComments => '评论';

  @override
  String photoCommentsCount(int count) {
    return '评论 · $count';
  }

  @override
  String get photoNoComments => '来留下第一条留言吧。';

  @override
  String get photoCouldNotLoad => '无法加载照片';

  @override
  String get photoAddComment => '添加评论…';

  @override
  String get photoReply => '回复';

  @override
  String photoReplyingTo(String username) {
    return '回复 @$username';
  }

  @override
  String timeWeeksShort(int count) {
    return '$count周';
  }

  @override
  String get mapEmptyOwn => '还没有照片——点击 + 添加你的第一张。';

  @override
  String mapEmptyFriend(String username) {
    return '@$username 还没有发布任何照片。';
  }

  @override
  String get mapEmptyRecent => '过去24小时内没有好友的照片。';

  @override
  String get mapLoadError => '无法加载地图。';

  @override
  String get mapGuidePost => '点击 + 把你的第一张照片放到地图上。';
}
