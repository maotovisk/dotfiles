pragma Singleton

import QtQuick
import Quickshell

// wttr.in forecast fetched straight from the QML engine (XMLHttpRequest).
Singleton {
    id: root

    property string location: "Sao Vicente BR"
    property string place: "São Vicente"

    property bool ready: false
    property var current: null               // { temp, feels, hum, wind, desc, code, night }
    property var hourly: []                  // [{ time, temp, code, rain, night }]
    property var today: null                 // { max, min, rise, set }

    // wttr code → icon / pt label / accent
    readonly property var groups: ({
        clear:  { icon: "sun",             night: "moon",       label: "Céu limpo",            accent: "peach" },
        partly: { icon: "cloud-sun",       night: "cloud-moon", label: "Parcialmente nublado", accent: "peach" },
        cloudy: { icon: "cloud",           label: "Nublado",       accent: "muted" },
        fog:    { icon: "cloud-fog",       label: "Neblina",       accent: "muted" },
        drizzle:{ icon: "cloud-drizzle",   label: "Garoa",         accent: "blue" },
        rain:   { icon: "cloud-rain",      label: "Chuva",         accent: "blue" },
        heavy:  { icon: "cloud-rain-wind", label: "Chuva forte",   accent: "blue" },
        storm:  { icon: "cloud-lightning", label: "Tempestade",    accent: "blue" },
        snow:   { icon: "cloud-snow",      label: "Neve",          accent: "mint" },
        ice:    { icon: "snowflake",       label: "Gelo",          accent: "mint" }
    })
    readonly property var codes: ({
        113: "clear", 116: "partly", 119: "cloudy", 122: "cloudy",
        143: "fog", 248: "fog", 260: "fog",
        176: "drizzle", 263: "drizzle", 266: "drizzle", 293: "drizzle", 296: "drizzle", 353: "drizzle",
        299: "rain", 302: "rain", 356: "rain",
        305: "heavy", 308: "heavy", 359: "heavy",
        200: "storm", 386: "storm", 389: "storm", 392: "storm", 395: "storm",
        179: "snow", 227: "snow", 230: "snow", 323: "snow", 326: "snow", 329: "snow",
        332: "snow", 335: "snow", 338: "snow", 368: "snow", 371: "snow",
        182: "ice", 185: "ice", 281: "ice", 284: "ice", 311: "ice", 314: "ice", 317: "ice",
        320: "ice", 350: "ice", 362: "ice", 365: "ice", 374: "ice", 377: "ice"
    })

    function info(code, night) {
        const g = groups[codes[code]] || groups.cloudy
        return { icon: night && g.night ? g.night : g.icon, label: g.label, accent: g.accent }
    }

    // "06:12 AM" → minutes since midnight
    function minutes(s) {
        const m = /(\d+):(\d+)\s*(AM|PM)/.exec(s || "")
        if (!m)
            return -1
        return (Number(m[1]) % 12 + (m[3] === "PM" ? 12 : 0)) * 60 + Number(m[2])
    }

    // "06:12 AM" → "06:12"
    function clock24(s) {
        const m = minutes(s)
        return m < 0 ? "—" : String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0")
    }

    function isNight(mins, day) {
        const rise = minutes(day.astronomy[0].sunrise)
        const set = minutes(day.astronomy[0].sunset)
        return rise >= 0 && set >= 0 && (mins < rise || mins > set)
    }

    function parse(data) {
        const now = new Date()
        const day0 = data.weather[0]
        const cur = data.current_condition[0]

        current = {
            temp: Number(cur.temp_C),
            feels: Number(cur.FeelsLikeC),
            hum: Number(cur.humidity),
            wind: Number(cur.windspeedKmph),
            desc: (cur.lang_pt && cur.lang_pt[0].value) || cur.weatherDesc[0].value,
            code: Number(cur.weatherCode),
            night: isNight(now.getHours() * 60 + now.getMinutes(), day0)
        }

        const hours = []
        for (let d = 0; d < 2 && hours.length < 8; d++) {
            const day = data.weather[d]
            for (const h of day.hourly) {
                const hh = Number(h.time) / 100
                if (d === 0 && hh <= now.getHours())
                    continue
                hours.push({
                    time: String(hh).padStart(2, "0") + "h",
                    temp: Number(h.tempC),
                    code: Number(h.weatherCode),
                    rain: Number(h.chanceofrain),
                    night: isNight(hh * 60, day)
                })
                if (hours.length >= 8)
                    break
            }
        }
        hourly = hours

        today = {
            max: Number(day0.maxtempC),
            min: Number(day0.mintempC),
            rise: day0.astronomy[0].sunrise,
            set: day0.astronomy[0].sunset
        }
        ready = true
    }

    function fetch() {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            try {
                if (xhr.status !== 200)
                    throw new Error("HTTP " + xhr.status)
                parse(JSON.parse(xhr.responseText))
                poll.interval = 30 * 60 * 1000
            } catch (e) {
                console.warn("weather:", e)
                poll.interval = 2 * 60 * 1000       // retry sooner after a failure
            }
            poll.restart()
        }
        xhr.open("GET", "https://wttr.in/" + encodeURIComponent(location) + "?format=j1&lang=pt")
        xhr.send()
    }

    Timer {
        id: poll
        interval: 30 * 60 * 1000
        running: true
        onTriggered: root.fetch()
    }

    Component.onCompleted: fetch()
}
