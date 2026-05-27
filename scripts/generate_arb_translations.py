#!/usr/bin/env python3
"""Generate app_en/de/es/it.arb from app_fr.arb using batch translation."""

import re
import time
from pathlib import Path

from deep_translator import GoogleTranslator

ROOT = Path(__file__).resolve().parents[1]
FR_PATH = ROOT / "lib/l10n/app_fr.arb"

# ICU / plural strings — hand-translated to preserve syntax
ICU_OVERRIDES = {
    "en": {
        "entityTeamWithIndex": "Team {index}",
        "periodMatchDay": "Matchday {day}",
        "periodSelectedWeek": "Selected week: {range}",
        "emptyNoSvgForPeriod": "No SVG image found for {period}.",
        "errorGeneric": "Error: {details}",
        "errorLoadingResource": "Error loading {resource}.",
        "errorFilteringResource": "Error filtering {resource}.",
        "errorComputingStats": "Error computing {resource} statistics.",
        "errorSaving": "Error while saving: {details}",
        "errorLogout": "Error while signing out: {details}",
        "errorTeamParamsLoad": "Error loading settings: {details}",
        "errorDeleteFailed": "Error while deleting: {details}",
        "errorChatCreate": "Error while creating: {details}",
        "successConversionDone": "Conversion complete - {count} row(s) kept",
        "statsPlayersCount": "{count} players",
        "statsAvgWorkload": "Avg. load {value}",
        "statsAvgDistance": "Avg. distance {value}",
        "statsAvgMaxSpeed": "Avg. max speed {value}",
        "statsZScore": "zScore {sign}{value}",
        "teamMembersPlayers": "{count, plural, =1{1 player} other{{count} players}}",
        "teamMembersStaff": "{count, plural, =1{1 staff member} other{{count} staff members}}",
        "fieldSnackbarAddressNotFoundWithStatus": "Address not found: {status}",
        "asiFilePickError": "Error selecting file: {details}",
        "asiConversionError": "Error during conversion: {details}",
        "teamsListCount": "{count} team(s)",
        "teamsListCountFiltered": "{filtered} / {total}",
        "matchDateTimeAt": "{date} at {time}",
        "highlightSubstitutionOut": "{player} off",
        "highlightSubstitutionIn": "{incoming} replaces {outgoing}",
        "trackerCount": "{count} tracker(s)",
        "trackerDeviceName": "Device: {name}",
        "asiPeriodsMany": "{count} period(s) sent - the first 2 will be used for halves",
        "periodCustomRange": "from {start} to {end}",
        "statsPresenceRate": "Attendance rate: ({value}) %",
        "periodLoaded": "Period loaded: {range}",
        "agendaOverviewEventsCount": "{count, plural, =1{1 event} other{{count} events}}",
        "agendaEventSummaryMatches": "{count, plural, =1{1 match} other{{count} matches}}",
        "agendaEventSummaryTrainings": "{count, plural, =1{1 training} other{{count} trainings}}",
        "agendaEventSummaryPrepas": "{count, plural, =1{1 prep session} other{{count} prep sessions}}",
        "teamDetailAverageAge": "Average age: {age} years",
        "teamDetailConfirmRemoveStaff": "Remove staff member {playerName}?",
        "teamDetailConfirmRemovePlayerTeam": "Remove {playerName} from the team?",
        "teamDetailPlayerRemoved": "{playerName} has been removed.",
        "teamDetailPlayerTeamRemoved": "{playerName} has been removed from the team.",
        "teamParamsZoneMaxGreaterThanMin": "Zone \"{label}\" must have a max bound higher than the min bound.",
        "teamParamsZonesOverlap": "Zones \"{zoneA}\" and \"{zoneB}\" overlap.",
        "teamParamsZoneTitle": "Zone {index}",
        "trackerParamTeam": "Team param {teamId}",
        "halfNth": "{index}th half",
        "asiHeatmapPointCount": "{count} point(s) - {period}",
        "metricsEvolutionTitle": "Trend - {metric}",
        "trainingOnDate": "Training on {date}",
    },
    "de": {
        "entityTeamWithIndex": "Team {index}",
        "periodMatchDay": "Spieltag {day}",
        "periodSelectedWeek": "Ausgewählte Woche: {range}",
        "emptyNoSvgForPeriod": "Kein SVG-Bild für {period} gefunden.",
        "errorGeneric": "Fehler: {details}",
        "errorLoadingResource": "Fehler beim Laden von {resource}.",
        "errorFilteringResource": "Fehler beim Filtern von {resource}.",
        "errorComputingStats": "Fehler bei der Statistikberechnung für {resource}.",
        "errorSaving": "Fehler beim Speichern: {details}",
        "errorLogout": "Fehler beim Abmelden: {details}",
        "errorTeamParamsLoad": "Fehler beim Laden der Einstellungen: {details}",
        "errorDeleteFailed": "Fehler beim Löschen: {details}",
        "errorChatCreate": "Fehler beim Erstellen: {details}",
        "successConversionDone": "Konvertierung abgeschlossen - {count} Zeile(n) übernommen",
        "statsPlayersCount": "{count} Spieler",
        "statsAvgWorkload": "Ø Belastung {value}",
        "statsAvgDistance": "Ø Distanz {value}",
        "statsAvgMaxSpeed": "Ø Max.-Geschw. {value}",
        "statsZScore": "zScore {sign}{value}",
        "teamMembersPlayers": "{count, plural, =1{1 Spieler} other{{count} Spieler}}",
        "teamMembersStaff": "{count, plural, =1{1 Staff-Mitglied} other{{count} Staff-Mitglieder}}",
        "fieldSnackbarAddressNotFoundWithStatus": "Adresse nicht gefunden: {status}",
        "asiFilePickError": "Fehler bei der Dateiauswahl: {details}",
        "asiConversionError": "Fehler bei der Konvertierung: {details}",
        "teamsListCount": "{count} Team(s)",
        "teamsListCountFiltered": "{filtered} / {total}",
        "matchDateTimeAt": "{date} um {time}",
        "highlightSubstitutionOut": "{player} raus",
        "highlightSubstitutionIn": "{incoming} ersetzt {outgoing}",
        "trackerCount": "{count} Tracker",
        "trackerDeviceName": "Gerät: {name}",
        "asiPeriodsMany": "{count} Periode(n) übermittelt - die ersten 2 werden für die Halbzeiten verwendet",
        "periodCustomRange": "vom {start} bis {end}",
        "statsPresenceRate": "Anwesenheitsquote: ({value}) %",
        "periodLoaded": "Zeitraum geladen: {range}",
        "agendaOverviewEventsCount": "{count, plural, =1{1 Ereignis} other{{count} Ereignisse}}",
        "agendaEventSummaryMatches": "{count, plural, =1{1 Spiel} other{{count} Spiele}}",
        "agendaEventSummaryTrainings": "{count, plural, =1{1 Training} other{{count} Trainings}}",
        "agendaEventSummaryPrepas": "{count, plural, =1{1 Vorbereitung} other{{count} Vorbereitungen}}",
        "teamDetailAverageAge": "Durchschnittsalter: {age} Jahre",
        "teamDetailConfirmRemoveStaff": "Staff {playerName} wirklich entfernen?",
        "teamDetailConfirmRemovePlayerTeam": "Spieler {playerName} aus dem Team entfernen?",
        "teamDetailPlayerRemoved": "{playerName} wurde entfernt.",
        "teamDetailPlayerTeamRemoved": "{playerName} wurde aus dem Team entfernt.",
        "teamParamsZoneMaxGreaterThanMin": "Zone \"{label}\" muss eine obere Grenze über der unteren Grenze haben.",
        "teamParamsZonesOverlap": "Die Zonen \"{zoneA}\" und \"{zoneB}\" überschneiden sich.",
        "teamParamsZoneTitle": "Zone {index}",
        "trackerParamTeam": "Team-Param {teamId}",
        "halfNth": "{index}. Halbzeit",
        "asiHeatmapPointCount": "{count} Punkt(e) - {period}",
        "metricsEvolutionTitle": "Verlauf - {metric}",
        "trainingOnDate": "Training am {date}",
    },
    "es": {
        "entityTeamWithIndex": "Equipo {index}",
        "periodMatchDay": "Jornada {day}",
        "periodSelectedWeek": "Semana seleccionada: {range}",
        "emptyNoSvgForPeriod": "No se encontró imagen SVG para {period}.",
        "errorGeneric": "Error: {details}",
        "errorLoadingResource": "Error al cargar {resource}.",
        "errorFilteringResource": "Error al filtrar {resource}.",
        "errorComputingStats": "Error al calcular las estadísticas de {resource}.",
        "errorSaving": "Error al guardar: {details}",
        "errorLogout": "Error al cerrar sesión: {details}",
        "errorTeamParamsLoad": "Error al cargar los parámetros: {details}",
        "errorDeleteFailed": "Error al eliminar: {details}",
        "errorChatCreate": "Error al crear: {details}",
        "successConversionDone": "Conversión terminada - {count} fila(s) conservada(s)",
        "statsPlayersCount": "{count} jugadores",
        "statsAvgWorkload": "Carga media {value}",
        "statsAvgDistance": "Distancia media {value}",
        "statsAvgMaxSpeed": "Vel. máx. media {value}",
        "statsZScore": "zScore {sign}{value}",
        "teamMembersPlayers": "{count, plural, =1{1 jugador} other{{count} jugadores}}",
        "teamMembersStaff": "{count, plural, =1{1 miembro del staff} other{{count} miembros del staff}}",
        "fieldSnackbarAddressNotFoundWithStatus": "Dirección no encontrada: {status}",
        "asiFilePickError": "Error al seleccionar el archivo: {details}",
        "asiConversionError": "Error durante la conversión: {details}",
        "teamsListCount": "{count} equipo(s)",
        "teamsListCountFiltered": "{filtered} / {total}",
        "matchDateTimeAt": "{date} a las {time}",
        "highlightSubstitutionOut": "Sale {player}",
        "highlightSubstitutionIn": "{incoming} sustituye a {outgoing}",
        "trackerCount": "{count} tracker(s)",
        "trackerDeviceName": "Dispositivo: {name}",
        "asiPeriodsMany": "{count} período(s) enviado(s) - los 2 primeros se usarán para los tiempos",
        "periodCustomRange": "del {start} al {end}",
        "statsPresenceRate": "Tasa de presencia: ({value}) %",
        "periodLoaded": "Período cargado: {range}",
        "agendaOverviewEventsCount": "{count, plural, =1{1 evento} other{{count} eventos}}",
        "agendaEventSummaryMatches": "{count, plural, =1{1 partido} other{{count} partidos}}",
        "agendaEventSummaryTrainings": "{count, plural, =1{1 entrenamiento} other{{count} entrenamientos}}",
        "agendaEventSummaryPrepas": "{count, plural, =1{1 prep. física} other{{count} prep. físicas}}",
        "teamDetailAverageAge": "Edad media: {age} años",
        "teamDetailConfirmRemoveStaff": "¿Eliminar al staff {playerName}?",
        "teamDetailConfirmRemovePlayerTeam": "¿Eliminar a {playerName} del equipo?",
        "teamDetailPlayerRemoved": "{playerName} ha sido eliminado.",
        "teamDetailPlayerTeamRemoved": "{playerName} ha sido eliminado del equipo.",
        "teamParamsZoneMaxGreaterThanMin": "La zona \"{label}\" debe tener un máximo superior al mínimo.",
        "teamParamsZonesOverlap": "Las zonas \"{zoneA}\" y \"{zoneB}\" se solapan.",
        "teamParamsZoneTitle": "Zona {index}",
        "trackerParamTeam": "Parámetro equipo {teamId}",
        "halfNth": "{index}.º tiempo",
        "asiHeatmapPointCount": "{count} punto(s) - {period}",
        "metricsEvolutionTitle": "Evolución - {metric}",
        "trainingOnDate": "Entrenamiento del {date}",
    },
    "it": {
        "entityTeamWithIndex": "Squadra {index}",
        "periodMatchDay": "Giornata {day}",
        "periodSelectedWeek": "Settimana selezionata: {range}",
        "emptyNoSvgForPeriod": "Nessuna immagine SVG trovata per {period}.",
        "errorGeneric": "Errore: {details}",
        "errorLoadingResource": "Errore durante il caricamento di {resource}.",
        "errorFilteringResource": "Errore durante il filtraggio di {resource}.",
        "errorComputingStats": "Errore nel calcolo delle statistiche di {resource}.",
        "errorSaving": "Errore durante il salvataggio: {details}",
        "errorLogout": "Errore durante la disconnessione: {details}",
        "errorTeamParamsLoad": "Errore nel caricamento dei parametri: {details}",
        "errorDeleteFailed": "Errore durante l'eliminazione: {details}",
        "errorChatCreate": "Errore durante la creazione: {details}",
        "successConversionDone": "Conversione completata - {count} riga/e conservata/e",
        "statsPlayersCount": "{count} giocatori",
        "statsAvgWorkload": "Carico medio {value}",
        "statsAvgDistance": "Distanza media {value}",
        "statsAvgMaxSpeed": "Vel. max media {value}",
        "statsZScore": "zScore {sign}{value}",
        "teamMembersPlayers": "{count, plural, =1{1 giocatore} other{{count} giocatori}}",
        "teamMembersStaff": "{count, plural, =1{1 membro staff} other{{count} membri staff}}",
        "fieldSnackbarAddressNotFoundWithStatus": "Indirizzo non trovato: {status}",
        "asiFilePickError": "Errore nella selezione del file: {details}",
        "asiConversionError": "Errore durante la conversione: {details}",
        "teamsListCount": "{count} squadra/e",
        "teamsListCountFiltered": "{filtered} / {total}",
        "matchDateTimeAt": "{date} alle {time}",
        "highlightSubstitutionOut": "Esce {player}",
        "highlightSubstitutionIn": "{incoming} sostituisce {outgoing}",
        "trackerCount": "{count} tracker",
        "trackerDeviceName": "Dispositivo: {name}",
        "asiPeriodsMany": "{count} periodo/i inviato/i - i primi 2 saranno usati per i tempi",
        "periodCustomRange": "dal {start} al {end}",
        "statsPresenceRate": "Tasso di presenza: ({value}) %",
        "periodLoaded": "Periodo caricato: {range}",
        "agendaOverviewEventsCount": "{count, plural, =1{1 evento} other{{count} eventi}}",
        "agendaEventSummaryMatches": "{count, plural, =1{1 partita} other{{count} partite}}",
        "agendaEventSummaryTrainings": "{count, plural, =1{1 allenamento} other{{count} allenamenti}}",
        "agendaEventSummaryPrepas": "{count, plural, =1{1 prep. fisica} other{{count} prep. fisiche}}",
        "teamDetailAverageAge": "Età media: {age} anni",
        "teamDetailConfirmRemoveStaff": "Rimuovere lo staff {playerName}?",
        "teamDetailConfirmRemovePlayerTeam": "Rimuovere {playerName} dalla squadra?",
        "teamDetailPlayerRemoved": "{playerName} è stato rimosso.",
        "teamDetailPlayerTeamRemoved": "{playerName} è stato rimosso dalla squadra.",
        "teamParamsZoneMaxGreaterThanMin": "La zona \"{label}\" deve avere un massimo superiore al minimo.",
        "teamParamsZonesOverlap": "Le zone \"{zoneA}\" e \"{zoneB}\" si sovrappongono.",
        "teamParamsZoneTitle": "Zona {index}",
        "trackerParamTeam": "Param squadra {teamId}",
        "halfNth": "{index}° tempo",
        "asiHeatmapPointCount": "{count} punto/i - {period}",
        "metricsEvolutionTitle": "Andamento - {metric}",
        "trainingOnDate": "Allenamento del {date}",
    },
}


