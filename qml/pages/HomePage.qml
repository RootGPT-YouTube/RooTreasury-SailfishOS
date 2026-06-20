import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property int selectedMonth: (new Date()).getMonth()
    property int selectedYear: (new Date()).getFullYear()
    property real totalIncome: 0
    property real totalExpense: 0
    property real monthlyBalance: totalIncome - totalExpense
    property real monthNavButtonWidth: Theme.itemSizeSmall
    property int primaryTitlePixelSize: Theme.fontSizeLarge
    property int secondaryTitlePixelSize: Theme.fontSizeMedium
    property var pieSegments: []

    function monthName(index) {
        var months = [
            qsTr("Gennaio"), qsTr("Febbraio"), qsTr("Marzo"), qsTr("Aprile"),
            qsTr("Maggio"), qsTr("Giugno"), qsTr("Luglio"), qsTr("Agosto"),
            qsTr("Settembre"), qsTr("Ottobre"), qsTr("Novembre"), qsTr("Dicembre")
        ]
        return months[index]
    }

    function formatAmount(value) {
        return Number(value).toFixed(2) + " " + appWindow.currency
    }

    // Restituisce un colore distinto per ogni indice di categoria. Per i primi
    // valori usa la palette fissa; oltre, genera tinte sempre nuove (passo ad
    // angolo aureo su tonalità/saturazione/luminosità) così i colori del grafico
    // a torta non si ripetono MAI, qualunque sia il numero di categorie.
    function pieColorForIndex(index) {
        var palette = appWindow.piePalette
        if (index < palette.length) {
            return palette[index]
        }
        var extra = index - palette.length
        var hue = (extra * 0.6180339887 + 0.15) % 1.0
        var sat = 0.55 + 0.25 * (extra % 2)
        var val = 0.9 - 0.2 * (Math.floor(extra / 2) % 2)
        // toString() -> "#rrggbb": una stringa coerente sia per il Canvas della
        // torta sia per il Rectangle della legenda (un oggetto colore nel
        // ListModel andrebbe perso e renderizzato bianco).
        return Qt.hsva(hue, sat, val, 1.0).toString()
    }

    function balanceColor() {
        if (monthlyBalance < 0) {
            return "#d32f2f"
        }
        if (monthlyBalance <= 200) {
            return "#ff9800"
        }
        return "#2e7d32"
    }

    function prevMonth() {
        if (selectedMonth === 0) {
            selectedMonth = 11
            selectedYear -= 1
        } else {
            selectedMonth -= 1
        }
    }

    function nextMonth() {
        if (selectedMonth === 11) {
            selectedMonth = 0
            selectedYear += 1
        } else {
            selectedMonth += 1
        }
    }

    function refreshData() {
        totalIncome = 0
        totalExpense = 0
        movementModel.clear()
        pieLegendModel.clear()

        var filtered = []
        for (var i = 0; i < appWindow.transactions.length; i++) {
            var tx = appWindow.transactions[i]
            var txDate = new Date(tx.date)
            if (txDate.getMonth() === selectedMonth && txDate.getFullYear() === selectedYear) {
                var normalizedAmount = Number(tx.amount)
                filtered.push({
                    movementType: tx.type,
                    amount: normalizedAmount,
                    category: tx.category,
                    notes: tx.notes ? tx.notes : "",
                    date: tx.date,
                    transactionIndex: i
                })
                if (tx.type === "income") {
                    totalIncome += normalizedAmount
                } else {
                    totalExpense += normalizedAmount
                }
            }
        }

        filtered.sort(function(a, b) {
            return (new Date(b.date)).getTime() - (new Date(a.date)).getTime()
        })

        for (var j = 0; j < filtered.length; j++) {
            var movement = filtered[j]
            movementModel.append({
                movementType: movement.movementType,
                amount: Number(movement.amount),
                category: movement.category,
                notes: movement.notes,
                dateText: Qt.formatDate(new Date(movement.date), "dd/MM/yyyy"),
                transactionIndex: movement.transactionIndex
            })
        }

        var categoryTotals = {}
        var categoryColors = {}
        var paletteIndex = 0

        for (var k = 0; k < filtered.length; k++) {
            var expense = filtered[k]
            if (expense.movementType !== "expense") {
                continue
            }
            var expenseCategory = expense.category && expense.category !== "" ? expense.category : qsTr("Uscita")

            if (categoryTotals[expenseCategory] === undefined) {
                categoryTotals[expenseCategory] = 0
                categoryColors[expenseCategory] = page.pieColorForIndex(paletteIndex)
                paletteIndex += 1
            }
            categoryTotals[expenseCategory] += Number(expense.amount)
        }

        var legendEntries = []
        for (var categoryName in categoryTotals) {
            legendEntries.push({
                category: categoryName,
                amount: categoryTotals[categoryName],
                legendColor: categoryColors[categoryName]
            })
        }

        legendEntries.sort(function(a, b) {
            return b.amount - a.amount
        })

        var nextPieSegments = []
        for (var m = 0; m < legendEntries.length; m++) {
            var legendEntry = legendEntries[m]
            var percentage = totalExpense > 0 ? (legendEntry.amount / totalExpense) * 100 : 0

            nextPieSegments.push({
                value: legendEntry.amount,
                color: legendEntry.legendColor
            })
            pieLegendModel.append({
                category: legendEntry.category,
                amount: legendEntry.amount,
                legendColor: legendEntry.legendColor,
                percentage: percentage
            })
        }

        pieSegments = nextPieSegments
        pieCanvas.requestPaint()
    }

    onSelectedMonthChanged: refreshData()
    onSelectedYearChanged: refreshData()
    Component.onCompleted: refreshData()

    Connections {
        target: appWindow
        onTransactionsChanged: page.refreshData()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + header.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: qsTr("Opzioni")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
        }

        PageHeader {
            id: header
            title: appWindow.appName
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
                    width: page.monthNavButtonWidth
                    height: Theme.itemSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: "<"
                    onClicked: page.prevMonth()
                }

                Item {
                    width: parent.width - 2 * page.monthNavButtonWidth - 2 * Theme.paddingMedium
                    height: parent.height

                    Column {
                        width: parent.width
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.paddingSmall / 3

                        Label {
                            width: parent.width
                            text: page.monthName(page.selectedMonth)
                            horizontalAlignment: Text.AlignHCenter
                            font.bold: true
                            font.pixelSize: page.primaryTitlePixelSize
                            color: Theme.primaryColor
                        }

                        Label {
                            width: parent.width
                            text: page.selectedYear
                            horizontalAlignment: Text.AlignHCenter
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: page.secondaryTitlePixelSize
                            font.bold: true
                        }
                    }
                }

                Button {
                    width: page.monthNavButtonWidth
                    height: Theme.itemSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: ">"
                    onClicked: page.nextMonth()
                }
            }

            Label {
                width: parent.width
                text: qsTr("Saldo mensile")
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                font.bold: true
                font.pixelSize: page.primaryTitlePixelSize
            }

            Label {
                width: parent.width
                text: page.formatAmount(page.monthlyBalance)
                horizontalAlignment: Text.AlignHCenter
                color: page.balanceColor()
                font.pixelSize: Theme.fontSizeExtraLarge * 2
                font.bold: true
                fontSizeMode: Text.HorizontalFit
            }

            Row {
                width: parent.width
                spacing: Theme.paddingMedium

                Button {
                    width: (parent.width - Theme.paddingMedium) / 2
                    text: qsTr("Entrate")
                    onClicked: pageStack.push(Qt.resolvedUrl("IncomePage.qml"), {
                        selectedMonth: page.selectedMonth,
                        selectedYear: page.selectedYear
                    })
                }

                Button {
                    width: (parent.width - Theme.paddingMedium) / 2
                    text: qsTr("Uscite")
                    onClicked: pageStack.push(Qt.resolvedUrl("ExpensePage.qml"), {
                        selectedMonth: page.selectedMonth,
                        selectedYear: page.selectedYear
                    })
                }
            }

            Label {
                width: parent.width
                text: qsTr("Grafico delle Uscite")
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                font.bold: true
                font.pixelSize: page.primaryTitlePixelSize
            }

            Canvas {
                id: pieCanvas
                width: parent.width
                height: Theme.itemSizeExtraLarge * 2

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()


                    var cx = width / 2
                    var cy = height / 2
                    var radius = Math.min(width, height) / 2 - Theme.paddingSmall
                    var hasSegments = page.pieSegments && page.pieSegments.length > 0
                    var total = 0
                    if (hasSegments) {
                        for (var i = 0; i < page.pieSegments.length; i++) {
                            total += page.pieSegments[i].value
                        }
                    }

                    if (!hasSegments || total <= 0) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, radius, 0, Math.PI * 2, false)
                        ctx.closePath()
                        ctx.fillStyle = "#455a64"
                        ctx.fill()

                        ctx.fillStyle = "#ffffff"
                        ctx.font = Math.round(Theme.fontSizeLarge * 1.2) + "px sans-serif"
                        ctx.textAlign = "center"
                        ctx.textBaseline = "middle"
                        ctx.fillText("0%", cx, cy)
                        return
                    }
                    var angle = -Math.PI / 2

                    for (var j = 0; j < page.pieSegments.length; j++) {
                        var seg = page.pieSegments[j]
                        var part = (seg.value / total) * (Math.PI * 2)

                        ctx.beginPath()
                        ctx.moveTo(cx, cy)
                        ctx.arc(cx, cy, radius, angle, angle + part, false)
                        ctx.closePath()
                        ctx.fillStyle = seg.color
                        ctx.fill()

                        angle += part
                    }
                }
            }

            Label {
                width: parent.width
                text: qsTr("Nessuna uscita nel mese selezionato")
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                visible: pieLegendModel.count === 0
            }

            Repeater {
                model: pieLegendModel
                delegate: Row {
                    width: contentColumn.width
                    spacing: Theme.paddingSmall

                    Rectangle {
                        id: legendDot
                        width: Theme.iconSizeSmall / 2
                        height: Theme.iconSizeSmall / 2
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: legendColor
                    }

                    Label {
                        width: parent.width - legendDot.width - legendPercent.implicitWidth - 2 * Theme.paddingSmall
                        text: "%1: %2 %3"
                                .arg(category)
                                .arg(Number(amount).toFixed(2))
                                .arg(appWindow.currency)
                        truncationMode: TruncationMode.Elide
                        elide: Text.ElideRight
                        color: Theme.secondaryColor
                    }

                    Label {
                        id: legendPercent
                        text: " - " + Number(percentage).toFixed(1) + "%"
                        color: Theme.secondaryColor
                        font.bold: true
                    }
                }
            }

            SectionHeader {
                text: qsTr("Entrate e Uscite")
                horizontalAlignment: Text.AlignRight
                font.bold: true
                font.pixelSize: page.primaryTitlePixelSize
            }

            Label {
                width: parent.width
                text: qsTr("Nessun movimento nel mese selezionato")
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                visible: movementModel.count === 0
            }

            Repeater {
                model: movementModel
                delegate: ListItem {
                    id: movementItem
                    width: contentColumn.width
                    visible: movementModel.count > 0
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("Modifica")
                            onClicked: {
                                if (transactionIndex >= 0) {
                                    var currentTransaction = appWindow.transactions[transactionIndex]
                                    pageStack.push(Qt.resolvedUrl("EditTransactionPage.qml"), {
                                        transactionIndex: transactionIndex,
                                        transactionType: movementType,
                                        initialAmount: Number(amount),
                                        initialCategory: category,
                                        initialNotes: notes,
                                        initialDate: currentTransaction && currentTransaction.date ? currentTransaction.date : ""
                                    })
                                }
                            }
                        }

                        MenuItem {
                            text: qsTr("Elimina")
                            onClicked: {
                                if (transactionIndex >= 0) {
                                    movementItem.remorseAction(qsTr("Eliminazione"), function() {
                                        appWindow.removeTransaction(transactionIndex)
                                    })
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.paddingSmall / 2
                        Label {
                            width: parent.width
                            font.bold: movementType === "income"
                            color: movementType === "income" ? Theme.highlightColor : Theme.primaryColor
                            text: "%1 %2 %3 (%4)"
                                    .arg(movementType === "income" ? "+" : "-")
                                    .arg(Number(amount).toFixed(2))
                                    .arg(appWindow.currency)
                                    .arg(category)
                        }

                        Label {
                            width: parent.width
                            text: notes === "" ? dateText : "%1 • %2".arg(dateText).arg(notes)
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.Wrap
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.secondaryColor
                            opacity: 0.2
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: movementModel
    }

    ListModel {
        id: pieLegendModel
    }
}
