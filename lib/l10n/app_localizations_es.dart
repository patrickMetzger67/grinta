// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Grinta';

  @override
  String get heroTitle => 'Gestiona tu actividad deportiva de forma sencilla';

  @override
  String get heroSubtitle =>
      'Organiza tus eventos, administra a tus miembros y monitorea tu actividad desde una interfaz clara, moderna y responsiva.';

  @override
  String get loginTitle => 'Conexión';

  @override
  String get loginSubtitle => 'Inicia sesión para acceder a tu espacio.';

  @override
  String get email => 'Dirección de correo electrónico';

  @override
  String get emailHint => 'tu@ejemplo.com';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordHint => '••••••••';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get signIn => 'Acceso';

  @override
  String get emailAndPasswordRequired =>
      'Se requiere correo electrónico y contraseña';

  @override
  String get signInError => 'Error de conexión';

  @override
  String get userNotFound =>
      'No se encontraron usuarios para este correo electrónico';

  @override
  String get wrongPassword => 'Contraseña incorrecta';

  @override
  String get invalidEmail => 'Dirección de correo electrónico no válida';

  @override
  String get invalidCredential => 'Identificadores no válidos';

  @override
  String get tooManyRequests =>
      'Demasiados intentos. Vuelve a intentarlo más tarde';

  @override
  String get userDisabled => 'Esta cuenta ha sido desactivada.';

  @override
  String get unexpectedError => 'error inesperado';

  @override
  String get createAccount => 'Crea una cuenta';

  @override
  String get noAccountYet => '¿No tienes una cuenta?';

  @override
  String get createOneLink => 'Crea una';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get confirmPasswordHint => '••••••••';

  @override
  String get passwordRequirements =>
      'La contraseña debe tener al menos 8 caracteres e incluir una mayúscula, un dígito y un carácter especial.';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get signInLink => 'Acceso';

  @override
  String get or => 'O';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get continueWithMeta => 'Continuar con Meta';

  @override
  String get hasATeamCode => 'tengo un codigo de equipo';

  @override
  String get hasInvitationCodeQuestion => '¿Tiene un código de invitación?';

  @override
  String get invitationCode => 'Código de invitación';

  @override
  String get invitationCodeHint => 'Introduzca su código';

  @override
  String get invitationNotFound => 'Código de invitación no encontrado';

  @override
  String get invitationNotFoundContinuePrompt =>
      'Este código no existe. ¿Desea continuar creando su perfil de jugador?';

  @override
  String get invitationAlreadyUsed =>
      'Este código de invitación ya ha sido utilizado';

  @override
  String invitationSentBy(String firstName, String lastName) {
    return 'La invitación le fue enviada por $firstName $lastName';
  }

  @override
  String get signupWithoutInvitationComingSoon => 'Función próximamente';

  @override
  String get emailAlreadyInUse =>
      'Ya existe una cuenta con esta dirección de correo';

  @override
  String get invitationCodeRequired =>
      'Introduzca y valide un código de invitación';

  @override
  String get invitationChoiceRequired =>
      'Indica si tienes un código de invitación';

  @override
  String get memberProfileTitle => 'Tu perfil';

  @override
  String get memberFirstName => 'Nombre';

  @override
  String get memberLastName => 'Apellido';

  @override
  String get memberEmail => 'Correo electrónico';

  @override
  String get memberEmailOptional => 'Correo electrónico (opcional)';

  @override
  String get memberPhone => 'Teléfono';

  @override
  String get memberPhoneOptional => 'Teléfono (opcional)';

  @override
  String get memberEmailInvalid =>
      'Introduce una dirección de correo electrónico válida';

  @override
  String get memberPhoneInvalid => 'Introduce un número de teléfono válido';

  @override
  String get memberPhoneRequired =>
      'El número de teléfono es obligatorio para las invitaciones';

  @override
  String get memberEmailRequired =>
      'El correo electrónico es obligatorio para las invitaciones';

  @override
  String invitationEmailSubject(String appName) {
    return 'Tu entrenador te invita a unirte a $appName';
  }

  @override
  String invitationEmailIntro(String appName) {
    return 'Tu entrenador te invita a unirte a $appName';
  }

  @override
  String get invitationEmailCodeLabel => 'Tu código de invitación';

  @override
  String get invitationEmailDownloadIos => 'Descargar en iPhone';

  @override
  String get invitationEmailDownloadAndroid => 'Descargar en Android';

  @override
  String invitationEmailFooter(String appName) {
    return 'Has recibido este correo porque un entrenador te ha añadido en $appName. Si no esperabas este mensaje, puedes ignorarlo.';
  }

  @override
  String invitationSmsMessage(
      String appName, String code, String appleStoreUrl, String googlePlayUrl) {
    return 'Tu entrenador te invita a unirte a $appName. Tu código: $code.\niPhone: $appleStoreUrl\nAndroid: $googlePlayUrl';
  }

  @override
  String sessionReportEmailSubject(
      String appName, String eventLabel, String title) {
    return '$appName — Informe de $eventLabel: $title';
  }

  @override
  String sessionReportEmailIntro(String appName) {
    return 'Aquí tienes tu informe de estadísticas de $appName';
  }

  @override
  String get sessionReportEmailEventMatch => 'partido';

  @override
  String get sessionReportEmailEventTraining => 'entrenamiento';

  @override
  String get sessionReportEmailDetailsLabel => 'Detalles del informe';

  @override
  String get sessionReportEmailTypeLabel => 'Tipo';

  @override
  String get sessionReportEmailTitleLabel => 'Sesión';

  @override
  String get sessionReportEmailDateLabel => 'Fecha';

  @override
  String get sessionReportEmailTeamLabel => 'Equipo';

  @override
  String get sessionReportEmailPlayersLabel => 'Jugadores';

  @override
  String get sessionReportEmailAvgWorkloadLabel => 'Workload medio';

  @override
  String sessionReportEmailDateLine(String date) {
    return 'Fecha: $date';
  }

  @override
  String sessionReportEmailTeamLine(String team) {
    return 'Equipo: $team';
  }

  @override
  String sessionReportEmailPlayersLine(int count) {
    return 'Jugadores con datos: $count';
  }

  @override
  String get sessionReportEmailAttachmentHint =>
      'El informe PDF de estadísticas del tracker está adjunto a este correo.';

  @override
  String get sessionReportEmailDownloadHint =>
      'Descarga el informe PDF con el botón de abajo.';

  @override
  String get sessionReportEmailDownloadButton => 'Descargar PDF';

  @override
  String sessionReportEmailDownloadLine(String url) {
    return 'Descargar el PDF: $url';
  }

  @override
  String get sessionReportEmailAskAddress =>
      'Indícame la dirección de correo a la que enviar el informe PDF.';

  @override
  String get sessionReportEmailNoSessionYesterday =>
      'No encontré ninguna sesión para ese período.';

  @override
  String get sessionReportEmailPeriodUnclear =>
      'Precisa el período (ayer, hoy…) para el informe.';

  @override
  String sessionReportEmailFooter(String appName) {
    return 'Has recibido este correo porque se generó un informe de sesión desde $appName. Si no esperabas este mensaje, puedes ignorarlo.';
  }

  @override
  String get sessionReportEmailDialogTitle => 'Enviar informe PDF';

  @override
  String get sessionReportEmailDialogMessage =>
      'Selecciona uno o varios managers que recibirán el informe de estadísticas (PDF).';

  @override
  String get sessionReportEmailDialogHint => 'tu@ejemplo.com';

  @override
  String get sessionReportEmailDialogSend => 'Enviar';

  @override
  String get sessionReportEmailDialogCancel => 'Cancelar';

  @override
  String get sessionReportEmailActionTooltip => 'Enviar informe PDF por correo';

  @override
  String get sessionReportEmailActionLabel => 'Informe PDF';

  @override
  String sessionReportEmailSuccess(String email) {
    return 'Informe enviado a $email';
  }

  @override
  String sessionReportEmailSuccessCount(int count) {
    return 'Informe enviado a $count destinatarios';
  }

  @override
  String sessionReportEmailSelectedCount(int count) {
    return '$count seleccionado(s)';
  }

  @override
  String get sessionReportEmailSelectAll => 'Seleccionar todo';

  @override
  String get sessionReportEmailDeselectAll => 'Deseleccionar todo';

  @override
  String get sessionReportEmailNoManagers =>
      'No se encontraron managers con correo para este equipo.';

  @override
  String get sessionReportEmailManualOnlyMessage =>
      'Introduce una o varias direcciones de correo que recibirán el informe (separadas por ;).';

  @override
  String get sessionReportEmailAdditionalLabel => 'Direcciones adicionales';

  @override
  String get sessionReportEmailManualHint => 'tu@ejemplo.com; otro@ejemplo.com';

  @override
  String get sessionReportEmailManualHelper =>
      'Varias direcciones: sepáralas con punto y coma (;).';

  @override
  String get sessionReportEmailNoSelection =>
      'Selecciona un manager o introduce al menos una dirección de correo.';

  @override
  String get sessionReportEmailFailed => 'No se pudo enviar el informe PDF.';

  @override
  String get sessionReportEmailNoStats =>
      'No hay estadísticas del tracker disponibles para generar este informe.';

  @override
  String get sessionReportEmailInvalid => 'Dirección de correo no válida.';

  @override
  String get memberInvitationEmailFailed =>
      'Miembro añadido, pero no se pudo enviar el correo de invitación.';

  @override
  String get memberAddedToTeamNotificationTitle => 'Actualización del equipo';

  @override
  String memberAddedToTeamNotificationBody(String teamName) {
    return 'Tu entrenador te ha añadido a $teamName.';
  }

  @override
  String get invitationAccepted => 'Invitación aceptada';

  @override
  String get invitationPending => 'Invitación pendiente';

  @override
  String get memberAppAccountLinked => 'Cuenta de la app vinculada';

  @override
  String get resendInvitationTooltip => 'Resend invitation email';

  @override
  String get resendInvitationNoEmailTooltip =>
      'Add an email address to send an invitation';

  @override
  String get resendInvitationSuccess => 'Invitation email sent';

  @override
  String get resendInvitationFailed => 'Could not send the invitation email';

  @override
  String get memberBirthDate => 'Fecha de nacimiento';

  @override
  String get memberBirthDateOptional => 'Fecha de nacimiento (opcional)';

  @override
  String get memberBirthPlace => 'Lugar de nacimiento';

  @override
  String get memberBirthPlaceOptional => 'Lugar de nacimiento (opcional)';

  @override
  String get memberNationality => 'Nacionalidad';

  @override
  String get memberNationalityHint => 'Selecciona una nacionalidad';

  @override
  String get memberNationalitySearch => 'Buscar nacionalidad';

  @override
  String get memberPositions => 'Posiciones';

  @override
  String get memberPositionsHint =>
      'Selecciona una o más posiciones (opcional)';

  @override
  String get memberFirstNameRequired => 'El nombre es obligatorio';

  @override
  String get memberLastNameRequired => 'El apellido es obligatorio';

  @override
  String get memberBirthPlaceRequired =>
      'El lugar de nacimiento es obligatorio';

  @override
  String get memberNationalityRequired => 'La nacionalidad es obligatoria';

  @override
  String get memberContactRequired =>
      'Indica al menos un correo electrónico o un número de teléfono';

  @override
  String get memberProfileIncomplete => 'Completa tu perfil';

  @override
  String get memberProfileSubmit => 'Crear mi perfil';

  @override
  String get memberProfileUpdateSuccess => 'Perfil actualizado';

  @override
  String memberProfileUpdateError(String error) {
    return 'No se pudo actualizar el perfil: $error';
  }

  @override
  String get memberProfileChangePhoto => 'Cambiar foto';

  @override
  String get memberProfileTakePhoto => 'Tomar una foto';

  @override
  String get memberProfileChooseFromGallery => 'Elegir de la galería';

  @override
  String memberProfilePhotoUploadError(String error) {
    return 'No se pudo actualizar la foto: $error';
  }

  @override
  String get errorEditProfileUnavailable =>
      'No hay perfil disponible para editar';

  @override
  String get createTeamPromptQuestion => '¿Desea crear un equipo?';

  @override
  String get createTeamPromptLater => 'Más tarde';

  @override
  String get slide1Title => 'Gestiona tu equipo';

  @override
  String get slide1Subtitle =>
      'Centraliza tus socios, información y organización en una sola aplicación.';

  @override
  String get slide2Title => 'Planifica tus partidos';

  @override
  String get slide2Subtitle =>
      'Crea tus eventos, convoca a tus jugadores y rastrea fácilmente la disponibilidad.';

  @override
  String get slide3Title => 'Realice un seguimiento de su rendimiento';

  @override
  String get slide3Subtitle =>
      'Vea estadísticas, actividad y resultados desde una interfaz clara.';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'BORRAR';

  @override
  String get actionRetry => 'Intentar otra vez';

  @override
  String get actionClose => 'Cerca';

  @override
  String get actionOk => 'Bueno';

  @override
  String get actionYes => 'Sí';

  @override
  String get actionNo => 'No';

  @override
  String get actionValidate => 'para validar';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionReset => 'Reiniciar';

  @override
  String get actionBack => 'Atrás';

  @override
  String get actionNew => 'Nuevo';

  @override
  String get actionChoosePeriod => 'Elige un periodo';

  @override
  String get actionWeekPrevious => 'Semana -';

  @override
  String get actionWeekNext => 'Semana +';

  @override
  String get actionLoadBefore => 'Cargar hacia adelante';

  @override
  String get actionLoadAfter => 'Cargar después';

  @override
  String get actionToday => 'Hoy';

  @override
  String get actionEditProfile => 'Editar perfil';

  @override
  String get settingsMyUnavailabilities => 'Mis indisponibilidades';

  @override
  String get myUnavailabilitiesNoPlayer =>
      'Ningún perfil de jugador vinculado a tu cuenta.';

  @override
  String get myUnavailabilitiesNoSeason =>
      'Ninguna temporada seleccionada. Elige una temporada en el menú de cuenta.';

  @override
  String get actionCreateNewProfile => 'Crear un nuevo perfil';

  @override
  String get actionLogout => 'Desconectar';

  @override
  String get actionLogoutConfirmTitle => 'Desconectar';

  @override
  String get actionLogoutConfirmMessage => '¿Realmente quieres cerrar sesión?';

  @override
  String get actionCreateTeam => 'Crear un equipo';

  @override
  String get teamCreationAttachClubQuestion =>
      '¿Desea asociar este equipo a un club?';

  @override
  String get teamCreationSelectClub => 'Seleccionar un club';

  @override
  String get teamCreationClubRequired => 'Seleccione un club';

  @override
  String get teamCreationSelectClubTeams => 'Seleccionar equipos del club';

  @override
  String get teamCreationNoClubTeams => 'Ningún equipo inscrito';

  @override
  String teamCreationSelectedClubTeamsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count equipos seleccionados',
      one: '1 equipo seleccionado',
      zero: 'Ningún equipo seleccionado',
    );
    return '$_temp0';
  }

  @override
  String teamCreationClubTeamCompetitionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count competiciones',
      one: '1 competición',
    );
    return '$_temp0';
  }

  @override
  String get teamCreationSoccerType => 'Tipo de fútbol';

  @override
  String get teamCreationNoClubWarningTitle => 'Advertencia';

  @override
  String get teamCreationNoClubWarning =>
      'Este equipo no está vinculado a un club ni a una competición. En ese caso, no se recuperan automáticamente el calendario ni los resultados.';

  @override
  String equipeCompetitionsSheetTitle(String teamName) {
    return 'Competiciones — $teamName';
  }

  @override
  String fffCompetitionPhaseLabel(int phase) {
    return 'Fase $phase';
  }

  @override
  String fffCompetitionGroupeLabel(int groupe) {
    return 'Grupo $groupe';
  }

  @override
  String get hintSearchClub => 'Buscar un club';

  @override
  String get hintSearchClubTeam => 'Buscar un equipo';

  @override
  String get actionAddPlayer => 'Añadir un jugador';

  @override
  String get actionCreatePlayer => 'Crear un jugador';

  @override
  String get actionEditPlayer => 'Editar jugador';

  @override
  String get actionEditStaff => 'Editar cuerpo técnico';

  @override
  String get addPlayerPositionRequired => 'Selecciona una posición';

  @override
  String get addPlayerHeightCmOptional => 'Altura (cm, opcional)';

  @override
  String get addPlayerWeightKgOptional => 'Peso (kg, opcional)';

  @override
  String get addPlayerHeightInvalid => 'Introduce una altura entre 50 y 250 cm';

  @override
  String get addPlayerWeightInvalid => 'Introduce un peso entre 20 y 200 kg';

  @override
  String get actionAddStaff => 'Agregar un personal';

  @override
  String get actionAddZone => 'Agregar un área';

  @override
  String get actionAddToCart => 'Añadir a la cesta';

  @override
  String get actionBeginCheckout => 'Iniciar pago';

  @override
  String get actionConnect => 'Conectar';

  @override
  String get actionDownload => 'Descargar';

  @override
  String get actionEraseData => 'Borrar datos';

  @override
  String get actionChooseAsiFile => 'Elija un archivo .asi';

  @override
  String get actionDefaultValues => 'Valores predeterminados';

  @override
  String get actionRemoveCustomization => 'Eliminar personalización';

  @override
  String get actionDisconnect => 'Desconectar';

  @override
  String get actionAsiFile => 'archivo .asi';

  @override
  String get actionWeekPreviousLong => 'Semana anterior';

  @override
  String get actionWeekNextLong => 'La próxima semana';

  @override
  String get entityTeam => 'equipo';

  @override
  String entityTeamWithIndex(int index) {
    return 'Equipo $index';
  }

  @override
  String get entityTeams => 'equipos';

  @override
  String get entityPlayer => 'Jugador';

  @override
  String get entityPlayers => 'Jugadores';

  @override
  String get entityPlayerUnknown => 'Jugador desconocido';

  @override
  String get entityPlayerNotSet => 'Jugador no informado';

  @override
  String get entityStaff => 'Personal';

  @override
  String get entityMatch => 'Fósforo';

  @override
  String get entityMatches => 'Partidos';

  @override
  String get entityTraining => 'Capacitación';

  @override
  String get entityTrainings => 'Entrenamientos';

  @override
  String get entityField => 'Suelo';

  @override
  String get entityFieldUndefined => 'Tierra indefinida';

  @override
  String get entitySeason => 'Estación';

  @override
  String get entityEvent => 'evento';

  @override
  String get entityEvents => 'eventos';

  @override
  String get entityConversation => 'conversación';

  @override
  String get entityUser => 'usuario';

  @override
  String get entityProduct => 'Producto';

  @override
  String get entityCart => 'Cesta';

  @override
  String get entityApplication => 'Solicitud';

  @override
  String get entityMap => 'Mapa';

  @override
  String get entityIndicator => 'Indicador';

  @override
  String get entityDeviceId => 'ID del dispositivo';

  @override
  String get entityTracker => 'Rastreador';

  @override
  String get entityTrackerId => 'identificación';

  @override
  String get entityName => 'nombre';

  @override
  String get entityCode => 'Código';

  @override
  String get entityLabel => 'Fraseología';

  @override
  String get entityMinSpeed => 'Velocidad mínima';

  @override
  String get entityMaxSpeed => 'Velocidad máxima';

  @override
  String get entityFullMatch => 'Todo el partido';

  @override
  String get entityFullMatchShort => 'Partido completo';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navAgenda => 'Diario';

  @override
  String get navTeams => 'equipos';

  @override
  String get navChat => 'Mensajería';

  @override
  String get navSync => 'Sincronización';

  @override
  String get navNotifications => 'Notificaciones';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmptyTitle => 'Sin notificaciones';

  @override
  String get notificationsEmptyMessage => 'No tienes notificaciones sin leer.';

  @override
  String get notificationsMarkAsRead => 'Marcar como leída';

  @override
  String get notificationsMarkAsReadError =>
      'No se pudo marcar la notificación como leída.';

  @override
  String get notificationsConvocationMatchDetails => 'Detalles del partido';

  @override
  String get notificationsConvocationPresent => 'Estaré presente';

  @override
  String get notificationsConvocationAbsent => 'No presente';

  @override
  String get notificationsConvocationAbsentDialogTitle =>
      'Motivo de la ausencia';

  @override
  String get notificationsConvocationAbsentMessageHint =>
      'Explique por qué no podrá asistir';

  @override
  String get notificationsConvocationAbsentConfirm => 'Confirmar';

  @override
  String get notificationsConvocationAbsentMessageRequired =>
      'Introduzca un mensaje.';

  @override
  String get notificationsConvocationActionError =>
      'No se pudo responder a la convocatoria.';

  @override
  String get featureDiscoveryAgendaTitle => 'Descubra la agenda';

  @override
  String get featureDiscoveryAgendaMessage =>
      'Consulte sus partidos y entrenamientos desde la pestaña Agenda.';

  @override
  String get featureDiscoveryDiscover => 'Descubrir';

  @override
  String get featureDiscoveryDashboardTitle => 'Descubra el panel';

  @override
  String get featureDiscoveryDashboardMessage =>
      'Siga la actividad, estadísticas y próximos eventos desde la pestaña Panel.';

  @override
  String get featureDiscoveryChatTitle => 'Descubra la mensajería';

  @override
  String get featureDiscoveryChatMessage =>
      'Chatee con su equipo desde la pestaña Mensajería.';

  @override
  String get featureDiscoverySyncTitle => 'Descubra la sincronización';

  @override
  String get featureDiscoverySyncMessage =>
      'Suba datos del tracker y gestione dispositivos desde Sincronización.';

  @override
  String get featureDiscoveryTeamsTitle => 'Descubra los equipos';

  @override
  String get featureDiscoveryTeamsMessage =>
      'Gestione plantillas y ajustes desde la sección Equipos.';

  @override
  String get featureDiscoveryFieldsTitle => 'Descubra los campos';

  @override
  String get featureDiscoveryFieldsMessage =>
      'Localice campos para el análisis tracker desde la pestaña Campos.';

  @override
  String get featureDiscoveryCompoTitle => 'Descubra las alineaciones';

  @override
  String get featureDiscoveryCompoMessage =>
      'Cree y reutilice alineaciones desde la pestaña Composición.';

  @override
  String get featureDiscoveryMatchCompoTitle => 'Pestaña Composición';

  @override
  String get featureDiscoveryMatchCompoMessage =>
      'Vea y edite la alineación del partido en Composición.';

  @override
  String get featureDiscoveryMatchTacticalTitle => 'Pestaña Esquema táctico';

  @override
  String get featureDiscoveryMatchTacticalMessage =>
      'Coloque jugadores en el campo en Esquema táctico.';

  @override
  String get featureDiscoveryMatchHighlightsTitle => 'Pestaña Momentos clave';

  @override
  String get featureDiscoveryMatchHighlightsMessage =>
      'Revise los momentos clave en Momentos clave.';

  @override
  String get featureDiscoveryMatchStatsTitle => 'Pestaña Estadísticas';

  @override
  String get featureDiscoveryMatchStatsMessage =>
      'Explore estadísticas y mapas de calor en Estadísticas.';

  @override
  String get featureDiscoveryDismiss => 'Cerrar';

  @override
  String get navFields => 'Tierra';

  @override
  String get navCompo => 'Composición';

  @override
  String get navStatistics => 'Estadística';

  @override
  String get navOverview => 'Descripción general';

  @override
  String get navNavigation => 'Navegación';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get tabCompo => 'Composición';

  @override
  String get tabConvocations => 'Convocatorias';

  @override
  String get tabConvocationsShort => 'Convoc.';

  @override
  String get matchConvocationsSaved => 'Convocatorias guardadas';

  @override
  String get matchConvocationsUnavailable =>
      'Convocatorias no disponibles para este partido';

  @override
  String get matchPlayerUnavailableOnMatchDate =>
      'No disponible en la fecha del partido';

  @override
  String get matchPlayerCannotConvokeUnavailable =>
      'Este jugador no está disponible en la fecha del partido y no puede ser convocado.';

  @override
  String get matchConvocationsStatusPresent => 'Presencia confirmada';

  @override
  String get matchConvocationsStatusPending => 'Pendiente de respuesta';

  @override
  String get matchConvocationsSendAction => 'Enviar convocatorias';

  @override
  String get matchConvocationsSendTitle => 'Enviar convocatorias';

  @override
  String matchConvocationsSendSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores convocados',
      one: '1 jugador convocado',
    );
    return '$_temp0';
  }

  @override
  String get matchConvocationsSendMessage => 'Mensaje';

  @override
  String get matchConvocationsSendMessageHint =>
      'Información adicional para los jugadores';

  @override
  String get matchConvocationsSendMessageRequired => 'Introduce un mensaje';

  @override
  String get matchConvocationsSendTime => 'Hora de convocatoria';

  @override
  String get matchConvocationsSendAddress => 'Dirección de convocatoria';

  @override
  String get matchConvocationsSendAddressHint => 'Punto de encuentro';

  @override
  String get matchConvocationsSendAddressRequired => 'Introduce una dirección';

  @override
  String get matchConvocationsSendSubmit => 'Enviar';

  @override
  String matchConvocationsSendSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count convocatorias enviadas',
      one: '1 convocatoria enviada',
    );
    return '$_temp0';
  }

  @override
  String matchConvocationsSendSkippedNoAccount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores sin cuenta vinculada',
      one: '1 jugador sin cuenta vinculada',
    );
    return '$_temp0';
  }

  @override
  String matchConvocationsSendSkippedNoPush(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores sin notificación push',
      one: '1 jugador sin notificación push',
    );
    return '$_temp0';
  }

  @override
  String get matchConvocationsSendNoRecipients =>
      'Ningún jugador convocado tiene una cuenta Grinta vinculada.';

  @override
  String matchConvocationsSendError(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get matchConvocationsSendErrorAuth =>
      'Inicia sesión para enviar convocatorias.';

  @override
  String matchConvocationsSendDateTimeValue(String date, String time) {
    return '$date a las $time';
  }

  @override
  String matchConvocationsSendMatchLine(String opponent) {
    return 'Partido: $opponent';
  }

  @override
  String matchConvocationsSendTimeLine(String time) {
    return 'Hora: $time';
  }

  @override
  String matchConvocationsSendAddressLine(String address) {
    return 'Dirección: $address';
  }

  @override
  String matchConvocationNotificationTitle(String opponent) {
    return 'Convocatoria · $opponent';
  }

  @override
  String matchConvocationFeedbackNotificationTitle(String opponent) {
    return 'Respuesta convocatoria · $opponent';
  }

  @override
  String matchConvocationNotificationBody(String opponent, String time) {
    return '$opponent · Cita a las $time';
  }

  @override
  String matchConvocationNotificationBodyWithMessage(
      String opponent, String time, String message) {
    return '$opponent · Cita a las $time · $message';
  }

  @override
  String get tabTacticalSchema => 'Esquema táctico';

  @override
  String get tabTacticalSchemaShort => 'Esquema';

  @override
  String get matchTacticalSchemaConvocation => 'Convocar jugadores';

  @override
  String get matchTacticalSchemaConvocationHint =>
      'Opcional — limita la selección a los convocados';

  @override
  String get matchTacticalSchemaSubstitutes => 'Suplentes';

  @override
  String get matchTacticalSchemaAddSubstitute => 'Añadir suplente';

  @override
  String get matchTacticalSchemaNoSubstitutes => 'Sin suplentes';

  @override
  String get matchTacticalSchemaPickPlayer => 'Elegir jugador';

  @override
  String get matchTacticalSchemaClearSlot => 'Quitar del puesto';

  @override
  String get matchTacticalSchemaSaved => 'Esquema táctico guardado';

  @override
  String get matchTacticalSchemaEmpty =>
      'Sin esquema táctico para este partido';

  @override
  String get matchTacticalSchemaUnavailable =>
      'Esquema táctico no disponible para este partido';

  @override
  String get matchTacticalSchemaNoTeam =>
      'No se puede identificar el equipo vinculado a este partido.';

  @override
  String get matchTacticalSchemaJerseyNumber => 'Número de camiseta';

  @override
  String get matchTacticalSchemaPlayerAssignment => 'Asignación del jugador';

  @override
  String get matchTacticalSchemaJerseyNumberRequired =>
      'Indique un número de camiseta (1 a 99).';

  @override
  String get matchTacticalSchemaNoJerseyNumberAvailable =>
      'No hay números de camiseta disponibles (todos los del 1 al 99 ya están asignados).';

  @override
  String get matchTacticalSchemaRemoveFromCompo => '¿Quitar de la alineación?';

  @override
  String get matchTacticalSchemaRemoveFromCompoMessage =>
      'Este jugador se eliminará del esquema táctico (puesto y suplentes).';

  @override
  String get matchTacticalSchemaRemoveFromCompoConfirm => 'Quitar';

  @override
  String get matchTacticalSchemaSensorRequired =>
      'Seleccione un sensor disponible.';

  @override
  String get matchTacticalSchemaNoPlayerAvailable =>
      'No hay jugadores disponibles — todos los elegibles ya están en la alineación.';

  @override
  String get tabHighlights => 'Reflejos';

  @override
  String get tabStats => 'Estadística';

  @override
  String get tabStarters => 'Titulares';

  @override
  String get tabSubstitutes => 'Suplentes';

  @override
  String get tabSynthesis => 'Resumen';

  @override
  String get tabSpeedZones => 'Zonas de velocidad';

  @override
  String get tabFieldZones => 'Áreas de campo';

  @override
  String get tabHalfTimeComparison => 'Comparación del medio tiempo';

  @override
  String get tabDistanceTimeline => 'Distancia de la línea de tiempo';

  @override
  String get tabHeatmap => 'Mapa de calor';

  @override
  String get periodWeek => 'Semana';

  @override
  String get periodMonth => 'Mes';

  @override
  String get periodCustom => 'Período';

  @override
  String get periodPrep => 'Preparación física';

  @override
  String get periodPostponed => 'Aplazado';

  @override
  String periodMatchDay(String day) {
    return 'Jornada $day';
  }

  @override
  String periodSelectedWeek(String range) {
    return 'Semana seleccionada: $range';
  }

  @override
  String get periodUndefined => 'Sin periodo definido';

  @override
  String get hintSearchTeam => 'encontrar un equipo';

  @override
  String get hintSearchMember => 'Buscar un miembro';

  @override
  String get memberSearchPrompt => 'Escriba un nombre o apellido para buscar';

  @override
  String get memberAlreadyOnTeamRoster =>
      'Este miembro ya forma parte del plantel';

  @override
  String get memberAlreadyPlayer =>
      'Este miembro ya figura como jugador en el equipo';

  @override
  String get memberAlreadyStaff =>
      'Este miembro ya figura como staff en el equipo';

  @override
  String get hintSearchUser => 'Buscar un usuario';

  @override
  String get hintSearchAddress => 'Buscar una dirección o estadio';

  @override
  String get hintSelectSeason => 'Selecciona una temporada';

  @override
  String get hintFieldName => 'Nombre del terreno';

  @override
  String get hintCompoType => 'Tipo de composición';

  @override
  String get hintMetric => 'Indicador';

  @override
  String get hintDeviceIdExample => 'Ejemplo: rastreador_001';

  @override
  String get hintSpeedZoneMaxEmpty => 'Dejar en blanco para la última área';

  @override
  String get emptyNoData => 'No hay datos disponibles';

  @override
  String get emptyNoEvent => 'Sin eventos';

  @override
  String get emptyNoConversation => 'Sin conversación';

  @override
  String get emptyNoHighlights => 'Sin aspectos destacados';

  @override
  String get emptyNoCompo =>
      'No se han encontrado alineaciones para este partido.';

  @override
  String get emptyNoStarters => 'No se ha especificado ningún titular.';

  @override
  String get emptyNoSubstitutes => 'No se indica reemplazo.';

  @override
  String get emptyNoTracker => 'No se seleccionó ningún rastreador';

  @override
  String get emptyNoTrackers => 'No hay rastreadores para mostrar';

  @override
  String get emptyNoDeviceId => 'No hay ningún ID de dispositivo disponible';

  @override
  String get emptyNoFileSelected => 'No hay archivos seleccionados';

  @override
  String get emptyNoSpeedZone => 'No hay zona de velocidad disponible.';

  @override
  String get emptyNoFieldZoneData =>
      'No hay datos de la zona del terreno disponibles.';

  @override
  String get emptyNoDistanceTimeline =>
      'No hay cronograma de distancia disponible.';

  @override
  String get emptyNoStatsForMatch =>
      'No se encontraron datos para este partido.';

  @override
  String get emptyNoStatsTeamAnalysis =>
      'No se encontraron datos en TRACKER_TeamAnalysis para este partido.';

  @override
  String get emptyNoPendingMatch => 'No hay partidos pendientes.';

  @override
  String get emptyNoPendingTraining =>
      'No hay entrenamiento con rastreador pendiente.';

  @override
  String get emptyNoTeamFound => 'No se encontraron equipos';

  @override
  String get emptyNoTeamAvailable => 'No hay equipos disponibles';

  @override
  String get emptyNoTeamForSeason =>
      'No se encontraron equipos para esta temporada.';

  @override
  String get emptyNoTeamForStats =>
      'No hay equipos disponibles para ver estadísticas.';

  @override
  String get emptyNoPlayerForTeam =>
      'No se encontraron jugadores para este equipo.';

  @override
  String get trainingPlayersRecap => 'Resumen';

  @override
  String get trainingPlayersLoading => 'Cargando jugadores…';

  @override
  String get trainingPlayersClose => 'Cerrar';

  @override
  String get presencePresent => 'Presente';

  @override
  String get presenceInjured => 'Lesionado/a';

  @override
  String get presenceExcused => 'Justificado/a';

  @override
  String get presenceAbsent => 'Ausente';

  @override
  String get presenceLate => 'Retraso';

  @override
  String get presenceUnknown => '—';

  @override
  String get trainingPlayersAddPlayer => 'Añadir jugador';

  @override
  String get trainingPlayersAddPlayerTitle => 'Elegir jugador';

  @override
  String get trainingPlayersNoCandidates =>
      'Todos los jugadores del equipo ya están inscritos.';

  @override
  String get trainingPlayersChangePresence => 'Cambiar asistencia';

  @override
  String get trainingPlayersAssignTracker => 'Asignar tracker';

  @override
  String get trainingPlayersNoTrackerAvailable => 'No hay tracker disponible.';

  @override
  String get trainingPlayersSelectTracker => 'Tracker';

  @override
  String get emptyNoStaffForTeam => 'No se encontró personal para este equipo.';

  @override
  String get emptyNoPlayerSelected => 'No hay jugadores seleccionados.';

  @override
  String get emptyNoCurrentSeason => 'No hay temporada actual disponible.';

  @override
  String get emptyNoUserFound => 'No se encontraron usuarios';

  @override
  String get emptyNoUserAvailable => 'No hay usuarios disponibles';

  @override
  String get emptyNoConnectedDevice => 'No hay dispositivos conectados';

  @override
  String get emptyNoMatchToShow => 'No hay coincidencias para mostrar.';

  @override
  String get emptyNoCompoType => 'No se encontró ningún tipo de composición.';

  @override
  String get emptyNoAnalysis => 'No hay análisis disponibles';

  @override
  String get emptyNoStats => 'No hay estadísticas disponibles';

  @override
  String get emptyNoPlayersInStats =>
      'Existen estadísticas pero no hay puntuación de jugador disponible.';

  @override
  String get emptyHeatmap => 'Mapa de calor no disponible';

  @override
  String emptyNoSvgForPeriod(String period) {
    return 'No se encontró imagen SVG para $period.';
  }

  @override
  String errorGeneric(String details) {
    return 'Error: $details';
  }

  @override
  String errorLoadingResource(String resource) {
    return 'Error al cargar $resource.';
  }

  @override
  String errorFilteringResource(String resource) {
    return 'Error al filtrar $resource.';
  }

  @override
  String errorComputingStats(String resource) {
    return 'Error al calcular las estadísticas de $resource.';
  }

  @override
  String errorSaving(String details) {
    return 'Error al guardar: $details';
  }

  @override
  String errorLogout(String details) {
    return 'Error al cerrar sesión: $details';
  }

  @override
  String get errorStreamConnection => 'No se puede conectar a Stream';

  @override
  String get sessionReplacedOnAnotherDevice =>
      'Tu sesión se abrió en otro dispositivo. Vuelve a iniciar sesión.';

  @override
  String get errorOpenAnalysis =>
      'No se puede abrir el análisis: falta eventId o trackerId.';

  @override
  String get errorAgendaLoad => 'No se puede cargar el calendario';

  @override
  String errorTeamParamsLoad(String details) {
    return 'Error al cargar los parámetros: $details';
  }

  @override
  String get errorSaveTeamIdEmpty => 'No se puede guardar: teamId vacío.';

  @override
  String errorDeleteFailed(String details) {
    return 'Error al eliminar: $details';
  }

  @override
  String get errorLoadingTitle => 'Error de carga';

  @override
  String get errorCompositionTitle => 'error de composición';

  @override
  String get errorPlayerTitle => 'error del jugador';

  @override
  String get errorPlayersTitle => 'error del jugador';

  @override
  String get errorTrackerTitle => 'Error de seguimiento';

  @override
  String get errorMatchNotIdentified => 'Partido no identificado';

  @override
  String get errorPlayerNotIdentified => 'Jugador no identificado';

  @override
  String get errorPlayerNotFound => 'Jugador no encontrado';

  @override
  String get errorPlayerNotFoundInMatch => 'Jugador no encontrado';

  @override
  String get errorStatsUnavailable => 'Estadísticas no disponibles';

  @override
  String get errorNoStats => 'Sin estadísticas';

  @override
  String get errorNoStatsForPlayer =>
      'No se pueden cargar las estadísticas del jugador.';

  @override
  String get errorPlayerNotFoundMessage =>
      'No se puede encontrar el jugador seleccionado.';

  @override
  String get errorNoTrackerData =>
      'No se encontraron datos de seguimiento para este partido.';

  @override
  String get errorNoTrackerStats =>
      'No se pueden cargar las estadísticas del rastreador sin ID de coincidencia.';

  @override
  String get errorNoTrackerAnalysis =>
      'No se pueden encontrar datos de seguimiento para este reproductor.';

  @override
  String get errorMatchIdMissing => 'Falta el ID del partido.';

  @override
  String errorChatCreate(String details) {
    return 'Error al crear: $details';
  }

  @override
  String get errorCompoTitle => 'Error';

  @override
  String get errorNoCompoTitle => 'Sin composición';

  @override
  String get successSettingsSaved =>
      'La configuración se guardó correctamente.';

  @override
  String get successGpsCopied => 'GPS copiado.';

  @override
  String get successDefaultsLoaded =>
      'Valores predeterminados cargados en el formulario.';

  @override
  String successConversionDone(int count) {
    return 'Conversión terminada - $count fila(s) conservada(s)';
  }

  @override
  String get infoReadOnly => 'Solo lectura';

  @override
  String get infoWebShellOnly =>
      'Este shell está destinado únicamente a Flutter Web.';

  @override
  String get settingsLanguageLabel => 'Idioma';

  @override
  String get themeDarkModeLabel => 'Modo oscuro';

  @override
  String get themeEnableDarkModeTooltip => 'Activar modo oscuro';

  @override
  String get themeDisableDarkModeTooltip => 'Desactivar modo oscuro';

  @override
  String get infoParameters => 'Ajustes';

  @override
  String get infoUserNotConnected => 'Usuario no iniciado sesión.';

  @override
  String get dialogCloseSyncTitle => 'Cerrar definitivamente la sincronización';

  @override
  String get dialogCloseSyncMessage =>
      '¿Quieres cerrar definitivamente la sincronización? Sí: esta pantalla ya no estará disponible. No: salir sin cerrar.';

  @override
  String get dialogDeleteCustomizationTitle => '¿Eliminar personalización?';

  @override
  String get dialogDeleteAssignmentTitle => 'Eliminar tarea';

  @override
  String get dialogNewConversation => 'Nueva conversación';

  @override
  String get dialogAsiConversionTitle => 'Conversión de ASI a CSV';

  @override
  String get syncMatchesToSync => 'Partidos para sincronizar';

  @override
  String get syncNoDeviceForTraining =>
      'No se encontraron dispositivos para este entrenamiento';

  @override
  String get syncNoDeviceForMatch =>
      'No se encontraron dispositivos para este partido';

  @override
  String get statsWins => 'Victorias';

  @override
  String get statsLosses => 'Derrotas';

  @override
  String get statsDraws => 'Dummies';

  @override
  String get statsDistance => 'Distancia';

  @override
  String get statsMaxSpeed => 'Velocidad máxima';

  @override
  String get statsAvgSpeed => 'velocidad promedio';

  @override
  String get statsWorkload => 'Carga de trabajo';

  @override
  String get statsFatigue => 'Fatiga';

  @override
  String get statsDuration => 'Duración';

  @override
  String get statsSprints => 'Sprints';

  @override
  String get statsHighAccel => 'Acc. alto';

  @override
  String get statsHighSpeedTime => 'Alta velocidad';

  @override
  String get statsHighSpeedTimeShort => 'Tiempo de alta velocidad';

  @override
  String get statsMaxAccel => 'Acc. máximo';

  @override
  String get statsAxisSpeed => 'Velocidad (km/h)';

  @override
  String get statsAxisTime => 'Veces)';

  @override
  String get statsAxisAcceleration => 'Aceleración (m/s²)';

  @override
  String get statsScore => 'puntaje';

  @override
  String statsPlayersCount(int count) {
    return '$count jugadores';
  }

  @override
  String statsAvgWorkload(String value) {
    return 'Carga media $value';
  }

  @override
  String statsAvgDistance(String value) {
    return 'Distancia media $value';
  }

  @override
  String statsAvgMaxSpeed(String value) {
    return 'Vel. máx. media $value';
  }

  @override
  String statsZScore(String sign, String value) {
    return 'zScore $sign$value';
  }

  @override
  String get statsMaxAccelSample => 'Aceleración máxima: 4m/s2';

  @override
  String get speedZoneWalk => 'Caminar';

  @override
  String get speedZoneJogging => 'Correr';

  @override
  String get speedZoneRun => 'Carrera';

  @override
  String get speedZoneHighIntensity => 'Alta intensidad';

  @override
  String get speedZoneSprint => 'Sprint';

  @override
  String get highlightKickoff => 'Patada inicial';

  @override
  String get highlightFullTime => 'Fin del partido';

  @override
  String get substitutionOut => 'Salida';

  @override
  String get substitutionIn => 'Entrada';

  @override
  String get teamParamsPerformanceTitle => 'Configuración de rendimiento';

  @override
  String get teamParamsSpeedSprints => 'Velocidad y sprints';

  @override
  String get teamParamsIntensity => 'Intensidad';

  @override
  String get teamParamsGpsTimeline => 'GPS / validación / línea de tiempo';

  @override
  String get teamParamsSpeedZones => 'Zonas de velocidad';

  @override
  String get teamParamsMinOneZone => 'Se debe preservar al menos un área.';

  @override
  String get teamParamsAddSpeedZone => 'Agrega al menos una zona de velocidad.';

  @override
  String get teamParamsSprintThreshold => 'Umbral de sprint (km/h)';

  @override
  String get teamParamsSprintMinAccel => 'Mini aceleración para sprint';

  @override
  String get teamParamsSprintMinDuration => 'Duración del mini sprint';

  @override
  String get teamParamsSpeedMinDuration =>
      'Duración de velocidad mínima validada';

  @override
  String get teamParamsHighAccelThreshold => 'Umbral de aceleración fuerte';

  @override
  String get teamParamsHighAccelMinDuration =>
      'Mini duración fuerte aceleración.';

  @override
  String get teamParamsMaxStepDistance => 'Distancia máxima aceptada por paso';

  @override
  String get teamParamsMaxPlausibleSpeed => 'Velocidad máxima posible';

  @override
  String get teamParamsMaxPlausibleAccel => 'Aceleración máxima posible';

  @override
  String get teamParamsMinDeltaTime => 'Delta de tiempo mínimo';

  @override
  String get teamParamsMaxDeltaTime => 'Delta de tiempo máximo';

  @override
  String get teamParamsSmoothingWindow => 'Ventana de suavizado';

  @override
  String get teamParamsTimelineBucket => 'Línea de tiempo del cubo';

  @override
  String teamMembersPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores',
      one: '1 jugador',
    );
    return '$_temp0';
  }

  @override
  String teamMembersStaff(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros del staff',
      one: '1 miembro del staff',
    );
    return '$_temp0';
  }

  @override
  String get fieldTooltipZoomIn => 'Ampliar todo el terreno';

  @override
  String get fieldTooltipZoomOut => 'Colapsar todo terreno';

  @override
  String get fieldTooltipLengthUp => 'aumentar longitud';

  @override
  String get fieldTooltipLengthDown => 'Reducir longitud';

  @override
  String get fieldTooltipWidthUp => 'aumentar ancho';

  @override
  String get fieldTooltipWidthDown => 'Reducir el ancho';

  @override
  String get fieldTooltipRotateLeft => 'Gire a la izquierda';

  @override
  String get fieldTooltipRotateRight => 'Gire a la derecha';

  @override
  String get fieldTooltipMap => 'Mapa';

  @override
  String get fieldTooltipSatellite => 'Satélite';

  @override
  String get fieldLocateCorners => 'Localizar esquinas';

  @override
  String get fieldSnackbarLocationDisabled =>
      'El seguimiento de ubicación está deshabilitado.';

  @override
  String get fieldSnackbarAllowLocation =>
      'Permite que la ubicación centre el mapa.';

  @override
  String get fieldSnackbarGpsFailed =>
      'No se puede recuperar la posición actual.';

  @override
  String get fieldSnackbarEnterAddress =>
      'Ingrese una dirección o nombre del estadio.';

  @override
  String get fieldSnackbarMapNotReady => 'El mapa aún no está listo.';

  @override
  String get fieldSnackbarAddressNotFound => 'Dirección no encontrada.';

  @override
  String fieldSnackbarAddressNotFoundWithStatus(String status) {
    return 'Dirección no encontrada: $status';
  }

  @override
  String get fieldSnackbarGeocodingFailed =>
      'No se puede buscar esta dirección. Comprueba la clave y la API de codificación geográfica.';

  @override
  String get fieldSnackbarPlaceInMap =>
      'Coloca el terreno completamente en el mapa.';

  @override
  String get fieldSnackbarGpsConvertFailed =>
      'No se pueden convertir esquinas en posiciones GPS.';

  @override
  String get fieldHelpGestures =>
      'Campo: arrastrar para mover • 2 dedos zoom/rotar • trackpad: scroll zoom, Mayús rotar, Opción ancho, Mayús+Opción largo';

  @override
  String get compoNotFoundTitle => 'Composición no especificada';

  @override
  String get compoTypeEmptyTitle => 'Sin composición';

  @override
  String get matchStatsUnavailableTitle => 'Estadísticas no disponibles';

  @override
  String get sensorNotFoundTitle => 'Sensor no encontrado';

  @override
  String get sensorNotFoundMessage =>
      'No hay sensores asociados con este jugador para este partido.';

  @override
  String get matchHomeJersey => 'camiseta de local';

  @override
  String get matchCartTitle => 'Tu cesta';

  @override
  String get matchCartOneItem => '1 artículo - 49,90 €';

  @override
  String get asiSelectFile => 'Por favor seleccione un archivo .asi';

  @override
  String get asiEnterDeviceId => 'Por favor ingrese el ID del dispositivo';

  @override
  String get asiCannotReadFile =>
      'No se puede reproducir el archivo seleccionado';

  @override
  String get asiFileEmptyOrNoData =>
      'El archivo .asi está vacío o no contiene datos utilizables.';

  @override
  String get asiFileMismatch =>
      'El archivo no coincide con el rastreador seleccionado';

  @override
  String get asiTrackerUnknown => 'Rastreador no reconocido';

  @override
  String asiFilePickError(String details) {
    return 'Error al seleccionar el archivo: $details';
  }

  @override
  String asiConversionError(String details) {
    return 'Error durante la conversión: $details';
  }

  @override
  String get asiAnalysisFailed => 'Análisis no posible';

  @override
  String get playerSynthesisTitle => 'Resumen del jugador';

  @override
  String get playerSynthesisTabTitle => 'Resumen';

  @override
  String teamsListCount(int count) {
    return '$count equipo(s)';
  }

  @override
  String teamsListCountFiltered(int filtered, int total) {
    return '$filtered / $total';
  }

  @override
  String get teamsListNoResults => 'No se encontraron equipos';

  @override
  String get teamsListNoTeams => 'No hay equipos disponibles';

  @override
  String get teamStreamChannelSynced => 'Grupo de Stream activo';

  @override
  String get teamStreamChannelPending => 'Grupo de Stream no sincronizado';

  @override
  String get teamStreamChannelCreateTitle => '¿Crear grupo de Stream?';

  @override
  String teamStreamChannelCreateMessage(String teamName) {
    return '¿Crear el grupo de Stream para el equipo $teamName? Los jugadores y el staff se añadirán automáticamente.';
  }

  @override
  String get teamStreamChannelCreateConfirm => 'Crear';

  @override
  String get teamStreamChannelCreateLoading => 'Creando grupo de Stream…';

  @override
  String teamStreamChannelCreateSuccess(String teamName) {
    return 'Grupo de Stream creado para $teamName.';
  }

  @override
  String teamStreamChannelCreateError(String details) {
    return 'No se pudo crear el grupo de Stream: $details';
  }

  @override
  String get teamStreamChannelCreateNotManager =>
      'Solo los managers pueden crear el grupo de Stream.';

  @override
  String get navHome => 'Bienvenido';

  @override
  String get myTeams => 'mis equipos';

  @override
  String get syncTrainingsToSync => 'Entrenamientos para sincronizar';

  @override
  String get chatSelectConversation => 'Seleccione una conversación';

  @override
  String get chatStartNewHint => 'Presione \"Nuevo\" para iniciar un chat.';

  @override
  String get chatTryAnotherName => 'Prueba con otro nombre.';

  @override
  String get chatUsersAppearHere => 'Otros usuarios aparecerán aquí.';

  @override
  String get chatChannelMembersTitle => 'Miembros';

  @override
  String get chatMessageReadByTitle => 'Leído por';

  @override
  String get chatMessageNotReadYet => 'Aún no leído';

  @override
  String get matchDetailTitle => 'Detalles del partido';

  @override
  String get matchDetailVenueTitle => 'Lugar del partido';

  @override
  String get matchDetailTrackerKitTitle => 'Selección del kit';

  @override
  String get matchDetailTrackerKitLabel => 'Trackers';

  @override
  String get matchDetailTrackerKitComingSoon => 'Próximamente';

  @override
  String get matchDetailTrackerKitWithTracker => 'Con tracker';

  @override
  String get matchDetailTrackerKitWithoutTracker => 'Sin tracker';

  @override
  String get matchDetailTrackerKitSelectLabel => 'Kit';

  @override
  String get matchDetailTrackerKitNoOwners =>
      'No hay kit configurado para este equipo.';

  @override
  String get matchDetailTrackerKitSignInRequired =>
      'Inicie sesión para seleccionar un kit.';

  @override
  String playerAgeYears(int age) {
    return '$age años';
  }

  @override
  String get playerAgeUnknown => 'Edad no indicada';

  @override
  String get dateUndefined => 'Fecha no definida';

  @override
  String matchDateTimeAt(String date, String time) {
    return '$date a las $time';
  }

  @override
  String get entityComposition => 'Composición';

  @override
  String get entityDetails => 'Detalles';

  @override
  String get entityHeatmap => 'Mapa de calor';

  @override
  String get entityPeriods => 'Periodos';

  @override
  String get tabHighlightsShort => 'Tiempo';

  @override
  String get emptyNoHighlightsMessage =>
      'Aquí aparecerán goles, tarjetas y sustituciones.';

  @override
  String get matchHighlightsSourceFmi => 'Momentos clave de la FMI';

  @override
  String get matchHighlightsSourceGrinta => 'Momentos clave Grinta';

  @override
  String get matchHighlightsGrintaPlaceholderMessage =>
      'A detallar juntos más adelante.';

  @override
  String get matchGrintaHighlightsAddAction => 'Añadir momento clave';

  @override
  String get matchGrintaHighlightsPickTypeTitle =>
      'Elegir tipo de momento clave';

  @override
  String get matchGrintaHighlightsPickTimeEventTitle =>
      'Elegir evento temporal';

  @override
  String get matchGrintaHighlightsEmptyMessage =>
      'Empieza con el saque inicial con el botón +.';

  @override
  String get matchGrintaHighlightsDetailsComingSoon =>
      'Los detalles de este momento clave llegarán pronto.';

  @override
  String get matchGrintaHighlightsActionTimeEvent => 'Evento temporal';

  @override
  String get matchGrintaHighlightsAllTimeEventsRecorded =>
      'Todos los eventos temporales ya han sido registrados para este partido.';

  @override
  String get matchGrintaHighlightDeleteConfirmTitle =>
      '¿Eliminar el momento destacado?';

  @override
  String matchGrintaHighlightDeleteConfirmMessage(String highlightLabel) {
    return '¿Seguro que quieres eliminar \"$highlightLabel\"? Esta acción es permanente.';
  }

  @override
  String get matchGrintaHighlightDeleted => 'Momento destacado eliminado';

  @override
  String get matchGoalAddTitle => 'Registrar un gol';

  @override
  String get matchGoalPickTeamTitle => '¿Qué equipo marcó?';

  @override
  String get matchGoalPickScorerTitle => 'Goleador';

  @override
  String get matchGoalPickAssisterTitle => 'Asistente (opcional)';

  @override
  String get matchGoalNoAssister => 'Sin asistente';

  @override
  String get matchGoalOpponentJerseyTitle => 'Dorsal del goleador (opcional)';

  @override
  String get matchGoalOpponentJerseyHint => 'ej. 10';

  @override
  String get matchGoalScorerRequired => 'Selecciona un goleador.';

  @override
  String get matchGoalInvalidJerseyNumber => 'Introduce un dorsal válido.';

  @override
  String get matchGoalMinuteTitle => 'Minuto';

  @override
  String get matchGoalMinuteHint => 'ej. 67';

  @override
  String get matchGoalInvalidMinute => 'Introduce un minuto de al menos 1.';

  @override
  String get matchGoalSelectScorer => 'Elegir goleador';

  @override
  String get matchGoalSelectAssister => 'Elegir asistente';

  @override
  String get matchCardYellowAddTitle => 'Registrar tarjeta amarilla';

  @override
  String get matchCardRedAddTitle => 'Registrar tarjeta roja';

  @override
  String get matchCardPickTeamTitle => '¿Qué equipo recibe la tarjeta?';

  @override
  String get matchCardPickPlayerTitle => 'Jugador';

  @override
  String get matchCardSelectPlayer => 'Elegir jugador';

  @override
  String get matchCardPlayerRequired => 'Selecciona un jugador.';

  @override
  String get matchCardOpponentJerseyTitle => 'Dorsal del jugador (opcional)';

  @override
  String get matchCardOpponentJerseyHint => 'ej. 10';

  @override
  String get matchSubstitutionAddTitle => 'Registrar un cambio';

  @override
  String get matchSubstitutionPickTeamTitle => '¿Qué equipo hace el cambio?';

  @override
  String get matchSubstitutionPickOutgoingTitle => 'Jugador que sale';

  @override
  String get matchSubstitutionPickIncomingTitle => 'Jugador que entra';

  @override
  String get matchSubstitutionSelectOutgoing => 'Elegir jugador que sale';

  @override
  String get matchSubstitutionSelectIncoming => 'Elegir jugador que entra';

  @override
  String get matchSubstitutionOutgoingRequired =>
      'Selecciona al jugador que sale.';

  @override
  String get matchSubstitutionIncomingRequired =>
      'Selecciona al jugador que entra.';

  @override
  String get matchSubstitutionSamePlayerError =>
      'Los dos jugadores deben ser diferentes.';

  @override
  String get matchSubstitutionOpponentOutgoingJerseyTitle =>
      'Dorsal del jugador que sale (opcional)';

  @override
  String get matchSubstitutionOpponentIncomingJerseyTitle =>
      'Dorsal del jugador que entra (opcional)';

  @override
  String highlightGoalScored(String scorer) {
    return 'Gol — $scorer';
  }

  @override
  String get highlightTimeHalfTime => 'Descanso';

  @override
  String get highlightTimeSecondHalf => 'Segunda parte';

  @override
  String get highlightTimeStartExtraTime => 'Prórroga';

  @override
  String get highlightTypeGoal => 'Apuntar';

  @override
  String get highlightTypeSubstitution => 'Cambiar';

  @override
  String get highlightTypeYellowCard => 'tarjeta amarilla';

  @override
  String get highlightTypeRedCard => 'Tarjeta roja';

  @override
  String highlightYellowCardShown(String player) {
    return 'Tarjeta amarilla — $player';
  }

  @override
  String highlightRedCardShown(String player) {
    return 'Tarjeta roja — $player';
  }

  @override
  String get highlightTypeOwnGoal => 'Gol en propia meta';

  @override
  String get highlightTypePenalty => 'Pena';

  @override
  String get highlightTypeGeneric => 'Destacar';

  @override
  String highlightSubstitutionOut(String player) {
    return 'Sale $player';
  }

  @override
  String highlightSubstitutionIn(String incoming, String outgoing) {
    return '$incoming sustituye a $outgoing';
  }

  @override
  String get errorNoPlayersTitle => 'Sin jugadores';

  @override
  String get matchTrackerDataAvailable =>
      'Los datos del rastreador están disponibles.';

  @override
  String get matchTrackerDataPending =>
      'Los datos del rastreador aún no se han importado.';

  @override
  String get errorPlayerNoTrackerMatch =>
      'Este jugador no tiene datos de seguimiento para este partido.';

  @override
  String get trackerSyncTitle => 'Sincronización de sensores';

  @override
  String get trackerAvailableSensors => 'Sensores disponibles';

  @override
  String trackerCount(int count) {
    return '$count tracker(s)';
  }

  @override
  String get trackerAllSensorsSynced =>
      'Todos los sensores han sido sincronizados';

  @override
  String get trackerSensorsRemaining => 'Por sincronizar';

  @override
  String get trackerSensorsAlreadySynced => 'Ya sincronizados';

  @override
  String trackerSyncedProgress(int synced, int total) {
    return '$synced/$total sincronizados';
  }

  @override
  String get trackerAlreadySyncedTitle => 'Sincronización ya realizada';

  @override
  String get trackerAlreadySyncedMessage =>
      'El sensor ya se ha sincronizado para esta sesión.';

  @override
  String get trackerStatusSelected => 'Seleccionado';

  @override
  String get trackerStatusSynced => 'sincronizado';

  @override
  String get trackerStatusOpen => 'Abierto';

  @override
  String get trackerSelectForActions =>
      'Selecciona un rastreador para mostrar acciones de inicio de sesión, descarga y borrado.';

  @override
  String get trackerSelectedLabel => 'Rastreador seleccionado';

  @override
  String get trackerLogsPlaceholder => 'Los registros aparecerán aquí.';

  @override
  String get trackerNoDataOnDevice => 'No hay datos en este sensor.';

  @override
  String get trackerNoDataOnDeviceTitle =>
      'Sensor conectado — ninguna sesión que importar';

  @override
  String get trackerNoDataOnDeviceDetails =>
      'La conexión USB ha funcionado (UUID OK), pero el pod no tiene sesión registrada: actividad no iniciada o datos ya borrados. Graba una sesión en el Inspirit y vuelve a pulsar «Descargar».';

  @override
  String get trackerDownloadFailedTitle => 'Error de descarga';

  @override
  String get trackerDownloadBusyHint =>
      'Asegúrese de que no haya otra instancia de Grinta abierta.';

  @override
  String get trackerDownloadPrepareSession =>
      'Preparación USB antes de la descarga (como Desconectar y volver a Conectar)…';

  @override
  String get uploadTrackerLoading => 'Cargando...';

  @override
  String get uploadTrackerDownloadData => 'Descargar los datos';

  @override
  String get syncFieldGeolocationPromptTitle => '¿Geolocalizar el terreno?';

  @override
  String get syncFieldGeolocationPromptMessage =>
      'Las coordenadas GPS del terreno no están definidas. ¿Desea definirlas antes de descargar los datos del tracker?';

  @override
  String get trackerUsbAuthorizeHint =>
      'Ningún Inspirit autorizado para este sitio. Se abrirá Chrome: elija su Inspirit y pulse «Conectar» — no cierre la ventana.';

  @override
  String get trackerUsbPopupCancelled =>
      'Ventana de Chrome cerrada o ningún dispositivo elegido. Conecte el tracker, pulse «Conectar» de nuevo y selecciónelo en la lista.';

  @override
  String get trackerUsbPhysicalReconnect =>
      'Sesión USB caducada (cable desconectado o sensor reiniciado). Vuelva a conectar el tracker si hace falta y pulse «Conectar» — Chrome puede pedir seleccionarlo de nuevo.';

  @override
  String trackerDeviceName(String name) {
    return 'Dispositivo: $name';
  }

  @override
  String get asiImportTitle => 'Importar un archivo .asi';

  @override
  String get asiImportSubtitle =>
      'Seleccione un archivo, verifique el ID del dispositivo y luego inicie la conversión.';

  @override
  String get asiFileSelectedLabel => 'Archivo seleccionado';

  @override
  String get asiImportFileHeader => 'Importar archivo ASI';

  @override
  String get actionConvertToCsv => 'Convertir a CSV';

  @override
  String get asiConverting => 'Conversión en curso...';

  @override
  String get asiPeriodsOne => '1 período transmitido';

  @override
  String asiPeriodsMany(int count) {
    return '$count período(s) enviado(s) - los 2 primeros se usarán para los tiempos';
  }

  @override
  String get statsUnitKm => 'kilómetros';

  @override
  String get statsUnitKmh => 'kilómetros por hora';

  @override
  String get statsUnitCount => 'nótese bien';

  @override
  String get statsUnitSeconds => 'seco';

  @override
  String get statsUnitMps2 => 'm/s²';

  @override
  String get loadingSession => 'Cargando sesión...';

  @override
  String get loadingStats => 'Cargando estadísticas...';

  @override
  String get dashboardMyManagedTeams => 'Mis equipos gestionados';

  @override
  String get dashboardMatchListTitle => 'Lista de partidos';

  @override
  String periodCustomRange(String start, String end) {
    return 'del $start al $end';
  }

  @override
  String statsPresenceRate(String value) {
    return 'Tasa de presencia: ($value) %';
  }

  @override
  String get statsDoneSingular => 'comprendió';

  @override
  String get statsDonePlural => 'hecho';

  @override
  String get statsPlannedSingular => 'planificado';

  @override
  String get statsPlannedPlural => 'planificado';

  @override
  String get actionDayPrevious => 'dia anterior';

  @override
  String get actionDayNext => 'dia siguiente';

  @override
  String get actionMonthPrevious => 'Mes anterior';

  @override
  String get actionMonthNext => 'Mes próximo';

  @override
  String get actionSave => 'Ahorrar';

  @override
  String get actionSaving => 'Registro...';

  @override
  String periodLoaded(String range) {
    return 'Período cargado: $range';
  }

  @override
  String get agendaAddEventTitle => 'Crear';

  @override
  String get agendaAddEventMatch => 'Un partido / encuentro';

  @override
  String get agendaAddEventTraining => 'Una sesión de entrenamiento';

  @override
  String get agendaAddEventPersonalSport => 'Una actividad deportiva personal';

  @override
  String get agendaAddEventPersonalSportHint => 'Running, preparación, …';

  @override
  String get agendaAddEventNonSport => 'Un evento / actividad no deportiva';

  @override
  String get agendaAllDayLabel => 'All day';

  @override
  String agendaEventSummaryNonSport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
    );
    return '$_temp0';
  }

  @override
  String get createNonSportEventTitle => 'New event / activity';

  @override
  String get createNonSportEventTitleField => 'Title';

  @override
  String get createNonSportEventTitleRequired => 'Enter a title';

  @override
  String get createNonSportEventDate => 'Date';

  @override
  String get createNonSportEventTime => 'Time';

  @override
  String get createNonSportEventAllDay => 'All day';

  @override
  String get createNonSportEventStartDate => 'Start date';

  @override
  String get createNonSportEventStartTime => 'Start time';

  @override
  String get createNonSportEventEndDate => 'End date';

  @override
  String get createNonSportEventEndTime => 'End time';

  @override
  String get createNonSportEventInvalidRange => 'End must be after start.';

  @override
  String get editNonSportEventTitle => 'Edit event';

  @override
  String get editNonSportEventSubmit => 'Save';

  @override
  String get editNonSportEventSaved => 'Event updated';

  @override
  String get editNonSportEventError =>
      'Could not update the event. Please try again.';

  @override
  String get deleteNonSportEventConfirmTitle => 'Delete event?';

  @override
  String deleteNonSportEventConfirmMessage(String title) {
    return '“$title” will be permanently deleted, including related notifications.';
  }

  @override
  String get deleteNonSportEventDeleted => 'Event deleted';

  @override
  String get deleteNonSportEventError =>
      'Could not delete the event. Please try again.';

  @override
  String get createNonSportEventLocation => 'Location';

  @override
  String get createNonSportEventLocationHint => 'Address or meeting place';

  @override
  String get createNonSportEventInviteTeams => 'Invite one or more teams';

  @override
  String get createNonSportEventSelectMembers => 'Select members';

  @override
  String createNonSportEventSelectedMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members selected',
      one: '1 member selected',
    );
    return '$_temp0';
  }

  @override
  String get createNonSportEventNoTeamMembers => 'No members in this team.';

  @override
  String get createNonSportEventInviteOthers => 'Invite other profiles';

  @override
  String get createNonSportEventAddProfile => 'Add a profile';

  @override
  String get createNonSportEventInvitees => 'Invitees';

  @override
  String get createNonSportEventNoInvitees => 'No invitees yet.';

  @override
  String get createNonSportEventNoTeams =>
      'No teams available for this season.';

  @override
  String get createNonSportEventSubmit => 'Create event';

  @override
  String get createNonSportEventSaved => 'Event created';

  @override
  String get createNonSportEventError =>
      'Could not create the event. Please try again.';

  @override
  String get createNonSportEventInviteStatusSent => 'Notification sent';

  @override
  String get createNonSportEventInviteStatusNoAccount =>
      'No linked user account';

  @override
  String get createNonSportEventInviteStatusPending => 'Pending';

  @override
  String get createNonSportEventInviteStatusError => 'Notification failed';

  @override
  String get createNonSportEventNotificationTitle => 'New event';

  @override
  String createNonSportEventNotificationBody(String title, String when) {
    return '$title — $when';
  }

  @override
  String createNonSportEventNotificationBodyWithLocation(
      String title, String when, String location) {
    return '$title — $when — $location';
  }

  @override
  String get nonSportEventInviteesTitle => 'Invitations';

  @override
  String get agendaLegend => 'Leyenda';

  @override
  String agendaOverviewEventsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos',
      one: '1 evento',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidos',
      one: '1 partido',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryTrainings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrenamientos',
      one: '1 entrenamiento',
    );
    return '$_temp0';
  }

  @override
  String agendaEventSummaryPrepas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prep. físicas',
      one: '1 prep. física',
    );
    return '$_temp0';
  }

  @override
  String get agendaTrackerStatsTitle => 'Estadísticas del rastreador';

  @override
  String get teamDetailBackToTeams => 'De vuelta a los equipos';

  @override
  String teamDetailAverageAge(String age) {
    return 'Edad media: $age años';
  }

  @override
  String get teamDetailConfirmDeleteTitle => 'Confirmar eliminación';

  @override
  String teamDetailConfirmRemoveStaff(String playerName) {
    return '¿Eliminar al staff $playerName?';
  }

  @override
  String teamDetailConfirmRemovePlayerTeam(String playerName) {
    return '¿Eliminar a $playerName del equipo?';
  }

  @override
  String teamDetailPlayerRemoved(String playerName) {
    return '$playerName ha sido eliminado.';
  }

  @override
  String teamDetailPlayerTeamRemoved(String playerName) {
    return '$playerName ha sido eliminado del equipo.';
  }

  @override
  String get teamDetailColumnAge => 'Edad';

  @override
  String get teamDetailColumnPosition => 'Posición';

  @override
  String get teamDetailColumnHeight => 'Altura';

  @override
  String get teamDetailColumnWeight => 'Peso';

  @override
  String teamDetailHeightCm(int value) {
    return '$value cm';
  }

  @override
  String teamDetailWeightKg(int value) {
    return '$value kg';
  }

  @override
  String teamDetailConfirmRemoveTracker(String trackerName) {
    return '¿Eliminar la asignación del tracker «$trackerName»?';
  }

  @override
  String get teamDetailColumnApp => 'App';

  @override
  String get teamDetailPlayerDetailsTitle => 'Detalles del jugador';

  @override
  String get teamDetailGrantManager => 'Otorgar derechos de manager';

  @override
  String get teamDetailRevokeManager => 'Revocar derechos de manager';

  @override
  String get teamDetailRemoveFromTeam => 'Eliminar';

  @override
  String get teamDetailTrackerOwnersTitle => 'Trackers GPS';

  @override
  String get teamDetailTrackerOwnersEmpty =>
      'No hay kit tracker disponible para su cuenta.';

  @override
  String teamDetailTrackerOwnerType(String type) {
    return 'Tipo: $type';
  }

  @override
  String get teamDetailTrackerOwnersSaved => 'Kits tracker actualizados.';

  @override
  String get teamDetailTrackerCoachProRequiredTitle => 'Trackers GPS';

  @override
  String get teamDetailTrackerCoachProRequiredMessage =>
      'Vincular kits tracker GPS a un equipo requiere una suscripción Coach Pro.';

  @override
  String get roleCoach => 'Entrenador';

  @override
  String get roleExecutive => 'Directivo';

  @override
  String get grintaStaffRoleEducator => 'Entrenador / Educador';

  @override
  String get grintaStaffRoleMedical => 'Médico';

  @override
  String get grintaStaffRoleExecutive => 'Directivo';

  @override
  String get addStaffRoleLabel => 'Función';

  @override
  String get addStaffRoleHint => 'Elegir una función';

  @override
  String get addStaffRoleRequired => 'Seleccione una función';

  @override
  String get positionEducator => 'Educador/Entrenador';

  @override
  String get positionExecutive => 'Directivo';

  @override
  String get positionGoalkeeper => 'Portero';

  @override
  String get positionCenterBack => 'Defensa central';

  @override
  String get positionCenterBackLeft => 'Defensa central izquierdo';

  @override
  String get positionCenterBackRight => 'Defensa central derecho';

  @override
  String get positionLeftDefender => 'Defensa izquierdo';

  @override
  String get positionRightDefender => 'Defensa derecho';

  @override
  String get positionLeftBack => 'Lateral izquierdo';

  @override
  String get positionRightBack => 'Lateral derecho';

  @override
  String get positionLeftPiston => 'Carrilero izquierdo';

  @override
  String get positionRightPiston => 'Carrilero derecho';

  @override
  String get positionDefensiveMidfielder => 'Mediocampista defensivo';

  @override
  String get positionCentralMidfielder => 'Mediocampista central';

  @override
  String get positionBoxToBoxMidfielder => 'Mediocampista de contención';

  @override
  String get positionLeftMidfielder => 'Mediocampista izquierdo';

  @override
  String get positionRightMidfielder => 'Mediocampista derecho';

  @override
  String get positionAttackingMidfielder => 'Mediocampista ofensivo';

  @override
  String get positionPlaymaker => 'Organizador';

  @override
  String get positionLeftWinger => 'Extremo izquierdo';

  @override
  String get positionRightWinger => 'Extremo derecho';

  @override
  String get positionSecondStriker => 'Segundo delantero';

  @override
  String get positionCenterForward => 'Delantero centro';

  @override
  String get positionStriker => 'Goleador';

  @override
  String get positionAttacker => 'Delantero';

  @override
  String get positionDefender => 'Defensa';

  @override
  String get positionMidfielder => 'Centrocampista';

  @override
  String get positionForward => 'Delantero';

  @override
  String get teamParamsCustomThresholds => 'Umbrales personalizados';

  @override
  String get teamParamsDefaultThresholds => 'Umbrales predeterminados';

  @override
  String get teamParamsBackToTeam => 'De vuelta al equipo';

  @override
  String get teamParamsDeleteCustomizationBody =>
      'Se eliminarán las configuraciones específicas para este equipo. Luego, el equipo utilizará la configuración predeterminada.';

  @override
  String get teamParamsCustomizationRemoved =>
      'Se eliminó la personalización. Se utilizarán las configuraciones predeterminadas.';

  @override
  String teamParamsZoneMaxGreaterThanMin(String label) {
    return 'La zona \"$label\" debe tener un máximo superior al mínimo.';
  }

  @override
  String get teamParamsOnlyLastZoneEmptyMax =>
      'Sólo la última zona puede tener un terminal máximo vacío.';

  @override
  String teamParamsZonesOverlap(String zoneA, String zoneB) {
    return 'Las zonas \"$zoneA\" y \"$zoneB\" se solapan.';
  }

  @override
  String get teamParamsCustomizeZonesHint =>
      'Puede personalizar libremente las zonas utilizadas para calcular el tiempo pasado en cada zona.';

  @override
  String get teamParamsZonesReadOnly =>
      'Sólo consulta: las zonas de velocidad no se pueden modificar.';

  @override
  String get teamParamsInvalidInteger => 'Valor entero no válido';

  @override
  String get teamParamsInvalidNumber => 'Valor numérico no válido';

  @override
  String teamParamsZoneTitle(int index) {
    return 'Zona $index';
  }

  @override
  String get hintRequiredField => 'Campo requerido';

  @override
  String get fieldSnackbarGoogleMapsKeyMissing =>
      'Falta la clave de Google Maps para la búsqueda de direcciones.';

  @override
  String get fieldMapModeHelp => 'Modo mapa: mueve o amplía el mapa';

  @override
  String get fieldSideLeft => 'Lado izquierdo';

  @override
  String get fieldSideRight => 'Lado derecho';

  @override
  String get fieldEstimatedAddress => 'Dirección estimada';

  @override
  String get fieldAddressUnavailable =>
      'Dirección postal no disponible para este puesto.';

  @override
  String get fieldGpsPositionsTitle => 'Posiciones GPS del terreno';

  @override
  String get fieldAverageLength => 'longitud media';

  @override
  String get fieldAverageWidth => 'Ancho promedio';

  @override
  String get trackerParamDefault => 'Configuración predeterminada';

  @override
  String trackerParamTeam(String teamId) {
    return 'Parámetro equipo $teamId';
  }

  @override
  String get halfFirst => '1er tiempo';

  @override
  String get halfSecond => '2da mitad';

  @override
  String halfNth(int index) {
    return '$index.º tiempo';
  }

  @override
  String get halfFirstShort => '1er';

  @override
  String get halfSecondShort => '2do';

  @override
  String get halfMatchShort => 'Fósforo';

  @override
  String get tabSpeedZonesShort => 'Velocidad';

  @override
  String get fieldZoneAttackLeftShort => 'Att. IZQUIERDA';

  @override
  String get fieldZoneAttackRightShort => 'Att. BIEN';

  @override
  String get fieldZoneMidLeftShort => 'Mil. IZQUIERDA';

  @override
  String get fieldZoneMidRightShort => 'Mil. BIEN';

  @override
  String get fieldZoneDefenseLeftShort => 'Def. IZQUIERDA';

  @override
  String get fieldZoneDefenseRightShort => 'Def. BIEN';

  @override
  String get fieldZoneAttackLeft => 'Ataque de izquierda';

  @override
  String get fieldZoneAttackRight => 'ataque derecho';

  @override
  String get fieldZoneMidLeft => 'Mediocampista izquierdo';

  @override
  String get fieldZoneMidRight => 'Medio derecho';

  @override
  String get fieldZoneDefenseLeft => 'Defensa izquierda';

  @override
  String get fieldZoneDefenseRight => 'Defensa derecha';

  @override
  String get halfFirstUnavailable => '1.ª mitad no disponible';

  @override
  String get halfSecondUnavailable => '2da mitad no disponible';

  @override
  String asiHeatmapPointCount(int count, String period) {
    return '$count punto(s) - $period';
  }

  @override
  String metricsEvolutionTitle(String metric) {
    return 'Evolución - $metric';
  }

  @override
  String trainingOnDate(String date) {
    return 'Entrenamiento del $date';
  }

  @override
  String get subscriptionPaywallTitle => 'Pasa a Grinta Premium';

  @override
  String get subscriptionPaywallSubtitle =>
      'Desbloquea todas las funciones para el seguimiento de tus equipos y jugadores.';

  @override
  String get subscriptionPaywallLater => 'Más tarde';

  @override
  String get subscriptionOfferingCoach => 'Entrenador';

  @override
  String get subscriptionOfferingPlayer => 'Jugador';

  @override
  String get subscriptionTierCoachBasic => 'Coach Basic';

  @override
  String get subscriptionTierCoachBasicDesc =>
      'Gestión esencial del equipo: calendario, plantilla y estadísticas básicas.';

  @override
  String get subscriptionTierCoachElite => 'Coach Elite';

  @override
  String get subscriptionTierCoachEliteDesc =>
      'Análisis avanzados, alineaciones tácticas y herramientas completas.';

  @override
  String get subscriptionTierCoachPro => 'Coach Pro';

  @override
  String get subscriptionTierCoachProDesc =>
      'Todo Elite, más tracker GPS, mapas de calor y exportaciones pro.';

  @override
  String get subscriptionTierPlayer => 'Jugador';

  @override
  String get subscriptionTierPlayerDesc =>
      'Sigue tu rendimiento, estadísticas personales y progreso.';

  @override
  String get subscriptionPerMonth => '/mes';

  @override
  String get subscriptionPerYear => '/año';

  @override
  String get subscriptionBillingMonthly => 'Mensual';

  @override
  String get subscriptionBillingYearly => 'Anual';

  @override
  String get subscriptionAnnualSavings => '2 meses gratis';

  @override
  String get subscriptionSubscribe => 'Suscribirse';

  @override
  String get subscriptionTierActive => 'Suscripción activa';

  @override
  String get subscriptionRestorePurchases => 'Restaurar compras';

  @override
  String get subscriptionAutoRenewLegal =>
      'La suscripción se renueva automáticamente. Puedes cancelarla en cualquier momento en Ajustes de App Store o Google Play.';

  @override
  String get subscriptionStoreUnavailable =>
      'Las compras integradas no están disponibles en esta plataforma.';

  @override
  String get subscriptionAlreadyActive => 'Ya tienes una suscripción activa.';

  @override
  String get subscriptionProductNotFound =>
      'Producto no encontrado. Comprueba la configuración de RevenueCat.';

  @override
  String get subscriptionOfferingsUnavailable =>
      'No se pudieron cargar los planes de suscripción. Comprueba tu conexión y la offering web de RevenueCat, e inténtalo de nuevo.';

  @override
  String get subscriptionPurchaseFailed =>
      'La compra ha fallado. Inténtalo de nuevo.';

  @override
  String get subscriptionRestoreNone => 'No hay compras que restaurar.';

  @override
  String get subscriptionRestoreFailed => 'Error al restaurar.';

  @override
  String get subscriptionPromptTitle => 'Hazte Premium';

  @override
  String get subscriptionPromptMessage =>
      'Accede a todas las funciones de Grinta con un plan adaptado a tu perfil.';

  @override
  String get subscriptionPromptAction => 'Ver planes';

  @override
  String get subscriptionMenu => 'Suscripción';

  @override
  String get subscriptionDetailsTitle => 'Suscripción';

  @override
  String get subscriptionTier => 'Plan';

  @override
  String subscriptionRenewalDate(String date) {
    return 'Renovación el $date';
  }

  @override
  String get subscriptionNone => 'Sin suscripción activa';

  @override
  String subscriptionTrialEnds(String date) {
    return 'Fin de la prueba el $date';
  }

  @override
  String get subscriptionPeriodLabel => 'Periodo';

  @override
  String get subscriptionRenewalLabel => 'Renovación';

  @override
  String get subscriptionBillingPeriodMonthly => 'Mensual';

  @override
  String get subscriptionBillingPeriodYearly => 'Anual';

  @override
  String get subscriptionStatusActive => 'Activo';

  @override
  String get subscriptionChangePlan => 'Cambiar plan';

  @override
  String get subscriptionChangePlanTitle => 'Modificar suscripción';

  @override
  String get subscriptionChangePlanSubtitle =>
      'Cambia entre Entrenador y Jugador, modifica el nivel o el periodo de facturación.';

  @override
  String get subscriptionChangePlanConfirm => 'Confirmar cambio';

  @override
  String get subscriptionCurrentPlan => 'Plan actual';

  @override
  String get subscriptionPlanChanged => 'Tu suscripción se ha actualizado.';

  @override
  String subscriptionLimitMaxTeamsReached(int max) {
    return 'Has alcanzado el número máximo de equipos ($max) para tu suscripción.';
  }

  @override
  String subscriptionLimitMaxPlayersReached(int max) {
    return 'Has alcanzado el número máximo de jugadores ($max) para este equipo.';
  }

  @override
  String get subscriptionLimitPlayerTierOnlySelf =>
      'Tu suscripción Jugador solo te permite añadirte a ti mismo a un equipo.';

  @override
  String subscriptionLimitMaxProfilesReached(int max) {
    return 'Has alcanzado el número máximo de perfiles ($max) para tu suscripción.';
  }

  @override
  String get subscriptionLimitProfileUpgradeTitle => 'Perfiles adicionales';

  @override
  String get subscriptionLimitProfileUpgradeMessage =>
      'Pasa a una suscripción de pago para crear perfiles adicionales.';

  @override
  String get subscriptionLimitProfileCoachBasicTitle => 'Perfiles adicionales';

  @override
  String get subscriptionLimitProfileCoachBasicMessage =>
      'Pasa a Elite o Pro para crear hasta 3 perfiles.';

  @override
  String get subscriptionLimitProfilePremiumBadge => 'Premium';

  @override
  String get subscriptionLimitTeamUpgradeTitle => 'Equipos adicionales';

  @override
  String get subscriptionLimitTeamUpgradeMessage =>
      'Pase a la suscripción Jugador para crear más equipos y gestionar su plantilla.';

  @override
  String get subscriptionLimitTeamCoachBasicTitle => 'Equipos adicionales';

  @override
  String get subscriptionLimitTeamCoachBasicMessage =>
      'Pase a Elite o Pro para crear más equipos.';

  @override
  String get subscriptionLimitTeamDetailBlockedTitle => 'Gestión del equipo';

  @override
  String get subscriptionLimitTeamDetailBlockedMessage =>
      'Pase a la suscripción Jugador para acceder a los detalles del equipo y gestionar su plantilla.';

  @override
  String get subscriptionLimitTeamCreatedFreePlayer =>
      'Su equipo ha sido creado. Actualice su suscripción para acceder a los detalles.';

  @override
  String get trialStatusTitle => 'Prueba gratuita';

  @override
  String trialDaysRemaining(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días restantes',
      one: '1 día restante',
    );
    return '$_temp0';
  }

  @override
  String get shopTitle => 'Tienda Grinta';

  @override
  String get shopPromoTitle => 'Oferta de la tienda';

  @override
  String get shopPromoCta => 'Ver oferta';

  @override
  String get shopBrowseAll => 'Ver tienda';

  @override
  String get shopLoadError => 'No se pudo cargar la tienda.';

  @override
  String get shopRetry => 'Reintentar';

  @override
  String get legalPrivacyPolicy => 'Política de privacidad';

  @override
  String get legalTermsOfService => 'Términos de servicio';

  @override
  String get actionDeleteAccount => 'Eliminar cuenta';

  @override
  String get actionDeleteAccountConfirmTitle => '¿Eliminar cuenta?';

  @override
  String get actionDeleteAccountConfirmMessage =>
      'Esta acción es permanente. Se eliminarán tu cuenta, tu perfil de miembro y los datos asociados.';

  @override
  String errorDeleteAccount(String details) {
    return 'No se pudo eliminar la cuenta: $details';
  }

  @override
  String get errorDeleteAccountRequiresRecentLogin =>
      'Por seguridad, cierra sesión, vuelve a iniciar sesión e inténtalo de nuevo.';

  @override
  String get actionDeleteTeam => 'Eliminar equipo';

  @override
  String get teamDeleteConfirmTitle => '¿Eliminar equipo?';

  @override
  String teamDeleteConfirmMessage(String teamName) {
    return '¿Seguro que quieres eliminar «$teamName»? Esta acción es permanente. Se eliminarán todos los datos relacionados con el equipo (miembros, partidos, estadísticas, etc.).';
  }

  @override
  String teamDeleteSuccess(String teamName) {
    return 'El equipo «$teamName» ha sido eliminado.';
  }

  @override
  String get teamEditNameTitle => 'Modifier le nom de l\'équipe';

  @override
  String get teamEditNameSuccess => 'Nom de l\'équipe mis à jour.';

  @override
  String get calendarSyncToggleLabel => 'Sync. calendario';

  @override
  String get calendarSyncToggleSubtitle =>
      'Actualización al abrir la agenda (máx. 1×/15 min)';

  @override
  String get calendarSyncWebSubtitle =>
      'Descarga un archivo ICS para importarlo en tu calendario';

  @override
  String get calendarSyncWebRedownloadHint =>
      'Toca para volver a descargar el archivo del calendario';

  @override
  String get calendarSyncWebDownloaded =>
      'Archivo de calendario descargado. Impórtalo en tu aplicación de calendario.';

  @override
  String get calendarSyncPermissionDenied =>
      'Se denegó el acceso al calendario. Actívalo en los ajustes del dispositivo.';

  @override
  String get calendarSyncCalendarCreationFailed =>
      'No se pudo crear el calendario de Grinta en este dispositivo.';

  @override
  String get calendarSyncEnableFailed =>
      'No se pudo activar la sincronización del calendario. Inténtalo de nuevo.';

  @override
  String get calendarSyncForceNow => 'Sincronizar ahora';

  @override
  String get calendarSyncForceSuccess => 'Calendario sincronizado.';

  @override
  String get calendarSyncForceFailed =>
      'Error de sincronización. Inténtalo de nuevo.';

  @override
  String get settingsDevicesSection => 'Appareils/Applications';

  @override
  String get settingsDevicesClose => 'Fermer';

  @override
  String get settingsDevicesSync => 'Synchroniser';

  @override
  String get settingsDevicesConnectedTitle =>
      'Appareils/applications connectés';

  @override
  String get settingsDevicesConnectedStatus => 'Connecté';

  @override
  String get settingsDevicesDisconnect => 'Déconnecter';

  @override
  String get settingsDevicesNoConnected =>
      'Aucun appareil ou application connecté';

  @override
  String get settingsDevicesAddTitle => 'Ajouter une connexion';

  @override
  String get settingsDevicesAddFabTooltip => 'Ajouter une connexion';

  @override
  String get settingsDevicesAllConnected =>
      'Tous les appareils/applications disponibles sont déjà connectés';

  @override
  String settingsDevicesBadgeLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils/applications connectés',
      one: '1 appareil/application connecté',
      zero: 'Aucun appareil/application connecté',
    );
    return '$_temp0';
  }

  @override
  String get wearableDeviceTypeLabel => 'Type d\'appareil/application';

  @override
  String get wearableDeviceWhoop => 'Whoop';

  @override
  String get wearableDeviceStrava => 'Strava';

  @override
  String get wearableDevicePolar => 'Polar';

  @override
  String get wearableDeviceFitbit => 'Fitbit';

  @override
  String get wearableDeviceAppleHealth => 'Apple Forme';

  @override
  String get wearableDeviceGoogleHealthConnect => 'Google Fit / Health Connect';

  @override
  String get whoopConnectToggleLabel => 'Sync. Whoop';

  @override
  String get whoopConnectToggleSubtitle =>
      'Connecte ton compte Whoop pour importer récupération, sommeil et entraînements';

  @override
  String get whoopConnectToggleConnectedSubtitle =>
      'Whoop connecté — synchronisation des données à venir (Phase 2)';

  @override
  String get whoopConnectSuccess => 'Compte Whoop connecté.';

  @override
  String get whoopAccountHintGuidance =>
      'L\'email Whoop peut être différent de ton compte Grinta. Indique le compte Whoop à utiliser, puis connecte-toi avec ce compte sur la page Whoop.';

  @override
  String get whoopAccountHintLabel => 'Compte Whoop';

  @override
  String get whoopAccountHintPlaceholder => 'email Whoop';

  @override
  String get whoopAccountHintRequired =>
      'Indique ton compte Whoop (email) avant de continuer.';

  @override
  String get whoopConnectContinue => 'Continuer vers Whoop';

  @override
  String get whoopConnectFailed =>
      'La connexion Whoop a échoué. Vérifie que les Cloud Functions Whoop sont déployées et que les secrets WHOOP_CLIENT_ID / WHOOP_CLIENT_SECRET sont configurés.';

  @override
  String get whoopConnectLaunchFailed =>
      'Impossible d\'ouvrir la page de connexion Whoop.';

  @override
  String get whoopConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Whoop.';

  @override
  String get whoopDisconnectFailed => 'La déconnexion Whoop a échoué.';

  @override
  String get whoopCoachVisibilityTitle => 'Visibilité coach';

  @override
  String get whoopCoachVisibilitySubtitle =>
      'Autoriser ton coach à voir cette donnée';

  @override
  String get whoopCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Whoop.';

  @override
  String get whoopMetricRecovery => 'Récupération';

  @override
  String get whoopMetricCycles => 'Cycles';

  @override
  String get whoopMetricSleep => 'Sommeil';

  @override
  String get whoopMetricWorkout => 'Entraînements';

  @override
  String get whoopMetricProfile => 'Profil';

  @override
  String get whoopMetricBodyMeasurement => 'Mensurations';

  @override
  String get whoopCoachConnectTitle => 'Whoop';

  @override
  String whoopCoachConnectSubtitle(String playerName) {
    return 'Connecter le compte Whoop de $playerName';
  }

  @override
  String get whoopCoachConnectAction => 'Connecter';

  @override
  String whoopCoachConnectConnectedSubtitle(String playerName) {
    return 'Whoop connecté pour $playerName';
  }

  @override
  String get stravaConnectToggleSubtitle =>
      'Connecte ton compte Strava pour importer activités et entraînements';

  @override
  String get stravaConnectToggleConnectedSubtitle =>
      'Strava connecté — synchronisation des données à venir (Phase 2)';

  @override
  String get stravaAccountHintGuidance =>
      'L\'email Strava peut être différent de ton compte Grinta. Indique le compte Strava à utiliser, puis connecte-toi avec ce compte sur la page Strava.';

  @override
  String get stravaAccountHintLabel => 'Compte Strava';

  @override
  String get stravaAccountHintPlaceholder =>
      'email ou nom d\'utilisateur Strava';

  @override
  String get stravaAccountHintRequired =>
      'Indique ton compte Strava (email ou nom d\'utilisateur) avant de continuer.';

  @override
  String get stravaConnectContinue => 'Continuer vers Strava';

  @override
  String get stravaConnectSuccess => 'Compte Strava connecté.';

  @override
  String get stravaConnectFailed =>
      'La connexion Strava a échoué. Vérifie que les Cloud Functions Strava sont déployées et que les secrets STRAVA_CLIENT_ID / STRAVA_CLIENT_SECRET sont configurés.';

  @override
  String get stravaConnectLaunchFailed =>
      'Impossible d\'ouvrir la page de connexion Strava.';

  @override
  String get stravaConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Strava.';

  @override
  String get stravaDisconnectFailed => 'La déconnexion Strava a échoué.';

  @override
  String get stravaCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Strava.';

  @override
  String get stravaMetricActivities => 'Activités';

  @override
  String get stravaMetricProfile => 'Profil';

  @override
  String stravaCoachConnectSubtitle(String playerName) {
    return 'Connecter le compte Strava de $playerName';
  }

  @override
  String stravaCoachConnectConnectedSubtitle(String playerName) {
    return 'Strava connecté pour $playerName';
  }

  @override
  String get polarConnectToggleSubtitle =>
      'Connecte ton compte Polar pour importer entraînements, sommeil et fréquence cardiaque depuis Loop ou Verity Sense via Polar Flow';

  @override
  String get polarConnectToggleConnectedSubtitle =>
      'Polar connecté — synchronisation des données à venir (Phase 2)';

  @override
  String get polarConnectSuccess => 'Compte Polar connecté.';

  @override
  String get polarConnectFailed => 'La connexion Polar a échoué. Réessayez.';

  @override
  String get polarConnectLaunchFailed =>
      'Impossible d\'ouvrir la page de connexion Polar.';

  @override
  String get polarConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Polar.';

  @override
  String get polarDisconnectFailed => 'La déconnexion Polar a échoué.';

  @override
  String get polarCoachVisibilityTitle => 'Visibilité coach';

  @override
  String get polarCoachVisibilitySubtitle =>
      'Autoriser ton coach à voir cette donnée';

  @override
  String get polarCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Polar.';

  @override
  String get polarMetricTraining => 'Entraînements';

  @override
  String get polarMetricSleep => 'Sommeil';

  @override
  String get polarMetricRecoveryHr => 'Récupération / fréquence cardiaque';

  @override
  String get polarMetricProfile => 'Profil';

  @override
  String get polarMetricBody => 'Mensurations';

  @override
  String polarCoachConnectSubtitle(String playerName) {
    return 'Connecter le compte Polar de $playerName';
  }

  @override
  String polarCoachConnectConnectedSubtitle(String playerName) {
    return 'Polar connecté pour $playerName';
  }

  @override
  String get fitbitConnectToggleSubtitle =>
      'Connecte ton compte Fitbit pour importer activité, fréquence cardiaque, sommeil et poids depuis ton bracelet via le cloud Fitbit';

  @override
  String get fitbitConnectToggleConnectedSubtitle =>
      'Fitbit connecté — synchronisation des données à venir (Phase 2)';

  @override
  String get fitbitConnectSuccess => 'Compte Fitbit connecté.';

  @override
  String get fitbitConnectFailed => 'La connexion Fitbit a échoué. Réessayez.';

  @override
  String get fitbitConnectLaunchFailed =>
      'Impossible d\'ouvrir la page de connexion Fitbit.';

  @override
  String get fitbitConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Fitbit.';

  @override
  String get fitbitDisconnectFailed => 'La déconnexion Fitbit a échoué.';

  @override
  String get fitbitCoachVisibilityTitle => 'Visibilité coach';

  @override
  String get fitbitCoachVisibilitySubtitle =>
      'Autoriser ton coach à voir cette donnée';

  @override
  String get fitbitCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Fitbit.';

  @override
  String get fitbitMetricActivity => 'Activité / entraînements / pas';

  @override
  String get fitbitMetricHeartrate => 'Fréquence cardiaque';

  @override
  String get fitbitMetricSleep => 'Sommeil';

  @override
  String get fitbitMetricProfile => 'Profil';

  @override
  String get fitbitMetricBody => 'Poids / mensurations';

  @override
  String fitbitCoachConnectSubtitle(String playerName) {
    return 'Connecter le compte Fitbit de $playerName';
  }

  @override
  String fitbitCoachConnectConnectedSubtitle(String playerName) {
    return 'Fitbit connecté pour $playerName';
  }

  @override
  String get appleHealthConnectToggleSubtitle =>
      'Connecte Apple Forme pour importer entraînements, fréquence cardiaque et énergie active depuis l\'app Santé (iOS uniquement)';

  @override
  String get appleHealthConnectToggleConnectedSubtitle =>
      'Apple Forme connecté — synchronisation complète des entraînements à venir (Phase 2)';

  @override
  String get appleHealthConnectSuccess => 'Apple Forme connecté.';

  @override
  String get appleHealthConnectFailed =>
      'La connexion Apple Forme a échoué. Réessayez.';

  @override
  String get appleHealthConnectDenied =>
      'L\'accès Santé a été refusé. Active-le dans Réglages → Santé → Accès aux données et appareils → Grinta.';

  @override
  String get appleHealthConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Apple Forme.';

  @override
  String get appleHealthIosOnlyMessage =>
      'Apple Forme est disponible uniquement sur iPhone. Les données sont lues sur l\'appareil via Apple HealthKit.';

  @override
  String get appleHealthDisconnectFailed =>
      'La déconnexion Apple Forme a échoué.';

  @override
  String get appleHealthCoachVisibilityTitle => 'Visibilité coach';

  @override
  String get appleHealthCoachVisibilitySubtitle =>
      'Autoriser ton coach à voir cette donnée';

  @override
  String get appleHealthCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Apple Forme.';

  @override
  String get appleHealthMetricActivity => 'Entraînements / activité';

  @override
  String get appleHealthMetricHeartrate => 'Fréquence cardiaque';

  @override
  String get appleHealthMetricActiveEnergy => 'Énergie active';

  @override
  String get appleHealthMetricSleep => 'Sommeil';

  @override
  String appleHealthCoachConnectSubtitle(String playerName) {
    return 'Connecter Apple Forme pour $playerName';
  }

  @override
  String appleHealthCoachConnectConnectedSubtitle(String playerName) {
    return 'Apple Forme connecté pour $playerName';
  }

  @override
  String get googleHealthConnectToggleSubtitle =>
      'Connecte Google Fit pour importer entraînements, fréquence cardiaque et énergie active depuis Health Connect (Android uniquement)';

  @override
  String get googleHealthConnectToggleConnectedSubtitle =>
      'Google Fit / Health Connect connecté — synchronisation complète des entraînements à venir (Phase 2)';

  @override
  String get googleHealthConnectSuccess =>
      'Google Fit / Health Connect connecté.';

  @override
  String get googleHealthConnectFailed =>
      'La connexion Google Fit / Health Connect a échoué. Réessayez.';

  @override
  String get googleHealthConnectDenied =>
      'L\'accès Health Connect a été refusé. Active-le dans Health Connect → Autorisations des applis → Grinta.';

  @override
  String get googleHealthConnectAuthRequired =>
      'Connecte-toi à Grinta pour lier Google Fit / Health Connect.';

  @override
  String get googleHealthAndroidOnlyMessage =>
      'Google Fit / Health Connect est disponible uniquement sur Android. Les données sont lues sur l\'appareil via Health Connect.';

  @override
  String get googleHealthDisconnectFailed =>
      'La déconnexion Google Fit / Health Connect a échoué.';

  @override
  String get googleHealthCoachVisibilityTitle => 'Visibilité coach';

  @override
  String get googleHealthCoachVisibilitySubtitle =>
      'Autoriser ton coach à voir cette donnée';

  @override
  String get googleHealthCoachVisibilitySaveFailed =>
      'Impossible d\'enregistrer les préférences Google Fit / Health Connect.';

  @override
  String get googleHealthMetricActivity => 'Entraînements / activité';

  @override
  String get googleHealthMetricHeartrate => 'Fréquence cardiaque';

  @override
  String get googleHealthMetricActiveEnergy => 'Énergie active';

  @override
  String get googleHealthMetricSleep => 'Sommeil';

  @override
  String googleHealthCoachConnectSubtitle(String playerName) {
    return 'Connecter Google Fit / Health Connect pour $playerName';
  }

  @override
  String googleHealthCoachConnectConnectedSubtitle(String playerName) {
    return 'Google Fit / Health Connect connecté pour $playerName';
  }

  @override
  String get createTrainingTitle => 'Nueva sesión de entrenamiento';

  @override
  String get createTrainingTeam => 'Equipo';

  @override
  String get createTrainingTeamRequired => 'Selecciona un equipo';

  @override
  String get createTrainingDate => 'Fecha';

  @override
  String get createTrainingTime => 'Hora';

  @override
  String get createTrainingDuration => 'Duración';

  @override
  String createTrainingDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createTrainingRecurrent => 'Recurrente';

  @override
  String get createTrainingRecurrentDays => 'Día(s) de la semana';

  @override
  String get createTrainingRecurrentDaysRequired =>
      'Selecciona al menos un día';

  @override
  String get createTrainingRecurrentFrom => 'Desde';

  @override
  String get createTrainingRecurrentTo => 'Hasta';

  @override
  String get createTrainingRecurrentInvalidRange =>
      'La fecha de fin no puede ser anterior a la de inicio';

  @override
  String get createTrainingWithTracker => 'Con tracker GPS';

  @override
  String get createTrainingSelectOwner => 'Kit tracker (propietario)';

  @override
  String get createTrainingOwnerRequired =>
      'Selecciona un propietario del tracker';

  @override
  String get createTrainingNoOwners =>
      'No hay kit tracker asignado a este equipo.';

  @override
  String get createTrainingNoManagedTeams =>
      'No gestionas ningún equipo en esta temporada.';

  @override
  String createTrainingSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrenamientos creados',
      one: '1 entrenamiento creado',
    );
    return '$_temp0';
  }

  @override
  String get createTrainingError =>
      'No se pudo crear el entrenamiento. Inténtalo de nuevo.';

  @override
  String get createTrainingSubmit => 'Crear entrenamiento';

  @override
  String get createTrainingRecurrentConfirmTitle => 'Entrenamiento recurrente';

  @override
  String get createTrainingRecurrentConfirmMessage =>
      '¿Desea crear las repeticiones?';

  @override
  String get editTrainingTitle => 'Editar entrenamiento';

  @override
  String get editTrainingSubmit => 'Guardar';

  @override
  String get editTrainingSaved => 'Entrenamiento actualizado';

  @override
  String get editTrainingError =>
      'No se pudo actualizar el entrenamiento. Inténtalo de nuevo.';

  @override
  String get trainingDeleteConfirmTitle => '¿Eliminar entrenamiento?';

  @override
  String get trainingDeleteConfirmMessage =>
      '¿Seguro que quieres eliminar este entrenamiento? Esta acción es permanente.';

  @override
  String get trainingDeleteRecurrentTitle =>
      'Supprimer l\'entraînement récurrent ?';

  @override
  String get trainingDeleteRecurrentMessage =>
      'Souhaitez-vous supprimer toutes les récurrences de cette série ?';

  @override
  String get trainingDeleteThisOccurrence => 'Cette occurrence uniquement';

  @override
  String get trainingDeleteAllOccurrences => 'Toutes les occurrences';

  @override
  String get trainingDeleted => 'Entrenamiento eliminado';

  @override
  String get trainingDeleteError =>
      'No se pudo eliminar el entrenamiento. Inténtalo de nuevo.';

  @override
  String get finishTrainingTitle => 'Finalizar entrenamiento';

  @override
  String get trainingFinishConfirmTitle => '¿Finalizar entrenamiento?';

  @override
  String get trainingFinishConfirmMessage =>
      'Los jugadores no disponibles marcados como presentes pasarán a ausentes. ¿Desea finalizar este entrenamiento?';

  @override
  String get trainingFinished => 'Entrenamiento finalizado';

  @override
  String get trainingFinishError =>
      'No se pudo finalizar el entrenamiento. Inténtalo de nuevo.';

  @override
  String get trainingIntenseFinishTitle => 'Recuperación de datos del sensor';

  @override
  String get trainingIntenseFinishMessage =>
      'Recuperando datos de jugadores presentes con sensor asignado. No cierre esta ventana.';

  @override
  String get trainingIntenseResyncButton => 'Re sync';

  @override
  String get trainingIntenseResyncTitle => 'Resincronizar datos de sensores';

  @override
  String get trainingIntenseResyncMessage =>
      'Volviendo a recuperar los datos del tracker en toda la ventana del entrenamiento (inicio → fin). No cierre esta ventana.';

  @override
  String get trainingIntenseResyncSuccess =>
      'Datos de sensores resincronizados.';

  @override
  String get trainingIntenseFinishSyncing => 'Sincronización en curso…';

  @override
  String get trainingIntenseFinishStagePending => 'En espera';

  @override
  String get trainingIntenseFinishStageFetching => 'Recuperando datos brutos…';

  @override
  String get trainingIntenseFinishStageConverting => 'Convirtiendo datos…';

  @override
  String get trainingIntenseFinishStageAnalyzing => 'Analizando…';

  @override
  String get trainingIntenseFinishStageDone => 'Hecho';

  @override
  String get trainingIntenseFinishStageError => 'Error';

  @override
  String get trainingIntenseFinishNoTrackers =>
      'Ningún jugador presente tiene sensor asignado. Puede finalizar el entrenamiento sin recuperación.';

  @override
  String get trainingIntenseFinishPartialError =>
      'Algunas recuperaciones fallaron. Corrija el problema y reintente.';

  @override
  String get intenseLiveTitle => 'Live';

  @override
  String get intenseLiveOpenTooltip => 'Ver live del sensor';

  @override
  String get intenseLiveSelectPlayer => 'Seleccionar un jugador';

  @override
  String get intenseLiveNoPlayers =>
      'Ningún jugador presente tiene sensor asignado';

  @override
  String get intenseLiveRefresh => 'Actualizar';

  @override
  String intenseLiveLastUpdate(String time) {
    return 'Actualizado a las $time';
  }

  @override
  String get tabLive => 'Live';

  @override
  String get tabLiveShort => 'Live';

  @override
  String get createMatchTitle => 'Nuevo partido';

  @override
  String get createMatchTeam => 'Equipo';

  @override
  String get createMatchTeamRequired => 'Selecciona un equipo';

  @override
  String get createMatchHome => 'Partido en casa';

  @override
  String get createMatchFriendly => 'Partido amistoso';

  @override
  String get createMatchDate => 'Fecha';

  @override
  String get createMatchTime => 'Hora';

  @override
  String get createMatchDuration => 'Duración';

  @override
  String createMatchDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createMatchOpponent => 'Rival';

  @override
  String get createMatchSelectOpponentClub => 'Buscar un club';

  @override
  String get createMatchClubNotFound => 'Club no encontrado';

  @override
  String get createMatchOpponentNameManual => 'Nombre del rival';

  @override
  String get createMatchOpponentRequired => 'Indica el rival';

  @override
  String get createMatchVenue => 'Lugar / dirección del campo';

  @override
  String get createMatchSurface => 'Superficie de juego';

  @override
  String get createMatchSurfaceSynthetic => 'Césped sintético';

  @override
  String get createMatchSurfaceNatural => 'Césped natural';

  @override
  String get createMatchWithTracker => 'Con tracker GPS';

  @override
  String get createMatchSelectOwner => 'Kit tracker (propietario)';

  @override
  String get createMatchOwnerRequired =>
      'Selecciona un propietario del tracker';

  @override
  String get createMatchNoOwners =>
      'No hay kit tracker asignado a este equipo.';

  @override
  String get createMatchNoManagedTeams =>
      'No gestionas ningún equipo en esta temporada.';

  @override
  String get createMatchSaved => 'Partido creado';

  @override
  String get createMatchError =>
      'No se pudo crear el partido. Inténtalo de nuevo.';

  @override
  String get createMatchSubmit => 'Crear partido';

  @override
  String get editMatchTitle => 'Editar partido';

  @override
  String get editMatchSubmit => 'Guardar';

  @override
  String get editMatchSaved => 'Partido actualizado';

  @override
  String get editMatchError =>
      'No se pudo actualizar el partido. Inténtalo de nuevo.';

  @override
  String get matchDeleteConfirmTitle => '¿Eliminar partido?';

  @override
  String get matchDeleteConfirmMessage =>
      '¿Seguro que quieres eliminar este partido? Esta acción es permanente.';

  @override
  String get matchRemoveFromTeamConfirmTitle =>
      '¿Quitar el partido del calendario?';

  @override
  String get matchRemoveFromTeamConfirmMessage =>
      'Esto quitará el partido del calendario de tu equipo. El partido seguirá visible para los demás equipos.';

  @override
  String get matchDeleted => 'Partido eliminado';

  @override
  String get matchRemovedFromTeam =>
      'Partido quitado del calendario de tu equipo';

  @override
  String get matchDeleteError =>
      'No se pudo eliminar el partido. Inténtalo de nuevo.';

  @override
  String get teamDetailManageUnavailabilities => 'Gestionar indisponibilidades';

  @override
  String get manageUnavailabilitiesTitle => 'Indisponibilidades';

  @override
  String get manageUnavailabilitiesEmpty =>
      'No hay indisponibilidades en esta temporada.';

  @override
  String get manageUnavailabilitiesAdd => 'Añadir indisponibilidad';

  @override
  String get manageUnavailabilitiesEditTitle => 'Editar indisponibilidad';

  @override
  String get manageUnavailabilitiesFromDate => 'Desde';

  @override
  String get manageUnavailabilitiesToDate => 'Hasta';

  @override
  String get manageUnavailabilitiesType => 'Tipo';

  @override
  String get manageUnavailabilitiesDetails => 'Detalles';

  @override
  String get manageUnavailabilitiesDetailsHint => 'Detalles opcionales';

  @override
  String get manageUnavailabilitiesVisible => 'Visible para el equipo';

  @override
  String get manageUnavailabilitiesVisibleHint =>
      'Si está desactivado, solo los managers ven esta entrada';

  @override
  String manageUnavailabilitiesDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get manageUnavailabilitiesHidden => 'Oculto';

  @override
  String get manageUnavailabilitiesSaved => 'Indisponibilidad guardada';

  @override
  String get manageUnavailabilitiesDeleted => 'Indisponibilidad eliminada';

  @override
  String get manageUnavailabilitiesError =>
      'No se pudo guardar la indisponibilidad. Inténtalo de nuevo.';

  @override
  String get manageUnavailabilitiesDeleteError =>
      'No se pudo eliminar la indisponibilidad. Inténtalo de nuevo.';

  @override
  String get manageUnavailabilitiesDeleteConfirmTitle =>
      '¿Eliminar indisponibilidad?';

  @override
  String get manageUnavailabilitiesDeleteConfirmMessage =>
      'Esta acción es permanente.';

  @override
  String get manageUnavailabilitiesInvalidRange =>
      'La fecha de fin no puede ser anterior a la de inicio';

  @override
  String get manageUnavailabilitiesTypeRequired => 'Selecciona un tipo';

  @override
  String get unavailabilityTypeHoliday => 'Vacaciones';

  @override
  String get unavailabilityTypeUnwell => 'Enfermo';

  @override
  String get unavailabilityTypeInjured => 'Lesionado';

  @override
  String get unavailabilityTypeOther => 'Otro motivo';

  @override
  String teamStatsScreenTitle(String teamName) {
    return 'Estadísticas — $teamName';
  }

  @override
  String get teamStatsTabAnalysis => 'Análisis';

  @override
  String get teamStatsTabCalendars => 'Calendarios';

  @override
  String get teamStatsCompetitionFilterLabel => 'Competiciones';

  @override
  String get teamStatsOpponentFilterLabel => 'Club';

  @override
  String get teamStatsNoOpponents => 'Ningún club en esta competición';

  @override
  String get teamStatsTabTrainings => 'Entrenamientos';

  @override
  String get teamStatsTabOpponents => 'Adversarios';

  @override
  String get teamStatsSubTabMatches => 'Partidos';

  @override
  String get teamStatsSubTabRanking => 'Clasificación';

  @override
  String get teamStatsSubTabGoals => 'Goles';

  @override
  String get teamStatsSubTabPlayers => 'Jugadores';

  @override
  String get teamStatsSubTabTypicalTeam => 'Equipo tipo';

  @override
  String get teamStatsTypicalTeamStartersSection => 'Titulares probables';

  @override
  String get teamStatsTypicalTeamSubstitutesSection => 'Suplentes probables';

  @override
  String teamStatsTypicalTeamStartsLabel(int starts, int total) {
    return '$starts/$total titularidades';
  }

  @override
  String teamStatsTypicalTeamSubsLabel(int subs, int total) {
    return '$subs/$total como suplente';
  }

  @override
  String get teamStatsTypicalTeamNoData =>
      'No hay datos de alineación para este adversario';

  @override
  String teamStatsTypicalTeamIncompleteStarters(int count) {
    return 'Solo $count jugadores con datos de titularidad';
  }

  @override
  String teamStatsTypicalTeamMatchesBasis(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidos con alineación',
      one: '1 partido con alineación',
    );
    return 'Basado en $_temp0';
  }

  @override
  String get teamStatsRankingAtDate => 'Actual';

  @override
  String get teamStatsRankingEvolution => 'Evolución';

  @override
  String get teamStatsRankingNoData =>
      'No hay clasificación disponible para esta competición';

  @override
  String get teamStatsRankingSelectCompetition =>
      'Seleccione una competición para ver la clasificación';

  @override
  String get teamStatsRankingColumnRank => '#';

  @override
  String get teamStatsRankingColumnTeam => 'Equipo';

  @override
  String get teamStatsRankingColumnPts => 'Pts';

  @override
  String get teamStatsRankingColumnPlayed => 'J';

  @override
  String get teamStatsRankingColumnWon => 'G';

  @override
  String get teamStatsRankingColumnDrawn => 'E';

  @override
  String get teamStatsRankingColumnLost => 'P';

  @override
  String get teamStatsRankingColumnDiff => '+/-';

  @override
  String get teamStatsRankingAddClubs => 'Comparar clubes';

  @override
  String get teamStatsRankingSelectClubsTitle =>
      'Seleccionar clubes para comparar';

  @override
  String get teamStatsRankingOwnTeamLabel => 'Tu equipo';

  @override
  String teamStatsRankingTooltipRank(String rank) {
    return 'Puesto $rank';
  }

  @override
  String get teamStatsAllCompetitions => 'Todas las competiciones';

  @override
  String get teamStatsContentComingSoon => 'Contenido próximamente';

  @override
  String get teamStatsNoCompetitions => 'No hay competiciones disponibles';

  @override
  String get teamStatsPlayerComingSoon => 'Vista jugador próximamente';

  @override
  String get teamStatsPeriodFullSeason => 'Temporada completa';

  @override
  String get teamStatsPeriodFirstHalf => '1.er semestre';

  @override
  String get teamStatsPeriodSecondHalf => '2.º semestre';

  @override
  String get teamStatsNoPlayedMatches =>
      'Ningún partido jugado en este periodo';

  @override
  String teamStatsWdlMatchesDialogTitle(String outcome, String period) {
    return '$outcome — $period';
  }

  @override
  String get teamStatsTrendLabel => 'Tendencia';

  @override
  String get teamStatsTrendUp => 'En ascenso';

  @override
  String get teamStatsTrendDown => 'En descenso';

  @override
  String get teamStatsTrendFlat => 'Estable';

  @override
  String get teamStatsTrendInsufficientData => 'Datos insuficientes';

  @override
  String get teamStatsGoalsScored => 'Goles marcados';

  @override
  String get teamStatsGoalsConceded => 'Goles encajados';

  @override
  String get teamStatsGoalsTrendScored => 'Goles marcados';

  @override
  String get teamStatsGoalsTrendConceded => 'Goles encajados';

  @override
  String teamStatsGoalsAvgPerMatch(double avg) {
    final intl.NumberFormat avgNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
            locale: localeName, decimalDigits: 2);
    final String avgString = avgNumberFormat.format(avg);

    return '$avgString/partido';
  }

  @override
  String teamStatsGoalsMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidos',
      one: '1 partido',
    );
    return '$_temp0';
  }

  @override
  String teamStatsAvgPointsPerMatch(double avg) {
    final intl.NumberFormat avgNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
            locale: localeName, decimalDigits: 2);
    final String avgString = avgNumberFormat.format(avg);

    return '$avgString';
  }

  @override
  String get teamStatsPlayersColumnPlayer => 'Jugador';

  @override
  String get teamStatsPlayersColumnConvocations => 'Conv.';

  @override
  String get teamStatsPlayersColumnStarts => 'Titu.';

  @override
  String get teamStatsPlayersColumnPlayTime => 'T. juego';

  @override
  String get teamStatsPlayersColumnGoals => 'Goles';

  @override
  String get teamStatsPlayersNoData =>
      'Sin datos de jugadores para este periodo';

  @override
  String teamStatsPlayersPlayTimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get teamStatsAllMonths => 'Todos los meses';

  @override
  String teamStatsTrainingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrenamientos',
      one: '1 entrenamiento',
    );
    return '$_temp0';
  }

  @override
  String get teamStatsTrainingsAttendanceRate => 'Tasa de presencia';

  @override
  String teamStatsTrainingsAttendanceRateValue(String value) {
    return '$value %';
  }

  @override
  String get teamStatsTrainingsNoData =>
      'Ningún entrenamiento pasado en este periodo';

  @override
  String get teamStatsTrainingsNoSeasonMonths =>
      'No hay meses disponibles para esta temporada';

  @override
  String get teamStatsTrainingsColumnPresent => 'Pres.';

  @override
  String get teamStatsTrainingsColumnAbsent => 'Aus.';

  @override
  String get teamStatsTrainingsColumnAttendanceRate => 'Tasa';

  @override
  String get teamStatsTrainingsPlayersNoData =>
      'Sin datos de jugadores para este periodo';

  @override
  String get teamStatsTrainingsGlobalSection => 'Equipo';

  @override
  String get teamStatsTrainingsPersonalSection => 'Mis stats';

  @override
  String get teamStatsCalendarNoMatchdays =>
      'No hay partidos para esta competición';

  @override
  String get teamStatsCalendarNoMatchesForMatchday =>
      'No hay partidos para esta jornada';

  @override
  String get teamStatsCalendarDatesLabel => 'Fechas';

  @override
  String get teamStatsCalendarNoMatchDates => 'Sin fechas programadas';

  @override
  String get teamStatsCalendarDateSeparator => ', ';

  @override
  String get askDiegoTitle => 'Ask Gio';

  @override
  String get askDiegoWelcome =>
      '¡Hola! Soy Gio. Puedo ayudarte con tu agenda, tu próximo rival o las estadísticas del equipo.';

  @override
  String get askDiegoInputHint => 'Pregunta a Gio…';

  @override
  String get askDiegoSend => 'Enviar';

  @override
  String get askDiegoListen => 'Escuchar respuesta';

  @override
  String get askDiegoOpenScreen => 'Abrir';

  @override
  String get askDiegoOpenOpponentStats => 'Ver estadísticas del rival';

  @override
  String get askDiegoStartListening => 'Dictar una pregunta';

  @override
  String get askDiegoStopListening => 'Detener escucha';

  @override
  String get askDiegoSpeechUnavailable =>
      'El reconocimiento de voz no está disponible en este dispositivo.';

  @override
  String get askDiegoSpeechPermissionDenied =>
      'Permiso de micrófono o reconocimiento de voz denegado. Actívelo en Ajustes.';

  @override
  String askDiegoSpeechError(String reason) {
    return 'Error de reconocimiento de voz: $reason';
  }

  @override
  String get askDiegoEmptyResponse => 'No tengo respuesta por ahora.';

  @override
  String get askDiegoCloseSpeedDial => 'Cerrar';

  @override
  String askDiegoNavigationUnknown(String route) {
    return 'Navegación desconocida: $route';
  }

  @override
  String get askDiegoNavigationAgendaHint =>
      'Abre la pestaña Agenda para ver tu calendario.';

  @override
  String get askDiegoNavigationMatchMissing =>
      'Falta el identificador del partido.';

  @override
  String get askDiegoNavigationMatchNotFound => 'Partido no encontrado.';

  @override
  String get askDiegoNavigationNoTeam => 'Ningún equipo seleccionado.';

  @override
  String get askDiegoNavigationOpponentsManagerOnly =>
      'Las estadísticas de rivales son solo para entrenadores.';

  @override
  String get askDiegoNavigationOpponentsPremiumOnly =>
      'Las estadísticas de rivales requieren suscripción.';

  @override
  String get settingsNotificationsSection => 'Notificaciones';

  @override
  String get settingsRemindersSubtitle =>
      'Recordatorios locales para entrenamientos y partidos.';

  @override
  String get settingsRemindersEnabled => 'Activar recordatorios';

  @override
  String get settingsQuietDaysLabel => 'Días silenciosos';

  @override
  String get settingsQuietHoursLabel => 'Horas silenciosas';

  @override
  String get settingsQuietHoursStart => 'Inicio';

  @override
  String get settingsQuietHoursEnd => 'Fin';

  @override
  String get settingsMorningReminderHour => 'Hora del recordatorio matinal';

  @override
  String get reminderWeekdayMon => 'Lun';

  @override
  String get reminderWeekdayTue => 'Mar';

  @override
  String get reminderWeekdayWed => 'Mié';

  @override
  String get reminderWeekdayThu => 'Jue';

  @override
  String get reminderWeekdayFri => 'Vie';

  @override
  String get reminderWeekdaySat => 'Sáb';

  @override
  String get reminderWeekdaySun => 'Dom';

  @override
  String get reminderTrainingTitle => 'Entrenamiento hoy';

  @override
  String reminderTrainingBody(String time) {
    return 'Entrenamiento hoy a las $time — avisa a tu entrenador si estás ausente';
  }

  @override
  String get reminderMatchOpponentStatsTitle => 'Partido hoy';

  @override
  String reminderMatchOpponentStatsBody(String time, String opponent) {
    return 'Hoy a las $time juegas contra $opponent — descubre sus estadísticas';
  }

  @override
  String get trainingPresenceConfirmPresent => 'Estaré presente';

  @override
  String get trainingPresenceConfirmAbsent => 'Estaré ausente';

  @override
  String get trainingPresenceConfirmedPresent => 'Presencia confirmada';

  @override
  String get trainingPresenceConfirmedAbsent => 'Ausencia registrada';

  @override
  String get matchDetailOpponentStats => 'Stats del rival';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminSubtitle =>
      'Herramientas de administración de la plataforma.';

  @override
  String get adminPromoCodesSection => 'Códigos promo';

  @override
  String get adminPromoCodesSectionDesc =>
      'Crear y gestionar códigos promo de suscripción.';

  @override
  String get adminPromoCodesTitle => 'Códigos promo';

  @override
  String get adminPromoCodeCreate => 'Crear código';

  @override
  String get adminPromoCodesLoadError =>
      'No se pudieron cargar los códigos promo.';

  @override
  String get adminPromoCodesEmpty => 'Aún no hay códigos promo.';

  @override
  String get adminPromoCodeUpdateFailed =>
      'No se pudo actualizar el código promo.';

  @override
  String get adminPromoCodeCreated => 'Código promo creado.';

  @override
  String adminPromoCodeEntitlementLabel(String entitlement) {
    return 'Derecho: $entitlement';
  }

  @override
  String adminPromoCodeUsageLabel(int used, int max) {
    return 'Usos: $used / $max';
  }

  @override
  String adminPromoCodeDurationLabel(int days) {
    return 'Duración: $days días';
  }

  @override
  String adminPromoCodeTeamLabel(String teamId) {
    return 'Club: $teamId';
  }

  @override
  String adminPromoCodeExpiresLabel(String date) {
    return 'Caduca: $date';
  }

  @override
  String get adminPromoCodeStatusInactive => 'Inactivo';

  @override
  String get adminPromoCodeStatusExpired => 'Caducado';

  @override
  String get adminPromoCodeStatusExhausted => 'Agotado';

  @override
  String get adminPromoCodeStatusActive => 'Activo';

  @override
  String get adminPromoCodeFieldCode => 'Código';

  @override
  String get adminPromoCodeFieldCodeInvalid =>
      'El código debe tener al menos 4 caracteres.';

  @override
  String get adminPromoCodeFieldEntitlement => 'Derecho';

  @override
  String get adminPromoCodeFieldMaxUses => 'Usos máximos';

  @override
  String get adminPromoCodeFieldMaxUsesInvalid =>
      'Introduce un número mayor que 0.';

  @override
  String get adminPromoCodeFieldDurationDays =>
      'Duración de suscripción (días)';

  @override
  String get adminPromoCodeFieldDurationDaysInvalid =>
      'Introduce un número mayor que 0.';

  @override
  String get adminPromoCodeFieldTeamId => 'ID del club (opcional)';

  @override
  String get adminPromoCodeFieldTeamIdHint =>
      'Restringir el canje a miembros de este club.';

  @override
  String get adminPromoCodeFieldExpiresOptional =>
      'Definir fecha de caducidad (opcional)';

  @override
  String get adminPromoCodeAlreadyExists => 'Este código promo ya existe.';

  @override
  String get adminPromoCodeCreateFailed => 'No se pudo crear el código promo.';

  @override
  String get adminPromoCodePermissionDenied =>
      'Se requiere acceso de administrador para gestionar códigos promo.';

  @override
  String get adminPromoCodeAuthRequired =>
      'Debes iniciar sesión para crear códigos promo.';

  @override
  String get adminPromoCodeActions => 'Acciones';

  @override
  String get adminPromoCodeEdit => 'Editar';

  @override
  String get adminPromoCodeEditTitle => 'Editar código promo';

  @override
  String get adminPromoCodeDelete => 'Eliminar';

  @override
  String get adminPromoCodeDeleteConfirmTitle => '¿Eliminar código promo?';

  @override
  String adminPromoCodeDeleteConfirmMessage(String code) {
    return '¿Seguro que quieres eliminar el código $code? Esta acción es definitiva.';
  }

  @override
  String get adminPromoCodeDeleted => 'Código promo eliminado.';

  @override
  String get adminPromoCodeDeleteFailed =>
      'No se pudo eliminar el código promo.';

  @override
  String get adminPromoCodeUpdated => 'Código promo actualizado.';

  @override
  String get adminPromoCodeSave => 'Guardar';

  @override
  String get adminPromoCodeFieldCodeReadOnly =>
      'El código no se puede modificar.';

  @override
  String adminPromoCodeFieldMaxUsesBelowUsed(int used) {
    return 'Los usos máximos deben ser al menos $used (ya canjeados).';
  }

  @override
  String get adminPromoCodeFieldActive => 'Activo';

  @override
  String get adminPromoCodeClearExpiry => 'Quitar fecha de caducidad';

  @override
  String get adminPromoCodeNotFound => 'Código promo no encontrado.';

  @override
  String get adminTrackerOwnersSection => 'Propietarios de trackers';

  @override
  String get adminTrackerOwnersSectionDesc =>
      'Crea y gestiona los propietarios de trackers.';

  @override
  String get adminTrackerOwnersTitle => 'Propietarios de trackers';

  @override
  String get adminTrackerOwnersEmpty => 'Aún no hay propietarios.';

  @override
  String get adminTrackerOwnersLoadError =>
      'No se pudieron cargar los propietarios.';

  @override
  String get adminTrackerOwnerCreate => 'Añadir propietario';

  @override
  String get adminTrackerOwnerCreateTitle => 'Añadir propietario';

  @override
  String get adminTrackerOwnerEditTitle => 'Editar propietario';

  @override
  String get adminTrackerOwnerFieldName => 'Nombre';

  @override
  String get adminTrackerOwnerFieldEmail => 'Correo electrónico';

  @override
  String get adminTrackerOwnerFieldFirstname => 'Nombre';

  @override
  String get adminTrackerOwnerFieldLastname => 'Apellido';

  @override
  String get adminTrackerOwnerFieldActive => 'Activo';

  @override
  String get adminTrackerOwnerFieldTypeTracker => 'Tipo de tracker';

  @override
  String get adminTrackerOwnerTypeInspirit => 'Inspirit';

  @override
  String get adminTrackerOwnerTypeFootbar => 'Footbar';

  @override
  String get adminTrackerOwnerTypeIntense => 'Intense (SIM, flujo en la nube)';

  @override
  String get adminTrackerOwnerFieldRequired => 'Campo obligatorio';

  @override
  String get adminTrackerOwnerFieldEmailInvalid =>
      'Correo electrónico no válido';

  @override
  String get adminTrackerOwnerStatusActive => 'Activo';

  @override
  String get adminTrackerOwnerStatusInactive => 'Inactivo';

  @override
  String get adminTrackerOwnerSave => 'Guardar';

  @override
  String get adminTrackerOwnerDelete => 'Eliminar';

  @override
  String get adminTrackerOwnerDeleteConfirmTitle => '¿Eliminar propietario?';

  @override
  String adminTrackerOwnerDeleteConfirmMessage(String name) {
    return '¿Seguro que quieres eliminar a $name? Esta acción es permanente.';
  }

  @override
  String get adminTrackerOwnerCreated => 'Propietario creado.';

  @override
  String get adminTrackerOwnerUpdated => 'Propietario actualizado.';

  @override
  String get adminTrackerOwnerDeleted => 'Propietario eliminado.';

  @override
  String get adminTrackerOwnerSaveFailed =>
      'No se pudo guardar el propietario.';

  @override
  String get adminTrackerOwnerDeleteFailed =>
      'No se pudo eliminar el propietario.';

  @override
  String get adminTrackerOwnerPermissionDenied =>
      'Se requiere acceso de administrador para gestionar los propietarios.';

  @override
  String get adminTrackerDevicesSection => 'Gestión de trackers';

  @override
  String get adminTrackerDevicesSectionDesc =>
      'Sincronizar, asignar y gestionar dispositivos tracker.';

  @override
  String get adminTrackerDevicesTitle => 'Gestión de trackers';

  @override
  String get adminTrackerDevicesManageAction => 'Gestión de trackers';

  @override
  String get adminTrackerDevicesShowUnassigned =>
      'Mostrar dispositivos sin asignar';

  @override
  String get adminTrackerDevicesSelectOwner => 'Seleccionar un responsable';

  @override
  String get adminTrackerDevicesResetFilter => 'Restablecer';

  @override
  String get adminTrackerDevicesEmpty => 'Ningún dispositivo';

  @override
  String get adminTrackerDevicesEmptySubtitle =>
      'Ningún documento en TRACKER_Device.';

  @override
  String get adminTrackerDevicesLoadError =>
      'No se pudieron cargar los dispositivos.';

  @override
  String adminTrackerDevicesSource(String provider) {
    return 'Fuente: $provider';
  }

  @override
  String adminTrackerDevicesSerial(String serial) {
    return 'Serial: $serial';
  }

  @override
  String adminTrackerDevicesUpdatedAt(String date) {
    return 'Actualizado: $date';
  }

  @override
  String get adminTrackerDevicesStatusActive => 'Activo';

  @override
  String get adminTrackerDevicesStatusInactive => 'Inactivo';

  @override
  String get adminTrackerDevicesAssign => 'Asignar';

  @override
  String get adminTrackerDevicesUnassign => 'Desasignar';

  @override
  String get adminTrackerDevicesAssignTitle => 'Asignar un dispositivo';

  @override
  String get adminTrackerDevicesCustomName => 'Nombre (opcional)';

  @override
  String get adminTrackerDevicesCancel => 'Cancelar';

  @override
  String get adminTrackerDevicesValidate => 'Confirmar';

  @override
  String get adminTrackerDevicesSelectOwnerRequired =>
      'Seleccione un responsable.';

  @override
  String get adminTrackerDevicesAssignSuccess => 'Asignación guardada.';

  @override
  String get adminTrackerDevicesUnassignSuccess => 'Dispositivo desasignado.';

  @override
  String adminTrackerDevicesError(String error) {
    return 'Error: $error';
  }

  @override
  String get adminTrackerDevicesSyncInspirit => 'Sync Inspirit';

  @override
  String get adminTrackerDevicesSyncFootbar => 'Sync Footbar';

  @override
  String get adminTrackerDevicesSyncInProgress => 'Sincronizando...';

  @override
  String get adminTrackerDevicesSyncInspiritInProgress =>
      'Sync Inspirit (insiders) en curso...';

  @override
  String get adminTrackerDevicesSyncFootbarInProgress =>
      'Sync Footbar en curso...';

  @override
  String adminTrackerDevicesSyncInspiritSuccess(int count) {
    return 'Sync Inspirit: $count dispositivo(s) actualizado(s).';
  }

  @override
  String adminTrackerDevicesSyncInspiritError(String error) {
    return 'Error Sync Inspirit: $error';
  }

  @override
  String get adminTrackerDevicesPermissionDenied =>
      'Se requiere acceso de administrador para gestionar los dispositivos.';

  @override
  String get adminStreamGroupsSection => 'Mensajería - Grupos';

  @override
  String get adminStreamGroupsSectionDesc =>
      'Listar y eliminar los grupos de chat de equipo en GetStream.';

  @override
  String get adminStreamGroupsTitle => 'Mensajería - Grupos';

  @override
  String get adminStreamGroupsEmpty => 'Sin grupos de chat';

  @override
  String get adminStreamGroupsEmptySubtitle =>
      'No se encontraron canales de equipo en GetStream.';

  @override
  String get adminStreamGroupsLoadError =>
      'No se pudieron cargar los grupos de chat.';

  @override
  String get adminStreamGroupsRefresh => 'Actualizar';

  @override
  String adminStreamGroupsCid(String cid) {
    return 'CID: $cid';
  }

  @override
  String adminStreamGroupsMemberCount(int count) {
    return '$count miembros';
  }

  @override
  String adminStreamGroupsLastMessageAt(String date) {
    return 'Último mensaje: $date';
  }

  @override
  String get adminStreamGroupsDelete => 'Eliminar';

  @override
  String get adminStreamGroupsCancel => 'Cancelar';

  @override
  String get adminStreamGroupsDeleteConfirmTitle => '¿Eliminar grupo?';

  @override
  String adminStreamGroupsDeleteConfirmMessage(String name, String cid) {
    return '¿Seguro que quieres eliminar el grupo $name ($cid)? Esta acción es permanente.';
  }

  @override
  String get adminStreamGroupsDeleted => 'Grupo eliminado.';

  @override
  String get adminStreamGroupsDeleteFailed => 'No se pudo eliminar el grupo.';

  @override
  String get adminStreamGroupsPermissionDenied =>
      'Se requiere acceso de administrador para gestionar los grupos de chat.';

  @override
  String get adminSeasonsSection => 'Saisons';

  @override
  String get adminSeasonsSectionDesc =>
      'Lister et gérer les saisons de la plateforme.';

  @override
  String get adminSeasonsTitle => 'Saisons';

  @override
  String get adminSeasonsEmpty => 'Aucune saison pour le moment.';

  @override
  String get adminSeasonsLoadError => 'Impossible de charger les saisons.';

  @override
  String get adminSeasonCreate => 'Ajouter une saison';

  @override
  String get adminSeasonEditTitle => 'Modifier la saison';

  @override
  String get adminSeasonCreated => 'Saison créée.';

  @override
  String get adminSeasonUpdated => 'Saison mise à jour.';

  @override
  String get adminSeasonCreateFailed => 'Impossible de créer la saison.';

  @override
  String get adminSeasonUpdateFailed =>
      'Impossible de mettre à jour la saison.';

  @override
  String get adminSeasonUnnamed => 'Saison sans nom';

  @override
  String get adminSeasonCurrentBadge => 'Actuelle';

  @override
  String get adminSeasonNewVersionBadge => 'Nouvelle version';

  @override
  String adminSeasonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String adminSeasonClubLabel(String clubName) {
    return 'Club : $clubName';
  }

  @override
  String adminSeasonAffiliateLabel(String number) {
    return 'N° affilié : $number';
  }

  @override
  String get adminSeasonFieldName => 'Nom';

  @override
  String get adminSeasonFieldNameReadOnly =>
      'Le nom de la saison ne peut pas être modifié après création.';

  @override
  String get adminSeasonFieldRequired => 'Ce champ est obligatoire.';

  @override
  String get adminSeasonFieldStartDate => 'Date de début';

  @override
  String get adminSeasonFieldEndDate => 'Date de fin';

  @override
  String adminSeasonDateSelected(String date) {
    return 'Sélection : $date';
  }

  @override
  String get adminSeasonFieldClubName => 'Nom du club';

  @override
  String get adminSeasonFieldAffiliateNumber => 'Numéro d\'affilié';

  @override
  String get adminSeasonFieldCurrent => 'Saison actuelle';

  @override
  String get adminSeasonFieldCurrentHint =>
      'Une seule saison peut être actuelle à la fois.';

  @override
  String get adminSeasonFieldNewVersion => 'Nouvelle version';

  @override
  String get adminSeasonChangeDefaultTitle => 'Changer la saison actuelle ?';

  @override
  String adminSeasonChangeDefaultMessage(String seasonName) {
    return '« $seasonName » est actuellement la saison par défaut. Voulez-vous la remplacer ?';
  }

  @override
  String get adminSeasonChangeDefaultConfirm => 'Changer la saison par défaut';

  @override
  String get promoCodeMenuLabel => 'Código promo';

  @override
  String get promoCodeDialogValidate => 'Validar';

  @override
  String get promoCodeRedeemTitle => '¿Tienes un código promo?';

  @override
  String get promoCodeRedeemHint => 'Introduce tu código';

  @override
  String get promoCodeRedeemAction => 'Canjear';

  @override
  String get promoCodeRedeemEmpty => 'Introduce un código promo.';

  @override
  String promoCodeRedeemSuccess(int days, String entitlement) {
    return 'Código promo aplicado: $days días de $entitlement.';
  }

  @override
  String promoCodeRedeemSuccessVerified(
      String entitlement, String expiresAt, int days) {
    return '$entitlement activo hasta el $expiresAt ($days días concedidos).';
  }

  @override
  String get promoCodeRedeemSyncPending =>
      'Código registrado en el servidor, pero la suscripción aún no es visible. Abre Ajustes → Suscripción en un momento, o cierra sesión y vuelve a entrar.';

  @override
  String get promoCodeRedeemRcUnavailable =>
      'Código registrado en el servidor, pero RevenueCat no está configurado en este dispositivo (comprueba las claves API). Prueba en iOS o web, o reinicia con dart_defines.json.';

  @override
  String get promoCodeRedeemNotFound => 'Código promo no encontrado.';

  @override
  String get promoCodeRedeemInvalid => 'Este código promo ya no es válido.';

  @override
  String get promoCodeRedeemInactive => 'Este código promo no está activo.';

  @override
  String get promoCodeRedeemExpired => 'Este código promo ha caducado.';

  @override
  String get promoCodeRedeemAlreadyRedeemed =>
      'Ya has canjeado este código promo.';

  @override
  String get promoCodeRedeemExhausted =>
      'Este código promo ha alcanzado su límite de uso.';

  @override
  String get promoCodeRedeemTeamMismatch =>
      'Este código promo está reservado a otro club.';

  @override
  String get promoCodeRedeemUnauthenticated =>
      'Debes iniciar sesión para canjear un código promo.';

  @override
  String get promoCodeRedeemFailed => 'No se pudo canjear el código promo.';

  @override
  String get playerFeelingPrompt => '¿Cómo te sientes?';

  @override
  String get playerFeelingNotifTitle => 'Resumen de sesión';

  @override
  String get playerFeelingNotifBody => 'Mira tus estadísticas y dinos cómo te sientes.';

  @override
  String get playerFeelingRecapTitle => 'Tu resumen';

  @override
  String get playerFeelingRecapSubtitle => 'Tus datos de sesión';

  @override
  String get playerFeelingSubmitAction => 'Enviar';

  @override
  String get playerFeelingUpdateAction => 'Actualizar';

  @override
  String get playerFeelingSaved => 'Gracias, tu sensación se ha guardado.';

  @override
  String get playerFeelingSaveError => 'No se pudo guardar tu sensación.';

  @override
  String get playerFeelingLoadError => 'No se pudo cargar el resumen.';

  @override
  String get forgotPasswordTitle => 'Contraseña olvidada';

  @override
  String get forgotPasswordMessage => 'Introduce el correo de tu cuenta. Te enviaremos un enlace para restablecer tu contraseña.';

  @override
  String get forgotPasswordSendAction => 'Enviar enlace';

  @override
  String get forgotPasswordSent => 'Se ha enviado un correo para restablecer la contraseña.';

  @override
  String get forgotPasswordFailed => 'No se pudo enviar el correo de restablecimiento.';
}
