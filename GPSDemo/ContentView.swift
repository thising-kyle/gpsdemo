//
//  ContentView.swift
//  GPSDemo
//
//  Created by Kyle Davis on 2022/11/29.
//

import SwiftUI
import CoreLocation

struct LocalStatus {
    var tracking: String {
        get {
            return _tracking ? "Enabled" : "Disabled"
        }
    }
    
    var currentLocation: String {
        get {
            return ("经度：\(_currentLocation.coordinate.longitude)\n纬度：\(_currentLocation.coordinate.latitude)\n海拔：\(_currentLocation.altitude)\n水平精度：\(_currentLocation.horizontalAccuracy)\n垂直精度：\(_currentLocation.verticalAccuracy)\n方向：\(_currentLocation.course)\n速度：\(_currentLocation.speed)")
        }
    }
    
    var desiredAccuracy: String {
        get {
            switch(_desiredAccuracy) {
            case kCLLocationAccuracyBestForNavigation:
                return "Best For Navigation"
                break
            case kCLLocationAccuracyBest:
                return "Best"
                break
            case kCLLocationAccuracyNearestTenMeters:
                return "10m"
                break
            case kCLLocationAccuracyHundredMeters:
                return "100m"
                break
            case kCLLocationAccuracyKilometer:
                return "1000m"
                break
            default:
                return "unknown"
            }
        }
    }
    
    var authorizationStatus: String {
        get {
            switch(_authorizationStatus) {
            case .authorizedAlways:
                return "Always"
                break
            case .authorizedWhenInUse:
                return "In use"
                break
            case .restricted:
                return "Restricted"
                break
            case .denied:
                return "Denied"
                break
            case .notDetermined:
                return "Not determined"
                break
            default:
                return "unknown"
            }
        }
    }
    
    var _tracking: Bool = false
    var _currentLocation: CLLocation = CLLocation()
    var _desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyKilometer
    var _authorizationStatus: CLAuthorizationStatus = .notDetermined
    var _count: Int = 0
    
