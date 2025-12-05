# 📱 Инструкция по сборке .apk файла

## Требования

### 1. Установить Flutter

**Windows:**
```bash
# Скачать Flutter SDK
# https://docs.flutter.dev/get-started/install/windows

# Распаковать в C:\src\flutter
# Добавить в PATH: C:\src\flutter\bin

# Проверить установку
flutter doctor
```

**macOS/Linux:**
```bash
# Установить через snap (Linux)
sudo snap install flutter --classic

# Или скачать с сайта
# https://docs.flutter.dev/get-started/install

# Проверить
flutter doctor
```

### 2. Установить Android Studio

1. Скачать [Android Studio](https://developer.android.com/studio)
2. Установить Android SDK
3. Настроить переменные окружения:
   - `ANDROID_HOME` = путь к Android SDK
   - `JAVA_HOME` = путь к JDK

### 3. Проверить настройку

```bash
flutter doctor -v
```

Должно быть:
- ✅ Flutter (Channel stable)
- ✅ Android toolchain
- ✅ Android Studio

---

## Сборка .apk

### Шаг 1: Перейти в папку проекта

```bash
cd flutter-app
```

### Шаг 2: Установить зависимости

```bash
flutter pub get
```

### Шаг 3: Собрать .apk (Debug)

```bash
flutter build apk --debug
```

**Результат:** `build/app/outputs/flutter-apk/app-debug.apk`

### Шаг 4: Собрать .apk (Release) - Оптимизированный

```bash
flutter build apk --release
```

**Результат:** `build/app/outputs/flutter-apk/app-release.apk`

### Шаг 5: Собрать split APKs (рекомендуется)

```bash
flutter build apk --split-per-abi --release
```

**Результат:**
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

Размер каждого будет ~30-40 MB вместо ~60-70 MB для универсального.

---

## Быстрая сборка (одной командой)

```bash
cd flutter-app && flutter pub get && flutter build apk --release
```

APK будет в: `build/app/outputs/flutter-apk/app-release.apk`

---

## Установка на устройство

### Через USB

```bash
# Включить "Режим разработчика" на Android устройстве
# Подключить через USB
# Разрешить отладку по USB

flutter install
```

### Вручную

1. Скопировать `app-release.apk` на телефон
2. Открыть файл через File Manager
3. Разрешить установку из неизвестных источников
4. Установить

---

## Подписание APK (для Production)

### 1. Создать ключ подписи

```bash
keytool -genkey -v -keystore recall-upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Введите:
- Пароль keystore: (придумайте надежный)
- Пароль ключа: (тот же или другой)
- Имя, организация и т.д.

### 2. Настроить Gradle

Создайте `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../recall-upload-keystore.jks
```

Обновите `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 3. Собрать подписанный APK

```bash
flutter build apk --release
```

---

## Размер APK

| Сборка | Размер |
|--------|--------|
| Debug | ~80-100 MB |
| Release (универсальный) | ~50-70 MB |
| Release (split по ABI) | ~30-40 MB каждый |

---

## Проблемы и решения

### Ошибка: "SDK location not found"

**Решение:**
```bash
# Windows
set ANDROID_HOME=C:\Users\YourUser\AppData\Local\Android\Sdk

# Linux/Mac
export ANDROID_HOME=$HOME/Android/Sdk

# Или создать android/local.properties:
sdk.dir=C:\\Users\\YourUser\\AppData\\Local\\Android\\Sdk
```

### Ошибка: "Gradle task assembleRelease failed"

**Решение:**
```bash
cd android
./gradlew clean

cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Ошибка: "No connected devices"

**Решение:**
```bash
# Список устройств
flutter devices

# Если нет - включить отладку по USB
# Или собрать APK без запуска:
flutter build apk --release
```

---

## Оптимизация размера

### 1. Включить ProGuard (shrink code)

В `android/app/build.gradle`:
```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
    }
}
```

### 2. Удалить неиспользуемые ресурсы

```bash
flutter build apk --release --shrink
```

### 3. Split по архитектуре

```bash
flutter build apk --split-per-abi --release
```

---

## Тестирование APK

### Проверить размер

```bash
ls -lh build/app/outputs/flutter-apk/
```

### Установить на эмулятор

```bash
flutter emulators --launch Pixel_5_API_33
flutter install
```

### Проверить работу

1. Запустить приложение
2. Проверить все экраны
3. Проверить подключение к Supabase (если backend запущен)

---

## Публикация в Google Play

1. **Создать Google Play Console аккаунт** ($25 одноразово)
2. **Создать новое приложение**
3. **Загрузить подписанный APK** (или лучше AAB)
4. **Заполнить метаданные** (описание, скриншоты, иконка)
5. **Отправить на проверку**

### Собрать AAB (Android App Bundle) для Google Play

```bash
flutter build appbundle --release
```

**Результат:** `build/app/outputs/bundle/release/app-release.aab`

AAB предпочтительнее APK для Google Play, так как Google сам создаст оптимизированные APK для разных устройств.

---

## Готовые команды

```bash
# Быстрая сборка для тестирования
flutter build apk --debug

# Production сборка (один универсальный APK)
flutter build apk --release

# Production сборка (split APKs - меньший размер)
flutter build apk --split-per-abi --release

# Для Google Play Store
flutter build appbundle --release

# Установить на подключенное устройство
flutter install

# Запустить на устройстве
flutter run --release
```

---

## Итоговый checklist

- [ ] Flutter установлен (`flutter doctor`)
- [ ] Android SDK настроен
- [ ] Проект синхронизирован (`flutter pub get`)
- [ ] APK собран (`flutter build apk --release`)
- [ ] APK протестирован на устройстве
- [ ] (Опционально) Ключ подписи создан
- [ ] (Опционально) APK подписан для production
- [ ] (Опционально) Загружен в Google Play

---

**Готово!** APK будет в папке:
`build/app/outputs/flutter-apk/app-release.apk`
