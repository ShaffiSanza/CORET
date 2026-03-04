import Foundation
import SwiftData
import COREEngine

// MARK: - MilestoneEntity
// Immutable once written. Created by EngineCoordinator after each recompute
// when MilestoneTracker.milestones(history:) detects new milestones not yet stored.
// Deduplication: compare Milestone.type + Milestone.snapshotIndex before inserting.

@Model
final class MilestoneEntity {

    var id: UUID
    var createdAt: Date
    var type: String            // MilestoneType.rawValue
    var title: String
    var milestoneDescription: String
    var snapshotIndex: Int      // Index in ClaritySnapshot history

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        type: String,
        title: String,
        milestoneDescription: String,
        snapshotIndex: Int
    ) {
        self.id = id
        self.createdAt = createdAt
        self.type = type
        self.title = title
        self.milestoneDescription = milestoneDescription
        self.snapshotIndex = snapshotIndex
    }
}

// MARK: - Conversion

extension MilestoneEntity {

    func toMilestone() -> Milestone {
        Milestone(
            id: id,
            type: MilestoneType(rawValue: type) ?? .journeyStarted,
            title: title,
            description: milestoneDescription,
            snapshotIndex: snapshotIndex,
            createdAt: createdAt
        )
    }

    static func from(_ milestone: Milestone) -> MilestoneEntity {
        MilestoneEntity(
            id: milestone.id,
            createdAt: milestone.createdAt,
            type: milestone.type.rawValue,
            title: milestone.title,
            milestoneDescription: milestone.description,
            snapshotIndex: milestone.snapshotIndex
        )
    }
}
