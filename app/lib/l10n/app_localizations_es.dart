// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'waylo';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonGotIt => 'Entendido';

  @override
  String get commonSomethingWrong => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get welcomeTagline => 'Comparte tus lugares\ncon amigos';

  @override
  String get welcomeSignUp => 'Regístrate gratis';

  @override
  String get authLogIn => 'Iniciar sesión';

  @override
  String get authEmailLabel => 'Correo';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authInvalidEmail => 'Introduce un correo válido';

  @override
  String get authEnterPassword => 'Introduce tu contraseña';

  @override
  String get signUpCreateAccount => 'Crear cuenta';

  @override
  String get signUpEmailQuestion => '¿Cuál es tu correo?';

  @override
  String get signUpPasswordQuestion => 'Crea una contraseña';

  @override
  String get signUpPasswordRequirements =>
      '• Al menos 10 caracteres\n• Debe incluir letras y números';

  @override
  String get signUpBirthDateQuestion => '¿Cuál es tu fecha de nacimiento?';

  @override
  String get signUpBirthDateHint => 'YYYY-MM-DD';

  @override
  String signUpAgeRestriction(int minAge) {
    return 'Debes tener al menos $minAge años para registrarte.';
  }

  @override
  String get signUpGenderQuestion => '¿Cuál es tu género?';

  @override
  String get signUpGenderSelect => 'Selecciona tu género';

  @override
  String get genderMale => 'Hombre';

  @override
  String get genderFemale => 'Mujer';

  @override
  String get genderNonBinary => 'No binario';

  @override
  String get genderOther => 'Otro';

  @override
  String get genderPreferNotToSay => 'Prefiero no decirlo';

  @override
  String get signUpUsernameQuestion => '¿Cuál es tu nombre de usuario?';

  @override
  String get signUpUsernameRequirements =>
      '• 1-30 caracteres\n• Puede contener letras, números, \'.\' y \'_\'\n• No puede empezar ni terminar con \'.\' o \'_\'\nSin \'..\' consecutivos (dos puntos)';

  @override
  String get signUpConfirmEmailNotice =>
      'Revisa tu correo para confirmar tu cuenta y luego inicia sesión.';

  @override
  String get signUpUsernameTaken => 'Ese nombre de usuario ya está en uso.';

  @override
  String get profileLoadError => 'No se pudo cargar tu perfil.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionProfile => 'Perfil';

  @override
  String get settingsSectionAccount => 'Cuenta';

  @override
  String get settingsSectionPreferences => 'Preferencias';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsUsername => 'Nombre de usuario';

  @override
  String get settingsDisplayName => 'Nombre visible';

  @override
  String get settingsEmail => 'Correo';

  @override
  String get settingsPassword => 'Contraseña';

  @override
  String get settingsChange => 'Cambiar';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsThemeSystem => 'Predeterminado del sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsPhotoVisibility => 'Visibilidad de fotos';

  @override
  String get settingsFriendsOnly => 'Solo amigos';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsTermsOfService => 'Términos del servicio';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsEdit => 'Editar';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String settingsSignedInAs(String username) {
    return 'Sesión iniciada como @$username';
  }

  @override
  String get settingsProfilePhoto => 'Foto de perfil';

  @override
  String get settingsTakePhoto => 'Tomar una foto';

  @override
  String get settingsChooseFromGallery => 'Elegir de la galería';

  @override
  String get settingsRemovePhoto => 'Quitar foto';

  @override
  String get settingsAppLanguage => 'Idioma de la app';

  @override
  String get settingsLanguageSystem => 'Predeterminado del sistema';

  @override
  String get settingsLanguageNote =>
      'Pronto habrá más idiomas. Elegir un idioma actualiza toda la app.';

  @override
  String get settingsVisibilityFriendsDesc =>
      'Tus fotos son visibles para tus amigos, y solo en tu propio mapa.';

  @override
  String get settingsVisibilityFixedNote =>
      'Por ahora es fijo: mantiene waylo simple y tus fotos privadas para quienes confías.';

  @override
  String get settingsDeleteTitle => '¿Eliminar cuenta?';

  @override
  String get settingsDeleteBody =>
      'Esto elimina permanentemente tu cuenta, fotos y amistades. No se puede deshacer.';

  @override
  String settingsCouldNotDeleteAccount(String error) {
    return 'No se pudo eliminar la cuenta: $error';
  }

  @override
  String get settingsUsernameHint => 'nombre de usuario';

  @override
  String get settingsEnterUsername => 'Introduce un nombre de usuario.';

  @override
  String settingsCouldNotUpdateUsername(String error) {
    return 'No se pudo actualizar el nombre de usuario: $error';
  }

  @override
  String get settingsDisplayNameHint => 'Tu nombre';

  @override
  String settingsCouldNotUpdateDisplayName(String error) {
    return 'No se pudo actualizar el nombre visible: $error';
  }

  @override
  String get settingsEmailHint => 'tu@correo.com';

  @override
  String settingsCouldNotUpdateEmail(String error) {
    return 'No se pudo actualizar el correo: $error';
  }

  @override
  String settingsEmailChangeSent(String email) {
    return 'Enviamos un enlace de confirmación a $email. Tu correo cambia cuando lo toques.';
  }

  @override
  String get settingsNewPassword => 'Nueva contraseña';

  @override
  String get settingsPasswordHint =>
      'Al menos 10 caracteres, con letras y números';

  @override
  String get settingsPasswordTooShort =>
      'La contraseña debe tener al menos 10 caracteres e incluir letras y números.';

  @override
  String settingsCouldNotUpdatePassword(String error) {
    return 'No se pudo actualizar la contraseña: $error';
  }

  @override
  String settingsCouldNotUpdatePhoto(String error) {
    return 'No se pudo actualizar la foto: $error';
  }

  @override
  String settingsCouldNotRemovePhoto(String error) {
    return 'No se pudo quitar la foto: $error';
  }

  @override
  String get avatarNewProfilePhoto => 'Nueva foto de perfil';

  @override
  String get avatarPhotoAccessOff =>
      'El acceso a las fotos está desactivado.\nPermite el acceso para elegir una foto, o toma una nueva.';

  @override
  String get avatarOpenSettings => 'Abrir ajustes';

  @override
  String avatarCouldNotCrop(String error) {
    return 'No se pudo recortar la foto: $error';
  }

  @override
  String get friendsSegRecent => 'Reciente';

  @override
  String get friendsSegFriends => 'Amigos';

  @override
  String get friendsSegRequests => 'Solicitudes';

  @override
  String friendsFailed(String error) {
    return 'Error: $error';
  }

  @override
  String get friendsEmptyFriends =>
      'Aún no tienes amigos.\nToca la lupa para encontrar personas.';

  @override
  String friendsCountHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos',
      one: '1 amigo',
    );
    return '$_temp0';
  }

  @override
  String friendsRemoveTitle(String username) {
    return '¿Eliminar a @$username?';
  }

  @override
  String get friendsRemoveBody => 'Dejaréis de ver los mapas del otro.';

  @override
  String get friendsRemove => 'Eliminar';

  @override
  String get friendsEmptyRequests => 'No hay solicitudes pendientes.';

  @override
  String get friendsRequestsHeader => 'Quiere ser tu amigo';

  @override
  String get friendsAccept => 'Aceptar';

  @override
  String get friendsDecline => 'Rechazar';

  @override
  String friendsMutual(int count) {
    return '$count en común';
  }

  @override
  String friendsSearchFailed(String error) {
    return 'Error en la búsqueda: $error';
  }

  @override
  String get friendsStatusSent => 'Enviada';

  @override
  String get friendsAdd => 'Añadir';

  @override
  String get friendsSearchHint => 'Buscar nombre de usuario';

  @override
  String get friendsNoOneFound =>
      'No se encontró a nadie.\nPrueba con otro nombre de usuario.';

  @override
  String get friendsSearchPrompt =>
      'Busca un nombre de usuario para añadir amigos.';

  @override
  String get friendsNoPlaces => 'Aún no hay lugares';

  @override
  String friendsCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count países',
      one: '1 país',
    );
    return '$_temp0';
  }

  @override
  String friendsCountriesMore(int count) {
    return '+$count países';
  }

  @override
  String get friendsFindTitle => 'Encontrar amigos';

  @override
  String get friendsJustIn => 'NOVEDAD';

  @override
  String get recentLast24h => 'Últimas 24 h';

  @override
  String recentPostsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count publicaciones',
      one: '1 publicación',
    );
    return '$_temp0';
  }

  @override
  String recentFriendsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos',
      one: '1 amigo',
    );
    return '$_temp0';
  }

  @override
  String get timeNow => 'ahora';

  @override
  String timeMinutesShort(int count) {
    return '$count min';
  }

  @override
  String timeHoursShort(int count) {
    return '$count h';
  }

  @override
  String timeDaysShort(int count) {
    return '$count d';
  }

  @override
  String get commonBack => 'Atrás';

  @override
  String get postNewPost => 'Nueva publicación';

  @override
  String get postPhotoAccessOff =>
      'El acceso a las fotos está desactivado.\nPermite el acceso o toma una foto.';

  @override
  String get postRatioOriginal => 'Original';

  @override
  String get postRatioFree => 'Libre';

  @override
  String get postCropTitle => 'Recortar';

  @override
  String get postCropHint =>
      'Arrastra el marco · tira de una esquina para ajustar';

  @override
  String get postPreparing => 'Preparando…';

  @override
  String postCouldNotPrepare(String error) {
    return 'No se pudo preparar la foto: $error';
  }

  @override
  String get postDetailsTitle => 'Detalles';

  @override
  String get postInvalidCoords => 'Introduce una latitud y longitud válidas.';

  @override
  String get postSourceExif => 'Desde la ubicación de la foto';

  @override
  String get postSourceDevice => 'Tu ubicación actual';

  @override
  String get postSourceMapDefault => 'Arrastra para colocar el pin';

  @override
  String get postTimeAutoNote => 'La hora se toma automáticamente de la foto.';

  @override
  String get postSearchPlace => 'Buscar un lugar';

  @override
  String get postPlaceNameLabel => 'Nombre del lugar';

  @override
  String get postPlaceNameHint => 'Nombra este lugar';

  @override
  String get postDateLabel => 'Fecha';

  @override
  String get postCaptionLabel => 'Descripción';

  @override
  String get postCaptionOptional => '· opcional';

  @override
  String get postCaptionHint => 'Di algo sobre este lugar…';

  @override
  String get postEnterCoordsManually => 'Introducir coordenadas manualmente';

  @override
  String get postLatLabel => 'LAT';

  @override
  String get postLngLabel => 'LON';

  @override
  String get postGoToCoords => 'Ir a las coordenadas';

  @override
  String get postPost => 'Publicar';

  @override
  String get mapTabMap => 'Mapa';

  @override
  String get mapAddPhotoTooltip => 'Añadir foto';

  @override
  String get mapYou => 'Tú';

  @override
  String get mapSignOut => 'Cerrar sesión';

  @override
  String mapCouldNotPost(String error) {
    return 'No se pudo publicar: $error';
  }

  @override
  String friendMapTitle(String username) {
    return 'Mapa de @$username';
  }

  @override
  String get photoSomewhere => 'En algún lugar';

  @override
  String get photoEditPost => 'Editar publicación';

  @override
  String get photoDeletePost => 'Eliminar publicación';

  @override
  String get photoDeleteTitle => '¿Eliminar esta publicación?';

  @override
  String get photoDeleteBody => 'Se quitará de tu mapa para siempre.';

  @override
  String photoCouldNotSave(String error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String photoCouldNotPostComment(String error) {
    return 'No se pudo publicar: $error';
  }

  @override
  String photoCouldNotDelete(String error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String photoLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count me gusta',
      one: '1 me gusta',
    );
    return '$_temp0';
  }

  @override
  String get photoNoLikes => 'Aún no hay me gusta';

  @override
  String get photoLike => 'Me gusta';

  @override
  String get photoLiked => 'Te gusta';

  @override
  String get photoComments => 'COMENTARIOS';

  @override
  String photoCommentsCount(int count) {
    return 'COMENTARIOS · $count';
  }

  @override
  String get photoNoComments => 'Sé el primero en dejar una nota.';

  @override
  String get photoCouldNotLoad => 'No se pudo cargar la foto';

  @override
  String get photoAddComment => 'Añade un comentario…';

  @override
  String get photoReply => 'Responder';

  @override
  String photoReplyingTo(String username) {
    return 'Respondiendo a @$username';
  }

  @override
  String timeWeeksShort(int count) {
    return '$count sem';
  }

  @override
  String mapEmptyFriend(String username) {
    return '@$username aún no ha publicado fotos.';
  }

  @override
  String get mapEmptyRecent =>
      'No hay fotos de amigos en las últimas 24 horas.';

  @override
  String get mapLoadError => 'No se pudo cargar el mapa.';

  @override
  String get mapGuidePost => 'Toca + para poner tu primera foto en el mapa.';
}
