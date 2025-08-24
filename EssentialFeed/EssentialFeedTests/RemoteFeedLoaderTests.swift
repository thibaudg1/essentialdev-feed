import XCTest

class RemoteFeedLoader {
    func load() {
        HTTPClient.shared.requestedUrl = URL(string: "https://a-url.com")
    }
} 

class HTTPClient {
    static let shared = HTTPClient()
    
    private init() {}
    
    var requestedUrl: URL?
}

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient.shared
        _ = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedUrl)
    }
    
    func test_load_requestDataFromURL() {
        let client = HTTPClient.shared
        let sut = RemoteFeedLoader()
        
        sut.load()
        
        XCTAssertNotNil(client.requestedUrl)
    }
}
