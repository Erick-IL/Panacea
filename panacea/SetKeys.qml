import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io

// Shortcut keys. Opens as a separate window via Super + /, not as a section
// settings: this is a reference book that is accessed in the middle of work, and a sidebar
// with a list of sections it would only get in the way.
//
// Edits accumulate in the draft and go to Hyprland using “Apply”. Not right away
// we use it on purpose: a half-empty combination written down while typing could
// to take away the key from the one with whom it is controlled.
ColumnLayout {
    id: page

    property var sys

    // ---------------------------------------------------- draft combinations
    property var bindDraft: ({})
    property int bindRev: 0          // counter so that the bindings are reread
    readonly property bool dirty: {
        bindRev;
        for (var id in page.bindDraft) return true;
        return false;
    }

    function bindCombo(id) {
        bindRev;                     // dependency for recalculation
        var raw = page.bindDraft[id] !== undefined
                  ? String(page.bindDraft[id]) : String(page.sys.cfg["bind_" + id] || "");
        return page.prettyCombo(raw);
    }
    function bindRaw(id) {
        bindRev;
        return page.bindDraft[id] !== undefined
               ? String(page.bindDraft[id]) : String(page.sys.cfg["bind_" + id] || "");
    }

    // Hyprland knows the keys by name (slash, comma, period...), and to a person
    // the sign itself is more familiar. We show the sign, the name is in the settings.
    readonly property var keySigns: ({
        slash: "/", backslash: "\\", comma: ",", period: ".",
        semicolon: ";", apostrophe: "'", grave: "`", minus: "-", equal: "=",
        bracketleft: "[", bracketright: "]", space: "Space", delete: "Del"
    })
    function prettyCombo(raw) {
        var parts = String(raw).split("+");
        for (var i = 0; i < parts.length; i++) {
            var k = parts[i].trim();
            var sign = page.keySigns[k.toLowerCase()];
            parts[i] = sign !== undefined ? sign : k;
        }
        return parts.join(" + ");
    }
    function bindChanged(id) {
        bindRev;
        return page.bindDraft[id] !== undefined;
    }
    function setBind(id, combo) {
        page.bindDraft[id] = combo;
        page.bindRev++;
    }
    function clearBind(id) { page.setBind(id, ""); }
    function discardBinds() { page.bindDraft = ({}); page.bindRev++; }

    function applyBinds() {
        var touched = false;
        for (var id in page.bindDraft) {
            page.sys.cfg["bind_" + id] = page.bindDraft[id];
            touched = true;
        }
        page.discardBinds();
        // applyBinds itself saves the settings and rebuilds binds_data.lua
        if (touched) page.sys.applyBinds();
    }
    // “Reset” returns the factory combinations, rather than simply undoing the edits:
    // We put everything that now differs from the default values into the draft.
    function resetBinds() {
        var o = {};
        var def = page.sys.defaultBinds;
        for (var id in def) {
            if (String(page.sys.cfg["bind_" + id] || "") !== def[id]) o[id] = def[id];
        }
        page.bindDraft = o;
        page.bindRev++;
    }

    // ------------------------------------------------------------- capture
    property string capturingKey: ""

    // What has already been pressed right now is shown in the line as you type.
    property bool  mMeta:  false
    property bool  mCtrl:  false
    property bool  mAlt:   false
    property bool  mShift: false
    property string pendingName: ""

    readonly property string capturePreview: {
        var m = [];
        if (mMeta)  m.push("SUPER");
        if (mCtrl)  m.push("CTRL");
        if (mAlt)   m.push("ALT");
        if (mShift) m.push("SHIFT");
        if (pendingName.length) m.push(pendingName);
        return m.join(" + ");
    }

    // While the capture is in progress, Hyprland is moved to an empty submap: otherwise, press
    // worked as an already existing combination and did not reach the panel.
    Process { id: pCapture }
    function grabKeys(on) {
        // Restarting explicitly: assigning a command to a running Process
        // does not take effect, and the next entry into the submap silently disappears.
        pCapture.running = false;
        pCapture.command = ["sh", "-c",
            page.sys.scriptDir + "/capture.sh " + (on ? "on" : "off")];
        pCapture.running = true;
    }

    function clearHeld() {
        page.mMeta = false; page.mCtrl = false; page.mAlt = false; page.mShift = false;
        page.pendingName = "";
    }

    function startCapture(key) {
        page.capturingKey = key;
        page.clearHeld();
        page.forceActiveFocus();
        page.grabKeys(true);
        captureTimeout.restart();
    }
    function stopCapture() {
        if (page.capturingKey.length === 0) return;   // already stopped
        page.capturingKey = "";
        page.clearHeld();
        captureTimeout.stop();
        page.grabKeys(false);
    }

    // insurance: do not leave the system without hotkeys
    Timer {
        id: captureTimeout
        interval: 8000
        onTriggered: page.stopCapture()
    }

    Connections {
        target: page.sys
        // comes from capture.sh off; if the grip has already been removed, we do nothing
        function onCancelCaptureRequested() {
            if (page.capturingKey.length) page.stopCapture();
        }
    }

    readonly property var modKeys: [
        Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_AltGr,
        Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_CapsLock
    ]

    function isMeta(k)  { return k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R; }
    function isCtrl(k)  { return k === Qt.Key_Control; }
    function isAlt(k)   { return k === Qt.Key_Alt || k === Qt.Key_AltGr; }
    function isShift(k) { return k === Qt.Key_Shift; }

    // Name of a regular key in Hyprland terms
    function keyName(k) {
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F12) return "F" + (k - Qt.Key_F1 + 1);
        switch (k) {
            case Qt.Key_Space:  return "Space";
            case Qt.Key_Return:
            case Qt.Key_Enter:  return "Return";
            case Qt.Key_Tab:    return "Tab";
            case Qt.Key_Left:   return "left";
            case Qt.Key_Right:  return "right";
            case Qt.Key_Up:     return "up";
            case Qt.Key_Down:   return "down";
            case Qt.Key_Comma:  return "comma";
            case Qt.Key_Period: return "period";
            case Qt.Key_Slash:  return "slash";
            case Qt.Key_Minus:  return "minus";
            case Qt.Key_Equal:  return "equal";
            case Qt.Key_BracketLeft:  return "bracketleft";
            case Qt.Key_BracketRight: return "bracketright";
            case Qt.Key_Semicolon:    return "semicolon";
            case Qt.Key_Apostrophe:   return "apostrophe";
            case Qt.Key_Backslash:    return "backslash";
            case Qt.Key_Delete:       return "delete";
            case Qt.Key_Insert:       return "insert";
            case Qt.Key_Home:         return "home";
            case Qt.Key_End:          return "end";
            case Qt.Key_PageUp:       return "Page_Up";
            case Qt.Key_PageDown:     return "Page_Down";
            case Qt.Key_Backspace:    return "BackSpace";
            case Qt.Key_Print:        return "Print";
            case Qt.Key_Pause:        return "Pause";
            case Qt.Key_Menu:         return "Menu";
        }
        return "";
    }

    focus: true

    Keys.onPressed: event => {
        if (page.capturingKey.length === 0) {
            if (event.key === Qt.Key_Escape) {
                page.sys.keysWindowOpen = false;
                event.accepted = true;
                return;
            }
            // Super + / closes the window with the same combination that opened it. Before
            // Hyprland it does not reach: while the window is on the screen, the layer holds
            // the keyboard is exclusive, and compositor binding does not work -
            // so we catch the combination here.
            if (event.key === Qt.Key_Slash && (event.modifiers & Qt.MetaModifier)) {
                page.sys.keysWindowOpen = false;
                event.accepted = true;
            }
            return;
        }
        event.accepted = true;
        captureTimeout.restart();

        if (event.key === Qt.Key_Escape) { page.stopCapture(); return; }

        // We mark modifiers immediately - they appear in the line as you click.
        // Qt does not yet show it in the event of the modifier itself, so
        // We look at both the key code and the mask.
        page.mMeta  = page.mMeta  || page.isMeta(event.key)  || (event.modifiers & Qt.MetaModifier)    !== 0;
        page.mCtrl  = page.mCtrl  || page.isCtrl(event.key)  || (event.modifiers & Qt.ControlModifier) !== 0;
        page.mAlt   = page.mAlt   || page.isAlt(event.key)   || (event.modifiers & Qt.AltModifier)     !== 0;
        page.mShift = page.mShift || page.isShift(event.key) || (event.modifiers & Qt.ShiftModifier)   !== 0;

        if (page.modKeys.indexOf(event.key) >= 0) return;   // waiting for a real key

        var n = page.keyName(event.key);
        if (n.length === 0) return;
        page.pendingName = n;

        // the combination is collected - save it as a draft, it will be applied by “Apply”
        var target = page.capturingKey;
        var combo = page.capturePreview;
        page.stopCapture();
        page.setBind(target, combo);
    }

    Keys.onReleased: event => {
        if (page.capturingKey.length === 0) return;
        event.accepted = true;
        if (page.isMeta(event.key))  page.mMeta = false;
        if (page.isCtrl(event.key))  page.mCtrl = false;
        if (page.isAlt(event.key))   page.mAlt = false;
        if (page.isShift(event.key)) page.mShift = false;
    }

    Component.onCompleted: page.forceActiveFocus()
    Component.onDestruction: {
        // do not leave the system without hotkeys
        if (page.capturingKey.length) page.grabKeys(false);
    }

    // ------------------------------------------------------------ lines
    component BindRow: RowLayout {
        id: brow
        property string bindId: ""
        property string label: ""
        property bool manual: false
        readonly property bool capturing: page.capturingKey === brow.bindId
        readonly property string combo: page.bindCombo(brow.bindId)
        readonly property bool edited: page.bindChanged(brow.bindId)

<<<<<<< HEAD
        // The rows divide the column height among themselves: the card takes up almost
        // the entire screen, and without stretching the list would be strayed to the top edge,
        // leaving an empty field underneath. The ceiling is needed so that it is high
        // on the screen, the lines did not disperse into a sparse list.
=======
        // Keep each shortcut at a consistent height in the scrollable list.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        spacing: 14

        Rectangle {
            id: box
            Layout.preferredWidth: brow.manual ? 220 : 176
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            radius: 9
            color: brow.capturing
                   ? Qt.rgba(page.sys.colOn.r, page.sys.colOn.g, page.sys.colOn.b, 0.20)
                   : (bMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.07))
            border.color: brow.capturing ? page.sys.colOn : page.sys.colLine
            border.width: 1
            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            SequentialAnimation {
                running: brow.capturing
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { target: box; property: "opacity"; to: 0.45; duration: 520 }
                NumberAnimation { target: box; property: "opacity"; to: 1.0;  duration: 520 }
            }

            Text {
                visible: !brow.manual
                anchors.centerIn: parent
                // during capture we show what has already been pressed
                text: brow.capturing
                      ? (page.capturePreview.length ? page.capturePreview
                                                    : page.sys.tr("Нажмите сочетание…"))
                      : (brow.combo.length ? brow.combo : "—")
                color: brow.combo.length || brow.capturing ? page.sys.colFg : page.sys.colMuted
                font { family: page.sys.fontFam; pixelSize: page.sys.fontSize - 4; bold: true }
            }

<<<<<<< HEAD
            // dot-mark: combination changed but not yet applied
=======
            TextField {
                id: manualCombo
                visible: brow.manual
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                text: page.bindRaw(brow.bindId)
                color: page.sys.colFg
                selectByMouse: true
                background: null
                font { family: page.sys.fontFam; pixelSize: page.sys.fontSize - 4 }
                onEditingFinished: if (text.trim() !== page.bindRaw(brow.bindId)) page.setBind(brow.bindId, text.trim())
            }

            Connections {
                target: page
                function onBindRevChanged() { if (brow.manual) manualCombo.text = page.bindRaw(brow.bindId); }
            }

            // точка-отметка: сочетание изменено, но ещё не применено
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
            Rectangle {
                width: 6; height: 6; radius: 3
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
                visible: brow.edited
                color: page.sys.colOk
            }

            MouseArea {
                id: bMa
                anchors.fill: parent
                enabled: !brow.manual
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.startCapture(brow.bindId)
            }
        }

        Text {
            Layout.fillWidth: true
            text: brow.label
            color: page.sys.colMuted
            elide: Text.ElideRight
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 2 }
        }

        Text {
            text: "×"
            visible: brow.combo.length > 0
            color: cMa.containsMouse ? page.sys.colCrit : page.sys.colMuted
            font { family: page.sys.fontFam; pixelSize: page.sys.fontSize + 2 }
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea {
                id: cMa
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.clearBind(brow.bindId)
            }
        }
    }


    // Group title. Not SetLabel: that one is designed for a settings card, but
    // here the columns are a continuous list, and it needs an indent at the top.
    component Head: Text {
        Layout.fillWidth: true
        Layout.topMargin: 8
        color: page.sys.colMuted
        font {
            family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4
            bold: true; capitalization: Font.AllUppercase; letterSpacing: 1
        }
    }

    // =========================================================== layout
    // Only what can be reassigned: Hyprland's permanent combinations
    // (tables by numbers, focus with arrows, mouse) are removed from here - in the window where
    // every row is clickable, there is nothing to show rows that are not clickable.
    //
