pragma Singleton
import QtQuick
import Qt.labs.platform
import Quickshell
import Quickshell.Services.Notifications
import "./"
import "./core" as Core
import "./core/Log.js" as Log

Singleton {
    id: root

    // Bildirim Listesi
    property var notifications: []
    property var activeNotifications: []
    
    // PENCERE KONTROLÜ
    property bool historyVisible: false
    function toggleHistory() { historyVisible = !historyVisible }

    // Display Duration (ms)
    property int displayDuration: 5000

    // DO NOT DISTURB
    property bool dnd: false
    
    // NEW ADVANCED SETTINGS
    property int popupPosition: 1 // 1: Top Right, 2: Top Left, 3: Top Center, 4: Bottom Center, 5: Bottom Right, 6: Bottom Left
    property bool overlayEnabled: false
    property bool compactMode: false
    property bool popupShadowEnabled: true
    property bool privacyMode: false
    property int animationSpeed: 1 // 0: None, 1: Short, 2: Medium, 3: Long, 4: Custom
    property int historyRetentionMs: 3600000

    // --- HTML TEMİZLEYİCİ ---
    function stripHtml(html) {
        if (!html) return ""
            return html.replace(/<[^>]*>/g, "")
    }

    // Bildirim Sunucusu
    property NotificationServer server: NotificationServer {
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        actionIconsSupported: true
        onNotification: notif => root.addNotification(notif)
    }

    function addNotification(notif) {
        // Gereksizleri at (Spotify vb.)
        if (notif.appName === "Spotify") return;

        // 1. İÇERİK HAZIRLIĞI (Firefox Düzeltmesi)
        var rawSummary = stripHtml(notif.summary || "")
        var rawBody = stripHtml(notif.body || "")
        var rawAppName = notif.appName || "Sistem"

        if (rawBody.trim() === "" && rawSummary !== "") {
            rawBody = rawSummary;
            rawSummary = rawAppName;
        }
        if (rawSummary === "") rawSummary = "Yeni Bildirim";
        if (rawBody === "") rawBody = "İçerik yok.";

        // 2. ÇİFT MESAJ ENGELLEME (ID veya içerik+zaman bazlı)
        var now = new Date();
        for (var d = 0; d < root.notifications.length && d < 5; d++) {
            var existing = root.notifications[d];
            // Aynı ID varsa güncelleme olabilir, tekrar ekleme
            if (existing.id === notif.id) return;
            // Aynı içerik 2 saniye içinde geldiyse engelle
            if (existing.summary === rawSummary && existing.body === rawBody) {
                var age = now - existing.timestamp;
                if (age < 2000) return;
            }
        }

        // İkon Çözücü (image://icon/ — rofi/wofi tarzı)
        var finalIcon = "";

        var appLower = rawAppName.toLowerCase().replace(/\s+/g, "-");
        var knownAppIcons = {
            "telegram-desktop": "telegram",
            "telegram": "telegram",
            "whatsapp": "whatsapp",
            "whatsapp-desktop": "whatsapp",
            "whatsapp-for-linux": "whatsapp",
            "zapzap": "whatsapp",
            "firefox": "firefox",
            "firefox-esr": "firefox-esr",
            "firefox-developer-edition": "firefox-developer-edition",
            "brave-browser": "brave",
            "brave": "brave",
            "google-chrome": "google-chrome",
            "google-chrome-stable": "google-chrome",
            "chromium": "chromium",
            "chromium-browser": "chromium-browser"
        };

        function resolveIconSource(rawIconValue) {
            var raw = String(rawIconValue || "").trim();
            if (raw === "") return "";
            if (raw.startsWith("image://icon//")) return "file://" + raw.substring("image://icon/".length);
            if (raw.startsWith("file://") || raw.startsWith("http://") || raw.startsWith("https://") || raw.startsWith("image://")) return raw;
            if (raw.startsWith("~/")) return "file://" + StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + raw.substring(1);
            if (raw.startsWith("/") || raw.indexOf("/") !== -1) return "file://" + raw;
            return "image://icon/" + raw.toLowerCase().replace(/\s+/g, "-");
        }

        if (knownAppIcons[appLower]) {
            finalIcon = "image://icon/" + knownAppIcons[appLower];
        } else {
            // 2. Genel ikon çözümlemesi
            let rawIcon = String(notif.image || notif.appIcon || notif.icon || "").trim();
            if (rawIcon !== "") {
                finalIcon = resolveIconSource(rawIcon);
            }
        }

        // Yeni Bildirim Objesi
        var newNotif = {
            id: notif.id,
            summary: rawSummary,
            body: rawBody,
            appName: rawAppName,
            appIcon: finalIcon,
            urgency: notif.urgency,
            timestamp: new Date(),
            closed: false
        };

        // Listeyi Güncelle (En başa ekle, max 100 tut)
        var newList = [newNotif];
        for(var i=0; i<root.notifications.length; i++) {
            if(i < 99) newList.push(root.notifications[i]);
        }
        root.notifications = newList;
        root.refreshActiveNotifications();
    }

    function removeNotification(index) {
        var list = root.notifications;
        // Listeden sil
        list.splice(index, 1);
        // Tetiklemek için tekrar ata
        root.notifications = list;
        root.refreshActiveNotifications();
    }

    function refreshActiveNotifications() {
        // Sadece kapatılmamış olanları filtrele
        root.activeNotifications = root.notifications.filter(n => !n.closed);
    }

    // 1 dakika sonra bildirimleri otomatik temizle
    Timer {
        id: cleanupTimer
        interval: 5000 // Her 5 saniyede kontrol et
        repeat: true
        running: true
        onTriggered: {
            var now = new Date();
            var changed = false;
            var newList = [];
            for (var i = 0; i < root.notifications.length; i++) {
                var age = now - root.notifications[i].timestamp;
                if (age < root.historyRetentionMs) {
                    newList.push(root.notifications[i]);
                } else {
                    changed = true;
                }
            }
            if (changed) {
                root.notifications = newList;
                root.refreshActiveNotifications();
            }
        }
    }

    function closeNotification(id) {
        // ID'ye göre bul ve kapatıldı işaretle
        for(var i=0; i<root.notifications.length; i++) {
            if (root.notifications[i].id === id) {
                root.notifications[i].closed = true;
            }
        }
        root.refreshActiveNotifications();
    }

    function focusApp(appName) {
        if (!appName || appName === "") return;
        CompositorService.focusAppByName(appName);
    }

    // ── PERSISTENCE (AYARLARI KAYDETME) ──
    property string configPath: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/quickshell/notification_config.json"
    
    function saveConfig() {
        var obj = {
            displayDuration: root.displayDuration,
            dnd: root.dnd,
            popupPosition: root.popupPosition,
            overlayEnabled: root.overlayEnabled,
            compactMode: root.compactMode,
            popupShadowEnabled: root.popupShadowEnabled,
            privacyMode: root.privacyMode,
            animationSpeed: root.animationSpeed
        };
        configStore.save(obj);
    }

    // Load on start
    Component.onCompleted: {
        configStore.load();
    }

    // Save on change
    onDisplayDurationChanged: saveConfigTimer.restart()
    onDndChanged: saveConfigTimer.restart()
    onPopupPositionChanged: saveConfigTimer.restart()
    onOverlayEnabledChanged: saveConfigTimer.restart()
    onCompactModeChanged: saveConfigTimer.restart()
    onPopupShadowEnabledChanged: saveConfigTimer.restart()
    onPrivacyModeChanged: saveConfigTimer.restart()
    onAnimationSpeedChanged: saveConfigTimer.restart()

    // Debounce save
    Timer {
        id: saveConfigTimer
        interval: 1000
        repeat: false
        onTriggered: root.saveConfig()
    }

    Core.JsonDataStore {
        id: configStore
        path: root.configPath
        defaultValue: ({
            displayDuration: 5000,
            dnd: false,
            popupPosition: 1,
            overlayEnabled: false,
            compactMode: false,
            popupShadowEnabled: true,
            privacyMode: false,
            animationSpeed: 1
        })
        onLoadedValue: function(cfg) {
            root.displayDuration = cfg.displayDuration || 5000;
            root.dnd = cfg.dnd !== undefined ? cfg.dnd : false;
            root.popupPosition = cfg.popupPosition !== undefined ? cfg.popupPosition : 1;
            root.overlayEnabled = cfg.overlayEnabled !== undefined ? cfg.overlayEnabled : false;
            root.compactMode = cfg.compactMode !== undefined ? cfg.compactMode : false;
            root.popupShadowEnabled = cfg.popupShadowEnabled !== undefined ? cfg.popupShadowEnabled : true;
            root.privacyMode = cfg.privacyMode !== undefined ? cfg.privacyMode : false;
            root.animationSpeed = cfg.animationSpeed !== undefined ? cfg.animationSpeed : 1;
        }
        onFailed: function(phase, exitCode, details) {
            if (phase === "parse") Log.warn("Notifications", "Config parse error: " + details);
        }
    }
}
