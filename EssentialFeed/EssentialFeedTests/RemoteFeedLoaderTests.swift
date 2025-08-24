import XCTest

class RemoteFeedLoader {

}

class HTTPClient{
    var requestedUrl: URL?
}

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        _ = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedUrl)
    }
}
