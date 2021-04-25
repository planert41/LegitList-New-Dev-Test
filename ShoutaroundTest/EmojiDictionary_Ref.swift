//
//  EmojiDictionary_Ref.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/23/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation

// Emoji Search Categories
var allRatingEmojis:[Emoji] = []
var allSearchEmojis:[Emoji] = []
var allMealTypeEmojis:[Emoji] = []
var allMealTypeOptions:[String] = []

// Default Food Emojis
var breakfastFoodEmojis: [String] =
    ["🥞","🥓","🍳","🧀","🥚","🍞","🥖"]
var lunchFoodEmojis:[String] =
    ["🍱","🥗","🍲","🥙","🌮","🥪","🌯","🍔","🍕","🌭","🍟","🍗","🍤","🍢"]
var dinnerFoodEmojis:[String] =
    ["🍽","🍝","🥩","🍛","🍜","🍣","🍚","🥘","🥟","🥧","🥠"]
var allFoodEmojis:[String] = []

// Default Snack Drink Emojis
var snackEmojis:[String] =
    ["☕️","🍵","🥐","🍩","🍪","🍫","🍯","🥨","🍮","🍰","🍦","🍨","🍿","🍭","🍙"]
var drinkEmojis:[String] =
    ["🍺","🍷","🥃","🍸","🍶","🥤","🥛"]
var allDrinkEmojis:[String] = []


// Default Ingredient Emojis
var meatIngredientEmojis: [String] =
    ["🐮","🐷","🐔","🦆","🐟","🦐","🦀","🐙","🐌"]
var vegIngredientEmojis: [String] =
    ["🌱","🌿","🌶","🌾","🥜","🌰","🌽","🍅","🥑","🍄","🥕","🍆","🥦","🥒","🥔","🍠"]
var fruitsIngredientEmojis: [String] =
    ["🍎","🍋","🍊","🍑","🥥","🍐","🍌","🍓","🍇","🥝","🌹","🍈","🍉","🍒","🍍"]
var allIngredientEmojis:[String] = []

var allDefaultEmojis: [String] = []



// Default Smiley Emojis

var smileyEmojis: [String] = ["😍","😋","🤤","👍","😀","😝","😂","😎","😮","🤔","🤑","😴","😢","😭","🤥","😑","😡","😤","🤒","💩","😩"]

//var extraRatingEmojis: [String] = ["💯", "👑", "🥇", "🔥","👌", "💪", "👺", "💩","☠️"]
var extraRatingEmojis: [String] = ["💩","😡","🤔","👌","🔥","💯", "🥇"]

var extraRatingEmojisDic: [String: String] =
    ["💩":"poop", "😡":"angry", "🤔":"iffy", "👌":"legit","🔥":"fire", "💯":"100%", "🥇":"best"]


var UserStatusEmojis: [String] = "😍😋🤤🤩😭😤😥😓💩😡😵🤑💪👍✌️👌💯❤️🔥🏆🤯😭😤😢🤤😵🤮😋".map(String.init)


//"😍😋🤤🤩😭😤😥😓💩😡😵🤑💪👍✌️👌💯❤️🔥🏆🤯 😭😤😢🤤😵🤮😋"

// 💯👑🥇🔥👌💪👺💩☠️

// DEFAULT OTHER

var otherEmojis: [String] =
    ["🚗","🏠","🚌","🏪","🎂","💑","💼","📆","👔","👖","💵","💸","🔕","🅿️","🆕","👶","👨‍👩‍👧‍👦"]

var mealEmojis:[Emoji] = []
var cuisineEmojis:[Emoji] = []
var dietEmojis:[Emoji] = []

var mealEmojisSelect:[String] = ["🍳","🥞","🍱","🍽","🍮","☕️","🍺","🌙","📍"]
var mealEmojiDictionary:[String:String] = [
    "🍳":"breakfast",
    "🥞":"brunch",
    "🍱":"lunch",
    "🍽":"dinner",
    "🍮":"dessert",
    "☕️":"coffee",
    "🍺":"drinks",
    "🌙":"latenight",
    "📍":"poi"
]

var cuisineEmojiSelect:[String] = [
    "🇺🇸","🇲🇽","🇬🇷","🇹🇷","🇫🇷","🇮🇹","🇩🇪","🇪🇸","🇨🇳","🇯🇵","🇰🇷","🇮🇳","🇻🇳","🇵🇭",
    "🇹🇭","🇲🇾","🇵🇹","🇨🇦","🇬🇧","🇮🇷","🇮🇪","🇸🇪","🇦🇷","🇧🇷","🇵🇪","🇨🇴","🇨🇺","🇪🇹",
    "🇯🇲","🇳🇱","🇸🇳","🇷🇺"
]

