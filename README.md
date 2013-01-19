geotracking (STGT)
==========

Установка
---
```pod 'STGT', :git => "https://github.com/gogbajbobo/geotracking.git", :branch => 'master'```

Настройка
---
```
Скопировать модель данных STGTTracker.xcdatamodel из Pods/STGT/ в текущий проект.
```

Использование
---

`[STGTTrackingLocationController sharedTracker]` - доступ к геотрекеру.
`[STGTDataSyncController sharedSyncer]` - доступ к синхронизатору.


