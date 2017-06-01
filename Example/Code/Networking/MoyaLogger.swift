import Foundation
import Moya
import Result

/// Logs network activity (outgoing requests and incoming responses).
public class MoyaLoggerPlugin: PluginType {
    
    fileprivate let dateFormatString = "HH:mm:ss"
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = self.dateFormatString
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// If true, also logs response body data.
    public let verbose: Bool
    
    public typealias CustomLogClosure = ((_ timeStamp: Date, _ message: String, _ formattedMessage: String) -> ())
    
    /// This closure can be used to customize logging. If not `nil`, this closure will be called each time
    /// the logger wants to log a string. The time stamp will be the time the log event occured.
    /// If `nil` the logger will just print out the formatted message.
    public var customLogClosure: CustomLogClosure?
    
    
    public init(verbose: Bool = false) {
        self.verbose = verbose
    }
    
    public func willSend(_ request: RequestType, target: TargetType) {
        logNetworkRequest(request: request.request, target: target)
    }
    
    public func didReceive(_ result: Result<Response, Moya.MoyaError>, target: TargetType) {
        logNetworkResponse(response: result, target: target)
    }
    
    
}

private extension MoyaLoggerPlugin {
    
    func logNetworkRequest(request: URLRequest?, target: TargetType) {
        guard let request = request else {
            logOut(message: "No Request")
            return
        }
        
        var output = [String]()
        
        // [10:13:54] ↗️ GET http://example.com/foo
        output.append(String(format: "(%i) ↗️ %@ %@", target.hashValue, request.httpMethod ?? "", request.url?.absoluteString ?? ""))
        
        let spacing = "              "
        if let headers = request.allHTTPHeaderFields?.map({ "\(spacing)   \($0.0): \($0.1)" }).joined(separator: "\n"), verbose == true {
            output.append(String(format: "%@Headers: \n%@", spacing, headers))
        }
        
        if let body = prettyJSON(data: request.httpBody), verbose == true {
            output.append(String(format: "%@Request Body: \n%@", spacing, body))
        }
        
        logOut(message: output.joined(separator: "\n"))
    }
    
    func logNetworkResponse(response: Result<Response, Moya.MoyaError>, target: TargetType) {
        switch response {
        case let .success(value):
            guard let response = value.response as? HTTPURLResponse else {
                logOut(message: "🔸 Received empty network response for <\(target)>.")
                return
            }
            
            var output = [String]()
            
            let range = 200...399
            let success = range.contains(response.statusCode) ? "✅" : "❌"
            output.append(String(format: "(%i) %@ %i %@", target.hashValue, success, response.statusCode, response.url?.absoluteString ?? ""))
            
            if let body = prettyJSON(data: value.data) ?? String(data: value.data, encoding: String.Encoding.utf8), verbose == true {
                output.append(body)
            }
            
            logOut(message: output.joined(separator: "\n"))
            
        case let .failure(error):
            switch error {
            case let .underlying(e):
                let e = e as NSError
                if e.code == -999 {
                    logOut(message: "🔸 Request Cancelled \(e.userInfo["NSErrorFailingURLStringKey"]!)")
                    return
                }
                fallthrough
            default:
                logOut(message: "❌ \(error)")
            }
            
        }
    }
    
    private func prettyJSON(data: Data?) -> String? {
        if let data = data,
            let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let prettyJson = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
            let string = NSString(data: prettyJson, encoding: String.Encoding.utf8.rawValue) {
            return string as String
        }
        return nil
    }
    
    private func logOut(message: String) {
        let now = Date()
        let formattedMessage = "[\(dateFormatter.string(from: now))] \(message)"
        
        if let customLogClosure = customLogClosure {
            customLogClosure(now, message, formattedMessage)
        } else {
            print(formattedMessage)
        }
    }

}

extension TargetType {
    
    var hashValue: Int {
        var hash = method.hashValue + path.hashValue
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters ?? [:], options: .prettyPrinted) {
            if let string = String(data: jsonData, encoding: String.Encoding.utf8) {
                let parameterHash = "\(string.hashValue)"
                let subString = parameterHash.substring(to: parameterHash.index(parameterHash.startIndex, offsetBy: 8))
                hash += Int(subString)!
            }
        }
        return hash
    }
    
}
