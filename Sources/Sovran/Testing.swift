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
    #if os(Linux)
    let found = Thread.main.threadDictionary.allKeys.contains { key in
        return (key as? String)?.split(separator: ".").contains("xctest") == true
    }
    #else
    let env = ProcessInfo.processInfo.environment
    let found = (env["XCTestConfigurationFilePath"] != nil)
    #endif
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
