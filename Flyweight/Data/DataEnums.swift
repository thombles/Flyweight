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

@objc public enum GSTimelineType: Int32 {
    case Home = 1
    case User = 2
    case Public = 3
    case KnownNetwork = 4
    case Mentions = 5 // basic mentions_timeline implementation, notices only
    case Favourites = 6
    case Search = 7
    case Tag = 8
    case Group = 9
    case Notifications = 10 // a fuller featured stream from Qvitter
    case Conversation = 11
}
