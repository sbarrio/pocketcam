//
//  ViewController.swift
//  pocketcam
//
//  Created by Sergio Barrio Slocker on 27/2/16.
//  Copyright © 2016 Sergio Barrio Slocker. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var cameraView: CameraView!
    var currentCamera: AVCaptureDevice.Position = AVCaptureDevice.Position.back
    var currentPalette:Int = Constants.GB_YELLOW_PALETTE
    
    var takePictureButton: UIButton?
    var cancelButton: UIButton?
    var albumButton: UIButton?
    var paletteButton: UIButton?
    var toggleCameraButton: UIButton?
    
    var audioPlayer:AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        
        let backgroundImageView:UIImageView = UIImageView(image:UIImage(named:"background"))
        backgroundImageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        backgroundImageView.contentMode = UIView.ContentMode.scaleToFill
        backgroundImageView.layer.magnificationFilter = CALayerContentsFilter.nearest
        backgroundImageView.center = self.view.center
        self.view.addSubview(backgroundImageView)
        
        //Positions
        var cameraY: CGFloat = 60
        var takePictureY: CGFloat = 265
        var albumX: CGFloat = 160
        var albumY: CGFloat = 310
        var paletteX: CGFloat = -36
        var paletteY: CGFloat = 310
        var toggleX: CGFloat = -22
        var toggleY: CGFloat = 280
        
        print(self.view.frame.height)
        
        switch(self.view.frame.height){
            case 568 :
                cameraY = 90
                takePictureY = 305
                albumX = 160
                albumY = 350
                paletteX = -36
                paletteY = 352
                toggleX = -22
                toggleY = 280
                break
            case 667 :
                cameraY = 130
                takePictureY = 340
                albumX = 180
                albumY = 400
                paletteX = -56
                paletteY = 400
                toggleX = -42
                toggleY = 310
                break
            case 736 :
                cameraY = 160
                takePictureY = 370
                albumX = 190
                albumY = 450
                paletteX = -65
                paletteY = 450
                toggleX = -50
                toggleY = 330
                break
            case 812 :
                cameraY = 180
                takePictureY = 400
                albumX = 175
                albumY = 480
                paletteX = -55
                paletteY = 480
                toggleX = -40
                toggleY = 360
                break
            case 844 :
                cameraY = 190
                takePictureY = 410
                albumX = 175
                albumY = 490
                paletteX = -55
                paletteY = 490
                toggleX = -40
                toggleY = 370
                break
            case 896 :
                cameraY = 200
                takePictureY = 440
                albumX = 190
                albumY = 520
                paletteX = -65
                paletteY = 520
                toggleX = -50
                toggleY = 400
                break
            case 926 :
                cameraY = 220
                takePictureY = 460
                albumX = 190
                albumY = 540
                paletteX = -65
                paletteY = 540
                toggleX = -50
                toggleY = 420
                break
            default:
                cameraY = 190
                takePictureY = 410
                albumX = 175
                albumY = 490
                paletteX = -55
                paletteY = 490
                toggleX = -40
                toggleY = 370
                break
        }
                    
        cameraView = CameraView(frame: CGRect(x: 0,y: 0,width: Constants.PREVIEW_WIDTH,height: Constants.PREVIEW_WIDTH))
        cameraView.center = self.view.center
        cameraView.frame.origin.y = cameraY
        self.view .addSubview(cameraView)
        
        //BUTTONS
        
        //Take picture
        takePictureButton = UIButton(frame: CGRect(x: 0,y: 0,width: 100,height: 100))
        takePictureButton!.setImage(UIImage(named:"button"), for: UIControl.State())
        takePictureButton!.center = self.view.center;
        takePictureButton!.frame.origin.y = cameraView.frame.origin.y + takePictureY
        self.view.addSubview(takePictureButton!)
        
        takePictureButton!.addTarget(self, action:#selector(ViewController.takePictureButtonPressed), for:UIControl.Event.touchUpInside)
        
        //Go to album
        albumButton = UIButton(frame: CGRect(x: 0,y: 0,width: 75,height: 75))
        albumButton!.setImage(UIImage(named:"album"), for: UIControl.State())
        albumButton!.center = self.view.center;
        albumButton!.frame.origin.x = cameraView.frame.origin.x + albumX
        albumButton!.frame.origin.y = cameraView.frame.origin.y + albumY
        self.view.addSubview(albumButton!)
        
        albumButton!.addTarget(self, action:#selector(ViewController.albumButtonPressed), for:UIControl.Event.touchUpInside)
        
        // Change palette
        paletteButton = UIButton(frame: CGRect(x: 0, y:0, width: 75, height: 75))
        paletteButton!.setImage(UIImage(named:"palette"), for: UIControl.State())
        paletteButton!.frame.origin.x = cameraView.frame.origin.x + paletteX
        paletteButton!.frame.origin.y = cameraView.frame.origin.y + paletteY
        self.view.addSubview(paletteButton!)
        
        paletteButton!.addTarget(self, action: #selector(ViewController.paletteButtonPressed), for: UIControl.Event.touchUpInside)

        // Toggle camera
        toggleCameraButton = UIButton(frame: CGRect(x: 0, y:0, width: 50, height: 50))
        toggleCameraButton!.setImage(UIImage(named:"toggleCamera"), for: UIControl.State())
        toggleCameraButton!.frame.origin.x = cameraView.frame.origin.x + toggleX
        toggleCameraButton!.frame.origin.y = cameraView.frame.origin.y + toggleY
        self.view.addSubview(toggleCameraButton!)
        
        toggleCameraButton!.addTarget(self, action: #selector(ViewController.toggleCameraPressed), for: UIControl.Event.touchUpInside)
        
        //Cancel
        cancelButton = UIButton(frame: CGRect(x: 0,y: 0,width: 75,height: 75))
        cancelButton!.setImage(UIImage(named:"cancel"), for: UIControl.State())
        cancelButton!.center = self.view.center;
        cancelButton!.frame.origin.x = cameraView.frame.origin.x + albumX
        cancelButton!.frame.origin.y = cameraView.frame.origin.y + albumY
        
        cancelButton!.isHidden = true
        self.view.addSubview(cancelButton!)
        
        cancelButton!.addTarget(self, action:#selector(ViewController.cancelButtonPressed), for:UIControl.Event.touchUpInside)
        
        //Sound
        let shutterSound = URL(fileURLWithPath: Bundle.main.path(forResource: "shutter", ofType: "wav")!)
        audioPlayer = AVAudioPlayer()
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: shutterSound)
            audioPlayer.prepareToPlay()
        }catch{
            print("Cannot init sound!")
        }
    }
    
    @objc func takePictureButtonPressed() {
        if(self.cameraView.cameraReady) {
            print("Taking picture!")
            self.audioPlayer.play();
            self.cameraView.takePicture()
        } else {
            print("Cant take picture yet, camera is not ready!")
        }
    }
    
    @objc func albumButtonPressed() {
        print("Opening album!")
        if(self.cameraView.cameraReady
            && UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) ){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @objc func paletteButtonPressed() {
        
        if(self.cameraView.cameraReady) {
            self.currentPalette += 1
            if (self.currentPalette > Constants.GB_BLACKWHITE_PALETTE) {
                self.currentPalette = Constants.GB_YELLOW_PALETTE
            }
            
            print("Switch palette to " + String(self.currentPalette))
            self.cameraView.changePaletteAndUpdate(newPalette: self.currentPalette)
        } else {
            print("Cant switch palette yet, camera is not ready!")
        }
    }
    
    @objc func cancelButtonPressed() {
        cancelButton!.isHidden = true
        albumButton!.isHidden = false
        toggleCameraButton!.isHidden = false
        takePictureButton!.setImage(UIImage(named:"button"), for: UIControl.State())
        
        self.cameraView.cancelImageEdit()
        
    }
    
    @objc func toggleCameraPressed() {
        
        if(self.cameraView.cameraReady) {
            if (currentCamera == AVCaptureDevice.Position.front) {
                print("Changed to back camera")
                currentCamera = AVCaptureDevice.Position.back
            } else {
                print("Changed to front camera")
                currentCamera = AVCaptureDevice.Position.front
            }
                    
            self.cameraView.resetCamera(selectedCamera: currentCamera, palette: self.currentPalette)
        } else {
            print("Cant toggle camera yet, camera is not ready!")
        }
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [AnyHashable: Any]!) {
        
        self.dismiss(animated: true, completion: nil);
        
        if (image != nil) {
            self.cameraView.setImageToEdit(image)
            cancelButton?.isHidden = false
            albumButton?.isHidden = true
            toggleCameraButton?.isHidden = true
            takePictureButton!.setImage(UIImage(named:"button2"), for: UIControl.State())
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}

