import XCTest
import EssentialFeed


    
class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super .tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let expectation = expectation(description: "wait for request")
        
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        }
        
        makeSUT().get(from: url, completion: { _ in })
        
        wait(for: [expectation], timeout: 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError
        
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
        
        assertNSErrorsAreEqual(error1: receivedError! as NSError, error2: requestError)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: nil))
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData
        let response = anyHTTPURLResponse
        
        let receivedValues = resultValuesFor(data: data, response: response, error: nil)
        
        XCTAssertEqual(response.url, receivedValues?.response.url)
        XCTAssertEqual(response.statusCode, receivedValues?.response.statusCode )
        XCTAssertEqual(data, receivedValues?.data)
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse
        
        let receivedValues = resultValuesFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(response.url, receivedValues?.response.url)
        XCTAssertEqual(response.statusCode, receivedValues?.response.statusCode )
        XCTAssertEqual(emptyData, receivedValues?.data)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient  {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private var anyData: Data {
        Data("some data".utf8)
    }
    
    private var nonHTTPURLResponse: URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private var anyHTTPURLResponse: HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let result = resultFor(data: data, response: response, error: error)
        
        switch result {
        case .failure(let error):
            return error
        default:
            XCTFail("Expected failure, got result: \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error)
         
        switch result {
        case .success(let data, let response):
            return (data, response)
        default:
            XCTFail("Expected success, got result: \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let expectation = expectation(description: "wait for request")
        
        var receivedResult: HTTPClientResult!

        sut.get(from: anyURL()) { result in
            receivedResult = result
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
        return receivedResult
    }
    
    private func assertNSErrorsAreEqual(
        error1: NSError,
        error2: NSError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(error1.domain, error2.domain)
        XCTAssertEqual(error1.code, error2.code)
    }
    
    private class URLProtocolStub: URLProtocol  {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func observeRequest(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
         
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let requestObserver = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}

