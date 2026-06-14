# Quick test to count entries in each vector

# Count cities
cities <- c(
    # Asia - 50
    "Tokyo", "Delhi", "Shanghai", "Mumbai", "Beijing", "Dhaka", "Osaka",
    "Karachi", "Chongqing", "Istanbul", "Buenos Aires", "Kolkata", "Manila",
    "Lagos", "Rio de Janeiro", "Tianjin", "Kinshasa", "Guangzhou", "Los Angeles",
    "Moscow", "Shenzhen", "Lahore", "Bangalore", "Paris", "Bogota",
    "Jakarta", "Chennai", "Lima", "Bangkok", "Seoul", "Nagoya", "Hyderabad",
    "London", "Tehran", "Nanjing", "Chengdu", "Cairo", "Baghdad", "Luanda",
    "Ho Chi Minh City", "Hong Kong", "Dongguan", "Dar es Salaam", "Foshan",
    "Santiago", "Madrid", "Haora", "Shenyang", "Riyadh", "Toronto",
    # Additional - 30
    "Singapore", "Saint Petersburg", "Pune", "Surat", "Yangon", "Xi'an",
    "Barcelona", "Johannesburg", "Qingdao", "Harbin", "Changchun", "Dalian",
    "Zhengzhou", "Shantou", "Jinan", "Hangzhou", "Wenzhou", "Kunming",
    "Sydney", "Melbourne", "Montreal", "Vancouver", "Chicago", "Houston",
    "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "Austin",
    # Europe - 25
    "Berlin", "Rome", "Milan", "Naples", "Athens", "Hamburg", "Munich",
    "Warsaw", "Vienna", "Budapest", "Prague", "Brussels", "Amsterdam",
    "Stockholm", "Copenhagen", "Helsinki", "Dublin", "Lisbon", "Bucharest",
    "Minsk", "Kiev", "Sofia", "Zagreb", "Belgrade", "Oslo",
    # Middle East & Africa - 24
    "Dubai", "Jeddah", "Alexandria", "Khartoum", "Casablanca", "Algiers",
    "Addis Ababa", "Nairobi", "Kano", "Ibadan", "Accra", "Dakar", "Abidjan",
    "Cape Town", "Durban", "Pretoria", "Tel Aviv", "Amman", "Beirut",
    "Damascus", "Aleppo", "Kuwait City", "Doha", "Muscat", "Sanaa",
    # Americas - 31
    "São Paulo", "Mexico City", "New York", "Brasilia", "Belo Horizonte",
    "Guadalajara", "Monterrey", "Medellin", "Cali", "Quito", "Guayaquil",
    "Caracas", "Havana", "Santo Domingo", "Port-au-Prince", "Guatemala City",
    "San Salvador", "Tegucigalpa", "Managua", "San Jose", "Panama City",
    "Seattle", "Boston", "Washington", "Miami", "Atlanta", "Denver",
    "Minneapolis", "Detroit", "Las Vegas", "Portland", "San Francisco",
    # Asia-Pacific - should be 32
    "Kuala Lumpur", "Hanoi", "Phnom Penh", "Vientiane", "Kathmandu",
    "Colombo", "Islamabad", "Kabul", "Tashkent",
    "Almaty", "Bishkek", "Dushanbe", "Ashgabat", "Baku", "Tbilisi", "Yerevan",
    "Brisbane", "Perth", "Adelaide", "Auckland", "Wellington", "Suva",
    "Port Moresby", "Taipei", "Kaohsiung", "Busan", "Incheon", "Pyongyang",
    "Ulaanbaatar", "Cebu", "Davao", "Quezon City"
)

cat("Cities:", length(cities), "\n")
cat("Expected: 50+30+25+24+31+32 = 192\n")
