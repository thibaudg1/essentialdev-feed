import XCTest
import EssentialFeed

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: self.currentDate(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

class FeedStore {
    typealias DeleteCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    private var deletionCompletions: [DeleteCompletion] = []
    private var insertionCompletions: [InsertionCompletion] = []
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
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
    
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        receivedMessages.append(.insert(items, timestamp))
        insertionCompletions.append(completion)
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages.count, 0)
    }
    
    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let deletionError = anyNSError
        
        sut.save(items) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        
        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items, timestamp)])
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let deletionError = anyNSError
        let expectation = expectation(description: "wait for save completion")
        
        var receivedError: Error?
        sut.save(items) { error in
            receivedError = error
            expectation.fulfill()
        }
        
        store.completeDeletion(with: deletionError)
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(receivedError as NSError?, deletionError)
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let insertionError = anyNSError
        let expectation = expectation(description: "wait for save completion")
        
        var receivedError: Error?
        sut.save(items) { error in
            receivedError = error
            expectation.fulfill()
        }
        
        store.completeDeletionSuccessfully()
        store.completeInsertion(with: insertionError)
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(receivedError as NSError?, insertionError)
    }
    
    func test_save_succeedsOnSuccesfulCacheInsertion() {
        let (sut, store) = makeSUT()
        let items: [FeedItem] = [uniqueItem(), uniqueItem()]
        let expectation = expectation(description: "wait for save completion")
        
        var receivedError: Error?
        sut.save(items) { error in
            receivedError = error
            expectation.fulfill()
        }
        
        store.completeDeletionSuccessfully()
        store.completeInsertionSuccessfully()
        wait(for: [expectation], timeout: 1)
        
        XCTAssertNil(receivedError)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueItem() -> FeedItem {
        .init(
            id: UUID(),
            description: "description",
            location: "loaction",
            imageURL: anyURL()
        )
    }
    
    private func anyURL() -> URL {
        URL(string: "https://www.google.com")!
    }
    
    private var anyNSError: NSError {
        NSError(domain: "any error", code: 1)
    }
}
