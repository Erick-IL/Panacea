#!/bin/bash
<<<<<<< HEAD
# Weather with OpenWeatherMap - for desktop widgets.
=======
# Погода с OpenWeatherMap и Open-Meteo (резервный источник) — для настольных виджетов.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
#
#   weather.sh KEY CITY UNITS LANG
#
#   UNITS  metric | imperial
#   LANG en | en - verbal description language
#
<<<<<<< HEAD
# Returns key=value lines, one per value. They are easier to disassemble than
# JSON: in QML there is nothing ready for fetching fields, but a key with a value
# reads in a couple of lines.
#
# In case of any problem, it prints err= with the reason and nothing more. Widget then
# shows that there is no connection, not zeros: zero degrees is legal weather, and
# it would be impossible to distinguish it from “didn’t get through.”
=======
# Если указан API ключ, в первую очередь опрашивается OpenWeatherMap.
# Если ключа нет или запрос к OpenWeatherMap не удался, используется бесплатный
# сервис Open-Meteo с геокодированием по названию города.
#
# Отдаёт строки key=value, по одной на значение.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255

KEY="$1"
CITY="$2"
UNITS="${3:-metric}"
LANG_="${4:-en}"

fail() { printf 'err=%s\n' "$1"; exit 0; }

[ -n "$CITY" ] || fail "no-city"

command -v curl >/dev/null 2>&1 || fail "no-curl"
command -v jq   >/dev/null 2>&1 || fail "no-jq"

<<<<<<< HEAD
# --max-time, and not just --connect-timeout: the server knows how to accept a connection
# and shut up, and without a general limit, the survey would hang until the next one.
#
# Without -f on purpose: with it, curl returns empty for failure, and the reason is “the key is not
# approached" or "no city" - is lost along with the body of the answer. It is needed:
# otherwise, an invalid key looks like a broken network.
# Name or index - the service searches for them using different fields. We distinguish by
# I mean: continuous numbers, if desired, with the country separated by a comma, is an index.
# The name does not start with numbers, so it cannot be confused.
#
# The service considers an index without a country to be American, so if it is not
# added, substitute RU: six-digit indices without country - Russian
# much more often than any other.
case "$CITY" in
    [0-9]*)
        case "$CITY" in
            *,*) FIELD="zip=$CITY" ;;
            *)   FIELD="zip=$CITY,RU" ;;
        esac
        ;;
    *) FIELD="q=$CITY" ;;
esac

body=$(curl -sS --connect-timeout 5 --max-time 12 --get \
    --data-urlencode "$FIELD" \
    --data-urlencode "appid=$KEY" \
    --data-urlencode "units=$UNITS" \
    --data-urlencode "lang=$LANG_" \
    "https://api.openweathermap.org/data/2.5/weather" 2>/dev/null)

[ -n "$body" ] || fail "network"

# The service explains its problem in the message field and returns it with the same code: 401 -
# the key did not fit, 404 - no city. We retell the reason as it is, otherwise
# “does not work” would have to be found out from the log.
code=$(printf '%s' "$body" | jq -r '.cod // empty' 2>/dev/null)
case "$code" in
    200) ;;
    401) fail "bad-key" ;;
    404) fail "no-such-city" ;;
    429) fail "rate-limit" ;;
    "")  fail "bad-answer" ;;
    *)   fail "http-$code" ;;
esac

