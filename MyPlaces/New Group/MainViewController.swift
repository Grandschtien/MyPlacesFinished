//
//  MainViewController.swift
//  MyPlaces
//
//  Created by Егор Шкарин on 06.06.2021.
//

import UIKit
import RealmSwift
import Cosmos
class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let searchController = UISearchController(searchResultsController: nil)
    /// Это свойство нужно для вывода отсортированного массива объектов при сортировке
    private var places: Results<Place>!
    /// Это свойство нужно для отсортированной коллекции объктов при поиске
    private var filteredPlaces: Results<Place>!
    /// Свойтсво для отслежитвания направления сортировки
    private var ascendingSorting: Bool = true
    /// Свойство для отслеживания пустоты в окне поиска
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else {
            return false
        }
        return text.isEmpty
    }
    /// Свойтсво для проверки активно ли окно поиска и не пустое ли оно
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    @IBOutlet weak var reversedsortingButton: UIBarButtonItem!
    @IBOutlet weak var segmetedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Этот метод возвращает все объекты которые хранятся в базе данных и помещает их в массив
        places = realm.objects(Place.self)
        
        //Найстройка Search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    // MARK: - Table view data source

    // Количество ячеек
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if isFiltering{
            return filteredPlaces.count
        }
        return places.count
    }

   // Кастомизация ячеек
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Получение ячейки с идентификатором, важно то, что я привожу ячейку к конкретному классу так как у нас есть отдельный класс ячейки.
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? CustomTableViewCell else {return UITableViewCell()}
        
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
        
        // Добавление в ячейку из массива моделей данных
        cell.nameLabel.text = place.name
        cell.typeLabel.text = place.type
        cell.locationLabel.text = place.location
        cell.imageOfPlace.image = UIImage(data: place.image!)
        cell.cosmosView.rating = place.rating
        
        return cell
    }
    
    //MARK: - TableViewDelegate
    // высота ячейки
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // высота ячейки 85 пикселей
        return 85
    }
   // Этот метод дает возможность удалять данные из таблицы и соотвественно из базы данных через метод deleteObject
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Если идет стиль удаления, тогда выполняется код в if
        if editingStyle == .delete {
            let place = places[indexPath.row]
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    // MARK: - Navigation
    
    //  Метод для перехода по сегуэю showDetail (передача данных для редактирования)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Делаем условие, что проверить сегуэй перехода
        if segue.identifier == "showDetail" {
            // этот метод table view дает возможность достучаться до выбранной ячейки и забрать ее индекс
            guard let indexPath = tableView.indexPathForSelectedRow else {return}
            // Если значение true, тогда выводим отфильтрованные массив, иначе нет
            let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
            // создаем новый котроллер через свойство destination у segue, чтобы вытащить нужный котроллер
            guard let newPlaceVC = segue.destination as? NewPlaceViewController else {return}
            // передаем данные 
            newPlaceVC.currentPlace = place
            // Снятие выделения с ячейки при переходе на другой экран
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    

    // Для бар баттона сегуэй закрытия
    @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {
        // Теперь тут просто перезагружается таблица при переходе от окна добавления места
        guard let newPlaceVC = segue.source as? NewPlaceViewController else {return}
        // Сохраняем данные
        newPlaceVC.savePlace()
        tableView.reloadData()
    }
    
    //MARK: - SORTING
    @IBAction func sortSelection(_ sender: UISegmentedControl) {
        sorting()
    }
    @IBAction func reversedSorting(_ sender: UIBarButtonItem) {
        ascendingSorting.toggle()
        if ascendingSorting {
            reversedsortingButton.image = #imageLiteral(resourceName: "AZ")
        } else {
            reversedsortingButton.image = #imageLiteral(resourceName: "ZA")
        }
        sorting()
    }
    /// Функция сортировки по дате и имени
    private func sorting() {
        if segmetedControl.selectedSegmentIndex == 0 {
            places = places.sorted(byKeyPath: "date", ascending: ascendingSorting)
        } else {
            places = places.sorted(byKeyPath: "name", ascending: ascendingSorting)
        }
        tableView.reloadData()
    }
}

extension MainViewController: UISearchResultsUpdating {
    
    /// функция для обновления контента на контроллеле (поиск работает так, что при наборе запроса появляются новые контроллеры с отфильтрованными данными
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    /// функция для ображения к БД с запросом на фильрацию по имени и местоположению
    private func filterContentForSearchText(_ searchText: String) {
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText)
        tableView.reloadData()
    }
}
