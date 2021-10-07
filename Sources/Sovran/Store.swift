//
//  Store.swift
//  Sovran
//
//  Created by Brandon Sneed on 11/18/20.
//

import Foundation

public typealias SubscriptionID = Int

public class Store {
    // handles synchronizing state changes thru the system
    internal let updateQueue = DispatchQueue(label: "state.update.segment.com")
    // handles synchronizing subscription adds/removes
    internal let syncQueue = DispatchQueue(label: "state.sync.segment.com")
    internal var states = [Container]()
    internal var subscribers = [Subscription]()
    
    // bullshit
    public required init(from decoder: Decoder) throws {
    }
    
    public func encode(to encoder: Encoder) throws {
    }
    // end bullshit

    
    /// Creates a new Store instance.
    public init() { }
    
    /**
     Subscribe a closure to a particular type of state.
     
     Note: Subscribers are weakly held and will be discarded automatically when no longer present.
     
     - parameters:
         - subscriber: The object subscribing to a given state type.  Must conform to `Subscriber`.
         - initialState: Specifies that the handler should be called with current state upon subscribing. Default is false.
         - queue: Specifies the GCD queue this handler will be executed on.  Default is .main.
         - handler: A closure to be executed when the specified state type is modified.
     
     - returns: A SubscriptionID that can be used to unsubscribe at a later time.
     
     example:
     ```
     store.subscribe(self, initialState: true, queue: myBackgroundQueue) { (state: MyState) in
         // MyState was updated, react to it in some way.
         print(state)
     }
     ```
     */
    @discardableResult
    public func subscribe<T: State>(_ subscriber: Subscriber, initialState: Bool = false, queue: DispatchQueue = .main, handler: @escaping Handler<T>) -> SubscriptionID {
        let subscription = Subscription(owner: subscriber, queue: queue, handler: handler)
        syncQueue.sync {
            subscribers.append(subscription)
        }
        if initialState {
            if let state: T = currentState() {
                notify(subscribers: [subscription], state: state)
            }
        }
        return subscription.subscriptionID
    }
    
    /**
     Unsubscribe from state updates.  The supplied SubscriptionID will be used to perform the
     lookup and removal of a given subscription.
     
     - parameters:
        - identifier: The subscriberID given as a result from a previous subscribe() call.
     */
    public func unsubscribe(identifier: SubscriptionID) {
        syncQueue.sync {
            subscribers.removeAll { (subscription) -> Bool in
                return subscription.subscriptionID == identifier
            }
        }
    }

    /**
     Provides an instance of T as state within the system.  If a state type is
     provided more than once, it is simply ignored.  In DEBUG, this method
     will trigger an `assertionFailure` if the same state type is provided again.
     
     - parameter state: An struct instance conforming to `State`.
     */
    public func provide<T: State>(state: T) {
        let exists = existing(state: state)
        if exists.count != 0 {
            #if DEBUG
            // do a hard error if in debug mode (but not in a test suite).
            if !isUnitTesting {
                assertionFailure("\(state) has already been provided elsewhere and can't be provided twice!")
            }
            #endif
            // simply ignore since it's already there.
            return
        }
        let container = Container(state: state)
        updateQueue.sync {
            states.append(container)
        }
        
        // get any handlers that may have been added prior to
        // state being provided that work against state T
        let subs = existing(handlerType: T.self)
        notify(subscribers: subs, state: state)
    }
    
    /**
     Synchronously dispatch an Action with the intent of changing the state.  Reducers
     are run on a serial queue in the order the attached Actions are received.
     
     - parameter action: The action to be dispatched.  Must conform to `Action`.
     */
    public func dispatch<T: Action>(action: T) {
        // check if we have the isntance type requested.
        guard let target = existing(stateType: T.StateType.self).first else {
            return
        }
        // type the current state to match.
        guard var state = target.state as? T.StateType else {
            return
        }
        
        updateQueue.sync {
            // perform data reduction.
            state = action.reduce(state: state)
            // state is final now, apply it back to storage.
            target.state = state as State
        }
        
        // get any handlers that work against T.StateType
        let subs = existing(handlerType: T.StateType.self)
        notify(subscribers: subs, state: state)
    }
    
