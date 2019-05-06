//
//  RealmHelper.swift
//  KapuGems
//
//  Created by Monish Painter on 24/05/18.
//  Copyright © 2018 Qwesys Digital Solutions. All rights reserved.
//

import UIKit
import Realm
import RealmSwift

class DBManager {
    
    var database:Realm
    
    static let sharedInstance:DBManager = {
        let instance = DBManager ()
        return instance
    } ()
    
    private init() {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    migration.enumerateObjects(ofType: RObjDiamond.className()) { (_, newRoute) in
                        //newRoute?["lrHalf"] = 0.0
                    }
                }
        })
        Realm.Configuration.defaultConfiguration = config
        
        _ = try! Realm.performMigration()

        database = try! Realm()
    }
    
    
    private func safeTransaction(withBlock block: @escaping ()
        -> Void) {
        if !DBManager.sharedInstance.database.isInWriteTransaction {
            DBManager.sharedInstance.database.beginWrite()
        }
        block()
        if DBManager.sharedInstance.database.isInWriteTransaction {
            do {
                try DBManager.sharedInstance.database.commitWrite()
            }
            catch {
                DLog(error.localizedDescription)
            }
        }
    }
    
    //DBManager.sharedInstance.fetchObjects(type: RObjStatusList.self, predicate: NSPredicate(format: "key = 'all'"), order:nil)
    func fetchObjects<T: Object>(type: T.Type, predicate: NSPredicate?, order: [SortDescriptor]?) -> Results<T>? {
        var results = DBManager.sharedInstance.database.objects(type)
        if predicate != nil {
            results = results.filter(predicate!)
        }
        if order != nil {
            results = results.sorted(by: order!)
        }
        return results
    }
    
    
    /*let objRTrack = RObjTrackList()
     objRTrack.stockIdn = objDiamond.stockIdn!
     DBManager.sharedInstance.addObject(object: objRTrack, update: true)*/
    func addObject(object: Object?, update: Bool? = false) {
        safeTransaction {
            if object != nil {
                DBManager.sharedInstance.database.add(object!, update: update!)
            }
        }
    }
    
    
    func editObjects(object: Object?) {
        
        safeTransaction {
            if object != nil {
                DBManager.sharedInstance.database.add(object!, update: true)
            }
        }
    }
    func editObject(object:Object,key:String,value:Any?){
        safeTransaction {
            object[key] = value
            DBManager.sharedInstance.database.add(object, update: true)
        }
    }
    //Pass All Realm object
    //DBManager.sharedInstance.addAllObjectsFormDic(RObjStatusList.self, value: dicStatus, update: true)
    func addAllObjects<T: Object>(list: [T]?, update: Bool? = false) {
        safeTransaction {
            DBManager.sharedInstance.database.add(list!, update: update!)
        }
    }
    
    //add object from dic
    //DBManager.sharedInstance.addAllObjectsFormDic(RObjStatusList.self, value: dicStatus, update: true)
    func addAllObjectsFormDic<T: Object>(_ type: T.Type, value: Any = [:], update: Bool = false){
        safeTransaction {
            DBManager.sharedInstance.database.create(type, value: value, update: update)
        }
    }
    
    func updateObject(updateBlock: @escaping () -> ()) {
        safeTransaction {
            updateBlock()
        }
    }
    
    
    //DBManager.sharedInstance.deleteObject(objBuy)
    func deleteObject(_ object: Object?) {
        safeTransaction {
            if object != nil {
                DBManager.sharedInstance.database.delete(object!)
            }
        }
    }
    
    //DBManager.sharedInstance.deleteObjects(RObjBuy.self)
    func deleteObjects<T: Object>(_ type: T.Type) {
        safeTransaction {
            let allObj = DBManager.sharedInstance.database.objects(type)
            DBManager.sharedInstance.database.delete(allObj)
        }
    }
    
    //DBManager.sharedInstance.deleteAllFromDatabase()
    func deleteAllFromDatabase()  {
        safeTransaction {
            DBManager.sharedInstance.database.deleteAll()
        }
    }
    
   
    
}
