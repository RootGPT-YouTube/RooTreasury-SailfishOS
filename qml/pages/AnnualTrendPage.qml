import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property int selectedYear: (new Date()).getFullYear()
    property real annualBalance: 0
    property real maxAbsMonthlyBalance: 1
    property real yearNavButtonWidth: Theme.itemSizeSmall

    function formatAmount(value) {
        return Number(value).toFixed(2) + " " + appWindow.currency
    }

    function monthName(index) {
        return Qt.formatDate(new Date(selectedYear, index, 1), "MMMM")
    }

    function monthShortName(index) {
        return Qt.formatDate(new Date(selectedYear, index, 1), "MMM")
    }

    function balanceColor(value) {
        if (value < 0) {
            return "#d32f2f"
        }
        if (value === 0) {
            return Theme.secondaryColor
        }
        return "#2e7d32"
    }

    function previousYear() {
        selectedYear -= 1
    }

    function nextYear() {
        selectedYear += 1
    }

    function refreshData() {
        monthlyBalanceModel.clear()
        annualBalance = 0
        var nextMaxAbs = 0
        var hasMovement = false

        for (var monthIndex = 0; monthIndex < 12; monthIndex++) {
            var monthBalance = 0

            for (var i = 0; i < appWindow.transactions.length; i++) {
                var tx = appWindow.transactions[i]
                if (!tx) {
                    continue
                }

                var txDate = new Date(tx.date)
                if (isNaN(txDate.getTime())) {
                    continue
                }
                if (txDate.getFullYear() !== selectedYear || txDate.getMonth() !== monthIndex) {
                    continue
                }

                var amount = Number(tx.amount)
                if (!isFinite(amount)) {
                    continue
                }
                monthBalance += tx.type === "income" ? amount : -amount
            }

            if (monthBalance !== 0) {
                hasMovement = true
            }

            var absBalance = Math.abs(monthBalance)
            if (absBalance > nextMaxAbs) {
                nextMaxAbs = absBalance
            }

            annualBalance += monthBalance
            monthlyBalanceModel.append({
                monthIndex: monthIndex,
                monthLabel: monthName(monthIndex),
                monthShortLabel: monthShortName(monthIndex),
                balance: monthBalance
            })
        }

        maxAbsMonthlyBalance = nextMaxAbs > 0 ? nextMaxAbs : 1
        emptyYearLabel.visible = !hasMovement
    }

    onSelectedYearChanged: refreshData()
    Component.onCompleted: refreshData()

    Connections {
        target: appWindow
        onTransactionsChanged: page.refreshData()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + header.height + Theme.paddingLarge

        PageHeader {
            id: header
            title: qsTr("Andamento Annuo")
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

            Row {
                width: parent.width
                height: Theme.itemSizeLarge
                spacing: Theme.paddingMedium

                Button {
                    width: page.yearNavButtonWidth
                    height: Theme.itemSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: "<"
                    onClicked: page.previousYear()
                }

                Item {
                    width: parent.width - 2 * page.yearNavButtonWidth - 2 * Theme.paddingMedium
                    height: parent.height

                    Label {
                        width: parent.width
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.selectedYear
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.primaryColor
                        font.bold: true
                        font.pixelSize: Theme.fontSizeLarge
                    }
                }

                Button {
                    width: page.yearNavButtonWidth
                    height: Theme.itemSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: ">"
                    onClicked: page.nextYear()
                }
            }

            Label {
                width: parent.width
                text: qsTr("Saldo annuo")
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
            }

            Label {
                width: parent.width
                text: page.formatAmount(page.annualBalance)
                horizontalAlignment: Text.AlignHCenter
                color: page.balanceColor(page.annualBalance)
                font.pixelSize: Theme.fontSizeExtraLarge
                font.bold: true
                fontSizeMode: Text.HorizontalFit
            }

            Label {
                width: parent.width
                text: qsTr("Grafico saldi mensili")
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
            }

            Item {
                id: chartArea
                width: parent.width
                height: Theme.itemSizeExtraLarge * 2.4
                property real chartTopMargin: Theme.paddingSmall
                property real chartBottomMargin: Theme.itemSizeSmall
                property real availableHeight: Math.max(20, height - chartTopMargin - chartBottomMargin)
                property real zeroY: chartTopMargin + availableHeight / 2
                property real maxBarHeight: Math.max(2, (availableHeight / 2) - Theme.paddingSmall)

                Rectangle {
                    id: zeroLine
                    x: 0
                    y: chartArea.zeroY
                    width: parent.width
                    height: 1
                    color: Theme.secondaryColor
                    opacity: 0.4
                }

                Row {
                    id: barsRow
                    x: 0
                    y: 0
                    width: parent.width
                    height: parent.height
                    spacing: Theme.paddingSmall / 2

                    Repeater {
                        model: monthlyBalanceModel

                        delegate: Item {
                            width: (barsRow.width - barsRow.spacing * 11) / 12
                            height: barsRow.height

                            property real ratio: Math.min(1, Math.abs(balance) / page.maxAbsMonthlyBalance)
                            property real barHeight: Math.max(1, ratio * chartArea.maxBarHeight)

                            Rectangle {
                                width: Math.max(2, parent.width * 0.62)
                                height: parent.barHeight
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: balance >= 0
                                   ? (chartArea.zeroY - height)
                                   : (chartArea.zeroY + zeroLine.height)
                                color: page.balanceColor(balance)
                                radius: Theme.paddingSmall / 3
                            }

                            Label {
                                width: parent.width
                                anchors {
                                    bottom: parent.bottom
                                    bottomMargin: 0
                                }
                                text: monthShortLabel
                                horizontalAlignment: Text.AlignHCenter
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeTiny
                                truncationMode: TruncationMode.Fade
                            }
                        }
                    }
                }
            }

            Label {
                id: emptyYearLabel
                width: parent.width
                text: qsTr("Nessun movimento nell'anno selezionato")
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                visible: false
            }

            Label {
                width: parent.width
                text: qsTr("Saldi finali mensili")
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
            }

            Repeater {
                model: monthlyBalanceModel

                delegate: Row {
                    width: contentColumn.width
                    spacing: Theme.paddingMedium

                    Label {
                        width: parent.width * 0.55
                        text: monthLabel
                        color: Theme.primaryColor
                        truncationMode: TruncationMode.Fade
                    }

                    Label {
                        width: parent.width - (parent.width * 0.55) - Theme.paddingMedium
                        text: page.formatAmount(balance)
                        horizontalAlignment: Text.AlignRight
                        color: page.balanceColor(balance)
                        font.bold: true
                        truncationMode: TruncationMode.Fade
                    }
                }
            }
        }
    }

    ListModel {
        id: monthlyBalanceModel
    }
}
