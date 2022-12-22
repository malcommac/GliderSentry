//
//  GliderSentry
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created by Daniele Margutti
//  Email: <hello@danielemargutti.com>
//  Web: <http://www.danielemargutti.com>
//
//  Copyright ©2022 Daniele Margutti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation
import Glider
import Sentry

open class SentryTransport: Transport {

    // MARK: - Public Properties
    
    /// Is the transport enabled.
    public var isEnabled: Bool = true
    
    /// Minimum accepted level
    public var minimumAcceptedLevel: Glider.Level? = nil
    
    /// GCD queue.
    public var queue: DispatchQueue
    
    /// Configuration.
    public let configuration: Configuration
    
    // MARK: - Initialization
    
    /// Initialize a new Sentry transport service.
    /// - Parameter builder: builder pattern.
    public init(_ builder: ((inout Configuration) -> Void)? = nil) {
        self.configuration = Configuration(builder)
        self.queue = configuration.queue

        if let sdkConfiguration = configuration.sdkConfiguration {
            SentrySDK.start(options: sdkConfiguration)
        }
    }
    
    // MARK: - Conformance
    
    public func record(event: Glider.Event) -> Bool {
        let message = configuration.formatters.format(event: event)
        let sentryEvent = event.toSentryEvent(withMessage: message)
        
        sentryEvent.environment = configuration.environment
        sentryEvent.logger = configuration.loggerName
        sentryEvent.user = event.scope.user?.toSentryUser()
        
        SentrySDK.capture(event: sentryEvent) {
            $0.setExtras(event.scope.extra.values.compactMapValues({ $0 }))
            $0.setTags(event.scope.tags)
        }

        return true
    }
    
}

// MARK: - Configuration

extension SentryTransport {
    
    public struct Configuration {
        
        /// This is the SDK configuration object. You should set a non `nil` value here if you want
        /// Glider's `SentryTransport` needs to initialize the SDK for you.
        /// If you have the SDK already initialized at this time leave this `nil`.
        /// `SentryTransport` will always use the static methods of `SentrySDK` to dispatch events.
        public var sdkConfiguration: Sentry.Options?
        
        
        /// Formatter used to transform a payload into a string.
        public var formatters = [EventMessageFormatter]()
        
        /// Matches on the name of the logger, which is useful to combine all messages of a logger together.
        ///  This match is case sensitive.
        public var loggerName: String?
        
        /// Generally, the tag accepts any value, but it's intended to refer to your code deployments'
        /// naming convention, such as development, testing, staging, or production.
        /// More on <https://docs.sentry.io/product/sentry-basics/environments/>.
        public var environment: String?
        
        // The `DispatchQueue` to use for the recorder.
        public var queue: DispatchQueue
        
        public init(_ builder: ((inout Configuration) -> Void)?) {
            self.queue = DispatchQueue(label: String(describing: type(of: self)), attributes: [])
            builder?(&self)
        }
        
    }
    
}
