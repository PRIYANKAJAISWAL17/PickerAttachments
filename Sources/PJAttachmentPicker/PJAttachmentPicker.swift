//
//  AttachmentClass.swift
//
//  Created by Priyanka Jaiswal on 27/07/23.
//

import Foundation
import UIKit
import MobileCoreServices
import AVFoundation
import Photos

public class PJAttachmentPickerHandler: NSObject {
    
    fileprivate var currentVC: UIViewController?
    public var shared = PJAttachmentPickerHandler()
    
    //MARK: - Internal Properties
    public var imagePickedBlock: ((UIImage, String, String) -> Void)?
    public var videoPickedBlock: ((NSURL) -> Void)?
    public var filePickedBlock: ((URL) -> Void)?
    
    enum AttachmentType: String {
        case camera, video, photoLibrary
    }
    
    //MARK: - Constants
    // This is used to show the alert or msg to user.
    struct Constants {
        static let actionFileTypeHeading = "Add a File"
        static let actionFileTypeDescription = "Choose a filetype to add..."
        static let camera = "Camera"
        static let phoneLibrary = "Gallery"
        static let video = "Video"
        static let file = "File"
        
        static let alertForPhotoLibraryMessage = "App does not have access to your photos. To enable access, tap settings and turn on Photo Library Access."
        
        static let alertForCameraAccessMessage = "App does not have access to your camera. To enable access, tap settings and turn on Camera."
        
        static let alertForVideoLibraryMessage = "App does not have access to your video. To enable access, tap settings and turn on Video Library Access."
        
        static let settingsBtnTitle = "Settings"
        static let cancelBtnTitle = "Cancel"
    }
    
    //MARK: Constant String
    struct KString {
        static let strAppHeader              = "Attachment !!"
        static let ok                        = "OK"
        static let cancel                    = "Cancel"
    }
    
    
    //MARK: - showAttachmentActionSheet
    /// This function is used to show the attachment sheet for image, video, photo and file.
   public func showAttachmentActionSheet(vc: UIViewController) {
            currentVC = vc
            let actionSheet = UIAlertController(title: Constants.actionFileTypeHeading, message: Constants.actionFileTypeDescription, preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: Constants.camera, style: .default, handler: { (action) -> Void in
                self.authorisationStatus(attachmentTypeEnum: .camera, vc: self.currentVC!)
            }))
            
            actionSheet.addAction(UIAlertAction(title: Constants.phoneLibrary, style: .default, handler: { (action) -> Void in
                self.authorisationStatus(attachmentTypeEnum: .photoLibrary, vc: self.currentVC!)
            }))
            
//            actionSheet.addAction(UIAlertAction(title: Constants.video, style: .default, handler: { (action) -> Void in
//                self.authorisationStatus(attachmentTypeEnum: .video, vc: self.currentVC!)
//
//            }))
            
            actionSheet.addAction(UIAlertAction(title: Constants.file, style: .default, handler: { (action) -> Void in
                self.documentPicker()
            }))
            
            actionSheet.addAction(UIAlertAction(title: Constants.cancelBtnTitle, style: .cancel, handler: nil))
            
