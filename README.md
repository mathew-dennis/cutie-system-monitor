# libcutiebattery

`Cutie.Battery` QML module for cutie-settings/cutie-sysmonitor.

```qml
import Cutie.Battery
```

## `BatteryHistory` (singleton)

D-Bus client for UPower's battery state and 24h charge history. See
`src/cutiebatteryhistory.h` for the full property list
(`percentage`, `stateString`, `timeToEmpty`/`timeToFull`, `energyRate`,
`energy`, `voltage`, `capacity`, `energyFull`, `energyFullDesign`,
`technology`, `voltageMinDesign`, `chargeStartThreshold`,
`chargeEndThreshold`, `points`, `available`). Threshold values have matching
`hasChargeStartThreshold` / `hasChargeEndThreshold` flags because many devices
do not expose charge thresholds. Values are read from the real battery device;
the aggregate display device supplies percentage, state, and time estimates.

## `PowerSaving` (singleton)

GSettings client for [mobile-power-saver-droidian](https://github.com/adishatz/mobile-power-saver)'s
`org.adishatz.Mps` schema - the screen-off/bluetooth/radio power-saving
toggles shown on the battery settings page. `available` is `false` if
mobile-power-saver-droidian isn't installed; check it before relying on
the toggles doing anything.

```qml
Switch {
    enabled: PowerSaving.available
    checked: PowerSaving.screenOffPowerSaving
    onToggled: PowerSaving.screenOffPowerSaving = checked
}
```

Also exposes `bluetoothPowerSaving`, `radioPowerSaving`, and generic
`stringListValue(key)` / `setStringListValue(key, value)` for the
schema's app/service exclusion-list keys (`suspend-apps-blacklist`,
`suspend-user-services`, etc.) - not wired to dedicated properties, for
use by a future exclusion-list editor page.
