//
//  ViewController.swift
//  weathearAppDemo
//
//  Created by Bhavin Kapadia on 2022-05-22.
//

import UIKit
import CoreLocation

//enum City: String {
//    case Current = "Current Location"
//    case Chicago = "Chicago"
//    case London = "London"
//    case LosAngeles = "Los Angeles"
//    case NewYork = "New York"
//    case Sacremento = "Sacremento"
//    case Toronto = "Toronto"
//}

enum City {
    case Current
    case Chicago
    case London
    case LosAngeles
    case NewYork
    case Sacremento
    case Toronto
    
    var name: String {
        switch self {
        case .Current:
            return "Current Location"
        case .Chicago:
            return "Chicago"
        case .London:
            return "London"
        case .LosAngeles:
            return "Los Angeles"
        case .NewYork:
            return "New York"
        case .Sacremento:
            return "Sacremento"
        case .Toronto:
            return "Toronto"
        }
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var currentInfoView: UIView!
    @IBOutlet var dailyWeatherTableView: UITableView!
    @IBOutlet weak var hourlyWeatherCollectionView: UICollectionView!
    @IBOutlet weak var cityImage: UIImageView!
    
    var dailyWeatherModel = [Daily]()
    var hourlyWeatherModel = [Current]()
    let locationManager  = CLLocationManager()
    var currenetLocation: CLLocation?
    var current: Current?
    let geoCoder = CLGeocoder()
    var cityName: String = ""
    let dataArray = [City.Current, City.Chicago, City.London, City.LosAngeles, City.NewYork, City.Sacremento, City.Toronto]
    var selectedCity = 0
    //    let cities: [City] = []
    let picker: UIPickerView = UIPickerView()
    var barAccessory:UIToolbar = UIToolbar()

    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        setupLocation()

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(cityPicker))
        
        dailyWeatherTableView.register(WeatherTableViewCell.nib(), forCellReuseIdentifier: WeatherTableViewCell.identifer)
        dailyWeatherTableView.delegate = self
        dailyWeatherTableView.dataSource = self
        
        hourlyWeatherCollectionView.register(HourlyWeatherCollectionViewCell.nib(), forCellWithReuseIdentifier: HourlyWeatherCollectionViewCell.identifer)
        
        hourlyWeatherCollectionView.delegate = self
        hourlyWeatherCollectionView.dataSource = self
        
