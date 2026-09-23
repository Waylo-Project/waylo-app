import 'package:flutter/widgets.dart';

/// In-app legal documents (Terms of Service, Privacy Policy).
///
/// These are kept as structured Dart content — not ARB strings — on purpose:
/// the prose is long, multi-paragraph and locale-specific, which makes ARB
/// (built for short UI labels) unwieldy. Short row labels / titles still live
/// in the ARB files; only the document bodies live here.
///
/// NOTE: this is a first-draft template tailored to waylo's actual model
/// (friends-only photos, Supabase storage, Mapbox maps). It still needs a legal
/// review before store submission — replace the contact email and confirm the
/// minimum age for your jurisdiction.
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final String intro;
  final List<LegalSection> sections;
}

class LegalSection {
  const LegalSection(this.heading, this.paragraphs);

  final String heading;
  final List<String> paragraphs;
}

/// Pick the document for the active locale (Korean, else English fallback).
LegalDocument termsOfService(Locale locale) =>
    locale.languageCode == 'ko' ? _termsKo : _termsEn;

LegalDocument privacyPolicy(Locale locale) =>
    locale.languageCode == 'ko' ? _privacyKo : _privacyEn;

// ---------------------------------------------------------------------------
// English
// ---------------------------------------------------------------------------

const _termsEn = LegalDocument(
  title: 'Terms of Service',
  lastUpdated: 'Last updated: June 29, 2026',
  intro:
      'Welcome to waylo. These Terms of Service ("Terms") govern your use of '
      'the waylo mobile app and related services (the "Service"). By creating '
      'an account or using the Service, you agree to these Terms.',
  sections: [
    LegalSection('1. The Service', [
      'waylo is a map-based photo-sharing app. You pin your photos to locations '
          'on your own map, add friends, and view your friends’ photos on '
          'their maps. Each person has their own map showing only their own '
          'photos.',
    ]),
    LegalSection('2. Your Account', [
      'You must provide accurate information when you sign up and keep it up to '
          'date. You are responsible for keeping your password secure and for '
          'all activity under your account.',
      'You must be at least 14 years old to use waylo. If you are younger, '
          'please do not create an account.',
    ]),
    LegalSection('3. Your Content', [
      'You keep ownership of the photos and other content you post. By posting, '
          'you grant waylo a limited license to store, process and display your '
          'content for the sole purpose of operating the Service — that '
          'means showing it to you and to the friends you have accepted.',
      'You are responsible for the content you post. Do not post anything that '
          'is illegal, infringes someone else’s rights, or that you do not '
          'have permission to share.',
    ]),
    LegalSection('4. Photo Visibility', [
      'A photo you post is visible only to you and to your accepted friends. '
          'Nothing on waylo is public. We do not offer a public feed, discovery '
          'or search of other people’s photos.',
    ]),
    LegalSection('5. Acceptable Use', [
      'Do not use the Service to harass others, share illegal or harmful '
          'content, attempt to access data you are not permitted to see, scrape '
          'or reverse-engineer the Service, or interfere with its operation.',
    ]),
    LegalSection('6. Termination', [
      'You can delete your account at any time from Settings. We may suspend or '
          'terminate accounts that violate these Terms.',
    ]),
    LegalSection('7. Disclaimer', [
      'The Service is provided "as is" without warranties of any kind. We do '
          'our best to keep it running but cannot guarantee it will always be '
          'available or error-free.',
    ]),
    LegalSection('8. Changes to These Terms', [
      'We may update these Terms from time to time. If we make a material '
          'change, we will let you know in the app. Continuing to use waylo '
          'after a change means you accept the updated Terms.',
    ]),
    LegalSection('9. Contact', [
      'Questions about these Terms? Contact us at support@waylo.app.',
    ]),
  ],
);

