//
//  ViewController.swift
//  Twitter Data Sentiment Analyzer
//
//  Created by Simeon Bikorimana on 08/4/18.
//  Copyright © 2019 Exile Capital Management,LLP. All rights reserved.
//

// MARK: -modules to import
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
import UIKit
import SwifteriOS
import CoreML
import SwiftyJSON
import Foundation
import Charts
import RappleProgressHUD

//MARK: -ViewController class
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

class ViewController: UIViewController, UITextFieldDelegate, ReferenceDelegate {
   
    // Function for the ViewController to comfort to the Delegate which takes the user to
    // the next pager of reference: Sentiment Indicator
    
    func userSearchReference() {
       
    }
    
    //@IBOutlet variables
    // add UITextFieldDelegate  to dismiss the keyboard
    @IBOutlet weak var goForward: UINavigationItem!
    
    @IBOutlet weak var neutralSentimentScore: UILabel!
    
    @IBOutlet weak var pieChart: PieChartView!
    
    @IBOutlet weak var sentimentLabel: UILabel!
    
    @IBOutlet weak var textField: UITextField!
    
    
    // Properties declaration
    let tweetCount = 100// Standard Twitter API allows only a maximum of 100 tweets
    let sentimentClassifier = TweetSentimentClassifierSanders()
    let swifter = Swifter(consumerKey: "QLIWRk7Dl2vlJBEWXEcJ0Y3tA", consumerSecret: "QDEPuluItfbBlYdo5OgntympfpMg807nXU6BF1xtVmCZ3tM2V7")// initialize it with your twitter dev credentials. Used crednetials belongs to Simeon Bikorimana
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // to dissmiss the keyboard
        textField.delegate = self
        
