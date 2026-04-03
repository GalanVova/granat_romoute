import SwiftUI

// MARK: - Theme

enum AppTheme: String, CaseIterable {
    case dark   = "dark"
    case light  = "light"
    case system = "system"

    var colorScheme: ColorScheme? {
        switch self {
        case .dark:   return .dark
        case .light:  return .light
        case .system: return nil
        }
    }
}

// MARK: - Language

enum AppLanguage: String, CaseIterable {
    case english    = "en"
    case ukrainian  = "ua"
    case russian    = "ru"
    case spanish    = "es"
    case french     = "fr"
    case polish     = "pl"
    case bulgarian  = "bg"
    case romanian   = "ro"

    var displayName: String {
        switch self {
        case .english:   return "English"
        case .ukrainian: return "Українська"
        case .russian:   return "Русский"
        case .spanish:   return "Español"
        case .french:    return "Français"
        case .polish:    return "Polski"
        case .bulgarian: return "Български"
        case .romanian:  return "Română"
        }
    }
}

// MARK: - AppSettings

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "app_theme") }
    }
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "app_language") }
    }

    init() {
        let t = UserDefaults.standard.string(forKey: "app_theme") ?? AppTheme.dark.rawValue
        theme = AppTheme(rawValue: t) ?? .dark
        let l = UserDefaults.standard.string(forKey: "app_language") ?? AppLanguage.english.rawValue
        language = AppLanguage(rawValue: l) ?? .english
    }

    func t(_ key: String) -> String {
        L10n.strings[language]?[key] ?? L10n.strings[.english]?[key] ?? key
    }
}

// MARK: - L10n strings table

enum L10n {
    static let strings: [AppLanguage: [String: String]] = [
        .english:   en,
        .ukrainian: ua,
        .russian:   ru,
        .spanish:   es,
        .french:    fr,
        .polish:    pl,
        .bulgarian: bg,
        .romanian:  ro,
    ]

    // MARK: English
    static let en: [String: String] = [
        // Tabs
        "tab.home":     "Home",
        "tab.events":   "Events",
        "tab.balance":  "Balance",
        "tab.help":     "Help",
        "tab.settings": "Settings",

        // Home
        "home.objects":           "Your objects",
        "home.connection_error":  "Connection error",
        "home.retry":             "Try again",

        // Commands
        "cmd.arm_stay":   "Arm stay\nat home",
        "cmd.disarm":     "Disarm",
        "cmd.arm":        "Arm",
        "cmd.sos":        "SOS\nAlarm",
        "cmd.output":     "Toggle\noutput",
        "cmd.out_status": "Output\nstatus",

        // Arm states
        "arm.disarmed": "Disarmed",
        "arm.armed":    "Armed",
        "arm.home":     "Home",
        "arm.unknown":  "Unknown",

        // Panel / cameras
        "panel.cameras":     "Cameras",
        "panel.no_cameras":  "No cameras added",

        // Output number sheet
        "output.title":       "Output number",
        "output.placeholder": "Number",
        "btn.ok":     "OK",
        "btn.cancel": "Cancel",

        // Balance
        "balance.title": "Balance",

        // Events
        "events.title":  "Events",
        "events.none":   "No events",

        // Help
        "help.title":  "Help",
        "help.none":   "No help information available.",

        // Settings
        "settings.title":       "Settings",
        "settings.account":     "Account",
        "settings.login":       "Login",
        "settings.pcn":         "Monitoring center",
        "settings.logout":      "Log out",
        "settings.logout_title":"Log out?",
        "settings.logout_msg":  "Saved credentials will be removed.",
        "settings.cameras":     "Cameras",
        "settings.add_camera":  "Add camera",
        "settings.appearance":  "Appearance",
        "settings.language":    "Language",
        "settings.about":       "About",
        "settings.version":     "Version",

        // Theme
        "theme.dark":   "Dark",
        "theme.light":  "Light",
        "theme.system": "System",

        // Camera edit
        "camera.add":         "Add camera",
        "camera.edit":        "Edit camera",
        "camera.name":        "Camera name",
        "camera.name_ph":     "e.g. Entrance",
        "camera.url":         "Stream URL",
        "camera.url_ph":      "rtsp:// or http://",
        "btn.save":           "Save",

        // General
        "err.not_connected": "Not connected",
        "err.error":         "Error",
        "err.cmd":           "Command error",

        // Object tabs
        "obj.commands": "Commands",
        "obj.events":   "Events",
        "obj.schedule": "Schedule",

        // Events camera button
        "events.camera": "Camera",

        // Schedule
        "schedule.title":      "Schedule",
        "schedule.add":        "Add rule",
        "schedule.none":       "No schedule rules",
        "schedule.arm":        "Arm",
        "schedule.disarm":     "Disarm",
        "schedule.arm_stay":   "Arm stay",
        "schedule.everyday":   "Every day",
        "schedule.weekdays":   "Weekdays",
        "schedule.weekends":   "Weekends",
        "schedule.mon": "Mon", "schedule.tue": "Tue", "schedule.wed": "Wed",
        "schedule.thu": "Thu", "schedule.fri": "Fri", "schedule.sat": "Sat", "schedule.sun": "Sun",
        "schedule.time":       "Time",
        "schedule.days":       "Days",
        "schedule.action":     "Action",
        "schedule.add_title":  "Add rule",
        "schedule.edit_title": "Edit rule",
        "schedule.object":     "Object",
        "schedule.all":        "All objects",
    ]

