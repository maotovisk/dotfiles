#!/usr/bin/env python

import json
import requests
from datetime import datetime

# Define colors for Pango markup
COLOR_CITY_TEMP = "#FFA500"  # Orange
COLOR_FEELS_LIKE = "#FF8C00" # DarkOrange
COLOR_WIND = "#87CEEB"       # SkyBlue
COLOR_HUMIDITY = "#90EE90"   # PaleGreen

COLOR_DATE_HEADER = "#81D4FA" # Light Blue
COLOR_MAX_TEMP = "#FF6347"    # Tomato
COLOR_MIN_TEMP = "#1E90FF"    # DodgerBlue
COLOR_SUNRISE = "#FFD700"     # Gold
COLOR_SUNSET = "#9370DB"      # MediumPurple

COLOR_HOURLY_ICON = "#87CEFA" # LightSkyBlue
COLOR_HOURLY_TEMP = "#F4A460" # SandyBrown
COLOR_CHANCES = "#DEB887"     # Burlywood

WEATHER_CODES = {
    '113': '\uf185',  #   (sun)
    '116': '\uf6c4',  #   (cloud-sun)
    '119': '\uf0c2',  #   (cloud)
    '122': '\uf0c2',  #   (cloud)
    '143': '\uf75f',  #   (fog)
    '176': '\uf73c',  #   (cloud-showers)
    '179': '\uf73b',  #   (cloud-snow)
    '182': '\uf73b',  #   (cloud-snow)
    '185': '\uf73b',  #   (cloud-snow)
    '200': '\uf76c',  #   (thunderstorm)
    '227': '\uf73b',  #   (cloud-snow)
    '230': '\uf2dc',  #   (snowflake)
    '248': '\uf75f',  #   (fog)
    '260': '\uf75f',  #   (fog)
    '263': '\uf73c',  #   (cloud-showers)
    '266': '\uf73c',  #   (cloud-showers)
    '281': '\uf73b',  #   (cloud-snow)
    '284': '\uf73b',  #   (cloud-snow)
    '293': '\uf73c',  #   (cloud-showers)
    '296': '\uf73c',  #   (cloud-showers)
    '299': '\uf73b',  #   (cloud-snow)
    '302': '\uf73b',  #   (cloud-snow)
    '305': '\uf73b',  #   (cloud-snow)
    '308': '\uf73b',  #   (cloud-snow)
    '311': '\uf73b',  #   (cloud-snow)
    '314': '\uf73b',  #   (cloud-snow)
    '317': '\uf73b',  #   (cloud-snow)
    '320': '\uf73b',  #   (cloud-snow)
    '323': '\uf73b',  #   (cloud-snow)
    '326': '\uf73b',  #   (cloud-snow)
    '329': '\uf2dc',  #   (snowflake)
    '332': '\uf2dc',  #   (snowflake)
    '335': '\uf2dc',  #   (snowflake)
    '338': '\uf2dc',  #   (snowflake)
    '350': '\uf73b',  #   (cloud-snow)
    '353': '\uf73c',  #   (cloud-showers)
    '356': '\uf73b',  #   (cloud-snow)
    '359': '\uf73b',  #   (cloud-snow)
    '362': '\uf73b',  #   (cloud-snow)
    '365': '\uf73b',  #   (cloud-snow)
    '368': '\uf73b',  #   (cloud-snow)
    '371': '\uf2dc',  #   (snowflake)
    '374': '\uf73b',  #   (cloud-snow)
    '377': '\uf73b',  #   (cloud-snow)
    '386': '\uf76c',  #   (thunderstorm)
    '389': '\uf76c',  #   (thunderstorm)
    '392': '\uf76c',  #   (thunderstorm)
    '395': '\uf2dc'   #   (snowflake)
}

data = {}

weather = requests.get("http://pt.wttr.in/Sao Vicente BR?format=j1").json()

def format_time(time):
    return time.replace("00", "").zfill(2)