const _privacyEn = LegalDocument(
  title: 'Privacy Policy',
  lastUpdated: 'Last updated: June 29, 2026',
  intro:
      'This Privacy Policy explains what information waylo collects, how we use '
      'it, and the choices you have. We collect only what we need to run a '
      'map-based, friends-only photo app.',
  sections: [
    LegalSection('1. Information We Collect', [
      'Account information you provide when signing up: email address, '
          'username, date of birth and gender.',
      'Content you create: the photos you post and the location attached to '
          'each photo (either taken from the photo’s own metadata or the '
          'spot you place on the map).',
      'Basic usage information needed to operate the app, such as your friend '
          'connections and requests.',
    ]),
    LegalSection('2. How We Use Your Information', [
      'To provide the Service: to create your account, store your photos, place '
          'them on your map, and show them to the friends you have accepted.',
      'We do not sell your personal information, and we do not use your photos '
          'for advertising.',
    ]),
    LegalSection('3. Location Data', [
      'A photo’s location is used to place it on your map. You can '
          'fine-tune or correct the location before posting. Location comes from '
          'the photo you choose or from your device when you allow it.',
    ]),
    LegalSection('4. Who Can See Your Data', [
      'Your photos are visible only to you and your accepted friends — '
          'this rule is enforced by our database, not just the app.',
      'We use trusted service providers to run waylo: Supabase (database, '
          'authentication and photo storage) and Mapbox (the map). They process '
          'data only to provide their service to us.',
      'We may disclose information if required by law.',
    ]),
    LegalSection('5. Storage & Security', [
      'Your data is stored with Supabase. Photos live in private storage, and '
          'access is restricted by row-level security so that only you and your '
          'friends can read your content.',
    ]),
    LegalSection('6. Retention & Deletion', [
      'We keep your information while your account is active. When you delete '
          'your account from Settings, your profile, photos and related data are '
          'removed.',
    ]),
    LegalSection('7. Children', [
      'waylo is not intended for children under 14, and we do not knowingly '
          'collect their information.',
    ]),
    LegalSection('8. Your Rights', [
      'You can access and update your profile information in the app, and you '
          'can delete your account at any time. For other requests about your '
          'data, contact us.',
    ]),
    LegalSection('9. Changes to This Policy', [
      'We may update this Policy from time to time. We will notify you of '
          'material changes in the app.',
    ]),
    LegalSection('10. Contact', [
      'Questions about your privacy? Contact us at support@waylo.app.',
    ]),
  ],
);

// ---------------------------------------------------------------------------
// Korean
// ---------------------------------------------------------------------------

const _termsKo = LegalDocument(
  title: '이용약관',
  lastUpdated: '최종 수정일: 2026년 6월 29일',
  intro:
      'waylo에 오신 것을 환영합니다. 본 이용약관(이하 "약관")은 waylo 모바일 앱 및 '
      '관련 서비스(이하 "서비스") 이용에 적용됩니다. 계정을 만들거나 서비스를 '
      '이용하면 본 약관에 동의하는 것으로 간주됩니다.',
  sections: [
    LegalSection('1. 서비스 소개', [
      'waylo는 지도 기반 사진 공유 앱입니다. 내 지도 위 특정 위치에 사진을 고정하고, '
          '친구를 추가하며, 친구의 지도에서 친구의 사진을 볼 수 있습니다. 모든 사용자는 '
          '자신의 사진만 표시되는 자신만의 지도를 가집니다.',
    ]),
    LegalSection('2. 계정', [
      '가입 시 정확한 정보를 제공하고 최신 상태로 유지해야 합니다. 비밀번호를 안전하게 '
          '관리할 책임은 본인에게 있으며, 계정에서 발생하는 모든 활동에 대한 책임도 '
          '본인에게 있습니다.',
      'waylo는 만 14세 이상만 이용할 수 있습니다. 그 미만인 경우 계정을 생성하지 마세요.',
    ]),
    LegalSection('3. 사용자 콘텐츠', [
      '게시한 사진 및 기타 콘텐츠의 소유권은 사용자에게 있습니다. 콘텐츠를 게시하면, '
          '서비스 운영(즉, 본인과 수락한 친구에게 콘텐츠를 표시하는 것)을 위한 범위에 '
          '한해 waylo가 콘텐츠를 저장·처리·표시할 수 있는 제한적 권한을 부여하게 됩니다.',
      '게시하는 콘텐츠에 대한 책임은 사용자에게 있습니다. 불법적이거나 타인의 권리를 '
          '침해하는 콘텐츠, 또는 공유할 권한이 없는 콘텐츠를 게시하지 마세요.',
    ]),
    LegalSection('4. 사진 공개 범위', [
      '게시한 사진은 본인과 수락한 친구에게만 표시됩니다. waylo의 어떤 콘텐츠도 '
          '공개되지 않으며, 공개 피드·탐색·타인 사진 검색 기능을 제공하지 않습니다.',
    ]),
    LegalSection('5. 금지 행위', [
      '타인을 괴롭히거나, 불법적·유해한 콘텐츠를 공유하거나, 허용되지 않은 데이터에 '
          '접근을 시도하거나, 서비스를 스크래핑·역설계하거나, 서비스 운영을 방해하는 '
          '행위를 위해 서비스를 이용해서는 안 됩니다.',
    ]),
    LegalSection('6. 이용 종료', [
      '설정에서 언제든지 계정을 삭제할 수 있습니다. 본 약관을 위반하는 계정에 대해서는 '
          '이용을 정지하거나 종료할 수 있습니다.',
    ]),
    LegalSection('7. 면책', [
      '서비스는 어떠한 종류의 보증도 없이 "있는 그대로" 제공됩니다. 서비스를 안정적으로 '
          '운영하기 위해 최선을 다하지만, 항상 이용 가능하거나 오류가 없음을 보장하지는 '
          '않습니다.',
    ]),
    LegalSection('8. 약관 변경', [
      '본 약관은 수시로 변경될 수 있습니다. 중요한 변경이 있는 경우 앱 내에서 안내하며, '
          '변경 후에도 waylo를 계속 이용하면 변경된 약관에 동의하는 것으로 간주됩니다.',
    ]),
    LegalSection('9. 문의', [
      '본 약관에 대한 문의는 support@waylo.app 으로 연락해 주세요.',
    ]),
  ],
);

