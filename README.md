# cutie-sysmonitor

A GNOME System Monitor-style resource monitor for Cutie Shell, built on
`qml-module-cutie`.

The overview links to five live-monitor pages and a Device Information page:

- **Performance** — overall CPU usage graph plus a per-core usage grid.
- **Memory** — RAM usage graph, a Used/Cached/Buffers/Available breakdown,
  and swap usage.
- **Network** — aggregate up/down throughput graph and a per-interface
  list with live rates.
- **Disk** — storage activity and throughput.
- **Battery** — UPower charge history, live charge/energy/voltage/power/state
  and time estimate, plus a swipeable battery details card.
- **Device Information** — Cutie Shell, operating system, kernel, and hardware
  details from `Cutie.Systeminfo`.

## Architecture

All the actual system-stat reading lives in a single C++ backend,
`SystemMonitor` (`src/systemmonitor.h` / `.cpp`), registered as a QML
singleton under `Cutie.SysMonitor 1.0` (`SysMonitor`). It polls once a
second on a `QTimer` and reads straight from procfs:

- `/proc/stat` — aggregate + per-core CPU usage, computed from the delta
  between two samples (`(total - idle) delta / total delta`), not
  instantaneous /proc values.
- `/proc/meminfo` — total/used/available/cached/buffers, swap used/total.
  "Used" is `MemTotal - MemAvailable`, matching what `free`/GNOME System
  Monitor report rather than the more naive (and misleading)
  `MemTotal - MemFree`.
- `/proc/net/dev` — per-interface RX/TX byte counters, converted to
  rates using the poll interval. `lo` is filtered out.

Each metric keeps a rolling 60-sample history (`cpuHistory`,
`memHistory`, `netRxHistory`, `netTxHistory`) exposed as `QVariantList`,
which the QML side feeds into `LineGraph.qml` — a small reusable Canvas
component that scrolls a filled line graph, auto-scaling to the data
unless `maxValue` is given (used to pin CPU/Memory to a fixed 0-100%
scale).

No polling, timers, or file I/O happen in QML — pages just bind to
`SysMonitor` properties, matching how `CutieVolume`/`CutieWlc` are
consumed elsewhere in the shell.

## Building

Same shape as `cutie-settings`:

```sh
mkdir build && cd build
cmake ..
cmake --build .
```

Requires `qml6-module-cutie`, `qml6-module-cutiebattery`, and
`qml6-module-cutiesysteminfo` to be installed (for `Cutie`/`Atmosphere`,
`Cutie.Battery`, and `Cutie.Systeminfo`).

## Notes / follow-ups

- Per-core CPU count is read once at startup from `/proc/stat`; if you
  want to handle CPU hotplug (offlining cores at runtime) the core
  count would need to be re-derived on each poll instead of cached in
  the constructor.
- Network history currently sums all non-loopback interfaces into one
  graph. If you want per-interface history/graphs instead of just a
  live-rate list, that's a small extension to `SystemMonitor` (a
  `QMap<QString, QVariantList>` per iface) rather than a redesign.
- `formatBytes`/`formatRate` use base-1024 units labelled B/KB/MB/GB —
  swap to base-1000 labelling if you'd rather match `df`-style
  conventions.
