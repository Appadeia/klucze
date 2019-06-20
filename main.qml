import QtQuick 2.9
import QtQml 2.12
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.components 2.0 as PlasmaComponents
import me.appadeia.QmlTotp 1.0
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Dialogs 1.3 as Dialogs
import Qt.labs.platform 1.1 as QNative

Kirigami.ApplicationWindow {
    id: root
    visible: true
    width: 640
    minimumWidth: 470
    height: 480
    minimumHeight: 400
    title: qsTr("Klucze")
    property bool shouldClose: false
    QmlTotp {
        id: totpObj
    }
    Settings {
        id: settings
        property string dataStorage: ""
    }
    Component.onCompleted: {
      if (settings.dataStorage) {
        root.authModel.clear()
        var storemodel = JSON.parse(settings.dataStorage)
        for (var i = 0; i < storemodel.length; ++i) root.authModel.append(storemodel[i])
      }
      systrayIcon.visible = true
    }
    onClosing: {
        if (!root.shouldClose) {
            root.hide()
            close.accepted = false
            return
        } else {
            systrayIcon.visible = false
        }
        var storemodel = []
        for (var i = 0; i < root.authModel.count; ++i) storemodel.push(root.authModel.get(i))
        settings.dataStorage = JSON.stringify(storemodel)
        systrayIcon.visible = false
    }
    property ListModel authModel: ListModel {

    }
    QNative.SystemTrayIcon {
        id: systrayIcon
        visible: false
        iconName: "klucze"
        menu: QNative.Menu {
            id: trayCopyMenu
            QNative.MenuItem {
                text: "Focus Klucze"
                onTriggered: {
                    root.hide()
                    root.show()
                }
            }
            QNative.MenuItem {
                text: "Close Klucze"
                onTriggered: {
                    root.shouldClose = true
                    root.close()
                }
            }
            QNative.MenuSeparator {}
        }
    }
    Instantiator {
        model: root.authModel
        onObjectAdded: trayCopyMenu.insertItem( index + 3, object )
        onObjectRemoved: trayCopyMenu.removeItem( object )
        delegate: QNative.MenuItem {
            text: "Copy " + model["name"]
            onTriggered: {
                totpObj.copyToClipboard(totpObj.getTotpForSix(model["secret"]))
            }
        }
    }
    QNative.MenuBar {
        QNative.Menu {
            title: "Services"
            QNative.MenuItem {
                iconName: "list-add"
                text: "Add Service"
                onTriggered: {
                    addCard.visible = true
                }
            }
            QNative.MenuSeparator {}
            QNative.Menu {
                id: serviceCodeMenu
                title: "Copy Service Code"
                Instantiator {
                    model: root.authModel
                    onObjectAdded: serviceCodeMenu.insertItem( index, object )
                    onObjectRemoved: serviceCodeMenu.removeItem( object )
                    delegate: QNative.MenuItem {
                        text: model["name"]
                        onTriggered: {
                            copiedSheet.alertCopied(model["name"])
                            totpObj.copyToClipboard(totpObj.getTotpForSix(model["secret"]))
                        }
                    }
                }
            }
            QNative.Menu {
                id: serviceRemovalMenu
                title: "Remove Service"
                Instantiator {
                    model: root.authModel
                    onObjectAdded: serviceRemovalMenu.insertItem( index, object )
                    onObjectRemoved: serviceRemovalMenu.removeItem( object )
                    delegate: QNative.MenuItem {
                        text: model["name"]
                        onTriggered: {
                            deleteSheet.requestDelete(model["index"], model["name"])
                        }
                    }
                }
            }
        }
    }
    ScrollView {
        anchors.fill: parent
        Column {
            id: mainColumn
            spacing: Kirigami.Units.largeSpacing
            width: root.width
            height: children.height
            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    duration: 250
                    from: 0
                    to: 1
                }
            }
            move: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }

            Spacer {
                height: Kirigami.Units.largeSpacing
            }

            Kirigami.Card {
                visible: root.authModel.count == 0
                id: noServicesRect
                anchors.horizontalCenter: parent.horizontalCenter
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                width: root.width <= 500 ? root.width : 500
                height: 20 + noColumn.height + 20
                Column {
                    anchors.centerIn: parent
                    id: noColumn
                    spacing: 0
                    Kirigami.Heading {
                        id: noServicesLabel
                        width: noServicesRect.width * 4/5
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        text: "You have no services. Click \"Add Service\" to add a service."
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        addDialog.open()
                    }
                }
            }
            Repeater {
                model: root.authModel
                delegate: Kirigami.Card {
                    id: rect
                    property bool editMode: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    Kirigami.Theme.colorSet: Kirigami.Theme.View

//                    background: Rectangle {
//                        Kirigami.Theme.colorSet: Kirigami.Theme.View
//                        property color errorColor: Kirigami.Theme.negativeTextColor
//                        property color backgroundColor: Kirigami.Theme.backgroundColor
//                        color: codeField.text.toLowerCase().includes("error") ? Qt.tint(backgroundColor, Qt.rgba(errorColor.r,errorColor.g,errorColor.b,0.2)) : backgroundColor
//                    }

                    width: root.width <= 500 ? root.width : 500
                    height: rect.editMode ? 50 + editColumn.height : 10 + ( heading.height * 3 ) + 10
                    actions: [
                        Kirigami.Action {
                            iconName: "edit-copy-symbolic"
                            text: "Copy"
                            onTriggered: {
                                copiedSheet.alertCopied(model["name"])
                                totpObj.copyToClipboard(totpObj.getTotpForSix(model["secret"]))
                            }
                        }
                    ]
                    hiddenActions: [
                        Kirigami.Action {
                            iconName: "edit-delete-symbolic"
                            text: "Delete"
                            onTriggered: {
                                deleteSheet.requestDelete(model["index"], model["name"])
                            }
                        },
                        Kirigami.Action {
                            iconName: "edit-symbolic"
                            text: "Edit"
                            onTriggered: {
                                rect.editMode = true
                                editNameField.text = model["name"]
                                editKeyField.text = model["secret"]
                            }
                        }

                    ]
                    Kirigami.Heading {
                        visible: !rect.editMode
                        id: heading
                        anchors.top: parent.top
                        anchors.topMargin: Kirigami.Units.largeSpacing
                        anchors.left: parent.left
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        text: model["name"]
                    }
                    PlasmaComponents.TextField {
                        visible: !rect.editMode
                        anchors.verticalCenter: heading.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        id: codeField
                        readOnly: true
                        text: totpObj.getTotpForSix(model["secret"])
                        Timer {
                            interval: 500; running: true; repeat: true
                            onTriggered: codeField.text = totpObj.getTotpForSix(model["secret"])
                        }
                    }
                    PlasmaCore.IconItem {
                        visible: codeField.text.toLowerCase().includes("error")
                        source: "emblem-warning"
                        height: codeField.height
                        width: height
                        anchors.right: codeField.left
                        anchors.rightMargin: Kirigami.Units.largeSpacing
                        anchors.verticalCenter: codeField.verticalCenter
                    }
                    Column {
                        width: rect.width
                        id: editColumn
                        visible: rect.editMode
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: 10
                        Kirigami.FormLayout {
                            width: rect.width
                            PlasmaComponents.TextField {
                                id: editNameField
                                Kirigami.FormData.label: "Service Name:"
                            }
                            PlasmaComponents.TextField {
                                id: editKeyField
                                Kirigami.FormData.label: "Service Key:"
                            }
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Kirigami.Units.smallSpacing
                            PlasmaComponents.Button {
                                iconName: "checkbox"
                                text: "Accept"
                                onClicked: {
                                    root.authModel.set(model["index"], {"name":editNameField.text,"secret":editKeyField.text})
                                    rect.editMode = false
                                }
                            }
                            PlasmaComponents.Button {
                                iconName: "dialog-cancel"
                                text: "Cancel"
                                onClicked: {
                                    rect.editMode = false
                                }
                            }
                        }
                    }
                }
            }
            Kirigami.Card {
                id: addCard
                anchors.horizontalCenter: mainColumn.horizontalCenter
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                width: root.width <= 500 ? root.width : 500
                height: 20 + (addForm.height * 1.5) + 20
                visible: false
                Column {
                    topPadding: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    Kirigami.FormLayout {
                        id: addForm
                        width: addCard.width
                        PlasmaComponents.TextField {
                            id: nameField
                            Kirigami.FormData.label: "Service Name:"
                        }
                        PlasmaComponents.TextField {
                            id: keyField
                            Kirigami.FormData.label: "Service Key:"
                        }
                    }
                }
                actions: [
                    Kirigami.Action {
                        text: "Add"
                        onTriggered: {
                            root.authModel.append({"name":nameField.text,"secret":keyField.text})
                            nameField.text = ""
                            keyField.text = ""
                            addCard.visible = false
                        }
                    },
                    Kirigami.Action {
                        text: "Cancel"
                        onTriggered: {
                            addCard.visible = false
                            nameField.text = ""
                            keyField.text = ""
                        }
                    }
                ]
            }

            Kirigami.Card {
                enabled: !addCard.visible
                anchors.horizontalCenter: parent.horizontalCenter
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                width: root.width <= 500 ? root.width : 500
                height: 20 + addColumn.height + 20
                highlighted: mausArea.containsMouse
                Column {
                    anchors.centerIn: parent
                    id: addColumn
                    spacing: 0
                    PlasmaCore.IconItem {
                        anchors.horizontalCenter: addLabel.horizontalCenter
                        source: "list-add"
                    }
                    PlasmaComponents.Label {
                        id: addLabel
                        text: "Add Service"
                    }
                }
                MouseArea {
                    id: mausArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        addCard.visible = true
                    }
                }
            }

            Spacer {
                height: Kirigami.Units.largeSpacing
            }
        }
    }
    Kirigami.OverlaySheet {
        id: copiedSheet
        showCloseButton: false
        property string name: "Null"
        PlasmaComponents.Label {
            width: copiedSheet.width
            wrapMode: Text.WordWrap
            font.pointSize: 12
            text: "The key for " + copiedSheet.name + " has been copied to the clipboard."
        }
        function alertCopied(name) {
            copiedSheet.name = name
            root.showPassiveNotification("The key for " + copiedSheet.name + " has been copied to the clipboard", "short")
        }
    }
    Timer {
        id: copiedTimer
        interval: 1500
        onTriggered: {
            copiedSheet.close()
        }
    }

    Kirigami.OverlaySheet {
        id: deleteSheet
        property string name: "Null"
        property int index: 0

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Heading {
                font.pointSize: 12
                text: "Confirm removal of " + deleteSheet.name
            }
            Label {
                text: "Once deleted, you cannot restore a service."
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                PlasmaComponents.Button {
                    iconName: "checkmark"
                    text: "Accept"
                    onClicked: {
                        root.authModel.remove(deleteSheet.index)
                        deleteSheet.close()
                    }
                }
                PlasmaComponents.Button {
                    iconName: "dialog-cancel"
                    text: "Cancel"
                    onClicked: {
                        deleteSheet.close()
                    }
                }
            }
        }

        function requestDelete(index, name) {
            deleteSheet.index = index
            deleteSheet.name = name
            deleteSheet.open()
        }
    }

    Rectangle {
        id: timerBar
        property int time: totpObj.getTotpTime()
        x: 0
        y: 0
        color: Kirigami.Theme.highlightColor
        width: parent.width * (time / 30)
        height: 5
        Behavior on width {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutBounce
            }
        }

        Timer {
            interval: 250; running: true; repeat: true
            onTriggered: timerBar.time = totpObj.getTotpTime()
        }
    }
}
