//
//  ZCJWebImageDownloader.swift
//  ZCJWebImage
//
//  Created by zhangchaojie on 16/7/3.
//  Copyright © 2016年 zhangchaojie. All rights reserved.
//

import UIKit

//typealias DownloadProgressBlock = ((receivedSize: Int64, totalSize: Int64) -> ())
typealias CompletionHandle = ((image: UIImage?, error: NSError?, imageUrl: NSURL?) -> ())

private let kCompletionHandler = "kCompletionHandler"
private let downloaderBarrierName = "ImageDownloader.Barrier"

class ZCJWebImageDownloader:NSObject {
    
    struct ImageFetchLoad {
        var callbacks = [String:CompletionHandle?]()
        var responseData = NSMutableData()
    }
    
    var fetchLoads = [NSURL:ImageFetchLoad]()
    
    let barrierQueue = dispatch_queue_create(downloaderBarrierName, DISPATCH_QUEUE_CONCURRENT)
    
    class var shardedManager: ZCJWebImageDownloader{
        struct Static {
            static let instanse = ZCJWebImageDownloader()
        }
        return Static.instanse
    }
    
    func downloadWithURL(url: NSURL, complete: CompletionHandle?){
        setupProcessBlock(complete!, url: url) { (session, fetchLoad) in
            let request = NSURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 15)
            let task = session.dataTaskWithRequest(request)
            task.resume()
            
        }
    }
    
    func setupProcessBlock(completionHandle: CompletionHandle, url: NSURL, started: ((NSURLSession, ImageFetchLoad) -> Void)){
        
        dispatch_barrier_sync(barrierQueue, { () -> Void in
            
            var first = false
            if self.fetchLoads[url] == nil {
                self.fetchLoads[url] = ImageFetchLoad()
                first = true
            }
            
            var fetchUrl = self.fetchLoads[url]
            fetchUrl?.callbacks[kCompletionHandler] = completionHandle
            
            self.fetchLoads[url] = fetchUrl
            
            if first {
                let session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
                started(session, fetchUrl!)
            }
        })
    }
    
    func cleanUrl(url:NSURL){
        dispatch_barrier_sync(barrierQueue, { () -> Void in
            
                self.fetchLoads.removeValueForKey(url)
            })
    }
}

extension ZCJWebImageDownloader: NSURLSessionDataDelegate
{
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if let url = dataTask.originalRequest!.URL, fetchLoad = fetchLoads[url] {
            fetchLoad.responseData.appendData(data)
        }
    }
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        let url = task.originalRequest?.URL
        if let error = error {
            callbackWithImage(nil, error: error, imageUrl: url!)
        }
        else{
            dispatch_async(dispatch_queue_create("ImageProcessQueue", DISPATCH_QUEUE_CONCURRENT), { () -> Void in
                
                if let fetchLoad = self.fetchLoads[url!] {
                    if let image = UIImage(data: fetchLoad.responseData) {
                        self.callbackWithImage(image, error: nil, imageUrl: url!)
                    }
                    self.cleanUrl(url!)
                }
            })
        }
        
    }
    
    func callbackWithImage(image: UIImage?, error: NSError?, imageUrl: NSURL){
        if let complete = self.fetchLoads[imageUrl]?.callbacks[kCompletionHandler] {
            complete!(image: image, error: error, imageUrl: imageUrl)
        }
    }
}
