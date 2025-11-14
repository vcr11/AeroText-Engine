//
//  GazeSmoother.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  Advanced gaze smoothing system with prediction and filtering for spatial interaction
//

import Foundation
import Combine
import simd

class GazeSmoother: ObservableObject {
    @Published var smoothedPosition: SIMD3<Float> = .zero
    @Published var velocity: SIMD3<Float> = .zero
    @Published var isStable: Bool = false

    // Smoothing parameters
    private let smoothingFactor: Float = 0.15
    private let predictionFactor: Float = 0.3
    private let stabilityThreshold: Float = 0.01

    // Historical data for smoothing
    private var positionHistory: [SIMD3<Float>] = []
    private var timestampHistory: [Date] = []
    private let maxHistorySize = 10

    // Kalman filter state (simplified)
    private var estimatedPosition: SIMD3<Float> = .zero
    private var estimatedVelocity: SIMD3<Float> = .zero
    private var positionUncertainty: Float = 1.0
    private var velocityUncertainty: Float = 1.0

    // Noise filtering
    private let processNoise: Float = 0.1
    private let measurementNoise: Float = 0.5

    init() {
        // Initialize with default position
        smoothedPosition = SIMD3<Float>(0, 0, -0.5)
        estimatedPosition = smoothedPosition
    }

    // MARK: - Position Updates

    func updateGazePosition(_ newPosition: SIMD3<Float>) {
        let currentTime = Date()

        // Add to history
        positionHistory.append(newPosition)
        timestampHistory.append(currentTime)

        // Maintain history size
        if positionHistory.count > maxHistorySize {
            positionHistory.removeFirst()
            timestampHistory.removeFirst()
        }

        // Apply smoothing and prediction
        smoothedPosition = calculateSmoothedPosition(newPosition)

        // Update velocity estimation
        updateVelocity()

        // Check stability
        updateStability()
    }

    private func calculateSmoothedPosition(_ newPosition: SIMD3<Float>) -> SIMD3<Float> {
        // Apply Kalman filter for position estimation
        let predictedPosition = estimatedPosition + estimatedVelocity * predictionFactor

        // Update uncertainties
        positionUncertainty += processNoise
        velocityUncertainty += processNoise

        // Calculate Kalman gain
        let kalmanGain = positionUncertainty / (positionUncertainty + measurementNoise)

        // Update estimate
        let innovation = newPosition - predictedPosition
        estimatedPosition = predictedPosition + kalmanGain * innovation
        positionUncertainty *= (1 - kalmanGain)

        // Apply additional exponential smoothing for stability
        let alpha = smoothingFactor
        smoothedPosition = smoothedPosition * (1 - alpha) + estimatedPosition * alpha

        return smoothedPosition
    }

    private func updateVelocity() {
        guard positionHistory.count >= 2, timestampHistory.count >= 2 else { return }

        let recentPositions = Array(positionHistory.suffix(3))
        let recentTimestamps = Array(timestampHistory.suffix(3))

        // Calculate velocity from recent samples
        var totalVelocity = SIMD3<Float>.zero
        var sampleCount = 0

        for i in 1..<recentPositions.count {
            let dt = Float(recentTimestamps[i].timeIntervalSince(recentTimestamps[i-1]))
            if dt > 0 {
                let dv = (recentPositions[i] - recentPositions[i-1]) / dt
                totalVelocity += dv
                sampleCount += 1
            }
        }

        if sampleCount > 0 {
            estimatedVelocity = totalVelocity / Float(sampleCount)
            velocityUncertainty = abs(estimatedVelocity).max() * 0.1 // Estimate uncertainty
        }

        velocity = estimatedVelocity
    }

    private func updateStability() {
        guard positionHistory.count >= 3 else {
            isStable = false
            return
        }

        // Calculate variance in recent positions
        let recentPositions = Array(positionHistory.suffix(5))
        let meanPosition = recentPositions.reduce(SIMD3<Float>.zero, +) / Float(recentPositions.count)

        var variance: Float = 0
        for position in recentPositions {
            let diff = position - meanPosition
            variance += length_squared(diff)
        }
        variance /= Float(recentPositions.count)

        // Consider stable if variance is below threshold
        isStable = variance < stabilityThreshold
    }

    // MARK: - Prediction and Filtering

