//
//  Dictionary.swift
//  EmoticonTest
//
//  Created by Wei Zou Ang on 7/25/16.
//  Copyright © 2016 Wei Zou Ang. All rights reserved.
//

//
//  Dictionary.swift
//  Main_2
//
//  Created by Wei Zou Ang on 7/12/16.
//  Copyright © 2016 Wei Zou Ang. All rights reserved.
//


//Smiley Emoticons
//😀😆😂😊😍😘😋😝🤑😎😔😕🙁😣😫😤😩😡😑😵😱😢🤤😭😓😴🤔😷🤒👺💩☠️🙏👍✌️👌💪💍💄💋👨‍👩‍👧‍👦
//🌶🥔🥜🍯🥐🍞🥖🧀🥚🍳🥓🥞🍤🍗🍖🍕🌭🍔🍟🥙🌮🌯🥗🥘🍝🍜🍲🍥🍣🍱🍛🍚🍙🍘🍧🍨🍦🍰🎂🍮🍭🍬🍫🍿🍩🍪🥛🍼☕️🍶🍺🍻🍷🥂🍸🍹🍾🥄🍴🍽
//🐔🐷🐮🦆🐗🐴🐌🐚🐍🦀🦑🐙🦐🐟🐊🐄🐪🐖🐓🦃🐇🍄🌾⚡️🔥💥❄️💧🍎🍋🍌🍉🍇🥑🍅🍆🥒🥕🌽
//🏳️‍🌈🇦🇷🇦🇺🇦🇹🇧🇷🇨🇦🇨🇺🇨🇷🇨🇳🇪🇹🇪🇺🇫🇷🇮🇷🇮🇩🇮🇳🇭🇰🇬🇷🇩🇪🇬🇭🇮🇶🇮🇪🇮🇹🇯🇲🇯🇵🇲🇽🇲🇾🇵🇰🇵🇷🇵🇹🇵🇱🇸🇬🇿🇦🇰🇷🇪🇸🇸🇪🇺🇸🇬🇧🇹🇭🇻🇳



//😍😋🤤👍
//😀😝😂😎
//😮🤔🤑😴
//😢😭🤥😑
//😤🤒😡💩
//
//🍩🍪🥐🥞🥓
//🍕🍔🌭🍟🍗
//🥗🍝🍖🍲🍛
//🍣🍜🌮🌯🥙
//☕️🍦🍰🍺🍷
//
//🍳🍱🍽🍮🍻
//🚗🏠🚌🏪⛱
//🎂🎁💑💼📆
//💸💳💵👔👖
//👨‍👩‍👧‍👦🔕🅿️🆕🛎
//
//🐮🐷🐔🦆🐑
//🐟🦐🦀🐳🐚
//🌾🥜🌽🥔🍼
//🦃🥚🧀🍫🍄
//🌱⛪️🕍🕌☸️
//
//
//🍵🌶🔥🍯🥑
//🍎🍐🍑🍈🍌
//🍓🍇🍋🥝🌹
//🍉🍒🍍🍆🥒
//🍅🥕🥔🍠🌰
//
//🇺🇸🇲🇽🇬🇷🇹🇭
//🇫🇷🇮🇹🇩🇪🇪🇸
//🇨🇳🇯🇵🇰🇷🇮🇳
//🇻🇳🇵🇭🇲🇾🇸🇬
//🇵🇹🇮🇷🇮🇪🇸🇪
//🇦🇷🇧🇷🇨🇴🇨🇺
//🇪🇹🇯🇲🇳🇱🇸🇳
//🇲🇳🇲🇦🇷🇺🇵🇪


import Foundation

var defaultEmojis:[EmojiBasic] = []
var allEmojis:[EmojiBasic] = []
var allNonCuisineEmojis:[EmojiBasic] = []


struct EmojiBasic: Hashable, Equatable {
    let emoji : String
    let name : String?
    var count: Int = 0
    var defaultCount: Int = 0
    var hashValue: Int { get { return emoji.hashValue } }
//    var count : Int?
}

func ==(left:EmojiBasic, right:EmojiBasic) -> Bool {
    return (left.emoji == right.emoji) && (left.name == right.name)
}

var Ratings: [String] = [
    
    "😡","😩","😓","😕","😋","😍","💯"
    
]

//😍😀😅😋😝🤑🙁😩😤😡😵🤤😭🤤😑😷


var AdjustEmojiDictionary: [String:String] = [
    "🐓":"🐔"
    ]

var Emote1Init: [String] = [
    "😍","😋","🤤","👍",
    "😀","😝","😂","😎",
    "😮","🤔","🤑","😴",
    "😑","😩","😢","😭",
    "😡","😤","🤒","💩"
]


