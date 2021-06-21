//
//  NewPlaceViewController.swift
//  MyPlaces
//
//  Created by Егор Шкарин on 06.06.2021.
//

import UIKit

class NewPlaceViewController: UITableViewController {
    
    var currentPlace: Place!
    
    var imageIsChange: Bool = false
    
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var placeName: UITextField!
    @IBOutlet weak var placeLocation: UITextField!
    @IBOutlet weak var placeType: UITextField!
    @IBOutlet weak var ratingControl: RatingControl!
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // замена всех лишних разлиновок на пустоту
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,
                                                         y: 0,
                                                         width: tableView.frame.size.width,
                                                         height: 1))
        // Настройка доступности кнопки
        saveButton.isEnabled = false
        // Добавление таргета на изменение поля, что кнопка сохранить включалась когда поле с именем заполнено
        placeName.addTarget(self, action: #selector(textFieldChaged), for: .editingChanged)
        setupEditScreen()
    }
    @objc private func textFieldChaged() {
        // если поле именю пустое кнопка не доступна, иначе доступна
        if placeName.text?.isEmpty == false {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
    
    func savePlace() {
        let image = imageIsChange ? placeImage.image : #imageLiteral(resourceName: "imagePlaceholder")
        // Хдесь мы переводим изображение в байтовый вид, так как в БД не может храниться изображение в виде UIImage
        let imageData = image?.pngData()
        let newPlace = Place(name: placeName.text!,
                             location: placeLocation.text,
                             type: placeType.text,
                             image: imageData, rating: Double(ratingControl.rating))
        // сохранение объекта, соданного выше
        if currentPlace != nil {
            try! realm.write {
                currentPlace?.name = newPlace.name
                currentPlace?.location = newPlace.location
                currentPlace?.type = newPlace.type
                currentPlace?.image = newPlace.image
                currentPlace?.rating = newPlace.rating
            }
        } else {
            StorageManager.saveObject(newPlace)
        }
     
    }
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        // Закрытие и выгрузка контроллера из памяти (без ебатни с созданием нового и тд
        dismiss(animated: true, completion: nil)
    }
    /// Функция для настройки экрана редактирования
    private func setupEditScreen() {
        // Это условие для того чтобы отделять экран редактирования от экрана добавления. currentPlace это данные которые приходят с ячейки
        if currentPlace != nil {
            setUpNavigationBar()
             imageIsChange = true
            guard let data = currentPlace?.image, let image = UIImage(data: data) else {return}
            
            placeImage.image = image
            placeImage.contentMode = .scaleAspectFill
            placeName.text = currentPlace?.name
            placeLocation.text = currentPlace?.location
            placeType.text = currentPlace?.type
            ratingControl.rating = Int(currentPlace.rating)
            
        }
    }
    /// Функция, которая настраивает навигационную панель для экрана редактирования
    private func setUpNavigationBar() {
        // Через эту функцию мы убираем надпись рядом со значком назад
        if  let topItem = navigationController?.navigationBar.topItem {
            topItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
        navigationItem.leftBarButtonItem = nil
        title = currentPlace?.name
        saveButton.isEnabled = true
    }
    
    //MARK:- TableViewDelegate
    // обработка нажатия на ячейку
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Для ячейки с индексом 0 отдельный if так как ну нас эта ячейка отвечает за фото
        if indexPath.row == 0 {
            // Через image literal выбрали фото
            let cameraIcon = #imageLiteral(resourceName: "camera")
            let photoIcon = #imageLiteral(resourceName: "photo")
            
            // создаем алерт контроллер для вызова камеры и галереи
            let actionSheet = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .actionSheet)
            // зодаем action для камеры на алерт контроллере
            let camera = UIAlertAction(title: "Camera",
                                       style: .default) { _ in
                self.chooseImagePicker(source: .camera)
            }
            // Добавляем на action для камеры фото и выравниваем текст по левому краю
            camera.setValue(cameraIcon, forKey: "image")
            camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            // создаем action для выбора фото из галереи
            let photo = UIAlertAction(title: "Photo",
                                      style: .default) { _ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            // Добавляем фото для галереи action и выравнимаем текст по левому краю
            photo.setValue(photoIcon, forKey: "image")
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            // action закрытия
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            actionSheet.addAction(camera)
            actionSheet.addAction(photo)
            actionSheet.addAction(cancel)
            
            present(actionSheet, animated: true, completion: nil)
        } else {
            // Чтобы убрать клавиатуру
            view.endEditing(true)
        }
    }
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier,
              let mapVC = segue.destination as? MapViewController
        else {return}
        
        mapVC.incomeSegueIdentifier = identifier
        mapVC.mapViewControllerDelegate = self
        if identifier == "showPlace" {
            mapVC.place.name = self.currentPlace.name
            mapVC.place.location = self.currentPlace.location
            mapVC.place.type = self.currentPlace.type
            mapVC.place.image = self.placeImage.image?.pngData()
        }
    }
    
}



// MARK: - TextFieldDelegate

extension NewPlaceViewController: UITextFieldDelegate {
    
    //Скрываем клавиатуру по нажатию на Done
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

//MARK:  Work with image

extension NewPlaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func chooseImagePicker(source: UIImagePickerController.SourceType){
        if UIImagePickerController.isSourceTypeAvailable(source) {
            // Создаем экземпляр класса пикера фотографий из галереи
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            // Здесь мы разрежаем пользователю редактировать выбранное изображение
            imagePicker.allowsEditing = true
            // Здесь мы присваиваем тот вид выбора изображения, которые передаем в агрументы функции
            imagePicker.sourceType = source
            present(imagePicker, animated: true, completion: nil)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Здесь мы выбираем по ключу изображение которое выбрал пользователь (ключ editedImage)
        placeImage.image = info[.editedImage] as? UIImage
        // Подгонка по размер image view
        placeImage.contentMode = .scaleAspectFill
        // Обрезка по границам
        placeImage.clipsToBounds = true
        
        imageIsChange = true
        dismiss(animated: true, completion: nil)
    }
}

extension NewPlaceViewController: MapViewControllerDelegate {
    func getAddress(_ address: String?) {
        placeLocation.text = address
    }
    
}
