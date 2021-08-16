//
//  Testing.swift
//  Sovran
//
//  Created by Brandon Sneed on 11/18/20.
//

import Foundation

#if DEBUG

/// Inquire as to whether we are within a Test environment.
func isTesting() -> Bool {
    print("XCTestCase present = \(NSClassFromString("XCTestCase") != nil)")
    print("XCTest present = \(NSClassFromString("XCTest") != nil)")
    return (NSClassFromString("XCTestCase") != nil)
}

/// Allows calls to throw to simply be given a String.
extension String: Error { }

extension Store {
    /// Resets the state system.  Useful for testing.
    internal func reset() {
        syncQueue.sync {
            subscribers.removeAll()
        }
        updateQueue.sync {
            states.removeAll()
        }
    }
}

#endif
