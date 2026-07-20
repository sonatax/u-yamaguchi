@preconcurrency import CoreMotion
import Foundation

@MainActor
protocol MotionSensorProviding: AnyObject {
    var isAvailable: Bool { get }

    func start(
        onSample: @escaping @MainActor (MotionSensorSample) -> Void,
        onError: @escaping @MainActor (SensorServiceError) -> Void
    ) throws
    func stop()
}

@MainActor
final class MotionSensorService: MotionSensorProviding {
    private let motionManager: CMMotionManager
    private let operationQueue: OperationQueue

    var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }

    init(motionManager: CMMotionManager = CMMotionManager()) {
        self.motionManager = motionManager
        operationQueue = OperationQueue()
        operationQueue.name = "StackChanDriver.MotionSensor"
        operationQueue.qualityOfService = .userInitiated
        operationQueue.maxConcurrentOperationCount = 1
    }

    func start(
        onSample: @escaping @MainActor (MotionSensorSample) -> Void,
        onError: @escaping @MainActor (SensorServiceError) -> Void
    ) throws {
        guard isAvailable else {
            throw SensorServiceError.motionUnavailable
        }

        motionManager.stopDeviceMotionUpdates()
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: operationQueue) { motion, error in
            if let error {
                let message = error.localizedDescription
                Task { @MainActor in
                    onError(.motionUpdateFailed(message))
                }
                return
            }
            guard let motion else { return }

            let timestamp = Date()
            let x = motion.userAcceleration.x
            let y = motion.userAcceleration.y
            let z = motion.userAcceleration.z
            Task { @MainActor in
                onSample(
                    MotionSensorSample(
                        timestamp: timestamp,
                        accelerationX: x,
                        accelerationY: y,
                        accelerationZ: z
                    )
                )
            }
        }
        print("[Sensors] Motion updates started")
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        print("[Sensors] Motion updates stopped")
    }
}
