//
//  ReferenceViewController.swift
//  TweetSent
//
//  Created by Simeon Bikorimana on 9/15/18.
//  Copyright © 2019 Exile Capital Management, LP. All rights reserved.
//

import UIKit
//Write the protocol declaration here:
protocol ReferenceDelegate {
    func userSearchReference()
}
class ReferenceViewController: UIViewController {

     var delegate : ReferenceDelegate?
    //This is the IBAction that gets called when the user taps the back button. It dismisses the ChangeCityViewController.
    
    @IBAction func goBackBottonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Do any additional setup after loading the view.
//    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
