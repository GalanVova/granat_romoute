import Foundation

let demoCountries: [Country] = [
    Country(code: "UA", name: "Ukraine",  flag: "🇺🇦"),
    Country(code: "ES", name: "Spain",    flag: "🇪🇸"),
    Country(code: "GB", name: "England",  flag: "🇬🇧"),
    Country(code: "FR", name: "France",   flag: "🇫🇷"),
    Country(code: "PL", name: "Poland",   flag: "🇵🇱"),
    Country(code: "BG", name: "Bulgaria", flag: "🇧🇬"),
    Country(code: "RO", name: "Romania",  flag: "🇷🇴"),
]

let demoPCNs: [PCN] = [
    PCN(id: "safety-kharkiv",   countryCode: "UA", name: "Security and safety, Kharkiv", host: "91.223.152.18", port: 8383),
    PCN(id: "test-kharkiv-2",   countryCode: "UA", name: "Тест Харьков 2",               host: "91.223.152.18", port: 8282),
    PCN(id: "safety-kyiv",      countryCode: "UA", name: "Security and safety, Kyiv",    host: "91.223.152.18", port: 8383),
    PCN(id: "safety-odessa",    countryCode: "UA", name: "Security and safety, Odessa",  host: "91.223.152.18", port: 8383),
    PCN(id: "barsyk",           countryCode: "UA", name: "Barsyk security system",       host: "91.223.152.18", port: 8383),
    PCN(id: "badger",           countryCode: "UA", name: "Badger protection system",     host: "91.223.152.18", port: 8383),
    PCN(id: "cat",              countryCode: "UA", name: "Cat security system",          host: "91.223.152.18", port: 8383),
    PCN(id: "dog",              countryCode: "UA", name: "Dog protection system",        host: "91.223.152.18", port: 8383),
]