def parse_fr_arb() -> list[tuple[str, str]]:
    content = FR_PATH.read_text(encoding="utf-8")
    order: list[tuple[str, str]] = []
    i = 0
    lines = content.split("\n")
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith('"@') and not line.startswith('"@@'):
            if "{" in line:
                depth = line.count("{") - line.count("}")
                i += 1
                while i < len(lines) and depth > 0:
                    depth += lines[i].count("{") - lines[i].count("}")
                    i += 1
                continue
        m = re.match(r'"([^"]+)":\s*"(.*)"\s*,?\s*$', line)
        if m:
            key, val = m.group(1), m.group(2)
            if not key.startswith("@"):
                val = bytes(val, "utf-8").decode("unicode_escape")
                order.append((key, val))
        i += 1
    return order


def protect_placeholders(text: str) -> tuple[str, dict[str, str]]:
    mapping = {}

    def repl(m):
        token = f"__PH_{len(mapping)}__"
        mapping[token] = m.group(0)
        return token

    protected = re.sub(r"\{[^{}]+\}", repl, text)
    return protected, mapping


def restore_placeholders(text: str, mapping: dict[str, str]) -> str:
    for token, original in mapping.items():
        text = text.replace(token, original)
    return text


def escape_arb(s: str) -> str:
    # ARB is JSON: only escape backslash, double quotes, and newlines.
    return (
        s.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
    )


