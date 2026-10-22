import Foundation
import Combine

public enum WebSocketStreamingState: Equatable {
    case disconnected
    case connecting
    case connected
    case streaming
    case error(String)
}

public final class WebSocketStreamingClient: NSObject, ObservableObject {
    @Published public var state: WebSocketStreamingState = .disconnected
    @Published public var latencyMs: Int = 0

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var pingTimer: Timer?
    private var lastPingTimestamp: Date?

    // Keep memory footprint lean (~30 MB limit protection)
    private let maxBufferSize: Int = 100
    private var messageBuffer: [String] = []

    public var onTokenReceived: ((String) -> Void)?
    public var onAudioChunkReceived: ((Data) -> Void)?

    public override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: .main)
    }

    public func connect(to urlString: String) {
        guard let url = URL(string: urlString) else {
            state = .error("Invalid WebSocket URL")
            return
        }

        disconnect()
        state = .connecting

        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        state = .connected

        startHeartbeat()
        listenForMessages()
    }

    public func disconnect() {
        stopHeartbeat()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        state = .disconnected
        messageBuffer.removeAll()
    }

    public func sendAudioChunk(_ audioData: Data) {
        guard state == .connected || state == .streaming else { return }
        state = .streaming

        let message = URLSessionWebSocketTask.Message.data(audioData)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                Task { @MainActor in
                    self?.state = .error(error.localizedDescription)
                }
            }
        }
    }

    public func sendTextToken(_ text: String) {
        guard state == .connected || state == .streaming else { return }
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                Task { @MainActor in
                    self?.state = .error(error.localizedDescription)
                }
            }
        }
    }

    private func listenForMessages() {
        guard let task = webSocketTask else { return }

        task.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleIncomingToken(text)
                case .data(let data):
                    self.handleIncomingAudio(data)
                @unknown default:
                    break
                }
                // Recursively listen for subsequent frames
                self.listenForMessages()

            case .failure(let error):
                Task { @MainActor in
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    private func handleIncomingToken(_ token: String) {
        Task { @MainActor in
            // Memory buffer safety cap
            if self.messageBuffer.count > self.maxBufferSize {
                self.messageBuffer.removeFirst(20)
            }
            self.messageBuffer.append(token)
            self.onTokenReceived?(token)
        }
    }

    private func handleIncomingAudio(_ audio: Data) {
        Task { @MainActor in
            self.onAudioChunkReceived?(audio)
        }
    }

    // MARK: - Sub-Second Heartbeat & Latency Calculation
    private func startHeartbeat() {
        stopHeartbeat()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func stopHeartbeat() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func sendPing() {
        lastPingTimestamp = Date()
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                Task { @MainActor in
                    self?.state = .error("Ping failed: \(error.localizedDescription)")
                }
            } else if let sentTime = self?.lastPingTimestamp {
                let roundTripMs = Int(Date().timeIntervalSince(sentTime) * 1000)
                Task { @MainActor in
                    self?.latencyMs = roundTripMs
                }
            }
        }
    }

    deinit {
        disconnect()
    }
}
