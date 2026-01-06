//
//  ViewController.swift
//  calculator
//
//  Created by 龘天 on 2022/1/30.
//

import UIKit
import Kanna

class ViewController: UIViewController, URLSessionDownloadDelegate {
    //Main中的螢幕大小
    let projectScreenWidth: Double = 414
    let projectScreenHeight: Double = 736
    var adjustedWidth: Double = 0
    var adjustedHeight: Double = 0
    var magnification: Double = 1
    //  第一次、前一次的值
    var number01:Double?
    //  點選運算符號後輸入的值，若未輸入則會以原來的值繼續在計算
    var number02:Double?
    //  運算符號
    var operationSign:String?
    //  是否正在輸入狀態（沒有點選其他功能鍵)
    var typeing:Bool = false
    //  是否有計按下等於鍵
    var lastIsEqualBtn:Bool = false
    //  用於判斷正負號按鈕，監聽使用者是否有點選運算符號，那就代表沒有輸入要變負號的值
    var typeOperation = false
    //  紀錄點選的運算符號按鈕
    var currentOperatorBtn:UIButton?

    var firstCalculation = true
    var dotExisted = false
    var percentBtnCounting = 0
    var mode = "A"
    
    @IBOutlet weak var ansLabel: UILabel!
    @IBOutlet weak var equalBtn: UIButton!
    @IBOutlet var AllButtons: [UIButton]!
    @IBOutlet weak var closeBtn: UIButton!
    
    // 將狀態列顯示成light style
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func fixPosition (point: CGPoint) -> (Double, Double) {
        let newWidth = point.x * magnification
        let space = (UIScreen.main.bounds.size.width - adjustedWidth) / 2

        let newX = newWidth + space
        let originalHeight = projectScreenHeight - point.y
        let newHeight = originalHeight * magnification
        let newY = UIScreen.main.bounds.size.height - newHeight //要用原始的螢幕長度去扣 因為要靠下
        return (newX, newY)
    }
    
    func fixItemsPositionAndScale() {
        let newAnsLabelPosition: (Double, Double) = fixPosition(point: ansLabel.center)
        ansLabel.frame.size.width = ansLabel.frame.width * magnification
        ansLabel.frame.size.height = ansLabel.frame.height * magnification
        ansLabel.center = CGPoint(x: newAnsLabelPosition.0, y: newAnsLabelPosition.1)
        for button in AllButtons {
            let newButtonPosition = fixPosition(point: button.center)
            button.frame.size.width = button.frame.width * magnification
            button.frame.size.height = button.frame.height * magnification
            
            button.center = CGPoint(x: newButtonPosition.0, y: newButtonPosition.1)
            
        }
    }
    
    //  呼叫時若=在左邊代表要get，反之是set
    var input: Double{
        //  將使用者輸入的值傳回
        get{
            return Double(ansLabel.text!)!
        }
        //  顯示話格式於ansLabel顯示
        set{
            ansLabel.text = "\(removeDotZero(num: newValue))"
            typeing = false
        }
    }

    // 把".0"刪掉
    func removeDotZero (num: Double) -> String {
        var showingText = String(num)
        if showingText.hasSuffix(".0") {
            showingText.removeLast(2)
        }
        return showingText
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //  預設值設定為0
        ansLabel.text = String(Int(0))
        ansLabel.adjustsFontSizeToFitWidth = true
        closeBtn.isHidden = true
        let fullScreenSize = UIScreen.main.bounds.size
        let projectRatio = projectScreenHeight / projectScreenWidth
        let buildingRatio: Double = fullScreenSize.height / fullScreenSize.width
        if (buildingRatio >= projectRatio) { //運行裝置的螢幕比較長
            adjustedWidth = fullScreenSize.width
            adjustedHeight = adjustedWidth * projectRatio //16:9
            magnification = adjustedWidth / projectScreenWidth
        } else { //運行裝置的螢幕比較寬
            adjustedHeight = fullScreenSize.height
            adjustedWidth = adjustedHeight / projectRatio
            magnification = adjustedHeight / projectScreenHeight
        }
        fixItemsPositionAndScale()
    }
    
    //  數字鍵點按時候
    @IBAction func NumberBtn(_ sender: UIButton) {
        //   取得點選的數字
        let number = sender.accessibilityLabel!
        //  如果已經有其他數字在之前就輸入，就要記錄串起來
        if typeing {
            if number == "." {
                if !dotExisted {
                    ansLabel.text = ansLabel.text! + number
                    dotExisted = true
                }
            } else {
                ansLabel.text = ansLabel.text! + number
            }
        //  若之前沒有輸入過數值，若為0也可能是第一次
        }else{
            //  如果不是輸入0
            if number != "0"{
                if number == "." {
                    ansLabel.text! = "0."
                } else {
                    //  就當做第一次輸入然後顯示出來，不串起來
                    ansLabel.text = number
                }
                //  認為使用者會再輸入其他數字，就會進入上面那段
                typeing = true
            //  如果他是輸入0，且是第一次，就還是顯示0，因為不可能顯示000000...
            }else{
                ansLabel.text = "0"
                typeing = false
            }
            dotExisted = false
        }
        //  若在點選數字鍵前有按過運算符號，點選數字鍵後要將運算符號的顏色恢復
        changeColor(change: "SelectedToDefault")
        typeOperation = false
    }
    
