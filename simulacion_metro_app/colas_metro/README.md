# Colas Metro: calculadora M/M/1 y M/M/s con informe PDF

## Cómo generar el APK
Requisitos: Flutter 3.22 o superior (`flutter doctor` sin errores) y Android SDK.

```bash
flutter create --org co.edu.colas --project-name colas_metro colas_metro
cd colas_metro
# copia sobre esta carpeta: pubspec.yaml, lib/ y test/ (reemplazando los generados)
flutter pub get
flutter test                      # verifica el motor de cálculo
flutter run                       # prueba en el celular o emulador
flutter build apk --release       # genera el APK
```
El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Pásalo al celular e instálalo
(permite "instalar apps de orígenes desconocidos").

## Archivos
- `lib/queue_model.dart`: motor de cálculo (M/M/1, M/M/s, escenarios, estadísticas). Sin dependencias de UI.
- `lib/input_screen.dart`: ingreso de datos, selección de modelo.
- `lib/results_screen.dart`: parámetros, ecuaciones, simulador de hora pico y escenarios.
- `lib/pdf_report.dart`: informe PDF.
- `test/queue_model_test.dart`: pruebas unitarias contra los valores del Excel.

## Uso
Botón del matraz = carga el ejemplo de Estadio (35 tiempos de servicio, llegadas cada 40 s, 2 taquillas).

## Diseño
Paleta morado / rosado / amarillo en contraste (claro y oscuro) definida en `lib/theme.dart`.
Sin logos: las líneas de metro decorativas (encabezado, títulos de sección y la barra de
utilización con un "tren") están dibujadas con `CustomPaint` en `lib/metro_decor.dart`.
