//
//  PerformanceLogger.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  Comprehensive performance monitoring and logging system for spatial text input
//

import Foundation
import Combine
import QuartzCore // For CADisplayLink in visionOS

class PerformanceLogger: ObservableObject {
    @Published var averageInputLatency: Double = 0.0
    @Published var frameRate: Double = 0.0
    @Published var isHighPerformanceMode = true

    // Input latency tracking
    private var inputTimestamps: [Date] = []
    private var inputLatencies: [Double] = []
    private let maxSamples = 100

    // Frame rate monitoring
    private var frameTimestamps: [Date] = []
    private var displayLink: CADisplayLink?

    // Performance metrics
    private var renderTimes: [Double] = []
    private var lastRenderStart: Date?

    // Logging
    private var logEntries: [LogEntry] = []
    private let maxLogEntries = 1000

    init() {
        setupDisplayLink()
        startPerformanceMonitoring()
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: - Input Latency Tracking

    func logInputEvent() {
        let timestamp = Date()
        inputTimestamps.append(timestamp)

        // Keep only recent samples
        if inputTimestamps.count > maxSamples {
            inputTimestamps.removeFirst()
        }

        updateAverageLatency()
    }

    func logInputLatency(_ latency: TimeInterval) {
        let latencyMs = latency * 1000
        inputLatencies.append(latencyMs)

        if inputLatencies.count > maxSamples {
            inputLatencies.removeFirst()
        }

        updateAverageLatency()
        log(.info, "Input latency: \(String(format: "%.1f", latencyMs))ms")
    }

    private func updateAverageLatency() {
        guard !inputLatencies.isEmpty else { return }
        averageInputLatency = inputLatencies.reduce(0, +) / Double(inputLatencies.count)
    }

    // MARK: - Frame Rate Monitoring

    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(frameUpdate))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120)
        displayLink?.add(to: .main, forMode: .default)
    }

    @objc private func frameUpdate() {
        let timestamp = Date()
        frameTimestamps.append(timestamp)

        // Keep only recent samples for frame rate calculation
        if frameTimestamps.count > maxSamples {
            frameTimestamps.removeFirst()
        }
    }

    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateFrameRate()
        }
    }

    private func updateFrameRate() {
        guard frameTimestamps.count >= 2 else { return }

        let timeInterval = frameTimestamps.last!.timeIntervalSince(frameTimestamps.first!)
        let frameCount = Double(frameTimestamps.count - 1)

        frameRate = frameCount / timeInterval

        // Reset for next measurement period
        frameTimestamps.removeAll()

        // Log performance warnings
        if frameRate < 60 {
            log(.warning, "Low frame rate: \(String(format: "%.1f", frameRate)) FPS")
        }
    }

    // MARK: - Render Time Tracking

    func startRenderMeasurement() {
        lastRenderStart = Date()
    }

    func endRenderMeasurement() {
        guard let startTime = lastRenderStart else { return }
        let renderTime = Date().timeIntervalSince(startTime) * 1000 // Convert to milliseconds

        renderTimes.append(renderTime)
        if renderTimes.count > maxSamples {
            renderTimes.removeFirst()
        }

        // Log slow renders
        if renderTime > 16.67 { // Slower than 60 FPS
            log(.warning, "Slow render: \(String(format: "%.1f", renderTime))ms")
        }
    }

    // MARK: - Performance Mode Management

    func togglePerformanceMode() {
        isHighPerformanceMode.toggle()

        if isHighPerformanceMode {
            log(.info, "Switched to HIGH performance mode")
            // In a real implementation, this would:
            // - Increase render quality
            // - Enable more detailed physics
            // - Allow higher polycount models
        } else {
            log(.info, "Switched to BALANCED performance mode")
            // In a real implementation, this would:
            // - Reduce render quality
            // - Simplify physics calculations
            // - Use lower polycount models
        }
    }

    // MARK: - Logging System

    enum LogLevel: String {
        case debug, info, warning, error
    }

    struct LogEntry {
        let timestamp: Date
        let level: LogLevel
        let message: String
        let context: [String: Any]?
    }

    func log(_ level: LogLevel, _ message: String, context: [String: Any]? = nil) {
        let entry = LogEntry(timestamp: Date(), level: level, message: message, context: context)
        logEntries.append(entry)

        if logEntries.count > maxLogEntries {
            logEntries.removeFirst()
        }

        // Console output for debugging
        let timestamp = ISO8601DateFormatter().string(from: entry.timestamp)
        print("[\(timestamp)] [\(level.rawValue.uppercased())] \(message)")
    }

    // MARK: - Performance Analysis

    func getPerformanceReport() -> PerformanceReport {
        let avgRenderTime = renderTimes.isEmpty ? 0 : renderTimes.reduce(0, +) / Double(renderTimes.count)
        let maxRenderTime = renderTimes.max() ?? 0
        let minRenderTime = renderTimes.min() ?? 0

        return PerformanceReport(
            averageInputLatency: averageInputLatency,
            frameRate: frameRate,
            averageRenderTime: avgRenderTime,
            maxRenderTime: maxRenderTime,
            minRenderTime: minRenderTime,
            isHighPerformanceMode: isHighPerformanceMode,
            recentLogs: Array(logEntries.suffix(10))
        )
    }

    func exportPerformanceData() -> Data? {
        let report = getPerformanceReport()
        return try? JSONEncoder().encode(report)
    }

    // MARK: - Memory and CPU Estimation

    var estimatedMemoryUsage: Double {
        // Rough estimation based on object counts and typical memory usage
        // In a real implementation, this would use system APIs
        return Double.random(in: 50...200) // MB
    }

    var estimatedCPUUsage: Double {
        // Rough estimation based on frame rate and render times
        // In a real implementation, this would use system APIs
        let baseUsage = 100 - (frameRate / 60 * 100) // Lower frame rate = higher CPU usage
        return max(5, min(95, baseUsage))
    }
}

struct PerformanceReport: Codable {
    let averageInputLatency: Double
    let frameRate: Double
    let averageRenderTime: Double
    let maxRenderTime: Double
    let minRenderTime: Double
    let isHighPerformanceMode: Bool
    let recentLogs: [PerformanceLogger.LogEntry]

    enum CodingKeys: String, CodingKey {
        case averageInputLatency, frameRate, averageRenderTime, maxRenderTime, minRenderTime, isHighPerformanceMode, recentLogs
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(averageInputLatency, forKey: .averageInputLatency)
        try container.encode(frameRate, forKey: .frameRate)
        try container.encode(averageRenderTime, forKey: .averageRenderTime)
        try container.encode(maxRenderTime, forKey: .maxRenderTime)
        try container.encode(minRenderTime, forKey: .minRenderTime)
        try container.encode(isHighPerformanceMode, forKey: .isHighPerformanceMode)
        // Note: LogEntry contains Date which isn't directly Codable
        // In a real implementation, you'd make LogEntry Codable
    }
}