def write_arb(locale: str, order: list[tuple[str, str]], trans: dict[str, str]) -> None:
    out = ROOT / f"lib/l10n/app_{locale}.arb"
    lines = [f'{{\n  "@@locale": "{locale}",\n']
    keys = [k for k, _ in order]
    for idx, key in enumerate(keys):
        val = escape_arb(trans[key])
        comma = "," if idx < len(keys) - 1 else ""
        lines.append(f'  "{key}": "{val}"{comma}\n')
    lines.append("}\n")
    out.write_text("".join(lines), encoding="utf-8")
    print(f"Wrote {out} ({len(keys)} keys)")


def main() -> None:
    order = parse_fr_arb()
    icu_keys = set(ICU_OVERRIDES["en"].keys())

    for locale, target in [("en", "en"), ("de", "de"), ("es", "es"), ("it", "it")]:
        translator = GoogleTranslator(source="fr", target=target)
        overrides = ICU_OVERRIDES[locale]
        trans: dict[str, str] = {}

        batch_keys: list[str] = []
        batch_texts: list[str] = []
        batch_maps: list[dict[str, str]] = []

        def flush_batch() -> None:
            nonlocal batch_keys, batch_texts, batch_maps
            if not batch_keys:
                return
            try:
                translated = translator.translate_batch(batch_texts)
            except Exception:
                translated = [
                    translator.translate(t) for t in batch_texts
                ]
            for key, raw, ph_map in zip(batch_keys, translated, batch_maps):
                trans[key] = restore_placeholders(raw, ph_map)
            batch_keys, batch_texts, batch_maps = [], [], []

        for key, text in order:
            if key == "appName":
                trans[key] = "Grinta"
                continue
            if key in icu_keys:
                trans[key] = overrides[key]
                continue
            protected, ph_map = protect_placeholders(text)
            batch_keys.append(key)
            batch_texts.append(protected)
            batch_maps.append(ph_map)
            if len(batch_keys) >= 40:
                flush_batch()
                time.sleep(0.2)

        flush_batch()
        write_arb(locale, order, trans)
        time.sleep(0.5)

    print("All locales generated.")


if __name__ == "__main__":
    main()
