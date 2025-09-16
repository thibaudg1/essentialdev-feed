import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [weak self] cacheDeletionError in
            guard let self else { return }
            
            if let cacheDeletionError {
                completion(cacheDeletionError)
            } else {
                self.cache(items, with: completion)
            }
        }
    } 
    
    private func cache(_ items: [FeedItem], with completion: @escaping (Error?) -> Void) {
        store.insert(items, timestamp: currentDate()) { [weak self] insertionError in
            guard self != nil else { return }
            completion(insertionError)
        }
    }
}

public protocol FeedStore {
    typealias DeleteCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion)
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}
