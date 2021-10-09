//
//  EmojiDictionary_Ref.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 7/23/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation

// Emoji Search Categories
var allRatingEmojis:[EmojiBasic] = []
var allSearchEmojis:[EmojiBasic] = []
var allMealTypeEmojis:[EmojiBasic] = []
var allMealTypeOptions:[String] = []

// Default Food Emojis
var breakfastFoodEmojis: [String] =
    ["🍳","🥞","🧇","🥓","🥚","🍞","🥖", "🥐", "🥯","🥨","🧈","🧀","🥧","☕️","🫖"]
var lunchFoodEmojis:[String] =
    ["🍱","🥗","🍲","🍔","🌭","🍟","🥪","🍝","🍜","🍣","🍛","🥙", "🫓","🧆", "🥟","🍚","🥘","🥟","🫕","🥧","🥣"]
var dinnerFoodEmojis:[String] =
    ["🍽","🥩","🍤","🍝","🍣","🍜","🍲","🫕","🥘","🍔","🌭","🍟","🥪","🍛","🥟","🍚","🥘","🥟", "🥗"]
var allFoodEmojis:[String] = []

// Default Snack Drink Emojis
var snackEmojis:[String] =
    ["🧋","☕️","🫖","🍵","🥐","🍩","🍪","🍫","🍯","🥨","🍮","🍰","🍦","🍨","🍿","🍭","🍙","🥮"]
var drinkEmojis:[String] =
    ["🧋","🍺","🍷","🥃","🍸","🍶","🥤","🥛"]
var allDrinkEmojis:[String] = []


// Default Ingredient Emojis
var meatIngredientEmojis: [String] =
    ["🐮","🐷","🐔","🦆","🦃","🐤","🐟","🦐","🦀","🦞","🐙","🐌","🦬","🐐","🐑","🐰","🐴","🐊"]
var vegIngredientEmojis: [String] =
    ["🌿","☘️","🌳","🥬","🥑","🧄","🧅","🌽","🍅","🍄","🥕","🍆","🫑","🌾","🥜","🌰","🥦","🥒","🥔","🍠"]
var fruitsIngredientEmojis: [String] =
    ["🍎","🍋","🍊","🍑","🥥","🍐","🍌","🍓","🍇","🥝","🌹","🍈","🍉","🍒","🍍","🥭"]
var allIngredientEmojis:[String] = []

var allDefaultEmojis: [String] = []



// Default Smiley Emojis

var smileyEmojis: [String] = ["😍","😋","🤤","👍","😀","😝","😂","😎","😮","🤔","🤑","😴","😢","😭","🤥","😑","😡","😤","🤒","💩","😩"]

//var extraRatingEmojis: [String] = ["💯", "👑", "🥇", "🔥","👌", "💪", "👺", "💩","☠️"]
var extraRatingEmojis: [String] = ["💩","😡","🤔","👌","🔥","💯", "🥇"]
var extraRatingEmojisForList: [String] = ["🥇", "💯", "🔥", "👌", "🤔"]


var extraRatingEmojisDic: [String: String] =
    ["💩":"poop", "😡":"angry", "😍":"awesome", "👌":"legit","🔥":"fire", "💯":"100%", "🥇":"best","🤔":"curious"]


var UserStatusEmojis: [String] = "😍😋🤤🤩😭😤😥😓💩😡😵🤑💪👍✌️👌💯❤️🔥🏆🤯😭😤😢🤤😵🤮😋".map(String.init)


//"😍😋🤤🤩😭😤😥😓💩😡😵🤑💪👍✌️👌💯❤️🔥🏆🤯 😭😤😢🤤😵🤮😋"

// 💯👑🥇🔥👌💪👺💩☠️

// DEFAULT OTHER

var otherEmojis: [String] =
    ["🚗","🏠","🚌","🏪","🎂","💑","💼","📆","👔","👖","💵","💸","🔕","🅿️","🆕","👶","👨‍👩‍👧‍👦"]

