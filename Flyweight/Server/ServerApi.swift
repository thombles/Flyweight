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
import Alamofire
import AlamofireObjectMapper
import PromiseKit

class ApiError: Error {
    var path: String
    var description: String?
    
    init(path: String, error: Error?) {
        self.path = path
        if let error = error {
            self.description = error.localizedDescription
        }
    }
}

// Use this to build up the parameters and give them to a ServerApi call
class ApiRequestParameters {
    private var params: [(String, String)] = []
    
    func setParam(name: String, stringValue: String) {
        removeParam(name: name)
        params.append((name, stringValue))
    }
    
    func setParam(name: String, intValue: Int) {
        removeParam(name: name)
        params.append((name, "\(intValue)"))
    }
    
    func setParam(name: String, int64Value: Int64) {
        removeParam(name: name)
        params.append((name, "\(int64Value)"))
    }
    
    func removeParam(name: String) {
        params = params.filter { $0.0 != name }
    }
    
    var queryString: String {
        return "?" +
            params.map() { return "\($0.0)=\($0.1)" }
            .joined(separator: "&")
    }
}

class ListRequestParameters: ApiRequestParameters {
    func set(page: Int) {
        self.setParam(name: "page", intValue: page)
    }
    func set(count: Int) {
        self.setParam(name: "count", intValue: count)
    }
    func set(maxId: Int64) {
        self.setParam(name: "max_id", int64Value: maxId)
    }
    func set(sinceId: Int64) {
        self.setParam(name: "since_id", int64Value: sinceId)
    }
}

class ServerApi {
    let baseUrl: String
    
    /**
        Initialise a utility for making calls to a particular GNU social server.
     
        - parameter baseUrl: The full URL of the server's api up to "api" with no trailing slash.
    */
    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }
    
    /**
        Retrieve the public timeline. That is, all notices by everybody on this instance.
     
        Normal list parameters apply here.
    */
    func getPublicTimeline(params: ListRequestParameters) -> Promise<[NoticeDTO]> {
        let path = "statuses/public_timeline.json\(params.queryString)"
        return Promise { fulfil, reject in
            Alamofire.request(makeApiUrl(path)).responseArray { (response: DataResponse<[NoticeDTO]>) in
                if let array = response.result.value {
                    fulfil(array)
                    return
                }
                reject(ApiError(path: path, error: response.result.error))
            }
        }
    }
    
    func getPublicFeed(params: ListRequestParameters) -> Promise<Data> {
        let path = "statuses/public_timeline.atom\(params.queryString)"
        // Set up a custom manager with ephemeral config so we don't keep the session cookie
        // Otherwise once we get the password right it's "stuck"
        // TODO this doesn't seem to clear instantly after success. However if you get a valid login we're done, so it'll do for the moment...
        let configuration = URLSessionConfiguration()
        configuration.httpShouldSetCookies = false
        let sessionManager = Alamofire.SessionManager(configuration: configuration)
        return Promise { fulfil, reject in
            sessionManager.request(makeApiUrl(path)).responseData { (response: DataResponse<Data>) in
                if let data = response.data {
                    fulfil(data)
                    return
                }
                reject(ApiError(path: path, error: response.result.error))
            }
        }
    }
    
    func verifyCredentials(username: String, password: String) -> Promise<Bool> {
        let path = "account/verify_credentials.json"
        return Promise { fulfil, reject in
            Alamofire.request(makeApiUrl(path))
                .authenticate(user: username, password: password)
                .responseData { (response: DataResponse<Data>) in
                if let code = response.response?.statusCode {
                    switch code {
                    case 200: // expected response if valid credentials
                        fulfil(true)
                        return
                    case 401:
                        fulfil(false) // expected response if invalid credentials
                        return
                    default:
                        break
                    }
                }
                reject(ApiError(path: path, error: response.result.error))
            }
        }
    }
 
    fileprivate func makeApiUrl(_ path: String) -> String {
        return baseUrl + "api/" + path
    }
 
}
