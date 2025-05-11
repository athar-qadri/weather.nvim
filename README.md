# weather.nvim

**weather.nvim** brings real-time weather and earthquake alerts to Neovim without the need for any API keys, making it easy to set up and use. Using data from Open-Meteo for weather and USGS for earthquakes, it provides notifications about significant events based on your location—keeping you informed without leaving your workflow.

---

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Integration](#integration)
  - [Lualine Integration](#lualine-integration)
- [Contributing](#contributing)
- [License](#license)

---

## Introduction

Stay updated on the world around you with `weather.nvim`. This plugin fetches weather and earthquake data periodically, displaying alerts via Neovim’s notification system. Whether you’re tracking a storm or monitoring seismic activity, `weather.nvim` integrates seamlessly into your editing environment—all with **no API key required**, a standout feature that simplifies your setup.

---

## Features

- **No API Key Required**: Enjoy hassle-free setup with no need for API keys, thanks to open data sources—a key advantage of this plugin.
- **Automatic Location Detection**: Uses your IP address to determine your location.
- **Periodic Updates**: Fetches data at customizable intervals.
- **Customizable Alerts**: Set thresholds like minimum earthquake magnitude or radius.
- **Dual Data Sources**:
  - Weather data from [Open-Meteo](https://open-meteo.com/).
  - Earthquake data from [USGS Earthquake API](https://earthquake.usgs.gov/fdsnws/event/1/).
- **Notifications**: Alerts via `nvim-notify` (optional dependency).
- **Lualine Integration**: Display current weather in your status line (requires `lualine.nvim`).
- **Flexible Configuration**: Adjust temperature units, update intervals, and more.

---

## Installation

### Using Lazy.nvim

Install `weather.nvim` with [lazy.nvim](https://github.com/folke/lazy.nvim) using this example:

```lua
return {
  "athar-qadri/weather.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",  -- Required for HTTP requests
    "rcarriga/nvim-notify",   -- Optional, for notifications
  },
  config = function()
    local weather = require("weather")
    weather:setup({
      settings = {
        update_interval = 60 * 10 * 1000,  -- 10 minutes
        minimum_magnitude = 5,
        location = { lat = 34.0787, lon = 74.7659 },
        temperature_unit = "celsius",
      },
    })
    require("weather.notify").start()  -- Start notifications
  end,
}
```

### Using Packer.nvim

Alternatively, use [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'athar-qadri/weather.nvim',
  requires = {
    {'nvim-lua/plenary.nvim'},         -- Required for HTTP requests
    {'rcarriga/nvim-notify'},          -- Optional, for notifications
    {'nvim-lualine/lualine.nvim'},     -- Optional, for status line integration
  }
}
```

### Dependencies

- **Required**: `plenary.nvim` for HTTP requests.
- **Optional**:
  - `nvim-notify` for alert notifications.
  - `lualine.nvim` for status line weather display.

---

## Configuration

Configure `weather.nvim` by calling the `setup` function with a configuration table. Here’s an example with default values:

```lua
require('weather').setup({
  settings = {
    update_interval = 15 * 60 * 1000,  -- 15 minutes in milliseconds
    temperature_unit = "celsius",      -- "celsius" or "fahrenheit"
    location = { lat = 37.7749, lon = -122.4194 },  -- Optional fixed location
  },
  default = {
    minimum_magnitude = 4.0,           -- Minimum earthquake magnitude for alerts
    minimum_radius = 20,               -- Minimum radius in km for earthquake alerts
    default_sources = { "meteo", "usgs" },  -- Data sources
  },
})
```

### Configuration Options

| Option                      | Type     | Description                                      | Default                   |
| --------------------------- | -------- | ------------------------------------------------ | ------------------------- |
| `settings.update_interval`  | `number` | Data fetch interval (milliseconds)               | `15 * 60 * 1000` (15 min) |
| `settings.temperature_unit` | `string` | Temperature unit (`"celsius"` or `"fahrenheit"`) | `"celsius"`               |
| `settings.location`         | `table`  | Fixed location `{lat, lon}` (optional)           | `nil` (IP-based)          |
| `default.minimum_magnitude` | `number` | Minimum earthquake magnitude for alerts          | `4.0`                     |
| `default.minimum_radius`    | `number` | Minimum radius in km for earthquake alerts       | `20`                      |
| `default.default_sources`   | `table`  | List of data sources                             | `{"meteo", "usgs"}`       |

If `settings.location` is not set, the plugin uses [ip-api.com](http://ip-api.com) to detect your location.

---

## Usage

After installation and configuration, `weather.nvim` starts fetching data automatically based on your settings.

- **Manual Update**: Run `:WeatherNow` to trigger an immediate update.
- **Notifications**: Alerts appear via `nvim-notify` (if installed). Examples:
  - Weather: "25.3°C ☀️ Sunny" with high/low temps.
  - Earthquake: "Magnitude: 4.5 Coordinates: -122.4, 37.8 Place: San Francisco Time: 2023-10-15 14:30:00".

---

## Integration

### Lualine Integration

<img width="1512" alt="Screenshot 2025-05-11 at 2 39 27 PM" src="https://github.com/user-attachments/assets/cf2b6e46-f919-4428-b2fc-b969531ee29d" />

Display current weather in your status line with [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim). Here’s an excerpt from a custom configuration:

```lua
require('lualine').setup({
  options = {
    theme = {
      normal = {
        a = { bg = "#65D1FF", fg = "#112638", gui = "bold" },
        b = { bg = "#112638", fg = "#c3ccdc" },
        c = { bg = "#112638", fg = "#c3ccdc" },
      },
      -- Other modes defined...
    },
  },
  sections = {
    lualine_x = {
      { require("weather.lualine").default_c() },
      {
        require("lazy.status").updates,
        cond = require("lazy.status").has_updates,
        color = { fg = "#ff9e64" },
      },
      { "lsp_status" },
      { "filesize" },
      { "filetype" },
    },
  },
})
```

For the full configuration including all modes and additional components, refer to the [repository](https://github.com/athar-qadri/weather.nvim) and my [dotfiles] (https://github.com/athar-qadri/dotfiles).

---

## Contributing

Contributions are welcome! Please submit issues or pull requests on the [GitHub repository](https://github.com/athar-qadri/weather.nvim).

---

## License

Released under the [GPL-3.0 license](LICENSE).
