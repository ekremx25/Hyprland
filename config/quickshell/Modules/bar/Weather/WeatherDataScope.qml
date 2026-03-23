import QtQuick
import Qt.labs.platform
import Quickshell
import Quickshell.Io
import "../../../Services/core" as Core
import "../../../Services/core/Log.js" as Log

Scope {
    id: root

    property string currentTemp: "--"
    property string weatherIcon: "󰖕"
    property string cityName: "Erzurum"
    property string customLat: "39.9208"
    property string customLon: "41.2746"
    property bool useFahrenheit: false
    property bool weatherEnabled: true

    property var popupData: ({
        desc: "Waiting for data...",
        feelsLike: "-",
        humidity: "-",
        wind: "-",
        sunrise: "--:--",
        sunset: "--:--",
        forecast: []
    })

    property string cachePath: StandardPaths.writableLocation(StandardPaths.CacheLocation).toString().replace("file://", "") + "/quickshell/weather.json"
    readonly property string weatherConfigPath: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/quickshell/weather_config.json"

    function triggerRefresh() {
        apiProc.running = false;
        apiProc.fullOutput = "";
        apiProc.running = true;
    }

    Component.onCompleted: {
        weatherConfigStore.load();
        cacheStore.load();
    }

    Process {
        id: apiProc
        command: ["curl", "-s", "http://api.openweathermap.org/data/2.5/forecast?lat=" + root.customLat + "&lon=" + root.customLon + "&appid=0893defca21907657083a55440bd9f71&units=" + (root.useFahrenheit ? "imperial" : "metric") + "&lang=en"]
        property string fullOutput: ""

        stdout: SplitParser { onRead: data => { apiProc.fullOutput += data; } }
        stderr: SplitParser { onRead: data => Log.warn("WeatherDataScope", "curl stderr: " + data) }

        onExited: {
            if (apiProc.fullOutput.trim() === "") {
                Log.warn("WeatherDataScope", "Weather data empty, retrying in 10s");
                cacheStore.load();
                updateTimer.interval = 10000;
                updateTimer.restart();
                return;
            }

            try {
                var json = JSON.parse(apiProc.fullOutput);
                if (json.cod != "200") {
                    Log.warn("WeatherDataScope", "Weather API error: " + json.message);
                    cacheStore.load();
                    updateTimer.interval = 900000;
                    updateTimer.restart();
                    return;
                }

                var current = json.list[0];
                var weatherCode = current.weather[0].icon;
                var weatherDesc = current.weather[0].description;
                weatherDesc = weatherDesc.charAt(0).toUpperCase() + weatherDesc.slice(1);
                var info = root.getWeatherInfo(weatherCode);

                root.currentTemp = Math.round(current.main.feels_like).toString();
                root.weatherIcon = info.icon;

                var dailyForecasts = {};
                var todayDate = new Date().getDate();
                for (var i = 0; i < json.list.length; i++) {
                    var item = json.list[i];
                    var date = new Date(item.dt * 1000);
                    var day = date.getDate();

                    if (!dailyForecasts[day]) {
                        dailyForecasts[day] = {
                            date: date,
                            min: item.main.temp_min,
                            max: item.main.temp_max,
                            icon: item.weather[0].icon
                        };
                    } else {
                        dailyForecasts[day].min = Math.min(dailyForecasts[day].min, item.main.temp_min);
                        dailyForecasts[day].max = Math.max(dailyForecasts[day].max, item.main.temp_max);
                    }

                    if (date.getHours() >= 11 && date.getHours() <= 15) {
                        dailyForecasts[day].icon = item.weather[0].icon;
                    }
                }

                var forecastList = [];
                var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                var sortedKeys = Object.keys(dailyForecasts).sort(function(a, b) {
                    return dailyForecasts[a].date - dailyForecasts[b].date;
                });

                for (var j = 0; j < sortedKeys.length; j++) {
                    var key = sortedKeys[j];
                    var data = dailyForecasts[key];
                    var dayName = (data.date.getDate() === todayDate) ? "Today" : days[data.date.getDay()];
                    if (forecastList.length < 5) {
                        forecastList.push({
                            day: dayName,
                            max: Math.round(data.max),
                            min: Math.round(data.min),
                            icon: root.getWeatherInfo(data.icon).icon
                        });
                    }
                }

                root.popupData = {
                    desc: weatherDesc,
                    feelsLike: Math.round(current.main.feels_like).toString(),
                    humidity: current.main.humidity.toString(),
                    wind: Math.round(current.wind.speed).toString(),
                    sunrise: new Date(json.city.sunrise * 1000).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" }),
                    sunset: new Date(json.city.sunset * 1000).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" }),
                    forecast: forecastList
                };

                var cacheData = {
                    currentTemp: root.currentTemp,
                    icon: root.weatherIcon,
                    popupData: root.popupData,
                    lastUpdate: new Date().toLocaleString()
                };
                cacheStore.save(cacheData);

                updateTimer.interval = 1800000;
                updateTimer.restart();
            } catch (e) {
                Log.warn("WeatherDataScope", "Weather JSON error: " + e);
                cacheStore.load();
                updateTimer.interval = 60000;
                updateTimer.restart();
            }
            apiProc.fullOutput = "";
        }
    }

    Timer {
        id: updateTimer
        interval: 1800000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: root.triggerRefresh()
    }

    Timer {
        id: initTimer
        interval: 5000
        running: true
        repeat: false
        onTriggered: apiProc.running = true
    }

    function getWeatherInfo(code) {
        var mapping = {
            "01d": "󰖙", "01n": "󰖔",
            "02d": "󰖕", "02n": "󰖕",
            "03d": "󰖐", "03n": "󰖐",
            "04d": "󰖑", "04n": "󰖑",
            "09d": "󰖖", "09n": "󰖖",
            "10d": "󰖗", "10n": "󰖗",
            "11d": "󰖓", "11n": "󰖓",
            "13d": "󰖘", "13n": "󰖘",
            "50d": "󰖑", "50n": "󰖑"
        };
        return { icon: mapping[code] || "󰖕", text: "" };
    }

    Core.JsonDataStore {
        id: weatherConfigStore
        path: root.weatherConfigPath
        defaultValue: ({
            lat: root.customLat,
            lon: root.customLon,
            city: root.cityName,
            fahrenheit: root.useFahrenheit,
            enabled: root.weatherEnabled
        })
        onLoadedValue: function(cfg) {
            var changed = false;
            if (cfg.lat && cfg.lat !== root.customLat) { root.customLat = cfg.lat; changed = true; }
            if (cfg.lon && cfg.lon !== root.customLon) { root.customLon = cfg.lon; changed = true; }
            if (cfg.city && cfg.city !== root.cityName) { root.cityName = cfg.city; }
            if (cfg.fahrenheit !== undefined && cfg.fahrenheit !== root.useFahrenheit) { root.useFahrenheit = cfg.fahrenheit; changed = true; }
            if (cfg.enabled !== undefined && cfg.enabled !== root.weatherEnabled) { root.weatherEnabled = cfg.enabled; }
            if (changed) {
                root.triggerRefresh();
                updateTimer.restart();
            }
        }
        onFailed: function(phase, exitCode, details) {
            if (phase === "parse") Log.warn("WeatherDataScope", "Weather config parse error: " + details);
        }
    }

    Core.FileChangeWatcher {
        path: root.weatherConfigPath
        interval: 1500
        onChanged: weatherConfigStore.load()
    }

    Core.JsonDataStore {
        id: cacheStore
        path: root.cachePath
        defaultValue: ({})
        onLoadedValue: function(json) {
            if (json.currentTemp) root.currentTemp = json.currentTemp;
            if (json.icon) root.weatherIcon = json.icon;
            if (json.popupData) root.popupData = json.popupData;
        }
        onFailed: function(phase, exitCode, details) {
            if (phase === "parse") Log.warn("WeatherDataScope", "Weather cache parse error: " + details);
        }
    }
}
