//
//  TableVC.swift
//  XMCommDemo
//
//  Created by Ferdinand Urban on 07.10.2021.
//

import UIKit
import XMComm
import RxSwift

class CarListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  var cars: [Car] = [] {
    didSet {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  let defaults = UserDefaults.standard
  
  let commService = CommCarService.instance
  let restService = XMRestService.sharedInstance
  let disposeBag: DisposeBag = DisposeBag()
  
  @IBOutlet var tableView: UITableView!
  @IBOutlet weak var loginBtn: UIButton!
  @IBOutlet weak var getCarsBtn: UIButton!
  @IBOutlet weak var userNameLbl: UILabel!
  @IBOutlet weak var logoutBtn: UIButton!
  
  @IBAction func logoutBtnClick(_ sender: UIButton) {
    defaults.removeObject(forKey: "accessToken")
    defaults.removeObject(forKey: "refreshToken")
    defaults.removeObject(forKey: "deviceId")
    defaults.removeObject(forKey: "email")

    loginBtn.setTitle("Log In", for: .normal)
    userNameLbl.text = "N/A"
  }
  
  @IBAction func loginBtnClick(_ sender: UIButton) {
    login()
  }
  
  @IBAction func getCarsBtnClick(_ sender: UIButton) {
    restService.getCars() {[weak self](result) in
      switch result {
        case .failure(let error):
          print("error getting cars: \(error)")
        case .success(let cars):
          self?.cars = cars
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    userNameLbl.adjustsFontSizeToFitWidth = true
    loginBtn.layer.cornerRadius = 10.0
    getCarsBtn.layer.cornerRadius = 10.0
    logoutBtn.layer.cornerRadius = 10.0
    getCarsBtn.isEnabled = false
    
    tableView.delegate = self
    tableView.dataSource = self
    tableView.tableFooterView = UIView()
    tableView.bounces = false
    
    readDefaults()
    login()
    
  }
    
  func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    return cars.count
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 80
  }
  
  func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CarCell",
                                             for: indexPath)  as! CarCell
    cell.content = cars[indexPath.row]

    return cell
  }
  
  func tableView(_ tableView: UITableView,
                 didSelectRowAt indexPath: IndexPath) {
    if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CarDetailVC") as? CarDetailVC {
      let car = cars[indexPath.row]
      vc.car = car
      
      // Set currently selected car to communicate with
//      commService.currentCar = car
      
      if let navigator = navigationController {
        navigator.pushViewController(vc, animated: true)
      }
    }
  }
}
