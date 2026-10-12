import QtQuick
import QtQuick.Layouts
import Quickshell.Io

<<<<<<< HEAD
// Appearance. The theme sets the palette for the entire shell and nothing else
// depends: the wallpaper changes on its own, the color on its own. Theme "Default"
// left as it was, so manually selected text color and accent
// continue to work on it.
=======
// Appearance. Оформление в стиле Nothing OS: минималистичная монохромная
// палитра, фирменные точечные шрифты, виджеты рабочего стола и системные звуки.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
ColumnLayout {
    id: page

    property var sys
    property bool detailsOpen: false
    property var localeOptions: [{ id: "en", text: "English" }, { id: "ru", text: "Русский" }, { id: "tr", text: "Türkçe" }]

    Process {
        command: [page.sys.scriptDir + "/locale.sh", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var options = [];
                var lines = String(text).trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("|");
                    if (parts.length !== 2 || !parts[0].length) continue;
                    var locale = Qt.locale(parts[0]);
                    var nativeName = locale && locale.name !== "C" ? locale.nativeLanguageName : "";
                    options.push({ id: parts[0], text: nativeName ? nativeName + " · " + parts[0] : parts[1] });
                }
                if (options.length) page.localeOptions = options;
            }
        }
    }
    Layout.fillWidth: true
    spacing: 12

    // ------------------------------------------------------------- language
    // It comes first: they start with language, not end with it.
    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Язык") }

        SetPick {
            sys: page.sys
            label: page.sys.tr("Язык системы")
            options: page.localeOptions
            searchable: true
            value: page.sys.cfg.lang
            onPicked: id => page.sys.setLang(id)
        }

        Text {
            Layout.fillWidth: true
            text: page.sys.sysLangPending
                  ? page.sys.tr("Меняем язык системы…")
                  : (!page.sys.systemLocaleMatches
                     ? page.sys.tr("Оболочка уже на новом языке. Приложения и меню читают язык при входе — они переключатся после перезахода.")
                     : page.sys.tr("Оболочка переключается сразу. Приложения и меню — после перезахода: язык они читают при входе."))
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
<<<<<<< HEAD
    }

    // ------------------------------------------------------------- topic
    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Тема") }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: page.sys.themes

                Rectangle {
                    id: swatch
                    required property var modelData
                    readonly property bool active: page.sys.cfg.themeId === swatch.modelData.id

                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 14
                    color: swatch.modelData.bg
                    border.width: swatch.active ? 2 : 1
                    border.color: swatch.active
                                  ? swatch.modelData.on
                                  : Qt.rgba(page.sys.colFg.r, page.sys.colFg.g, page.sys.colFg.b,
                                            swatchMa.containsMouse ? 0.30 : 0.12)
                    Behavior on border.color { ColorAnimation { duration: page.sys.animFade } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 9

                        // three circles: accent, text, alarming color - according to them
                        // the topic is recognized faster than by its title
                        Repeater {
                            model: [swatch.modelData.on, swatch.modelData.fg, swatch.modelData.crit]
                            Rectangle {
                                required property var modelData
                                width: 14; height: 14; radius: 7
                                color: modelData
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 9
                        text: swatch.modelData.name
                        color: swatch.modelData.fg
                        font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
                    }

                    MouseArea {
                        id: swatchMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { page.sys.cfg.themeId = swatch.modelData.id; page.sys.saveCfg(); }
                    }
                }
            }
        }