        // to move the textfield
        // Listen for keyword events
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil) //You can use any
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil) //You can use any
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil) //You can use any
        
    }
    
    // stop listening
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    //@IBAction for Get Sentiment buttton
    @IBAction func getSentimentPressed(_ sender: Any) {
        // Object to be called to fetch tweets
        fetchTweets()

    }
    
    //MARK:-Methods and functions
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // To dismiss the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        
        
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            view.frame.origin.y = -keyboardRect.height
        } else {
            view.frame.origin.y = 0
        }
        
    }
    func hidekeyboard(){
        
        textField.resignFirstResponder()
    }
    // UITextFieldDelegate Methods
    func textFiledShouldReturn(_textField: UITextField)-> Bool {
        //print("Return pressed")
        hidekeyboard()
        return true
    }
    
    // fetchingTweets
    func fetchTweets() {
        
        loadRappleProgressHUD()
        Thread.sleep(forTimeInterval: 0.005)
        if let searchText = textField.text {
            
            swifter.searchTweet(using: searchText, lang: "en", count: tweetCount, tweetMode: .extended, success: { (results, metadata) in
                
                var tweets = [TweetSentimentClassifierSandersInput]()
                
                for i in 0..<self.tweetCount {
                    if let tweet = results[i]["full_text"].string {
                        let tweetForClassification = TweetSentimentClassifierSandersInput(text: tweet)
                        tweets.append(tweetForClassification)
                    }
                }
                
                self.makePrediction(with: tweets)
                
            }) { (error) in
                //print("There was an error with the Twitter API Request, \(error)")
            RappleActivityIndicatorView.stopAnimation(completionIndicator: .success, completionLabel: " Twitter API Error.", completionTimeout: 1.0)
            }
        }
        
    }
    //MARK: - Progress bar
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    func loadRappleProgressHUD() {
        
        let attribute = RappleActivityIndicatorView.attribute(style: .apple, tintColor: .white, screenBG: .purple, progressBG: .black, progressBarBG: .lightGray, progreeBarFill: .green, thickness: 4)
        
        RappleActivityIndicatorView.startAnimatingWithLabel("Predicting...", attributes: attribute)
        
        Thread.detachNewThread {
            self.runCustomProgress()
        }
        
    }
    
    @objc func stopAnimation() {
        DispatchQueue.main.async {
            let timeOut: TimeInterval = 1
            
            RappleActivityIndicatorView.stopAnimation(completionIndicator: .success, completionLabel: "Completed.", completionTimeout: timeOut)
        }
    }
    
    @objc func runCustomProgress() {
        var i: CGFloat = 0
        while i <= 100 {
            RappleActivityIndicatorView.setProgress(i/100)
            i += 1
            Thread.sleep(forTimeInterval: 0.005)// 0.003
        }
        RappleActivityIndicatorView.stopAnimation(completionIndicator: .success, completionLabel: "", completionTimeout: 1.0)

    }
    
    //MARK: -Sentiment prediction method
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Function to make prediction on tweets document
    func makePrediction(with tweets: [TweetSentimentClassifierSandersInput]) {
        
        do {
            
            var posSentimentScoreChartDataEntry = PieChartDataEntry(value: 0)
            var negSentimentScoreChartDataEntry = PieChartDataEntry(value: 0)
            //var neutSentimentScoreChartDataEntry = PieChartDataEntry(value: 0)
            var numberOfTweets = [PieChartDataEntry]()
            
            // Tweets parameters
            var count = 0
            var posSentimentScore = 0.0
            var poSentPercentage = 0.0
            var neutSentimentScore = 0.0
            var neuSentPercentage = 0.0
            var negSentimentScore = 0.0
            var negSentPercentage = 0.0
            //var log10SentimentScore = 0.0
            //var averageSentimentIndicator = 0.0
            var posSentimentCount = 0.0
            var negSentimentCount = 0.0
            
            
            let predictions = try self.sentimentClassifier.predictions(inputs: tweets)
            var sentimentScore = 0.0
            // for loop to scan and assign scores to fetched tweets
            for pred in predictions {
                
                let sentiment = pred.label
                
                if sentiment == "positive" {
                    
                    posSentimentScore += 1
                    posSentimentCount += 1
                    posSentimentScoreChartDataEntry.value = posSentimentScore
                    posSentimentCount += 1
                } else if sentiment == "negative"{
                    negSentimentScore -= 1
                    negSentimentCount += 1
                    negSentimentScoreChartDataEntry.value = negSentimentScore
                } else {
                    neutSentimentScore += 1
                    //neutSentimentScoreChartDataEntry.value = neutSentimentScore
                }
                count += 1
            }
            
            // predictor construction
            
            sentimentScore  = negSentimentScore + posSentimentScore
            poSentPercentage = (posSentimentScore/Double(count))*100
            neuSentPercentage = (1 - ((((-1) * negSentimentScore) + posSentimentScore)/Double(count)))*100
            negSentPercentage = (abs(negSentimentScore)/Double(count))*100
            
//            log10SentimentScore =  log10(Double(1+posSentimentCount)/Double((1+negSentimentCount)))
//
//            averageSentimentIndicator = Double(sentimentScore) / Double(count)
//
            //negSentPercentage = 0.0
            //poSentPercentage = 0.0
            // chart
        
            if (count == 0){
                self.neutralSentimentScore.text = ""
                pieChart.chartDescription?.text = ""
                RappleActivityIndicatorView.stopAnimation(completionIndicator: .unknown, completionLabel: " Unkown!", completionTimeout: 1)
                
            }
           else  if (negSentPercentage == 0.0) && (poSentPercentage == 0.0) && (count != 0) {
                
                self.neutralSentimentScore.text = " Neutral Score: " + String (format: "%.2f", neuSentPercentage) + "(%)"
                    pieChart.chartDescription?.text = ""
                RappleActivityIndicatorView.stopAnimation(completionIndicator: .success, completionLabel: "Completed.", completionTimeout: 1.0)
                
            } else {
                self.neutralSentimentScore.text = ""
                pieChart.chartDescription?.text = "Sentiment Score: " + String(format : "%.2f", sentimentScore) + ", Positive: " + String(format:"%.2f", poSentPercentage) + "%" + ", Neutral: " + String(format: "%.2f",neuSentPercentage) + "%" + ", Negative: " + String(format: "%.2f", negSentPercentage) + "%" + "          "
                
                
                posSentimentScoreChartDataEntry.value = (posSentimentScore/Double(count))*100
                posSentimentScoreChartDataEntry.label = "Positive(%)"
                
                //neutSentimentScoreChartDataEntry.value = (neutSentimentScore/Double(count))*100
                //neutSentimentScoreChartDataEntry.label = "Neut."
                
                negSentimentScoreChartDataEntry.value = (abs(negSentimentScore)/Double(count))*100
                negSentimentScoreChartDataEntry.label = "Negative(%)"
                
                numberOfTweets = [posSentimentScoreChartDataEntry, negSentimentScoreChartDataEntry ]
                
                RappleActivityIndicatorView.stopAnimation(completionIndicator: .success, completionLabel: "Completed.", completionTimeout: 1.0)
            }
           
            
            // Debugging

//            print("#positive score:", posSentimentScore)
//            print("#Neutral score:", neutSentimentScore)
//            print("#negative score:", negSentimentScore)
//            print("linear:", sentimentScore)
//            print ("log10:", log10SentimentScore)
//            print("averangeSentimentIndicator:",averageSentimentIndicator)
//            print("+++++++++++++++++++++++++++++")
//            print ("Tweets Count:", count)
//            print("Chart Postive Data:", posSentimentScoreChartDataEntry.value)
//            print("Chart Neutral Data:", neutSentimentScoreChartDataEntry.value)
//            print("Chart Negative Data:", negSentimentScoreChartDataEntry.value)

            
            // upDateUI method
          
            updateUI(with: Int(sentimentScore))
            updateChartData(with: numberOfTweets)
            
        } catch {
            //print("There was an error with making a prediction, \(error)")
            RappleActivityIndicatorView.stopAnimation(completionIndicator: .failed, completionLabel: "Failed.", completionTimeout: 1)
        }
        
    }
    
        //upDateUI function

    func updateUI(with sentimentScore: Int) {
        // Sentiment expressions
        if sentimentScore > 20 {
            self.sentimentLabel.text = "😍"
        } else if sentimentScore > 10 {
            self.sentimentLabel.text = "😀"
        } else if sentimentScore > 0 {
            self.sentimentLabel.text = "🙂"
        } else if sentimentScore == 0 {
            self.sentimentLabel.text = "😐"
        } else if sentimentScore > -10 {
            self.sentimentLabel.text = "😕"
        } else if sentimentScore > -20 {
            self.sentimentLabel.text = "😡"
        } else {
            self.sentimentLabel.text = "🥵"
        }
    }
    
    // UpdatingChartData based on the prediction entry data
    func updateChartData(with numberOfTweets: [ChartDataEntry]){
        
        let chartDataSet = PieChartDataSet(values: numberOfTweets, label: nil)// or use nil
        
        let chartData = PieChartData(dataSet: chartDataSet)
        
        let colors = [UIColor(named: "positive"), UIColor(named:"negative")]
        
        chartDataSet.colors = colors as![UIColor]
        
        pieChart.data = chartData
        
    }
    
    
    
}
//MARK: - UIButton settings
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Button settings

    @IBDesignable extension UIButton {
        
        @IBInspectable var borderWidth: CGFloat {
            set {
                layer.borderWidth = newValue
            }
            get {
                return layer.borderWidth
            }
        }
        
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
    

    // PrepareForSegue Method here
    
   func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "NavigateReference" {
            
            let destinationVC = segue.destination as! ReferenceViewController
            
            
            destinationVC.delegate = self as? ReferenceDelegate
            
        }
        
    }
    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//    }
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++END+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
}