var Emote2Init: [String] = [
    "☕️","🍩","🥐","🥞","🥓","🥚",
    "🍺","🍕","🍔","🌭","🍟","🍗",
    "🍷","🍝","🥗","🍲","🍖","🍢",
    "🌮","🌯","🍣","🍜","🍛","🥙",
    "🍦","🍰","🍪","🍫","🍧","🍭"
    
]


var Emote3Init: [String] = [
    "🐮","🐷","🐔","🦆",
    "🐟","🦐","🦀","🐙",
    "🌱","🐳","🐚","🥚",
    "🌾","🥜","🌽","🍼",
    "⛪️","🕍","🕌","☸️"

]

var Emote4Init: [String] = [
    "🍯","🍋","🌶","🔥",
    "🍵","🥑","🧀","🍉",
    "🍎","🍊","🍑","🍐",
    "🍌","🍄","🥕","🍅",
    "🍓","🍇","🥝","🌹",

    
]


var Emote5Init: [String] = [
    "🍳","🍱","🍽","🍮",
    "🚗","🏠","🚌","🏪",
    "🎂","💑","💼","📆",
    "👔","👖","💵","💸",
    "👶","🔕","🅿️","🆕"
    
]

var Emote6Init: [String] = [
    "🇺🇸","🇨🇦","🇲🇽","🇨🇺","🇦🇷",
    "🇫🇷","🇮🇹","🇩🇪","🇪🇸","🇧🇷",
    "🇨🇳","🇯🇵","🇰🇷","🇮🇳","🇹🇭",
    "🇻🇳","🇵🇭","🇲🇾","🇸🇬","🇨🇴",
    "🇵🇹","🇮🇷","🇮🇪","🇬🇷","🇷🇺"
    
]


var EmoteInits:[[String]] = [Emote1Init, Emote2Init, Emote3Init, Emote4Init, Emote5Init, Emote6Init]

//var Emote1Selected: [String] = []
//var Emote2Selected: [String] = []
//var Emote3Selected: [String] = []
//var Emote4Selected: [String] = []
//var EmoticonSelectedArray: [[String]] = [Emote1Selected, Emote2Selected, Emote3Selected, Emote4Selected]


var Emote1Display: [String] = Emote1Init
var Emote2Display: [String] = Emote2Init
var Emote3Display: [String] = Emote3Init
var Emote4Display: [String] = Emote4Init
var Emote5Display: [String] = Emote5Init
var Emote6Display: [String] = Emote6Init



var EmoticonArray: [[String]] = EmoteInits

var UploadFoodEmojiArray: [String] = [
"🍕","🍔","🌭","🍗","🍝","🥗","🍲","🍖","🌮","🌯","🍣","🍜","🍛","🥙","🥞"
]

//Breakfast/Brunch "   ☕️🥛🍩🍞🥞🥐🥓🥔🥑🍌🍯🍫🍄🌯🥜]
//Lunch/Dinner/Late    🍔🍟🍲🥗🌮🌯🍕🍗🍖🍝🍜🍣🍛🌭🥙]
// Dessert/Bakery      🥐🍩🍪🍫🍦🍰🍫🍮🍧🍭🍯🍎🍓🍌🍋]
// Coffee/Drinks       ☕️🍵🍺🍷🥃🍸🍹🍶🍾🍋🍉🍇🍍🍊🍑]


var breakfastEmojiArray: [String] = [
"☕️","🥐","🥞","🍳","🥓","🍞","🥙","🥔","🥑","🍄","🍅","🥝","🍊","🍓","🍌"
]

var lunchEmojiArray: [String] = [
"🍔","🍟","🥙","🥗","🌮","🌯","🍲","🍝","🍜","🍣","🍛","🍕","🍗","🌭","🍢"
]

var dinnerEmojiArray: [String] = [
"🍝","🍖","🍣","🍜","🌮","🌯","🥗","🍲","🍛","🍚","🍔","🥙","🍟","🍕","🍗"
]

var dessertEmojiArray: [String] = [
"🍮","🍰","🍦","🥐","🍫","🍨","🥛","🍵","🍧","🍭","🍿","🍓","🍉","🍒","🍌"
]

var drinksEmojiArray: [String] = [
"🍺","🍷","🥃","🍸","🍹","🍶","🍾","☕️","🍵","🥛","🍓","🍒","🍊","🍑","🍉"
]

var coffeeEmojiArray: [String] = [
"☕️","🍵","🥐","🍩","🍮","🍰","🥖","🍪","🍘","🥛","🥗","🍲","🥙","🍞","🍳"
]

var UploadFlavorsEmojiArray: [String] = [
"💯","❤️","😋","😵","💩","🔥","🍯","🌶","🍋","🍫","🍨","🍼","🍺","🍵"
]

