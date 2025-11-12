<h1 align="center">� PadelHub</h1>

<p align="center">
  <em>Tu plataforma completa para gestionar partidos de pádel</em>
</p>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  </a>
  <a href="https://dart.dev">
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  </a>
  <a href="https://firebase.google.com">
    <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  </a>
</p>

<p align="center">
  <a href="https://github.com/clarriu97/padelhub/actions/workflows/ci.yml">
    <img src="https://img.shields.io/badge/CI-passing-brightgreen?style=flat-square&logo=github" alt="CI Status">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="License">
  </a>
  <img src="https://img.shields.io/badge/version-0.1.0-orange?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20Web-lightgrey?style=flat-square" alt="Platform">
</p>

---

## 📱 Sobre el Proyecto

**PadelHub** es una aplicación multiplataforma desarrollada con Flutter que te permite organizar y gestionar partidos de pádel de forma sencilla. Conecta con tus amigos, reserva pistas, y lleva un seguimiento de tus partidos.

### ✨ Características

- 🔐 **Autenticación segura** con Firebase Authentication
- 👥 **Gestión de usuarios** y perfiles personalizados
- 🎾 **Organización de partidos** y reservas
- 📊 **Estadísticas** de tus partidos
- 🌍 **Multiplataforma**: iOS, Android y Web
- 🎨 **UI moderna** y responsive con Material Design

---

## 🚀 Empezando

### Requisitos Previos

- Flutter SDK (^3.9.2)
- Dart SDK
- Firebase project configurado
- Android Studio / Xcode (para desarrollo móvil)

### Instalación

1. **Clona el repositorio**
   ```bash
   git clone https://github.com/clarriu97/padelhub.git
   cd padelhub
   ```

2. **Instala las dependencias**
   ```bash
   flutter pub get
   ```

3. **Configura Firebase**
   - Coloca tu `google-services.json` en `android/app/`
   - Coloca tu `GoogleService-Info.plist` en `ios/Runner/`

4. **Ejecuta la aplicación**
   ```bash
   flutter run
   ```

---

## 🧪 Testing

Ejecuta los tests con:

```bash
# Unit tests
flutter test

# Tests con coverage
flutter test --coverage
```

---

## 🏗️ Estructura del Proyecto

```
lib/
├── main.dart           # Punto de entrada de la aplicación
├── colors.dart         # Tema y colores
├── firebase_options.dart
└── screens/
    ├── auth/          # Pantallas de autenticación
    └── home/          # Pantallas principales
```

---

## 🛠️ Tecnologías

- **Flutter**: Framework de UI multiplataforma
- **Firebase Auth**: Autenticación de usuarios
- **Firebase Core**: Servicios de Firebase
- **Mockito**: Testing y mocking

---

## 📝 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

---

## 👨‍💻 Autor

Desarrollado con ❤️ y ☕ por [Carlos](https://github.com/clarriu97)

---

<p align="center">
  <em>¿Listo para tu próximo partido? 🎾</em>
</p>