    // MARK: Ukrainian
    static let ua: [String: String] = [
        "tab.home":     "Головна",
        "tab.events":   "Події",
        "tab.balance":  "Баланс",
        "tab.help":     "Довідка",
        "tab.settings": "Налаштування",

        "home.objects":          "Ваші об'єкти",
        "home.connection_error": "Помилка з'єднання",
        "home.retry":            "Спробувати знову",

        "cmd.arm_stay":   "Вдома\nпід охороною",
        "cmd.disarm":     "Зняти\nз охорони",
        "cmd.arm":        "Поставити\nпід охорону",
        "cmd.sos":        "SOS\nТривога",
        "cmd.output":     "Перемкнути\nвихід",
        "cmd.out_status": "Стан\nвиходу",

        "arm.disarmed": "Знято",
        "arm.armed":    "Під охороною",
        "arm.home":     "Вдома",
        "arm.unknown":  "Невідомо",

        "panel.cameras":    "Камери",
        "panel.no_cameras": "Камер немає",

        "output.title":       "Номер виходу",
        "output.placeholder": "Номер",
        "btn.ok":     "OK",
        "btn.cancel": "Скасувати",

        "balance.title": "Баланс",

        "obj.commands": "Команди",
        "obj.events":   "Події",
        "obj.schedule": "Розклад",
        "events.camera": "Camera",

        "events.title": "Події",
        "events.none":  "Подій немає",

        "help.title": "Довідка",
        "help.none":  "Інформація відсутня.",

        "settings.title":        "Налаштування",
        "settings.account":      "Акаунт",
        "settings.login":        "Логін",
        "settings.pcn":          "Пункт охорони",
        "settings.logout":       "Вийти",
        "settings.logout_title": "Вийти?",
        "settings.logout_msg":   "Збережені дані буде видалено.",
        "settings.cameras":      "Камери",
        "settings.add_camera":   "Додати камеру",
        "settings.appearance":   "Оформлення",
        "settings.language":     "Мова",
        "settings.about":        "Про застосунок",
        "settings.version":      "Версія",

        "theme.dark":   "Темна",
        "theme.light":  "Світла",
        "theme.system": "Системна",

        "camera.add":     "Додати камеру",
        "camera.edit":    "Редагувати камеру",
        "camera.name":    "Назва камери",
        "camera.name_ph": "напр. Вхід",
        "camera.url":     "URL потоку",
        "camera.url_ph":  "rtsp:// або http://",
        "btn.save":       "Зберегти",

        "err.not_connected": "Немає з'єднання",
        "err.error":         "Помилка",
        "err.cmd":           "Помилка команди",

        "schedule.title":      "Розклад",
        "schedule.add":        "Додати правило",
        "schedule.none":       "Правил немає",
        "schedule.arm":        "Поставити під охорону",
        "schedule.disarm":     "Зняти з охорони",
        "schedule.arm_stay":   "Дома під охороною",
        "schedule.everyday":   "Щодня",
        "schedule.weekdays":   "Будні",
        "schedule.weekends":   "Вихідні",
        "schedule.mon": "Пн", "schedule.tue": "Вт", "schedule.wed": "Ср",
        "schedule.thu": "Чт", "schedule.fri": "Пт", "schedule.sat": "Сб", "schedule.sun": "Нд",
        "schedule.time":       "Час",
        "schedule.days":       "Дні",
        "schedule.action":     "Дія",
        "schedule.add_title":  "Додати правило",
        "schedule.edit_title": "Редагувати правило",
        "schedule.object":     "Об'єкт",
        "schedule.all":        "Всі об'єкти",
    ]

