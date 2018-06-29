//
//  ViewController.swift
//  SmartCalculator
//
//  Created by SP19 on 30/5/18.
//  Copyright © 2018 UCU. All rights reserved.
//

import UIKit
import CoreGraphics
import Vision
import CoreML

class ViewController: UIViewController {

    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var predictionImage: UIImageView!
    
    var calculator = Calculator()
    var inputImageArray: [UIImage] = []
    var operationValues: [String] = []
    var rhsArray: [String] = []
    var lhsArray: [String] = []
    var rhsNumber: Int = 0
    var lhsNumber: Int = 0
    var path       = UIBezierPath()
    var startPoint = CGPoint()
    var touchPoint = CGPoint()
    var image : UIImage?
    
    let alert = UIAlertController(title: "CoreML Error", message: "Los numeros detectados rompieron CoreML \n😡", preferredStyle: .alert)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView.clipsToBounds          = true
        canvasView.isMultipleTouchEnabled = false
        canvasView.layer.borderWidth = 2
        canvasView.layer.borderColor = UIColor.blue.cgColor
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Perdon Sr.CoreML, no voy a dibujar eso otra vez", comment: "Default action"), style: .default, handler: { _ in
            NSLog("The \"OK\" alert occured.")
        }))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if let point = touch?.location(in: canvasView){
            startPoint = point
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if let point = touch?.location(in: canvasView){
            touchPoint = point
        }
        path.move(to: startPoint)
        path.addLine(to: touchPoint)
        startPoint = touchPoint
        draw()
    }
    
    func draw(){
        let strokeLayer         = CAShapeLayer()
        strokeLayer.fillColor   = nil
        strokeLayer.strokeColor = UIColor.white.cgColor
        strokeLayer.lineWidth   = 5
        strokeLayer.path        = path.cgPath
        canvasView.layer.addSublayer(strokeLayer)
        canvasView.setNeedsDisplay()
    }
    
    @IBAction func clearScreen(_ sender: Any) {
        path.removeAllPoints()  
        canvasView.layer.sublayers?.forEach({ $0.removeFromSuperlayer() })
        canvasView.setNeedsDisplay()
    }
    
    @IBAction func addition(_ sender: Any) {
            calculate(operation: "+")
    }

    @IBAction func substraction(_ sender: Any) {
            calculate(operation: "-")
    }
    
    @IBAction func division(_ sender: Any) {
        calculate(operation: "/")
    }
    
    @IBAction func multiplication(_ sender: Any) {
        calculate(operation: "*")
    }
    
    
    @IBAction func cleanAll(_ sender: Any) {
    
        inputImageArray = []
        operationValues = []
        rhsArray = []
        lhsArray = []
        rhsNumber = 0
        lhsNumber = 0
        path      = UIBezierPath()
        startPoint = CGPoint()
        touchPoint = CGPoint()
        image = UIImage()
        predictionLabel.text = "Prediction"
        outputTextView.text = ""
        predictionImage.image = UIImage()
    
    
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
        //return UIStatusBarStyle.default   // Make dark again
    }
    
    func calculate(operation: String) {
        findNumbers()
        if rhsArray.isEmpty {
            rhsNumber = arrayToNumber(arrayNumber: operationValues)
            outputTextView.text = String(rhsNumber)
            rhsArray = operationValues
            operationValues = []
            return
        }
        lhsNumber = arrayToNumber(arrayNumber: operationValues)
        var result = 0
        switch operation {
        case "+":
            result = calculator.addition(rhs:rhsNumber, lhs:lhsNumber)
        case "-":
            result = calculator.substraction(rhs:rhsNumber, lhs:lhsNumber)
        case "/":
            result = calculator.division(rhs:rhsNumber, lhs:lhsNumber)
        case "*":
            result = calculator.multiplication(rhs:rhsNumber, lhs:lhsNumber)
        default:
            result = -1
        }
        rhsNumber = result
        operationValues = []
        var text = outputTextView.text
        text?.append("\n")
        text?.append(String(result))
        outputTextView.text = text
        
    }
    
    func arrayToNumber(arrayNumber: Array<String>) -> Int{
        
        var result = ""
        for number in arrayNumber {
            result.append(number)
        }
        if result == "" { //guard
            self.present(alert, animated: true, completion: nil)
            return 0
        }
        return Int(result)!
    }
    
    @IBAction func canvasToImage(_ sender: Any) {
    }
    func findNumbers(){
        inputImageArray = []
        image = UIImage(view: canvasView)
        findText(image: image!)
        let e347 = E347()
        var text = ""
        do {
            for image in inputImageArray {
                let buffer = image.buffer()!
                let type = CVPixelBufferGetPixelFormatType(buffer)
                let prediction  = try e347.prediction(image: buffer)
                text = text + String(prediction.classLabel)
                operationValues.append(String(prediction.classLabel))
            }
            predictionLabel.text = "Prediction: "+text
            
        } catch {
            let alert = UIAlertController(title: "Error", message: "No se detectaron numeros", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Reintentar", comment: "Default action"), style: .default, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func findText(image: UIImage) {
        let imageRequest = VNDetectTextRectanglesRequest { (request, error) in
            guard let results = request.results else {
                print("no results :(")
                return
            }
            
            UIGraphicsBeginImageContextWithOptions(image.size, true, 0)
            
            let context = UIGraphicsGetCurrentContext()
            context?.setStrokeColor(UIColor.red.cgColor)
            context?.translateBy(x: 0, y: image.size.height)
            context?.scaleBy(x: 1, y: -1)
            context?.draw(image.cgImage!, in: CGRect(origin: .zero, size: image.size))
            
            
            
            for result in results {
                if let textObservation = result as? VNTextObservation {
                    guard let characterBoxes = textObservation.characterBoxes else { return }
                    for charBox in characterBoxes {
                       // var auxRect = charBox.boundingBox
                        
                        let rectBox = self.boundingBox(forRegionOfInterest: charBox.boundingBox, withinImageBounds: self.canvasView.bounds)
                        let asdfBox = CGRect(x: rectBox.minX,
                                             y: self.canvasView.bounds.height - rectBox.maxY,
                                             width: rectBox.width,
                                             height: rectBox.height)
                        
                        context?.stroke(rectBox, width: 4)
                        let cropped = image.cropped(boundingBox: asdfBox)!
                        let squareImage = self.drawInSquare(image: cropped)
                        let convertedImage = self.resizeImage(image: squareImage)
                        self.inputImageArray.append(convertedImage)

                        
                    }
                }
            }
            
            let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            self.predictionImage.image = drawnImage
        }
        imageRequest.reportCharacterBoxes = true
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!)
        
        do {
            try handler.perform([imageRequest])
        }
        catch {
            
        }
    }
    
    func shapeLayer(color: UIColor, frame: CGRect) -> CAShapeLayer {
        // Create a new layer.
        let layer = CAShapeLayer()
        
        // Configure layer's appearance.
        layer.fillColor = nil // No fill to show boxed object
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.borderWidth = 2
        
        // Vary the line color according to input.
        layer.borderColor = color.cgColor
        
        // Locate the layer.
        layer.anchorPoint = .zero
        layer.frame = frame
        layer.masksToBounds = true
        
        // Transform the layer to have same coordinate system as the imageView underneath it.
        layer.transform = CATransform3DMakeScale(1, -1, 1)
        
        return layer
    }
    
    private func cropImage(image:UIImage , cropRect:CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(cropRect.size, false, 0);
        let context = UIGraphicsGetCurrentContext();
        
        context?.translateBy(x: 0.0, y: image.size.height);
        context?.scaleBy(x: 1.0, y: -1.0);
        context?.draw(image.cgImage!, in: CGRect(x:0, y:0, width:image.size.width, height:image.size.height), byTiling: false);
        context?.clip(to: [cropRect]);
        
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return croppedImage!;
    }
    
    func boundingBox(forRegionOfInterest: CGRect, withinImageBounds bounds: CGRect) -> CGRect {
        
        let imageWidth  = bounds.width
        let imageHeight = bounds.height
        
        // Begin with input rect.
        var rect = forRegionOfInterest
        
        // Reposition origin.
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.origin.x
        rect.origin.y = rect.origin.y * imageHeight + bounds.origin.y
        
        // Rescale normalized coordinates.
        rect.size.width  *= imageWidth
        rect.size.height *= imageHeight
        
        return rect
    }
    
    func resizeImage(image: UIImage) -> UIImage {
        let size = image.size
        
        let widthRatio  = 28 / size.width
        let heightRatio = 28 / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func drawInSquare(image: UIImage) -> UIImage {
        let side = max(image.size.width, image.size.height)
        let size = CGSize(width: side, height: side)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.black.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: side, height: side))
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let image = context?.makeImage()
        UIGraphicsEndImageContext()
        return UIImage(cgImage: image!)
    }
    
}

extension UIImage { // mover a otra clase
    convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }
    
    func cropped(boundingBox: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: boundingBox) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    func buffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_OneComponent8, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    
}

