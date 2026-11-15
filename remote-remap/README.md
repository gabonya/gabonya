# Переназначение кнопок кинотеатров на пульте Xiaomi

Пульт Xiaomi Mi TV 4A (MiTV-MOOQ1). Кнопки кинотеатров открывают приложение
с определённым именем пакета, а если его нет, открывают Google Play.
Каждый APK здесь — приложение-«пустышка» (около 4 КБ) с таким именем пакета.
При запуске оно сразу открывает другое приложение и закрывается.
У него нет разрешений: ни интернета, ни доступа к файлам.

| Кнопка   | Пакет-пустышка       | Открывает                         | Файл                  |
|----------|----------------------|-----------------------------------|-----------------------|
| иви      | `ru.ivi.client`      | SmartTube `org.smarttube.stable`  | `1-ivi-smarttube.apk` |
| okko     | `ru.more.play`       | Zona `mobi.zona`                  | `2-okko-zona.apk`     |
| VK Видео | `com.vk.tv`          | Кинопоиск `ru.kinopoisk.tv`       | `3-vk-kinopoisk.apk`  |
| RUTUBE   | `ru.rutube.app`      | VLC `org.videolan.vlc`            | `4-rutube-vlc.apk`    |
| KION     | `ru.mts.mtstv`       | Браузер `com.internet.tvbrowser`  | `5-kion-browser.apk`  |
| Wink     | `ru.rt.video.app.tv` | MantaRay `com.mantaray.vpn`       | `6-wink-mantaray.apk` |

## Установка (Termux)

    adb connect <IP телевизора>:5555
    for f in *.apk; do adb install "$f"; done

## Удаление (вернуть кнопкам стандартное поведение)

    for p in ru.ivi.client ru.more.play com.vk.tv ru.rutube.app ru.mts.mtstv ru.rt.video.app.tv; do adb uninstall $p; done

Если понадобится настоящее приложение (например, иви), сначала удалите его пустышку.

## Сборка

`src/<имя>/` — исходники для Apktool 2.10.0 (manifest + smali).
Сборка: `java -jar apktool.jar b src/<имя> -o <имя>.apk`, подпись: `jarsigner` (схема v1, targetSdk 29).