    //必須用Decimal計算 不能用Double 不然會有誤差
    func operation (num1: Double, num2: Double) -> Double {
        let decimalNum1: Decimal = Decimal(num1)
        let decimalNum2: Decimal = Decimal(num2)
        var result: Decimal = 0 //其實這個0沒意義 只是先把他初始化
        switch operationSign {
        case "+":
            result = decimalNum1 + decimalNum2
        case "-":
            result = decimalNum1 - decimalNum2
        case "x":
            result = decimalNum1 * decimalNum2
        case "÷":
            result = decimalNum1 / decimalNum2
        default:
            print("計算發生錯誤")
        }
        return Double(truncating: result as NSNumber)
    }
    
    @IBAction func percentBtnSelected(_ sender: UIButton) {
        //  將畫面值直接除以100，計算百分比
        let orgOperationSign = operationSign
        operationSign = "÷"
        input = operation(num1: input , num2: Double(100))
        operationSign = orgOperationSign
    }
    
    //  運算按鈕點選
    @IBAction func operationBtnPressed(_ sender: UIButton) {
        if !lastIsEqualBtn {
            //連續兩次按運算符號 先把上一次的清掉
            if typeOperation {
                changeColor(change: "SelectedToDefault")
                operationSign = sender.accessibilityLabel
            } else {
                //第一次按運算符號
                if firstCalculation {
                    //  抓出運算符號
                    operationSign = sender.accessibilityLabel
                    //  先不做計算，但將值計入至畫面上label
                    number01 = input
                    //  且認為上一次的輸入已經結束
                    typeing = false
                    firstCalculation = false
                } else { //第二次以後按運算符號
                    number02 = input
                    input = operation(num1: number01!, num2: number02!)
                    
                    //準備給下次運算
                    operationSign = sender.accessibilityLabel
                    number01 = input
                    number02 = nil
                }
            }
        } else {
            operationSign = sender.accessibilityLabel
            number01 = input
            typeing = false
            lastIsEqualBtn = false
        }
        currentOperatorBtn = sender
        changeColor(change: "DefaultToSelected")
        typeOperation = true
    }
    
    //  正負號按鈕
    @IBAction func negativeBtn(_ sender: UIButton) {
        //  抓取畫面上的值
        var tempResult = input
        //  因為等等為了要運算，所以先記錄最後一次的運算符號
        let orgOperationSign = operationSign
        //  如果使用者上一個動作是按運算符號，那就只需將畫面上的值做變更
        if typeOperation {
            input = -0
        //  若是已經輸入完要變更正負值，那就是值輸入值乘以-1
        }else{
            operationSign = "x"
            tempResult = operation(num1: tempResult , num2: -1)
            //  變完後要把最後一次的運算值放回去
            operationSign = orgOperationSign
            input = tempResult
        }
    }
    
    //  變更按鈕顏色（用於運算符號）
    func changeColor(change: String){
        
        if currentOperatorBtn != nil {
            var signName = ""
            switch currentOperatorBtn?.accessibilityLabel! {
            case "+":
                signName = "symbolPlus"
            case "-":
                signName = "symbolMinus"
            case "x":
                signName = "symbolMultiply"
            case "÷":
                signName = "symbolDivide"
            default:
                print("Operation Sign Error!")
            }
            if change == "DefaultToSelected" {
                currentOperatorBtn?.setBackgroundImage(UIImage(named: signName + "Selected"), for: .normal)
                currentOperatorBtn?.setBackgroundImage(UIImage(named: signName + "Highlighted2"), for: .highlighted)
            }
            else if change == "SelectedToDefault" {
                currentOperatorBtn?.setBackgroundImage(UIImage(named: signName), for: .normal)
                currentOperatorBtn?.setBackgroundImage(UIImage(named: signName + "Highlighted"), for: .highlighted)
            }
        }
    }
    