    // MARK: Russian
    static let ru: [String: String] = [
        "tab.home":     "Главная",
        "tab.events":   "События",
        "tab.balance":  "Баланс",
        "tab.help":     "Справка",
        "tab.settings": "Настройки",

        "home.objects":          "Ваши объекты",
        "home.connection_error": "Ошибка соединения",
        "home.retry":            "Попробовать снова",

        "cmd.arm_stay":   "Дома\nпод охраной",
        "cmd.disarm":     "Снять\nс охраны",
        "cmd.arm":        "Поставить\nпод охрану",
        "cmd.sos":        "SOS\nТревога",
        "cmd.output":     "Переключить\nвыход",
        "cmd.out_status": "Статус\nвыхода",

        "arm.disarmed": "Снято",
        "arm.armed":    "Под охраной",
        "arm.home":     "Дома",
        "arm.unknown":  "Неизвестно",

        "panel.cameras":    "Камеры",
        "panel.no_cameras": "Камер нет",

        "output.title":       "Номер выхода",
        "output.placeholder": "Номер",
        "btn.ok":     "OK",
        "btn.cancel": "Отмена",

        "balance.title": "Баланс",

        "obj.commands": "Команды",
        "obj.events":   "События",
        "obj.schedule": "Расписание",
        "events.camera": "Camera",

        "events.title": "События",
        "events.none":  "Событий нет",

        "help.title": "Справка",
        "help.none":  "Информация отсутствует.",

        "settings.title":        "Настройки",
        "settings.account":      "Аккаунт",
        "settings.login":        "Логин",
        "settings.pcn":          "Пункт охраны",
        "settings.logout":       "Выйти",
        "settings.logout_title": "Выйти?",
        "settings.logout_msg":   "Сохранённые данные будут удалены.",
        "settings.cameras":      "Камеры",
        "settings.add_camera":   "Добавить камеру",
        "settings.appearance":   "Оформление",
        "settings.language":     "Язык",
        "settings.about":        "О приложении",
        "settings.version":      "Версия",

        "theme.dark":   "Тёмная",
        "theme.light":  "Светлая",
        "theme.system": "Системная",

        "camera.add":     "Добавить камеру",
        "camera.edit":    "Редактировать камеру",
        "camera.name":    "Название камеры",
        "camera.name_ph": "напр. Вход",
        "camera.url":     "URL потока",
        "camera.url_ph":  "rtsp:// или http://",
        "btn.save":       "Сохранить",

        "err.not_connected": "Нет соединения",
        "err.error":         "Ошибка",
        "err.cmd":           "Ошибка команды",

        "schedule.title":      "Расписание",
        "schedule.add":        "Добавить правило",
        "schedule.none":       "Правил нет",
        "schedule.arm":        "Поставить под охрану",
        "schedule.disarm":     "Снять с охраны",
        "schedule.arm_stay":   "Дома под охраной",
        "schedule.everyday":   "Ежедневно",
        "schedule.weekdays":   "Будни",
        "schedule.weekends":   "Выходные",
        "schedule.mon": "Пн", "schedule.tue": "Вт", "schedule.wed": "Ср",
        "schedule.thu": "Чт", "schedule.fri": "Пт", "schedule.sat": "Сб", "schedule.sun": "Вс",
        "schedule.time":       "Время",
        "schedule.days":       "Дни",
        "schedule.action":     "Действие",
        "schedule.add_title":  "Добавить правило",
        "schedule.edit_title": "Редактировать правило",
        "schedule.object":     "Объект",
        "schedule.all":        "Все объекты",
    ]

