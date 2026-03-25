import Foundation
import SwiftData
import COREEngine

@Model
final class WearLogEntity {
    var id: UUID
    var garmentID: UUID
    var date: Date

    init(id: UUID = UUID(), garmentID: UUID, date: Date = Date()) {
        self.id = id
        self.garmentID = garmentID
        self.date = date
    }
}

extension WearLogEntity {
    func toWearLog() -> WearLog {
        WearLog(id: id, garmentID: garmentID, date: date)
    }

    static func from(_ log: WearLog) -> WearLogEntity {
        WearLogEntity(id: log.id, garmentID: log.garmentID, date: log.date)
    }
}
