//
//  SovranTests.swift
//  Sovran
//
//  Created by Brandon Sneed on 11/18/20.
//

import XCTest
@testable import Sovran


class StateInterfaceTests: XCTestCase, Subscriber {
    let store = Store()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        //store.reset()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testProvide() {
        store.provide(state: MessagesState())
        XCTAssertTrue(store.states.count == 1)
        
        store.provide(state: UserState())
        XCTAssertTrue(store.states.count == 2)
    }
    
    func testDoubleSubscribe() {
        // register some state
        store.provide(state: MessagesState())
        store.provide(state: UserState())
        
        // register some handlers for state changes
        store.subscribe(self) { (state: MessagesState) in
            print("unreadCount = \(state.unreadCount)")
        }
        
        // subscribe self to UserState twice.
        store.subscribe(self) { (state: UserState) in
            print("username = \(String(describing: state.username))")
        }

        // this should add a second listener for UserState
        store.subscribe(self) { (state: UserState) in
            print("username2 = \(String(describing: state.username))")
        }
        
        // we should have 3 subscriptions.  2 for UserState, one for MessagesState.
        XCTAssert(store.subscribers.count == 3)
    }
    
    func testDoubleProvide() {
        // register some state
        store.provide(state: MessagesState())
        store.provide(state: UserState())
        
        // this should do nothing since UserState has already been provided.
        // in use, this will assert in DEBUG mode, outside of tests.
        store.provide(state: UserState())
        
        XCTAssert(store.states.count == 2)
    }
    
    func testDispatch() {
        // register some state
        store.provide(state: MessagesState())

        let trigger = expectation(description: "triggered")
        trigger.expectedFulfillmentCount = 2
        
        var triggerCount = 0
        
        // register some handlers for state changes
        store.subscribe(self, initialState: true) { (state: MessagesState) in
            triggerCount += 1
            trigger.fulfill()

            if triggerCount < 2 {
                return
            }
            // now we got hit by the action, verify the expected value.
            XCTAssertTrue(state.unreadCount == 22)
        }
        
        let action = MessagesUnreadAction(value: 22)
        store.dispatch(action: action)
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testAsyncDispatch() {
        // register some state
        store.provide(state: MessagesState())
        
        let trigger = expectation(description: "triggered")
        trigger.expectedFulfillmentCount = 2
        
        var triggerCount = 0

        // register some handlers for state changes
        store.subscribe(self, initialState: true) { (state: MessagesState) in
            triggerCount += 1
            
            trigger.fulfill()
            
            if triggerCount < 2 {
                return
            }
            // now we got hit by the action, verify the expected value.
            XCTAssertTrue(state.unreadCount == 666)
        }
        
        let action = MessagesUnreadAsyncAction(drop: false, value: 666)
        store.dispatch(action: action)
        
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDroppedAsyncDispatch() {
        // register some state
        store.provide(state: MessagesState())
        
        let trigger = expectation(description: "triggered")
        trigger.expectedFulfillmentCount = 2
        
        var triggerCount = 0

        // register some handlers for state changes
        store.subscribe(self, initialState: true) { (state: MessagesState) in
            triggerCount += 1
            
            trigger.fulfill()
            
            if triggerCount < 2 {
                return
            }
            
            XCTAssertTrue(state.unreadCount != 666)
        }
        
        let action = MessagesUnreadAsyncAction(drop: true, value: 666)
        store.dispatch(action: action)
        
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testUnprovidedStateAsyncDispatch() {
        // register some state
        store.provide(state: MessagesState())
        
        let trigger = expectation(description: "triggered")
        trigger.isInverted = true

        // register some handlers for state changes
        store.subscribe(self, initialState: true) { (state: NotProvidedState) in
            // we should never get here because NotProvidedState isn't what's in the store.
            trigger.fulfill()
        }
        
        let action = NotProvidedAsyncAction()
        // this action should get dropped, because there's no matching state for it.
        store.dispatch(action: action)
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testUnprovidedStateDispatch() {
        // register some state
        store.provide(state: MessagesState())
        
        let trigger = expectation(description: "triggered")
        trigger.isInverted = true

        // register some handlers for state changes
        store.subscribe(self, initialState: true) { (state: NotProvidedState) in
            // we should never get here because NotProvidedState isn't what's in the store.
            trigger.fulfill()
        }
        
        let action = NotProvidedAction()
        // this action should get dropped, because there's no matching state for it.
        store.dispatch(action: action)
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnsubscribeForAction() {
        // register some state
        store.provide(state: MessagesState())

        let trigger = expectation(description: "triggered")

        // register some handlers for state changes
        let identifier = store.subscribe(self) { (state: MessagesState) in
            // now we got hit by the action, verify the expected value.
            XCTAssertTrue(state.unreadCount == 22)
            // if this gets hit twice, we'll get an error about multiple calls to the trigger.
            trigger.fulfill()
        }
        
        let action = MessagesUnreadAction(value: 22)
        store.dispatch(action: action)
        
        store.unsubscribe(identifier: identifier)
        
        // this should be ignored since we've unsubscribed.
        let nextAction = MessagesUnreadAction(value: 11)
        store.dispatch(action: nextAction)
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnsubscribeForAsyncAction() {
        // register some state
        store.provide(state: MessagesState())
        
        let trigger = expectation(description: "triggered")

        // register some handlers for state changes
        let identifier = store.subscribe(self) { (state: MessagesState) in
            trigger.fulfill()
            // now we got hit by the action, verify the expected value.
            XCTAssertTrue(state.unreadCount == 666)
        }
        
        let action = MessagesUnreadAsyncAction(drop: false, value: 666)
        store.dispatch(action: action)
        
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))
        
        store.unsubscribe(identifier: identifier)
        
        let nextAction = MessagesUnreadAsyncAction(drop: false, value: 10)
        store.dispatch(action: nextAction)
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAlternateSubscriptionSyntax() {
        // this is more of a syntax test.  we don't really care if it's
        // a success, just that it builds.
        // register some state
        
        store.provide(state: MessagesState())

        // register some handlers for state changes
        store.subscribe(self) { (state: MessagesState) in
            // do nothing
        }
        
        let action = MessagesUnreadAction(value: 22)
        store.dispatch(action: action)
    }

    func testSubscriptionIDIncrement() {
        let handler: Handler<MessagesState> = { MessagesState in
            print("booya")
        }
        let s1 = Subscription(owner: self, queue: .main, handler: handler)
        let s2 = Subscription(owner: self, queue: .main, handler: handler)
        let s3 = Subscription(owner: self, queue: .main, handler: handler)

        XCTAssertTrue(s2.subscriptionID > s1.subscriptionID)
        XCTAssertTrue(s3.subscriptionID > s2.subscriptionID)
    }
    
    func testGetCurrentState() {
        let state = MessagesState(unreadCount: 1, outgoingCount: 2, messages: [], outgoing: [])
        store.provide(state: state)
        
        let messageState: MessagesState? = store.currentState()
        XCTAssertTrue(messageState?.unreadCount == 1)
    }

    func testConcurrentDispatch() {
        let outerIterationCount = 10
        let innerIterationCount = 100_000

        for outerIteration in 1..<outerIterationCount {
            store.provide(state: MessagesState())

            var updates = [UInt]()
            store.subscribe(self, initialState: false) { (state: MessagesState) in
                updates.append(state.unreadCount)
            }

            DispatchQueue.concurrentPerform(iterations: innerIterationCount) { index in
                let action = MessagesUnreadAction(value: UInt((outerIteration * innerIterationCount) + index))
                store.dispatch(action: action)
            }

            RunLoop.main.run(until: Date())

            XCTAssertEqual(updates.count, innerIterationCount)
            let sortedUpdates = updates.sorted()
            let monotonicallyIncreasing = zip(sortedUpdates, sortedUpdates.dropFirst()).allSatisfy(<)
            XCTAssertTrue(monotonicallyIncreasing)
        }
    }
}