    //  等於
    @IBAction func equalityPressed(_ sender: UIButton) {
        //  認為使用者輸入完畢
        typeing = false
        var tempResult:Double = 0
        //  若沒有點選過
        if !lastIsEqualBtn {
            //  若是按完第二次值，所以等於必須依據第一個值和第二個值中間的運算符號進行處理結果
            if operationSign != nil {
                //  抓取第二個值
                number02 = input
                //  運算
                tempResult = operation(num1: number01 ?? 0, num2: number02 ?? 0)
                //  顯示於畫面上
                input = tempResult
                //  設定使用者點選過=鍵計算過結果
                lastIsEqualBtn = true
            }
        //  連按等號
        } else {
            number01 = input
            //  運算
            tempResult = operation(num1: number01 ?? 0, num2: number02 ?? 0)
            //  顯示於畫面上
            input = tempResult
        }
        //  清除上一次運算符號的顏色
        changeColor(change: "SelectedToDefault")
        typeOperation = false
    }
    
    //  如果按了AC，則將全部過程和記錄都清空
    @IBAction func acButton(_ sender: UIButton) {
        input = 0
        number01 = nil
        number02 = nil
        operationSign = nil
        lastIsEqualBtn = false
        typeing = false
        typeOperation = false
        changeColor(change: "SelectedToDefault")
        firstCalculation = true
    }
    
    //設計給%%%用的 而獨立出來
    @IBAction func percentBtnPressed(_ sender: UIButton) {
        percentBtnCounting += 1
    }
    
    @IBAction func enterBtnPressed(_ sender: UIButton) {
        if (mode == "A") {
            if (percentBtnCounting == 3) {
                switchToModeB()
            } else {
                percentBtnCounting = 0
            }
        } else {
            downloadManager(gengo: ansLabel.text!)
        }
    }
    
    @IBAction func otherBtnPressed(_ sender: UIButton) {
        percentBtnCounting = 0
    }
    
    func switchToModeB(){
        mode = "B"
        percentBtnCounting = 0
        closeBtn.isHidden = false
        input = 0
    }
    
    @IBAction func switchToModeA(){
        mode = "A"
        percentBtnCounting = 0
        closeBtn.isHidden = true
        input = 0
    }
    
    
    func downloadManager(gengo: String){
        let honUrl = "https://nhentai.net/g/" + gengo
        let honPath = NSHomeDirectory() + "/Documents/" + gengo
        print(honPath)
        do {
            try FileManager.default.createDirectory(atPath: honPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Cannot create directory")
        }
        print("debug1")
        let url = URL(string: honUrl)
        var pages = "1"
        do{
            //取得送出後資料的回傳值
            let html = try String(contentsOf: url!)
            let doc = try HTML(html: html, encoding: .utf8)
            let pagesXpath = doc.xpath("//*[@id='tags']/div[@class='tag-container field-name']/span/a/span")
            pages = (pagesXpath.first?.text)!
            print("pages: " + pages)
        } catch {
            print(error)
        }
        
        print("debug2")
        for index in 1...Int(pages)! {
            let pageUrl = honUrl + "/\(index)"
            do{
                //取得送出後資料的回傳值
                let pageHtml = try String(contentsOf: URL(string: pageUrl)!)
                let doc = try HTML(html: pageHtml, encoding: .utf8)
                let imageXpath = doc.xpath("//*[@id='image-container']/a/img")
                let imageUrl = imageXpath.first?["src"]
                print("image link: " + imageUrl!)
                downloadImage(page: String(index), imageUrl: imageUrl!, gengo: String(gengo))
            } catch {
                print(error)
            }
        }
        print("debug3")
    }
    
    func downloadImage(page: String, imageUrl: String, gengo: String) {
        let url = URL(string: imageUrl)
        //使用者背景設定建立 session，並且給一個 session 的名字
        let gengoAndPage = gengo + "/" + page
        let config = URLSessionConfiguration.background(withIdentifier: gengoAndPage)
        print()
        // delegateQueue 如果為 nil，delegate 會在另外一個執行緒中被呼叫
        let session = URLSession(configuration: config, delegate: self,delegateQueue: nil)
        let dnTask = session.downloadTask(with: url!)
        dnTask.resume()
        print("downloding " + page)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let identifier = session.configuration.identifier!
        let folder = identifier.components(separatedBy:"/")[0]
        print("folder: " + folder)
        let fileName = downloadTask.originalRequest?.url?.lastPathComponent
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        var destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appending("/" + folder))
        do {
            try fileManager.createDirectory(at: destinationURLForFile, withIntermediateDirectories: true, attributes: nil)
            destinationURLForFile.appendPathComponent(String(describing: fileName!))
            try fileManager.moveItem(at: location, to: destinationURLForFile)
        }catch(let error){
            print(error)
        }
    }
    
    func saveImage(currentImage: UIImage, persent: CGFloat, path: String, index: Int){
        if let imageData = currentImage.jpegData(compressionQuality: persent) as NSData? {
            let fullPath = path + "/\(index)"
            imageData.write(toFile: fullPath, atomically: true)
            print("fullPath=\(fullPath)")
        }
    }
}

