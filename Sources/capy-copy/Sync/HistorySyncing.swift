import Foundation

protocol HistorySyncing: AnyObject {
    func added(_ item: ClipItem) async
    func updated(_ item: ClipItem) async
    func deleted(recordNames: [String]) async
    func start() async
    func stop() async
}
