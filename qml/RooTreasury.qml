import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import "pages"

ApplicationWindow {
    id: appWindow
    allowedOrientations: Orientation.Portrait
    initialPage: Component { HomePage { } }
    cover: Component {
        CoverBackground {
            Column {
                anchors.centerIn: parent
                width: parent.width - 2 * Theme.paddingMedium
                spacing: Theme.paddingSmall

                Label {
                    width: parent.width
                    text: appWindow.appName
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.highlightColor
                    font.bold: true
                    font.pixelSize: Theme.fontSizeLarge
                    truncationMode: TruncationMode.Fade
                }

                Label {
                    width: parent.width
                    text: qsTr("Saldo mensile")
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.secondaryColor
                    font.bold: true
                    font.pixelSize: Theme.fontSizeSmall
                }

                Label {
                    width: parent.width
                    text: appWindow.coverMonthlyBalanceText()
                    horizontalAlignment: Text.AlignHCenter
                    color: appWindow.coverMonthlyBalanceColor()
                    font.bold: true
                    font.pixelSize: Theme.fontSizeLarge
                    truncationMode: TruncationMode.Fade
                }
            }
        }
    }

    property string appName: "RooTreasury"
    property string appVersion: "1.6"
    property string appAuthor: "RootGPT"
    property string currency: "€"
    property var transactions: []
    property var categories: []
    property bool transactionsLoaded: false
    property var piePalette: [
        "#ef5350", "#ab47bc", "#5c6bc0", "#29b6f6",
        "#66bb6a", "#ffa726", "#8d6e63", "#26a69a"
    ]

    function coverMonthlyBalanceValue() {
        var now = new Date()
        var month = now.getMonth()
        var year = now.getFullYear()
        var balance = 0

        for (var i = 0; i < transactions.length; i++) {
            var tx = transactions[i]
            if (!tx) {
                continue
            }

            var txDate = new Date(tx.date)
            if (isNaN(txDate.getTime())) {
                continue
            }
            if (txDate.getMonth() !== month || txDate.getFullYear() !== year) {
                continue
            }

            var amount = Number(tx.amount)
            if (!isFinite(amount)) {
                continue
            }
            balance += tx.type === "income" ? amount : -amount
        }

        return balance
    }

    function coverMonthlyBalanceText() {
        return Number(coverMonthlyBalanceValue()).toFixed(2) + " " + currency
    }

    function coverMonthlyBalanceColor() {
        var value = coverMonthlyBalanceValue()
        if (value < 0) {
            return "#d32f2f"
        }
        if (value <= 200) {
            return "#ff9800"
        }
        return "#2e7d32"
    }
    ConfigurationValue {
        id: transactionsConfig
        key: "/apps/RooTreasury/transactionsJson"
    }
    ConfigurationValue {
        id: categoriesConfig
        key: "/apps/RooTreasury/categoriesJson"
    }
    ConfigurationValue {
        id: currencyConfig
        key: "/apps/RooTreasury/currency"
    }

    function loadCurrency() {
        var raw = currencyConfig.value === undefined || currencyConfig.value === null
                ? ""
                : String(currencyConfig.value).trim()
        if (raw !== "") {
            currency = raw
        }
    }

    function setCurrency(value) {
        var normalized = value === undefined || value === null ? "" : String(value).trim()
        if (normalized === "") {
            return false
        }
        currency = normalized
        try {
            currencyConfig.value = normalized
        } catch (error) {
            console.log("Unable to save currency:", error)
        }
        return true
    }

    function normalizeCategoryName(name) {
        if (name === undefined || name === null) {
            return ""
        }
        return String(name).replace(/\s+/g, " ").trim()
    }

    function categoryCompare(a, b) {
        var aa = String(a).toLowerCase()
        var bb = String(b).toLowerCase()
        if (aa < bb) {
            return -1
        }
        if (aa > bb) {
            return 1
        }
        return String(a).localeCompare(String(b))
    }

    function sortAndUniqueCategories(values) {
        var normalized = []
        for (var i = 0; i < values.length; i++) {
            var candidate = normalizeCategoryName(values[i])
            if (candidate === "") {
                continue
            }

            var exists = false
            for (var j = 0; j < normalized.length; j++) {
                if (normalized[j].toLowerCase() === candidate.toLowerCase()) {
                    exists = true
                    break
                }
            }
            if (!exists) {
                normalized.push(candidate)
            }
        }

        normalized.sort(categoryCompare)
        return normalized
    }

    function defaultCategoryForType(transactionType) {
        return transactionType === "income" ? qsTr("Entrata") : qsTr("Uscita")
    }

    function categoriesFromTransactions() {
        var extracted = []
        for (var i = 0; i < transactions.length; i++) {
            var tx = transactions[i]
            if (!tx) {
                continue
            }

            var category = normalizeCategoryName(tx.category)
            if (category !== "") {
                extracted.push(category)
            }
        }
        return sortAndUniqueCategories(extracted)
    }

    function categoryIndexByName(categoryName) {
        var normalized = normalizeCategoryName(categoryName)
        if (normalized === "") {
            return -1
        }

        for (var i = 0; i < categories.length; i++) {
            if (String(categories[i]).toLowerCase() === normalized.toLowerCase()) {
                return i
            }
        }
        return -1
    }

    function ensureFallbackCategories() {
        if (categories.length > 0) {
            return categories
        }
        return sortAndUniqueCategories([qsTr("Entrata"), qsTr("Uscita")])
    }

    function normalizedTransaction(rawTransaction, index) {
        if (!rawTransaction) {
            return null
        }

        var amount = Math.abs(Number(rawTransaction.amount))
        if (!isFinite(amount) || amount <= 0) {
            return null
        }

        var type = rawTransaction.type === "income" ? "income" : "expense"
        var category = rawTransaction.category ? String(rawTransaction.category).trim() : ""
        if (category === "") {
            category = type === "income" ? qsTr("Entrata") : qsTr("Uscita")
        }

        var notes = rawTransaction.notes ? String(rawTransaction.notes).trim() : ""
        var rawDate = rawTransaction.date ? String(rawTransaction.date) : ""
        var parsedDate = rawDate === "" ? new Date() : new Date(rawDate)
        if (isNaN(parsedDate.getTime())) {
            parsedDate = new Date()
        }

        var color = rawTransaction.color ? String(rawTransaction.color) : ""
        if (color === "") {
            color = piePalette[index % piePalette.length]
        }

        return {
            type: type,
            amount: amount,
            category: category,
            notes: notes,
            date: parsedDate.toISOString(),
            color: color
        }
    }

    function transactionDedupKey(transaction) {
        var normalized = normalizedTransaction(transaction, 0)
        if (!normalized) {
            return ""
        }

        var amount = Number(normalized.amount)
        if (!isFinite(amount)) {
            return ""
        }

        var category = normalizeCategoryName(normalized.category).toLowerCase()
        var notes = normalized.notes ? String(normalized.notes).trim() : ""
        var date = normalized.date ? String(normalized.date) : ""
        return normalized.type + "|" + amount.toFixed(6) + "|" + category + "|" + notes + "|" + date
    }

    function hasCategoryInList(categoryList, categoryName) {
        var normalized = normalizeCategoryName(categoryName)
        if (normalized === "") {
            return false
        }

        for (var i = 0; i < categoryList.length; i++) {
            if (String(categoryList[i]).toLowerCase() === normalized.toLowerCase()) {
                return true
            }
        }
        return false
    }

    function listEquals(left, right) {
        if (!left || !right || left.length !== right.length) {
            return false
        }

        for (var i = 0; i < left.length; i++) {
            if (String(left[i]) !== String(right[i])) {
                return false
            }
        }
        return true
    }

    function restoreFromBackupPayload(payload) {
        if (!payload || typeof payload !== "object") {
            return { success: false, errorCode: "invalid_backup" }
        }

        var importedCategories = payload.categories && payload.categories.length !== undefined
                ? payload.categories
                : []
        var importedTransactions = payload.transactions && payload.transactions.length !== undefined
                ? payload.transactions
                : []

        if (importedCategories.length === 0 && importedTransactions.length === 0) {
            return { success: false, errorCode: "empty_backup" }
        }

        var mergedCategories = sortAndUniqueCategories(categories.concat(importedCategories))
        var mergedTransactions = transactions.slice(0)
        var existingTransactionKeys = {}

        for (var i = 0; i < transactions.length; i++) {
            var existingKey = transactionDedupKey(transactions[i])
            if (existingKey !== "") {
                existingTransactionKeys[existingKey] = true
            }
        }

        var addedTransactions = 0
        for (var j = 0; j < importedTransactions.length; j++) {
            var normalizedImported = normalizedTransaction(importedTransactions[j], mergedTransactions.length + j)
            if (!normalizedImported) {
                continue
            }

            if (!hasCategoryInList(mergedCategories, normalizedImported.category)) {
                mergedCategories = sortAndUniqueCategories(mergedCategories.concat([normalizedImported.category]))
            }

            var importedKey = transactionDedupKey(normalizedImported)
            if (importedKey === "" || existingTransactionKeys[importedKey]) {
                continue
            }

            existingTransactionKeys[importedKey] = true
            if (!normalizedImported.color || String(normalizedImported.color).trim() === "") {
                normalizedImported.color = piePalette[mergedTransactions.length % piePalette.length]
            }
            mergedTransactions.push(normalizedImported)
            addedTransactions += 1
        }

        var categoriesFromMergedTransactions = []
        for (var k = 0; k < mergedTransactions.length; k++) {
            var mergedTx = mergedTransactions[k]
            if (mergedTx && mergedTx.category) {
                categoriesFromMergedTransactions.push(mergedTx.category)
            }
        }
        mergedCategories = sortAndUniqueCategories(mergedCategories.concat(categoriesFromMergedTransactions))
        if (mergedCategories.length === 0) {
            mergedCategories = ensureFallbackCategories()
        }

        var addedCategories = 0
        for (var m = 0; m < mergedCategories.length; m++) {
            if (!hasCategoryInList(categories, mergedCategories[m])) {
                addedCategories += 1
            }
        }

        var categoriesChanged = !listEquals(categories, mergedCategories)
        if (categoriesChanged) {
            categories = mergedCategories
        }
        if (addedTransactions > 0) {
            transactions = mergedTransactions
        }

        return {
            success: true,
            addedTransactions: addedTransactions,
            addedCategories: addedCategories
        }
    }

    function loadTransactions() {
        var restoredTransactions = []
        var rawTransactions = transactionsConfig.value === undefined || transactionsConfig.value === null
                ? "[]"
                : String(transactionsConfig.value)

        if (rawTransactions !== "") {
            try {
                var parsed = JSON.parse(rawTransactions)
                if (parsed && parsed.length !== undefined) {
                    for (var i = 0; i < parsed.length; i++) {
                        var normalized = normalizedTransaction(parsed[i], i)
                        if (normalized) {
                            restoredTransactions.push(normalized)
                        }
                    }
                }
            } catch (error) {
                console.log("Unable to load saved transactions:", error)
            }
        }

        transactions = restoredTransactions
    }

    function loadCategories() {
        var restoredCategories = []
        var rawCategories = categoriesConfig.value === undefined || categoriesConfig.value === null
                ? "[]"
                : String(categoriesConfig.value)

        if (rawCategories !== "") {
            try {
                var parsed = JSON.parse(rawCategories)
                if (parsed && parsed.length !== undefined) {
                    restoredCategories = sortAndUniqueCategories(parsed)
                }
            } catch (error) {
                console.log("Unable to load saved categories:", error)
            }
        }

        if (restoredCategories.length === 0) {
            restoredCategories = categoriesFromTransactions()
        }
        categories = restoredCategories.length > 0 ? restoredCategories : ensureFallbackCategories()
    }

    function saveTransactions() {
        if (!transactionsLoaded) {
            return
        }

        try {
            transactionsConfig.value = JSON.stringify(transactions ? transactions : [])
        } catch (error) {
            console.log("Unable to save transactions:", error)
        }
    }

    function saveCategories() {
        if (!transactionsLoaded) {
            return
        }

        try {
            categoriesConfig.value = JSON.stringify(categories ? categories : [])
        } catch (error) {
            console.log("Unable to save categories:", error)
        }
    }

    function addCategory(categoryName) {
        var normalized = normalizeCategoryName(categoryName)
        if (normalized === "") {
            return false
        }
        if (categoryIndexByName(normalized) >= 0) {
            return false
        }

        categories = sortAndUniqueCategories(categories.concat([normalized]))
        return true
    }

    function renameCategory(oldName, newName) {
        var normalizedOld = normalizeCategoryName(oldName)
        var normalizedNew = normalizeCategoryName(newName)
        if (normalizedOld === "" || normalizedNew === "") {
            return false
        }

        var oldIndex = categoryIndexByName(normalizedOld)
        if (oldIndex < 0) {
            return false
        }

        var existingNewIndex = categoryIndexByName(normalizedNew)
        if (existingNewIndex >= 0 && existingNewIndex !== oldIndex) {
            return false
        }

        var updatedCategories = categories.slice(0)
        updatedCategories[oldIndex] = normalizedNew
        categories = sortAndUniqueCategories(updatedCategories)

        var updatedTransactions = transactions.slice(0)
        var hasTransactionChanges = false
        for (var i = 0; i < updatedTransactions.length; i++) {
            var tx = updatedTransactions[i]
            if (!tx || !tx.category) {
                continue
            }
            if (String(tx.category).toLowerCase() === normalizedOld.toLowerCase()) {
                updatedTransactions[i] = {
                    type: tx.type,
                    amount: tx.amount,
                    category: normalizedNew,
                    notes: tx.notes,
                    date: tx.date,
                    color: tx.color
                }
                hasTransactionChanges = true
            }
        }
        if (hasTransactionChanges) {
            transactions = updatedTransactions
        }

        return true
    }

    function removeCategory(categoryName) {
        var normalized = normalizeCategoryName(categoryName)
        if (normalized === "") {
            return false
        }

        var removeIndex = categoryIndexByName(normalized)
        if (removeIndex < 0) {
            return false
        }

        var updatedCategories = categories.slice(0)
        updatedCategories.splice(removeIndex, 1)

        var updatedTransactions = transactions.slice(0)
        var hasTransactionChanges = false
        for (var i = 0; i < updatedTransactions.length; i++) {
            var tx = updatedTransactions[i]
            if (!tx || !tx.category) {
                continue
            }
            if (String(tx.category).toLowerCase() === normalized.toLowerCase()) {
                var replacement = updatedCategories.length > 0
                        ? updatedCategories[0]
                        : defaultCategoryForType(tx.type)
                updatedTransactions[i] = {
                    type: tx.type,
                    amount: tx.amount,
                    category: replacement,
                    notes: tx.notes,
                    date: tx.date,
                    color: tx.color
                }
                hasTransactionChanges = true
            }
        }

        categories = updatedCategories
        if (hasTransactionChanges) {
            transactions = updatedTransactions
        }

        if (categories.length === 0 && transactions.length > 0) {
            categories = sortAndUniqueCategories(categoriesFromTransactions())
        }

        return true
    }

    function addTransaction(transactionType, rawAmount, category, notes, year, month, day) {
        var amount = Math.abs(Number(rawAmount))
        if (!amount || amount <= 0) {
            return
        }
        var normalizedCategory = normalizeCategoryName(category)
        if (normalizedCategory === "") {
            normalizedCategory = defaultCategoryForType(transactionType)
        }
        if (categoryIndexByName(normalizedCategory) < 0) {
            categories = sortAndUniqueCategories(categories.concat([normalizedCategory]))
        }

        var txDate = new Date()
        if (typeof year === "number" && typeof month === "number") {
            var txDay = txDate.getDate()
            if (typeof day === "number" && day > 0) {
                txDay = day
            }
            txDate = new Date(year, month, txDay, 12, 0, 0, 0)
        }

        var nextIndex = transactions.length % piePalette.length
        transactions = transactions.concat([{
            type: transactionType,
            amount: amount,
            category: normalizedCategory,
            notes: notes ? notes.trim() : "",
            date: txDate.toISOString(),
            color: piePalette[nextIndex]
        }])
    }

    function updateTransaction(transactionIndex, rawAmount, category, notes, year, month, day) {
        if (transactionIndex < 0 || transactionIndex >= transactions.length) {
            return false
        }

        var amount = Math.abs(Number(rawAmount))
        if (!amount || amount <= 0) {
            return false
        }

        var current = transactions[transactionIndex]
        if (!current) {
            return false
        }

        var normalizedCategory = normalizeCategoryName(category)
        if (normalizedCategory === "") {
            normalizedCategory = defaultCategoryForType(current.type)
        }
        if (categoryIndexByName(normalizedCategory) < 0) {
            categories = sortAndUniqueCategories(categories.concat([normalizedCategory]))
        }

        var updatedDate = current.date ? new Date(current.date) : new Date()
        if (isNaN(updatedDate.getTime())) {
            updatedDate = new Date()
        }
        if (typeof year === "number" && typeof month === "number") {
            var txDay = updatedDate.getDate()
            if (typeof day === "number" && day > 0) {
                txDay = day
            }
            updatedDate = new Date(year, month, txDay, 12, 0, 0, 0)
        }

        var updatedTransactions = transactions.slice(0)
        updatedTransactions[transactionIndex] = {
            type: current.type,
            amount: amount,
            category: normalizedCategory,
            notes: notes ? notes.trim() : "",
            date: updatedDate.toISOString(),
            color: current.color ? current.color : piePalette[transactionIndex % piePalette.length]
        }

        transactions = updatedTransactions
        return true
    }

    function removeTransaction(transactionIndex) {
        if (transactionIndex < 0 || transactionIndex >= transactions.length) {
            return false
        }

        var updatedTransactions = transactions.slice(0)
        updatedTransactions.splice(transactionIndex, 1)
        transactions = updatedTransactions
        return true
    }

    onTransactionsChanged: saveTransactions()
    onCategoriesChanged: saveCategories()

    Component.onCompleted: {
        loadCurrency()
        loadTransactions()
        loadCategories()
        transactionsLoaded = true
        saveTransactions()
        saveCategories()
    }
}