var cuisineEmojiDictionary:[String:String] = [
    "🇺🇸":"american",
    "🇲🇽":"mexican",
    "🇬🇷":"greek",
    "🇹🇷":"turkish",
    "🇫🇷":"french",
    "🇮🇹":"italian",
    "🇩🇪":"german",
    "🇪🇸":"spanish",
    "🇨🇳":"chinese",
    "🇯🇵":"japanese",
    "🇰🇷":"korean",
    "🇮🇳":"indian",
    "🇻🇳":"vietnamese",
    "🇵🇭":"filipino",
    "🇹🇭":"thai",
    "🇲🇾":"malaysian",
    "🇵🇹":"portugese",
    "🇨🇦":"canadian",
    "🇬🇧":"british",
    "🇮🇷":"persian",
    "🇮🇪":"irish",
    "🇸🇪":"swedish",
    "🇦🇷":"argentinian",
    "🇧🇷":"brazilian",
    "🇵🇪":"peruvian",
    "🇨🇴":"colombian",
    "🇨🇺":"cuban",
    "🇪🇹":"bolivian",
    "🇯🇲":"jamaican",
    "🇳🇱":"dutch",
    "🇸🇳":"senagalese",
    "🇷🇺":"russian"
]
var dietEmojiSelect:[String] = [
   "❌🍖","❌🌽","❌🥜","❌🥛","⛪️","🕍","🕌", "☸️"
]
var dietEmojiDictionary:[String:String] = [
    "⛪️":"christian",
    "🕍":"kosher",
    "🕌":"halal",
    "☸️":"buddhist",
    "❌🍖": "vegetarian",
    "❌🌽": "gluten free",
    "❌🥜":"peanut free",
    "❌🥛":"non dairy"
]

var allAutoTagDictionary = [mealEmojiDictionary, cuisineEmojiDictionary,dietEmojiDictionary]





var eatsEmojis: [String] =
    ["🍕","🍔","🌭","🍟","🍲","🥗","🍝","🍖","🍣","🍜","🍚","🍛","🌮","🌯","🥙","🍗"]
var drinksEmojis: [String] =
    ["☕️","🍺","🍷","🍵"]
var snacksEmojis: [String] =
    ["🍩","🥐","🍦","🍰","🍫","🍪","🍧","🍭"]
var meatEmojis: [String] =
    ["🥓","🥚","🐮","🐷","🐔","🦆","🐟","🦐","🦀","🐙"]
var vegEmojis: [String] =
    ["🌾","🥜","🌽","🥑","🍎","🍊","🍑","🍐","🍌","🍄","🥕","🍅","🍓","🍇","🥝","🌹","🍈","🍉","🍒","🍍"]

var SET_VegEmojis: [String] = ["🍏","🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🍈","🍒","🍑","🍍","🥥","🥝","🍅","🍆","🥑","🥦","🥒","🌶","🌽","🥕","🥔","🍠","🌰","🥜","🍄","🌾","🌹"]
var SET_FoodEmojis: [String] = ["🥐","🍞","🥖","🥨","🧀","🥚","🍳","🥞","🥓","🍗","🍖","🌭","🍔","🍟","🍕","🥪","🥙","🌮","🌯","🥗","🥫","🍝","🍜","🍲","🍛","🍣","🍱","🥟","🍤","🍚","🥧"]
var SET_SnackEmojis: [String] = ["🍙","🍘","🍥","🥠","🍢","🍡","🍧","🍨","🍦","🥧","🍰","🎂","🍮","🍭","🍬","🍫","🍿","🍩","🍪"]
var SET_DrinkEmojis: [String] = ["🥛","☕️","🍵","🍯","🥤","🍶","🍺","🍻","🥂","🍷","🥃","🍸","🍹","🍾"]
var SET_FlagEmojis: [String] = [ "🇺🇸","🇲🇽","🇬🇷","🇹🇷","🇫🇷","🇮🇹","🇩🇪","🇪🇸","🇨🇳","🇯🇵","🇰🇷","🇮🇳","🇻🇳","🇵🇭",
                                    "🇹🇭","🇲🇾","🇵🇹","🇨🇦","🇬🇧","🇮🇷","🇮🇪","🇸🇪","🇦🇷","🇧🇷","🇵🇪","🇨🇴","🇨🇺","🇪🇹",
                                    "🇯🇲","🇳🇱","🇸🇳","🇷🇺"]
var SET_SmileyEmojis: [String] = ["😍","😋","🤤","👍","😀","😝","😂","😎","😮","🤔","🤑","😴","😢","😭","🤥","😑","😡","😤","🤒","💩","😩"]
var SET_RawEmojis: [String] = ["🥚","🥩","🐮","🐷","🐓","🦆","🐗","🐴","🐌","🐚","🐙","🦑","🦐","🦀","🐟","🐰","🐸","🐑","🐐","🦌","🦃","🐇"]
