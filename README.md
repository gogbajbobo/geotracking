geotracking (STGT)
==========

Установка
---
Проект использует CocoaPods — http://cocoapods.org

При использовании проекта как stand-alone приложения необходимо выполнить установку библиотек:
``` pod install ```

При использовании проекта как части другой программы необходимо добавить в Podfile строчку:
```pod 'STGT', :git => "https://github.com/gogbajbobo/geotracking.git", :branch => 'master'```

Настройка
---
```
Скопировать модель данных STGTTracker.xcdatamodel из Pods/STGT/ в текущий проект.

В настройках проекта добавить:
Targets / Info / Custom iOS Target Properties / Required background modes / + App registered for location updates
```

Использование
---

`[STGTTrackingLocationController sharedTracker]` - доступ к геотрекеру.

`[STGTDataSyncController sharedSyncer]` - доступ к синхронизатору.

