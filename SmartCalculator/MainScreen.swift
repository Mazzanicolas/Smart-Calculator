//
//  ViewController.swift
//  SmartCalculator
//
//  Created by SP19 on 30/5/18.
//  Copyright © 2018 UCU. All rights reserved.
//

import UIKit
import Vision
import CoreML

class ViewController: UIViewController {

    @IBOutlet weak var foundImage: UIImageView!
    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var predictionImage: UIImageView!
    var inputImageArray: [UIImage] = []
    var path       = UIBezierPath()
    var startPoint = CGPoint()
    var touchPoint = CGPoint()
    var image : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView.clipsToBounds          = true
        canvasView.isMultipleTouchEnabled = false
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
        strokeLayer.strokeColor = UIColor.black.cgColor
        strokeLayer.lineWidth   = 10
        strokeLayer.path        = path.cgPath
        canvasView.layer.addSublayer(strokeLayer)
        canvasView.setNeedsDisplay()
    }
    
    @IBAction func clearScreen(_ sender: Any) {
        path.removeAllPoints()  
        canvasView.layer.sublayers?.forEach({ $0.removeFromSuperlayer() })
        canvasView.setNeedsDisplay()
    }
    
    @IBAction func canvasToImage(_ sender: Any) {
        image = UIImage(view: canvasView)
        imagePreview.image = image
        findText(image: image!)
        self.foundImage.image = self.inputImageArray[0]
    
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
                        self.inputImageArray.append(cropped)
                        
                        let boxY = (self.canvasView.frame.midY -  rectBox.minY) * 2  - rectBox.height
                        
                       
                        let coloredView = UIView()
                        
                        coloredView.backgroundColor = .green
                        
                      /*  coloredView.frame = CGRect(x: rectBox.maxX - rectBox.width,
                                                   y: self.canvasView.frame.minY + rectBox.minY,
                                                   width: rectBox.width,
                                                   height: rectBox.height)
 */
                        coloredView.frame = CGRect(x: rectBox.minX,
                                                  y: self.canvasView.frame.minY + rectBox.height - rectBox.minY,
                                                  width: rectBox.width,
                                                  height: rectBox.height
                                                  )
                        
                        self.view.addSubview(coloredView)
                        break
                        
                        
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
    
}

extension UIImage {
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
    
    
}

