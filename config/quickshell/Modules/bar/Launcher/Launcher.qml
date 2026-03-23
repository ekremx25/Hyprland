import QtQuick
import QtQuick.Layouts
import "."
import "../../../Widgets"

Rectangle {
    id: launcherRoot

    // --- SİNYAL ---
    signal settingsRequested()
    LauncherService { id: launcherService }

    // --- RENK AYARLARI ---
    // --- RENK AYARLARI ---
    property color containerColor: Theme.launcherColor
    property color hoverColor: Qt.lighter(containerColor, 1.1)
    property color iconColor: Theme.launcherIconColor
    property color borderColor: "#ccd0da" // border color unused? or keep?

    width: 34
    height: 34
    implicitWidth: 34
    implicitHeight: 34
    radius: 17
    color: launcherMouse.containsMouse ? hoverColor : containerColor
    border.width: 0 // Remove border to match Power button style? Power has no border.
    // border.color: borderColor

    Behavior on color { ColorAnimation { duration: 200 } }

    // --- LOGO SETTINGS ---
    property string logo: ""

    // --- GENTOO İKONU / CUSTOM LOGO ---
    
    // 1. Text Logo (if logo is text or empty/default)
    Text {
        anchors.centerIn: parent
        text: (launcherRoot.logo !== "" && launcherRoot.logo.indexOf("/") === -1 && launcherRoot.logo.indexOf(".") === -1) 
              ? launcherRoot.logo 
              : launcherService.distroIcon(launcherService.distroName)
        visible: !imgLogo.visible
        color: iconColor
        font.pixelSize: 18
        font.family: "JetBrainsMono Nerd Font"
        anchors.verticalCenterOffset: 1
    }

    // 2. Image Logo (if logo is a file path)
    Image {
        id: imgLogo
        anchors.centerIn: parent
        source: (launcherRoot.logo !== "" && (launcherRoot.logo.indexOf("/") !== -1 || launcherRoot.logo.indexOf(".") !== -1))
                ? (launcherRoot.logo.indexOf("file://") === 0 ? launcherRoot.logo : "file://" + launcherRoot.logo)
                : ""
        visible: source !== "" && status === Image.Ready
        width: 20
        height: 20
        fillMode: Image.PreserveAspectFit
    }

    // --- TIKLAMA ALANI ---
    MouseArea {
        id: launcherMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: launcherRoot.settingsRequested()
    }
}