var mealEmojis:[EmojiBasic] = []
var cuisineEmojis:[EmojiBasic] = []
var dietEmojis:[EmojiBasic] = []

var mealEmojisSelect:[String] = ["🍳","🍱","🍽","🍨","☕️","🍙","🍻","🌙","🥡","🚗","📍"]
var mealEmojiDictionary:[String:String] = [
//    "🥞":"brunch",
    "🍳":"breakfast",
    "🍱":"lunch",
    "🍽":"dinner",
    "🍨":"dessert",
    "🍙":"snack",
    "☕️":"coffee",
    "🍻":"drinks",
    "🌙":"latenight",
    "🚗":"delivery",
    "🥡":"takeout",
    "📍":"poi"
]

var cuisineEmojiSelect:[String] = [

]

var dietEmojiSelect:[String] = ["❌🍖","❌🌾","✅","☘️","❌🍚","🕍","🕌","⛪️","🛕","☸️","❌🥜","❌🥛"]
//var dietEmojiDictionary:[String:String] = [
//    "⛪️":"christian",
//    "🕍":"kosher",
//    "🕌":"halal",
//    "☸️":"buddhist",
//    "❌🍖": "vegetarian",
//    "❌🌽": "gluten free",
//    "❌🥜":"peanut free",
//    "❌🥛":"non dairy"
//]

var allAutoTagDictionary = [mealEmojiDictionary, FlagEmojiDictionary, DietEmojiDictionary]
var autoTagEmojiSelect:[String] = []







var SET_VegEmojis: [String] = ["🥬","🥑","🥒","🥦","🍆","🍄","🥥","🍌","🍉","🍋","🧄","🧅"]
var SET_FoodEmojis: [String] = ["🍩","🍔","🍕","🍟","🌭","🥗","🍣","🍜","🌮","🌯","🫔","🥙","🧆","🫓","🍗","🍝","🍛"]
var SET_SnackEmojis: [String] = ["🍩","🍪","🍫","🍿","🍦","🍨","🧁","🍰","🥐","🥖","🥨"]
var SET_DrinkEmojis: [String] = ["🧋","☕️","🫖","🍵","🍺","🍷","🍸","🍹"]
var SET_FlagEmojis: [String] = ["🇺🇸","🇫🇷","🇮🇹","🇩🇪","🇬🇷","🇨🇳","🇯🇵","🇰🇷","🇹🇼","🇮🇳","🇻🇳","🇭🇰","🇹🇭","🇲🇾","🇨🇺","🇵🇷","🇲🇽","🇧🇷","🇨🇴","🇨🇱"]
var SET_SmileyEmojis: [String] = ["😀","😍","🤤","🤯","😂","😢","😭","😓","😩","😑","😱","😤","🤬"]
var SET_RawEmojis: [String] = ["🐮","🐷","🐔","🦆","🐟","🦐","🦀","🦞","🐙","🦑","🦃","🐑","🐐","🦬","🐗","🐴","🐰"]
var SET_OtherEmojis: [String] = ["🚗","🏠","💑","👔","🩴","🕯","⚡️","🎉","📆","🧨","💣","✈️","❤️","🌟","🗽","👑"]
var SET_AllEmojis: [String] = ["🚗","🏠","💑","👔","🩴","🕯","⚡️","🎉","📆","🧨","💣","✈️","❤️","🌟","🗽","👑"]