var UploadIngredientsEmojiArray: [String] = [
"🐮","🐷","🐓","🦆","🦃","🐑","🐟","🦐","🦀","🦑","🧀","🥚","🍎","🥒","🥔"
]

var UploadSettingEmojiArray: [String] = [
"🚗","🏠","🚌","🏪","🎂","💑","💼","📆","👔","👖","👶","⛪️","🕍","🕌","☸️"
]

var UploadCuisineEmojiArray: [String] = [
"🍀","🍤","🇺🇸","🇮🇹","🇲🇽","🇹🇭","🇨🇳","🇯🇵","🇮🇳","🇰🇷","🇫🇷","🇬🇷","🇪🇸","🕌","🕍"
]

var defaultEmojiArray = UploadIngredientsEmojiArray + UploadFlavorsEmojiArray + UploadCuisineEmojiArray


//var EmoticonArray: [[String]] = [Emote1Display, Emote2Display, Emote3Display, Emote4Display]


var extras = "🐮🐔🐷🐙🍅🍠🐣🐌🐛🎭🎯🍳☝️⭐️⚠️🍖🍛🍴🍛🎃🎓💍🎈🎆🏆🎪🎮🔍🚽🗿🎮♨️♻️💊👌🔒"

var defaultEmojiSelection: [String] = [
    "🍩",
    "🥞",
    "🍔",
    "🍕",
    "🍣",
    "🍜",
    "🥗",
    "🍝",
    "🍖",
    "🌮",
    "🌯",
    "🥙",
    "🍗",
    "☕️",
    "🍺",
    "🍷",
    "🍦",
    "🍰",
    "🍢",
    "🍪",
    "🍧",
    "🍭"

]

var EmojiDictionaryEmojis: [EmojiBasic] = []

var userEmojiDictionary: [String:String] = [:]

var FoodEmojiDictionary: [String:String] = [
    "🧀":"cheese",
    "🥚":"egg",
    "🧈":"butter",
    "🍯":"honey",
    "🥐":"pastry",
    "🥯":"bagel",
    "🍞":"bread",
    "🥖":"baguette",
    "🥨":"pretzel",
    
    "🥞":"pancake",
    "🧇":"waffle",
    "🥓":"bacon",
    
    "🥩":"steak",
    "🍗":"wings",
    "🌭":"hotdog",
    "🍔":"burger",
    "🍟":"fries",
    "🍕":"pizza",
    "🥪":"sandwich",
    "🥙":"pita",
    "🧆":"falafel",
    "🫓":"flatbread",
    
    "🌮":"taco",
    "🌯":"burrito",
    "🫔":"tamale",
    "🥗":"salad",
    "🫕":"hotpot",

    "🍝":"pasta",
    "🍜":"noodle",
    "🍲":"soup",
    "🥘":"pan",
    "🍛":"curry",
    "🍣":"sushi",
    "🥟":"dumpling",
    "🦪":"oyster",
    "🍚":"rice",
    "🥮":"mooncake",
    "🍡":"skewer",
    "🍨":"sundae",
    "🍦":"icecream",
    "🥧":"pie",
    "🧁":"cupcake",
    "🍰":"cake",
    "🍘":"biscuit",
    "🍬":"candy",
    "🍫":"chocolate",
    "🍿":"popcorn",
    "🍩":"donut",
    "🍪":"cookie",
    "🦴":"bone",
    "🧂":"salt",
    "🥠":"fortune",
    "🍭":"sweet",
    "🌶":"spicy",
    "🥣":"bowl",
    "🍖":"bbq",
    "🍤":"seafood"
]

var SnacksEmojiDictionary: [String:String] = [
    "🥐":"pastry",
    "🥯":"bagel",
    "🍞":"bread",
    "🥖":"baguette",
    "🥨":"pretzel",
    "🍨":"sundae",
    "🍦":"icecream",
    "🥧":"pie",
    "🧁":"cupcake",
    "🍰":"cake",
    "🍘":"biscuit",
    "🍬":"candy",
    "🍫":"chocolate",
    "🍿":"popcorn",
    "🍩":"donut",
    "🍪":"cookie",
    "🥮":"mooncake",
    "🥠":"fortune",
    "🍟":"fries"
]

var DrinksEmojiDictionary: [String:String] = [

    "🥛":"milk",
    "☕️":"coffee",
    "🫖":"tea",
    "🍵":"matcha",
    "🧃":"juice",
    "🥤":"soda",
    "🧋":"boba",
    "🍶":"sake",
    "🍺":"beer",
    "🍷":"wine",
    "🥃":"alcohol",
    "🍸":"cocktail",
    "🍾":"champagne",
    "🧊":"ice",
    "🍹":"fruity"


]

