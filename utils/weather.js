.pragma library

// Open-Meteo reports the weather as a WMO code (https://open-meteo.com/en/docs, "WMO Weather
// interpretation codes"). These turn a code into a Material Symbols icon and a description.

function icon(code, isDay = true) {
    if (code <= 1)
        return isDay ? "clear_day" : "clear_night";
    if (code === 2)
        return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
    if (code === 3)
        return "cloud";
    if (code === 45 || code === 48)
        return "foggy";
    if (code >= 51 && code <= 67)
        return "rainy";
    if (code === 75 || code === 86)
        return "snowing_heavy";
    if (code >= 71 && code <= 86 && !(code >= 80 && code <= 82))
        return "cloudy_snowing";
    if (code >= 80 && code <= 82)
        return "rainy";
    if (code >= 95)
        return "thunderstorm";
    return "air";
}

function description(code) {
    const names = {
        0: "Clear", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
        45: "Fog", 48: "Freezing fog",
        51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle", 56: "Freezing drizzle", 57: "Freezing drizzle",
        61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Freezing rain",
        71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
        80: "Light showers", 81: "Showers", 82: "Heavy showers", 85: "Snow showers", 86: "Heavy snow showers",
        95: "Thunderstorm", 96: "Thunderstorm with hail", 99: "Thunderstorm with hail"
    };
    return names[code] ?? "Unknown";
}
