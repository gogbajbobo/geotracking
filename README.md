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
Скопировать модель данных STGTTracker.xcdatamodel (или STGTTracker.xcdatamodeld) из Pods/STGT/ в текущий проект.

В настройках проекта добавить:
Targets / Info / Custom iOS Target Properties / Required background modes / + App registered for location updates
```

Использование
---

Запуск геотрекера:
```
    [[STGTTrackingLocationController sharedTracker] initDatabase:^(BOOL success) {
        [[STGTDataSyncController sharedSyncer] setAuthDelegate:[STGTAuthBasic sharedOAuth]];
    }];
```


Описание ошибок
---

`NO CONNECTION` - не удалось установить соединение с сервером.
`NO TOKEN` - не получен токен.
`SYNC FAIL` - потеря соединения с сервером во время синхронизации.
`RESPONSE ERROR` - ответ от сервера не xml.
`SYNC ERROR` - в ответе от сервера есть нода error.



