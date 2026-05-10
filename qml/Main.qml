import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.3
import QtQuick.LocalStorage 2.0

MainView {
    id: root
    objectName: "mainView"
    applicationName: "expensetracker.keshvi"
    automaticOrientation: true
    width: units.gu(130)
    height: units.gu(85)

    property var db: null
    property real totalAmount: 0
    property real budgetLimit: 0
    property string selectedCategory: "All"
    property int currentTab: 0
    property bool darkMode: false
    property string bgColor: darkMode ? "#1a1a2e" : "#f8f4ff"
    property string cardColor: darkMode ? "#16213e" : "#ffffff"
    property string textColor: darkMode ? "#ffffff" : "#2d3436"
    property string subTextColor: darkMode ? "#a0a0b0" : "#636e72"
    property string borderColor: darkMode ? "#2a2a4a" : "#f0eaff"
    property string accentColor: "#7C3AED"

    readonly property var categories: ["All","Food","Transport","Shopping","Health","Entertainment","General"]
    readonly property var categoryColors: ({
        "Food": "#FF6B6B", "Transport": "#4ECDC4", "Shopping": "#45B7D1",
        "Health": "#96CEB4", "Entertainment": "#A29BFE", "General": "#FD79A8", "All": "#7C3AED"
    })

    function initDB() {
        db = LocalStorage.openDatabaseSync("expensetracker", "1.0", "Expense Tracker DB", 1000000)
        db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, description TEXT, amount REAL, category TEXT, date TEXT)')
            tx.executeSql('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)')
        })
        db.transaction(function(tx) {
            var r = tx.executeSql('SELECT value FROM settings WHERE key="budget"')
            if (r.rows.length > 0) budgetLimit = parseFloat(r.rows.item(0).value)
        })
    }

    function loadExpenses() {
        db.transaction(function(tx) {
            var query = 'SELECT * FROM expenses'
            if (selectedCategory !== "All") query += ' WHERE category="' + selectedCategory + '"'
            query += ' ORDER BY id DESC'
            var result = tx.executeSql(query)
            expenseModel.clear()
            var total = 0
            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i)
                expenseModel.append({
                    "dbid": row.id, "description": row.description,
                    "amount": row.amount.toFixed(2), "category": row.category, "date": row.date
                })
                total += row.amount
            }
            totalAmount = total
        })
    }

    function addExpense(desc, amount, category) {
        var date = new Date().toLocaleDateString()
        db.transaction(function(tx) {
            tx.executeSql('INSERT INTO expenses (description, amount, category, date) VALUES (?, ?, ?, ?)',
                [desc, parseFloat(amount), category, date])
        })
        loadExpenses()
    }

    function deleteExpense(dbid) {
        db.transaction(function(tx) { tx.executeSql('DELETE FROM expenses WHERE id = ?', [dbid]) })
        loadExpenses()
    }

    function updateExpense(dbid, desc, amount, category) {
        db.transaction(function(tx) {
            tx.executeSql('UPDATE expenses SET description=?, amount=?, category=? WHERE id=?',
                [desc, parseFloat(amount), category, dbid])
        })
        loadExpenses()
    }

    function saveBudget(val) {
        budgetLimit = parseFloat(val)
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES ("budget", ?)', [val])
        })
    }

    function getCategoryTotal(cat) {
        var total = 0
        db.transaction(function(tx) {
            var r = tx.executeSql('SELECT SUM(amount) as total FROM expenses WHERE category=?', [cat])
            if (r.rows.length > 0 && r.rows.item(0).total) total = r.rows.item(0).total
        })
        return total
    }

    ListModel { id: expenseModel }

    Component.onCompleted: { initDB(); loadExpenses() }

    Page {
        anchors.fill: parent
        header: PageHeader { id: header; title: ""; visible: false }

        Rectangle {
            anchors.fill: parent
            color: bgColor

            Row {
                anchors.fill: parent

                // Sidebar
                Rectangle {
                    width: units.gu(24); height: parent.height
                    color: darkMode ? "#0f0f23" : "#ffffff"

                    Column {
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        spacing: 0

                        Rectangle {
                            width: parent.width; height: units.gu(11); color: "transparent"
                            Row {
                                anchors { left: parent.left; leftMargin: units.gu(2); verticalCenter: parent.verticalCenter }
                                spacing: units.gu(1)
                                Rectangle {
                                    width: units.gu(4.5); height: units.gu(4.5); radius: units.gu(1); color: accentColor
                                    Label { text: "Rs"; anchors.centerIn: parent; color: "white"; font.pixelSize: units.gu(1.8); font.bold: true }
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Label { text: "ExpenseTracker"; font.pixelSize: units.gu(1.8); font.bold: true; color: textColor }
                                    Label { text: "Personal Finance"; font.pixelSize: units.gu(1.3); color: subTextColor }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width - units.gu(4); height: units.gu(5.5)
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: units.gu(1); color: accentColor
                            Row {
                                anchors.centerIn: parent; spacing: units.gu(0.8)
                                Label { text: "+"; color: "white"; font.pixelSize: units.gu(2.5); font.bold: true }
                                Label { text: "Add Expense"; color: "white"; font.pixelSize: units.gu(1.6); font.bold: true }
                            }
                            MouseArea { anchors.fill: parent; onClicked: PopupUtils.open(addDialogComponent) }
                        }

                        Rectangle { width: parent.width; height: units.gu(1.5); color: "transparent" }

                        Repeater {
                            model: ["Dashboard","Analytics","Transactions","Settings"]
                            Rectangle {
                                width: parent.width - units.gu(3); height: units.gu(5.5)
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: units.gu(1)
                                color: currentTab === index ? (darkMode ? "#7C3AED33" : "#f3eeff") : "transparent"
                                Rectangle {
                                    visible: currentTab === index
                                    width: units.gu(0.4); height: units.gu(3); radius: width/2; color: accentColor
                                    anchors { left: parent.left; leftMargin: units.gu(0.3); verticalCenter: parent.verticalCenter }
                                }
                                Label {
                                    text: modelData
                                    anchors { left: parent.left; leftMargin: units.gu(2); verticalCenter: parent.verticalCenter }
                                    font.pixelSize: units.gu(1.7)
                                    color: currentTab === index ? accentColor : subTextColor
                                    font.bold: currentTab === index
                                }
                                MouseArea { anchors.fill: parent; onClicked: currentTab = index }
                            }
                        }
                    }

                    Column {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: units.gu(2); bottomMargin: units.gu(3) }
                        spacing: units.gu(1.5)
                        Rectangle {
                            width: parent.width; height: units.gu(11); radius: units.gu(1.5); color: accentColor
                            Column {
                                anchors { left: parent.left; leftMargin: units.gu(1.5); verticalCenter: parent.verticalCenter }
                                spacing: units.gu(0.5)
                                Label { text: "Monthly Budget"; color: "#ffffff99"; font.pixelSize: units.gu(1.3) }
                                Label { text: budgetLimit > 0 ? "Rs" + budgetLimit.toFixed(0) : "Not set"; color: "white"; font.pixelSize: units.gu(2.2); font.bold: true }
                                Rectangle {
                                    visible: budgetLimit > 0
                                    width: units.gu(16); height: units.gu(0.6); radius: height/2; color: "#ffffff44"
                                    Rectangle {
                                        width: Math.min(parent.width, parent.width * (totalAmount / budgetLimit))
                                        height: parent.height; radius: parent.radius
                                        color: totalAmount > budgetLimit ? "#FF6B6B" : "#55efc4"
                                    }
                                }
                                Label {
                                    visible: budgetLimit > 0
                                    text: totalAmount > budgetLimit ? "Over budget!" : "Rs" + (budgetLimit - totalAmount).toFixed(0) + " left"
                                    color: totalAmount > budgetLimit ? "#FF6B6B" : "#ffffff99"
                                    font.pixelSize: units.gu(1.2)
                                }
                            }
                        }
                        Row {
                            spacing: units.gu(1)
                            Label { text: darkMode ? "Dark" : "Light"; color: subTextColor; font.pixelSize: units.gu(1.5); anchors.verticalCenter: parent.verticalCenter }
                            Rectangle {
                                width: units.gu(5); height: units.gu(2.5); radius: height/2
                                color: darkMode ? accentColor : "#e0e0e0"
                                anchors.verticalCenter: parent.verticalCenter
                                Rectangle {
                                    width: units.gu(2); height: units.gu(2); radius: height/2; color: "white"
                                    anchors { verticalCenter: parent.verticalCenter; right: darkMode ? parent.right : undefined; left: darkMode ? undefined : parent.left; margins: units.gu(0.2) }
                                }
                                MouseArea { anchors.fill: parent; onClicked: darkMode = !darkMode }
                            }
                        }
                    }
                }

                // Main content area
                Rectangle {
                    width: parent.width - units.gu(24); height: parent.height; color: bgColor

                    // Dashboard
                    Item {
                        anchors.fill: parent; visible: currentTab === 0
                        ScrollView {
                            anchors.fill: parent
                            Column {
                                width: parent.parent.width - units.gu(4); x: units.gu(2)
                                spacing: units.gu(2); topPadding: units.gu(3); bottomPadding: units.gu(3)
                                Column {
                                    spacing: units.gu(0.3)
                                    Label { text: "Good day, Keshvi"; color: subTextColor; font.pixelSize: units.gu(1.6) }
                                    Label { text: "Your Expense Dashboard"; font.pixelSize: units.gu(3); font.bold: true; color: textColor }
                                }
                                Row {
                                    width: parent.width; spacing: units.gu(2)
                                    Repeater {
                                        model: [
                                            {"title": "Total Spent", "value": "Rs" + totalAmount.toFixed(2), "sub": "This period", "c1": "#7C3AED"},
                                            {"title": "Budget Left", "value": budgetLimit > 0 ? "Rs" + Math.max(0, budgetLimit - totalAmount).toFixed(2) : "--", "sub": "Monthly limit", "c1": "#059669"},
                                            {"title": "Transactions", "value": expenseModel.count.toString(), "sub": "Total entries", "c1": "#DC2626"},
                                            {"title": "Avg/Transaction", "value": expenseModel.count > 0 ? "Rs" + (totalAmount / expenseModel.count).toFixed(0) : "--", "sub": "Per expense", "c1": "#D97706"}
                                        ]
                                        Rectangle {
                                            width: (parent.width - units.gu(6)) / 4; height: units.gu(13); radius: units.gu(1.5); color: cardColor
                                            Column {
                                                anchors { left: parent.left; leftMargin: units.gu(2); top: parent.top; topMargin: units.gu(1.5) }
                                                spacing: units.gu(0.8)
                                                Rectangle {
                                                    width: units.gu(5); height: units.gu(5); radius: units.gu(1); color: modelData.c1 + "22"
                                                    Label { text: modelData.title[0]; anchors.centerIn: parent; font.pixelSize: units.gu(2.2); color: modelData.c1 }
                                                }
                                                Label { text: modelData.title; color: subTextColor; font.pixelSize: units.gu(1.4) }
                                                Label { text: modelData.value; color: modelData.c1; font.pixelSize: units.gu(2.2); font.bold: true }
                                                Label { text: modelData.sub; color: subTextColor; font.pixelSize: units.gu(1.2) }
                                            }
                                        }
                                    }
                                }
                                Row {
                                    width: parent.width; spacing: units.gu(2)
                                    Rectangle {
                                        width: parent.width * 0.62; height: units.gu(52); radius: units.gu(1.5); color: cardColor
                                        Column {
                                            anchors { top: parent.top; left: parent.left; right: parent.right; margins: units.gu(2) }
                                            spacing: units.gu(1.5)
                                            Label { text: "Recent Transactions"; font.pixelSize: units.gu(2); font.bold: true; color: textColor }
                                            Flow {
                                                width: parent.width; spacing: units.gu(0.5)
                                                Repeater {
                                                    model: categories
                                                    Rectangle {
                                                        height: units.gu(3); width: fLbl.width + units.gu(1.5); radius: height/2
                                                        color: selectedCategory === modelData ? accentColor : (darkMode ? "#2a2a4a" : "#f3eeff")
                                                        Label { id: fLbl; text: modelData; anchors.centerIn: parent; font.pixelSize: units.gu(1.2); color: selectedCategory === modelData ? "white" : subTextColor }
                                                        MouseArea { anchors.fill: parent; onClicked: { selectedCategory = modelData; loadExpenses() } }
                                                    }
                                                }
                                            }
                                            ListView {
                                                width: parent.width; height: units.gu(40); clip: true; model: expenseModel
                                                delegate: Rectangle {
                                                    width: parent.width; height: units.gu(7.5); color: "transparent"
                                                    Rectangle {
                                                        anchors.bottom: parent.bottom
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        height: 1; color: borderColor
                                                    }
                                                    Rectangle {
                                                        width: units.gu(5.5); height: units.gu(5.5); radius: units.gu(1)
                                                        color: (categoryColors[model.category] || "#7C3AED") + "22"
                                                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                                        Label { text: model.category.substring(0,1); anchors.centerIn: parent; font.pixelSize: units.gu(2.2); font.bold: true; color: categoryColors[model.category] || "#7C3AED" }
                                                    }
                                                    Column {
                                                        anchors { left: parent.left; leftMargin: units.gu(7); right: amountLbl.left; rightMargin: units.gu(1); verticalCenter: parent.verticalCenter }
                                                        spacing: units.gu(0.3)
                                                        Label { text: model.description; font.pixelSize: units.gu(1.8); font.bold: true; color: textColor; elide: Text.ElideRight; width: parent.width }
                                                        Row {
                                                            spacing: units.gu(0.8)
                                                            Rectangle {
                                                                height: units.gu(2.2); width: cLbl.width + units.gu(1.5); radius: height/2
                                                                color: (categoryColors[model.category] || "#7C3AED") + "22"
                                                                Label { id: cLbl; text: model.category; anchors.centerIn: parent; font.pixelSize: units.gu(1.2); color: categoryColors[model.category] || "#7C3AED" }
                                                            }
                                                            Label { text: model.date; font.pixelSize: units.gu(1.3); color: subTextColor; anchors.verticalCenter: parent.verticalCenter }
                                                        }
                                                    }
                                                    Label {
                                                        id: amountLbl
                                                        text: "Rs" + model.amount
                                                        font.pixelSize: units.gu(1.8); font.bold: true; color: accentColor
                                                        anchors { right: actionRow.left; rightMargin: units.gu(1); verticalCenter: parent.verticalCenter }
                                                    }
                                                    Row {
                                                        id: actionRow
                                                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                                        spacing: units.gu(0.5)
                                                        Rectangle {
                                                            width: units.gu(5); height: units.gu(3.5); radius: units.gu(0.8); color: accentColor
                                                            Label { text: "Edit"; anchors.centerIn: parent; color: "white"; font.pixelSize: units.gu(1.3); font.bold: true }
                                                            MouseArea { anchors.fill: parent; onClicked: PopupUtils.open(editDialogComponent, null, {"editId": model.dbid, "editDesc": model.description, "editAmount": model.amount, "editCategory": model.category}) }
                                                        }
                                                        Rectangle {
                                                            width: units.gu(5); height: units.gu(3.5); radius: units.gu(0.8); color: "#FF6B6B"
                                                            Label { text: "Del"; anchors.centerIn: parent; color: "white"; font.pixelSize: units.gu(1.3); font.bold: true }
                                                            MouseArea { anchors.fill: parent; onClicked: deleteExpense(model.dbid) }
                                                        }
                                                    }
                                                }
                                                Label { anchors.centerIn: parent; text: "No expenses yet."; color: subTextColor; font.pixelSize: units.gu(1.8); visible: expenseModel.count === 0 }
                                            }
                                        }
                                    }
                                    Column {
                                        width: parent.width * 0.38 - units.gu(2); spacing: units.gu(2)
                                        Rectangle {
                                            width: parent.width; height: units.gu(30); radius: units.gu(1.5); color: cardColor
                                            Column {
                                                anchors { top: parent.top; left: parent.left; right: parent.right; margins: units.gu(2) }
                                                spacing: units.gu(1.2)
                                                Label { text: "Spending by Category"; font.pixelSize: units.gu(1.8); font.bold: true; color: textColor }
                                                Repeater {
                                                    model: ["Food","Transport","Shopping","Health","Entertainment","General"]
                                                    Column {
                                                        width: parent.width; spacing: units.gu(0.4)
                                                        property real catTotal: totalAmount >= 0 ? getCategoryTotal(modelData) : 0
                                                        property real pct: totalAmount > 0 ? catTotal / totalAmount : 0
                                                        Row {
                                                            width: parent.width
                                                            Label { text: modelData; font.pixelSize: units.gu(1.5); color: textColor; width: parent.width - amtL.width }
                                                            Label { id: amtL; text: catTotal > 0 ? "Rs" + catTotal.toFixed(0) : "Rs0"; font.pixelSize: units.gu(1.4); color: catTotal > 0 ? (categoryColors[modelData] || accentColor) : subTextColor; font.bold: true }
                                                        }
                                                        Rectangle {
                                                            width: parent.width; height: units.gu(0.8); radius: height/2; color: darkMode ? "#2a2a4a" : "#f0eaff"
                                                            Rectangle { width: parent.width * pct; height: parent.height; radius: parent.radius; color: categoryColors[modelData] || accentColor }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        Rectangle {
                                            width: parent.width; height: units.gu(20); radius: units.gu(1.5); color: accentColor
                                            Column {
                                                anchors { left: parent.left; leftMargin: units.gu(2); top: parent.top; topMargin: units.gu(2) }
                                                spacing: units.gu(1)
                                                Label { text: "Budget Overview"; color: "#ffffff99"; font.pixelSize: units.gu(1.5) }
                                                Label { text: "Rs" + totalAmount.toFixed(2); color: "white"; font.pixelSize: units.gu(3.5); font.bold: true }
                                                Label { text: budgetLimit > 0 ? "of Rs" + budgetLimit.toFixed(0) + " budget" : "No budget set"; color: "#ffffff99"; font.pixelSize: units.gu(1.4) }
                                                Rectangle {
                                                    visible: budgetLimit > 0; width: units.gu(22); height: units.gu(1); radius: height/2; color: "#5B2DC4"
                                                    Rectangle { width: Math.min(parent.width, parent.width * (totalAmount / budgetLimit)); height: parent.height; radius: parent.radius; color: totalAmount > budgetLimit ? "#FF6B6B" : "#55efc4" }
                                                }
                                                Rectangle {
                                                    width: units.gu(14); height: units.gu(4); radius: units.gu(0.8); color: "#5B2DC4"
                                                    border.color: "white"; border.width: 1
                                                    Label { text: "Set Budget"; anchors.centerIn: parent; color: "white"; font.pixelSize: units.gu(1.5) }
                                                    MouseArea { anchors.fill: parent; onClicked: currentTab = 3 }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Analytics
                    Item {
                        anchors.fill: parent; visible: currentTab === 1
                        ScrollView {
                            anchors.fill: parent
                            Column {
                                width: parent.parent.width - units.gu(4); x: units.gu(2); spacing: units.gu(2); topPadding: units.gu(3)
                                Label { text: "Analytics"; font.pixelSize: units.gu(3); font.bold: true; color: textColor }
                                Row {
                                    width: parent.width; spacing: units.gu(2)
                                    Rectangle {
                                        width: parent.width * 0.45; height: units.gu(42); radius: units.gu(1.5); color: cardColor
                                        Column {
                                            anchors { top: parent.top; left: parent.left; right: parent.right; margins: units.gu(2) }
                                            spacing: units.gu(1.5)
                                            Label { text: "Spending Breakdown"; font.pixelSize: units.gu(1.8); font.bold: true; color: textColor }
                                            Repeater {
                                                model: ["Food","Transport","Shopping","Health","Entertainment","General"]
                                                Column {
                                                    width: parent.width; spacing: units.gu(0.5)
                                                    property real catTotal: totalAmount >= 0 ? getCategoryTotal(modelData) : 0
                                                    property real pct: totalAmount > 0 ? catTotal / totalAmount : 0
                                                    Row {
                                                        width: parent.width
                                                        Label { text: modelData; font.pixelSize: units.gu(1.5); color: textColor; width: parent.width * 0.3 }
                                                        Rectangle {
                                                            width: parent.width * 0.5; height: units.gu(2.5); radius: height/2
                                                            color: darkMode ? "#2a2a4a" : "#f0eaff"; anchors.verticalCenter: parent.verticalCenter
                                                            Rectangle { width: parent.width * pct; height: parent.height; radius: parent.radius; color: categoryColors[modelData] || accentColor }
                                                        }
                                                        Label { text: Math.round(pct * 100) + "%"; font.pixelSize: units.gu(1.4); color: subTextColor; width: parent.width * 0.2; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    Column {
                                        width: parent.width * 0.55 - units.gu(2); spacing: units.gu(2)
                                        Rectangle {
                                            width: parent.width; height: units.gu(12); radius: units.gu(1.5); color: cardColor
                                            Column {
                                                anchors { left: parent.left; leftMargin: units.gu(2); verticalCenter: parent.verticalCenter }
                                                spacing: units.gu(0.5)
                                                Label { text: "Highest Spending"; color: subTextColor; font.pixelSize: units.gu(1.4) }
                                                Label {
                                                    text: {
                                                        var max = 0; var cat = "None"
                                                        var cats = ["Food","Transport","Shopping","Health","Entertainment","General"]
                                                        for (var i = 0; i < cats.length; i++) { var t = getCategoryTotal(cats[i]); if (t > max) { max = t; cat = cats[i] } }
                                                        return cat
                                                    }
                                                    font.pixelSize: units.gu(2.5); font.bold: true; color: accentColor
                                                }
                                                Label { text: "Rs" + totalAmount.toFixed(2) + " total"; color: subTextColor; font.pixelSize: units.gu(1.3) }
                                            }
                                        }
                                        Grid {
                                            width: parent.width; columns: 2; spacing: units.gu(1.5)
                                            Repeater {
                                                model: ["Food","Transport","Shopping","Health","Entertainment","General"]
                                                Rectangle {
                                                    width: (parent.width - units.gu(1.5)) / 2; height: units.gu(9); radius: units.gu(1.5); color: cardColor
                                                    property real catTotal: totalAmount >= 0 ? getCategoryTotal(modelData) : 0
                                                    property real pct: totalAmount > 0 ? catTotal / totalAmount : 0
                                                    Rectangle { width: units.gu(0.5); height: parent.height * 0.6; radius: width/2; color: categoryColors[modelData] || accentColor; anchors { left: parent.left; leftMargin: units.gu(0.5); verticalCenter: parent.verticalCenter } }
                                                    Column {
                                                        anchors { left: parent.left; leftMargin: units.gu(2); verticalCenter: parent.verticalCenter }
                                                        spacing: units.gu(0.4)
                                                        Label { text: modelData; font.pixelSize: units.gu(1.5); font.bold: true; color: textColor }
                                                        Label { text: "Rs" + catTotal.toFixed(0); font.pixelSize: units.gu(1.8); font.bold: true; color: categoryColors[modelData] || accentColor }
                                                        Label { text: Math.round(pct * 100) + "% of total"; font.pixelSize: units.gu(1.2); color: subTextColor }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Transactions
                    Item {
                        anchors.fill: parent; visible: currentTab === 2
                        ScrollView {
                            anchors.fill: parent
                            Column {
                                width: parent.parent.width - units.gu(4); x: units.gu(2); spacing: units.gu(2); topPadding: units.gu(3)
                                Label { text: "All Transactions"; font.pixelSize: units.gu(3); font.bold: true; color: textColor }
                                Rectangle {
                                    width: parent.width; height: units.gu(62); radius: units.gu(1.5); color: cardColor
                                    Column {
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: units.gu(2) }
                                        spacing: units.gu(1)
                                        Flow {
                                            width: parent.width; spacing: units.gu(0.5)
                                            Repeater {
                                                model: categories
                                                Rectangle {
                                                    height: units.gu(3); width: tLbl.width + units.gu(1.5); radius: height/2
                                                    color: selectedCategory === modelData ? accentColor : (darkMode ? "#2a2a4a" : "#f3eeff")
                                                    Label { id: tLbl; text: modelData; anchors.centerIn: parent; font.pixelSize: units.gu(1.2); color: selectedCategory === modelData ? "white" : subTextColor }
                                                    MouseArea { anchors.fill: parent; onClicked: { selectedCategory = modelData; loadExpenses() } }
                                                }
                                            }
                                        }
                                        ListView {
                                            width: parent.width; height: units.gu(52); clip: true; model: expenseModel
                                            delegate: Rectangle {
                                                width: parent.width; height: units.gu(7.5); color: "transparent"
                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    height: 1; color: borderColor
                                                }
                                                Row {
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    spacing: units.gu(1.5)
                                                    Rectangle {
                                                        width: units.gu(5.5); height: units.gu(5.5); radius: units.gu(1)
                                                        color: (categoryColors[model.category] || "#7C3AED") + "22"
                                                        Label { text: model.category.substring(0,1); anchors.centerIn: parent; font.pixelSize: units.gu(2.2); font.bold: true; color: categoryColors[model.category] || "#7C3AED" }
                                                    }
                                                    Column {
                                                        width: parent.width - units.gu(20); anchors.verticalCenter: parent.verticalCenter; spacing: units.gu(0.3)
                                                        Label { text: model.description; font.pixelSize: units.gu(1.8); font.bold: true; color: textColor }
                                                        Row {
                                                            spacing: units.gu(0.8)
                                                            Rectangle {
                                                                height: units.gu(2.2); width: cLbl2.width + units.gu(1.5); radius: height/2
                                                                color: (categoryColors[model.category] || "#7C3AED") + "22"
                                                                Label { id: cLbl2; text: model.category; anchors.centerIn: parent; font.pixelSize: units.gu(1.2); color: categoryColors[model.category] || "#7C3AED" }
                                                            }
                                                            Label { text: model.date; font.pixelSize: units.gu(1.3); color: subTextColor; anchors.verticalCenter: parent.verticalCenter }
                                                        }
                                                    }
                                                    Label { text: "Rs" + model.amount; font.pixelSize: units.gu(2); font.bold: true; color: accentColor; anchors.verticalCenter: parent.verticalCenter }
                                                    Row {
                                                        anchors.verticalCenter: parent.verticalCenter; spacing: units.gu(0.5)
                                                        Rectangle {
                                                            width: units.gu(4); height: units.gu(3.5); radius: units.gu(0.8); color: accentColor
                                                            Label { text: "Edit"; anchors.centerIn: parent; color: "white"; font.pixelSize: units.gu(1.3); font.bold: true }
                                                            MouseArea { anchors.fill: parent; onClicked: PopupUtils.open(editDialogComponent, null, {"editId": model.dbid, "editDesc": model.description, "editAmount": model.amount, "editCategory": model.category}) }
                                                        }
                                                        Rectangle {
                                                            width: units.gu(4); height: units.gu(3.5); radius: units.gu(0.8); color: "#FF6B6B"
                                                            Label { text: "Del"; anchors.centerIn: parent; color: "white"; font.pixelSize: units.gu(1.3); font.bold: true }
                                                            MouseArea { anchors.fill: parent; onClicked: deleteExpense(model.dbid) }
                                                        }
                                                    }
                                                }
                                            }
                                            Label { anchors.centerIn: parent; text: "No expenses yet."; color: subTextColor; font.pixelSize: units.gu(1.8); visible: expenseModel.count === 0 }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Settings
                    Item {
                        anchors.fill: parent; visible: currentTab === 3
                        Column {
                            anchors { top: parent.top; left: parent.left; margins: units.gu(3) }
                            spacing: units.gu(2); width: units.gu(55)
                            Label { text: "Settings"; font.pixelSize: units.gu(3); font.bold: true; color: textColor }
                            Rectangle {
                                width: units.gu(55); height: units.gu(14); radius: units.gu(1.5); color: cardColor
                                Column {
                                    anchors { left: parent.left; leftMargin: units.gu(2); verticalCenter: parent.verticalCenter }
                                    spacing: units.gu(1.2)
                                    Label { text: "Monthly Budget"; font.pixelSize: units.gu(1.8); font.bold: true; color: textColor }
                                    Label { text: "Set your spending limit for the month"; font.pixelSize: units.gu(1.4); color: subTextColor }
                                    Row {
                                        spacing: units.gu(1)
                                        TextField {
                                            id: budgetSettingField; width: units.gu(25)
                                            placeholderText: "Enter budget (Rs)"
                                            text: budgetLimit > 0 ? budgetLimit.toString() : ""
                                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                                        }
                                        Button {
                                            text: "Save"; color: accentColor
                                            onClicked: { if (budgetSettingField.text) saveBudget(budgetSettingField.text) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: addDialogComponent
            Dialog {
                id: addDialog; title: i18n.tr("Add Expense")
                TextField { id: descField; placeholderText: i18n.tr("Description"); width: parent.width }
                TextField { id: amountField; placeholderText: i18n.tr("Amount (Rs)"); inputMethodHints: Qt.ImhFormattedNumbersOnly; width: parent.width }
                OptionSelector { id: categorySelector; model: ["Food","Transport","Shopping","Health","Entertainment","General"]; width: parent.width }
                Button {
                    text: i18n.tr("Add"); color: accentColor; width: parent.width
                    onClicked: {
                        if (descField.text && amountField.text) {
                            addExpense(descField.text, amountField.text, categorySelector.model[categorySelector.selectedIndex])
                            PopupUtils.close(addDialog)
                        }
                    }
                }
                Button { text: i18n.tr("Cancel"); width: parent.width; onClicked: PopupUtils.close(addDialog) }
            }
        }

        Component {
            id: editDialogComponent
            Dialog {
                id: editDialog; title: i18n.tr("Edit Expense")
                property int editId
                property string editDesc
                property string editAmount
                property string editCategory
                TextField { id: editDescField; text: editDialog.editDesc; width: parent.width }
                TextField { id: editAmountField; text: editDialog.editAmount; inputMethodHints: Qt.ImhFormattedNumbersOnly; width: parent.width }
                OptionSelector {
                    id: editCategorySelector
                    model: ["Food","Transport","Shopping","Health","Entertainment","General"]
                    selectedIndex: model.indexOf(editDialog.editCategory)
                    width: parent.width
                }
                Button {
                    text: i18n.tr("Save"); color: accentColor; width: parent.width
                    onClicked: {
                        updateExpense(editDialog.editId, editDescField.text, editAmountField.text,
                            editCategorySelector.model[editCategorySelector.selectedIndex])
                        PopupUtils.close(editDialog)
                    }
                }
                Button { text: i18n.tr("Cancel"); width: parent.width; onClicked: PopupUtils.close(editDialog) }
            }
        }

        Splash {
            id: splashScreen
            anchors.fill: parent
            visible: true
            onDone: visible = false
        }
    }
}
