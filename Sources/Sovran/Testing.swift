//
//  Testing.swift
//  Sovran
//
//  Created by Brandon Sneed on 11/18/20.
//

import Foundation

#if DEBUG

/// Inquire as to whether we are within a Unit Testing environment.
var isUnitTesting: Bool = {
    let matches = Thread.callStackSymbols.filter { line in
        return line.contains("XCTest") || line.contains("xctest")
    }
    return matches.count > 0
}()

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
