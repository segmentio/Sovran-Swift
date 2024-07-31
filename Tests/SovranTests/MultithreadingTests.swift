//
//  MultithreadingTests.swift
//  
//
//  Created by Brandon Sneed on 7/29/24.
//

import XCTest
@testable import Sovran


// Define the state
struct MyState: State, Codable, Equatable {
    var value: Int
}

// Define another state
struct AnotherState: State, Codable, Equatable {
    var count: Int
}

// Define actions
struct IncrementMyStateAction: Action {
    func reduce(state: MyState) -> MyState {
        var newState = state
        newState.value += 1
        return newState
    }
}

struct IncrementAnotherStateAction: Action {
    func reduce(state: AnotherState) -> AnotherState {
        var newState = state
        newState.count += 1
        return newState
    }
}


final class MultithreadingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // Setup the store
        let store = Store()
        let initialMyState = MyState(value: 0)
        let initialAnotherState = AnotherState(count: 0)

        store.provide(state: initialMyState)
        store.provide(state: initialAnotherState)

        // Perform concurrent dispatch actions using GCD
        let group = DispatchGroup()
        let queue = DispatchQueue.global()

        let numThreads = 10
        let numActionsPerThread = 10000

        let startTime = DispatchTime.now()
        
        for _ in 0..<numThreads {
            queue.async(group: group) {
                for _ in 0..<numActionsPerThread {
                    store.dispatch(action: IncrementMyStateAction())
                    store.dispatch(action: IncrementAnotherStateAction())
                }
            }
        }

        // Wait for all threads to finish
        group.wait()
        
        let endTime = DispatchTime.now()
        let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let elapsedTimeInMilliSeconds = Double(elapsedTime) / 1_000_000.0
        print("Time taken for 200_000 actions (2 per thread): \(elapsedTimeInMilliSeconds)ms");

        // Assertions
        let finalMyState: MyState = store.currentState()!
        let finalAnotherState: AnotherState = store.currentState()!

        let expectedMyStateValue = numThreads * numActionsPerThread
        let expectedAnotherStateCount = numThreads * numActionsPerThread

        assert(finalMyState.value == expectedMyStateValue, "MyState value: \(finalMyState.value), Expected: \(expectedMyStateValue)")
        assert(finalAnotherState.count == expectedAnotherStateCount, "AnotherState count: \(finalAnotherState.count), Expected: \(expectedAnotherStateCount)")

        print("Tests passed!")
        print("Final MyState value: \(finalMyState.value)")
        print("Final AnotherState count: \(finalAnotherState.count)")
    }
}