/*
MISSING EMOJIS

 EMOJIS

🍏
🫐
🥭
🥥
🍆
🥦
🥬
🥒
🫑
🫒
🧄
🧅
🥔
🍠
🥯
🍞
🥖
🥨
🧈
🧇
🥩
🥩
🦴
🥪
🫓
🧆
🫔
🥘
🫕
🥫
🥟
🦪
🍙
🍘
🍥
🥠
🥮
🍡
🍨
🥧
🧁
🍬
🍿
🌰
🥛
🫖
🧃
🥤
🧋
🍶
🍻
🥂
🥃
🍹
🧉
🍾
🧊
🥄
🍴
🥣
🥡
🥢
🧂
🐶
🐱
🐭
🐰
🐹
🐻
🦊
🐻‍❄️
🐼
🐨
🐯
🦁
🐽
🐸
🐵
🐧
🐦
🐤
🐥
🐣
🦅
🦉
🦇
🐺
🐗
🐴
🦄
🐝
🪱
🐛
🦋
🐌
🐞
🐜
🪰
🐢
🐍
🦎
🦖
🦕
🦑
🦞
🐡
🐠
🐬
🐳
🐋
🦈
🦭
🐊
🐅
🐆
🦓
🦍
🦧
🦣
🐘
🦏
🦛
🐪
🐫
🦘
🦒
🐃
🦬
🐄
🐂
🐎
🐖
🐏
🐑
🦙
🐐
🦌
🐕
🐩
🦮
🐕‍🦺
🐈
🐈‍⬛
🪶
🦃
🦚
🦤
🦢
🦜
🦩
🕊
🐇
🦝
🦨
🦡
🦫
🦦
🦥
🐁
🐀
🐿
🦔
🐉
🌷
🥀
🌺
🌼
🌞
 
 COUNTRIES
 
 🏳️‍🌈
 🏳️‍⚧️
 🇺🇳
 🇦🇫
 🇦🇽
 🇩🇿
 🇦🇱
 🇦🇩
 🇦🇸
 🇦🇮
 🇦🇴
 🇦🇶
 🇦🇬
 🇦🇲
 🇦🇺
 🇦🇼
 🇦🇹
 🇦🇿
 🇧🇸
 🇧🇭
 🇧🇩
 🇧🇧
 🇧🇪
 🇧🇾
 🇧🇿
 🇧🇯
 🇧🇲
 🇧🇹
 🇧🇴
 🇧🇦
 🇧🇼
 🇻🇬
 🇧🇳
 🇧🇬
 🇧🇫
 🇧🇮
 🇰🇭
 🇨🇲
 🇮🇨
 🇨🇻
 🇧🇶
 🇰🇾
 🇨🇫
 🇹🇩
 🇮🇴
 🇨🇱
 🇨🇽
 🇨🇨
 🇰🇲
 🇨🇬
 🇨🇩
 🇨🇰
 🇨🇷
 🇨🇮
 🇭🇷
 🇨🇼
 🇨🇾
 🇨🇿
 🇩🇰
 🇩🇯
 🇩🇲
 🇩🇴
 🇪🇨
 🇪🇬
 🇸🇻
 🇬🇶
 🇪🇷
 🇪🇪
 🇸🇿
 🇪🇺
 🇫🇴
 🇫🇰
 🇫🇯
 🇫🇮
 🇬🇫
 🇵🇫
 🇹🇫
 🇬🇦
 🇬🇲
 🇬🇪
 🇬🇭
 🇬🇮
 🇬🇱
 🇬🇩
 🇬🇵
 🇬🇺
 🇬🇹
 🇬🇬
 🇬🇳
 🇬🇼
 🇬🇾
 🇭🇹
 🇭🇳
 🇭🇰
 🇭🇺
 🇮🇸
 🇮🇩
 🇮🇶
 🇮🇲
 🇮🇱
 🎌
 🇯🇴
 🇯🇪
 🇰🇿
 🇰🇪
 🇰🇮
 🇽🇰
 🇰🇼
 🇰🇬
 🇱🇦
 🇱🇻
 🇱🇧
 🇱🇸
 🇱🇷
 🇱🇾
 🇱🇮
 🇱🇹
 🇱🇺
 🇲🇴
 🇲🇬
 🇲🇼
 🇲🇻
 🇲🇱
 🇲🇹
 🇲🇭
 🇲🇶
 🇲🇷
 🇲🇺
 🇾🇹
 🇫🇲
 🇲🇩
 🇲🇨
 🇲🇳
 🇲🇪
 🇲🇸
 🇲🇦
 🇲🇿
 🇲🇲
 🇳🇦
 🇳🇷
 🇳🇵
 🇳🇨
 🇳🇿
 🇳🇮
 🇳🇪
 🇳🇬
 🇳🇺
 🇳🇫
 🇲🇰
 🇰🇵
 🇲🇵
 🇴🇲
 🇳🇴
 🇵🇰
 🇵🇼
 🇵🇸
 🇵🇦
 🇵🇬
 🇵🇾
 🇵🇳
 🇵🇱
 🇵🇷
 🇶🇦
 🇷🇪
 🇷🇴
 🇷🇼
 🇼🇸
 🇸🇲
 🇸🇹
 🇸🇦
 🇷🇸
 🇸🇨
 🇸🇱
 🇸🇬
 🇸🇽
 🇸🇰
 🇸🇮
 🇬🇸
 🇸🇧
 🇸🇴
 🇿🇦
 🇸🇸
 🇱🇰
 🇧🇱
 🇸🇭
 🇰🇳
 🇵🇲
 🇱🇨
 🇻🇨
 🇸🇷
 🇸🇩
 🇨🇭
 🇸🇾
 🇹🇼
 🇹🇯
 🇹🇿
 🇹🇱
 🇹🇬
 🇹🇰
 🇹🇴
 🇹🇹
 🇹🇳
 🇹🇲
 🇹🇨
 🇹🇻
 🇻🇮
 🇺🇬
 🇺🇦
 🇦🇪
 🏴󠁧󠁢󠁥󠁮󠁧󠁿
 🏴󠁧󠁢󠁳󠁣󠁴󠁿
 🏴󠁧󠁢󠁷󠁬󠁳󠁿
 🇺🇾
 🇻🇺
 🇺🇿
 🇻🇦
 🇻🇪
 🇼🇫
 🇪🇭
 🇾🇪
 🇾🇪
 🇿🇲
 🇿🇼


 let testEmoji = "🍏🍎🍐🍊🍋🍌🍉🍇🍓🫐🍈🍒🍑🥭🍍🥥🥝🍅🍆🥑🥦🥬🥒🌶🫑🌽🥕🫒🧄🧅🥔🍠🥐🥯🍞🥖🥨🥚🧀🍳🧈🥞🧇🥓🥩🥩🍗🍖🦴🌭🍔🍟🍕🥪🫓🥙🧆🌮🌯🫔🥗🥘🫕🥫🍝🍜🍲🍛🍣🍱🥟🦪🍤🍙🍚🍘🍥🥠🥮🍢🍡🍧🍨🍦🥧🧁🍰🎂🍮🍭🍬🍿🍫🍩🍪🌰🥜🍯🥛🍼🫖☕️🍵🧃🥤🧋🍶🍺🍻🥂🍷🥃🍸🍹🧉🍾🧊🥄🍴🍽🥣🥡🥢🧂🐶🐱🐭🐰🐹🐻🦊🐻‍❄️🐼🐨🐯🦁🐮🐽🐷🐸🐵🐔🐧🐦🐤🐥🐣🦆🦅🦉🦇🐺🐗🐴🦄🐝🪱🐛🦋🐌🐞🐜🪰🐢🐍🦎🦖🦕🐙🦑🦞🦐🦀🐡🐠🐟🐬🐳🐋🦈🦭🐊🐅🐆🦓🦍🦧🦣🐘🦏🦛🐪🐫🦘🦒🐃🦬🐄🐂🐎🐖🐏🐑🦙🐐🦌🐕🐩🦮🐕‍🦺🐈🐈‍⬛🪶🐓🦃🦚🦤🦢🦜🦩🕊🐇🦝🦨🦡🦫🦦🦥🐁🐀🐿🦔🐉🍄🌷🌹🥀🌺🌼🌞"
 
 let countryEmoji = "🏳️‍🌈🏳️‍⚧️🇺🇳🇦🇫🇦🇽🇩🇿🇦🇱🇦🇩🇦🇸🇦🇮🇦🇴🇦🇶🇦🇬🇦🇷🇦🇲🇦🇺🇦🇼🇦🇹🇦🇿🇧🇸🇧🇭🇧🇩🇧🇧🇧🇪🇧🇾🇧🇿🇧🇯🇧🇲🇧🇹🇧🇴🇧🇦🇧🇼🇧🇷🇻🇬🇧🇳🇧🇬🇧🇫🇧🇮🇰🇭🇨🇲🇨🇦🇮🇨🇨🇻🇧🇶🇰🇾🇨🇫🇹🇩🇮🇴🇨🇱🇨🇳🇨🇽🇨🇨🇨🇴🇰🇲🇨🇬🇨🇩🇨🇰🇨🇷🇨🇮🇭🇷🇨🇺🇨🇼🇨🇾🇨🇿🇩🇰🇩🇯🇩🇲🇩🇴🇪🇨🇪🇬🇸🇻🇬🇶🇪🇷🇪🇪🇸🇿🇪🇺🇪🇹🇫🇴🇫🇰🇫🇯🇫🇮🇫🇷🇬🇫🇵🇫🇹🇫🇬🇦🇬🇲🇩🇪🇬🇪🇬🇭🇬🇮🇬🇷🇬🇱🇬🇩🇬🇵🇬🇺🇬🇹🇬🇬🇬🇳🇬🇼🇬🇾🇭🇹🇭🇳🇭🇰🇭🇺🇮🇸🇮🇳🇮🇩🇮🇷🇮🇶🇮🇪🇮🇲🇮🇱🇮🇹🇯🇲🇯🇵🎌🇯🇴🇯🇪🇰🇿🇰🇪🇰🇮🇽🇰🇰🇼🇰🇬🇱🇦🇱🇻🇱🇧🇱🇸🇱🇷🇱🇾🇱🇮🇱🇹🇱🇺🇲🇴🇲🇬🇲🇼🇲🇾🇲🇻🇲🇱🇲🇹🇲🇭🇲🇶🇲🇷🇲🇺🇾🇹🇲🇽🇫🇲🇲🇩🇲🇨🇲🇳🇲🇪🇲🇸🇲🇦🇲🇿🇲🇲🇳🇦🇳🇷🇳🇵🇳🇱🇳🇨🇳🇿🇳🇮🇳🇪🇳🇬🇳🇺🇳🇫🇲🇰🇰🇵🇲🇵🇴🇲🇳🇴🇵🇰🇵🇼🇵🇸🇵🇦🇵🇬🇵🇾🇵🇪🇵🇭🇵🇳🇵🇱🇵🇹🇵🇷🇶🇦🇷🇪🇷🇴🇷🇺🇷🇼🇼🇸🇸🇲🇸🇹🇸🇦🇸🇳🇷🇸🇸🇨🇸🇱🇸🇬🇸🇽🇸🇰🇸🇮🇬🇸🇸🇧🇸🇴🇿🇦🇰🇷🇸🇸🇪🇸🇱🇰🇧🇱🇸🇭🇰🇳🇵🇲🇱🇨🇻🇨🇸🇷🇸🇩🇸🇪🇨🇭🇸🇾🇹🇼🇹🇯🇹🇿🇹🇭🇹🇱🇹🇬🇹🇰🇹🇴🇹🇹🇹🇳🇹🇷🇹🇲🇹🇨🇹🇻🇻🇮🇺🇬🇺🇦🇦🇪🇬🇧🏴󠁧󠁢󠁥󠁮󠁧󠁿🏴󠁧󠁢󠁳󠁣󠁴󠁿🏴󠁧󠁢󠁷󠁬󠁳󠁿🇺🇾🇺🇸🇻🇺🇺🇿🇻🇦🇻🇪🇻🇳🇼🇫🇪🇭🇾🇪🇾🇪🇿🇲🇿🇼"
 
*/
