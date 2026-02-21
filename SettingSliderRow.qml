import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property string label: ''
    property string description: ''
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0
    property string text: String(value)
    signal moved(real value)

    spacing: Style.marginXXS
    Layout.fillWidth: true

    NLabel {
        label: root.label
        description: root.description
    }

    NValueSlider {
        Layout.fillWidth: true
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        text: root.text
        onMoved: value => root.moved(value)
    }
}
