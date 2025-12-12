import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1

/// NIO-based HTTP server for receiving intercepted network transactions
final class MyBurpHTTPServer {
    private let group: MultiThreadedEventLoopGroup
    private let port: Int
    private var channel: Channel?
    
    init(port: Int = 8080) {
        self.port = port
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    }
    
    func start() throws {
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(HTTPHandler())
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
        
        do {
            channel = try bootstrap.bind(host: "0.0.0.0", port: port).wait()
            
            guard let localAddress = channel?.localAddress else {
                throw MyBurpServerError.failedToBind
            }
            
            print("🚀 MyBurp Server started on \(localAddress)")
            print("📡 Listening for intercepted traffic...")
            print("🌐 Open http://localhost:\(port) in your browser")
            print("Press Ctrl+C to stop")
            
            try channel?.closeFuture.wait()
        } catch {
            throw error
        }
    }
    
    func stop() throws {
        try channel?.close().wait()
        try group.syncShutdownGracefully()
    }
}

enum MyBurpServerError: Error {
    case failedToBind
}