    // MARK: Spanish
    static let es: [String: String] = [
        "tab.home": "Inicio", "tab.events": "Eventos", "tab.balance": "Balance",
        "tab.help": "Ayuda", "tab.settings": "Ajustes",
        "home.objects": "Sus objetos", "home.connection_error": "Error de conexión", "home.retry": "Reintentar",
        "cmd.arm_stay": "En casa\nbajo guardia", "cmd.disarm": "Desactivar", "cmd.arm": "Activar",
        "cmd.sos": "Alarma\nSOS", "cmd.output": "Alternar\nsalida", "cmd.out_status": "Estado\nsalida",
        "arm.disarmed": "Desactivado", "arm.armed": "Activado", "arm.home": "En casa", "arm.unknown": "Desconocido",
        "panel.cameras": "Cámaras", "panel.no_cameras": "Sin cámaras",
        "output.title": "Número de salida", "output.placeholder": "Número",
        "btn.ok": "OK", "btn.cancel": "Cancelar", "btn.save": "Guardar",
        "obj.commands": "Comandos", "obj.events": "Eventos", "obj.schedule": "Horario",
        "events.camera": "Camera",
        "balance.title": "Balance", "events.title": "Eventos", "events.none": "Sin eventos",
        "help.title": "Ayuda", "help.none": "Sin información.",
        "settings.title": "Ajustes", "settings.account": "Cuenta", "settings.login": "Usuario",
        "settings.pcn": "Centro de seguridad", "settings.logout": "Cerrar sesión",
        "settings.logout_title": "¿Cerrar sesión?", "settings.logout_msg": "Se eliminarán las credenciales.",
        "settings.cameras": "Cámaras", "settings.add_camera": "Añadir cámara",
        "settings.appearance": "Apariencia", "settings.language": "Idioma",
        "settings.about": "Acerca de", "settings.version": "Versión",
        "theme.dark": "Oscuro", "theme.light": "Claro", "theme.system": "Sistema",
        "camera.add": "Añadir cámara", "camera.edit": "Editar cámara",
        "camera.name": "Nombre", "camera.name_ph": "ej. Entrada",
        "camera.url": "URL del stream", "camera.url_ph": "rtsp:// o http://",
        "err.not_connected": "Sin conexión", "err.error": "Error", "err.cmd": "Error de comando",
        "schedule.title": "Horario", "schedule.add": "Añadir regla", "schedule.none": "Sin reglas",
        "schedule.arm": "Activar", "schedule.disarm": "Desactivar", "schedule.arm_stay": "En casa bajo guardia",
        "schedule.everyday": "Diario", "schedule.weekdays": "Laborables", "schedule.weekends": "Fines de semana",
        "schedule.mon": "Lun", "schedule.tue": "Mar", "schedule.wed": "Mié",
        "schedule.thu": "Jue", "schedule.fri": "Vie", "schedule.sat": "Sáb", "schedule.sun": "Dom",
        "schedule.time": "Hora", "schedule.days": "Días", "schedule.action": "Acción",
        "schedule.add_title": "Añadir regla", "schedule.edit_title": "Editar regla",
        "schedule.object": "Objeto", "schedule.all": "Todos los objetos",
    ]

