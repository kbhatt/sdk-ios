/*  MonkeyTalk - a cross-platform functional testing tool
 Copyright (C) 2012 Gorilla Logic, Inc.
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.
 
 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>. */

#import "MTComponentTree.h"
#import "MTOrdinalView.h"
#import "MonkeyTalk.h"
#import "UIView+MTReady.h"
#import "MTConvertType.h"
#import "MTCommandEvent.h"
#import "MTGetVariableCommand.h"

@implementation MTComponentTree

+ (NSInteger) superCountForView:(UIView *)view {
    NSInteger superCount = -1;
    while (view) {
        superCount++;
        view = view.superview;
    }
    
    return superCount;
}

+ (NSString *) treeIndent:(NSInteger)count {
    NSString *indent = @"";
    
    for (int i = 0; i < count; i++)
        indent = [indent stringByAppendingFormat:@"    "];
    
    return indent;
}

+ (NSArray *) componentTree {
    NSMutableArray *tree = [[NSMutableArray alloc] init];
    
//    dispatch_async(dispatch_get_main_queue(), ^{
        [MTOrdinalView buildFoundComponentsStartingFromView:nil havingClass:@"MTComponentTree"];
        NSMutableArray *rawTree = [[NSMutableArray alloc] init];
        
        for (UIView *view in [MonkeyTalk sharedMonkey].foundComponents) {
            MTCommandEvent *event = nil;
            NSString *value = nil;
            NSString *component = [MTConvertType convertedComponentFromString:[NSString stringWithFormat:@"%@",[view class]] isRecording:YES];
            NSString *className = [NSString stringWithFormat:@"%@",[view class]];
            NSString *indent = [[self class] treeIndent:[[self class] superCountForView:view]];
            NSLog(@"%@%@ %@",indent,component,[view monkeyID]);
            
            NSMutableArray *childArray = [[NSMutableArray alloc] init];
            NSString *visible = @"true";
            
            if (view.hidden)
                visible = @"false";
            
            event = [[MTCommandEvent alloc] init:MTCommandGet className:component monkeyID:view.monkeyID args:[NSArray arrayWithObject:@"value"]];
            
            value = [MTGetVariableCommand execute:event];
            
            if (!value || ([value respondsToSelector:@selector(rangeOfString:)] && [value rangeOfString:@"is not a valid keypath"].location != NSNotFound) || ![value respondsToSelector:@selector(rangeOfString:)])
                value = @"";
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:component forKey:@"ComponentType"];
            [dict setObject:className forKey:@"className"];
            [dict setObject:view.monkeyID forKey:@"monkeyId"];
            [dict setObject:childArray forKey:@"children"];
            [dict setObject:value forKey:@"value"];
            [dict setObject:visible forKey:@"visible"];
            
            // If we want to add childCount to json, uncomment following line
//            [dict setObject:[NSString stringWithFormat:@"%i",[view.subviews count]] forKey:@"childCount"];
            [rawTree addObject:dict];
            
            if ([[self class] superCountForView:view] > 0) {
//                [tree addObject:dict];
                for (NSMutableDictionary *prevDict in rawTree) {
                    NSString *prevClass = [prevDict objectForKey:@"className"];
                    NSString *prevMid = [prevDict objectForKey:@"monkeyId"];
                    NSString *superClass = [NSString stringWithFormat:@"%@",[view.superview class]];
                    NSString *superMid = view.superview.monkeyID;
                    
                    if ([superClass isEqualToString:prevClass] &&
                        [prevMid isEqualToString:superMid]) {
                        NSMutableArray *prevChild = [prevDict objectForKey:@"children"];
                        [prevChild addObject:dict];
//                        [tree removeObject:prevDict];
                        break;
                    }
                }
                
            } else {
                [tree addObject:dict];
            }
            
//            NSLog(@"%@%@",indent,dict);
            
            [dict release];
            [childArray release];
//            NSLog(@"parent: %@",view.superview);
        }

//        NSLog(@"tree: %@",tree);
//        [tree release];
        [rawTree release];
        
        [[MonkeyTalk sharedMonkey].foundComponents removeAllObjects];
        [MonkeyTalk sharedMonkey].foundComponents = nil;
//    }); 
    
    return tree;
}

@end