var IngEmojiDictionary: [String:String] = [:]

var VegEmojiDictionary: [String:String] = [
    "🍎":"apple",
    "🍐":"pear",
    "🍊":"orange",
    "🍋":"lemon",
    "🍌":"banana",
    "🍉":"watermelon",
    "🍇":"grape",
    "🍓":"strawberry",
    "🫐":"blueberry",
    "🍈":"melon",
    "🍒":"cheery",
    "🍑":"peach",
    "🥭":"mango",
    "🍍":"pineapple",
    "🥥":"coconut",
    "🥝":"kiwi",
    "🍅":"tomato",
    "🍆":"eggplant",
    "🥑":"avacado",
    "🥦":"broccoli",
    "🥒":"cucumber",
    "🫑":"pepper",
    "🌽":"corn",
    "🥕":"carrot",
    "🫒":"olive",
    "🧄":"garlic",
    "🧅":"onion",
    "🥔":"potato",
    "🍠":"sweet potato",
    "🥬":"vegetable",
    "🌰":"chestnut",
    "🥜":"peanut",

    "🌵":"cactus",
    "🪵":"wood",
    "🎋":"bamboo",
    "🍄":"mushroom",
    "🐚":"shell",
    "🪨":"rock",
    "🌾":"wheat",
    "💐":"flower",
    "🌹":"rose",
    "🌷":"tulip",
    "🌺":"blossom",
    "🌼":"flower",
    "🌻":"sunflower",

]

var MeatEmojiDictionary: [String: String] =
[
       "🐶":"dog",
       "🐱":"cat",
       "🐭":"mouse",
       "🐹":"hamster",
       "🐰":"rabbit",
       "🦊":"fox",
       "🐻":"bear",
       "🐼":"panda",
       "🐯":"tiger",
       "🦁":"lion",
       "🐮":"beef",
       "🐷":"pork",
       "🐔":"chicken",
       "🐒":"monkey",
       "🐤":"poultry",
       "🦆":"duck",
       "🦉":"owl",
       "🦇":"bat",
       "🦅":"eagle",
       "🐺":"wolf",
       "🐗":"boar",
       "🐴":"horse",
       "🦄":"unicorn",
       "🐝":"bee",
       "🪱":"worm",
       "🐛":"bug",
       "🦋":"butterfly",
       "🐌":"snail",
       "🪲":"beetle",
       "🐜":"ant",
       "🪰":"fly",
       "🪳":"cockroach",
       "🦟":"mosquito",
       "🦗":"cricket",
       "🕷":"spider",
       "🕸":"web",
       "🦂":"scorpion",
       "🐢":"turtle",
       "🐍":"snake",
       "🦎":"lizard",
       "🐙":"octopus",
       "🦑":"squid",
       "🦐":"shrimp",
       "🦞":"lobster",
       "🦀":"crab",
       "🐟":"fish",
       "🐋":"whale",
       "🦈":"dolphin",
       "🦭":"seal",
       "🐊":"crocodile",
       "🦓":"zebra",
       "🦍":"ape",
       "🐘":"elephant",
       "🦛":"hippopotamus",
       "🦏":"rhinoceros",
       "🐪":"camel",
       "🦒":"giraffe",
       "🦘":"kangaroo",
       "🦬":"bison",
       "🐃":"buffalo",
       "🐂":"ox",
       "🐎":"horse",
       "🐑":"sheep",
       "🦙":"llama",
       "🐐":"goat",
       "🦃":"turkey",
       "🦜":"parrot",
       "🦢":"swan",
       "🦩":"flamingo",
       "🦝":"raccoon",
       "🦨":"skunk",
       "🦡":"badger",
       "🦫":"beaver",
       "🦦":"otter",
       "🦥":"sloth",
       "🐿":"squirrel",
       "🦔":"hedgehog",
       "🐲":"dragon"]

var DietEmojiDictionary: [String:String] =
[
    "✅":"vegan",
    "☘️":"organic",
    "⛪️":"christian",
    "🕍":"kosher",
    "🛕":"hindu",
    "🕌":"halal",
    "☸️":"buddhist",
    
    "❌🍖": "vegetarian",
    "❌🌾": "gluten free",
    "❌🥜":"peanut free",
    "❌🥛":"non dairy",
    "❌🍚":"keto",
]


var SmileyEmojiDictionary: [String:String] =
[

    // OTHER SMILEYS
    
// FEELINGS
    "😋":"tasty",
    "🤤":"delicious",
    "👍":"awesome",
    "😀":"great",
    "😝":"lol",
    "😂":"funny",
    "😎":"cool",
    "😮":"surprised",
    "🤩":"amazing",

//    "🤑":"expensive",

    "😴":"slow",
    "😢":"sad",
    "🤥":"lied",
    "😑":"meh",
    "🤯":"omg",
    "😤":"angry",
    "🤒":"sick",
    "😩":"terrible",
    "😓":"bad",
    "🥳":"party",
    "🎩":"classy",
    "🥺":"please",
    "😭":"cry",
    "🤬":"wtf",
    "😱":"shock",
    "😮‍💨":"sigh",
    "😡":"awful",
    "🤫":"secret",

]

