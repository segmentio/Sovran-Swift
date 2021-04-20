//
//  ExampleStates.swift
//  Sovran
//
//  Created by Brandon Sneed on 11/18/20.
//

import Foundation
@testable import Sovran

struct Message {
    let from: String
    let to: String
    let content: String
    let photos: [URL]
}

// MARK: States

struct MessagesState: State {
    var unreadCount: UInt = 0
    var outgoingCount: UInt = 0
    var messages = [Message]()
    var outgoing = [Message]()
}

struct UserState: State {
    var username: String? = nil
    var token: String? = nil
}

struct NotProvidedState: State {
    var value: UInt = 0
}

// MARK: Actions

struct MessagesUnreadAction: Action {
    let value: UInt
    
    func reduce(state: MessagesState) -> MessagesState {
        var newState = state
        newState.unreadCount = value
        return newState
    }
}

struct MyResultType {
    let value: UInt
}

struct MessagesUnreadAsyncAction: AsyncAction {
    let drop: Bool
    let value: UInt
    
    func operation(state: MessagesState, completion: @escaping (MyResultType?) -> Void) {
        DispatchQueue.main.async {
            sleep(1)
            let result = MyResultType(value: value)
            completion(result)
        }
    }
    
    func reduce(state: MessagesState, operationResult: MyResultType?) -> MessagesState {
        var newState = state
        
        if !drop {
            if let operationResult = operationResult {
                newState.unreadCount = operationResult.value
            }
        }
        
        return newState
    }
}

struct NotProvidedAction: Action {
    func reduce(state: NotProvidedState) -> NotProvidedState {
        return state
    }
}

struct NotProvidedAsyncAction: AsyncAction {
    func operation(state: NotProvidedState, completion: @escaping (MyResultType?) -> Void) {
        // do nothing.
    }
    
    func reduce(state: NotProvidedState, operationResult: MyResultType?) -> NotProvidedState {
        return state
    }
}



