# Plantregistratie

Offline Android-app voor een plantenkwekerij. Open deze map in Android Studio (JDK 17), laat Gradle synchroniseren en start de `app`-configuratie. De eerste start importeert `app/src/main/assets/plants.csv` en `departments.txt` zonder duplicaten.

De database gebruikt Room met buitenlandse sleutels, indexen en een niet-destructieve migratie van versie 1 naar 2. Masterdata die in een registratie wordt gebruikt, kan niet worden verwijderd.

## Android en iOS

De cross-platformversie staat in `flutter_app/` en gebruikt Flutter met een lokale SQLite-database. De GitHub Actions-workflow **Bouw Android en iOS** maakt een Android-APK en een unsigned iOS-app. Voor installatie op een echte iPhone moet de iOS-app met een Apple Developer-certificaat en provisioning profile worden ondertekend.

## Webapp installeren

De workflow **Publiceer webapp** publiceert dezelfde Flutter-app als een installeerbare webapp via GitHub Pages. De browser bewaart de database lokaal op het apparaat. Open de webapp in Safari of Chrome en kies **Zet op beginscherm** of **Toevoegen aan startscherm** om hem als app te gebruiken.
