import Foundation

var anyNSError: NSError {
    NSError(domain: "any error", code: 1)
}

func anyURL() -> URL {
    URL(string: "https://www.google.com")!
}