var EmojiDictionary: [String:String] =

[

    

    //🥬🍙🍘🍥🥠🍢🍡🍧🍨🎂🍭🍼🫖🍻🥂🥢🥡🥄🍴🍽🍻🍧
    
    // RATING EMOJIS
        "💩":"poop",
        "😡":"furious",
        "😍":"awesome",
        "👌":"legit",
        "🔥":"fire",
        "💯":"100%",
        "🥇":"best",
    
    "🇹🇭🍝":"pad thai" ,
    "🍖🍡":"meatball",
    
    "🎃👻": "halloween",
    "🐔🍗": "chicken wing",
    "🐔🍚":"chicken rice",
    "🐔🍛": "chicken curry",
    "🐷🍛":"pork curry",
    "🐟🍛":"fish curry",
    
    


    
]

var OtherEmojiDictionary:[String:String] = [
    // OTHER
    "🧶":"comfortable",
    "🤲":"handmade",
    "👘":"traditional",
    "🏖":"relax",
    "🏃":"healthy",
    "🗽":"famous",
    "🧨":"dynamite",
    "💣":"bomb",
    "🕯":"atmosphere",
    "🏜":"dry",
    "🩴":"casual",
    "✈️":"travel",
    "⭐️":"star",
    "🎂":"birthday",
    "🥂":"celebrate",
    "🌳":"plant",
    "⛰":"natural",

    "🌟":"special",
    "❤️":"love",

    "❄️":"cold",
    "🫀":"heart",
    "🧠":"brain",
    "👻":"scary",
    "🦷":"teeth",
    "💋":"romantic",
    "💪":"strong",
    "🏆":"champ",
    "🙏":"pray",
    "👨‍🍳":"chef",
    "👨‍💻":"work",
    "🕵️‍♂️":"discover",
    "🧑‍🌾":"farmer",
    "🎤":"karaoke",
    "🎹":"music",
    "🎸":"guitar",
    "🎭":"drama",
    "🎨":"art",
    "🎟":"ticket",
    "🎫":"concert",
    "🎪":"festival",
    "🎥":"movie",
    "☎️":"telephone",
    "🔑":"key",
    "💻":"laptop",
    "🔜":"soon",
    "🔙":"back",
    "⚠️":"warn",
    "❓":"?",
    "‼️":"!!",
    "🚾":"bathroom",
    "🏧":"atm",
    "♿️":"wheelchair",
    "🈳":"empty",
    "💼":"bag",
    "🆓":"free",
    "👑":"king",
    "⚽️":"soccer",
    "🏀":"basketball",
    "🏈":"football",
    "⚾️":"baseball",
    "🥎":"softball",
    "🎾":"tennis",
    "🏐":"volleyball",
    "🏉":"rugby",
    "🥏":"frisbee",
    "🎱":"billard",
    "🏓":"table tennis",
    "🏸":"badminton",
    "🏒":"hockey",
    "🥍":"lacrosse",
    "🏏":"cricket",
    "⛳️":"golf",
    "🎣":"fishing",
    "🥊":"boxing",
    "🥋":"martial arts",
    "⛷":"ski",
    "🏂":"snowboard",
    "🏋️":"gym",
    "🚴":"cycling",
    "🏊":"swim",
    "🧘":"yoga",
    "⛸":"skate",
    "🔍":"find",
    "📆":"reservation",
    "📝":"remember",
    "🛍":"shopping",
    "🎁":"present",
    "🪄":"magic",
    "⚔️":"fight",
    "🚬":"cigarette",
    "⚡️":"fast",
    "🤵":"service",
    "🎉":"fun",

    "🏠":"restaurant",
    "🚌":"truck",
    "🏪":"24hour",
    "💑":"date",
    "👔":"business",
    "👖":"informal",
    "💵":"cash",
    "💳":"card",
    "💲":"cheap",
    "💸":"expensive",
    "🔕":"quiet",
    "🅿️":"parking",
    "🆕":"new",
    "👶":"kid",
    "🍼":"baby",
    "👨‍👩‍👧‍👦":"family",
    "👨‍🌾":"local",
    "💎":"gem",
    "🏕":"outdoor",
    "🧲":"chain",
    "🎖":"honor",
    "🎗":"charity",
    "🎃":"seasonal",
    "🤑":"pricey"

]

