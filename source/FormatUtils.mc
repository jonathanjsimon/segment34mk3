import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;

function formatTemperature(temp, propShowTempUnit as Boolean, tempUnit as String) as String {
    if(propShowTempUnit) {
        return temp.format("%d") + tempUnit;
    }
    return temp.format("%d");
}

function convertTemperature(temp as Numeric, unit as String) as Numeric {
    if(unit.equals("C")) {
        return temp;
    } else {
        return ((temp * 9/5) + 32);
    }
}

function formatWindSpeed(mps as Float, propWindUnit as Number) as String {
    if (propWindUnit == 0) {
        return Math.round(mps).format("%d");
    } else if (propWindUnit == 1) {
        return Math.round(mps * 3.6).format("%d");
    } else if (propWindUnit == 2) {
        return Math.round(mps * 2.237).format("%d");
    } else if (propWindUnit == 3) {
        return Math.round(mps * 1.944).format("%d");
    } else { // beaufort
        if (mps < 0.5f) { return "0"; }
        if (mps < 1.5f) { return "1"; }
        if (mps < 3.3f) { return "2"; }
        if (mps < 5.5f) { return "3"; }
        if (mps < 7.9f) { return "4"; }
        if (mps < 10.7f) { return "5"; }
        if (mps < 13.8f) { return "6"; }
        if (mps < 17.1f) { return "7"; }
        if (mps < 20.7f) { return "8"; }
        if (mps < 24.4f) { return "9"; }
        if (mps < 28.4f) { return "10"; }
        if (mps < 32.6f) { return "11"; }
        return "12";
    }
}

function formatPressure(pressureHpa as Float, width as Number, propPressureUnit as Number) as String {
    var val = "";
    var nf = "%d";

    if (propPressureUnit == 0) { // hPA
        val = pressureHpa.format(nf);
    } else if (propPressureUnit == 1) { // mmHG
        val = (pressureHpa * 0.750062).format(nf);
    } else if (propPressureUnit == 2) { // inHG
        if(width == 5) {
            val = (pressureHpa * 0.02953).format("%.2f");
        } else {
            val = (pressureHpa * 0.02953).format("%.1f");
        }
    }

    return val;
}

function formatDistanceByWidth(distance as Float, width as Number) as String {
    if (width == 3) {
        return distance < 9.9 ? distance.format("%.1f") : Math.round(distance).format("%d");
    } else if (width == 4) {
        return distance < 100 ? distance.format("%.1f") : distance.format("%d");
    } else {  // width == 5
        return distance < 1000 ? distance.format("%05.1f") : distance.format("%05d");
    }
}

function formatGraphAxisValue(val as Float) as String {
    var n = val.toNumber();
    if(n < 0) {
        var abs = (-val).toNumber();
        if(abs >= 1000) { return "-" + (abs / 1000).toString() + "K"; }
        return "-" + abs.toString();
    }
    if(n >= 1000) { return (n / 1000).toString() + "K"; }
    return n.toString();
}

function goalPercent(val as Number, goal as Number) as Number {
    if(goal == 0 || val == 0) { return 0; }
    return Math.round(val.toFloat() / goal.toFloat() * 100.0);
}

function moonPhase(time, propHemisphere as Number) as String {
    var jd = julianDay(time.year, time.month, time.day);

    var days_since_new_moon = jd - 2459966;
    var lunar_cycle = 29.53;
    var phase = ((days_since_new_moon / lunar_cycle) * 100).toNumber() % 100;
    var into_cycle = (phase / 100.0) * lunar_cycle;

    if(time.month == 5 and time.day == 4) {
        return "8"; // That's no moon!
    }

    var moonPhaseIdx;
    if (into_cycle < 3) { // 2+1
        moonPhaseIdx = 0;
    } else if (into_cycle < 6) { // 4
        moonPhaseIdx = 1;
    } else if (into_cycle < 10) { // 4
        moonPhaseIdx = 2;
    } else if (into_cycle < 14) { // 4
        moonPhaseIdx = 3;
    } else if (into_cycle < 18) { // 4
        moonPhaseIdx = 4;
    } else if (into_cycle < 22) { // 4
        moonPhaseIdx = 5;
    } else if (into_cycle < 26) { // 4
        moonPhaseIdx = 6;
    } else if (into_cycle < 29) { // 3
        moonPhaseIdx = 7;
    } else {
        moonPhaseIdx = 0;
    }

    // If hemisphere is 1 (southern), invert the phase index
    if (propHemisphere == 1) {
        moonPhaseIdx = (8 - moonPhaseIdx) % 8;
    }

    return moonPhaseIdx.toString();
}

function formatLabel(short as ResourceId, mid as ResourceId, size as Number) as String {
    if(size == 1) { return Application.loadResource(short) + ":"; }
    return Application.loadResource(mid) + ":";
}

function formatSunTime(s as Time.Moment?, width as Number, propIs24H as Boolean, propHourFormat as Number) as String {
    if(s != null) {
        var info = Time.Gregorian.info(s, Time.FORMAT_SHORT);
        var h = formatHour(info.hour, propIs24H, propHourFormat);
        if(width < 5) { return h.format("%02d") + info.min.format("%02d"); }
        return h.format("%02d") + ":" + info.min.format("%02d");
    }
    return Application.loadResource(Rez.Strings.LABEL_NA);
}

// Returns [dawn, dusk] as Time.Moment objects, or null if unavailable.
// dawn = civil dawn (sun at -6°), dusk = civil dusk (sun at -6°).
// Requires: lat_deg (latitude in degrees), sunrise and sunset as Time.Moment.
function getCivilTwilight(lat_deg as Double, sunrise as Time.Moment, sunset as Time.Moment) as Array? {
    var PI = Math.PI;
    var lat = lat_deg * PI / 180.0;

    // Half-day length as hour angle in radians (Earth rotates 2π in 86400s)
    var half_day_s = (sunset.value() - sunrise.value()) / 2.0;
    var H0 = half_day_s / 86400.0 * 2.0 * PI;

    // Back-calculate solar declination from H0 and latitude.
    // sunrise formula: cos(H0) = (sin(h0) - sin(lat)*sin(dec)) / (cos(lat)*cos(dec))
    // where h0 = -0.8333° (includes atmospheric refraction + solar disc)
    var sin_h0 = Math.sin(-0.8333 * PI / 180.0);
    var a = Math.cos(H0) * Math.cos(lat);
    var b = Math.sin(lat);
    var R = Math.sqrt(a * a + b * b);
    var ratio = sin_h0 / R;
    if (ratio < -1.0 || ratio > 1.0) { return null; }
    var alpha = Math.atan2(b, a);
    var dec = alpha - Math.acos(ratio); // valid root; other root is always ~180°+

    // Hour angle for civil twilight (sun at -6°)
    var cos_H_civil = (Math.sin(-6.0 * PI / 180.0) - Math.sin(lat) * Math.sin(dec)) /
                      (Math.cos(lat) * Math.cos(dec));
    if (cos_H_civil > 1.0) { return null; } // polar twilight — sun never drops below -6°
    if (cos_H_civil < -1.0) { return null; } // shouldn't happen when sunrise is valid
    var H_civil = Math.acos(cos_H_civil);

    var delta_s = (H_civil - H0) / (2.0 * PI) * 86400.0;
    var delta = new Time.Duration(delta_s.toNumber());
    return [sunrise.subtract(delta), sunset.add(delta)];
}
