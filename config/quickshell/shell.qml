//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import "./Services"

import "./Modules/bar"
import "./Modules/bar/Notifications"
import "./Modules/bar/Weather"
import "./Modules/bar/Dock"
import "./Modules/bar/Tray"
import "./Modules/OSD"

ShellRoot {
    Loader {
        active: true
        source: "Services/ShellBootstrap.qml"
    }

    Loader {
        active: true
        source: "Services/EqBootstrap.qml"
    }

    Loader {
        active: true
        source: "Services/MouseBootstrap.qml"
    }

    Bar {}

    WeatherDesktop {}

    Dock {}

    Loader {
        active: true
        source: "Modules/bar/Notifications/ToastHost.qml"
    }

    Variants {
        model: ScreenManager.getFilteredScreens("osd")
        delegate: VolumeOSD {}
    }
}