var FlagEmojiDictionary:[String:String] = [
    "🇦🇫":"afghanistan",
    "🇦🇱":"albania",
    "🇩🇿":"algeria",
    "🇦🇸":"samoa",
    "🇦🇩":"andorra",
    "🇦🇴":"angola",
    "🇦🇷":"argentina",
    "🇦🇲":"armenia",
    "🇦🇼":"aruba",
    "🇦🇺":"australia",
    "🇦🇹":"austria",
    "🇦🇿":"azerbajian",
    "🇧🇸":"bahamas",
    "🇧🇭":"bahrain",
    "🇧🇩":"bangladesh",
    "🇧🇧":"barbados",
    "🇧🇾":"belarus",
    "🇧🇪":"belgium",
    "🇧🇿":"belize",
    "🇧🇯":"benin",
    "🇧🇲":"bermuda",
    "🇧🇹":"bhutan",
    "🇧🇴":"bolivia",
    "🇧🇦":"bosnia",
    "🇧🇼":"botswana",
    "🇧🇷":"brazil",
    "🇧🇳":"brunei",
    "🇧🇬":"bulgaria",
    "🇧🇫":"burkina",
    "🇧🇮":"burundi",
    "🇰🇭":"cambodia",
    "🇨🇦":"canada",
    "🇧🇶":"bonaire",
    "🇰🇾":"cayman",
    "🇹🇩":"chad",
    "🇨🇱":"chile",
    "🇨🇳":"china",
    "🇨🇴":"colombia",
    "🇰🇲":"comoros",
    "🇨🇬":"congo",
    "🇨🇷":"costa rica",
    "🇭🇷":"croatia",
    "🇨🇺":"cuba",
    "🇨🇼":"curacao",
    "🇨🇾":"cyprus",
    "🇨🇿":"czech",
    "🇩🇰":"denmark",
    "🇩🇯":"djibouti",
    "🇩🇲":"dominica",
    "🇩🇴":"dominican",
    "🇪🇨":"ecuador",
    "🇪🇬":"egypt",
    "🇸🇻":"el savador",
    "🇪🇷":"eritrea",
    "🇪🇪":"estonia",
    "🇸🇿":"eswatini",
    "🇪🇹":"ethopia",
    "🇫🇯":"fiji",
    "🇫🇮":"finland",
    "🇫🇷":"france",
    "🇬🇦":"gabon",
    "🇬🇪":"georgia",
    "🇩🇪":"germany",
    "🇬🇭":"ghana",
    "🇬🇮":"gibraltar",
    "🇬🇷":"greece",
    "🇬🇱":"greenland",
    "🇬🇩":"grenada",
    "🇬🇺":"guam",
    "🇬🇹":"guatemala",
    "🇬🇬":"guernsey",
    "🇬🇳":"guinea",
    "🇬🇾":"guyana",
    "🇭🇹":"haiti",
    "🇭🇳":"honduras",
    "🇭🇰":"hong kong",
    "🇭🇺":"hungary",
    "🇮🇸":"iceland",
    "🇮🇳":"india",
    "🇮🇩":"indonesia",
    "🇮🇷":"iran",
    "🇮🇶":"iraq",
    "🇮🇪":"ireland",
    "🇮🇱":"israel",
    "🇮🇲":"isle of man",
    "🇮🇹":"italy",
    "🇯🇲":"jamaica",
    "🇯🇵":"japan",
    "🇯🇴":"jordan",
    "🇰🇿":"kazakhstan",
    "🇰🇪":"kenya",
    "🇰🇮":"kiribati",
    "🇽🇰":"kosovo",
    "🇰🇼":"kuwait",
    "🇰🇬":"kyrgyzstan",
    "🇱🇦":"laos",
    "🇱🇻":"latvia",
    "🇱🇧":"lebanon",
    "🇱🇸":"lesotho",
    "🇱🇷":"liberia",
    "🇱🇾":"libya",
    "🇱🇮":"liechtenstein",
    "🇱🇺":"luxembourg",
    "🇲🇴":"macao",
    "🇲🇬":"madagascar",
    "🇲🇼":"malawi",
    "🇲🇾":"malaysia",
    "🇲🇻":"maldives",
    "🇲🇱":"mali",
    "🇲🇹":"malta",
    "🇲🇭":"marshall islands",
    "🇲🇶":"martinique",
    "🇲🇷":"mauritania",
    "🇲🇺":"mauritius",
    "🇾🇹":"mayotte",
    "🇲🇽":"mexico",
    "🇫🇲":"micronesia",
    "🇲🇩":"moldova",
    "🇲🇨":"monaco",
    "🇲🇳":"mongolia",
    "🇲🇪":"montenegro",
    "🇲🇸":"montserrat",
    "🇲🇦":"morocco",
    "🇲🇿":"mozambique",
    "🇲🇲":"myanmar",
    "🇳🇦":"namibia",
    "🇳🇷":"nauru",
    "🇳🇵":"nepal",
    "🇳🇱":"netherlands",
    "🇳🇿":"new zealand",
    "🇳🇮":"nicaragua",
    "🇳🇪":"niger",
    "🇳🇬":"nigeria",
    "🇳🇺":"niue",
    "🇳🇫":"norfolk island",
    "🇰🇵":"north korea",
    "🇲🇰":"macedonia",
    "🇳🇴":"norway",
    "🇴🇲":"oman",
    "🇵🇰":"pakistan",
    "🇵🇼":"palau",
    "🇵🇸":"palestine",
    "🇵🇦":"panama",
    "🇵🇬":"new guinea",
    "🇵🇾":"paraguay",
    "🇵🇪":"peru",
    "🇵🇭":"phillipines",
    "🇵🇱":"poland",
    "🇵🇹":"portugal",
    "🇵🇷":"puerto rico",
    "🇶🇦":"qatar",
    "🇷🇴":"romania",
    "🇷🇺":"russia",
    "🇷🇼":"rwanda",
    "🇼🇸":"samoa",
    "🇸🇲":"san marino",
    "🇸🇦":"saudi arabia",
    "🇸🇳":"senegal",
    "🇷🇸":"serbia",
    "🇸🇨":"seychelles",
    "🇸🇬":"singapore",
    "🇸🇰":"slovakia",
    "🇸🇮":"slovenia",
    "🇸🇧":"soloman island",
    "🇸🇴":"somalia",
    "🇿🇦":"south africa",
    "🇰🇷":"south korea",
    "🇸🇸":"south sudan",
    "🇪🇸":"spain",
    "🇱🇰":"sri lanka",
    "🇸🇭":"st helena",
    "🇰🇳":"st kitts",
    "🇻🇨":"grenadine",
    "🇸🇩":"sudan",
    "🇸🇷":"suriname",
    "🇸🇪":"sweden",
    "🇨🇭":"switzerland",
    "🇸🇾":"syria",
    "🇹🇼":"taiwan",
    "🇹🇯":"tajikstan",
    "🇹🇿":"tanzania",
    "🇹🇭":"thailand",
    "🇹🇬":"togo",
    "🇹🇴":"tonga",
    "🇹🇹":"trinidad",
    "🇹🇷":"turkey",
    "🇹🇲":"turkmenistan",
    "🇹🇻":"tuvalu",
    "🇻🇮":"virgin islands",
    "🇺🇬":"uganda",
    "🇺🇦":"ukraine",
    "🇦🇪":"united arab emirates",
    "🇬🇧":"united kingdom",
    "🏴󠁧󠁢󠁥󠁮󠁧󠁿":"england",
    "🏴󠁧󠁢󠁳󠁣󠁴󠁿":"scotland",
    "🏴󠁧󠁢󠁷󠁬󠁳󠁿":"wales",
    "🇺🇸":"america",
    "🇺🇾":"uruguay",
    "🇺🇿":"uzbekistan",
    "🇻🇺":"vanuatu",
    "🇻🇦":"vatican",
    "🇻🇪":"venezuela",
    "🇻🇳":"vietnam",
    "🇪🇭":"sahara",
    "🇾🇪":"yemen",
    "🇿🇲":"zambia",
    "🇿🇼":"zimbabwe"
]

