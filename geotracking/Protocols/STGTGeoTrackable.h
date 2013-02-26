//
//  STGTGeoTrackable.h
//  geotracking
//
//  Created by kovtash on 25.02.13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "STGTDataSyncController.h"

// ========Протокол сессии========
@protocol STGTSession <NSObject> // не подлежит реализации
- (void) initWithUID:(NSString *) uid AuthDelegate(id) authDelegate;
- (void) completeSession()
@end

// ========Протоколы менеджера сессий=========
/* Менеджер сессий - управляет сессиями пользователей и устройств. У каждого пользователя или устройства есть уникальный неизменяемый UID.
 Менеджер обеспечивает сохдание и асинхронное завершение сесиий. Для каждого UID в каждый момент времени может существовать только одна сессия.
 */

@protocol STGTSessionManagement <NSObject>
- (void) startSessionForUID:(NSString *) uid AuthDelegate(id) authDelegate; //Создание сессии или ее активация, если сессия уже существует. Если в момент старта сессии уже имеется активная сессия, перед стартом новой сессии текущей сессии передается команда на завершение.
- (void) stopCurrentSession()
@end

@protocol STGTSessionManager <NSObject>
- (void) sessionCompletionFinished:(id) sender; //callback - вызываемый сессией после окончания процедуры завершения сессии
@end

// =======Протокол управляемой сессии==========
@protocol STGTManagedSession <STGTSession>
@property (weak,nonatomic) id <STGTSessionManager> manager; // ссылка на менеджер сессий, которому будет возвращен callbak sessionCompletionFinished
@end

// Объект, предназначенный заменить синглтон STGTTrackingLocationController
@interface STGTSession : NSObject <STGTManagedSession>
@property (strong,nonatomic) STGTLocationManagedDocument *locationManagedDocument;
@property (strong,nonatomic) STGTDataSyncController *syncController;
@property (strong,nonatomic) CLLocationManager *locationManager;
@end