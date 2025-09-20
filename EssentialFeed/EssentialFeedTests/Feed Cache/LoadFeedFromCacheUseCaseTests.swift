import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages.count, 0)
    }
    
    func test_load_requestCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError
        let expectation = self.expectation(description: "wait for load to complete")
        
        var receivedError: Swift.Error?
        sut.load { result in
            switch result {
            case let .failure(error):
                receivedError = error
            default :
                XCTFail("Expected failure, got \(result) instead")
            }
            
            expectation.fulfill()
        }
        
        store.completeRetrieval(with: retrievalError)
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(receivedError as NSError?, retrievalError)
    }
    
    func test_load_deliversNoImagesOnEmptyCacahe() {
        let (sut, store) = makeSUT()
        let expectation = self.expectation(description: "wait for load to complete")
        
        var receivedImages: [FeedImage]?
        sut.load { result in
            switch result {
            case let .success(images):
                receivedImages = images
            default :
                XCTFail("Expected success, got \(result) instead")
            }
            expectation.fulfill()
        }
        
        store.completeRetrievalWithEmptyCache()
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(receivedImages, [])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private var anyNSError: NSError {
        NSError(domain: "any error", code: 1)
    }
}