    // MARK: French
    static let fr: [String: String] = [
        "tab.home": "Accueil", "tab.events": "Événements", "tab.balance": "Solde",
        "tab.help": "Aide", "tab.settings": "Paramètres",
        "home.objects": "Vos objets", "home.connection_error": "Erreur de connexion", "home.retry": "Réessayer",
        "cmd.arm_stay": "À domicile\nsous surveillance", "cmd.disarm": "Désarmer", "cmd.arm": "Armer",
        "cmd.sos": "Alarme\nSOS", "cmd.output": "Basculer\nla sortie", "cmd.out_status": "État\nsortie",
        "arm.disarmed": "Désarmé", "arm.armed": "Armé", "arm.home": "À domicile", "arm.unknown": "Inconnu",
        "panel.cameras": "Caméras", "panel.no_cameras": "Aucune caméra",
        "output.title": "Numéro de sortie", "output.placeholder": "Numéro",
        "btn.ok": "OK", "btn.cancel": "Annuler", "btn.save": "Sauvegarder",
        "obj.commands": "Commandes", "obj.events": "Événements", "obj.schedule": "Horaire",
        "events.camera": "Camera",
        "balance.title": "Solde", "events.title": "Événements", "events.none": "Aucun événement",
        "help.title": "Aide", "help.none": "Aucune information disponible.",
        "settings.title": "Paramètres", "settings.account": "Compte", "settings.login": "Identifiant",
        "settings.pcn": "Centre de sécurité", "settings.logout": "Déconnexion",
        "settings.logout_title": "Se déconnecter ?", "settings.logout_msg": "Les identifiants seront supprimés.",
        "settings.cameras": "Caméras", "settings.add_camera": "Ajouter une caméra",
        "settings.appearance": "Apparence", "settings.language": "Langue",
        "settings.about": "À propos", "settings.version": "Version",
        "theme.dark": "Sombre", "theme.light": "Clair", "theme.system": "Système",
        "camera.add": "Ajouter une caméra", "camera.edit": "Modifier la caméra",
        "camera.name": "Nom de la caméra", "camera.name_ph": "ex. Entrée",
        "camera.url": "URL du flux", "camera.url_ph": "rtsp:// ou http://",
        "err.not_connected": "Non connecté", "err.error": "Erreur", "err.cmd": "Erreur de commande",
        "schedule.title": "Planning", "schedule.add": "Ajouter une règle", "schedule.none": "Aucune règle",
        "schedule.arm": "Armer", "schedule.disarm": "Désarmer", "schedule.arm_stay": "À domicile sous surveillance",
        "schedule.everyday": "Tous les jours", "schedule.weekdays": "Jours ouvrables", "schedule.weekends": "Week-ends",
        "schedule.mon": "Lun", "schedule.tue": "Mar", "schedule.wed": "Mer",
        "schedule.thu": "Jeu", "schedule.fri": "Ven", "schedule.sat": "Sam", "schedule.sun": "Dim",
        "schedule.time": "Heure", "schedule.days": "Jours", "schedule.action": "Action",
        "schedule.add_title": "Ajouter une règle", "schedule.edit_title": "Modifier la règle",
        "schedule.object": "Objet", "schedule.all": "Tous les objets",
    ]

