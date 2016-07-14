//
//  ZCJWebImageManager.swift
//  ZCJWebImage
//
//  Created by zhangchaojie on 16/7/3.
//  Copyright © 2016年 zhangchaojie. All rights reserved.
//

import UIKit

class ZCJWebImageManager {
    
    let downloader: ZCJWebImageDownloader
    
    let cache: ZCJWebImageCache

    class var shardedManager: ZCJWebImageManager{
        struct Static {
            static let instanse = ZCJWebImageManager()
        }
        return Static.instanse
    }
    
    init()
    {
        downloader = ZCJWebImageDownloader.shardedManager
        cache = ZCJWebImageCache.shardedManager
    }
    
    func downloadWithURL(url: NSURL, complete: CompletionHandle){
        if let image = cache.queryImageWith(url.absoluteString){
            complete(image: image, error: nil, imageUrl: url)
        }
        else{
            downloader.downloadWithURL(url, complete: { (image, error, imageUrl) in
                complete(image: image, error: error, imageUrl: imageUrl)
                self.cache.storeImageWith(image!, key: url.absoluteString)
            })
        }
    }
}
