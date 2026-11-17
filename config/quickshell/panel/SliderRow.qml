import QtQuick

Item {
    id: slider
    property string icon: ""
    property int value: 0
    property color accent: "#61afef"
    property color trackColor: "#1b2a44"
    property color textColor: "#e6e8ee"
    property bool dragging: false
    signal moved(int v)
    implicitHeight: 34

    Text {
        id: iconText
        text: slider.icon
        color: slider.textColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
        }
    }

    Text {
        id: valueText
        text: slider.value + "%"
        color: slider.textColor
        opacity: 0.85
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        width: 40
        horizontalAlignment: Text.AlignRight
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        id: track
        height: 6
        radius: 3
        color: slider.trackColor
        anchors.left: iconText.right
        anchors.leftMargin: 12
        anchors.right: valueText.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            height: parent.height
            radius: 3
            color: slider.accent
            width: Math.min(track.width, track.width * Math.min(100, Math.max(0, slider.value)) / 100)
            Behavior on width {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }

        Rectangle {
            id: knob
            width: slider.dragging ? 16 : 12
            height: width
            radius: width / 2
            color: slider.accent
            anchors.verticalCenter: parent.verticalCenter
            x: Math.min(track.width - width, Math.max(0, track.width * slider.value / 100 - width / 2))
            Behavior on width {
                NumberAnimation { duration: 120 }
            }
            Behavior on x {
                enabled: !slider.dragging
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            width: track.width
            height: 26
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            cursorShape: Qt.PointingHandCursor
            onPressed: slider.dragging = true
            onReleased: slider.dragging = false
            onPositionChanged: {
                if (!pressed) return;
                const p = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100);
                slider.moved(p);
            }
            onWheel: function (wheel) {
                const delta = wheel.angleDelta.y > 0 ? 5 : -5;
                slider.moved(Math.max(0, Math.min(100, slider.value + delta)));
            }
        }
    }
}
