import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.UserProfile;

class ComplicationHelper {

    hidden var cgmComplicationId as Complications.Id? = null;
    hidden var cgmAgeComplicationId as Complications.Id? = null;
    var vo2RunTrend as String = "";
    var vo2BikeTrend as String = "";

    function initialize() {}

    function getIconState(setting as Number) as String {
        if(setting == 1) { // Alarm
            var alarms = System.getDeviceSettings().alarmCount;
            if(alarms > 0) {
                return "A";
            } else {
                return "";
            }
        } else if(setting == 2) { // DND
            var dnd = System.getDeviceSettings().doNotDisturb;
            if(dnd) {
                return "D";
            } else {
                return "";
            }
        } else if(setting == 3) { // Bluetooth (on / off)
            var bl = System.getDeviceSettings().phoneConnected;
            if(bl) {
                return "L";
            } else {
                return "M";
            }
        } else if(setting == 4) { // Bluetooth (just off)
            var bl = System.getDeviceSettings().phoneConnected;
            if(bl) {
                return "";
            } else {
                return "M";
            }
        } else if(setting == 5) { // Move bar
            var mov = 0;
            if(ActivityMonitor.getInfo().moveBarLevel != null) {
                mov = ActivityMonitor.getInfo().moveBarLevel;
            }
            if(mov == 0) { return ""; }
            if(mov == 1) { return "N"; }
            if(mov == 2) { return "O"; }
            if(mov == 3) { return "P"; }
            if(mov == 4) { return "Q"; }
            if(mov == 5) { return "R"; }
        } else if(setting == 6 || setting == 7) { // Notification icon (6) or notification icon with count (7)
            var notif = System.getDeviceSettings().notificationCount;
            if(notif != null && notif > 0) {
                return "H";
            }
        } else if(setting == 8) { // Training status icon
            try {
                var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS));
                if(complication != null && complication.value != null) { return "V"; }
            } catch(e) {}
        }
        return "";
    }

    (:AMOLED)
    function getIconColor(setting as Number) as Number? {
        if(setting == 8) { // Training status icon
            try {
                var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS));
                if(complication != null && complication.value != null) {
                    var status = complication.value.toUpper();
                    if(status.find("OVERREACHING") != null) { return 0xFF3333; }
                    if(status.find("PEAKING") != null) { return 0x7B60FF; }
                    if(status.find("UNPRODUCTIVE") != null) { return 0xFF7700; }
                    if(status.find("PRODUCTIVE") != null) { return 0x30A050; }
                    if(status.find("MAINTAINING") != null) { return 0xFFCC00; }
                    if(status.find("RECOVERY") != null) { return 0x4488EE; }
                    if(status.find("STRAINED") != null) { return 0xFF44AA; }
                    if(status.find("DETRAINING") != null) { return 0x808080; }
                    if(status.find("PAUSED") != null) { return 0x444444; }
                    return 0x808080; // No Status / unknown
                }
            } catch(e) {}
        }
        return null;
    }

    (:MIP)
    function getIconColor(setting as Number) as Number? {
        if(setting == 8) { // Training status icon
            try {
                var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS));
                if(complication != null && complication.value != null) {
                    var status = complication.value.toUpper();
                    if(status.find("OVERREACHING") != null) { return 0xFF0000; }
                    if(status.find("PEAKING") != null) { return 0xAA55FF; }
                    if(status.find("UNPRODUCTIVE") != null) { return 0xFFAA00; }
                    if(status.find("PRODUCTIVE") != null) { return 0x55AA55; }
                    if(status.find("MAINTAINING") != null) { return 0xFFFF00; }
                    if(status.find("RECOVERY") != null) { return 0x55AAFF; }
                    if(status.find("STRAINED") != null) { return 0xFF55AA; }
                    if(status.find("DETRAINING") != null) { return 0xAAAAAA; }
                    if(status.find("PAUSED") != null) { return 0x555555; }
                    return 0xAAAAAA; // No Status / unknown
                }
            } catch(e) {}
        }
        return null;
    }

    function getIconCountOverlay(setting as Number) as String {
        if(setting == 7) {
            var notif = System.getDeviceSettings().notificationCount;
            if(notif != null && notif > 0) {
                return notif > 9 ? "9+" : notif.format("%d");
            }
        }
        return "";
    }

    function getAltitudeValue() as Float? {
        try {
            var comp = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_ALTITUDE));
            if (comp != null && comp.value != null) { return comp.value.toFloat(); }
        } catch(e) {}
        return null;
    }

    function getRecoveryTimeVal(numberFormat as String) as String {
        var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_RECOVERY_TIME));
        if (complication != null && complication.value != null) {
            var recovery_h = complication.value / 60.0;
            if(recovery_h < 9.9 and recovery_h != 0) { return recovery_h.format("%.1f"); }
            return Math.round(recovery_h).format(numberFormat);
        }
        return "";
    }

    function getTrainingStatusVal() as String {
        try {
            var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS));
            if (complication != null && complication.value != null) { return complication.value.toUpper(); }
        } catch(e) {}
        return "";
    }

    function getCalendarEventVal(width as Number) as String {
        var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS));
        var colon_index = null;
        var val = "";
        if (complication != null && complication.value != null) {
            val = complication.value;
            colon_index = val.find(":");
            if (colon_index != null && colon_index < 2) { val = "0" + val; }
        } else {
            val = "--:--";
        }
        if (width < 5 and colon_index != null) { val = val.substring(0, 2) + val.substring(3, 5); }
        return val;
    }

    function getPulseOxVal(numberFormat as String) as String {
        var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_PULSE_OX));
        if (complication != null && complication.value != null) { return complication.value.format(numberFormat); }
        return "";
    }

    hidden function getCgmComplicationByLabel(targetLabel as String) as Complications.Id? {
        try {
            var iter = Complications.getComplications();
            var comp = iter.next();
            while (comp != null) {
                var compType = comp.getType();
                var compLabel = comp.shortLabel;
                if (compType == Complications.COMPLICATION_TYPE_INVALID && compLabel != null) {
                    if (compLabel.equals(targetLabel)) {
                        return comp.complicationId;
                    }
                }
                comp = iter.next();
            }
        } catch (e) {}
        return null;
    }

    hidden function convertCgmTrendToArrow(trend as String) as String {
        if (trend.equals("R")) { return "a"; }  // Rapidly rising ↑
        if (trend.equals("r")) { return "b"; }  // Rising ↗
        if (trend.equals("n")) { return "c"; }  // Neutral →
        if (trend.equals("d")) { return "d"; }  // Falling ↘
        if (trend.equals("D")) { return "e"; }  // Rapidly falling ↓
        return "";
    }

    // Returns a trend arrow char (b=↗ c=→ d=↘) based on stored VO2 history.
    // Stores a new reading every 5 days; drops entries older than 30 days.
    // Returns "" if fewer than 2 stored entries exist.
    hidden function getVo2Trend(key as String, currentVal as Number) as String {
        var nowDays = (Time.now().value() / 86400).toNumber();
        var FIVE_DAYS  = 5;
        var THIRTY_DAYS = 30;

        var history = Application.Storage.getValue(key) as Array?;
        if (history == null) { history = [] as Array; }

        // Prune entries older than 30 days
        var pruned = [] as Array;
        for (var i = 0; i < history.size(); i++) {
            var entry = history[i] as Array;
            if (nowDays - (entry[0] as Number) <= THIRTY_DAYS) {
                pruned.add(entry);
            }
        }

        // Add new entry if history empty or >= 5 days since last stored
        var shouldAdd = pruned.size() == 0 ||
            (nowDays - ((pruned[pruned.size() - 1] as Array)[0] as Number) >= FIVE_DAYS);
        if (shouldAdd) {
            pruned.add([nowDays, currentVal]);
        }

        if (shouldAdd || pruned.size() != history.size()) {
            Application.Storage.setValue(key, pruned);
        }

        if (pruned.size() < 2) { return ""; }

        var oldest = (pruned[0] as Array)[1] as Number;
        if (currentVal > oldest) { return "b"; }  // ↗
        if (currentVal < oldest) { return "d"; }  // ↘
        return "c";  // →
    }

    function getCgmReading() as String {
        try {
            if (cgmComplicationId == null) {
                cgmComplicationId = getCgmComplicationByLabel("CGM");
            }
            if (cgmComplicationId == null) { return ""; }

            var comp = Complications.getComplication(cgmComplicationId);
            if (comp == null || comp.value == null) { return ""; }

            var valueStr = comp.value.toString();
            if (valueStr.equals("---")) { return "---"; }

            var spaceIndex = valueStr.find(" ");
            if (spaceIndex == null) { return valueStr; }

            var reading = valueStr.substring(0, spaceIndex);
            var trend = valueStr.substring(spaceIndex + 1, valueStr.length());
            var arrow = convertCgmTrendToArrow(trend);
            return reading + arrow;
        } catch (e) {}
        return "";
    }

    function getCgmAge() as String {
        try {
            if (cgmAgeComplicationId == null) {
                cgmAgeComplicationId = getCgmComplicationByLabel("CGM Age");
            }
            if (cgmAgeComplicationId == null) { return ""; }
            var comp = Complications.getComplication(cgmAgeComplicationId);
            if (comp == null || comp.value == null) { return ""; }
            var timestamp = comp.value.toString().toLong();
            if (timestamp == null || timestamp < 0) { return "---"; }
            var ageMin = (Time.now().value() - timestamp) / 60;
            if (ageMin < 0) { return "---"; }
            return ageMin.format("%d");
        } catch (e) {}
        return "";
    }

    function updateVo2History() as Void {
        var profile = UserProfile.getProfile();
        if (profile.vo2maxRunning != null) {
            vo2RunTrend = getVo2Trend("vo2run_hist", profile.vo2maxRunning as Number);
        }
        if (profile.vo2maxCycling != null) {
            vo2BikeTrend = getVo2Trend("vo2bike_hist", profile.vo2maxCycling as Number);
        }
    }
}