var emojiDictionarySets:[[String:String]] = [mealEmojiDictionary, FoodEmojiDictionary, DrinksEmojiDictionary, VegEmojiDictionary, FlagEmojiDictionary, DietEmojiDictionary, SmileyEmojiDictionary, OtherEmojiDictionary, MeatEmojiDictionary, OtherEmojiDictionary, SnacksEmojiDictionary]


//[
//        "💯":"best",
//        "😍":"amazing",
//        "😋":"good",
//        "😕":"ok",
//        "😓":"bad",
//        "😩":"terrible",
//        "😡":"worst",
//        "😢":"sad",
//        "💩":"poop",
//        "😑":"grrrr",
//        "😝":"lol",
//        "🍴":"food",
//        "🚗":"delivery",
//        "🔒":"private",
//        "🍳":"breakfast",
//        "🍱":"lunch",
//        "🍽":"dinner",
//        "🌙":"latenight",
//        "☕️":"coffee",
//        "🍦":"icecream",
//        "🍮":"dessert",
//        "🍺":"beer",
//        "🍷":"wine",
//        "🎁":"surprise",
//        "🎷":"music",
//        "🎨":"art",
//        "🎭":"theatre",
//        "📷":"photo",
//        "🎪":"attraction",
//        "📍":"local",
//        "🗿":"exotic",
//        "🍔":"burger",
//        "🍕":"pizza",
//        "🍟":"fries",
//        "🍗":"wings",
//        "🍛":"curry",
//        "🍣":"sushi",
//        "🍜":"ramen",
//        "🍰":"cake",
//        "🍲":"soup",
//        "🍝":"pasta",
//        "🍞":"bread",
//        "🍩":"doughnut",
//        "🍫":"chocolate",
//        "🍪":"cookie",
//        "🎤":"karaoke",
//        "🍋":"sour",
//        "🍯":"sweet",
//        "🔥":"spicy",
//        "🐓":"chicken",
//        "🐄":"beef",
//        "🐖":"pork",
//        "🐟":"fish",
//        "🐚":"shellfish",
//        "🐙":"seafood",
//        "🍀":"vegetarian",
//        "🍠": "potato",
//        "🍎":"fruit",
//        "🍤":"shrimp",
//        "🍼":"milk",
//        "🌽":"corn",
//        "🌾":"glutenfree",
//        "🍄":"mushroom",
//        "🌰":"nuts",
//        "🍚":"rice"]