            vc.present(actionSheet, animated: true, completion: nil)
        }

    
    //MARK: - Authorisation Status
    /// This is used to check the authorisation status whether user gives access to import the image, photo library, video. if the user gives access, then we can import the data safely if not show them alert to access from settings.
    func authorisationStatus(attachmentTypeEnum: AttachmentType, vc: UIViewController){
            currentVC = vc
            if attachmentTypeEnum ==  AttachmentType.camera{
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                switch status{
                case .authorized: // The user has previously granted access to the camera.
                    DispatchQueue.main.async {
                        self.openCamera()
                    }
                    
                case .notDetermined: // The user has not yet been asked for camera access.
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        if granted {
                            DispatchQueue.main.async {
                                self.openCamera()
                            }
                        }
                    }
                //denied - The user has previously denied access.
                //restricted - The user can't grant access due to restrictions.
                case .denied, .restricted:
                    DispatchQueue.main.async {
                        self.addAlertForSettings(attachmentTypeEnum)
                        return
                    }
                    
                default:
                    break
                }
            }else if attachmentTypeEnum == AttachmentType.photoLibrary || attachmentTypeEnum == AttachmentType.video{
                let status = PHPhotoLibrary.authorizationStatus()
                switch status{
                case .authorized:
                    if attachmentTypeEnum == AttachmentType.photoLibrary{
                        DispatchQueue.main.async {
                            self.photoLibrary()
                        }
                    }
                    
                    if attachmentTypeEnum == AttachmentType.video{
                        DispatchQueue.main.async {
                            self.videoLibrary()
                        }
                    }
                case .denied, .restricted:
                    self.addAlertForSettings(attachmentTypeEnum)
                case .notDetermined:
                    PHPhotoLibrary.requestAuthorization({ (status) in
                        if status == PHAuthorizationStatus.authorized{
                            // photo library access given
                            DispatchQueue.main.async {
                                self.photoLibrary()
                            }
                        }
                        if attachmentTypeEnum == AttachmentType.video{
                            DispatchQueue.main.async {
                                self.videoLibrary()
                            }
                        }
                    })
                default:
                    break
                }
            }
        }
    
    
    
    //MARK: - CAMERA PICKER
    ///This function is used to open camera from the iphone
   public func openCamera(){
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                let myPickerController = UIImagePickerController()
                myPickerController.delegate = self
                myPickerController.sourceType = .camera
                currentVC?.present(myPickerController, animated: true, completion: nil)
            }
        }

    //MARK: - PHOTO PICKER
    ///This function is used to open gallery photos from the iphone
   public func photoLibrary(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .photoLibrary
            currentVC?.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    //MARK: - VIDEO PICKER
    ///This function is used to open gallery video from the iphone
   public func videoLibrary(){
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                let myPickerController = UIImagePickerController()
                myPickerController.delegate = self
                myPickerController.sourceType = .photoLibrary
                myPickerController.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String]
               
                currentVC?.present(myPickerController, animated: true, completion: nil)
            }
        }
    
    //MARK: - FILE PICKER
    ///Handle the access files which we want to use for documents.
    public func documentPicker(){
        let importMenu = UIDocumentPickerViewController(documentTypes: ["public.image","public.text", "public.composite-content", "com.pkware.zip-archive"], in: .import)
        
//        let importMenu = UIDocumentPickerViewController(documentTypes: ["com.apple.iwork.pages.pages", "com.apple.iwork.numbers.numbers", "com.apple.iwork.keynote.key","public.image", "com.apple.application", "public.item","public.data", "public.content", "public.audiovisual-content", "public.movie", "public.audiovisual-content", "public.video", "public.audio", "public.text", "public.data", "public.zip-archive", "com.pkware.zip-archive", "public.composite-content", "public.text"], in: .import)
        
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        currentVC?.present(importMenu, animated: true, completion: nil)
    }
    
        
    //MARK: - SETTINGS ALERT
    /// Alert to tell user not having access and option to provide access.
    func addAlertForSettings(_ attachmentTypeEnum: AttachmentType){
        var alertTitle: String = ""
        if attachmentTypeEnum == AttachmentType.camera{
            alertTitle = Constants.alertForCameraAccessMessage
        }
        if attachmentTypeEnum == AttachmentType.photoLibrary{
            alertTitle = Constants.alertForPhotoLibraryMessage
        }
        if attachmentTypeEnum == AttachmentType.video{
            alertTitle = Constants.alertForVideoLibraryMessage
        }
        
        let cameraUnavailableAlertController = UIAlertController (title: alertTitle , message: nil, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: Constants.settingsBtnTitle, style: .destructive) { (_) -> Void in
            let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: Constants.cancelBtnTitle, style: .default, handler: nil)
        cameraUnavailableAlertController .addAction(cancelAction)
        cameraUnavailableAlertController .addAction(settingsAction)
        
        currentVC?.present(cameraUnavailableAlertController , animated: true, completion: nil)
    }
    
    
    ///alertMessase function for showing alert to user.
     func alertMessase(strOk: String? = KString.ok, withTitle : String? = KString.strAppHeader, message : String?, cancelAction : (()->())? = nil , okAction : @escaping (()->())) {
        
        let alertMessageController = UIAlertController(title: withTitle, message: message, preferredStyle: .alert)
        let cancelButton = UIAlertAction(title:KString.cancel, style: .cancel) { (cancel) in
            cancelAction?()
        }
        let okButton = UIAlertAction(title: strOk, style: .default) { (ok) in
            okAction()
        }
        if cancelAction != nil {
            alertMessageController.addAction(cancelButton)
        }
        alertMessageController.addAction(okButton)
        let appWindow = UIApplication.shared.delegate?.window??.rootViewController
        appWindow?.present(alertMessageController, animated: true, completion: nil)
    }
}

