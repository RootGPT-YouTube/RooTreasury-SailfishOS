import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property int selectedMonth: (new Date()).getMonth()
    property int selectedYear: (new Date()).getFullYear()
    property date selectedDate: new Date(selectedYear, selectedMonth, (new Date()).getDate(), 12, 0, 0, 0)
    property int selectedCategoryIndex: -1
    property real parsedAmount: Number(amountField.text.replace(",", "."))
    function formattedSelectedDate() {
        return Qt.formatDate(selectedDate, "dd/MM/yyyy")
    }
    function selectedCategoryName() {
        if (selectedCategoryIndex >= 0 && selectedCategoryIndex < appWindow.categories.length) {
            return appWindow.categories[selectedCategoryIndex]
        }
        return qsTr("Uscita")
    }

    function syncSelectedCategory(preferredCategory) {
        if (appWindow.categories.length === 0) {
            selectedCategoryIndex = -1
            return
        }

        var normalizedPreferred = preferredCategory ? String(preferredCategory).toLowerCase() : ""
        var resolvedIndex = 0
        for (var i = 0; i < appWindow.categories.length; i++) {
            if (String(appWindow.categories[i]).toLowerCase() === normalizedPreferred) {
                resolvedIndex = i
                break
            }
        }
        selectedCategoryIndex = resolvedIndex
    }

    function canSave() {
        return !isNaN(parsedAmount) && parsedAmount > 0
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: formColumn.height + header.height + Theme.paddingLarge

        PageHeader {
            id: header
            title: qsTr("Uscite")
        }

        Column {
            id: formColumn
            width: parent.width - 2 * Theme.paddingLarge
            anchors {
                top: header.bottom
                horizontalCenter: parent.horizontalCenter
                topMargin: Theme.paddingLarge
            }
            spacing: Theme.paddingLarge

            TextField {
                id: amountField
                width: parent.width
                label: qsTr("Uscita")
                placeholderText: qsTr("Inserisci uscita")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
            }

            ComboBox {
                id: categoryCombo
                width: parent.width
                label: qsTr("Categoria")
                currentIndex: appWindow.categories.length > 0 ? Math.max(0, selectedCategoryIndex) : 0
                menu: ContextMenu {
                    Repeater {
                        model: appWindow.categories.length > 0 ? appWindow.categories : [qsTr("Nessuna categoria")]
                        MenuItem {
                            text: modelData
                            enabled: appWindow.categories.length > 0
                        }
                    }
                }
                onCurrentIndexChanged: {
                    if (appWindow.categories.length > 0) {
                        selectedCategoryIndex = currentIndex
                    }
                }
            }

            TextArea {
                id: notesField
                width: parent.width
                label: qsTr("Note")
                placeholderText: qsTr("Appunti opzionali")
            }

            Row {
                width: parent.width
                spacing: Theme.paddingMedium

                Button {
                    width: (parent.width - Theme.paddingMedium) / 2
                    text: qsTr("Data") + ": " + page.formattedSelectedDate()
                    onClicked: {
                        var dialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                            date: page.selectedDate
                        })
                        dialog.accepted.connect(function() {
                            page.selectedDate = new Date(dialog.date.getFullYear(), dialog.date.getMonth(), dialog.date.getDate(), 12, 0, 0, 0)
                        })
                    }
                }

                Button {
                    width: (parent.width - Theme.paddingMedium) / 2
                    text: qsTr("Salva")
                    enabled: page.canSave()
                    onClicked: {
                        appWindow.addTransaction("expense", page.parsedAmount, page.selectedCategoryName(), notesField.text, page.selectedDate.getFullYear(), page.selectedDate.getMonth(), page.selectedDate.getDate())
                        pageStack.pop()
                    }
                }
            }
        }
    }

    Connections {
        target: appWindow
        onCategoriesChanged: page.syncSelectedCategory(page.selectedCategoryName())
    }

    Component.onCompleted: {
        page.syncSelectedCategory(qsTr("Uscita"))
    }
}
