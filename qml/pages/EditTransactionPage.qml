import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property int transactionIndex: -1
    property string transactionType: "expense"
    property real initialAmount: 0
    property string initialCategory: ""
    property string initialNotes: ""
    property string initialDate: ""
    property date selectedDate: new Date()
    property int selectedCategoryIndex: -1
    property real parsedAmount: Number(amountField.text.replace(",", "."))
    function formattedSelectedDate() {
        return Qt.formatDate(selectedDate, "dd/MM/yyyy")
    }
    function selectedCategoryName() {
        if (selectedCategoryIndex >= 0 && selectedCategoryIndex < appWindow.categories.length) {
            return appWindow.categories[selectedCategoryIndex]
        }
        return transactionType === "income" ? qsTr("Entrata") : qsTr("Uscita")
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
        return transactionIndex >= 0 && !isNaN(parsedAmount) && parsedAmount > 0
    }

    function amountLabel() {
        return transactionType === "income" ? qsTr("Entrata") : qsTr("Uscita")
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: formColumn.height + header.height + Theme.paddingLarge

        PageHeader {
            id: header
            title: transactionType === "income" ? qsTr("Modifica entrata") : qsTr("Modifica uscita")
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
                label: page.amountLabel()
                placeholderText: qsTr("Inserisci importo")
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
                        if (appWindow.updateTransaction(page.transactionIndex, page.parsedAmount, page.selectedCategoryName(), notesField.text, page.selectedDate.getFullYear(), page.selectedDate.getMonth(), page.selectedDate.getDate())) {
                            pageStack.pop()
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (initialAmount > 0) {
            amountField.text = Number(initialAmount).toFixed(2)
        }
        notesField.text = initialNotes
        var parsedInitialDate = initialDate !== "" ? new Date(initialDate) : new Date()
        if (isNaN(parsedInitialDate.getTime())) {
            parsedInitialDate = new Date()
        }
        selectedDate = new Date(parsedInitialDate.getFullYear(), parsedInitialDate.getMonth(), parsedInitialDate.getDate(), 12, 0, 0, 0)
        page.syncSelectedCategory(initialCategory)
    }

    Connections {
        target: appWindow
        onCategoriesChanged: page.syncSelectedCategory(page.selectedCategoryName())
    }
}
