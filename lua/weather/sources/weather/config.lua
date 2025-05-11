local result = {}

-- A bit of a hack here. Emojis offer so little in the way of weather icons,
-- day and night are basically the same. Here, we create the default 'day'
-- icons, then modify them in `default_icons` to change a few to their
-- corresponding night icons.

---@class WeatherWeatherConfig
---@field default table

local function day()
	return {
		clear = "☀️",
		fog = "🌁",
		haze = "🌁",
		lightning = "🌩️",
		tornado = "🌪️",
		snow = "🌨️",
		cloudy_partly = "🌤️",
		cloudy_cloudy = "🌥️",
		rain_sprinkle = "🌦️",
		rain_wind = "🌦️",
		rain_showers = "🌦️",
		rain_rain = "🌦️",
		rain_thunderstorm = "⛈️",
		hail = "⛈️",
		wind_light = "🌬️",
		wind_windy = "🌬️",
	}
end

local function night()
	local n = day()
	n.clear = "🌕"
	n.cloudy_partly = "☁️"
	n.cloudy_cloudy = "☁️"
	n.rain_sprinkle = "🌧️"
	n.rain_wind = "🌧️"
	n.rain_showers = "🌧️"
	n.rain_rain = "🌧️"

	return n
end

local function default_icons()
	return {
		day = day(),
		night = night(),
	}
end

result.default = {
	update_interval = 15 * 60 * 1000, -- 15 Minutes in ms
	-- The OWM configuration.
	meteo = {
		weather_code_to_icons = {
			-- 0xx: No significant weather
			[0] = "clear",
			[1] = "cloudy_partly",
			[2] = "cloudy_partly",
			[3] = "cloudy_cloudy",
			[4] = "haze",
			[5] = "haze",
			[6] = "fog",
			[7] = "dust",
			[8] = "smoke",
			[9] = "dust",
			[10] = "mist",
			-- 1xx: Precipitation in vicinity
			[17] = "rain_showers",
			[18] = "snow_showers",
			-- 2xx: Thunderstorms
			[20] = "lightning",
			[21] = "lightning",
			[22] = "rain_thunderstorm",
			[23] = "rain_thunderstorm",
			[24] = "rain_thunderstorm",
			[25] = "rain_thunderstorm",
			[26] = "rain_thunderstorm",
			[27] = "rain_thunderstorm",
			[28] = "rain_thunderstorm",
			[29] = "rain_thunderstorm",
			-- 3xx: Drizzle
			[30] = "rain_sprinkle",
			[31] = "rain_sprinkle",
			[32] = "rain_sprinkle",
			[33] = "rain_showers",
			[34] = "rain_showers",
			[35] = "rain_showers",
			[36] = "rain_showers",
			[37] = "rain_showers",
			[38] = "rain_showers",
			[39] = "rain_showers",
			-- 4xx: Fog and visibility reduction
			[40] = "fog",
			[41] = "fog",
			[42] = "fog",
			[43] = "fog",
			[44] = "fog",
			[45] = "fog",
			[46] = "fog",
			[47] = "fog",
			[48] = "fog",
			[49] = "fog",
			-- 5xx: Rain
			[50] = "rain_rain",
			[51] = "rain_rain",
			[52] = "rain_rain",
			[53] = "rain_rain",
			[54] = "rain_rain",
			[55] = "rain_rain",
			[56] = "rain_hail",
			[57] = "rain_hail",
			[58] = "rain_hail",
			-- 6xx: Snow
			[60] = "snow",
			[61] = "snow",
			[62] = "snow",
			[63] = "snow",
			[64] = "snow",
			[65] = "snow",
			[66] = "snow",
			[67] = "snow",
			[68] = "snow",
			[69] = "snow",
			-- 7xx: Atmosphere
			[70] = "haze",
			[71] = "haze",
			[72] = "haze",
			[73] = "haze",
			[74] = "haze",
			[75] = "haze",
			[76] = "haze",
			[77] = "haze",
			[78] = "haze",
			[79] = "haze",
			-- 80x: Clouds
			[80] = "cloudy_partly",
			[81] = "cloudy_cloudy",
			[82] = "cloudy_cloudy",
			[83] = "cloudy_cloudy",
			[84] = "cloudy_cloudy",
			[85] = "cloudy_cloudy",
			[86] = "cloudy_cloudy",
			[87] = "cloudy_cloudy",
			[88] = "cloudy_cloudy",
			[89] = "cloudy_cloudy",
			-- 90x: Extreme Weather
			[90] = "storm",
			[91] = "storm",
			[92] = "storm",
			[93] = "storm",
			[94] = "storm",
			[95] = "storm",
			[96] = "storm",
			[97] = "storm",
			[98] = "storm",
			[99] = "storm",
		},
	},
	-- The default weather source when calling subscribe.
	default = "meteo",
	-- The set of icons to use. See `day()` above for all names.
	weather_icons = default_icons(),
}

return result
