//
//  AHFMDatabase.swift
//  Pods
//
//  Created by Andy Tong on 7/20/17.
//
//

import Foundation
import UIDeviceExtension
import AHDataModel

internal var AHFMDatabasePath: String = (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("db.sqlte")


private let AHDatabaseQueue = "AHDatabaseQueue"


public class AHFMDataCenter {
    func setDatabaseFilePath(_ path: String) {
        AHFMDatabasePath = path
    }
}