/*
 
 "🇦🇺":"aus"
 "🇦🇹"
 "🇧🇪"
 "🇧🇷"
 "🇨🇦"
 "🇨🇱"
 "🇨🇳"
 "🇨🇴"
 "🇩🇰"
 "🇫🇮"
 "🇫🇷"
 "🇩🇪"
 "🇭🇰"
 "🇮🇳"
 "🇮🇩"
 "🇮🇪"
 "🇮🇱"
 "🇮🇹"
 "🇯🇵"
 "🇰🇷"
 "🇲🇴"
 "🇲🇾"
 "🇲🇽"
 "🇳🇱"
 "🇳🇿"
 "🇳🇴"
 "🇵🇭"
 "🇵🇱"
 "🇵🇹"
 "🇵🇷"
 "🇷🇺"
 "🇸🇦"
 "🇸🇬"
 "🇿🇦"
 "🇪🇸"
 "🇸🇪"
 "🇨🇭"
 "🇹🇷"
 "🇬🇧"
 "🇺🇸"
 "🇦🇪"
 "🇻🇳"
 */

/*
 public var tags = String()    {
 
 
 didSet {
 /*
 // Loop Through Array
 
 
 for EmoteArray: [String] in EmoteInits {
 
 // Loop Through Emoticoins
 
 var EmoteSelectedArray: [String] = []
 
 // Add it to the Selected Emoticon Array
 if EmoteArray == Emote1Init {
 EmoteSelectedArray = Emote1Selected
 }
 else if EmoteArray == Emote2Init {
 EmoteSelectedArray = Emote2Selected
 }
 else if EmoteArray == Emote3Init {
 EmoteSelectedArray = Emote3Selected
 }
 else if EmoteArray == Emote4Init {
 EmoteSelectedArray = Emote4Selected
 }
 var EmoteDisplayTemp = EmoteArray
 
 for Emoticon: String in EmoteArray  {
 
 // If Emoticon is Tagged
 
 if tags.containsString(Emoticon) {
 
 // If is tagged, remove emoticon from init
 EmoteDisplayTemp.removeAtIndex(EmoteDisplayTemp.indexOf(Emoticon)!)
 
 if EmoteSelectedArray.contains(Emoticon) {
 
 // pass nothig if emoticon is selected and is already in selected index
 
 } else {
 
 //Add selected emoticon to the selected index
 EmoteSelectedArray.append(Emoticon)
 }
 }
 
 // IF Emoticon is not tagged
 else {
 if EmoteSelectedArray.contains(Emoticon) {
 EmoteSelectedArray.removeAtIndex(EmoteSelectedArray.indexOf(Emoticon)!)
 }
 }
 }
 
 
 if EmoteArray == Emote1Init {
 Emote1Display = EmoteSelectedArray +  EmoteDisplayTemp
 Emote1Selected = EmoteSelectedArray
 }
 else if EmoteArray == Emote2Init {
 Emote2Display = EmoteSelectedArray +  EmoteDisplayTemp
 Emote2Selected = EmoteSelectedArray
 }
 else if EmoteArray == Emote3Init {
 Emote3Display = EmoteSelectedArray +  EmoteDisplayTemp
 Emote3Selected = EmoteSelectedArray
 }
 else if EmoteArray == Emote4Init {
 Emote4Display = EmoteSelectedArray +  EmoteDisplayTemp
 Emote4Selected = EmoteSelectedArray
 }
 
 
 EmoticonArray = [Emote1Display, Emote2Display, Emote3Display, Emote4Display]
 
 
 }
 */
 }
 
 }*/







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
