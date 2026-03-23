import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.platform
import "../../../Services/core" as Core
import "../../../Services/core/Log.js" as Log

Item {
    id: service
    visible: false
    width: 0
    height: 0

    readonly property string configPath: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/quickshell/weather_config.json"

    property bool weatherEnabled: true
    property bool useFahrenheit: false
    property bool autoLocation: false
    property string customLat: "39.9208"
    property string customLon: "41.2746"
    property string cityName: "Erzurum"
    property string searchText: ""
    property var searchResults: []
    property bool searching: false

    function saveConfig() {
        var cfg = {
            enabled: weatherEnabled,
            fahrenheit: useFahrenheit,
            autoLocation: autoLocation,
            lat: customLat,
            lon: customLon,
            city: cityName
        };
        configStore.save(cfg);
    }

    function searchCity() {
        var query = searchText.trim();
        if (query === "") return;
        searching = true;
        searchResults = [];
        geoSearchProc.query = query.replace(/ /g, "+");
        geoSearchProc.buf = "";
        geoSearchProc.running = false;
        geoSearchProc.running = true;
    }

    function toggleAutoLocation() {
        autoLocation = !autoLocation;
        if (autoLocation) {
            autoLocProc.buf = "";
            autoLocProc.running = true;
        }
        saveConfig();
    }

    function selectSearchResult(result) {
        customLat = result.lat;
        customLon = result.lon;
        cityName = result.name.split(",")[0].trim();
        searchResults = [];
        searchText = "";
        saveConfig();
    }

    Process {
        id: geoSearchProc
        property string buf: ""
        property string query: ""
        command: ["curl", "-s", "http://api.openweathermap.org/geo/1.0/direct?q=" + query + "&limit=5&appid=0893defca21907657083a55440bd9f71"]
        stdout: SplitParser { onRead: data => geoSearchProc.buf += data }
        onExited: {
            service.searching = false;
            try {
                var results = JSON.parse(geoSearchProc.buf);
                var list = [];
                for (var i = 0; i < results.length; i++) {
                    var item = results[i];
                    list.push({
                        name: item.name + (item.state ? ", " + item.state : "") + ", " + (item.country || ""),
                        lat: item.lat.toFixed(4),
                        lon: item.lon.toFixed(4)
                    });
                }
                service.searchResults = list;
            } catch (e) {
                Log.warn("WeatherSettingsService", "Search parse error: " + e);
                service.searchResults = [];
            }
            geoSearchProc.buf = "";
        }
    }

    Process {
        id: autoLocProc
        property string buf: ""
        command: ["curl", "-s", "http://ip-api.com/json/?fields=lat,lon,city"]
        stdout: SplitParser { onRead: data => autoLocProc.buf += data }
        onExited: {
            try {
                var result = JSON.parse(autoLocProc.buf);
                if (result.lat) service.customLat = result.lat.toFixed(4);
                if (result.lon) service.customLon = result.lon.toFixed(4);
                if (result.city) service.cityName = result.city;
                saveConfig();
            } catch (e) {
                Log.warn("WeatherSettingsService", "Auto location parse error: " + e);
            }
            autoLocProc.buf = "";
        }
    }

    Component.onCompleted: configStore.load()

    Core.JsonDataStore {
        id: configStore
        path: service.configPath
        defaultValue: ({
            enabled: true,
            fahrenheit: false,
            autoLocation: false,
            lat: "39.9208",
            lon: "41.2746",
            city: "Erzurum"
        })
        onLoadedValue: function(cfg) {
            if (cfg.enabled !== undefined) service.weatherEnabled = cfg.enabled;
            if (cfg.fahrenheit !== undefined) service.useFahrenheit = cfg.fahrenheit;
            if (cfg.autoLocation !== undefined) service.autoLocation = cfg.autoLocation;
            if (cfg.lat) service.customLat = cfg.lat;
            if (cfg.lon) service.customLon = cfg.lon;
            if (cfg.city) service.cityName = cfg.city;
        }
        onFailed: function(phase, exitCode, details) {
            if (phase === "parse") Log.warn("WeatherSettingsService", "Config parse error: " + details);
        }
    }
}
