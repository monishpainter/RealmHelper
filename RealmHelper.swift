//
//  RealmHelper.swift
//
//  Created by Monish Painter(monishpainter@yahoo.com) on 28/03/20.
//  Copyright © 2020 Monish Painter. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class DBManager {
    
    var database:Realm
    
    static let sharedInstance:DBManager = {
        let instance = DBManager ()
        return instance
    } ()
    
    private init() {
        print("\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])")
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 43,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 43 {
                    
                }
        })
        Realm.Configuration.defaultConfiguration = config
        //
        //        _ = try! Realm.performMigration()
        
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
                DBManager.sharedInstance.database.cancelWrite()
            }
        }
    }
    
    func config(){
        
    }
    
    func fetchObjects<T: Object>(_ type: T.Type, _ predicate: NSPredicate? = nil, _ order: [SortDescriptor]? = nil) -> Results<T>? {
        var results = DBManager.sharedInstance.database.objects(type)
        if predicate != nil {
            results = results.filter(predicate!)
        }
        if order != nil {
            results = results.sorted(by: order!)
        }
        return results
    }

    //DBManager.sharedInstance.fetchObjects(type: RObjStatusList.self, predicate: NSPredicate(format: "key = 'all'"), order:nil)
    func fetchObjectsInArray<T: Object>(_ type: T.Type, _ predicate: NSPredicate? = nil, _ order: [SortDescriptor]? = nil) -> [T] {
        var results = DBManager.sharedInstance.database.objects(type)
        if predicate != nil {
            results = results.filter(predicate!)
        }
        if order != nil {
            results = results.sorted(by: order!)
        }
        return results.toArray(ofType: T.self)
    }
    
    func fetchObjectsWithOffset<T: Object>(_ type: T.Type, _ predicate: NSPredicate? = nil, _ order: [SortDescriptor]? = nil, offset: Int, limit: Int ) -> [T] {
        var results = DBManager.sharedInstance.database.objects(type)
        if predicate != nil {
            results = results.filter(predicate!)
        }
        if order != nil {
            results = results.sorted(by: order!)
        }
        
        return results.get(offset: offset, limit: limit)
    }
    
    /*let objRTrack = RObjTrackList()
     objRTrack.stockIdn = objDiamond.stockIdn!
     DBManager.sharedInstance.addObject(object: objRTrack, update: true)*/
    func addObject(object: Object?, update: Realm.UpdatePolicy = .modified) {
        safeTransaction {
            if object != nil {
                DBManager.sharedInstance.database.add(object!, update: update)
            }
        }
    }
    
    
    func editObjects(object: Object?) {
        
        safeTransaction {
            if object != nil {
                DBManager.sharedInstance.database.add(object!, update: .all)
            }
        }
    }
    func editObject(object:Object,key:String,value:Any?){
        safeTransaction {
            object[key] = value
            DBManager.sharedInstance.database.add(object, update: .modified)
        }
    }
    //Pass All Realm object
    //DBManager.sharedInstance.addAllObjectsFormDic(RObjStatusList.self, value: dicStatus, update: true)
    func addAllObjects<T: Object>(list: [T]?, update: Realm.UpdatePolicy = .modified) {
        safeTransaction {
            DBManager.sharedInstance.database.add(list!, update: update)
        }
    }
    
    //add object from dic
    //DBManager.sharedInstance.addAllObjectsFormDic(RObjStatusList.self, value: dicStatus, update: true)
    func addAllObjectsFormDic<T: Object>(_ type: T.Type, value: Any = [:], update: Realm.UpdatePolicy = .modified){
        safeTransaction {
            DBManager.sharedInstance.database.create(type, value: value, update: update)
        }
    }
    
    func updateObject(updateBlock: @escaping () -> ()) {
        safeTransaction {
            updateBlock()
        }
    }
    
    
    //DBManager.sharedInstance.deleteObject(objBuy, cascading: true)
    func deleteObject(_ object: Object?, cascading: Bool) {
        safeTransaction {
            if object != nil {
                DBManager.sharedInstance.database.delete(object!, cascading: cascading)
            }
        }
    }
    
    //DBManager.sharedInstance.deleteObjects(RObjBuy.self)
    func deleteObjects<T: Object>(_ type: T.Type, cascading: Bool) {
        safeTransaction {
            let allObj = DBManager.sharedInstance.database.objects(type)
            DBManager.sharedInstance.database.delete(allObj, cascading: cascading)
        }
    }
    
    //DBManager.sharedInstance.deleteAllFromDatabase()
    func deleteAllFromDatabase()  {
        safeTransaction {
            DBManager.sharedInstance.database.deleteAll()
        }
    }
    /*
     func incrementID<T: Object>(_ type: T.Type, _ key :  String = "id") -> Int {
     let realm = try! Realm()
     return (realm.objects(type.self).max(ofProperty: key) as Int? ?? 0) + 1
     }
     */
    func incrementID<T: Object>(_ type: T.Type, _ key :  String = "id", _ predicate: NSPredicate? = nil) -> Int {
        var results = DBManager.sharedInstance.database.objects(type)
        if predicate != nil {
            results = results.filter(predicate!)
        }
        return (results.max(ofProperty: key) as Int? ?? 0) + 1
    }
    
}


extension Results {
    func toArray<T>(ofType: T.Type) -> [T] {
        var array = [T]()
        for i in 0 ..< count {
            if let result = self[i] as? T {
                array.append(result)
            }
        }
        
        return array
    }
    
    /*func toArray<T>(ofType: T.Type) -> [T] {
        let array = Array(self) as! [T]
        return array
    }*/

    func get<T> (offset: Int, limit: Int ) -> [T]{
        //create variables
        var lim = 0 // how much to take
        var off = 0 // start from
        var array = [T]()
        
        //check indexes
        if offset<=self.count {
            off = offset
        }
        if limit > self.count {
            lim = self.count
        }else{
            lim = limit + off
        }
        if lim > self.count{
            lim = self.count
        }
        
        //do slicing
        for i in off..<lim{
            let obj = self[i] as! T
            array.append(obj)
        }
        
        //results
        return array
    }
    
}


//extension List where Element : Decodable {
//    public convenience init(from decoder: Decoder) throws {
//        self.init()
//        var container = try decoder.unkeyedContainer()
//        while !container.isAtEnd {
//            let element = try container.decode(Element.self)
//            self.append(element)
//        }
//    } }
//
//extension List where Element : Encodable {
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.unkeyedContainer()
//        for element in self {
//            try element.encode(to: container.superEncoder())
//        }
//    }
//
//}

protocol DetachableObject: AnyObject {
    func detached() -> Self
}

extension Object: DetachableObject {
    func detached() -> Self {
        let detached = type(of: self).init()
        for property in objectSchema.properties {
            guard let value = value(forKey: property.name) else {
                continue
            }
            if let detachable = value as? DetachableObject {
                detached.setValue(detachable.detached(), forKey: property.name)
            } else { // Then it is a primitive
                detached.setValue(value, forKey: property.name)
            }
        }
        return detached
    }
}

extension List: DetachableObject {
    func detached() -> List<Element> {
        let result = List<Element>()
        forEach {
            if let detachableObject = $0 as? DetachableObject,
                let element = detachableObject.detached() as? Element {
                result.append(element)
            } else { // Then it is a primitive
                result.append($0)
            }
        }
        return result
    }
}
