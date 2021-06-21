//
//  PlaceModel.swift
//  MyPlaces
//
//  Created by Егор Шкарин on 06.06.2021.
//

import RealmSwift


class Place: Object {
    @objc dynamic var name = ""
    @objc dynamic var location: String?
    @objc dynamic var type: String?
    @objc dynamic var image: Data?
    @objc dynamic var date = Date()
    @objc dynamic var rating = 0.0
    // Здесь используется convenience инициализатор для того, чтобы мы могли создать объект с дефолтными полями и не ебать себе мозги
    convenience init (name: String, location: String?, type: String?, image: Data?, rating: Double) {
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.image = image
        self.rating = rating
    }
}