    var description: String {
        get {
            return ("AuthorizationStatus:\(self.authorizationStatus)\nTracking::\(self.tracking)\nDesiredAccuracy::\(self.desiredAccuracy)\nLocation(\(self._count)):\(self.currentLocation)")
        }
    }
}

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var localStatus: LocalStatus = LocalStatus()
    
    // http settings
    private let HTTP_HEADER_CONTENT_TYPE_KEY                  = "Content-Type"
    private let HTTP_HEADER_CONTENT_TYPE_VALUE                = "application/json"
    private let HTTP_METHOD_POST                              = "POST"
    private let HTTP_TIMEOUT                                  = 30.0
    
    // request keys
    private let REQUEST_HEADER_LONGITUDE = "longitude"
    private let REQUEST_HEADER_LATITUDE = "latitude"
    private let REQUEST_HEADER_ALTITUDE = "altitude"
    private let REQUEST_HEADER_HORIZONTALACCURACY = "horizontalAccuracy"
    private let REQUEST_HEADER_VERTICALACCURACY = "verticalAccuracy"
    private let REQUEST_HEADER_COURSE = "course"
    private let REQUEST_HEADER_SPEED = "speed"
    private let REQUEST_HEADER_TIMESTAMP = "timestamp"
    
    private var locationManager: CLLocationManager = CLLocationManager()
    
    override init() {
        super.init()
        
        localStatus._authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        //设置定位服务管理器代理
        locationManager.delegate = self

        //更新距离
        locationManager.distanceFilter = 5
        
        // 发送授权申请
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates=true
        
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func startRequestLocation() {
        if (self.locationManager != nil) && (CLLocationManager.authorizationStatus() == .denied) {
            // 没有获取到权限，再次请求授权
            print("拒绝授权")
            self.locationManager.requestWhenInUseAuthorization()
        } else {
            print("开始定位")
            locationManager.startUpdatingLocation()
            
            self.localStatus._tracking = true
        }
    }
    
    func stopRequestLocation() {
        locationManager.stopUpdatingLocation()
        
        self.localStatus._tracking = false
    }
    
    func setDesiredAccuracy(_ accuracy: CLLocationAccuracy) {
        locationManager.desiredAccuracy = accuracy
        
        self.localStatus._desiredAccuracy = locationManager.desiredAccuracy
    }
    
    func remoteLog(_ location: CLLocation) {
        
        self.localStatus._count += 1
        self.localStatus._currentLocation = location
        
        let completeUrl : String = "https://alert.qai.co/api/setGps"
        
        print("Request url: \(completeUrl)")
        
        let urlSession = URLSession.shared
        let url = URL(string: completeUrl)!
        var request =  URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: HTTP_TIMEOUT)
        request.httpMethod =  HTTP_METHOD_POST
        request.addValue(HTTP_HEADER_CONTENT_TYPE_VALUE, forHTTPHeaderField: HTTP_HEADER_CONTENT_TYPE_KEY)
        
        var para : [String : Any] = [:]
        para[REQUEST_HEADER_LONGITUDE] = location.coordinate.longitude
        para[REQUEST_HEADER_LATITUDE] = location.coordinate.latitude
        para[REQUEST_HEADER_ALTITUDE] = location.altitude
        para[REQUEST_HEADER_HORIZONTALACCURACY] = location.horizontalAccuracy
        para[REQUEST_HEADER_VERTICALACCURACY] = location.verticalAccuracy
        para[REQUEST_HEADER_COURSE] = location.course
        para[REQUEST_HEADER_SPEED] = location.speed
        para[REQUEST_HEADER_TIMESTAMP] = Date().timeIntervalSince1970
        
        print("source body = \(para)")
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: para, options: .prettyPrinted) else {
            print("no parames")
            return
        }
        
        let jsonString = String(data: httpBody, encoding: String.Encoding.utf8)
        print("json body = \(jsonString ?? "nil json")")
        
        request.httpBody = httpBody
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            
            if error != nil || data == nil {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Client error")
                }
                
                return
            }
            
            if let httpResp = response as? HTTPURLResponse {
                guard let value = data else {
                    print("no data ")
                    return
                }
                
                let tmp = String(decoding: value, as: UTF8.self)
                
                print("source response::\(httpResp.statusCode)::\(tmp)")
            }
        }
        
        task.resume()
    }
    
    //定位改变执行，可以得到新位置、旧位置
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //获取最新的坐标
        print("获取定位结果")
        let currLocation:CLLocation = locations.last!
        print("获取定位结果")
        print("经度：\(currLocation.coordinate.longitude)\n纬度：\(currLocation.coordinate.latitude)\n海拔：\(currLocation.altitude)\n水平精度：\(currLocation.horizontalAccuracy)\n垂直精度：\(currLocation.verticalAccuracy)\n方向：\(currLocation.course)\n速度：\(currLocation.speed)")
        
        self.remoteLog(currLocation)
    }
    
    // 代理方法，当定位授权更新时回调
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        print("授权变化")
        localStatus._authorizationStatus = manager.authorizationStatus
        
        // CLAuthorizationStatus
        // .notDetermined   用户还没有选择授权
        // .restricted   应用没有授权用户定位
        // .denied 用户禁止定位
        // .authorizedAlways 用户授权一直可以获取定位
        // .authorizedWhenInUse 用户授权使用期间获取定位
        // TODO...
        if status == .notDetermined {
            //未授予
        } else if (status == .restricted) {
            // 受限制，尝试提示然后进入设置页面进行处理
            
        } else if (status == .denied) {
            // 被拒绝，尝试提示然后进入设置页面进行处理
            
        } else {
            //startRequestLocation()
        }
    }
    
    // 当获取定位出错时调用
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 这里应该停止调用api
        print(error)
        print(error.localizedDescription)
        print("定位失败")
        //self.locationManager.stopUpdatingLocation()
    }
}

struct ContentView: View {
    
    @StateObject var model = LocationViewModel()
    
    let locationManager: CLLocationManager = CLLocationManager()
    
    var body: some View {
        List {
            Section("Status") {
                Text(model.localStatus.description)
            }
            
            Section("Request") {
                Button {
                    model.requestPermission()
                } label: {
                    Text("Request Permission")
                }
            }
            
            Section("Accuracy") {
                Button {
                    model.setDesiredAccuracy(kCLLocationAccuracyBestForNavigation)
                } label: {
                    Text("Best For Navigation")
                }
                
                Button {
                    model.setDesiredAccuracy(kCLLocationAccuracyBest)
                } label: {
                    Text("Best")
                }
                
                Button {
                    model.setDesiredAccuracy(kCLLocationAccuracyNearestTenMeters)
                } label: {
                    Text("TenMeters(10m)")
                }
                
                Button {
                    model.setDesiredAccuracy(kCLLocationAccuracyHundredMeters)
                } label: {
                    Text("HundredMeters(100m)")
                }
                
                Button {
                    model.setDesiredAccuracy(kCLLocationAccuracyKilometer)
                } label: {
                    Text("Kilometer(1000m)")
                }
            }
            
            Section("Action") {
                Button {
                    if (CLLocationManager.locationServicesEnabled())
                    {
                        //允许使用定位服务的话，开启定位服务更新
                        print("可以定位")
                        model.startRequestLocation()
                    }
                } label: {
                    Text("Start")
                }
                
                Button {
                    model.stopRequestLocation()
                } label: {
                    Text("Stop")
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
