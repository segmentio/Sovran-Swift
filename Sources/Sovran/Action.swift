//
//  Action.swift
//  Sovran
//
//  Created by Brandon Sneed on 11/18/20.
//

import Foundation

/**
 Defines conformance for synchronous Actions that will be dispatched through the State system.
 */
public protocol Action {
    /**
     The type of state this action deals with.  Usually inferred by simply specifying it
     in the implementation of `reduce` below.
     
     Note: It is strongly recommended that the state be immutable.
     Use of reference types to mutable objects may lead to unwanted state sharing, subverting
     the intent of the system.
     */
    associatedtype StateType: State
    
    /**
     The reducer for this action.  Reducer implementations should be constructed as pure functions,
     such that the returned state is only determined by its input values, without observable
     side effects.

     - parameters:
         - state: A copy of the current state.
     - returns: A new modified copy of state.
     
     example:
     ```
     struct ToggleAction: Action {
         value: Bool
     
         func reduce(state: SwitchState) -> SwitchState {
             var newState = state
             newState.isOn = value
             return newState
         }
     }
     ```
     */
    func reduce(state: StateType) -> StateType
}

/**
 Defines conformance for asynchronous Actions that will be dispatched through the State system.
 */
public protocol AsyncAction {
    /**
     The type of state this action deals with.  Usually inferred by simply specifying it
     in the implementation of `reduce`.
     */
    associatedtype StateType: State
    /**
     The type used for the result of an operation.  Usually inferred by simply specifying it
     in the implementation of `operation`.
     */
    associatedtype ResultType
    
    /**
     The asynchronous operation for this Action.
     
     The state provided here will almost certainly be different than what the
     reducer sees at a later date.  Also, if the completion closure is not called,
     the action is simply dropped.
     
     - parameters:
         - state: A copy of the current state.
         - completion: The completion closure that must be called by the implementor.
     
     example:
     ```
     struct ToggleAction: AsynAction {
         value: Bool
 
         func operation(state: SwitchState, completion: @escaping (NetworkResult) -> Void) {
             network.async(myRequest) {  results in
                 completion(results)
             }
         }
 
         func reduce(state: SwitchState, operationResult: NetworkResult) -> SwitchState {
             var newState = state
             if networkResult.allowed == true {
                 newState.isOn = value
             }
             return newState
         }
     }
     ```
     */
    func operation(state: StateType, completion: @escaping (ResultType?) -> Void)
    
    /**
     The reducer for this action.  Reducer implementations should be constructed such
     that the returned state is only determined by its input values, without observable
     side effects.
     
     - parameters:
         - state: A copy of the current state.
         - operationResult: The resulting data from `operation`, or nil.
     - returns: A new modified copy of state.
     
     example:
     ```
     struct ToggleAction: AsynAction {
         value: Bool
     
         func operation(state: SwitchState, completion: (NetworkResult) -> Void) {
             network.async(myRequest) {  results in
                 completion(results)
             }
         }
     
         func reduce(state: SwitchState, operationResult: NetworkResult) -> SwitchState {
             var newState = state
             if networkResult.allowed == true {
                 newState.isOn = value
             }
             return newState
         }
     }
     ```
     */
    func reduce(state: StateType, operationResult: ResultType?) -> StateType
}
