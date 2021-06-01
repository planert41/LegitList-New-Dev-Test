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

var extraRatingEmojisDic: [String: String] =
    ["💩":"poop", "😡":"angry", "🤔":"iffy", "👌":"legit","🔥":"fire", "💯":"100%", "🥇":"best"]


var UserStatusEmojis: [String] = "😍😋🤤🤩😭😤😥😓💩😡😵🤑💪👍✌️👌💯❤️🔥🏆🤯😭😤😢🤤😵🤮😋".map(String.init)


//"😍😋🤤🤩😭😤😥😓💩😡😵🤑💪👍✌️👌💯❤️🔥🏆🤯 😭😤😢🤤😵🤮😋"

// 💯👑🥇🔥👌💪👺💩☠️

// DEFAULT OTHER

var otherEmojis: [String] =
    ["🚗","🏠","🚌","🏪","🎂","💑","💼","📆","👔","👖","💵","💸","🔕","🅿️","🆕","👶","👨‍👩‍👧‍👦"]

var mealEmojis:[EmojiBasic] = []
var cuisineEmojis:[EmojiBasic] = []
var dietEmojis:[EmojiBasic] = []

var mealEmojisSelect:[String] = ["🍳","🍱","🍽","🍮","☕️","🍺","🌙","📍"]
var mealEmojiDictionary:[String:String] = [
    "🍳":"breakfast",
//    "🥞":"brunch",
    "🍱":"lunch",
    "🍽":"dinner",
    "🍮":"dessert",
    "☕️":"coffee",
    "🍺":"drinks",
    "🌙":"latenight",
    "📍":"poi"
]

var cuisineEmojiSelect:[String] = [

]

var cuisineEmojiDictionary:[String:String] = [
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
var SET_RawEmojis: [String] = ["🥚","🥩","🐮","🐷","🐔","🦆","🐦","🦃","🐗","🐴","🐌","🐚","🐙","🦑","🦐","🦀","🐟","🐰","🐸","🐑","🐐","🦌","🦃","🐇"]




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
