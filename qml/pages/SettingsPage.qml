import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import Sailfish.Share 1.0

Page {
    id: page
    property string restoreStatusText: ""
    property bool restoreStatusIsError: false

    function setRestoreStatus(message, isError) {
        restoreStatusText = message
        restoreStatusIsError = isError
    }

    function createBackupAndShare() {
        var backupPayload = {
            appName: appWindow.appName,
            appVersion: appWindow.appVersion,
            createdAt: (new Date()).toISOString(),
            categories: appWindow.categories ? appWindow.categories : [],
            transactions: appWindow.transactions ? appWindow.transactions : []
        }
        var backupPath = backupHelper.createBackupFile(JSON.stringify(backupPayload, null, 2))
        if (backupPath === "") {
            setRestoreStatus(qsTr("Impossibile creare il file di backup"), true)
            return
        }
        backupShareAction.resources = [backupPath]
        backupShareAction.trigger()
        setRestoreStatus(qsTr("Backup creato con successo"), false)
    }

    function chooseBackupToRestore() {
        var picker = pageStack.push("Sailfish.Pickers.FilePickerPage", {
            allowedOrientations: page.allowedOrientations
        })
        picker.selectedContentPropertiesChanged.connect(function() {
            if (!picker.selectedContentProperties || !picker.selectedContentProperties.filePath) {
                return
            }
            page.restoreBackupFromPath(picker.selectedContentProperties.filePath)
        })
    }

    function restoreBackupFromPath(filePath) {
        var backupContent = backupHelper.readBackupFile(filePath)
        if (backupContent === "") {
            setRestoreStatus(qsTr("Impossibile leggere il file di backup"), true)
            return
        }

        var parsedPayload = null
        try {
            parsedPayload = JSON.parse(backupContent)
        } catch (error) {
            setRestoreStatus(qsTr("Backup non valido"), true)
            return
        }

        var restoreResult = appWindow.restoreFromBackupPayload(parsedPayload)
        if (!restoreResult || !restoreResult.success) {
            if (restoreResult && restoreResult.errorCode === "empty_backup") {
                setRestoreStatus(qsTr("Il backup non contiene dati importabili"), true)
                return
            }
            setRestoreStatus(qsTr("Backup non valido"), true)
            return
        }

        if (restoreResult.addedTransactions === 0 && restoreResult.addedCategories === 0) {
            setRestoreStatus(qsTr("Nessun nuovo dato da importare"), false)
            return
        }

        setRestoreStatus(
                    qsTr("Ripristino completato: %1 movimenti, %2 categorie aggiunti")
                    .arg(restoreResult.addedTransactions)
                    .arg(restoreResult.addedCategories),
                    false
                    )
    }

    ShareAction {
        id: backupShareAction
        mimeType: "application/json"
        resources: []
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + header.height + Theme.paddingLarge

        PageHeader {
            id: header
            title: qsTr("Opzioni")
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

            ListItem {
                width: parent.width
                contentHeight: categoryLabel.height + 2 * Theme.paddingMedium
                onClicked: pageStack.push(Qt.resolvedUrl("CategoriesPage.qml"))

                Label {
                    id: categoryLabel
                    anchors {
                        left: parent.left
                        leftMargin: Theme.paddingMedium
                        right: parent.right
                        rightMargin: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("Categorie")
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeLarge
                    truncationMode: TruncationMode.Fade
                }
            }

            ListItem {
                width: parent.width
                contentHeight: currencyLabel.height + 2 * Theme.paddingMedium
                onClicked: pageStack.push(Qt.resolvedUrl("CurrencyPage.qml"))

                Label {
                    id: currencyLabel
                    anchors {
                        left: parent.left
                        leftMargin: Theme.paddingMedium
                        right: parent.right
                        rightMargin: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("Valuta")
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeLarge
                    truncationMode: TruncationMode.Fade
                }
            }

            ListItem {
                width: parent.width
                contentHeight: backupLabel.height + 2 * Theme.paddingMedium
                onClicked: page.createBackupAndShare()

                Label {
                    id: backupLabel
                    anchors {
                        left: parent.left
                        leftMargin: Theme.paddingMedium
                        right: parent.right
                        rightMargin: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("Backup")
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeLarge
                    truncationMode: TruncationMode.Fade
                }
            }

            ListItem {
                width: parent.width
                contentHeight: restoreBackupLabel.height + 2 * Theme.paddingMedium
                onClicked: page.chooseBackupToRestore()

                Label {
                    id: restoreBackupLabel
                    anchors {
                        left: parent.left
                        leftMargin: Theme.paddingMedium
                        right: parent.right
                        rightMargin: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("Ripristina backup")
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeLarge
                    truncationMode: TruncationMode.Fade
                }
            }

            ListItem {
                width: parent.width
                contentHeight: annualTrendLabel.height + 2 * Theme.paddingMedium
                onClicked: pageStack.push(Qt.resolvedUrl("AnnualTrendPage.qml"))

                Label {
                    id: annualTrendLabel
                    anchors {
                        left: parent.left
                        leftMargin: Theme.paddingMedium
                        right: parent.right
                        rightMargin: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("Andamento Annuo")
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeLarge
                    truncationMode: TruncationMode.Fade
                }
            }

            ListItem {
                width: parent.width
                contentHeight: aboutLabel.height + 2 * Theme.paddingMedium
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))

                Label {
                    id: aboutLabel
                    anchors {
                        left: parent.left
                        leftMargin: Theme.paddingMedium
                        right: parent.right
                        rightMargin: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("About <b>RooTreasury</b>")
                    textFormat: Text.RichText
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeLarge
                    truncationMode: TruncationMode.Fade
                }
            }

            Label {
                width: parent.width
                visible: page.restoreStatusText !== ""
                text: page.restoreStatusText
                color: page.restoreStatusIsError ? Theme.errorColor : Theme.highlightColor
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}
