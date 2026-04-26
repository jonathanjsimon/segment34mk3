// Sun/twilight calculation utilities

import Toybox.Lang;
import Toybox.Time;
import Toybox.Weather;

function getNextSunEvent(weatherCondition as StoredWeather?) as Lang.Array {
    var now = Time.now();
    if (weatherCondition != null) {
        var loc = weatherCondition.observationLocationPosition;
        if (loc != null) {
            var nextSunEvent = null;
            var sunrise = Weather.getSunrise(loc, now);
            var sunset = Weather.getSunset(loc, now);
            var isNight = false;

            if ((sunrise != null) && (sunset != null)) {
                if (sunrise.lessThan(now)) {
                    //if sunrise was already, take tomorrows
                    sunrise = Weather.getSunrise(loc, Time.today().add(new Time.Duration(86401)));
                }
                if (sunset.lessThan(now)) {
                    //if sunset was already, take tomorrows
                    sunset = Weather.getSunset(loc, Time.today().add(new Time.Duration(86401)));
                }
                if (sunrise.lessThan(sunset)) {
                    nextSunEvent = sunrise;
                    isNight = true;
                } else {
                    nextSunEvent = sunset;
                    isNight = false;
                }
                return [nextSunEvent, isNight];
            }
        }
    }
    return [];
}

function hoursToNextSunEvent(weatherCondition as StoredWeather?) as Lang.String {
    var nextSunEventArray = getNextSunEvent(weatherCondition);
    if (nextSunEventArray != null && nextSunEventArray.size() == 2) {
        var nextSunEvent = nextSunEventArray[0] as Time.Moment;
        var now = Time.now();
        // Converting seconds to hours
        var diff = (nextSunEvent.subtract(now)).value();
        if (diff >= 36000) { // No decimals if 10+ hours
            return (diff / 3600.0).format("%d");
        }
        return (diff / 3600.0).format("%.1f");
    }
    return "";
}
