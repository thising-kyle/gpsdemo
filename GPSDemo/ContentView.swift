//
//  ContentView.swift
//  GPSDemo
//
//  Created by Kyle Davis on 2022/11/29.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    
    let locationManager: CLLocationManager = CLLocationManager()
    @State var status: String = ""
    var body: some View {
        List {
            Section("Status") {
                Text(status)
            }
            
            Section("Request") {
                Button {
                    //设置定位服务管理器代理
                    locationManager.delegate = self

                    //更新距离
                    locationManager.distanceFilter = 1
                    
                    // 发送授权申请
                    locationManager.requestAlwaysAuthorization()
                    locationManager.allowsBackgroundLocationUpdates=true
                    
                    locationManager.pausesLocationUpdatesAutomatically = false
                } label: {
                    Text("Request Always Authorization")
                }
            }
            
            Section("Accuracy") {
                Button {
                    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                } label: {
                    Text("Best For Navigation")
                }
                
                Button {
                    locationManager.desiredAccuracy = kCLLocationAccuracyBest
                } label: {
                    Text("Best")
                }
                
                Button {
                    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                } label: {
                    Text("TenMeters(10m)")
                }
                
                Button {
                    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                } label: {
                    Text("HundredMeters(100m)")
                }
                
                Button {
                    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
                } label: {
                    Text("Kilometer(1000m)")
                }
            }
            
            Section("Action") {
                Button {
                    if (CLLocationManager.locationServicesEnabled())
                    {
                        //允许使用定位服务的话，开启定位服务更新
                        status = "可以定位"
                        print("可以定位")
                        startRequestLocation()
                    }
                } label: {
                    Text("Start")
                }
                
                Button {
                    
                } label: {
                    Text("Stop")
                }
            }
        }
        .padding()
    }
}

extension ContentView {
    func startRequestLocation() {
            if (self.locationManager != nil) && (CLLocationManager.authorizationStatus() == .denied) {
                // 没有获取到权限，再次请求授权
                print("拒绝授权")
                self.locationManager.requestWhenInUseAuthorization()
            } else {
                status = "开始定位"
                print("开始定位")
                locationManager.startUpdatingLocation()
            }
        }
}

extension ContentView: CLLocationManagerDelegate {
    //定位改变执行，可以得到新位置、旧位置
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //获取最新的坐标
        print("获取定位结果")
        let currLocation:CLLocation = locations.last!
        print("获取定位结果")
        print("经度：\(currLocation.coordinate.longitude)\n经度：\(currLocation.coordinate.longitude)\n海拔：\(currLocation.altitude)\n水平精度：\(currLocation.horizontalAccuracy)\n垂直精度：\(currLocation.verticalAccuracy)\n方向：\(currLocation.course)\n速度：\(currLocation.speed)")
    }
    // 代理方法，当定位授权更新时回调
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("授权变化")
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
            
        }else{
            startRequestLocation()
        }
    }
    
    // 当获取定位出错时调用
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 这里应该停止调用api
        print(error)
        print(error.localizedDescription)
        print("定位失败")
        self.locationManager.stopUpdatingLocation()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