printf '%s' "$body" | jq -r '
    "temp="     + ((.main.temp        // 0) | round | tostring),
    "feels="    + ((.main.feels_like  // 0) | round | tostring),
    "humidity=" + ((.main.humidity    // 0) | round | tostring),
    "pressure=" + ((.main.pressure    // 0) | round | tostring),
    "wind="     + ((.wind.speed       // 0) * 10 | round / 10 | tostring),
    "clouds="   + ((.clouds.all       // 0) | round | tostring),
    "cond="     + (.weather[0].main        // ""),
    "desc="     + (.weather[0].description // ""),
    "icon="     + (.weather[0].icon        // ""),
    "city="     + (.name                   // "")
=======
# ------------------------------------------------ 1. Попытка OpenWeatherMap
if [ -n "$KEY" ]; then
    case "$CITY" in
        [0-9]*)
            case "$CITY" in
                *,*) FIELD="zip=$CITY" ;;
                *)   FIELD="zip=$CITY,RU" ;;
            esac
            ;;
        *) FIELD="q=$CITY" ;;
    esac

    body=$(curl -sS --connect-timeout 5 --max-time 12 --get \
        --data-urlencode "$FIELD" \
        --data-urlencode "appid=$KEY" \
        --data-urlencode "units=$UNITS" \
        --data-urlencode "lang=$LANG_" \
        "https://api.openweathermap.org/data/2.5/weather" 2>/dev/null)

    code=$(printf '%s' "$body" | jq -r '.cod // empty' 2>/dev/null)
    if [ "$code" = "200" ]; then
        printf '%s' "$body" | jq -r '
            "temp="     + ((.main.temp        // 0) | round | tostring),
            "feels="    + ((.main.feels_like  // 0) | round | tostring),
            "humidity=" + ((.main.humidity    // 0) | round | tostring),
            "pressure=" + ((.main.pressure    // 0) | round | tostring),
            "wind="     + ((.wind.speed       // 0) * 10 | round / 10 | tostring),
            "clouds="   + ((.clouds.all       // 0) | round | tostring),
            "cond="     + (.weather[0].main        // ""),
            "desc="     + (.weather[0].description // ""),
            "icon="     + (.weather[0].icon        // ""),
            "city="     + (.name                   // "")
        ' 2>/dev/null && exit 0
    fi
fi

# ------------------------------------------------ 2. Резерв Open-Meteo
city_name="${CITY%%,*}"
geo=$(curl -sS --connect-timeout 5 --max-time 10 --get \
    --data-urlencode "name=$city_name" \
    --data-urlencode "count=1" \
    --data-urlencode "language=$LANG_" \
    --data-urlencode "format=json" \
    "https://geocoding-api.open-meteo.com/v1/search" 2>/dev/null)

lat=$(printf '%s' "$geo" | jq -r '.results[0].latitude // empty' 2>/dev/null)
lon=$(printf '%s' "$geo" | jq -r '.results[0].longitude // empty' 2>/dev/null)
res_name=$(printf '%s' "$geo" | jq -r '.results[0].name // empty' 2>/dev/null)

[ -n "$lat" ] && [ -n "$lon" ] || fail "no-such-city"
[ -n "$res_name" ] || res_name="$city_name"

temp_unit=""
[ "$UNITS" = "imperial" ] && { temp_unit="&temperature_unit=fahrenheit&wind_speed_unit=mph"; }

m_body=$(curl -sS --connect-timeout 5 --max-time 12 \
    "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,surface_pressure,wind_speed_10m,cloud_cover$temp_unit" 2>/dev/null)

[ -n "$m_body" ] || fail "network"

wcode=$(printf '%s' "$m_body" | jq -r '.current.weather_code // 0' 2>/dev/null)

case "$wcode" in
    0) cond="Clear";  icon="01d"; [ "$LANG_" = "ru" ] && desc="ясно" || desc="clear sky" ;;
    1) cond="Clouds"; icon="02d"; [ "$LANG_" = "ru" ] && desc="в основном ясно" || desc="mainly clear" ;;
    2) cond="Clouds"; icon="03d"; [ "$LANG_" = "ru" ] && desc="переменная облачность" || desc="partly cloudy" ;;
    3) cond="Clouds"; icon="04d"; [ "$LANG_" = "ru" ] && desc="пасмурно" || desc="overcast" ;;
    45|48) cond="Fog"; icon="50d"; [ "$LANG_" = "ru" ] && desc="туман" || desc="fog" ;;
    51|53|55) cond="Drizzle"; icon="09d"; [ "$LANG_" = "ru" ] && desc="морось" || desc="drizzle" ;;
    61|63|65) cond="Rain"; icon="10d"; [ "$LANG_" = "ru" ] && desc="дождь" || desc="rain" ;;
    71|73|75|77) cond="Snow"; icon="13d"; [ "$LANG_" = "ru" ] && desc="снег" || desc="snow" ;;
    80|81|82) cond="Rain"; icon="09d"; [ "$LANG_" = "ru" ] && desc="ливень" || desc="rain showers" ;;
    85|86) cond="Snow"; icon="13d"; [ "$LANG_" = "ru" ] && desc="снегопад" || desc="snow showers" ;;
    95|96|99) cond="Thunderstorm"; icon="11d"; [ "$LANG_" = "ru" ] && desc="гроза" || desc="thunderstorm" ;;
    *) cond="Clouds"; icon="03d"; [ "$LANG_" = "ru" ] && desc="облачно" || desc="cloudy" ;;
esac

printf '%s' "$m_body" | jq -r --arg cond "$cond" --arg desc "$desc" --arg icon "$icon" --arg city "$res_name" '
    "temp="     + ((.current.temperature_2m        // 0) | round | tostring),
    "feels="    + ((.current.apparent_temperature  // 0) | round | tostring),
    "humidity=" + ((.current.relative_humidity_2m  // 0) | round | tostring),
    "pressure=" + ((.current.surface_pressure      // 0) | round | tostring),
    "wind="     + ((.current.wind_speed_10m        // 0) * 10 | round / 10 | tostring),
    "clouds="   + ((.current.cloud_cover           // 0) | round | tostring),
    "cond="     + $cond,
    "desc="     + $desc,
    "icon="     + $icon,
    "city="     + $city
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
' 2>/dev/null || fail "bad-answer"
