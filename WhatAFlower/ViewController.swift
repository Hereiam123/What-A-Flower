//
//  ViewController.swift
//  WhatAFlower
//
//  Created by Brian De Maio on 1/26/19.
//  Copyright © 2019 Brian De Maio. All rights reserved.
//

import UIKit
import Vision
import CoreML

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
        
            guard let convertedCiImage = CIImage(image: userPickedImage) else{fatalError("Cannot convert to CIImage")}
            detect(image: convertedCiImage)
            imageView.image = userPickedImage
        }
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {fatalError("Cannot create VNModel for FlowerClassifier model")}
        
        let request = VNCoreMLRequest(model: model){(request,error) in
            let classification = request.results?.first as? VNClassificationObservation
                        
            self.navigationItem.title = classification?.identifier.capitalized
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        }
        catch{
            print(error)
        }
    }
}