=======
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
        Text {
            Layout.fillWidth: true
            visible: ["en", "ru", "tr"].indexOf(page.sys.languageCode) < 0
            text: page.sys.tr("Для этого языка нет перевода интерфейса Panacea. Пока используется английский; запросите перевод через issue на GitHub.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
    }

    // ------------------------------------------------------------- виджеты
    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Настольные виджеты") }

<<<<<<< HEAD
        // The toggle switch is here, next to the topic selection: cards are part of the look,
        // not a separate service.
=======
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
        SetToggle {
            sys: page.sys
            label: page.sys.tr("Виджеты на рабочем столе")
            sub: page.sys.tr("Карточки Nothing OS на обоях: дата, часы, погода, системный монитор и шкала прогресса. Клик по карточкам переключает режимы.")
            on: page.sys.cfg.featWidgets
            onToggled: v => { page.sys.cfg.featWidgets = v; page.sys.saveCfg(); }
        }

        SetSelect {
            visible: page.sys.cfg.featWidgets && page.detailsOpen
            sys: page.sys
            label: page.sys.tr("Стиль часов")
            options: [
                { id: "analog", text: page.sys.tr("Аналоговые Nothing") },
                { id: "digital", text: page.sys.tr("Цифровые точечные") }
            ]
            value: page.sys.cfg.widgetClockMode || "analog"
            onPicked: id => { page.sys.cfg.widgetClockMode = id; page.sys.saveCfg(); }
        }

        SetSelect {
            visible: page.sys.cfg.featWidgets && page.detailsOpen
            sys: page.sys
            label: page.sys.tr("Информационный блок")
            options: [
                { id: "weather", text: page.sys.tr("Погода (ветер и влажность)") },
                { id: "system", text: page.sys.tr("Система (RAM и SSD)") }
            ]
            value: page.sys.cfg.widgetRightMode || "weather"
            onPicked: id => { page.sys.cfg.widgetRightMode = id; page.sys.saveCfg(); }
        }

        SetSelect {
            visible: page.sys.cfg.featWidgets && page.detailsOpen
            sys: page.sys
            label: page.sys.tr("Шкала прогресса")
            options: [
                { id: "day", text: page.sys.tr("Прогресс дня (24 часа)") },
                { id: "year", text: page.sys.tr("Прогресс года (365 дней)") }
            ]
            value: page.sys.cfg.widgetProgressMode || "day"
            onPicked: id => { page.sys.cfg.widgetProgressMode = id; page.sys.saveCfg(); }
        }

        Text {
            Layout.fillWidth: true
            visible: page.sys.cfg.featWidgets
                     && page.sys.cfg.weatherKey.length === 0
            text: page.sys.tr("Впишите ключ и город во вкладке Weather, иначе карточка погоды останется пустой.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
    }

<<<<<<< HEAD
        // Terminal transparency. Here, not in a separate tab: this is one
        // handle, and it stands next to the rest of the exterior.
=======
    SetButton {
        sys: page.sys
        text: page.detailsOpen ? page.sys.tr("Скрыть подробности") : page.sys.tr("Подробные настройки")
        onClicked: page.detailsOpen = !page.detailsOpen
    }

    // ------------------------------------------------------------- оформление
    SetCard {
        sys: page.sys
        visible: page.detailsOpen

        SetLabel { sys: page.sys; text: page.sys.tr("Оформление") }

        SetSlider {
            sys: page.sys
            label: page.sys.tr("Приглушённый текст")
            from: 0.2; to: 1.0; step: 0.05
            decimals: 2
            value: page.sys.cfg.mutedAlpha
            onMoved: v => { page.sys.cfg.mutedAlpha = v; page.sys.saveCfg(); }
        }

        // Прозрачность терминала
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
        SetSlider {
            sys: page.sys
            label: page.sys.tr("Прозрачность терминала")
            from: 0.5; to: 1.0; step: 0.01
            decimals: 2
            value: page.sys.cfg.termAlpha
            onMoved: v => {
                page.sys.cfg.termAlpha = v;
                page.sys.saveCfg();
                page.sys.applyTermAlpha();
            }
        }

        Text {
            Layout.fillWidth: true
            text: page.sys.tr("1.00 — сплошной фон. Действует сразу; если нет — терминал держит свои настройки с прошлого входа, и его серверу нужен перезапуск.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            SetButton {
                sys: page.sys
                text: page.sys.tr("Перезапустить терминал")
                onClicked: page.sys.restartTerminalServer()
            }
        }

        Text {
            Layout.fillWidth: true
            text: page.sys.tr("Открытые окна терминала при этом закроются: они работают от того же сервера.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
    }

    // ------------------------------------------------------------- fonts
    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Шрифты") }

        SetSlider {
            sys: page.sys
            label: page.sys.tr("Размер текста")
            from: 10; to: 24; step: 1
            value: page.sys.cfg.fontSize
            suffix: "px"
            onMoved: v => { page.sys.cfg.fontSize = v; page.sys.saveCfg(); }
        }

        SetSlider {
            sys: page.sys
            label: page.sys.tr("Размер иконок")
            visible: page.detailsOpen
            from: 12; to: 28; step: 1
            value: page.sys.cfg.iconSize
            suffix: "px"
            onMoved: v => { page.sys.cfg.iconSize = v; page.sys.saveCfg(); }
        }

        SetPick {
            sys: page.sys
            label: page.sys.tr("Шрифт текста")
            visible: page.detailsOpen
            options: page.sys.fontList
            value: page.sys.cfg.fontBody || page.sys.cfg.fontFam
            onPicked: id => { page.sys.cfg.fontBody = id; page.sys.saveCfg(); }
        }

        SetPick {
            sys: page.sys
            label: page.sys.tr("Шрифт заголовков")
            visible: page.detailsOpen
            options: page.sys.fontList
            value: page.sys.cfg.fontDisplay || page.sys.cfg.fontFam
            onPicked: id => { page.sys.cfg.fontDisplay = id; page.sys.saveCfg(); }
        }

        // Icon font separately: you can put any signatures, but icons
        // draws only the Nerd Font, and you cannot change it along with the text one.
        SetPick {
            sys: page.sys
            label: page.sys.tr("Шрифт значков")
            visible: page.detailsOpen
            options: page.sys.fontList
            value: page.sys.cfg.fontFam
            onPicked: id => { page.sys.cfg.fontFam = id; page.sys.saveCfg(); }
        }
    }

<<<<<<< HEAD
    // ------------------------------------------------------------- geometry
=======
    // ------------------------------------------------------------- звуки
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Звуки") }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("Звуковые эффекты системы")
            sub: page.sys.tr("Зарядка, подключение Bluetooth, скриншоты, голосовой ввод")
            on: page.sys.cfg.uiSounds !== false
            onToggled: value => {
                page.sys.cfg.uiSounds = value;
                page.sys.saveCfg();
                if (value) page.sys.playSound("connect");
            }
        }

        // Кнопки предпрослушивания звуков
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8
            visible: page.sys.cfg.uiSounds !== false && page.detailsOpen

            Repeater {
                model: [
                    { id: "charge",      label: page.sys.tr("Зарядка"),     icon: "󰂄" },
                    { id: "connect",     label: "Bluetooth",               icon: "󰂯" },
                    { id: "disconnect",  label: page.sys.tr("Отключение"),  icon: "󰂲" },
                    { id: "screenshot",  label: page.sys.tr("Скриншот"),    icon: "󰄀" },
                    { id: "voice_start", label: page.sys.tr("Голос"),       icon: "󰍬" }
                ]

                Rectangle {
                    id: sndBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: sndMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: sndMa.containsMouse ? page.sys.colOn : page.sys.colLine
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: modelData.icon
                            color: sndMa.containsMouse ? page.sys.colOn : page.sys.colMuted
                            font { family: page.sys.fontFam; pixelSize: 13 }
                        }
                        Text {
                            text: modelData.label
                            color: sndMa.containsMouse ? page.sys.colFg : page.sys.colMuted
                            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: sndMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.sys.playSound(modelData.id)
                    }
                }
            }
        }
    }
}