//MARK: - IMAGE PICKER DELEGATE
/// This is responsible for image picker interface to access image, video and then responsible for canceling the picker
extension PJAttachmentPickerHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        currentVC?.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        guard info[UIImagePickerController.InfoKey.mediaType] != nil else { return }
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString
       
      

        switch mediaType {
        case kUTTypeImage:
//            if let asset = info[UIImagePickerController.InfoKey.phAsset.rawValue] as? PHAsset {
//             let assetResources = PHAssetResource.assetResources(for: asset)
//             print(assetResources.first!.originalFilename)
//           }
          
            guard let fileUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
                
                
                if let image = info[.editedImage] as? UIImage {
                    self.imagePickedBlock?(image,"CameraPicture", "png")
                    currentVC?.dismiss(animated: true, completion: nil)
                }else{
                    if let image = info[.originalImage] as? UIImage {
                        
                        self.imagePickedBlock?(image,"CameraPicture", "png")
                        
                        currentVC?.dismiss(animated: true, completion: nil)
                    }else{
                        alertMessase(message: "KAlertMsg.swr", okAction: {})
                    }
                }
                
                return
                
            }
                print(fileUrl.lastPathComponent) // get file Name
                print(fileUrl.pathExtension)     // get file extension
                    if let image = info[.editedImage] as? UIImage {
                        if let asset = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerPHAsset")] as? PHAsset{
                                    if let fileName = asset.value(forKey: "filename") as? String{
                                    print(fileName)
                                        
                                        self.imagePickedBlock?(image,fileName, fileUrl.pathExtension)
                                    }
                                }
                        
                    }else{
                        if let image = info[.originalImage] as? UIImage {
                            if let asset = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerPHAsset")] as? PHAsset {
                                        if let fileName = asset.value(forKey: "filename") as? String{
                                        print(fileName)
                                            
                                            self.imagePickedBlock?(image,fileName, fileUrl.pathExtension)
                                        }
                            }else{
                                
                                self.imagePickedBlock?(image,fileUrl.lastPathComponent, fileUrl.pathExtension)
                            }
                          
                            
                            
                        }else{
                            alertMessase(message: "KAlertMsg.swr", okAction: {})
                        }
                    }
            break
        case kUTTypeMovie:
            if let videoUrl = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.mediaURL.rawValue)] as? NSURL{
                       print("videourl: ", videoUrl)
                       //trying compression of video
                       let data = NSData(contentsOf: videoUrl as URL)!
                       print("File size before compression: \(Double(data.length / 1048576)) mb")
                       compressWithSessionStatusFunc(videoUrl)
                   }
                   else{
                       print("Something went wrong in  video")
                   }
            break
        case kUTTypeLivePhoto:

            break
        default:
            break
        }
        currentVC?.dismiss(animated: true, completion: nil)
    }
    

    /// Video Compressing technique
    public func compressWithSessionStatusFunc(_ videoUrl: NSURL) {
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".MOV")
        compressVideo(inputURL: videoUrl as URL, outputURL: compressedURL) { (exportSession) in
            guard let session = exportSession else {
                return
            }
            
            switch session.status {
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .completed:
                guard let compressedData = NSData(contentsOf: compressedURL) else {
                    return
                }
                print("File size after compression: \(Double(compressedData.length / 1048576)) mb")
                
                DispatchQueue.main.async {
                    self.videoPickedBlock?(compressedURL as NSURL)
                }
                // 50 mb
            case .failed:
                break
            case .cancelled:
                break
            @unknown default:
                fatalError()
            }
        }
    }
    
    /// Now compression is happening with medium quality, we can change when ever it is needed
    public func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset1280x720) else {
            handler(nil)
            
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
}


//MARK: - FILE IMPORT DELEGATE
extension PJAttachmentPickerHandler: UIDocumentPickerDelegate{
    
    public func documentMenu(_ documentMenu: UIDocumentPickerViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        currentVC?.present(documentPicker, animated: true, completion: nil)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        debugPrint("url", url)
        self.filePickedBlock?(url)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
    
}

/// image Compressing technique
extension UIImage {
    public func imageByNormalizingOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        let normalizedImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage!
    }
    // MARK: - UIImage+Resize
    public func compressTo(_ expectedSizeInMb:Double) -> Data? {
        
        if imageOrientation == .up {
            
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let sizeInBytes = expectedSizeInMb * 1024 * 1024
        var needCompress:Bool = true
        var imgData:Data?
        var compressingValue:CGFloat = 1.0
        while (needCompress && compressingValue > 0.0) {
            if let data:Data = self.jpegData(compressionQuality: compressingValue) {
                
                let imageSize: Int = data.count
                let size1 = (Double(imageSize) / 1024.0)/1024.0
                print("size of image in MB: %f ", size1)
                
                
                if Double(data.count) < sizeInBytes {
                    needCompress = false
                    imgData = data
                } else {
                    compressingValue -= 0.1
                }
            }
        }
        
        if let data = imgData {
            if (Double(data.count) < sizeInBytes) {
                return  data
            }
        }
        
        let lowdata :Data = self.jpegData(compressionQuality: 0.1)!
        return lowdata
    }
}

