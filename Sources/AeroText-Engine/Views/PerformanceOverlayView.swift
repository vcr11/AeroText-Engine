//
//  PerformanceOverlayView.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  Real-time performance metrics overlay for debugging and optimization
//

import SwiftUI

struct PerformanceOverlayView: View {
    @ObservedObject var logger: PerformanceLogger

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Header with toggle
            HStack(spacing: 8) {
                Text("Performance")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                // Mode toggle
                Button(action: { logger.togglePerformanceMode() }) {
                    Text(logger.isHighPerformanceMode ? "HIGH" : "LOW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            logger.isHighPerformanceMode ?
                                Color.green.opacity(0.8) :
                                Color.orange.opacity(0.8)
                        )
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())

                // Expand/collapse toggle
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }

            if isExpanded {
                // Detailed metrics
                VStack(alignment: .trailing, spacing: 4) {
                    MetricRow(label: "Input Latency", value: String(format: "%.1f ms", logger.averageInputLatency))
                    MetricRow(label: "Frame Rate", value: String(format: "%.1f FPS", logger.frameRate))
                    MetricRow(label: "CPU Usage", value: String(format: "%.1f%%", logger.cpuUsage))
                    MetricRow(label: "Memory", value: String(format: "%.1f MB", logger.memoryUsage))
                    MetricRow(label: "Render Time", value: String(format: "%.1f ms", logger.renderTime))
                }
                .padding(.top, 4)
            } else {
                // Compact view
                HStack(spacing: 12) {
                    Text(String(format: "%.0f FPS", logger.frameRate))
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    Text(String(format: "%.1f ms", logger.averageInputLatency))
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 4)
        .frame(width: isExpanded ? 200 : 150)
    }
}

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Performance Extensions
extension PerformanceLogger {
    var cpuUsage: Double {
        // Simplified CPU usage estimation
        // In a real implementation, this would use system APIs
        return Double.random(in: 10...30)
    }

    var memoryUsage: Double {
        // Simplified memory usage estimation
        return Double.random(in: 50...150)
    }

    var renderTime: Double {
        // Simplified render time estimation
        return Double.random(in: 8...16)
    }
}
