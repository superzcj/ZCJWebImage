//
//  UIImage+WebCache.swift
//  ZCJWebImage
//
//  Created by zhangchaojie on 16/7/3.
//  Copyright © 2016年 zhangchaojie. All rights reserved.
//

import UIKit

public extension UIImageView
{
    func zcj_setImageWithUrl(url: NSURL)
    {
        zcj_SetImageWithUrl(url, placeHolderImage: nil)
    }
    
    func zcj_SetImageWithUrl(url: NSURL, placeHolderImage: UIImage?)
    {
        image = placeHolderImage
        
        self.zcj_setImageUrl(url)
        
        ZCJWebImageManager.shardedManager.downloadWithURL(url, complete: { (image, error, imageUrl) in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if imageUrl == url && image != nil {
                        self.image = image
                    }
                })
            })
        
    }
}

private var lastUrlKey: Void
public extension UIImageView{
    
    private func zcj_getImageUrl() -> NSURL?{
        return objc_getAssociatedObject(self, &lastUrlKey) as? NSURL
    }
    
    private func zcj_setImageUrl(url: NSURL){
        objc_setAssociatedObject(self, &lastUrlKey, url, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
