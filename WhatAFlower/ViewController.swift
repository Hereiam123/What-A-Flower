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
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    @IBOutlet weak var flowerDescriptionLabel: UILabel!
    
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
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {fatalError("Cannot create VNModel for FlowerClassifier model")}
        
        let request = VNCoreMLRequest(model: model){(request,error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {fatalError("Could not get classification from VNCoreMLRequest")}
                        
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        }
        catch{
            print(error)
        }
    }
    
    func requestInfo(flowerName : String){
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize":"500"
            ]
        Alamofire.request(wikipediaURl, method: .get , parameters: parameters).responseJSON { (response) in
            if(response.result.isSuccess){
                print(response)
                let flowerJson : JSON = JSON(response.result.value!)
                let pageId = flowerJson["query"]["pageids"][0].stringValue
                let flowerDecription = flowerJson["query"]["pages"][pageId]["extract"].stringValue
                let flowerImage = flowerJson["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string:flowerImage))
                self.flowerDescriptionLabel.text = flowerDecription
            }
        }
    }
}
