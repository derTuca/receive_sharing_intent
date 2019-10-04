import Flutter
import UIKit
import Photos

public class SwiftReceiveSharingIntentPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    static let kMessagesChannel = "receive_sharing_intent/messages";
    static let kEventsChannelMedia = "receive_sharing_intent/events-media";
    static let kEventsChannelUrl = "receive_sharing_intent/events-url";
    static let kEventsChannelLink = "receive_sharing_intent/events-text";
    
    private var initialMedia: [SharedMediaFile]? = nil
    private var latestMedia: [SharedMediaFile]? = nil
    
    private var initialText: String? = nil
    private var latestText: String? = nil
    
    private var initialUrl: SharedUrl? = nil
    private var latestUrl: SharedUrl? = nil
    
    private var eventSinkMedia: FlutterEventSink? = nil;
    private var eventSinkText: FlutterEventSink? = nil;
    private var eventSinkUrl: FlutterEventSink? = nil;
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftReceiveSharingIntentPlugin()
        
        let channel = FlutterMethodChannel(name: kMessagesChannel, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let chargingChannelMedia = FlutterEventChannel(name: kEventsChannelMedia, binaryMessenger: registrar.messenger())
        chargingChannelMedia.setStreamHandler(instance)
        
        let chargingChannelLink = FlutterEventChannel(name: kEventsChannelLink, binaryMessenger: registrar.messenger())
        chargingChannelLink.setStreamHandler(instance)
        
        let chargingChannelUrl = FlutterEventChannel(name: kEventsChannelUrl, binaryMessenger: registrar.messenger())
        chargingChannelUrl.setStreamHandler(instance)
        
        registrar.addApplicationDelegate(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        switch call.method {
        case "getInitialMedia":
            result(toJson(data: self.initialMedia));
        case "getInitialText":
            result(self.initialText);
        case "getInitialUrl":
            result(self.initialUrl?.toJson())
        case "reset":
            self.initialMedia = nil
            self.latestMedia = nil
            self.initialText = nil
            self.latestText = nil
            self.initialUrl = nil
            self.latestUrl = nil
            result(nil);
        default:
            result(FlutterMethodNotImplemented);
        }
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        if let url = launchOptions[UIApplication.LaunchOptionsKey.url] as? URL {
            return handleUrl(url: url, setInitialData: true)
        } else if let activityDictionary = launchOptions[UIApplication.LaunchOptionsKey.userActivityDictionary] as? [AnyHashable: Any] { //Universal link
            for key in activityDictionary.keys {
                if let userActivity = activityDictionary[key] as? NSUserActivity {
                    if let url = userActivity.webpageURL {
                        return handleUrl(url: url, setInitialData: true)
                    }
                }
            }
        }
        return false
    }
    
    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return handleUrl(url: url, setInitialData: false)
    }
    
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        return handleUrl(url: userActivity.webpageURL, setInitialData: true)
    }
    
    private func handleUrl(url: URL?, setInitialData: Bool) -> Bool {
        if let url = url {
            let appDomain = Bundle.main.bundleIdentifier!
            let userDefaults = UserDefaults(suiteName: "group.\(appDomain)")
            if url.fragment == "media" {
                if let key = url.host?.components(separatedBy: "=").last,
                    let json = userDefaults?.object(forKey: key) as? Data {
                    let sharedArray = decodeMedia(data: json)
                    let sharedMediaFiles: [SharedMediaFile] = sharedArray.compactMap{
                        guard let path = getAbsolutePath(for: $0.path) else {
                            return nil
                        }
                       
                        if ($0.type == .video && $0.thumbnail != nil) {
                            let thumbnail = getAbsolutePath(for: $0.thumbnail!)
                            return SharedMediaFile.init(path: path, thumbnail: thumbnail, duration: $0.duration, type: $0.type)
                        } else if ($0.type == .video && $0.thumbnail == nil) {
                            return SharedMediaFile.init(path: path, thumbnail: nil, duration: $0.duration, type: $0.type)
                        }
                        
                        return SharedMediaFile.init(path: path, thumbnail: nil, duration: $0.duration, type: $0.type)
                    }
                    latestMedia = sharedMediaFiles
                    if(setInitialData) {
                        initialMedia = latestMedia
                    }
                    eventSinkMedia?(toJson(data: latestMedia))
                }
            } else if url.fragment == "text" {
                if let key = url.host?.components(separatedBy: "=").last,
                    let sharedArray = userDefaults?.object(forKey: key) as? [String] {
                    latestText =  sharedArray.joined(separator: ",")
                    if(setInitialData) {
                        initialText = latestText
                    }
                    eventSinkText?(latestText)
                }
            } else if url.fragment == "url" {
                if let key = url.host?.components(separatedBy: "=").last,
                    let json = userDefaults?.object(forKey: key) as? Data {
                    let sharedUrl = decodeUrl(data: json)
                    latestUrl = sharedUrl
                    if(setInitialData) {
                        initialUrl = latestUrl
                    }
                    eventSinkUrl?(latestUrl?.toJson())
                }
            } else {
                latestText = url.absoluteString
                if(setInitialData) {
                    initialText = latestText
                }
                eventSinkText?(latestText)
            }
            return true
        }
        
        latestMedia = nil
        latestText = nil
        latestUrl = nil
        return false
    }
    
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if (arguments as! String? == "media") {
            eventSinkMedia = events
        } else if (arguments as! String? == "text") {
            eventSinkText = events
        } else if (arguments as! String? == "url") {
            eventSinkUrl = events
        } else {
            return FlutterError.init(code: "NO_SUCH_ARGUMENT", message: "No such argument\(String(describing: arguments))", details: nil);
        }
        return nil;
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if (arguments as! String? == "media") {
            eventSinkMedia = nil;
        } else if (arguments as! String? == "text") {
            eventSinkText = nil;
        } else if (arguments as! String? == "url") {
            eventSinkUrl = nil
        } else {
            return FlutterError.init(code: "NO_SUCH_ARGUMENT", message: "No such argument as \(String(describing: arguments))", details: nil);
        }
        return nil;
    }
    
    private func getAbsolutePath(for identifier: String) -> String? {
        if (identifier.starts(with: "file://") || identifier.starts(with: "/var/mobile/Media") || identifier.starts(with: "/private/var/mobile")) {
            return identifier.replacingOccurrences(of: "file://", with: "")
        }
        let phAsset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: .none).firstObject
        if(phAsset == nil) {
            return nil
        }
        let (url, _) = getFullSizeImageURLAndOrientation(for: phAsset!)
        return url
    }
    
    private func getFullSizeImageURLAndOrientation(for asset: PHAsset)-> (String?, Int) {
           var url: String? = nil
           var orientation: Int = 0
           let semaphore = DispatchSemaphore(value: 0)
           let options2 = PHContentEditingInputRequestOptions()
           options2.isNetworkAccessAllowed = true
           asset.requestContentEditingInput(with: options2){(input, info) in
               orientation = Int(input?.fullSizeImageOrientation ?? 0)
               url = input?.fullSizeImageURL?.path
               semaphore.signal()
           }
           semaphore.wait()
           
           return (url, orientation)
       }
    
    private func decodeMedia(data: Data) -> [SharedMediaFile] {
        let encodedData = try? JSONDecoder().decode([SharedMediaFile].self, from: data)
        return encodedData!
    }
    
    private func decodeUrl(data: Data) -> SharedUrl {
        let encodedData = try? JSONDecoder().decode(SharedUrl.self, from: data)
        return encodedData!
    }
    
    private func toJson(data: [SharedMediaFile]?) -> String? {
        if data == nil {
            return nil
        }
        let encodedData = try? JSONEncoder().encode(data)
        let json = String(data: encodedData!, encoding: .utf8)!
        return json
    }
    
    
    class SharedMediaFile: Codable {
        var path: String;
        var thumbnail: String?; // video thumbnail
        var duration: Double?; // video duration in milliseconds
        var type: SharedMediaType;
        
        func toJson() -> String? {
            let encodedData = try? JSONEncoder().encode(self)
            let json = String(data: encodedData!, encoding: .utf8)!
            return json
        }
        
        
        init(path: String, thumbnail: String?, duration: Double?, type: SharedMediaType) {
            self.path = path
            self.thumbnail = thumbnail
            self.duration = duration
            self.type = type
        }
        
    }
    
    class SharedUrl: Codable {
        var url: String?;
        var mediaPath: String?;
        
        func toJson() -> String? {
            let encodedData = try? JSONEncoder().encode(self)
            let json = String(data: encodedData!, encoding: .utf8)!
            return json
        }
        
        init(url: String?, mediaPath: String?) {
            self.url = url
            self.mediaPath = mediaPath
        }
    }
    
    enum SharedMediaType: Int, Codable {
        case image
        case video
    }
}
