# Plantregistratie

Offline Android-app voor een plantenkwekerij. Open deze map in Android Studio (JDK 17), laat Gradle synchroniseren en start de `app`-configuratie. De eerste start importeert `app/src/main/assets/plants.csv` en `departments.txt` zonder duplicaten.

De database gebruikt Room met buitenlandse sleutels, indexen en een niet-destructieve migratie van versie 1 naar 2. Masterdata die in een registratie wordt gebruikt, kan niet worden verwijderd.
