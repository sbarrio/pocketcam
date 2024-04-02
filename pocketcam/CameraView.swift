//
//  CameraView.swift
//  pocketcam
//
//  Created by Sergio Barrio Slocker on 27/2/16.
//  Copyright © 2016 Sergio Barrio Slocker. All rights reserved.
//

import Foundation


import UIKit
import AVFoundation
import ImageIO

class CameraView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    // AVFoundation properties
    let captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice!
    var captureDeviceFormat: AVCaptureDevice.Format?
    let videoOutput = AVCaptureVideoDataOutput()
    var cameraLayer: AVCaptureVideoPreviewLayer?
    var deviceInput: AVCaptureDeviceInput!
    
    //UI
    var imageOK:UIImage!
    var imageLoading:UIImage!
    var imageError:UIImage!
    var messageShowing:Bool = false
    var audioPlayer:AVAudioPlayer!
    
    //Control
    var cameraReady:Bool = false
    var previewImageView:UIImageView?
    var processedImageRealSize:UIImage?
    var outImageToProcess:UIImage?
    
    var cubeData:Data?
    var cubeSize:Int?
    
    // Color palette
    var current_dmg1: CIColor?
    var current_dmg2: CIColor?
    var current_dmg3: CIColor?
    var current_dmg4: CIColor?
    
    // Palettes
    
    //Game boy palette (yellow)
    let dmg1_GBY = CIColor(red: 33 / 255.0, green: 32 / 255.0, blue: 16 / 255.0)
    let dmg2_GBY = CIColor(red: 107 / 255.0, green: 105 / 255.0, blue: 49 / 255.0)
    let dmg3_GBY = CIColor(red: 192 / 255.0, green: 184 / 255.0, blue: 77 / 255.0)
    let dmg4_GBY = CIColor(red: 255 / 255.0, green: 247 / 255.0, blue: 123 / 255.0)
            
    // Game boy palette (original green)
    let dmg1_GB = CIColor(red: 15 / 255.0, green: 56 / 255.0, blue: 15 / 255.0)
    let dmg2_GB = CIColor(red: 48 / 255.0, green: 98 / 255.0, blue: 48 / 255.0)
    let dmg3_GB = CIColor(red: 140 / 255.0, green: 173 / 255.0, blue: 15 / 255.0)
    let dmg4_GB = CIColor(red: 156 / 255.0, green: 189 / 255.0, blue: 15 / 255.0)
    
    // Game boy palette (pocket)
    let dmg1_GBP = CIColor(red: 108 / 255.0, green: 108 / 255.0, blue: 78 / 255.0)
    let dmg2_GBP = CIColor(red: 142 / 255.0, green: 139 / 255.0, blue: 97 / 255.0)
    let dmg3_GBP = CIColor(red: 192 / 255.0, green: 193 / 255.0, blue: 163 / 255.0)
    let dmg4_GBP = CIColor(red: 227 / 255.0, green: 230 / 255.0, blue: 201 / 255.0)
    
    // Game boy palette (b/w)
    let dmg1_GBBW = CIColor(red: 56 / 255.0, green: 56 / 255.0, blue: 56 / 255.0)
    let dmg2_GBBW = CIColor(red: 117 / 255.0, green: 117 / 255.0, blue: 117 / 255.0)
    let dmg3_GBBW = CIColor(red: 186 / 255.0, green: 186 / 255.0, blue: 186 / 255.0)
    let dmg4_GBBW = CIColor(red: 239 / 255.0, green: 239 / 255.0, blue: 239 / 255.0)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initCamera(selectedCamera: AVCaptureDevice.Position.back, palette: Constants.GB_YELLOW_PALETTE)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initCamera(selectedCamera: AVCaptureDevice.Position.back, palette: Constants.GB_YELLOW_PALETTE)
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setShouldAntialias(false)
        context?.setShouldSmoothFonts(false)
    }
    
    func resetCamera(selectedCamera: AVCaptureDevice.Position, palette: Int) {
        self.cameraReady = false;
        self.captureSession.stopRunning()
        self.captureSession.removeInput(deviceInput)
        initCamera(selectedCamera: selectedCamera, palette: palette)
    }
    
    func initCamera(selectedCamera: AVCaptureDevice.Position, palette: Int) {
        self.captureSession.beginConfiguration()
        
        //UI
        self.imageOK = UIImage(named: "ok")
        self.imageLoading = UIImage(named:"loading")
        self.imageError = UIImage(named: "error")
        
        //Sound
        let photoSound = URL(fileURLWithPath: Bundle.main.path(forResource: "photoSaved", ofType: "wav")!)
        self.audioPlayer = AVAudioPlayer()
        do{
            self.audioPlayer = try AVAudioPlayer(contentsOf: photoSound)
            self.audioPlayer.prepareToPlay()
        }catch{
            print("Cannot init sound!")
        }
        
        //configure preview image view
        previewImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: Constants.PREVIEW_WIDTH, height: Constants.PREVIEW_WIDTH))
        previewImageView?.backgroundColor = UIColor.black
        previewImageView?.contentMode = UIView.ContentMode.scaleToFill
        previewImageView?.layer.magnificationFilter = CALayerContentsFilter.nearest
        previewImageView?.image = imageLoading
        self.addSubview(previewImageView!)
        
        // get the back camera
        if let device = cameraDeviceForPosition(selectedCamera) {
            
            self.captureDevice = device
            self.captureDeviceFormat = device.activeFormat
            
            let error:NSErrorPointer? = nil
            
            do {
                try captureDevice!.lockForConfiguration()
            } catch let error1 as NSError {
                error??.pointee = error1
            }
            
            let focusMode = AVCaptureDevice.FocusMode.autoFocus
            if self.captureDevice.isFocusModeSupported(focusMode) {
                self.captureDevice!.focusMode = focusMode
            }
            
            self.captureDevice!.unlockForConfiguration()
            
            do {
                self.deviceInput = try AVCaptureDeviceInput(device: self.captureDevice)
            } catch _ as NSError {
//                error.memory = error1
                self.deviceInput = nil
                self.previewImageView!.image = imageError
                return
            }
            if(error == nil) {
                self.captureSession.addInput(self.deviceInput)
            }
            
            self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
            if self.captureSession.canAddOutput(self.videoOutput)
            {
                self.captureSession.addOutput(self.videoOutput)
            }
            
            // use the high resolution photo preset
            self.captureSession.sessionPreset = AVCaptureSession.Preset.cif352x288
            
            // setup camera preview (mandatory even if we dont use the cameraLayer)
            self.cameraLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            
            // commit and start capturing
            DispatchQueue.main.async {
                self.captureSession.commitConfiguration()
                self.captureSession.startRunning()
            }
            
            // Initial palette
            self.changePalette(newPalette: palette)
            
            //Generate Cube
            self.cubeData = createCubeData(dmg1: current_dmg1!, dmg2: current_dmg2!, dmg3: current_dmg3!, dmg4: current_dmg4!)
            
            //start capture
            self.captureSession.commitConfiguration()
            
            self.cameraReady = true
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        
        //Do nothing if message is on screen
        if (self.messageShowing){
            return
        }
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        var cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
        
        //if outisde image we process it instead of feed
        if ((self.outImageToProcess) != nil){
            cameraImage = CIImage(image: self.outImageToProcess!)!
        }
        
        //Filter creation and config
        
//PIXELIZE
        let filterPixel = CIFilter(name: "CIPixellate")
        filterPixel!.setValue(cameraImage, forKey: kCIInputImageKey)
        filterPixel!.setValue(CIVector(x: Constants.CAMERA_WIDTH/2, y: Constants.CAMERA_WIDTH/2), forKey: kCIInputCenterKey)
        filterPixel!.setValue(2.0, forKey: kCIInputScaleKey)

//GRAY SCALE
        let filterMono = CIFilter(name: "CIPhotoEffectMono")
        filterMono!.setValue(filterPixel!.value(forKey: kCIOutputImageKey) as! CIImage?, forKey: kCIInputImageKey)
        
//DITHER
        let filterDither = CIFilter(name : "CIDotScreen")
        
        filterDither!.setValue(filterMono!.value(forKey: kCIOutputImageKey) as! CIImage?, forKey: kCIInputImageKey)
        filterDither!.setValue(CIVector(x: Constants.CAMERA_WIDTH/2, y: Constants.CAMERA_WIDTH/2), forKey: kCIInputCenterKey)
        filterDither!.setValue(0.0, forKey: kCIInputAngleKey)
        filterDither!.setValue(3.0, forKey: kCIInputWidthKey)  //3
        filterDither!.setValue(0.2, forKey: kCIInputSharpnessKey)  //0.1
        
//SET GAME BOY COLOR TONES
        
        // Allocate and populate color cube table
    
        let filterCube = CIFilter(name: "CIColorCube")
        filterCube!.setValue(filterDither!.value(forKey: kCIOutputImageKey) as! CIImage?, forKey: kCIInputImageKey)
        filterCube!.setValue(self.cubeSize, forKey: "inputCubeDimension")
        filterCube!.setValue(self.cubeData, forKey: "inputCubeData")
        
        //Final output -> UIImage preview
        let ctx = CIContext(options:nil)
        let cgImage = ctx.createCGImage(filterCube!.outputImage!, from:filterCube!.outputImage!.extent)
        
        var orientation = UIImage.Orientation.right
        if (self.outImageToProcess != nil){
            orientation = UIImage.Orientation.up
        }
        
        var out = UIImage(cgImage: cgImage!, scale: 1.0, orientation: orientation)
        
        //Crop image to desired dimensions
        if (out.cgImage != nil){
            out = self.squareCropImageToSideLength(out, sideLength: Constants.CAMERA_WIDTH)
        }
        
        //assign generated image to previewImageView
        DispatchQueue.main.async
        {
            self.processedImageRealSize = out
            self.previewImageView?.image = out
        }
    }
    
    func takePicture(){
        if (!self.cameraReady || self.messageShowing){
            return
        }
        
        let image = processedImageRealSize
        
        self.messageShowing = true
        self.previewImageView!.image = imageLoading
        
        DispatchQueue.main.async {
            UIImageWriteToSavedPhotosAlbum(image!, self, #selector(CameraView.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    func setImageToEdit(_ image: UIImage){
        self.outImageToProcess = image
    }
    
    func cancelImageEdit(){
        self.outImageToProcess = nil
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
        
        guard error == nil else {
            print(error!)
            return
        }
        //Image saved successfully
        print("image saved OK!")
        
        self.audioPlayer.play()
        
        self.previewImageView!.image = self.imageOK
        self.messageShowing = true
        
        //starts timer message
        Timer.scheduledTimer(timeInterval: Constants.TIME_MESSAGE, target: self, selector: #selector(CameraView.update), userInfo: nil, repeats: true)
    }
    
    @objc func update(){
        self.messageShowing = false
    }
    
    
    
    func resizeImage(_ image: UIImage, newWidth: CGFloat, newHeight: CGFloat) -> UIImage {
        
        let newHeight = newHeight
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func croppIngimage(_ imageToCrop:UIImage, toRect rect:CGRect) -> UIImage{
        
        let imageRef:CGImage = imageToCrop.cgImage!.cropping(to: rect)!
        let cropped:UIImage = UIImage(cgImage:imageRef)
        return cropped
    }
    
    func getImageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    fileprivate func squareCropImageToSideLength(_ sourceImage: UIImage,
                                                 sideLength: CGFloat) -> UIImage {
        // input size comes from image
        let inputSize: CGSize = sourceImage.size
        
        // round up side length to avoid fractional output size
        let sideLength: CGFloat = ceil(sideLength)
        
        // output size has sideLength for both dimensions
        let outputSize: CGSize = CGSize(width: sideLength, height: sideLength)
        
        // calculate scale so that smaller dimension fits sideLength
        let scale: CGFloat = max(sideLength / inputSize.width,
                                 sideLength / inputSize.height)
        
        // scaling the image with this scale results in this output size
        let scaledInputSize: CGSize = CGSize(width: inputSize.width * scale,
                                                 height: inputSize.height * scale)
        
        // determine point in center of "canvas"
        let center: CGPoint = CGPoint(x: outputSize.width/2.0,
                                          y: outputSize.height/2.0)
        
        // calculate drawing rect relative to output Size
        let outputRect: CGRect = CGRect(x: center.x - scaledInputSize.width/2.0,
                                            y: center.y - scaledInputSize.height/2.0,
                                            width: scaledInputSize.width,
                                            height: scaledInputSize.height)
        
        // begin a new bitmap context, scale 0 takes display scale
        UIGraphicsBeginImageContextWithOptions(outputSize, true, 0)
        
        // optional: set the interpolation quality.
        // For this you need to grab the underlying CGContext
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        ctx.interpolationQuality = CGInterpolationQuality.high
        
        // draw the source image into the calculated rect
        sourceImage.draw(in: outputRect)
        
        // create new image from bitmap context
        let outImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        // clean up
        UIGraphicsEndImageContext()
        
        // pass back new image
        return outImage
    }
    
    
    func setFocusWithLensPosition(_ pos: CFloat) {
        let error: NSErrorPointer? = nil
        do {
            try self.captureDevice!.lockForConfiguration()
        } catch let error1 as NSError {
            error??.pointee = error1
        }
        self.captureDevice!.setFocusModeLocked(lensPosition: pos, completionHandler: nil)
        self.captureDevice!.unlockForConfiguration()
    }
    
    // return the camera device for a position
    func cameraDeviceForPosition(_ position:AVCaptureDevice.Position) -> AVCaptureDevice?
    {

        for device:Any in AVCaptureDevice.devices() {
            if ((device as! AVCaptureDevice).position == position) {
                return device as? AVCaptureDevice;
            }
        }

        return nil
    }

    
    //CIColorCube
    func createCubeData(dmg1: CIColor, dmg2: CIColor, dmg3: CIColor, dmg4: CIColor) -> Data{
        
        let size = 64
        var cubeData = [Float](repeating: 0, count: size * size * size * 4)
        let rgb: [Float] = [0, 0, 0]
        var newRGB: (r : Float, g : Float, b : Float)
        var offset = 0
        
        for _ in 0 ..< size {
            for _ in 0 ..< size {
                for x in 0 ..< size {
                    
                    if (x >= 0 && x < 16){
                        newRGB.r = Float(dmg1.red)
                        newRGB.g = Float(dmg1.green)
                        newRGB.b = Float(dmg1.blue)
                    }else if(x >= 16 && x < 32){
                        newRGB.r = Float(dmg2.red)
                        newRGB.g = Float(dmg2.green)
                        newRGB.b = Float(dmg2.blue)
                    }else if(x >= 32 && x < 48){
                        newRGB.r = Float(dmg3.red)
                        newRGB.g = Float(dmg3.green)
                        newRGB.b = Float(dmg3.blue)
                    }else if(x >= 48 && x < 64){
                        newRGB.r = Float(dmg4.red)
                        newRGB.g = Float(dmg4.green)
                        newRGB.b = Float(dmg4.blue)
                    }else{
                        newRGB.r = rgb[0]
                        newRGB.g = rgb[1]
                        newRGB.b = rgb[2]
                    }
                    
                    cubeData[offset]   = newRGB.r
                    cubeData[offset+1] = newRGB.g
                    cubeData[offset+2] = newRGB.b
                    cubeData[offset+3] = 1.0
                    offset += 4
                }
            }
        }
                
        let buffer = cubeData.withUnsafeBufferPointer { Data(buffer: $0) }
        let data = buffer as Data
        
        self.cubeSize = size
        
        return data
    }
    
    func changePalette(newPalette: Int) {
        
        switch(newPalette) {
            case Constants.GB_YELLOW_PALETTE:
                self.current_dmg1 = dmg1_GBY
                self.current_dmg2 = dmg2_GBY
                self.current_dmg3 = dmg3_GBY
                self.current_dmg4 = dmg4_GBY
                break;
            case Constants.GB_GREEN_PALETTE:
                self.current_dmg1 = dmg1_GB
                self.current_dmg2 = dmg2_GB
                self.current_dmg3 = dmg3_GB
                self.current_dmg4 = dmg4_GB
                break;
            case Constants.GB_POCKET_PALETTE:
                self.current_dmg1 = dmg1_GBP
                self.current_dmg2 = dmg2_GBP
                self.current_dmg3 = dmg3_GBP
                self.current_dmg4 = dmg4_GBP
                break;
            case Constants.GB_BLACKWHITE_PALETTE:
                self.current_dmg1 = dmg1_GBBW
                self.current_dmg2 = dmg2_GBBW
                self.current_dmg3 = dmg3_GBBW
                self.current_dmg4 = dmg4_GBBW
                break;
            default: break
        }
    
    }
    
    func changePaletteAndUpdate(newPalette: Int) {
        
        self.changePalette(newPalette: newPalette)
        self.cubeData = createCubeData(dmg1: current_dmg1!, dmg2: current_dmg2!, dmg3: current_dmg3!, dmg4: current_dmg4!)
        
    }
}
