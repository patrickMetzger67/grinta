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
  String get memberProfileIncomplete => 'Completa tu perfil';

  @override
  String get memberProfileSubmit => 'Crear mi ficha de jugador';

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
  String get actionLogout => 'Desconectar';

  @override
  String get actionLogoutConfirmTitle => 'Desconectar';

  @override
  String get actionLogoutConfirmMessage => '¿Realmente quieres cerrar sesión?';

  @override
  String get actionAddPlayer => 'Añadir un jugador';

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
  String get tabCompo => 'Composición';

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
  String get dialogCloseSyncTitle => 'Cerrar sincronización';

  @override
  String get dialogCloseSyncMessage => '¿Quieres cerrar la sincronización?';

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
  String get highlightTypeGoal => 'Apuntar';

  @override
  String get highlightTypeSubstitution => 'Cambiar';

  @override
  String get highlightTypeYellowCard => 'tarjeta amarilla';

  @override
  String get highlightTypeRedCard => 'Tarjeta roja';

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
  String get roleCoach => 'Entrenador';

  @override
  String get roleExecutive => 'Directivo';

  @override
  String get positionEducator => 'Educador/Entrenador';

  @override
  String get positionExecutive => 'Directivo';

  @override
  String get positionGoalkeeper => 'Portero';

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
}
