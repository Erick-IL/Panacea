import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Complete Weather Forecast: Current Condition, Hourly Forecast (24-36h) and Weekly Forecast with dedicated scroll


Item {
    id: view

    property var sys

    width: parent ? parent.width : ((view.sys && view.sys.panelW) ? view.sys.panelW - 30 : 510)

    readonly property bool isExpanded: view.sys && view.sys.weatherExpanded

    // Dynamic height: fills the screen when expanded, or adjusts perfectly without leaving a gap in the background


    readonly property real maxViewHeight: {
        if (view.isExpanded) {
            return (view.sys && view.sys.screen ? view.sys.screen.height - 70 : 820);
        }
        var h = view.sys && view.sys.cfg && view.sys.cfg.expandedH ? view.sys.cfg.expandedH : 620;
        return h - 30;
    }

    implicitHeight: view.isExpanded
        ? maxViewHeight
        : (view.sys && view.sys.weatherReady ? Math.min(maxViewHeight, Math.max(500, mainCol.implicitHeight))
                                             : Math.max(160, mainCol.implicitHeight))
    height: implicitHeight

    focus: true
    Component.onCompleted: forceActiveFocus()
    function goBack() { view.sys.page = "main"; return true; }
    Keys.onEscapePressed: view.goBack()

    readonly property var forecast: view.sys.weatherForecast
    readonly property var hourly: forecast && forecast.hourly ? forecast.hourly : []
    readonly property var daily: forecast && forecast.daily ? forecast.daily : []

    function glyphFor(code) {
        var k = String(code || "").slice(0, 2);
        return String.fromCodePoint(
            k === "01" ? 0xF0599   // limpo / sol
          : k === "02" ? 0xF0595   // poucas nuvens
          : k === "03" ? 0xF0590   // nuvens dispersas
          : k === "04" ? 0xF0590   // nublado
          : k === "09" ? 0xF0597   // pancadas de chuva
          : k === "10" ? 0xF0596   // chuva
          : k === "11" ? 0xF0593   // tempestade
          : k === "13" ? 0xF0598   // neve
          : k === "50" ? 0xF0591   // nevoa

                       : 0xF0590
        );
    }

    // Temperature limits of the week for the visual bar

    readonly property real weekMin: {
        if (!daily || !daily.length) return 0;
        var m = daily[0].min;
        for (var i = 1; i < daily.length; i++) if (daily[i].min < m) m = daily[i].min;
        return m;
    }
    readonly property real weekMax: {
        if (!daily || !daily.length) return 30;
        var m = daily[0].max;
        for (var i = 1; i < daily.length; i++) if (daily[i].max > m) m = daily[i].max;
        return m;
    }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        spacing: 8

        // ------------------------------------------------------------- 1. Header


        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 10

            // Back button


            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                radius: 10
                color: backMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 140 } }

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: view.sys.colFg
                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize + 4 }
                }

                MouseArea {
                    id: backMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: view.goBack()
                }
            }

            // Title and Subtitle (on the left)


            ColumnLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: -1

                Text {
                    text: view.sys.weatherReady ? view.sys.weatherPlace : (view.sys.cfg.weatherCity || (view.sys.isPt ? "Previsão do Tempo" : "Weather Forecast"))
                    color: view.sys.colFg
                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize + 2; bold: true }
                    elide: Text.ElideRight
                }

                Text {
                    text: forecast && forecast.updated 
                          ? ((view.sys.isPt ? "Atualizado às " : "Updated at ") + forecast.updated)
                          : (view.sys.isPt ? "Previsão detalhada" : "Detailed forecast")
                    color: view.sys.colMuted
                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 4 }
                }
            }

            // Spacer pushes the refresh button all the way to the opposite right corner


            Item {
                Layout.fillWidth: true
            }

            // Update button (in the opposite corner of the text)


            Rectangle {
                id: refreshBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.preferredHeight: 32
                Layout.preferredWidth: refreshRow.implicitWidth + 22
                radius: 10
                color: refreshMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 140 } }

                RowLayout {
                    id: refreshRow
                    anchors.centerIn: parent
                    spacing: 6

                    Item {
                        width: 16
                        height: 16
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: spinIcon
                            anchors.centerIn: parent
                            text: "󰑐"
                            color: view.sys.weatherBusy ? view.sys.colOn : view.sys.colMuted
                            font { family: view.sys.fontFam; pixelSize: view.sys.iconSize - 3 }
                            transformOrigin: Item.Center

                            RotationAnimation on rotation {
                                running: view.sys.weatherBusy
                                loops: Animation.Infinite
                                from: 0; to: 360; duration: 800
                                onRunningChanged: if (!running) spinIcon.rotation = 0
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: view.sys.isPt ? "Atualizar" : "Refresh"
                        color: view.sys.colMuted
                        font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3 }
                    }
                }

                MouseArea {
                    id: refreshMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: view.sys.refreshWeather()
                }
            }

            // Expand/Collapse Screen Button


            Rectangle {
                id: expandBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.preferredHeight: 32
                Layout.preferredWidth: 32
                radius: 10
                color: expandMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                border.color: view.isExpanded ? view.sys.colOn : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 140 } }

                Text {
                    anchors.centerIn: parent
                    text: view.isExpanded ? "󰊔" : "󰊓"
                    color: view.isExpanded ? view.sys.colOn : view.sys.colFg
                    font { family: view.sys.fontFam; pixelSize: 13 }
                }

                MouseArea {
                    id: expandMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        view.sys.weatherExpanded = !view.sys.weatherExpanded;
                    }
                }
            }
        }

        // --------------------------------------------- If Weather not configured


        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            radius: 14
            visible: !view.sys.weatherReady && view.sys.weatherErr.length > 0
            color: Qt.rgba(1, 0.27, 0.27, 0.08)
            border.color: Qt.rgba(1, 0.27, 0.27, 0.25)
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: view.sys.isPt ? "Configuração de Clima Necessária" : "Weather Configuration Required"
                    color: view.sys.colFg
                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize; bold: true }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: view.sys.weatherErr === "no-key" 
                          ? (view.sys.isPt ? "Chave OpenWeatherMap não configurada." : "OpenWeatherMap key not set.")
                          : (view.sys.weatherErr === "no-city" 
                              ? (view.sys.isPt ? "Cidade não configurada." : "City not set.")
                              : (view.sys.tr("Erro") + ": " + view.sys.weatherErr))
                    color: view.sys.colMuted
                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3 }
                }
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 140
                    radius: 8
                    color: view.sys.colOn
                    Text {
                        anchors.centerIn: parent
                        text: view.sys.isPt ? "Abrir Configurações" : "Open Settings"
                        color: "#ffffff"
                        font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3; bold: true }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            view.sys.settingsTab = 10;
                            view.sys.togglePage("settings");
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------- 2. Card Hero: Clima Atual
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 128
            radius: 14
            visible: view.sys.weatherReady
            color: Qt.rgba(view.sys.colFg.r, view.sys.colFg.g, view.sys.colFg.b, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // One day climate

                    Text {
                        text: view.sys.weatherGlyph
                        color: view.sys.colFg
                        font { family: view.sys.fontFam; pixelSize: 38 }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -2

                        RowLayout {
                            spacing: 6
                            Text {
                                text: view.sys.weatherTemp + "°" + view.sys.weatherUnitLetter
                                color: view.sys.colFg
                                font { family: view.sys.fontFam; pixelSize: 28; bold: true }
                            }
                            Text {
                                Layout.alignment: Qt.AlignBottom
                                Layout.bottomMargin: 4
                                text: (view.sys.isPt ? "Sensação " : "Feels ") + view.sys.weatherFeels + "°"
                                color: view.sys.colMuted
                                font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3 }
                            }
                        }

                        Text {
                            text: view.sys.weatherDesc
                            color: view.sys.colFg
                            font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 2 }
                            elide: Text.ElideRight
                        }
                    }
                }

                // Compact Details: Humidity, Wind, Pressure, Clouds (Nerd Font icons, no emoji)


                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 4
                    columnSpacing: 6

                    Repeater {
                        model: [
                            { label: view.sys.isPt ? "Umidade" : "Humidity", val: view.sys.weatherHumidity + "%", icon: "󰖎" },
                            { label: view.sys.isPt ? "Vento" : "Wind", val: view.sys.weatherWind + " " + view.sys.weatherWindUnit, icon: "󰕬" },
                            { label: view.sys.isPt ? "Pressão" : "Pressure", val: view.sys.weatherPressure + " hPa", icon: "󰈏" },
                            { label: view.sys.isPt ? "Nuvens" : "Clouds", val: view.sys.weatherClouds + "%", icon: "󰖐" }
                        ]

                        Rectangle {
                            id: detailCard
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.04)
                            border.color: Qt.rgba(1, 1, 1, 0.05)
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 3
                                    Text {
                                        text: detailCard.modelData.icon
                                        color: view.sys.colMuted
                                        font { family: view.sys.fontFam; pixelSize: 9 }
                                    }
                                    Text {
                                        text: detailCard.modelData.label
                                        color: view.sys.colMuted
                                        font { family: view.sys.fontFam; pixelSize: 8 }
                                    }
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: detailCard.modelData.val
                                    color: view.sys.colFg
                                    font { family: view.sys.fontFam; pixelSize: 11; bold: true }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------- 3. Hourly Forecast (Next 24-36h)


        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 116
            radius: 14
            visible: view.sys.weatherReady && hourly.length > 0
            color: Qt.rgba(view.sys.colFg.r, view.sys.colFg.g, view.sys.colFg.b, 0.04)
            border.color: Qt.rgba(1, 1, 1, 0.07)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: view.sys.isPt ? "Previsão por Hora" : "Hourly Forecast"
                        color: view.sys.colFg
                        font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 2; bold: true }
                    }
                    Text {
                        text: view.sys.isPt ? "(a cada 3h)" : "(3h steps)"
                        color: view.sys.colMuted
                        font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 5 }
                    }
                    Item { Layout.fillWidth: true }
                }

                // Horizontal scrollable line of hours


                Flickable {
                    id: hourlyScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: hourlyRow.implicitWidth
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: event => {
                            var step = event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.angleDelta.x;
                            if (step === 0 && (event.modifiers & Qt.ShiftModifier)) {
                                step = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y;
                            }
                            if (step !== 0) {
                                var maxH = Math.max(0, hourlyScroll.contentWidth - hourlyScroll.width);
                                hourlyScroll.contentX = Math.max(0, Math.min(maxH, hourlyScroll.contentX - step));
                            }
                        }
                    }

                    RowLayout {
                        id: hourlyRow
                        spacing: 6

                        Repeater {
                            model: view.hourly

                            Rectangle {
                                id: hourCard
                                required property var modelData
                                required property int index
                                Layout.preferredWidth: 64
                                Layout.preferredHeight: 70
                                radius: 8
                                color: hourHover.hovered ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.04)
                                border.color: hourCard.index === 0 ? view.sys.colOn : Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 130 } }

                                HoverHandler { id: hourHover }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: hourCard.index === 0 ? (view.sys.isPt ? "Agora" : "Now") : hourCard.modelData.time
                                        color: hourCard.index === 0 ? view.sys.colOn : view.sys.colMuted
                                        font { family: view.sys.fontFam; pixelSize: 9; bold: hourCard.index === 0 }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: view.glyphFor(hourCard.modelData.icon)
                                        color: view.sys.colFg
                                        font { family: view.sys.fontFam; pixelSize: 15 }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: hourCard.modelData.temp + "°"
                                        color: view.sys.colFg
                                        font { family: view.sys.fontFam; pixelSize: 11; bold: true }
                                    }

                                    // Probabilidade de chuva

                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 2
                                        visible: hourCard.modelData.pop > 0
                                        Text {
                                            text: "󰖎"
                                            color: "#60a5fa"
                                            font { family: view.sys.fontFam; pixelSize: 8 }
                                        }
                                        Text {
                                            text: hourCard.modelData.pop + "%"
                                            color: "#60a5fa"
                                            font { family: view.sys.fontFam; pixelSize: 8; bold: true }
                                        }
                                    }
                                    Item {
                                        visible: hourCard.modelData.pop === 0
                                        Layout.preferredHeight: 8
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------- 4. Weekly Forecast (With Dedicated Scroll)


        Rectangle {
            id: weeklyCard
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 180
            radius: 14
            visible: view.sys.weatherReady && daily.length > 0
            color: Qt.rgba(view.sys.colFg.r, view.sys.colFg.g, view.sys.colFg.b, 0.04)
            border.color: Qt.rgba(1, 1, 1, 0.07)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: view.sys.isPt ? "Previsão para a Semana" : "Weekly Forecast"
                        color: view.sys.colFg
                        font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 2; bold: true }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: view.sys.isPt ? "Mín / Máx" : "Min / Max"
                        color: view.sys.colMuted
                        font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 5 }
                    }
                }

                // SCROLL DEDICADO EXCLUSIVAMENTE NA SEMANA
                Flickable {
                    id: weekScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: dailyCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 3000
                    ScrollBar.vertical: SetScroll { sys: view.sys }

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: event => {
                            var step = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y;
                            if (step === 0) return;
                            var maxV = Math.max(0, weekScroll.contentHeight - weekScroll.height);
                            weekScroll.contentY = Math.max(0, Math.min(maxV, weekScroll.contentY - step));
                        }
                    }

                    ColumnLayout {
                        id: dailyCol
                        width: weekScroll.width - 8
                        spacing: 4

                        Repeater {
                            model: view.daily

                            Rectangle {
                                id: dailyRow
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                implicitHeight: 36
                                height: 36
                                radius: 8
                                color: dayHover.hovered ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
                                Behavior on color { ColorAnimation { duration: 130 } }

                                HoverHandler { id: dayHover }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    // Nome do dia e data
                                    RowLayout {
                                        Layout.preferredWidth: 100
                                        spacing: 6
                                        Text {
                                            text: dailyRow.modelData.isToday ? (view.sys.isPt ? "Hoje" : "Today") : dailyRow.modelData.day
                                            color: dailyRow.modelData.isToday ? view.sys.colOn : view.sys.colFg
                                            font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3; bold: dailyRow.modelData.isToday }
                                        }
                                        Text {
                                            text: dailyRow.modelData.date
                                            color: view.sys.colMuted
                                            font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 5 }
                                        }
                                    }

                                    // Weather icon and description


                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text {
                                            text: view.glyphFor(dailyRow.modelData.icon)
                                            color: view.sys.colFg
                                            font { family: view.sys.fontFam; pixelSize: view.sys.iconSize - 3 }
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: dailyRow.modelData.desc
                                            color: view.sys.colFg
                                            elide: Text.ElideRight
                                            font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3 }
                                        }
                                    }

                                    // Probabilidade de chuva (Nerd Font 󰖎)
                                    RowLayout {
                                        Layout.preferredWidth: 44
                                        spacing: 2
                                        visible: dailyRow.modelData.pop > 0
                                        Text {
                                            text: "󰖎"
                                            color: "#60a5fa"
                                            font { family: view.sys.fontFam; pixelSize: 9 }
                                        }
                                        Text {
                                            text: dailyRow.modelData.pop + "%"
                                            color: "#60a5fa"
                                            font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 4; bold: true }
                                        }
                                    }
                                    Item {
                                        visible: dailyRow.modelData.pop === 0
                                        Layout.preferredWidth: 44
                                    }

                                    // Visual min/max temperature bar


                                    RowLayout {
                                        Layout.preferredWidth: 105
                                        spacing: 6

                                        Text {
                                            text: dailyRow.modelData.min + "°"
                                            color: view.sys.colMuted
                                            font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3 }
                                            Layout.preferredWidth: 22
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        // Barra proporcional

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 5
                                            radius: 2.5
                                            color: Qt.rgba(1, 1, 1, 0.1)

                                            Rectangle {
                                                readonly property real range: Math.max(1, view.weekMax - view.weekMin)
                                                readonly property real startRatio: Math.max(0, Math.min(1, (dailyRow.modelData.min - view.weekMin) / range))
                                                readonly property real endRatio: Math.max(0, Math.min(1, (dailyRow.modelData.max - view.weekMin) / range))

                                                x: parent.width * startRatio
                                                width: Math.max(8, parent.width * (endRatio - startRatio))
                                                height: parent.height
                                                radius: 2.5
                                                color: dailyRow.modelData.isToday ? view.sys.colOn : Qt.rgba(0.9, 0.6, 0.2, 0.8)
                                            }
                                        }

                                        Text {
                                            text: dailyRow.modelData.max + "°"
                                            color: view.sys.colFg
                                            font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3; bold: true }
                                            Layout.preferredWidth: 22
                                            horizontalAlignment: Text.AlignLeft
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
