# Odoo CRM Flutter App Blueprint

## 1. Project Overview

This document outlines the architecture, features, and development plan for a new Flutter-based CRM application designed to integrate with Odoo. The application is intended for a global market, emphasizing a high-quality user experience, scalability, and maintainability.

**Core Principles:**
- **User-Centric Design:** Beautiful, intuitive, and responsive UI.
- **Scalable Architecture:** Clean, feature-first project structure with a robust state management and routing solution.
- **Theming & Customization:** A comprehensive Material 3 theme that is easily customizable.
- **Senior-Level Code Quality:** Adherence to best practices, strong typing, separation of concerns, and comprehensive error handling.

---

## 2. Implemented Features & Design

This section will be updated as new features are implemented.

### v0.1: Initial Foundation
- **Architecture:**
    - `provider` for state management.
    - `go_router` for declarative routing.
    - Feature-first project directory structure.
- **Theming:**
    - Centralized Material 3 theme (`AppTheme`).
    - Primary seed color: `#6b4c7e`.
    - Generated `ColorScheme` for both light and dark modes.
    - Custom typography using `google_fonts` (`Oswald` for headlines, `Roboto` for body).
    - Styled component themes (`AppBar`, `ElevatedButton`).
    - Theme toggle (light/dark) functionality using `ThemeProvider`.
- **UI & Navigation:**
    - **Login Screen:** A visually appealing login page.
    - **Home Screen:** A basic dashboard screen displayed after login.
    - **Routing:** Initial routes for `/login` and `/` (home).

---

## 3. Current Development Plan: v0.1

The following steps will be executed to build the initial application base.

1.  **Install Dependencies:** Add `provider`, `google_fonts`, and `go_router` to `pubspec.yaml`.
2.  **Project Structure:** Create directories for `core` (theme, router), `features/authentication`, and `features/dashboard`.
3.  **Implement Theme Provider:** Create a `ThemeProvider` class to manage theme state (`ChangeNotifier`).
4.  **Define App Theme:** Create a centralized `app_theme.dart` file with `ThemeData` for both light and dark modes, using the specified seed color and fonts.
5.  **Configure Router:** Set up `go_router` with routes for the login and home screens.
6.  **Build Login Screen:** Develop the UI for the login screen with placeholder functionality.
7.  **Build Home Screen:** Develop the UI for the home screen, including a theme toggle button in the `AppBar`.
8.  **Integrate in `main.dart`:**
    - Wrap the app in `ChangeNotifierProvider`.
    - Use `MaterialApp.router` to integrate `go_router`.
    - Consume the `ThemeProvider` to apply the correct theme.
9.  **Code Quality Checks:** Run `dart format .` and `flutter analyze` to ensure code quality.

