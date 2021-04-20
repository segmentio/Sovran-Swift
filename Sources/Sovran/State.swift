//
//  State.swift
//  Sovran
//
//  Created by Brandon Sneed on 11/18/20.
//

import Foundation

/**
 Generic state protocol.  All state structures must conform to this.  It is highly
 recommended that *only* structs conform to this protocol.  The system relies
 on a struct's built-in copy mechanism to function.  Behavior when applied to classes
 is currently undefined and will likely result in errors.
 */
public protocol State: Any { }

/**
 Typealias for state handlers implemented by subscribers.  T represents
 the type of state desired.
 
 example:
 ```
 store.subscribe(self) { (state: MyState) in
     // MyState was updated, react to it in some way.
     print(state)
 }
 ```
 In the example above, `T` represents `MyState`.
 */
public typealias Handler<T: State> = (T) -> Void
