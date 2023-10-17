# PickerAttachments


A Swift Attachment picker support Camera Image, Photo Library, Video and File using this package you can import Image, Video and File in your project.

#Step 1:

This means that we have to verify if the user has given permission to access their photo or not.
Add two lines in Info.plist
# Privacy — Camera Usage Description 
# Privacy — Photo Library Usage Description

The above two lines should be added in to your app’s Info.plist with sample description as “$(PRODUCT_NAME) would like to access your camera and $(PRODUCT_NAME) would like to access your photo.”


#Step 2: 

select project and go to add package dependencies add this git Url(https://github.com/PRIYANKAJAISWAL17/PickerAttachments)

#Step 3:

import package in class "import PJAttachmentPicker" and call methods like this


        PJAttachmentPickerHandler.shared.showAttachmentActionSheet(vc: self)
        //For image
        PJAttachmentPickerHandler.shared.imagePickedBlock = { (image, fileName, fileExt) in
            print(fileName)
           
        }
        //For files
        PJAttachmentPickerHandler.shared.filePickedBlock = { (url) in
                        print(url.lastPathComponent)
            
        }
        //For video
        PJAttachmentPickerHandler.shared.videoPickedBlock = { (url) in
                        print(url.lastPathComponent ?? "")
           
            
        }


and you will get picked file in closer block.