    // MARK: Polish
    static let pl: [String: String] = [
        "tab.home": "Główna", "tab.events": "Zdarzenia", "tab.balance": "Saldo",
        "tab.help": "Pomoc", "tab.settings": "Ustawienia",
        "home.objects": "Twoje obiekty", "home.connection_error": "Błąd połączenia", "home.retry": "Spróbuj ponownie",
        "cmd.arm_stay": "W domu\npod ochroną", "cmd.disarm": "Rozbrojenie", "cmd.arm": "Uzbrojenie",
        "cmd.sos": "Alarm\nSOS", "cmd.output": "Przełącz\nwyjście", "cmd.out_status": "Stan\nwyjścia",
        "arm.disarmed": "Rozbrojony", "arm.armed": "Uzbrojony", "arm.home": "W domu", "arm.unknown": "Nieznany",
        "panel.cameras": "Kamery", "panel.no_cameras": "Brak kamer",
        "output.title": "Numer wyjścia", "output.placeholder": "Numer",
        "btn.ok": "OK", "btn.cancel": "Anuluj", "btn.save": "Zapisz",
        "obj.commands": "Komendy", "obj.events": "Zdarzenia", "obj.schedule": "Harmonogram",
        "events.camera": "Camera",
        "balance.title": "Saldo", "events.title": "Zdarzenia", "events.none": "Brak zdarzeń",
        "help.title": "Pomoc", "help.none": "Brak informacji.",
        "settings.title": "Ustawienia", "settings.account": "Konto", "settings.login": "Login",
        "settings.pcn": "Centrum ochrony", "settings.logout": "Wyloguj",
        "settings.logout_title": "Wylogować się?", "settings.logout_msg": "Dane logowania zostaną usunięte.",
        "settings.cameras": "Kamery", "settings.add_camera": "Dodaj kamerę",
        "settings.appearance": "Wygląd", "settings.language": "Język",
        "settings.about": "O aplikacji", "settings.version": "Wersja",
        "theme.dark": "Ciemny", "theme.light": "Jasny", "theme.system": "Systemowy",
        "camera.add": "Dodaj kamerę", "camera.edit": "Edytuj kamerę",
        "camera.name": "Nazwa kamery", "camera.name_ph": "np. Wejście",
        "camera.url": "URL strumienia", "camera.url_ph": "rtsp:// lub http://",
        "err.not_connected": "Brak połączenia", "err.error": "Błąd", "err.cmd": "Błąd polecenia",
        "schedule.title": "Harmonogram", "schedule.add": "Dodaj regułę", "schedule.none": "Brak reguł",
        "schedule.arm": "Uzbrojenie", "schedule.disarm": "Rozbrojenie", "schedule.arm_stay": "W domu pod ochroną",
        "schedule.everyday": "Codziennie", "schedule.weekdays": "Dni robocze", "schedule.weekends": "Weekendy",
        "schedule.mon": "Pon", "schedule.tue": "Wt", "schedule.wed": "Śr",
        "schedule.thu": "Czw", "schedule.fri": "Pt", "schedule.sat": "Sob", "schedule.sun": "Nd",
        "schedule.time": "Czas", "schedule.days": "Dni", "schedule.action": "Działanie",
        "schedule.add_title": "Dodaj regułę", "schedule.edit_title": "Edytuj regułę",
        "schedule.object": "Obiekt", "schedule.all": "Wszystkie obiekty",
    ]

    // MARK: Bulgarian
    static let bg: [String: String] = [
        "tab.home": "Начало", "tab.events": "Събития", "tab.balance": "Баланс",
        "tab.help": "Помощ", "tab.settings": "Настройки",
        "home.objects": "Вашите обекти", "home.connection_error": "Грешка при връзка", "home.retry": "Опитай отново",
        "cmd.arm_stay": "У дома\nпод охрана", "cmd.disarm": "Деактивиране", "cmd.arm": "Активиране",
        "cmd.sos": "SOS\nТревога", "cmd.output": "Превключи\nизхода", "cmd.out_status": "Статус\nна изхода",
        "arm.disarmed": "Деактивирано", "arm.armed": "Активирано", "arm.home": "У дома", "arm.unknown": "Неизвестно",
        "panel.cameras": "Камери", "panel.no_cameras": "Няма камери",
        "output.title": "Номер на изхода", "output.placeholder": "Номер",
        "btn.ok": "OK", "btn.cancel": "Отказ", "btn.save": "Запази",
        "obj.commands": "Команди", "obj.events": "Събития", "obj.schedule": "Разписание",
        "events.camera": "Camera",
        "balance.title": "Баланс", "events.title": "Събития", "events.none": "Няма събития",
        "help.title": "Помощ", "help.none": "Няма информация.",
        "settings.title": "Настройки", "settings.account": "Акаунт", "settings.login": "Логин",
        "settings.pcn": "Охранителен център", "settings.logout": "Изход",
        "settings.logout_title": "Изход?", "settings.logout_msg": "Данните ще бъдат изтрити.",
        "settings.cameras": "Камери", "settings.add_camera": "Добави камера",
        "settings.appearance": "Външен вид", "settings.language": "Език",
        "settings.about": "За приложението", "settings.version": "Версия",
        "theme.dark": "Тъмна", "theme.light": "Светла", "theme.system": "Системна",
        "camera.add": "Добави камера", "camera.edit": "Редактирай камера",
        "camera.name": "Име на камерата", "camera.name_ph": "напр. Вход",
        "camera.url": "URL на потока", "camera.url_ph": "rtsp:// или http://",
        "err.not_connected": "Няма връзка", "err.error": "Грешка", "err.cmd": "Грешка на командата",
        "schedule.title": "Разписание", "schedule.add": "Добави правило", "schedule.none": "Няма правила",
        "schedule.arm": "Активиране", "schedule.disarm": "Деактивиране", "schedule.arm_stay": "У дома под охрана",
        "schedule.everyday": "Всеки ден", "schedule.weekdays": "Делнични", "schedule.weekends": "Почивни",
        "schedule.mon": "Пн", "schedule.tue": "Вт", "schedule.wed": "Ср",
        "schedule.thu": "Чт", "schedule.fri": "Пт", "schedule.sat": "Сб", "schedule.sun": "Нд",
        "schedule.time": "Час", "schedule.days": "Дни", "schedule.action": "Действие",
        "schedule.add_title": "Добави правило", "schedule.edit_title": "Редактирай правило",
        "schedule.object": "Обект", "schedule.all": "Всички обекти",
    ]