const _privacyKo = LegalDocument(
  title: '개인정보 처리방침',
  lastUpdated: '최종 수정일: 2026년 6월 29일',
  intro:
      '본 개인정보 처리방침은 waylo가 수집하는 정보, 이용 방법, 그리고 사용자의 선택권을 '
      '설명합니다. 지도 기반의 친구 전용 사진 앱을 운영하는 데 필요한 정보만 수집합니다.',
  sections: [
    LegalSection('1. 수집하는 정보', [
      '가입 시 제공하는 계정 정보: 이메일 주소, 사용자 이름, 생년월일, 성별.',
      '사용자가 생성하는 콘텐츠: 게시한 사진과 각 사진에 연결된 위치(사진 자체의 메타데이터 '
          '또는 지도에서 직접 지정한 위치).',
      '앱 운영에 필요한 기본 이용 정보(친구 관계 및 친구 요청 등).',
    ]),
    LegalSection('2. 정보 이용 목적', [
      '서비스 제공: 계정 생성, 사진 저장, 지도 표시, 그리고 수락한 친구에게 사진을 '
          '보여주기 위해 정보를 이용합니다.',
      '개인정보를 판매하지 않으며, 사진을 광고 목적으로 이용하지 않습니다.',
    ]),
    LegalSection('3. 위치 정보', [
      '사진의 위치 정보는 사진을 지도에 표시하는 데 사용됩니다. 게시 전에 위치를 세밀하게 '
          '조정하거나 수정할 수 있습니다. 위치는 선택한 사진 또는 허용 시 기기로부터 '
          '가져옵니다.',
    ]),
    LegalSection('4. 정보를 볼 수 있는 대상', [
      '사진은 본인과 수락한 친구에게만 표시됩니다. 이 규칙은 앱뿐 아니라 데이터베이스 '
          '수준에서 강제됩니다.',
      'waylo 운영을 위해 신뢰할 수 있는 서비스 제공업체를 이용합니다: Supabase(데이터베이스, '
          '인증, 사진 저장)와 Mapbox(지도). 이들은 우리에게 서비스를 제공하기 위한 범위에서만 '
          '데이터를 처리합니다.',
      '법령에서 요구하는 경우 정보를 제공할 수 있습니다.',
    ]),
    LegalSection('5. 저장 및 보안', [
      '데이터는 Supabase에 저장됩니다. 사진은 비공개 저장소에 보관되며, 행 수준 보안(RLS)에 '
          '의해 본인과 친구만 콘텐츠를 읽을 수 있도록 접근이 제한됩니다.',
    ]),
    LegalSection('6. 보관 및 삭제', [
      '계정이 활성 상태인 동안 정보를 보관합니다. 설정에서 계정을 삭제하면 프로필, 사진 및 '
          '관련 데이터가 삭제됩니다.',
    ]),
    LegalSection('7. 아동', [
      'waylo는 만 14세 미만 아동을 대상으로 하지 않으며, 해당 아동의 정보를 고의로 '
          '수집하지 않습니다.',
    ]),
    LegalSection('8. 사용자의 권리', [
      '앱에서 프로필 정보를 확인·수정할 수 있으며, 언제든지 계정을 삭제할 수 있습니다. '
          '데이터에 관한 기타 요청은 문의처로 연락해 주세요.',
    ]),
    LegalSection('9. 처리방침 변경', [
      '본 처리방침은 수시로 변경될 수 있습니다. 중요한 변경이 있는 경우 앱 내에서 '
          '안내합니다.',
    ]),
    LegalSection('10. 문의', [
      '개인정보에 관한 문의는 support@waylo.app 으로 연락해 주세요.',
    ]),
  ],
);
