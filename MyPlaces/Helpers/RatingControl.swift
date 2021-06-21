//
//  RatingControl.swift
//  MyPlaces
//
//  Created by Егор Шкарин on 08.06.2021.
//
// Этот класс не используется, но это впринципе рабочий варик 
import UIKit

// IBDesignable  - эта штука дает возможность писать в коде и отображаеть все это в сториборде в режиме онлайн
@IBDesignable class RatingControl: UIStackView {
    // MARK:- Varaibles
    var rating = 0 {
        didSet {
            updateButtonSelectedState()
        }
    }
    
    private var ratingButtons = [UIButton]()
    
    @IBInspectable var starSize: CGSize = CGSize(width: 44.0, height: 44.0) {
        didSet {
            setupButtons()
        }
    }
    @IBInspectable var starCount: Int = 5 {
        didSet {
            setupButtons()
        }
    }
    
    
    //MARK:- Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    //MARK: - Private Methods
    
    private func setupButtons() {
        for button in ratingButtons {
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        ratingButtons.removeAll()
        //Load button image
        let bundle = Bundle(for: type(of: self))
        let filledStar = UIImage(named: "filledStar",
                                 in: bundle, compatibleWith:
                                    self.traitCollection)
        
        let emptyStar = UIImage(named: "emptyStar",
                                in: bundle, compatibleWith:
                                    self.traitCollection)
        
        let hightLitedStar = UIImage(named: "highlightedStar",
                                     in: bundle,
                                     compatibleWith: traitCollection)
        
        
        for _ in 1...starCount {
            let button = UIButton()
            //set button images
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected)
            button.setImage(hightLitedStar, for: .highlighted)
            button.setImage(hightLitedStar, for: [.highlighted, .selected])
            //Констреинты (auto layout)
        
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
            // setup the button action
        
            button.addTarget(self, action: #selector(ratingButtonTapped(_:)), for: .touchUpInside)
            addArrangedSubview(button)
            ratingButtons.append(button)
        }
        updateButtonSelectedState()
    }
    
    //MARK: - Button Action
    
    @objc func ratingButtonTapped(_ button: UIButton) {
        guard let index = ratingButtons.firstIndex(of: button) else {return}
        // Определить рейтинг
        
        let selectedRating = index + 1
        if selectedRating == rating {
            rating = 0
        } else {
            rating = selectedRating
        }
    }
    
    private func updateButtonSelectedState() {
        for (index, button) in ratingButtons.enumerated() {
            button.isSelected = index < rating
        }
    }
}
