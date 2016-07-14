//
//  ZCJWebImageCache.swift
//  ZCJWebImage
//
//  Created by zhangchaojie on 16/7/3.
//  Copyright © 2016年 zhangchaojie. All rights reserved.
//

import UIKit

private let cacheName = "Default"

class ZCJWebImageCache {
    
    class var shardedManager: ZCJWebImageCache{
        struct Static {
            static let instanse = ZCJWebImageCache(cacheName: cacheName)
        }
        return Static.instanse
    }
    
    var memCache = NSCache()
    
    private let ioQueue = dispatch_queue_create("ZCJWebImageCacheIOQueue", DISPATCH_QUEUE_SERIAL)
    
    var diskCachePath: String = ""
    
    init(cacheName: String){
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        self.diskCachePath = (paths.first! as NSString).stringByAppendingPathComponent(cacheName)
    }
    
    func storeImageWith(image: UIImage, key: String){
        storeImageWith(image, key: key, toDisk: true)
    }
    
    func storeImageWith(image: UIImage, key: String, toDisk: Bool){
        self.memCache.setObject(image, forKey: key)
        
        if toDisk {
            dispatch_barrier_sync(self.ioQueue, { 
                if let data = UIImagePNGRepresentation(image) {
                    let fileManager = NSFileManager()
                    if !fileManager.fileExistsAtPath(self.diskCachePath) {
                        try! fileManager.createDirectoryAtPath(self.diskCachePath, withIntermediateDirectories: true, attributes: nil)
                    }
                    
                    fileManager.createFileAtPath(self.diskCachePath + key.kf_MD5, contents: data, attributes: nil)
                }
            })
        }
    }
    
    func removeImageWith(key: String){
        self.memCache.removeObjectForKey(key)
        
        dispatch_async(self.ioQueue) { 
            try! NSFileManager.defaultManager().removeItemAtPath(self.diskCachePath + key.kf_MD5)
        }
    }
    
    func queryImageWith(key: String) -> UIImage?{
        if let img = self.memCache.objectForKey(key) {
            return img as? UIImage
        }else{
            if let img = NSFileManager.defaultManager().contentsAtPath(self.diskCachePath + key.kf_MD5) {
                return UIImage(data: img)!
            }
            else{
                return nil
            }

        }
    }
}
