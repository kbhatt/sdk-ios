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

#import "MTSeleniumCommand.h"
#import "MTConvertType.h"
#import "MTConstants.h"
#import "NSString+MonkeyTalk.h"


@implementation MTSeleniumCommand
@synthesize mtEvent, xPath, alternateID, command, args, currentOrdinal, htmlTag;

- (id) initWithMTCommandEvent:(MTCommandEvent *)event {
    self = [super init];
    if (self) {
        mtEvent = event;
    }
    
    return self;
}

- (NSString *) htmlTag {
    NSString *mtComponent = [MTConvertType convertedComponentFromString:mtEvent.className isRecording:YES];
    NSString *tag = [NSString stringWithFormat:mtComponent];
    
    if ([mtComponent isEqualToString:MTComponentButtonSelector ignoreCase:YES])
        tag = @"input";
    else if ([mtComponent isEqualToString:MTComponentSelector ignoreCase:YES])
        tag = @"select";
    else if ([mtComponent isEqualToString:MTComponentLabel ignoreCase:YES])
        tag = @"a";
    else if ([mtComponent isEqualToString:MTComponentView ignoreCase:YES] ||
             [mtComponent isEqualToString:MTComponentHTMLTag ignoreCase:YES])
        tag = @"*";
    
    return tag;
}

- (NSString *) xPath {
    NSString *convertedCommand;
    
    NSString *mtComponent = [MTConvertType convertedComponentFromString:mtEvent.className isRecording:YES];
    NSString *path = [NSString stringWithFormat:@"[@id='%@' or @name='%@' or @value='%@' or text()='%@' or @title='%@' or @class='%@']",
                      mtEvent.monkeyID,mtEvent.monkeyID,mtEvent.monkeyID, mtEvent.monkeyID,mtEvent.monkeyID,mtEvent.monkeyID];
    BOOL isOrdinal = NO;
    NSInteger find = 0;
    
    if ([mtEvent.monkeyID rangeOfString:@"#"].location == 0) {
        find = [[mtEvent.monkeyID substringFromIndex:1] integerValue];
        find -= currentOrdinal;
        path = [NSString stringWithFormat:@"[%i]",find];
        isOrdinal = YES;
    }
    
    // Default converted command — handles most components
    convertedCommand = [NSString 
                        stringWithFormat:@"//%@%@",self.htmlTag,path];
    
    if ([[mtEvent.monkeyID lowercaseString] rangeOfString:@"xpath="].location != NSNotFound) {
        // Use Monkey ID as xpath
        convertedCommand = [NSString 
                            stringWithFormat:@"%@",path];
    } else if ([mtComponent isEqualToString:MTComponentButton ignoreCase:YES]) {

        // May be a submit/reset input
        self.alternateID = [NSString 
                            stringWithFormat:@"//input%@",path];
        
        if (isOrdinal) {
            // Special alternateID
        }
    } else if ([mtComponent isEqualToString:MTComponentButtonSelector ignoreCase:YES]) {
        // ButtonSelector creates xPath for radio group
        if ([mtEvent.args count] > 0) {
            if ([mtEvent.command isEqualToString:MTCommandSelect ignoreCase:YES]) {
                // Select command uses value to select in a radio group
                path = [path stringByReplacingOccurrencesOfString:[NSString 
                                                                   stringWithFormat:@"or @value='%@']",
                                                                   mtEvent.monkeyID] 
                                                       withString:[NSString 
                                                                   stringWithFormat:@"and @value='%@']",
                                                                   [mtEvent.args objectAtIndex:0]]];
                
                if (isOrdinal)
                    path = [NSString stringWithFormat:@"[@type='radio' and @value='%@'][%i]",
                            [mtEvent.args objectAtIndex:0],
                            currentOrdinal];
                
                convertedCommand = [NSString 
                                    stringWithFormat:@"(//input%@)",path];
            } else {
                // SelectIndex uses value of arg as index in xPath
                if (isOrdinal)
                    path = [NSString stringWithFormat:@"[@type='radio'][%i]",
                            find];
                
                convertedCommand = [NSString stringWithFormat:@"(//input%@)[%@]",
                                    path,[mtEvent.args objectAtIndex:0]];
            }
        }
    } else if ([mtComponent isEqualToString:MTComponentToggle ignoreCase:YES]) {
        // Toggle use default input element xPath
        if (isOrdinal) {
            convertedCommand = [NSString 
                                stringWithFormat:@"(//input[@type='checkbox'])%@",path];
            return convertedCommand;
        }
    } else if ([mtComponent isEqualToString:MTComponentSelector ignoreCase:YES]) {     
        // Selector finds select web element
        if (mtEvent.args && [mtEvent.args count] > 0) {
            // If there are args, add option to xPath
            
            if ([mtEvent.command isEqualToString:MTCommandSelectIndex ignoreCase:YES])
                convertedCommand = [convertedCommand stringByAppendingFormat:@"/option[%@]",
                                    [mtEvent.args objectAtIndex:0]];
            else if ([mtEvent.command isEqualToString:MTCommandSelect ignoreCase:YES])
                convertedCommand = [convertedCommand stringByAppendingFormat:@"/option[@value='%@' or ./text()=%@]",
                                    [mtEvent.args objectAtIndex:0], [mtEvent.args objectAtIndex:0]];
        }
    } else if ([mtComponent isEqualToString:MTComponentTable ignoreCase:YES]) {
        // Table finds table web element
        if (mtEvent.args && [mtEvent.args count] > 0) {
            if ([mtEvent.command isEqualToString:MTCommandSelect ignoreCase:YES]) {
                // For select command, create xPath finding text of tr or td
                NSString *origString = [NSString stringWithFormat:@"%@",convertedCommand];
                convertedCommand = [convertedCommand stringByAppendingFormat:@"//tr[contains(text(),'%@')]",
                                    [mtEvent.args objectAtIndex:0]];
                
                self.alternateID = [origString stringByAppendingFormat:@"//td[contains(text(),'%@')]",
                                    [mtEvent.args objectAtIndex:0]];
            } else {
                // SelectIndex or SelectRow use arg and index
                // Arg1 used for table row
                convertedCommand = [convertedCommand stringByAppendingFormat:@"//tr[%@]",
                                    [mtEvent.args objectAtIndex:0]];
                
                // Arg2 used for table cell and appended to xPath
                if ([mtEvent.args count] > 1)
                    convertedCommand = [convertedCommand stringByAppendingFormat:@"//td[%@]",
                                        [mtEvent.args objectAtIndex:1]];
            }
        }
        
    }
    
    return convertedCommand;
}

