pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon. `list` is the history shown in the center; `toasts`
// are lightweight snapshots so a toast can finish its exit animation even
// after the underlying notification object is gone.
Singleton {
    id: root

    property bool dnd: false
    property var toasts: []
    property var times: ({})                 // notification id → arrival ms

    readonly property var list: server.trackedNotifications.values
    readonly property int count: list.length

    signal clearing()                        // cards play their exit, then clear() runs

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true
            const t = Object.assign({}, root.times)
            t[n.id] = Date.now()
            root.times = t

            if (root.dnd && n.urgency !== NotificationUrgency.Critical)
                return
            root.toasts = root.toasts.concat([{
                n: n,
                id: n.id,
                appName: n.appName,
                appIcon: n.appIcon,
                image: n.image,
                summary: n.summary,
                body: n.body,
                critical: n.urgency === NotificationUrgency.Critical,
                timeout: n.expireTimeout > 0 ? n.expireTimeout : 7000
            }]).slice(-4)
        }
    }

    function dropToast(entry) {
        toasts = toasts.filter(t => t !== entry)
    }

    function clear() {
        const all = list.slice()
        for (const n of all)
            n.dismiss()
        toasts = []
    }

    function clearAnimated() {
        if (count === 0)
            return
        // cards leave staggered: i*40ms + 220ms slide + 220ms collapse; sweep
        // whatever's left (off-screen cards) after the last visible one
        clearTimer.interval = 480 + Math.min(count, 10) * 40
        clearing()
        clearTimer.restart()
    }

    Timer {
        id: clearTimer
        onTriggered: root.clear()
    }

    function ago(id, now) {
        const t = times[id]
        if (!t)
            return ""
        const m = Math.floor((now - t) / 60000)
        return m < 1 ? "agora" : m < 60 ? m + " min" : Math.floor(m / 60) + " h"
    }

    function iconFor(appIcon, image) {
        if (image)
            return image
        return Ui.icon(appIcon)
    }
}
