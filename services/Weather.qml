pragma Singleton

import QtQuick
import Quickshell
import qs.config
import "../utils/weather.js" as WeatherCodes

// Weather from Open-Meteo (free, no API key). The location comes from shell.json
// (services.weatherLocation: a city name or "lat,lon"); if that's empty, it's guessed from your
// IP address with ip-api.com. Fetched when the dashboard opens, at most every 15 minutes.
Singleton {
    id: root

    property string city: ""
    property var current: null  // { temp, feelsLike, humidity, wind, code, isDay }
    property var hourly: []     // next 12 hours: { time, temp, code }
    property var daily: []      // 7 days: { date, max, min, code }
    property string sunrise: ""
    property string sunset: ""
    property string error: ""
    property bool loading: false

    property real lastFetch: 0 // ms since epoch

    readonly property bool fahrenheit: Config.services.useFahrenheit
    readonly property string icon: current ? WeatherCodes.icon(current.code, current.isDay) : "cloud_off"
    readonly property string description: current ? WeatherCodes.description(current.code) : (error || "No weather yet")

    function formatTemp(celsius: var): string {
        if (celsius === undefined || celsius === null)
            return "--";
        return `${Math.round(fahrenheit ? celsius * 9 / 5 + 32 : celsius)}°`;
    }

    function iconFor(code: int, isDay: bool): string {
        return WeatherCodes.icon(code, isDay);
    }

    // Called when the dashboard opens
    function refreshIfStale(): void {
        if (!loading && Date.now() - lastFetch > 15 * 60 * 1000)
            refresh();
    }

    function refresh(): void {
        loading = true;
        error = "";
        const location = Config.services.weatherLocation.trim();
        if (/^-?[\d.]+\s*,\s*-?[\d.]+$/.test(location)) {
            const [lat, lon] = location.split(",").map(s => s.trim());
            city = location;
            fetchForecast(lat, lon);
        } else if (location !== "") {
            // City name → coordinates
            get(`https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(location)}&count=1&format=json`, data => {
                const place = data.results?.[0];
                if (!place)
                    return fail(`Unknown place "${location}"`);
                city = place.name;
                fetchForecast(place.latitude, place.longitude);
            });
        } else {
            // No location set: guess it from the IP address
            get("http://ip-api.com/json?fields=status,city,lat,lon", data => {
                if (data.status !== "success")
                    return fail("Couldn't find your location");
                city = data.city;
                fetchForecast(data.lat, data.lon);
            });
        }
    }

    function fetchForecast(lat: var, lon: var): void {
        const params = [`latitude=${lat}`, `longitude=${lon}`, "current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day", "hourly=temperature_2m,weather_code", "daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset", "timezone=auto", "forecast_days=7"];
        get(`https://api.open-meteo.com/v1/forecast?${params.join("&")}`, data => {
            const c = data.current;
            current = {
                temp: c.temperature_2m,
                feelsLike: c.apparent_temperature,
                humidity: c.relative_humidity_2m,
                wind: c.wind_speed_10m,
                code: c.weather_code,
                isDay: c.is_day === 1
            };

            // Hourly data starts at midnight today: skip to the current hour
            const now = data.current.time.slice(0, 13); // "2026-10-04T13"
            const start = Math.max(0, data.hourly.time.findIndex(t => t.startsWith(now)));
            hourly = data.hourly.time.slice(start, start + 12).map((t, i) => ({
                        time: t.slice(11, 16),
                        temp: data.hourly.temperature_2m[start + i],
                        code: data.hourly.weather_code[start + i]
                    }));

            daily = data.daily.time.map((d, i) => ({
                        date: new Date(d + "T12:00"),
                        max: data.daily.temperature_2m_max[i],
                        min: data.daily.temperature_2m_min[i],
                        code: data.daily.weather_code[i]
                    }));
            sunrise = data.daily.sunrise[0].slice(11, 16);
            sunset = data.daily.sunset[0].slice(11, 16);

            lastFetch = Date.now();
            loading = false;
        });
    }

    function fail(message: string): void {
        error = message;
        loading = false;
        lastFetch = Date.now(); // don't retry on every open; try again in 15 minutes
    }

    // A tiny HTTP GET that parses JSON. XMLHttpRequest is built into QML's JavaScript.
    function get(url: string, callback: var): void {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200)
                return fail(`Weather request failed (${xhr.status || "offline"})`);
            try {
                callback(JSON.parse(xhr.responseText));
            } catch (e) {
                fail(`Bad weather data: ${e}`);
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // The location was changed in shell.json: fetch again
    Connections {
        target: Config.services

        function onWeatherLocationChanged(): void {
            root.refresh();
        }
    }
}