    /**
     Asynchronously dispatch an Action with the intent of changing the state.
     Reducers are run on a serial queue in the order their operations complete.
     
     - parameter action: The action to be dispatched.  Must conform to `AsyncAction`.
     */
    public func dispatch<T: AsyncAction>(action: T) {
        // do we even have an instance of the state type they're asking for?
        guard let target = existing(stateType: T.StateType.self).first else {
            return
        }
        // get a copy of the current state, typed as necessary.
        guard var state = target.state as? T.StateType else {
            return
        }
        
        // perform async operation.
        action.operation(state: state) { (result) in
            self.updateQueue.sync {
                // perform data reduction.
                state = action.reduce(state: state, operationResult: result)
                // state is final now, apply it back to storage.
                target.state = state as State
            }
            
            // get any handlers that work against T.StateType
            let subs = self.existing(handlerType: T.StateType.self)
            self.notify(subscribers: subs, state: state)
        }
    }
    
    /**
     Retrieves the current state of a given type from the Store
     
     - returns: A copy of the state instance type requested.
     
     example:
     ```
     let state: MyState = store.currentState()
     ```
     */
    public func currentState<T: State>() -> T? {
        guard let container = existing(stateType: T.self).first else {
            return nil
        }
        return container.state as? T
    }
}


// MARK: - Internal

/// Describes the details of a given subscription.
internal struct Subscription {
    weak var owner: Subscriber? = nil
    let queue: DispatchQueue
    let handler: Any
    let subscriptionID = createNextSubscriptionID()
    
    fileprivate static var nextSubscriptionID = 1
    fileprivate static func createNextSubscriptionID() -> SubscriptionID {
        let result = nextSubscriptionID
        nextSubscriptionID += 1
        return result
    }
}

/// Containment for held state.  The state var is updated as state changes occur.
internal class Container {
    var state: State
    init(state: State) { self.state = state }
}

// MARK: State lookup

extension Store {
    /// Returns any state instances matching T.
    internal func existing<T: State>(state: T) -> [Container] {
        var result = [Container]()
        updateQueue.sync {
            result = states.filter {
                return ($0.state as? T) != nil
            }
        }
        return result
    }
    /// Returns any state instances matching T.Type
    internal func existing<T: State>(stateType: T.Type) -> [Container] {
        var result = [Container]()
        updateQueue.sync {
            result = states.filter {
                return ($0.state as? T) != nil
            }
        }
        return result
    }
    
}

// MARK: Notfication

extension Store {
    /// Notify any subscribers with the new state.
    internal func notify<T: State>(subscribers: [Subscription], state: T) {
        for sub in subscribers {
            guard let handler = sub.handler as? Handler<T> else { continue }
            // call said handlers to inform them of the new state.
            if sub.owner != nil {
                // call the handlers asynchronously.
                sub.queue.async {
                    handler(state)
                }
            }
        }
        // cleanup any expired subscribers.
        clean()
    }
}

// MARK: Subscriber cleanup

extension Store {
    /// Removes any expired subscribers.
    internal func clean() {
        syncQueue.sync {
            subscribers = subscribers.filter {
                return $0.owner != nil
            }
        }
    }
}

// MARK: Subscriber lookup

extension Store {
    /// Returns subscribers matching a given state type.
    internal func existing<T: State>(handlerType: T.Type) -> [Subscription] {
        var result = [Subscription]()
        syncQueue.sync {
            result = subscribers.filter {
                let handlerMatch = ($0.handler as? Handler<T>) != nil
                return handlerMatch
            }
        }
        return result
    }
    
}
