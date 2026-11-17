import QtQuick

Item {
    id: bar
    property string label: ""
    property int value: 0
    property color fg: "#61afef"
    property color bgc: "#1b2a44"
    property color txt: "#e6e8ee"
    implicitHeight: 26

    Text {
        id: labelText
        text: bar.label
        color: bar.txt
        opacity: 0.85
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        id: valueText
        text: bar.value + "%"
        color: bar.txt
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        width: 40
        horizontalAlignment: Text.AlignRight
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        id: track
        height: 5
        radius: 2.5
        color: bar.bgc
        anchors.left: labelText.right
        anchors.leftMargin: 12
        anchors.right: valueText.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            height: parent.height
            radius: 2.5
            color: bar.fg
            width: parent.width * Math.min(100, Math.max(0, bar.value)) / 100
            Behavior on width {
                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
            }
        }
    }
}
