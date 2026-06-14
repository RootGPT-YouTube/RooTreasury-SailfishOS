import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    property int editingIndex: -1
    property string editingOriginalName: ""

    function resetEditor() {
        editingIndex = -1
        editingOriginalName = ""
        categoryField.text = ""
    }

    function normalizedInput() {
        return categoryField.text.replace(/\s+/g, " ").trim()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + header.height + Theme.paddingLarge

        PageHeader {
            id: header
            title: qsTr("Categorie")
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

            TextField {
                id: categoryField
                width: parent.width
                label: qsTr("Categoria")
                placeholderText: qsTr("Nuova categoria")
            }

            Row {
                width: parent.width
                spacing: Theme.paddingMedium

                Button {
                    width: editingIndex >= 0 ? (parent.width - Theme.paddingMedium) / 2 : parent.width
                    text: editingIndex >= 0 ? qsTr("Salva modifica") : qsTr("Aggiungi")
                    enabled: page.normalizedInput() !== ""
                    onClicked: {
                        var input = page.normalizedInput()
                        var ok = false

                        if (editingIndex >= 0) {
                            ok = appWindow.renameCategory(editingOriginalName, input)
                        } else {
                            ok = appWindow.addCategory(input)
                        }

                        if (ok) {
                            page.resetEditor()
                        }
                    }
                }

                Button {
                    visible: editingIndex >= 0
                    width: (parent.width - Theme.paddingMedium) / 2
                    text: qsTr("Annulla")
                    onClicked: page.resetEditor()
                }
            }

            Label {
                width: parent.width
                text: qsTr("Categorie (ordine alfabetico)")
                color: Theme.secondaryColor
                font.bold: true
                wrapMode: Text.Wrap
            }

            Label {
                width: parent.width
                text: qsTr("Nessuna categoria disponibile")
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                visible: appWindow.categories.length === 0
            }

            Repeater {
                model: appWindow.categories
                delegate: ListItem {
                    id: categoryItem
                    width: contentColumn.width
                    contentHeight: categoryLabel.height + 2 * Theme.paddingMedium
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("Modifica")
                            onClicked: {
                                page.editingIndex = index
                                page.editingOriginalName = modelData
                                categoryField.text = modelData
                                categoryField.forceActiveFocus()
                            }
                        }

                        MenuItem {
                            text: qsTr("Elimina")
                            onClicked: {
                                categoryItem.remorseAction(qsTr("Eliminazione"), function() {
                                    if (appWindow.removeCategory(modelData)
                                            && page.editingOriginalName.toLowerCase() === String(modelData).toLowerCase()) {
                                        page.resetEditor()
                                    }
                                })
                            }
                        }
                    }

                    Label {
                        id: categoryLabel
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: Theme.paddingMedium
                            rightMargin: Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                        text: modelData
                        color: Theme.primaryColor
                        truncationMode: TruncationMode.Fade
                    }
                }
            }
        }
    }
}
