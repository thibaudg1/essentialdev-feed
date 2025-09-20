import XCTest
import EssentialFeed

class FeedStoreSpy: FeedStore {
    private var deletionCompletions: [DeleteCompletion] = []
    private var insertionCompletions: [InsertionCompletion] = []
    private var retrievalCompletions: [RetrievalCompletion] = []
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private(set) var receivedMessages: [ReceivedMessage] = []
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeRetrieval(with error: Error, at index: Int = 0) {
        retrievalCompletions[index](.failure(error))
    }
    
    func completeRetrievalWithEmptyCache(at index: Int = 0) {
        retrievalCompletions[index](.empty)
    }
    
    func completeRetrieval(with feed: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
        retrievalCompletions[index](.found(feed, timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        receivedMessages.append(.insert(feed, timestamp))
        insertionCompletions.append(completion)
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        receivedMessages.append(.retrieve)
        retrievalCompletions.append(completion)
    }
}
