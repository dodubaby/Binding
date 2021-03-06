//
//  BindingTests.m
//  BindingTests
//
//  Created by Jeremy Tregunna on 1/27/2014.
//  Copyright (c) 2014 Jeremy Tregunna. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Binding.h"

@interface Binding (PrivateMethodsForBindingTests)
@property (nonatomic, readonly) BOOL completed;
@end

@interface BindingTests : XCTestCase
@property (nonatomic, strong) Binding* binding;
@property (nonatomic, strong) NSString* dummy;
@property (nonatomic, strong) NSString* destination;
@end

@implementation BindingTests

- (void)setUp
{
    [super setUp];

    self.binding = Bind(self, dummy);
}

- (void)tearDown
{
    self.dummy       = nil;
    self.destination = nil;

    [super tearDown];
}

- (void)testBindingNotNil
{
    XCTAssertNotNil(self.binding, @"Binding must not be nil");
}

- (void)testFiresSingleNextBlockOnlyOnceWhenObservedValueChanges
{
    __block int count = 0;

    [self.binding next:^(NSString* value) {
        XCTAssertEqualObjects(value, @"single next block", @"Only fired once");
        ++count;
        XCTAssertEqual(count, 1, @"Must only fire this block once");
    }];

    self.dummy = @"single next block";

    if(count == 0)
        XCTFail(@"Did not call block");
}

- (void)testFiresTwoBlocksOnceWhenObservedValueChanges
{
    __block int count1 = 0;
    __block int count2 = 0;

    [self.binding next:^(NSString* value) {
        XCTAssertEqualObjects(value, @"next block", @"Only fired once");
        ++count1;
        XCTAssertEqual(count1, 1, @"Must only fire this block once");
    }];

    [self.binding next:^(NSString* value) {
        XCTAssertEqualObjects(value, @"next block", @"Only fired once");
        ++count2;
        XCTAssertEqual(count1, 1, @"Must only fire this block once");
    }];

    self.dummy = @"next block";

    if(count1 == 0 || count2 == 0)
        XCTFail(@"Did not call blocks");
}

- (void)testWontFireWhenValueChangesToNil
{
    self.dummy = @"not nil";

    [self.binding next:^(NSString* value) {
        XCTFail(@"Don't call block when value changes to nil");
    }];

    self.dummy = nil;
}

- (void)testWontFireAfterBeingMarkedComplete
{
    [self.binding next:^(NSString* value) {
        XCTFail(@"Don't call block when completed");
    }];
    [self.binding complete];

    self.dummy = @"won't fire";
}

- (void)testNoCrashAfterCompletingTwice
{
    [self.binding complete];
    XCTAssertNoThrow([self.binding complete], @"Doesn't crash if completed multiple times");
}

- (void)testPropogatesValueThroughToSecondBindingWhenJoined
{
    Binding* b = Bind(self, destination);
    [self.binding relate:b];

    self.dummy = @"propogation";

    XCTAssertEqualObjects(self.destination, @"propogation", @"Propogates values through to the destination key path when joined.");
}

- (void)testDoesntCompleteJoinedBindingsWhenOneBindingIsCompleted
{
    Binding* b = Bind(self, destination);
    [self.binding relate:b];
    [self.binding complete];

    XCTAssertFalse(b.completed, @"Joined bindings must not be complete when a binding they are joined to completes");
}

@end
