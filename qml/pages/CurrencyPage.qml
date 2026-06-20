import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    function normalizedInput() {
        return currencyField.text.replace(/\s+/g, " ").trim()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + header.height + Theme.paddingLarge

        PageHeader {
            id: header
            title: qsTr("Valuta")
        }

        Column {
            id: contentColumn
            width: parent.width - 2 * Theme.paddingLarge
            anchors {
                top: header.bottom
                horizontalCenter: parent.horizontalCenter
                topMargin: Theme.paddingLarge
            }
            spacing: Theme.paddingLarge

            Label {
                width: parent.width
                text: qsTr("Inserisci il simbolo della valuta (€, $, £, ...) oppure il codice di 3 lettere (EUR, USD, BTC, ...).")
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
            }

            TextField {
                id: currencyField
                width: parent.width
                label: qsTr("Valuta")
                placeholderText: qsTr("Valuta")
                text: appWindow.currency
                inputMethodHints: Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: page.saveAndReturn()
            }

            Label {
                width: parent.width
                text: qsTr("Valuta attuale: %1").arg(appWindow.currency)
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }

            Button {
                width: parent.width
                text: qsTr("Salva")
                enabled: page.normalizedInput() !== ""
                onClicked: page.saveAndReturn()
            }
        }
    }

    function saveAndReturn() {
        var input = page.normalizedInput()
        if (input === "") {
            return
        }
        if (appWindow.setCurrency(input)) {
            pageStack.pop()
        }
    }
}
