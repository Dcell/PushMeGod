//
//  PushBridging.h
//  PushMeGod
//
//  Created by ding_qili on 17/1/7.
//  Copyright © 2017年 ding_qili. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PushBridging : NSObject
@property (strong,nonatomic) NSString *certificate;

- (BOOL)connect:(BOOL)debug;
- (void)disconnect;
-(BOOL)push:(NSString *)token payload:(NSString *)payload;
@end
