# Clipfolio

Eine deutschsprachige Flutter-App zum Sammeln von Videolinks. Ein Tag entspricht einem Ordner. Ein Video kann in mehreren Ordnern liegen. Die Mediathek speichert Links, Tags, Titel, Kommentare und bekannte Laufzeiten auf dem Gerät. Ein Tipp auf den Eintrag öffnet den Original-Link.

## Ausprobieren

Mit Flutter 3.44.8 und Dart 3.12.2 entwickelt.

```sh
flutter pub get
flutter run
```

Für die Browservorschau `flutter run -d chrome` starten. Im Browser lassen sich Links manuell einfügen. Das native Teilen-Menü steht in den mobilen Apps zur Verfügung.

## Links sammeln

1. In der Quell-App einen Videolink teilen und Clipfolio wählen. Alternativ in der Mediathek **Video merken** antippen.
2. Vorhandene Tags auswählen oder einen neuen Tag eingeben. Ein Kommentar und ein eigener Titel sind optional.
3. Speichern und den Ordner auf dem Startbildschirm öffnen. Die Suche berücksichtigt Titel, Tags, Plattform, Link und Kommentar. Über das Menü am Eintrag lassen sich die Angaben bearbeiten.

Clipfolio liest Titel und Laufzeit aus verfügbaren HTML-Metadaten der verlinkten Seite. Plattformen mit Anmeldung, dynamischen Inhalten oder Zugriffsbeschränkungen können diese Angaben auslassen. Im Browser gelten zusätzlich die Zugriffsregeln der Quellseite. Die Dauer kann in Sekunden oder als Min:Sek eingegeben werden.

| Laufzeit | Formatfilter |
| --- | --- |
| Bis einschließlich 1:00 | Short-Form |
| Über 1:00 bis einschließlich 5:00 | Medium-Form |
| Über 5:00 | Long-Form |
| Unbekannt | Dauer offen |

## iPhone und TestFlight

Auf einem Mac mit Flutter und Xcode im Projektverzeichnis `flutter pub get` und `flutter build ios --config-only` ausführen. Dann `ios/Runner.xcworkspace` öffnen.

- Für **Runner** und **ShareExtension** unter **Signing & Capabilities** das eigene Apple-Team wählen. Die vordefinierten Bundle-IDs lauten `de.clipfolio.clipfolio` und `de.clipfolio.clipfolio.ShareExtension`.
- Die App Group `group.de.clipfolio.clipfolio` für beide Targets im Entwicklerkonto aktivieren. Bei geänderter Gruppen-ID beide Entitlement-Dateien und `ios/SharedInbox.swift` anpassen.
- Für den Gerätetest aus Safari oder einer Video-App einen Link an Clipfolio teilen, Tag und Kommentar eingeben und speichern. Beim nächsten Öffnen übernimmt die App den Eintrag. Mehrere geteilte Links können bis dahin im gemeinsamen Eingang liegen.
- Für TestFlight in Xcode das Scheme **Runner** archivieren und das signierte Archiv über den Organizer an App Store Connect übertragen.

Die Erweiterung schreibt jeden Eintrag atomar in eine eigene Datei. Die Haupt-App quittiert den Eingang nach dem Speichern. Die ID bleibt beim Import erhalten, sodass eine unterbrochene Übergabe beim Wiederholen denselben Eintrag trifft. [Apple-Dokumentation zu App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)

## Tests

```sh
flutter analyze
flutter test
flutter build apk --debug
```

Der native Android-Test unter `android/app/src/androidTest` teilt eine Text-URL über einen Android-Intent, wählt „Workout“, speichert und sucht den Eintrag im Ordner. Mit einem gestarteten Testemulator im Verzeichnis `android` über `./gradlew :app:connectedDebugAndroidTest` ausführen.