    func predictPosition(at timeOffset: TimeInterval) -> SIMD3<Float> {
        return estimatedPosition + estimatedVelocity * Float(timeOffset)
    }

    func getSmoothedVelocity() -> SIMD3<Float> {
        return estimatedVelocity
    }

    func reset() {
        positionHistory.removeAll()
        timestampHistory.removeAll()
        estimatedPosition = .zero
        estimatedVelocity = .zero
        smoothedPosition = .zero
        velocity = .zero
        isStable = false
    }

    // MARK: - Advanced Filtering

    func applyJitterReduction(to position: SIMD3<Float>) -> SIMD3<Float> {
        // Simple median filter for jitter reduction
        guard positionHistory.count >= 3 else { return position }

        let recent = Array(positionHistory.suffix(3))
        let sortedX = recent.map { $0.x }.sorted()
        let sortedY = recent.map { $0.y }.sorted()
        let sortedZ = recent.map { $0.z }.sorted()

        return SIMD3<Float>(
            sortedX[1], // median
            sortedY[1],
            sortedZ[1]
        )
    }

    func applyOutlierRejection(to position: SIMD3<Float>) -> SIMD3<Float> {
        guard positionHistory.count >= 5 else { return position }

        let recent = Array(positionHistory.suffix(5))
        let mean = recent.reduce(SIMD3<Float>.zero, +) / Float(recent.count)

        // Calculate standard deviation
        var variance = SIMD3<Float>.zero
        for pos in recent {
            let diff = pos - mean
            variance += diff * diff
        }
        variance /= Float(recent.count)
        let stdDev = sqrt(variance)

        // Reject outliers (more than 2 standard deviations from mean)
        let threshold = stdDev * 2
        let diff = abs(position - mean)

        if any(diff .> threshold) {
            // Return mean instead of outlier
            return mean
        }

        return position
    }

    // MARK: - Calibration and Adaptation

    func calibrate(with samples: [SIMD3<Float>]) {
        guard !samples.isEmpty else { return }

        // Use calibration samples to adjust filtering parameters
        let mean = samples.reduce(SIMD3<Float>.zero, +) / Float(samples.count)

        var totalVariance: Float = 0
        for sample in samples {
            let diff = sample - mean
            totalVariance += length_squared(diff)
        }
        totalVariance /= Float(samples.count)

        // Adjust measurement noise based on calibration
        measurementNoise = max(0.1, totalVariance * 0.1)

        print("Gaze smoother calibrated. Measurement noise: \(measurementNoise)")
    }

    func adaptToMovementSpeed() {
        let speed = length(estimatedVelocity)

        // Adjust smoothing based on movement speed
        if speed > 1.0 {
            // Fast movement - reduce smoothing for responsiveness
            // smoothingFactor = 0.3
        } else if speed < 0.1 {
            // Slow movement - increase smoothing for stability
            // smoothingFactor = 0.05
        } else {
            // Normal movement - use default smoothing
            // smoothingFactor = 0.15
        }
    }

    // MARK: - Debug and Analysis

    func getDebugInfo() -> GazeDebugInfo {
        return GazeDebugInfo(
            currentPosition: smoothedPosition,
            estimatedPosition: estimatedPosition,
            velocity: velocity,
            isStable: isStable,
            historySize: positionHistory.count,
            positionUncertainty: positionUncertainty,
            velocityUncertainty: velocityUncertainty
        )
    }
}

struct GazeDebugInfo {
    let currentPosition: SIMD3<Float>
    let estimatedPosition: SIMD3<Float>
    let velocity: SIMD3<Float>
    let isStable: Bool
    let historySize: Int
    let positionUncertainty: Float
    let velocityUncertainty: Float
}

// MARK: - SIMD Extensions

extension SIMD3 where Scalar == Float {
    static func > (lhs: SIMD3<Float>, rhs: SIMD3<Float>) -> SIMD3<Bool> {
        return SIMD3<Bool>(lhs.x > rhs.x, lhs.y > rhs.y, lhs.z > rhs.z)
    }

    static func < (lhs: SIMD3<Float>, rhs: SIMD3<Float>) -> SIMD3<Bool> {
        return SIMD3<Bool>(lhs.x < rhs.x, lhs.y < rhs.y, lhs.z < rhs.z)
    }
}

func any(_ vector: SIMD3<Bool>) -> Bool {
    return vector.x || vector.y || vector.z
}