- (NSString *) command {
    NSString *seleniumCommand;
    NSString *mtComponent = [MTConvertType convertedComponentFromString:mtEvent.className isRecording:YES];
    
    if ([mtEvent.command isEqualToString:MTCommandEnterText ignoreCase:YES])
        seleniumCommand = @"type:";
    else if ([mtEvent.command isEqualToString:MTCommandClear ignoreCase:YES])
        seleniumCommand = @"clear:";
    else if (!([mtComponent isEqualToString:MTComponentTable ignoreCase:YES] ||
               [mtComponent isEqualToString:MTComponentButtonSelector ignoreCase:YES]) && 
             ([mtEvent.command isEqualToString:MTCommandOn ignoreCase:YES] ||
              [mtEvent.command isEqualToString:MTCommandSelect ignoreCase:YES]))
        seleniumCommand = @"setChecked:";
    else if ([mtEvent.command isEqualToString:MTCommandOff ignoreCase:YES])
        seleniumCommand = @"toggleSelected";
    else
        seleniumCommand = @"click:";
    
    return seleniumCommand;
}

- (NSDictionary *) args {
    if (mtEvent.args != nil && [mtEvent.args count] > 0) {
        NSDictionary *argsDict = [NSDictionary dictionaryWithObject:[mtEvent.args objectAtIndex:0] forKey:@"value"];
        
        return argsDict;
    }
    
    return nil;
}

//- (void) dealloc {
//    [super dealloc];
//    [xPath release];
//    [command release];
//    [args release];
//}

@end