    // MARK: Romanian
    static let ro: [String: String] = [
        "tab.home": "Acasă", "tab.events": "Evenimente", "tab.balance": "Sold",
        "tab.help": "Ajutor", "tab.settings": "Setări",
        "home.objects": "Obiectele dvs.", "home.connection_error": "Eroare de conectare", "home.retry": "Încearcă din nou",
        "cmd.arm_stay": "Acasă\nsub pază", "cmd.disarm": "Dezarmare", "cmd.arm": "Armare",
        "cmd.sos": "Alarmă\nSOS", "cmd.output": "Comutare\niesire", "cmd.out_status": "Stare\niesire",
        "arm.disarmed": "Dezarmat", "arm.armed": "Armat", "arm.home": "Acasă", "arm.unknown": "Necunoscut",
        "panel.cameras": "Camere", "panel.no_cameras": "Fără camere",
        "output.title": "Numărul ieșirii", "output.placeholder": "Număr",
        "btn.ok": "OK", "btn.cancel": "Anulează", "btn.save": "Salvează",
        "obj.commands": "Comenzi", "obj.events": "Evenimente", "obj.schedule": "Program",
        "events.camera": "Camera",
        "balance.title": "Sold", "events.title": "Evenimente", "events.none": "Fără evenimente",
        "help.title": "Ajutor", "help.none": "Fără informații.",
        "settings.title": "Setări", "settings.account": "Cont", "settings.login": "Utilizator",
        "settings.pcn": "Centru de pază", "settings.logout": "Deconectare",
        "settings.logout_title": "Deconectare?", "settings.logout_msg": "Datele salvate vor fi șterse.",
        "settings.cameras": "Camere", "settings.add_camera": "Adaugă cameră",
        "settings.appearance": "Aspect", "settings.language": "Limbă",
        "settings.about": "Despre", "settings.version": "Versiune",
        "theme.dark": "Întunecat", "theme.light": "Luminos", "theme.system": "Sistem",
        "camera.add": "Adaugă cameră", "camera.edit": "Editează camera",
        "camera.name": "Numele camerei", "camera.name_ph": "ex. Intrare",
        "camera.url": "URL stream", "camera.url_ph": "rtsp:// sau http://",
        "err.not_connected": "Fără conexiune", "err.error": "Eroare", "err.cmd": "Eroare comandă",
        "schedule.title": "Orar", "schedule.add": "Adaugă regulă", "schedule.none": "Fără reguli",
        "schedule.arm": "Armare", "schedule.disarm": "Dezarmare", "schedule.arm_stay": "Acasă sub pază",
        "schedule.everyday": "Zilnic", "schedule.weekdays": "Zile lucrătoare", "schedule.weekends": "Weekend",
        "schedule.mon": "Lu", "schedule.tue": "Ma", "schedule.wed": "Mi",
        "schedule.thu": "Jo", "schedule.fri": "Vi", "schedule.sat": "Sâ", "schedule.sun": "Du",
        "schedule.time": "Oră", "schedule.days": "Zile", "schedule.action": "Acțiune",
        "schedule.add_title": "Adaugă regulă", "schedule.edit_title": "Editează regulă",
        "schedule.object": "Obiect", "schedule.all": "Toate obiectele",
    ]
}
