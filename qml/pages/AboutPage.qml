import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: aboutPage

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: aboutPage.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("About RooTreasury")
            }

            Rectangle {
                id: avatarClip
                width: Math.min(2 * Theme.itemSizeHuge, Math.min(aboutPage.width, aboutPage.height) / 2)
                height: width
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"
                clip: true

                Image {
                    width: parent.width
                    height: parent.height
                    source: Qt.resolvedUrl("../images/rootgpt-avatar.png")
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: "<b>" + appWindow.appName + "</b>"
                textFormat: Text.RichText
                font.pixelSize: Theme.fontSizeExtraLarge
                color: Theme.primaryColor
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Versione: %1").arg(appWindow.appVersion)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Creato da RootGPT affiancato da Claude Opus.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
                wrapMode: Text.Wrap
            }
        }
    }
}