# Corrected format_temp to use its argument
def format_temp(temp_value_str):
    return (temp_value_str+"°").ljust(3)

CHANCE_ICONS = {
    "chanceoffog": "\uf75f",         # fog
    "chanceoffrost": "\uf2dc",       # snowflake
    "chanceofovercast": "\uf0c2",    # cloud
    "chanceofrain": "\uf73c",        # cloud-showers
    "chanceofsnow": "\uf73b",        # cloud-snow
    "chanceofsunshine": "\uf185",    # sun
    "chanceofthunder": "\uf76c",     # thunderstorm
    "chanceofwindy": "\uf72e",       # wind
}

def format_chances(hour):
    chances = [
        "chanceoffog", "chanceoffrost", "chanceofovercast", "chanceofrain",
        "chanceofsnow", "chanceofsunshine", "chanceofthunder", "chanceofwindy"
    ]
    icons = []
    for event in chances:
        if int(hour[event]) > 0:
            icon = CHANCE_ICONS.get(event, "")
            icons.append(f"{icon} {hour[event]}%")
    return " ".join(icons)

data['text'] = WEATHER_CODES[weather['current_condition'][0]['weatherCode']] + \
    " "+weather['current_condition'][0]['temp_C']+"°C"

data['tooltip'] = f"<b>{weather['current_condition'][0]['lang_pt'][0]['value']} <span foreground='{COLOR_CITY_TEMP}'>{weather['current_condition'][0]['temp_C']}°</span></b>\n"
data['tooltip'] += f"Sensação térmica: <span foreground='{COLOR_FEELS_LIKE}'>{weather['current_condition'][0]['FeelsLikeC']}°</span>\n"
data['tooltip'] += f"Vento: <span foreground='{COLOR_WIND}'>{weather['current_condition'][0]['windspeedKmph']}Km/h</span>\n"
data['tooltip'] += f"Umidade: <span foreground='{COLOR_HUMIDITY}'>{weather['current_condition'][0]['humidity']}%</span>\n"

def fit_text(text, width):
    """Truncate and pad text to a fixed width, adding ellipsis if needed."""
    if len(text) > width:
        return text[:width-1] + "…"
    return text.ljust(width)

for i, day in enumerate(weather['weather']):
    day_header_text = ""
    if i == 0:
        day_header_text += "Hoje, "
    if i == 1:
        day_header_text += "Amanhã, "
    day_header_text += day['date']
    data['tooltip'] += f"\n<b><span foreground='{COLOR_DATE_HEADER}'>{day_header_text}</span></b>\n"

    data['tooltip'] += f"<span foreground='{COLOR_MAX_TEMP}'>\uf062 {day['maxtempC']}°</span> <span foreground='{COLOR_MIN_TEMP}'>\uf063 {day['mintempC']}°</span> "
    data['tooltip'] += f"<span foreground='{COLOR_SUNRISE}'>\uf185</span> {day['astronomy'][0]['sunrise']} <span foreground='{COLOR_SUNSET}'>\uf186</span> {day['astronomy'][0]['sunset']}\n"

    # Table header for hourly forecast
    data['tooltip'] += "<span font_family='monospace'><b>Hora  Icon  Térmica  Descrição                   Chances</b>\n"
    data['tooltip'] += "----- ----- ------- ---------------------------- --------------------</span>\n"

    for hour in day['hourly']:
        if i == 0:
            if int(format_time(hour['time'])) < datetime.now().hour-2:
                continue

        hourly_time = format_time(hour['time'])
        weather_icon = WEATHER_CODES[hour['weatherCode']]
        temp_formatted = format_temp(hour['FeelsLikeC'])
        description = hour['lang_pt'][0]['value']
        desc_fixed = fit_text(description, 28)
        chances_str = format_chances(hour)

        # Pad/align columns for table-like appearance
        line = f"<span font_family='monospace'>{hourly_time:>4}:00  {weather_icon}   {temp_formatted:<7} {desc_fixed} {chances_str}</span>\n"
        data['tooltip'] += line

print(json.dumps(data))
