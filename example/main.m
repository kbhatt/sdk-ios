//
//  main.m
//  example
//
//  Created by Jesus Fernandez on 4/25/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PHARCLogic.h"

int main(int argc, char *argv[])
{
    IF_ARC(@autoreleasepool {, NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];)
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    NO_ARC([pool release];)
    return retVal;
    HAS_ARC(})
}