<<<<<<< HEAD
    // There is no scrolling: two columns of fifteen lines each fit entirely, and
    // the lines are stretched along the height of the card, rather than being pressed to the top edge.
=======
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
    Layout.fillWidth: true
    spacing: 10

    Text {
        Layout.fillWidth: true
        text: page.sys.tr("Нажмите на сочетание, чтобы изменить. × убирает клавишу.")
        color: Qt.rgba(1, 1, 1, 0.32)
        font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
    }

    Flickable {
        id: bindScroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: bindColumns.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: SetScroll { sys: page.sys }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                var max = Math.max(0, bindScroll.contentHeight - bindScroll.height);
                bindScroll.contentY = Math.max(0, Math.min(max, bindScroll.contentY - event.angleDelta.y));
            }
        }

    RowLayout {
        id: bindColumns
        width: bindScroll.width - 12
        spacing: 26

        ColumnLayout {
            Layout.fillWidth: true
<<<<<<< HEAD
            Layout.fillHeight: true
            Layout.preferredWidth: 1     // divide equally, not according to content
=======
            Layout.preferredWidth: 1     // делим поровну, а не по содержимому
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
            spacing: 9

            Head { text: page.sys.tr("Пилюля") }
            BindRow { bindId: "pillLauncher";  label: page.sys.tr("Лаунчер приложений") }
            BindRow { bindId: "overview";      label: page.sys.tr("Обзор столов") }
            BindRow { bindId: "pillControls";  label: page.sys.tr("Wi-Fi, Bluetooth, питание") }
            BindRow { bindId: "pillSettings";  label: page.sys.tr("Эти настройки") }
            BindRow { bindId: "pillShortcuts"; label: page.sys.tr("Быстрые клавиши") }
            BindRow { bindId: "pillWifi";      label: page.sys.tr("Список сетей") }
            BindRow { bindId: "pillBt";        label: page.sys.tr("Устройства Bluetooth") }
            BindRow { bindId: "pillClip";      label: page.sys.tr("Буфер обмена") }
            BindRow { bindId: "pillPower";     label: page.sys.tr("Меню питания") }
            BindRow { bindId: "pillRecord";    label: page.sys.tr("Запись экрана") }
            BindRow { bindId: "voxDictate";    label: page.sys.tr("Голос в текст"); manual: true }
            BindRow { bindId: "pillNotif";     label: page.sys.tr("Уведомления") }
            BindRow { bindId: "fileManager";   label: page.sys.tr("Проводник") }
            BindRow { bindId: "pillVault";     label: page.sys.tr("Менеджер паролей") }

            Head { text: page.sys.tr("Система") }
            BindRow { bindId: "lockScreen"; label: page.sys.tr("Заблокировать экран") }
            BindRow { bindId: "screenOff";  label: page.sys.tr("Погасить экран") }
            BindRow { bindId: "exitHypr";   label: page.sys.tr("Выйти из Hyprland") }
            BindRow { bindId: "themeSwitch"; label: page.sys.tr("Смена темы") }

            Head { text: page.sys.tr("Рабочие столы") }
            Repeater {
                model: 10
                BindRow {
                    bindId: "workspace" + (index + 1)
                    label: page.sys.tr("Перейти на стол") + " " + (index + 1)
                }
            }
            BindRow { bindId: "workspaceNext"; label: page.sys.tr("Следующий рабочий стол"); manual: true }
            BindRow { bindId: "workspacePrevious"; label: page.sys.tr("Предыдущий рабочий стол"); manual: true }

            Head { text: page.sys.tr("Мультимедиа-клавиши") }
            BindRow { bindId: "volumeUp"; label: page.sys.tr("Увеличить громкость"); manual: true }
            BindRow { bindId: "volumeDown"; label: page.sys.tr("Уменьшить громкость"); manual: true }
            BindRow { bindId: "volumeMute"; label: page.sys.tr("Выключить звук"); manual: true }
            BindRow { bindId: "micMute"; label: page.sys.tr("Выключить микрофон"); manual: true }
            BindRow { bindId: "brightnessUp"; label: page.sys.tr("Увеличить яркость"); manual: true }
            BindRow { bindId: "brightnessDown"; label: page.sys.tr("Уменьшить яркость"); manual: true }
            BindRow { bindId: "mediaNext"; label: page.sys.tr("Следующий трек"); manual: true }
            BindRow { bindId: "mediaPrevious"; label: page.sys.tr("Предыдущий трек"); manual: true }
            BindRow { bindId: "mediaPlay"; label: page.sys.tr("Воспроизвести"); manual: true }
            BindRow { bindId: "mediaPause"; label: page.sys.tr("Пауза"); manual: true }
            BindRow { bindId: "mediaNextAlt"; label: page.sys.tr("Следующий трек (запасная)"); manual: true }
            BindRow { bindId: "mediaPreviousAlt"; label: page.sys.tr("Предыдущий трек (запасная)"); manual: true }

            Head { text: page.sys.tr("Крышка ноутбука") }
            BindRow { bindId: "lidOn"; label: page.sys.tr("Закрытие крышки"); manual: true }
            BindRow { bindId: "lidOff"; label: page.sys.tr("Открытие крышки"); manual: true }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            spacing: 9

            Head { text: page.sys.tr("Приложения") }
            BindRow { bindId: "terminal";       label: page.sys.tr("Терминал") }
            BindRow { bindId: "terminalAlt";    label: page.sys.tr("Терминал (запасная)") }
            BindRow { bindId: "browser";        label: page.sys.tr("Браузер") }
            BindRow { bindId: "fileManagerTui"; label: page.sys.tr("Файлы в терминале") }
            BindRow { bindId: "notes";          label: page.sys.tr("Заметки") }
            BindRow { bindId: "screenshot";     label: page.sys.tr("Скриншот области") }

            Head { text: page.sys.tr("Окна") }
            BindRow { bindId: "closeWindow"; label: page.sys.tr("Закрыть окно") }
            BindRow { bindId: "fullscreen";  label: page.sys.tr("Во весь экран") }
            BindRow { bindId: "floatToggle"; label: page.sys.tr("Плавающее окно") }
            BindRow { bindId: "floatCenter"; label: page.sys.tr("Плавающее по центру") }
            BindRow { bindId: "toggleSplit"; label: page.sys.tr("Сменить направление сплита") }
            BindRow { bindId: "closeMouse"; label: page.sys.tr("Закрыть средней кнопкой"); manual: true }
            BindRow { bindId: "dragWindow"; label: page.sys.tr("Перетащить окно"); manual: true }
            BindRow { bindId: "resizeWindowMouse"; label: page.sys.tr("Размер окна мышью"); manual: true }

            Head { text: page.sys.tr("Навигация по окнам") }
            BindRow { bindId: "focusLeft"; label: page.sys.tr("Фокус влево") }
            BindRow { bindId: "focusRight"; label: page.sys.tr("Фокус вправо") }
            BindRow { bindId: "focusUp"; label: page.sys.tr("Фокус вверх") }
            BindRow { bindId: "focusDown"; label: page.sys.tr("Фокус вниз") }
            BindRow { bindId: "moveLeft"; label: page.sys.tr("Переместить окно влево") }
            BindRow { bindId: "moveRight"; label: page.sys.tr("Переместить окно вправо") }
            BindRow { bindId: "moveUp"; label: page.sys.tr("Переместить окно вверх") }
            BindRow { bindId: "moveDown"; label: page.sys.tr("Переместить окно вниз") }
            BindRow { bindId: "resizeLeft"; label: page.sys.tr("Уменьшить ширину") }
            BindRow { bindId: "resizeRight"; label: page.sys.tr("Увеличить ширину") }
            BindRow { bindId: "resizeUp"; label: page.sys.tr("Уменьшить высоту") }
            BindRow { bindId: "resizeDown"; label: page.sys.tr("Увеличить высоту") }

            Head { text: page.sys.tr("Рабочие столы") }
            BindRow { bindId: "emptyWorkspace";   label: page.sys.tr("На пустой стол") }
            Repeater {
                model: 10
                BindRow {
                    bindId: "moveWorkspace" + (index + 1)
                    label: page.sys.tr("Перенести окно на стол") + " " + (index + 1)
                }
            }
            BindRow { bindId: "specialWorkspace"; label: page.sys.tr("Спецстол") }
            BindRow { bindId: "packWorkspaces";   label: page.sys.tr("Собрать столы подряд") }
        }
    }
    }

    // ------------------------------------------------------------- buttons
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        spacing: 12

        Item { Layout.fillWidth: true }

        SetButton {
            sys: page.sys
            text: page.sys.tr("Сбросить")
            onClicked: page.resetBinds()
        }

        SetButton {
            sys: page.sys
            text: page.sys.tr("Применить")
            primary: true
            enabled: page.dirty
            onClicked: page.applyBinds()
        }
    }
}
