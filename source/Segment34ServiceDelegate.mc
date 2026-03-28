import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;

(:background)
class Segment34ServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        System.ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var weatherProvider = Application.Properties.getValue("weatherProvider") as Number;
        if (weatherProvider != 1) { return; }

        var apiKey = Application.Properties.getValue("owmApiKey") as String;
        if (apiKey.length() == 0) { return; }

        var now = Time.now().value();
        var lastUpdate = Application.Storage.getValue("owm_last_update") as Number?;
        if (lastUpdate != null && now - lastUpdate <= 7200) { return; }

        var garminCc = Weather.getCurrentConditions();
        if (garminCc == null || garminCc.observationLocationPosition == null) { return; }

        var deg = garminCc.observationLocationPosition.toDegrees();
        var service = new OpenWeatherService();
        service.fetchWeather((deg[0] as Decimal).toFloat(), (deg[1] as Decimal).toFloat(), apiKey);
    }
}
