// Flyweight - iOS client for GNU social
// Copyright 2017 Thomas Karpiniec
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

fileprivate class EventIdGenerator {
    static let lock = NSLock()
    static var currentId: Int64 = 1
    
    static func getNextId() -> Int64 {
        lock.lock()
        let ret = currentId
        currentId += 1
        lock.unlock()
        return ret
    }
}

class EventListenerToken<T> {
    let id: Int64 = EventIdGenerator.getNextId()
    let source: EventSource<T>
    
    init(source: EventSource<T>) {
        self.source = source
    }
    
    func unsubscribe() {
        source.unsubscribe(id: id)
    }
    
    deinit {
        unsubscribe()
    }
}

class EventSource<T> {
    let lock = NSLock()
    var noParamHandlers: [Int64: () -> Void] = [:]
    var paramHandlers: [Int64: (T) -> Void] = [:]
    
    func subscribe(handler: @escaping () -> Void) -> EventListenerToken<T> {
        let token = EventListenerToken(source: self)
        
        lock.lock()
        noParamHandlers[token.id] = handler
        lock.unlock()
        
        return token
    }
    
    func subscribeValue(handler: @escaping (T) -> Void) -> EventListenerToken<T> {
        let token = EventListenerToken(source: self)
        
        lock.lock()
        paramHandlers[token.id] = handler
        lock.unlock()
        
        return token
    }
    
    func dispatch() {
        lock.lock()
        let handlers = Array(noParamHandlers.values)
        lock.unlock()
        
        for h in handlers {
            h()
        }
    }
    
    func dispatchValue(value: T) {
        lock.lock()
        let handlers1 = Array(noParamHandlers.values)
        let handlers2 = Array(paramHandlers.values)
        lock.unlock()
        
        for h in handlers1 {
            h()
        }
        for h in handlers2 {
            h(value)
        }
    }
    
    func unsubscribe(id: Int64) {
        lock.lock()
        noParamHandlers.removeValue(forKey: id)
        paramHandlers.removeValue(forKey: id)
        lock.unlock()
    }
}