        hourlyWeatherCollectionView.layer.borderColor = UIColor.lightGray.cgColor
        hourlyWeatherCollectionView.layer.borderWidth = 1.0
        hourlyWeatherCollectionView.layer.cornerRadius = 3.0 //if you want corner radius.addtional
    }
    
    @objc func cityPicker() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        picker.frame = CGRect(x: 0, y: 200, width: view.frame.width, height: view.frame.height)
        picker.autoresizingMask = .flexibleHeight

        picker.backgroundColor = .init(white: 0.9, alpha: 0.9)
        picker.delegate = self as UIPickerViewDelegate
        picker.dataSource = self as UIPickerViewDataSource
        picker.isHidden = false
        picker.selectRow(5, inComponent: 0, animated: true)
        self.view.addSubview(picker)
        picker.center = self.view.center
        
        // Toolbar
        let btnDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonTapped))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.canceButtonTapped))

        barAccessory = UIToolbar(frame: CGRect(x: 0, y: 0, width: picker.frame.width, height: 70))
        barAccessory.barStyle = .default
        barAccessory.isTranslucent = false
        barAccessory.isUserInteractionEnabled = true

        barAccessory.items = [cancelButton, spaceButton, btnDone]
        self.view.addSubview (barAccessory)
    }
    
    @objc func doneButtonTapped() {
        
        picker.isHidden = true
        barAccessory.isHidden = true
        self.navigationController?.isNavigationBarHidden = false
        
    }
    
    @objc func canceButtonTapped() {
        print("cancel")
//        view.endEditing(true)
        picker.isHidden = true
        barAccessory.isHidden = true
//        barAccessory.removeFromSuperview()
        self.navigationController?.isNavigationBarHidden = false

    }

    //Location
    
    func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func requestWeatherForLocation() {
        guard let currenetLocation = currenetLocation else {
            return
        }

        let long: Int = Int(currenetLocation.coordinate.longitude)
        let lat: Int = Int(currenetLocation.coordinate.latitude)
        
        let url = "https://api.openweathermap.org/data/2.5/onecall?lat=\(lat)&lon=\(long)&exclude=minutely,alerts&units=metric&appid=f1266e7ef11b56cc3e6f353b3bb2c635"
        
        URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
            
            // Validation
            guard let data = data, error == nil else {
                print("something's wrong with the data")
                return
            }
        
            // convert data to models/some object
            
            var json: WeatherResponse?
            do {
                json = try JSONDecoder().decode(WeatherResponse.self, from: data)
            } catch {
                print("error: \(error)")
            }
            
            guard let results = json else {
                return
            }
            
            let current = results.current
            self.current = current
            
            let dailyEntries = results.daily
            
            let hourlyEntries =  results.hourly[1...12]
            self.hourlyWeatherModel.append(contentsOf: hourlyEntries)
            self.dailyWeatherModel.append(contentsOf: dailyEntries)

            // GCD async
            DispatchQueue.main.async {
                self.dailyWeatherTableView.reloadData()
                self.hourlyWeatherCollectionView.reloadData()
                self.uiViewCurrentWeather()
            }
            
        }).resume()

    }
    
    func uiViewCurrentWeather() {
        currentInfoView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 0.3)
        
        let locationLabel =  UILabel(frame: CGRect(x: 10, y: 60, width: view.frame.size.width - 20, height: currentInfoView.frame.size.height/5))
        
        let summaryLabel = UILabel(frame: CGRect(x: 10, y: 60 + locationLabel.frame.size.height, width: view.frame.size.width - 20, height: currentInfoView.frame.size.height/15))
        
        let tempLabel = UILabel(frame: CGRect(x: 10, y: 60 + summaryLabel.frame.size.height + locationLabel.frame.size.height, width: view.frame.size.width - 20, height: currentInfoView.frame.size.height/10))

        
        self.cityImage.contentMode = .scaleToFill
        self.cityImage.image = UIImage(named: "toronto")

        currentInfoView.addSubview(locationLabel)
        currentInfoView.addSubview(summaryLabel)
        currentInfoView.addSubview(tempLabel)

        locationLabel.textAlignment = .center
        summaryLabel.textAlignment = .center
        tempLabel.textAlignment = .center

        tempLabel.font = UIFont(name: "Helvetica-Bold", size: 32)
        tempLabel.text = "\(Int(self.current!.temp))°"
        
        summaryLabel.font = UIFont(name: "Helvetica-Bold", size: 22)
        summaryLabel.text = "\(self.current!.weather[0].main)"

        locationLabel.font = UIFont(name: "Helvetica", size: 22)
        locationLabel.text = "Current Location"
        
        addBlurryEdgeToLabel(label: summaryLabel)
        addBlurryEdgeToLabel(label: locationLabel)
        addBlurryEdgeToLabel(label: tempLabel)
        }
    
    func addBlurryEdgeToLabel(label: UILabel) {
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.3)

        let maskLayer = CAGradientLayer()
        maskLayer.frame = label.bounds
        maskLayer.shadowRadius = 5
        maskLayer.shadowPath = CGPath(roundedRect: label.bounds.insetBy(dx: 50, dy: 5), cornerWidth: 15, cornerHeight: 10, transform: nil)
        maskLayer.shadowOpacity = 1
        maskLayer.shadowOffset = CGSize.zero
        maskLayer.shadowColor = UIColor.white.cgColor
        label.layer.mask = maskLayer
    }
}


extension ViewController:  UITableViewDelegate, UITableViewDataSource {
    //Table
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dailyWeatherModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WeatherTableViewCell.identifer, for: indexPath) as! WeatherTableViewCell
        cell.configureWithModel(with: dailyWeatherModel[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
}

extension ViewController:UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hourlyWeatherModel.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HourlyWeatherCollectionViewCell.identifer, for: indexPath) as! HourlyWeatherCollectionViewCell
        cell.configureWithModel(with: [hourlyWeatherModel[indexPath.item]])
        return cell
    }
}



extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let row = dataArray[row]
        return row.name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(row)
        
        selectedCity = row
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !locations.isEmpty, currenetLocation == nil  {
            currenetLocation = locations.first
            locationManager.stopUpdatingLocation()
            requestWeatherForLocation()
        }
        
        geoCoder.reverseGeocodeLocation(currenetLocation!, completionHandler: { (placemarks, _) -> Void in

            placemarks?.forEach { (placemark) in
                if let city = placemark.locality { self.cityName = city }
            }
        })
    }
}
