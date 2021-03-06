////
////  ReducerTests.swift
////  
////
////  Created by Thibault Wittemberg on 2019-12-31.
////

import RxBlocking
import RxSwift
import SpinRxSwift
import XCTest

final class ReducerTests: XCTestCase {

    func test_reducer_is_performed_on_default_executer_when_no_executer_is_specified() {
        // Given: an event stream switching on a specified Executer after being executed
        // and a Reducer applied after this event stream
        var reduceIsCalled = false
        let expectedExecuterName = "INPUT_STREAM_QUEUE_\(UUID().uuidString)"
        var receivedExecuterName = ""

        let inputStreamScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: expectedExecuterName,
                                                                                         qos: .userInitiated))

        let eventStream = Observable<String>.just("").observeOn(inputStreamScheduler)

        let reducerFunction = { (state: String, action: String) -> String in
            reduceIsCalled = true
            receivedExecuterName = DispatchQueue.currentLabel
            return ""
        }

        // When: reducing without specifying an Executer for the reduce operation
        let sut = Reducer(reducerFunction)
        let scheduledReducer = sut.scheduledReducer(with: "initialState")

        _ = scheduledReducer(eventStream)
            .take(2)
            .toBlocking()
            .materialize()

        // Then: the reduce is performed
        // Then: the reduce is performed on the default executer, ie the CurrentThreadScheduler for RxReducer
        XCTAssertTrue(reduceIsCalled)
        XCTAssertEqual(receivedExecuterName, expectedExecuterName)
    }

    func test_reducer_is_performed_on_dedicated_executer_when_executer_is_specified() {
        // Given: an effect switching on a specified Executer after being executed
        var reduceIsCalled = false
        let expectedExecuterName = "REDUCER_QUEUE_\(UUID().uuidString)"
        var receivedExecuterName = ""

        let inputStreamSchedulerQueueLabel = "INPUT_STREAM_QUEUE_\(UUID().uuidString)"
        let inputStreamScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: inputStreamSchedulerQueueLabel,
                                                                                         qos: .userInitiated))
        let reducerScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: expectedExecuterName, qos: .userInitiated))

        let eventStream = Observable<String>.just("").observeOn(inputStreamScheduler)

        let reducerFunction = { (state: String, action: String) -> String in
            reduceIsCalled = true
            receivedExecuterName = DispatchQueue.currentLabel
            return ""
        }

        // When: reducing without specifying an Executer for the reduce operation
        let sut = Reducer(reducerFunction, on: reducerScheduler)
        let scheduledReducer = sut.scheduledReducer(with: "initialState")

        _ = scheduledReducer(eventStream)
            .take(2)
            .toBlocking()
            .materialize()

        // Then: the reduce is performed
        // Then: the reduce is performed on the current executer, ie the one set by the feedback
        XCTAssertTrue(reduceIsCalled)
        XCTAssertEqual(receivedExecuterName, expectedExecuterName)
    }
}
