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
    var found = false
    for bundle in Bundle.allFrameworks {
        print(bundle.bundleURL)
//        if bundle.bundleURL.lastPathComponent == "XCTest.framework" {
//            found = true
//            break
//        }
    }
    return found
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
