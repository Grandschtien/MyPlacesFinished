//
//  StorageManager.swift
//  MyPlaces
//
//  Created by Егор Шкарин on 06.06.2021.
//

import RealmSwift

let realm = try! Realm()

class StorageManager {
    // Функция которая позваоляет сохранить объект в бд
    static func saveObject(_ place: Place) {
        try! realm.write{
            realm.add(place)
        }
    }
    // Функция, которая позволяет удалить объект из базы данных
    static func deleteObject(_ place: Place) {
        try! realm.write {
            realm.delete(place)
        }
    }
}
