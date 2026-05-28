import Foundation

struct RecallResult: Identifiable {
    var id: UUID
    var dayKey: String
    var title: String
    var excerpt: String
    var score: Double
}

protocol RecallSearching {
    func search(query: String) async throws -> [RecallResult]
}

struct StubRecallSearchService: RecallSearching {
    func search(query: String) async throws -> [RecallResult] {
        []
    }
}

