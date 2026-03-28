import Toybox.Test;
import Toybox.Lang;

// Unit tests for OpenWeatherService.owmCodeToGarmin()
// These test the OWM weather code -> Garmin condition enum mapping.
// Run with: monkeyc --unit-test -d fenix7

(:test)
function testOwmCodeClear(logger as Test.Logger) as Boolean {
    return OpenWeatherService.owmCodeToGarmin(800) == 0;
}

(:test)
function testOwmCodeThunderstorm(logger as Test.Logger) as Boolean {
    return OpenWeatherService.owmCodeToGarmin(200) == 6;
}

(:test)
function testOwmCodeRain(logger as Test.Logger) as Boolean {
    return OpenWeatherService.owmCodeToGarmin(500) == 14
        && OpenWeatherService.owmCodeToGarmin(501) == 3
        && OpenWeatherService.owmCodeToGarmin(502) == 15;
}

(:test)
function testOwmCodeSnow(logger as Test.Logger) as Boolean {
    return OpenWeatherService.owmCodeToGarmin(600) == 16
        && OpenWeatherService.owmCodeToGarmin(601) == 4
        && OpenWeatherService.owmCodeToGarmin(602) == 17;
}

(:test)
function testOwmCodeFog(logger as Test.Logger) as Boolean {
    return OpenWeatherService.owmCodeToGarmin(701) == 8
        && OpenWeatherService.owmCodeToGarmin(741) == 8;
}

(:test)
function testOwmCodeClouds(logger as Test.Logger) as Boolean {
    return OpenWeatherService.owmCodeToGarmin(801) == 1
        && OpenWeatherService.owmCodeToGarmin(803) == 2
        && OpenWeatherService.owmCodeToGarmin(804) == 20;
}

(:test)
function testOwmCodeUnknown(logger as Test.Logger) as Boolean {
    return OpenWeatherService.owmCodeToGarmin(999) == 53;
}
