//
//  ValidationError.swift
//  Freebitco.in Roll Reminder
//
//  Created by Ali Tabatabaei on 9/15/18.
//  Copyright © 2018 Ali Tabatabaei. All rights reserved.
//

import Foundation

struct ValidationError: Error {
    
    public let message: String
    
    public init(message m: String) {
        message = m
    }
}
